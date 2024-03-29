#!/usr/bin/env bash
set -euo pipefail

echo "Running OSSPI"

#Pass in append
declare -a baseos_append_flag
if [ "${APPEND+defined}" = defined ] && [ "$APPEND" = 'true' ]; then
  baseos_append_flag=('--baseos-append')
  echo "Using --baseos-append flag"
fi

declare -a ignore_package_flag
if [ "${OSSPI_IGNORE_RULES+defined}" = defined ] && [ -n "$OSSPI_IGNORE_RULES" ]; then
  printf "%s" "$OSSPI_IGNORE_RULES" > "/ignore-rules.yaml"
  ignore_package_flag=("--ignore-package-file" "/ignore-rules.yaml")
  printf "Using configured OSSPI_IGNORE_RULES:\n%s\n\n" "$OSSPI_IGNORE_RULES"
fi

echo "$USERNAME" "$API_KEY" > apiKeyFile

# Get product by name and version to fetch current release ID
PROJECT_RELEASE_REQUEST=$(curl -L -H "Authorization: ApiKey $USERNAME:$API_KEY" "$ENDPOINT/api/public/v1/release?product_name=$PRODUCT&version=$VERSION")
MATCHING_RELEASE=$(echo "$PROJECT_RELEASE_REQUEST" | jq ".results[] | .version |= ascii_downcase | select(.version==\"$(echo $VERSION  | tr '[:upper:]' '[:lower:]')\")")
RELEASE_ID=$(echo "$MATCHING_RELEASE" | jq '.id')
echo "$RELEASE_ID"

## Get ct tracker master package if exists, if not create it and return the ID
MASTER_PACKAGE_REQUEST=$(curl -H "Authorization: ApiKey $USERNAME:$API_KEY" "$ENDPOINT/api/public/v1/master_package/?name=ct-tracker-ubuntu&version=none&repository=Other")
if [ $(echo "$MASTER_PACKAGE_REQUEST" | jq .count) == 1 ]; then
 MASTER_PACKAGE_ID=$(echo "$MASTER_PACKAGE_REQUEST" | jq ".results[].id")
else
  MASTER_PACKAGE_REQUEST=$(curl --request POST -H "Authorization: ApiKey $USERNAME:$API_KEY" --data '{"name":"ct-tracker-ubuntu","version":"none","repository":"Other"}' "$ENDPOINT/api/public/v1/master_package/")
  MASTER_PACKAGE_ID=$(echo "$MASTER_PACKAGE_REQUEST" | jq ".results[].id")
fi
echo "$MASTER_PACKAGE_ID"

## Attach the ct-tracker-ubuntu master package to the osm release ID and return the ct tracker ID
CT_TRACKER_REQUEST=$(curl --request POST -H "Authorization: ApiKey $USERNAME:$API_KEY" -H "Content-Type: application/json" --data "{\"release_id\":\"$RELEASE_ID\",\"master_package_id\":\"$MASTER_PACKAGE_ID\",\"interaction_type_id\":[\"1\"],\"modified\":\"No\"}" "$ENDPOINT/api/public/v1/package/")
if [ $(echo "$CT_TRACKER_REQUEST" | jq -r ".err_code") == 40904  ]; then
  ERROR_MESSAGE=$(echo "$CT_TRACKER_REQUEST" | jq -r ".err_msg")
  CT_TRACKER_ID=$(echo ${ERROR_MESSAGE##* })
else
  CT_TRACKER_ID=$(echo "$CT_TRACKER_REQUEST" | jq ".results[].id")
fi

osspi scan docker-bom \
  "${ignore_package_flag[@]}" \
  --image "$IMAGE":"$TAG" \
  --format manifest \
  --output-dir docker_bom

declare -a osstp_dry_run_flag
if [ "${OSSTP_LOAD_DRY_RUN+defined}" = defined ] && [ "$OSSTP_LOAD_DRY_RUN" = 'true' ]; then
  osstp_dry_run_flag=('-n')
  echo "Dry run mode enabled for osstp-load"
fi

set -x

osstp-load.py \
  "${osstp_dry_run_flag[@]}" \
  -S "$OSM_ENVIRONMENT" \
  -F \
  -A apiKeyFile \
  "${baseos_append_flag[@]}" \
  --noinput \
  --baseos-ct-tracker "$CT_TRACKER_ID" \
  docker_bom/osspi_docker_detect_result.manifest

set +x