pipeline {
    agent none
    
    options {
        skipDefaultCheckout()
    }

    stages {
        /*
        //This cleanup will only be used when label 'built-in' is used 
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
                        sh "aws s3 rm s3://bnr-jenkins/package-repository/repodata --recursive --region eu-west-1"
                        sh "aws s3 sync $WORKSPACE/application/RPMS/noarch/repodata s3://bnr-jenkins/package-repository/repodata --region eu-west-1"
                    }
                }
            }
        }

        stage ('Deploy on Staging') {
            agent {
                label 'built-in'
            }
            steps {
                input message: 'Approval to Deploy on Staging', submitter: 'Dom AWS Admins'
            }
        }

        stage ('Staging') {
            agent {
                label 'cloud-agent-1'
            }
            steps {
                script {
                    withCredentials([sshUserPrivateKey(credentialsId: 'ec2-user', keyFileVariable: 'SSH_KEY')]) {
                        def remoteIp = '3.252.135.121'
                        sh """
                        ssh -o StrictHostKeyChecking=no -l ec2-user -i \${SSH_KEY} $remoteIp 'whoami'
                        ssh -l ec2-user -i \${SSH_KEY} $remoteIp 'sudo yum clean all'
                        ssh -l ec2-user -i \${SSH_KEY} $remoteIp 'sudo yum check-update || :'
                        ssh -l ec2-user -i \${SSH_KEY} $remoteIp 'sudo yum -y remove cup-tng-go'
                        ssh -l ec2-user -i \${SSH_KEY} $remoteIp 'sudo yum -y install cup-tng-go-${BUILD_NUMBER}'
                        """
                    }
                }
            }
        }
    }
}
