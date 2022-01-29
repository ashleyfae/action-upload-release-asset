#!/bin/bash

set -e
set -o pipefail

# Ensure that the GITHUB_TOKEN secret is included
if [[ -z "$GITHUB_TOKEN" ]]; then
  echo "Set the GITHUB_TOKEN env variable."
  exit 1
fi

# Ensure that the file path is present.
if [[ -z "$FILE" ]]; then
  echo "You must include the path to the file to upload."
  exit 1
fi

# Prepare the headers
AUTH_HEADER="Authorization: token ${GITHUB_TOKEN}"
CONTENT_LENGTH_HEADER="Content-Length: $(stat -c%s "${FILE}")"
CONTENT_TYPE_HEADER="Content-Type: ${FILE_TYPE}"

# Build the Upload URL from the various pieces
RELEASE_ID=$(jq --raw-output '.release.id' $GITHUB_EVENT_PATH)
if [[ -z "${RELEASE_ID}" ]]; then
  echo "There was no release ID in the GitHub event. Are you using the release event type?"
  exit 1
fi

FILENAME=$(basename $FILE)
UPLOAD_URL="https://uploads.github.com/repos/${GITHUB_REPOSITORY}/releases/${RELEASE_ID}/assets?name=${FILENAME}"
echo "$UPLOAD_URL"

response=$(
# Upload the file
curl \
  -f \
  -sSL \
  -XPOST \
  -H "${AUTH_HEADER}" \
  -H "${CONTENT_LENGTH_HEADER}" \
  -H "${CONTENT_TYPE_HEADER}" \
  --upload-file "${FILE}" \
  "${UPLOAD_URL}"
)

echo "${response}"

ASSET_URL=$(echo ${response} | jq '.url')
ASSET_ID=$(echo ${response} | jq '.id')

if [ -z "$ASSET_URL" ]; then
  echo "No asset URL in response."
  exit 1
else
  echo "::set-output name=asset-url::${ASSET_URL}"
  echo "::set-output name=asset-id::${ASSET_ID}"
fi
