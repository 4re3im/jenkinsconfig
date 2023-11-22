pipeline {
    agent none
    
    options {
        skipDefaultCheckout()
    }

    stages {
        stage('Build Package') {
            agent {
                label "built-in"
            }  
            steps {
                script {
                                  
                    sh '''
                    mkdir -p "${WORKSPACE}/jenkinsconfig"
                    '''
                    
                    dir("${WORKSPACE}/jenkinsconfig") {
                        sshagent(['sshgithub']) {
                            git branch: 'main', credentialsId: 'sshgithub', url: 'git@github.com:4re3im/jenkinsconfig.git'
                        }
                    }
                    
                    // Loading and executing the config script
                    def configScript = load "${WORKSPACE}/jenkinsconfig/config.groovy"
                    configScript.Extract()
                    
                    
                    sh """
                        ls -la ${WORKSPACE}/jenkinsconfig
                        pwd
                        chmod 755 jenkinsconfig/rpmcreation.sh
                        ls -la ${WORKSPACE}/jenkinsconfig
                        ./jenkinsconfig/rpmcreation.sh
                        """

                    
                    // Push to S3
                    withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', accessKeyVariable: 'AWS_ACCESS_KEY_ID', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY', credentialsId: 'AWS-BONP']]) {
                        sh "aws s3 cp $WORKSPACE/RPMS/noarch/${PACKAGE_NAME}-${VERSION}-${BUILD_NUMBER}.noarch.rpm s3://bnr-jenkins/package-repository/${PACKAGE_NAME}-${VERSION}-${BUILD_NUMBER}.noarch.rpm --region eu-west-1"
                    }
                }
            }
        }
        stage ('Copy RPM from S3') {
            agent {
                label 'built-in'
            }
            steps {
                input message: 'Approval to Copy from S3', submitter: 'Dom AWS Admins'
            }
        }
        stage ('RPM') {
            parallel {
                stage ('Downloading RPM from S3') {
                    agent {
                        label 'cloud-agent-1'
                    }
                    steps {
                        script {
                            withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', accessKeyVariable: 'AWS_ACCESS_KEY_ID', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY', credentialsId: 'AWS-BONP']]) {
                            sh "aws s3 cp s3://bnr-jenkins/package-repository/${PACKAGE_NAME}-${VERSION}-${BUILD_NUMBER}.noarch.rpm $WORKSPACE/RPMS/noarch/ --region eu-west-1"    
                            }
                        }
                        
                    } 
            
                }
                stage ('Donwloading RPM for transfer') {
                    agent {
                        label 'built-in'
                    }
                    steps {
                        echo 'Transfering RPM to other server'
                    }
                }
            }
        }
    }
}        
