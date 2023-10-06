#!/bin/bash
set -o pipefail

# extracts and installs the necessary plugins for tap
install_tanzu_cli() {
  TANZU_CLI_TARBALL="tanzu-framework-release/tanzu-framework-linux-amd64.tar.gz"
  mkdir /tmp/tanzu
  tar -zxvf $TANZU_CLI_TARBALL -C /tmp/tanzu > /dev/null

  pushd /tmp/tanzu > /dev/null
    install cli/core/*/tanzu-core-linux_amd64 /usr/local/bin/tanzu
    tanzu plugin install --local cli secret
    tanzu plugin install --local cli package
  popd > /dev/null
}

install_tanzu_apps_plugin() {
  APPS_PLUGIN_TARBALL="apps-cli-plugin-release/tanzu-apps-plugin-linux-amd64-*.tar.gz"
  mkdir /tmp/apps-cli
  tar -zxvf $APPS_PLUGIN_TARBALL -C /tmp/apps-cli > /dev/null
  tanzu plugin install --local /tmp/apps-cli apps
}

# extract the version of a package from the tap-pkg package (i.e. the one bundled with current version of tap)
version_from_tap() {
  local package_yaml=$1

  if [ ! -f $TOOLS_DIR/yq ]; then
    install_yq
  fi

  yq e '.spec.packageRef.versionSelection.constraints' "tap-packages/tap-pkg/config/$package_yaml"
}

# extract the version of a package from its semver (i.e. v1.2.3 -> 1.2.3)
version_from_semver() {
  echo $1 | tr -d 'v'
}

# extract list of versions from dir of yaml files
versions_from_file_names() {
  find "$1" -type f -name '[0-9].*' -printf "%f\n" | sed 's/\.yaml//' | sort -V -r
}

versions_from_package_constellation() {
  find "$1" -type d -name '[0-9].*' -printf "%f\n" | sed "s#$1/##" | sort -V -r
}

version_from_Package_file(){
  local package_yaml=$1

  if [ ! -f $TOOLS_DIR/yq ]; then
    install_yq
  fi

  yq e '.spec.version' "$package_yaml"
}

# extract the image name (and sha) from an image url
image_from_url() {
  local image=$1

  local parts=(${image//\// }) # replace '/' with ' ' and parse into array
  local len=${#parts[@]}
  echo ${parts[$len - 1]}
}

# extract the registry from an image url
registry_from_url() {
  local image=$1

  local parts=(${image//\// }) # replace '/' with ' ' and parse into array
  local len=${#parts[@]}
  echo ${parts[0]}
}

# replace the '+' char in an image tag with '_'
# https://gitlab.eng.vmware.com/tap-architecture/notes/-/blob/main/001-versioning.md#known-issues-for-labels
# https://helm.sh/docs/chart_best_practices/conventions/#version-numbers
sanitize_tag() {
  echo "${1/+/_}"
}

# creates a dir for any required tools to be installed to
setup_tools() {
  export TOOLS_DIR="/tmp/tools"
  mkdir "$TOOLS_DIR"
  export PATH="$PATH:$TOOLS_DIR"
}

install_ko() {
  tar -xzf ko-release/ko_Linux_x86_64.tar.gz -C "$TOOLS_DIR" && chmod +x "$TOOLS_DIR/ko"
  # curl -sSfL "https://github.com/ko-build/ko/releases/download/v0.14.1/ko_0.14.1_Linux_x86_64.tar.gz" > "$TOOLS_DIR"/ko.tar.gz && tar -xzf "$TOOLS_DIR/ko.tar.gz" -C "$TOOLS_DIR" && chmod +x "$TOOLS_DIR/ko"
}

install_ytt() {
  chmod +x ytt-release/ytt-linux-amd64 && mv ytt-release/ytt-linux-amd64 "$TOOLS_DIR/ytt"
}

install_kapp() {
  chmod +x carvel-kapp-release/kapp-linux-amd64 && mv carvel-kapp-release/kapp-linux-amd64 "$TOOLS_DIR/kapp"
}

install_kbld() {
  chmod +x carvel-kbld-release/kbld-linux-amd64 && mv carvel-kbld-release/kbld-linux-amd64 "$TOOLS_DIR/kbld"
}


install_imgpkg() {
  chmod +x carvel-imgpkg-release/imgpkg-linux-amd64 && mv carvel-imgpkg-release/imgpkg-linux-amd64 "$TOOLS_DIR/imgpkg"
}

install_grype() {
  tar -xzf grype-release/grype_*_linux_amd64.tar.gz -C "$TOOLS_DIR" grype && chmod +x "$TOOLS_DIR/grype"
}

install_yq() {
  chmod +x yq-release/yq_linux_amd64 && mv yq-release/yq_linux_amd64 "$TOOLS_DIR/yq"
}

install_crane() {
  tar -xzf go-containerregistry-release/go-containerregistry_Linux_x86_64.tar.gz -C "$TOOLS_DIR" && chmod +x "$TOOLS_DIR/crane"
}

install_tanzu_cli_new(){
  tar -xzf tanzu-cli/tanzu-cli-linux-amd64.tar.gz -C "$TOOLS_DIR" && mv $TOOLS_DIR/v*/tanzu-cli-linux_amd64 "$TOOLS_DIR/tanzu" && chmod +x "$TOOLS_DIR/tanzu"
}

