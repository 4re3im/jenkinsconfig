def Extract() {

def branch = sh(script: "cat ${WORKSPACE}/jenkinsconfig/Branch.txt | grep '^branch=' | cut -d'=' -f2", returnStdout: true).trim()
def repo_url = sh(script: "cat ${WORKSPACE}/jenkinsconfig/Branch.txt | grep '^giturl=' | cut -d'=' -f2", returnStdout: true).trim()

env.BRANCH = branch
env.REPO_URL = repo_url

// Print the values
echo "BRANCH: ${env.BRANCH}"
echo "REPO_URL: ${env.REPO_URL}"

dir("${WORKSPACE}/application"){
sshagent(['sshgithub']) {
    git branch: env.BRANCH, credentialsId: 'sshgithub', url: env.REPO_URL
    }
}

def version = sh(script: "cat ${WORKSPACE}/application/version.txt | grep '^version=' | cut -d'=' -f2", returnStdout: true).trim()
def packageName = sh(script: "cat ${WORKSPACE}/application/version.txt | grep '^package=' | cut -d'=' -f2", returnStdout: true).trim()

env.VERSION = version
env.PACKAGE_NAME = packageName

echo "Version: ${env.VERSION}"
echo "Package: ${env.PACKAGE_NAME}"
}
return this
