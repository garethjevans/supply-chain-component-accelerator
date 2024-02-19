#!/bin/bash

set -ex
YTT=ytt
mkdir -p pipeline

"$YTT" \
  -f build-and-package/ci/common/resources.lib.yml \
  -f build-and-package/ci/common/resource_types.lib.yml \
  -f build-and-package/ci/build/build.yml \
  -f build-and-package/ci/repo/setup-repo.yml \
  -f build-and-package/ci/template/pipeline-template.yml \
  --data-value build_and_package_branch=main \
  --data-value project=woke-scan > pipeline/pipeline.yml
