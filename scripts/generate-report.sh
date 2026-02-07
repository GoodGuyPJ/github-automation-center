#!/bin/bash
set -e

REPOS=$(jq -r '.repositories[]' config/repos.json)

START_DATE=$(date -d "1 month ago" +%Y-%m-01)
END_DATE=$(date +%Y-%m-%d)

echo "<html><body>" > report.html
echo "<h2>Monthly GitHub Report</h2>" >> report.html
echo "<table border='1'>" >> report.html
echo "<tr><th>Repo</th><th>Commits</th><th>PR Created</th><th>PR Merged</th></tr>" >> report.html

for repo in $REPOS; do
  echo "Processing $repo"

  COMMITS=$(gh api repos/$repo/commits \
    --paginate \
    -q ".[] | select(.commit.author.date >= \"$START_DATE\")" \
    | wc -l)

  PR_CREATED=$(gh pr list -R $repo \
    --state all \
    --search "created:>$START_DATE" \
    | wc -l)

  PR_MERGED=$(gh pr list -R $repo \
    --state merged \
    --search "merged:>$START_DATE" \
    | wc -l)

  echo "<tr>
  <td>$repo</td>
  <td>$COMMITS</td>
  <td>$PR_CREATED</td>
  <td>$PR_MERGED</td>
  </tr>" >> report.html

done

echo "</table>" >> report.html
echo "</body></html>" >> report.html
