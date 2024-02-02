#!/bin/sh

set -euo pipefail

#fly --target cartographer-team login --team-name cartographer-team --concourse-url https://runway-ci.eng.vmware.com/

cd template
./setup.sh > /tmp/catalog.yaml
PROJECT=woke-scan
BRANCH=main
fly --target cartographer-team set-pipeline --pipeline $PROJECT-$MAIN --config /tmp/catalog.yaml
cd ..
