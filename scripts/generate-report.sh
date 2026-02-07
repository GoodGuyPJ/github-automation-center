#!/bin/bash
set -e

CONFIG_FILE="config/repos.json"

# Validate config
if [ ! -f "$CONFIG_FILE" ]; then
  echo "❌ Missing config/repos.json"
  exit 1
fi

REPOS=$(jq -r '.repositories[]?' "$CONFIG_FILE")

if [ -z "$REPOS" ]; then
  echo "❌ No repositories found in config"
  exit 1
fi

START_DATE=$(date -d "1 month ago" +%Y-%m-%d)

TABLE_ROWS=""

TOTAL_COMMITS=0
TOTAL_PR_CREATED=0
TOTAL_PR_MERGED=0

echo "📊 Generating report..."

for repo in $REPOS; do
  echo "Processing $repo"

  # -------------------------
  # COMMITS
  # -------------------------
  COMMITS=$(gh api \
    -H "Accept: application/vnd.github+json" \
    "/search/commits?q=repo:$repo+committer-date:>=$START_DATE" 2>/dev/null \
    | jq '.total_count' 2>/dev/null || echo 0)

  # -------------------------
  # PR CREATED
  # -------------------------
  PR_CREATED=$(gh pr list -R "$repo" \
    --search "created:>$START_DATE" \
    --json number 2>/dev/null \
    | jq length 2>/dev/null || echo 0)

  # -------------------------
  # PR MERGED
  # -------------------------
  PR_MERGED=$(gh pr list -R "$repo" \
    --state merged \
    --search "merged:>$START_DATE" \
    --json number 2>/dev/null \
    | jq length 2>/dev/null || echo 0)

  # Add totals
  TOTAL_COMMITS=$((TOTAL_COMMITS + COMMITS))
  TOTAL_PR_CREATED=$((TOTAL_PR_CREATED + PR_CREATED))
  TOTAL_PR_MERGED=$((TOTAL_PR_MERGED + PR_MERGED))

  # Add table row
  TABLE_ROWS+="
  <tr>
    <td><a href='https://github.com/$repo'>$repo</a></td>
    <td>$COMMITS</td>
    <td>$PR_CREATED</td>
    <td>$PR_MERGED</td>
  </tr>
  "
done

# Totals row
TABLE_ROWS+="
<tr style='font-weight:bold;background:#eef2f7'>
  <td>Total</td>
  <td>$TOTAL_COMMITS</td>
  <td>$TOTAL_PR_CREATED</td>
  <td>$TOTAL_PR_MERGED</td>
</tr>
"

# Save rows separately (for email embed)
echo "$TABLE_ROWS" > table_rows.html

# -------------------------
# FULL HTML REPORT
# -------------------------

cat <<EOF > report.html
<html>
<head>
<style>
body {
  font-family: Arial, sans-serif;
  background:#f6f8fa;
  padding:20px;
}

.container {
  background:white;
  padding:20px;
  border-radius:10px;
  box-shadow:0 2px 6px rgba(0,0,0,0.1);
}

h2 {
  text-align:center;
  color:#24292e;
}

table {
  width:100%;
  border-collapse:collapse;
  margin-top:20px;
}

th {
  background:#24292e;
  color:white;
  padding:12px;
  text-align:left;
}

td {
  padding:10px;
  border-bottom:1px solid #ddd;
}

tr:nth-child(even) {
  background:#f2f2f2;
}

a {
  color:#0969da;
  text-decoration:none;
}

</style>
</head>

<body>
<div class="container">

<h2>📊 Monthly GitHub Report</h2>
<p>Report Period: Since $START_DATE</p>

<table>
<tr>
  <th>Repository</th>
  <th>Commits</th>
  <th>PR Created</th>
  <th>PR Merged</th>
</tr>

$TABLE_ROWS

</table>

</div>
</body>
</html>
EOF

echo "✅ Report generated successfully"
