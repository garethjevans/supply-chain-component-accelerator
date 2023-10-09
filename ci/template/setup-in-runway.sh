#!/bin/bash

set -ex
mkdir -p /tmp/tools
mv ytt-release/ytt-linux-amd64 /tmp/tools/ytt && chmod +x /tmp/tools/ytt
export YTT=/tmp/tools/ytt
"$YTT" version
mkdir -p pipelines

"$YTT" \
  -f build-and-package/ci/common/resources.lib.yml \
  -f build-and-package/ci/common/resource_types.lib.yml \
  -f build-and-package/ci/build/build.yml \
  -f build-and-package/ci/repo/setup-repo.yml \
  -f build-and-package/ci/template/pipeline-template.yml \
  --data-value build_and_package_branch=main > pipeline/pipeline.yml
