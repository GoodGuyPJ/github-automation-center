#!/bin/bash

TO=$(jq -r '.email.to[]' config/repos.json | paste -sd "," -)
CC=$(jq -r '.email.cc[]' config/repos.json | paste -sd "," -)

SUBJECT="Monthly GitHub Report"

curl --url "smtp://smtp.gmail.com:587" \
  --ssl-reqd \
  --mail-from "$EMAIL_USER" \
  --mail-rcpt "$TO" \
  --upload-file <(
cat <<EOF
From: GitHub Report <$EMAIL_USER>
To: $TO
Cc: $CC
Subject: $SUBJECT
Content-Type: text/html

<h2>Monthly GitHub Report</h2>
<p>Download full report from GitHub Actions Artifact.</p>

<a href="https://github.com/${GITHUB_REPOSITORY}/actions/runs/${GITHUB_RUN_ID}">
<button>Download Report</button>
</a>

EOF
)
