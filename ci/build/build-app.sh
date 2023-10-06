#!/usr/bin/env bash

# This script builds the source.apps.tanzu.vmware.com.
# It assumes that kubectl/kapp are configured to point at the lever cluster.

set -euo pipefail

source build-and-package/ci/hack/_helpers.sh

install_kapp
install_yq
install_ytt

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
   --app label:$PROJECT.cartographer.tanzu.vmware.com/build="$BUILD_ID" \
   --diff-changes \
   --wait-timeout 45m0s \
   --file - \
   --yes

mkdir -p manifests/lever

kubectl get request "$PROJECT-carvel-$BUILD_ID" -oyaml | yq '.status' > manifests/lever/carvel-build-status.yml
cat manifests/lever/carvel-build-status.yml

kubectl get request "$PROJECT-git-$BUILD_ID" -oyaml | yq '.status' > manifests/lever/git-build-status.yml
cat manifests/lever/git-build-status.yml

kubectl get request "$PROJECT-scripting-base-$BUILD_ID" -oyaml | yq '.status' > manifests/lever/scripting-base-build-status.yml
cat manifests/lever/scripting-base-build-status.yml

kubectl get request "$PROJECT-bundle-$BUILD_ID" -oyaml | yq '.status' > manifests/lever/controller-bundle-status.yml
cat manifests/lever/controller-bundle-status.yml