install_jq() {
  chmod +x jq-release/jq-linux64 && mv jq-release/jq-linux64 "$TOOLS_DIR/jq"
}

install_kustomize() {
  tar -xzf kustomize-release/kustomize_*_linux_amd64.tar.gz -C "$TOOLS_DIR" && chmod +x "$TOOLS_DIR/kustomize"
}

install_helm() {
  curl https://get.helm.sh/helm-v3.10.1-linux-amd64.tar.gz | tar -xz --strip-components 1 -C "$TOOLS_DIR" && chmod +x "$TOOLS_DIR/helm"
}

install_woke() {
  tar -xzf woke-release/woke-*-linux-amd64.tar.gz -C "$TOOLS_DIR" &&  mv $TOOLS_DIR/woke-*-linux-amd64/woke "$TOOLS_DIR/woke" && chmod +x "$TOOLS_DIR/woke"
}

install_kubeconfig() {
  mkdir -p $HOME/.kube
  cp "kubeconfigs/cluster-$1.kubeconfig" $HOME/.kube/config
  kubectl config current-context
  kubectl version
}

patch_tkg() {
  if [ ! -f $TOOLS_DIR/kapp ]; then
    install_kapp
  fi

  kapp deploy -a cluster-role -f ci/hack/tkg-kapp-clusterrole.yaml -y
}

_tanzu() {
  echo "tanzu $@"
  tanzu $@
}

get_package_file() {
  local PACKAGE_NAME="$1"
  local PACKAGE_VERS="$2"
  local TAP_PACKAGES_DIR="$3"
  local VERSIONED_PACKAGE_FILE="$TAP_PACKAGES_DIR/$PACKAGE_NAME/$PACKAGE_VERS.yaml"
  local UNVERSIONED_PACKAGE_FILE="$TAP_PACKAGES_DIR/$PACKAGE_NAME/package.yaml"

  if [[ -f $VERSIONED_PACKAGE_FILE ]]; then
    echo "$VERSIONED_PACKAGE_FILE"
  elif [[ $(yq .spec.version "$UNVERSIONED_PACKAGE_FILE") == $PACKAGE_VERS ]]; then
    echo "$UNVERSIONED_PACKAGE_FILE"
  else
    echo "Could not find package YAML file to test with." >&2
    exit 1
  fi
}

install_package_constellation() {
  pushd package-constellation
    export PATH="$PATH:$HOME/go/bin"
    CGO_ENABLED=0 make install
  popd
}

setup_tools
