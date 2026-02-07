#!/bin/bash
set -e

CONFIG_FILE="config/repos.json"

TO=$(jq -r '.email.to[]?' "$CONFIG_FILE" | paste -sd "," -)
CC=$(jq -r '.email.cc[]?' "$CONFIG_FILE" | paste -sd "," -)

SUBJECT="Monthly GitHub Report"

HTML_CONTENT=$(cat <<EOF
<html>
<body>
<h2>📊 Monthly GitHub Repository Report</h2>

<table border="1" cellpadding="8" cellspacing="0">
<tr>
  <th>Repository</th>
  <th>Commits</th>
  <th>PR Created</th>
  <th>PR Merged</th>
</tr>

$(cat table_rows.html)

</table>

<br/>
<a href="https://github.com/${GITHUB_REPOSITORY}/actions/runs/${GITHUB_RUN_ID}">
Download Full Report
</a>

</body>
</html>
EOF
)

curl --url "smtp://smtp.gmail.com:587" \
  --ssl-reqd \
  --mail-from "$EMAIL_USER" \
  --mail-rcpt "$TO" \
  ${CC:+--mail-rcpt "$CC"} \
  --user "$EMAIL_USER:$EMAIL_PASS" \
  --upload-file <(
cat <<EOF
From: GitHub Report <$EMAIL_USER>
To: $TO
Cc: $CC
Subject: $SUBJECT
Content-Type: text/html

$HTML_CONTENT
EOF
)
