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
                    ls -la ${WORKSPACE}
                    pwd
                    chmod 755 jenkinsconfig/rpmcreation.sh
                    ./jenkinsconfig/rpmcreation.sh
                    """

                    // Push to S3
                    withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'backoffice-nonprod']]) {
                        sh "aws s3 cp $WORKSPACE/application/RPMS/noarch/${PACKAGE_NAME}-${VERSION}-${BUILD_NUMBER}.noarch.rpm s3://bnr-jenkins/package-repository/${PACKAGE_NAME}-${VERSION}-${BUILD_NUMBER}.noarch.rpm --region eu-west-1"
                    }
                }
            }
        }

        stage ('Execute createrepo') {
            agent {
                label 'cloud-agent-1'
            }
            steps {
                script {
                    withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'backoffice-nonprod']]) {
                        sh "aws s3 sync s3://bnr-jenkins/package-repository/ $WORKSPACE --region eu-west-1"
                        sh """/usr/bin/createrepo_c $WORKSPACE"""
                        sh "aws s3 sync $WORKSPACE s3://bnr-jenkins/package-repository/"
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
                    // Get the current build number
                    def currentBuildNumber = currentBuild.number

                    // Check if there's a previous build
                    if (currentBuildNumber > 1) {
                        // Get information about the previous build
                        def previousBuild = Jenkins.instance.getItemByFullName(env.JOB_NAME).getBuildByNumber(currentBuildNumber - 1)

                        // Check if the previous build is waiting for input
                        if (previousBuild.isBuilding() && previousBuild.getAction(ParametersAction) != null) {
                            echo "Aborting previous build (#${previousBuild.number})"
                            build(job: env.JOB_NAME, parameters: [[$class: 'AbortBuild']])
                        }
                    }

                    input message: 'Approval to Deploy on Staging', submitter: 'Dom AWS Admins'
                }
            }
        }

        stage ('Staging') {
            agent {
                label 'cloud-agent-1'
            }
            steps {
                script {
                    withCredentials([sshUserPrivateKey(credentialsId: 'ec2-user', keyFileVariable: 'SSH_KEY')]) {
                        def remoteIp = '34.242.227.130'
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
        }
    }
}
