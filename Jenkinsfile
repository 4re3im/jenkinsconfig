pipeline {
  agent none

  options {
    skipDefaultCheckout()
  }

  stages {
    /*
    // This cleanup will only be used when the label 'built-in' is used 
    stage('Initial Clean Workspace') {
        agent {
            label "built-in"
        }  
        steps {
            cleanWs()
        }
    }
    */

    stage('Abort Previous Build') {
      agent {
        label 'built-in'
      }
      steps {
        script {
          def jobName = env.JOB_NAME
          def buildNumber = env.BUILD_NUMBER.toInteger()
          def currentJob = Jenkins.instance.getItemByFullName(jobName)

          for (def build: currentJob.builds) {
            def exec = build.getExecutor()
            if (build.isBuilding() && build.number.toInteger() != buildNumber && exec != null) {
              exec.interrupt(
                Result.ABORTED,
                new CauseOfInterruption.UserInterruption("Job aborted by #${currentBuild.number}")
              )
              echo "Job aborted previously running build #${build.number}"
            }
          }
        }
      }
    }

    stage('Build Package') {
      agent {
        label "cloud-agent-1"
      }
      steps {
        script {
          // Create jenkinsconfig and application directory                
          sh '''
          mkdir -p "${WORKSPACE}/jenkinsconfig"
          mkdir -p "${WORKSPACE}/application"
          '''

          // Checkout jenkins configuration files
          dir("${WORKSPACE}/jenkinsconfig") {
            sshagent(['cup-gitlab']) {
              git branch: 'master', credentialsId: 'cup-gitlab', url: 'git@cup-gitlab.cambridge.org:bnr-education/tng-go.git'
            }
          }

          // Loading and executing the config script
          def configScript = load "${WORKSPACE}/jenkinsconfig/extract.groovy"
          configScript.Extract()

          // Create RPM package
          sh """
          chmod 755 jenkinsconfig/rpmcreation.sh
          ./jenkinsconfig/rpmcreation.sh 
            """

          // Push to S3
          withCredentials([
            [$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'backoffice-nonprod']
          ]) {
            sh "aws s3 cp $WORKSPACE/application/RPMS/noarch/${PACKAGE_NAME}-${VERSION}-${BUILD_NUMBER}.noarch.rpm s3://bnr-jenkins/package-repository/${PACKAGE_NAME}-${VERSION}-${BUILD_NUMBER}.noarch.rpm --region eu-west-1"
          }
        }
      }
    }

    stage('Execute createrepo') {
      agent {
        label 'cloud-agent-1'
      }
      steps {
        script {
          withCredentials([
            [$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'backoffice-nonprod']
          ]) {
            sh """
            aws s3 sync s3://bnr-jenkins/package-repository/ $WORKSPACE --region eu-west-1
            /usr/bin/createrepo_c --update $WORKSPACE
            find $WORKSPACE -type f -name '*.rpm' -mtime +1 -delete
            find $WORKSPACE/repodata -type f -name '*.gz' -o -name '*.bz2' -mtime +1 -delete
            aws s3 sync $WORKSPACE s3://bnr-jenkins/package-repository/ --delete
            """
          }
        }
      }
    }

    stage('Deploy on Staging') {
      agent {
        label 'built-in'
      }
      steps {
        script {

          input message: 'Approval to Deploy on Staging', submitter: 'Dom AWS Admins'
        }
      }
    }

    stage('Staging') {
      agent {
        label 'cloud-agent-1'
      }
      steps {
        script {
            withCredentials([sshUserPrivateKey(credentialsId: 'ec2-user', keyFileVariable: 'SSH_KEY')]) {
            def remoteIp = '3.254.230.59'
            sh """
            ssh -o StrictHostKeyChecking=no -l ec2-user -i \${SSH_KEY} $remoteIp 'whoami'
            ssh -l ec2-user -i \${SSH_KEY} $remoteIp 'sudo yum clean all'
            ssh -l ec2-user -i \${SSH_KEY} $remoteIp 'sudo rm -rf /var/cache/yum'
            ssh -l ec2-user -i \${SSH_KEY} $remoteIp 'sudo yum check-update || :'
            ssh -l ec2-user -i \${SSH_KEY} $remoteIp 'sudo yum -y remove cup-tng-go'
            ssh -l ec2-user -i \${SSH_KEY} $remoteIp 'sudo yum -y install cup-tng-go'
            """
            
          }
        }
      }
      post {
            success {
                emailext attachLog: true, body: '$DEFAULT_CONTENT', subject: '$PROJECT_NAME - Build # $BUILD_NUMBER - $BUILD_STATUS!', to: '$DEFAULT_RECIPIENTS'
        }
            failure {
                emailext attachLog: true, body: '$DEFAULT_CONTENT', subject: '$PROJECT_NAME - Build # $BUILD_NUMBER - $BUILD_STATUS!', to: '$DEFAULT_RECIPIENTS'
        }
      }
    }
  }
}
