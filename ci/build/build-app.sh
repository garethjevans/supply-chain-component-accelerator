#!/usr/bin/env bash

# This script builds the source.apps.tanzu.vmware.com.
# It assumes that kubectl/kapp are configured to point at the lever cluster.

set -euo pipefail

mkdir -p manifests
# FIXME really should add a licence
# cp repo/LICENSE manifests/LICENSE

cp -R repo/config manifests

ls -l manifests

echo "$LEVER_CONFIG" > lever.kubeconfig
export KUBECONFIG="$(pwd)/lever.kubeconfig"

LEVER_APP_DIR=build-and-package/ci/lever
OFFICIAL=${OFFICIAL:-"true"}
PUBLISH=${PUBLISH:-"true"}
REPO_BRANCH=${REPO_BRANCH:-"unused"}

generate_random_build_id () {
    echo $RANDOM
}

BUILD_ID="$(generate_random_build_id)"

ytt -f "$LEVER_APP_DIR/manifests" \
    -v build_id="$BUILD_ID" \
    -v version="$BUILD_VERSION" \
    -v registry.host="$REGISTRY_HOST" \
    -v registry.path="$REGISTRY_PROJECT" \
    -v repo.branch="$REPO_BRANCH" \
    -v repo.commit="$REPO_COMMIT" \
    --data-value-yaml official="$OFFICIAL" \
    --data-value-yaml publishToConstellation="$PUBLISH" | \
   kapp deploy \
   --app label:woke.cartographer.tanzu.vmware.com/build="$BUILD_ID" \
   --diff-changes \
   --wait-timeout 45m0s \
   --file - \
   --yes

kubectl get request -l "woke.cartographer.tanzu.vmware.com/build=$BUILD_ID" -oyaml
