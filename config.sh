# Read branch and repo_url from Branch.txt
branch=$(grep '^branch=' "${WORKSPACE}/jenkinsconfig/Branch.txt" | cut -d'=' -f2)
repo_url=$(grep '^giturl=' "${WORKSPACE}/jenkinsconfig/Branch.txt" | cut -d'=' -f2)

# Trim leading and trailing whitespaces
branch=$(echo "$branch" | tr -d '[:space:]')
repo_url=$(echo "$repo_url" | tr -d '[:space:]')

# Set environment variables
export BRANCH="$branch"
export env.REPO_URL="$repo_url"

# Print the values
echo "BRANCH: ${BRANCH}"
echo "REPO_URL: $(REPO_URL}"
