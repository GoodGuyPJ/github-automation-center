#!/bin/bash
set -e

CONFIG_FILE="config/repos.json"
REPOS=$(jq -r '.repositories[]' $CONFIG_FILE)

START_DATE=$(date -d "1 month ago" +%Y-%m-%d)

echo "<html><body>" > report.html
echo "<h2>Monthly GitHub Report</h2>" >> report.html
echo "<table border='1'>" >> report.html
echo "<tr><th>Repository</th><th>Total Commits</th><th>PR Created</th><th>PR Merged</th></tr>" >> report.html

for repo in $REPOS; do
  echo "Processing $repo"

  # ✅ Get commits count using search API (more reliable)
  COMMITS=$(gh api \
    -H "Accept: application/vnd.github+json" \
    "/search/commits?q=repo:$repo+committer-date:>=$START_DATE" \
    | jq '.total_count')

  # ✅ PR Created
  PR_CREATED=$(gh pr list -R $repo --search "created:>$START_DATE" --json number | jq length)

  # ✅ PR Merged
  PR_MERGED=$(gh pr list -R $repo --state merged --search "merged:>$START_DATE" --json number | jq length)

  echo "<tr>
    <td>$repo</td>
    <td>$COMMITS</td>
    <td>$PR_CREATED</td>
    <td>$PR_MERGED</td>
  </tr>" >> report.html
done

echo "</table></body></html>" >> report.html
