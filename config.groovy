def Extract() {

def branch = sh(script: "cat ${WORKSPACE}/jenkinsconfig/Branch.txt | grep '^branch=' | cut -d'=' -f2", returnStdout: true).trim()
def repo_url = sh(script: "cat ${WORKSPACE}/jenkinsconfig/Branch.txt | grep '^giturl=' | cut -d'=' -f2", returnStdout: true).trim()

env.BRANCH = branch
env.REPO_URL = repo_url

// Print the values
echo "BRANCH: ${env.BRANCH}"
echo "REPO_URL: ${env.REPO_URL}"
}
return this
