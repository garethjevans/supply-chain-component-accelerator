#!/bin/bash

set -ex

YTT=ytt

"$YTT" \
  -f ../common/resources.lib.yml \
  -f ../common/resource_types.lib.yml \
  -f ../build/build.yml \
  -f ../repo/setup-repo.yml \
  -f ../template/pipeline-template.yml \
  --data-value build_and_package_branch=main \
  --data-value project=woke-scan
