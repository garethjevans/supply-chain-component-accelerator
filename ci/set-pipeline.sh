#!/bin/sh

set -euo pipefail

#fly --target cartographer-team login --team-name cartographer-team --concourse-url https://runway-ci.eng.vmware.com/

cd template
./setup.sh > /tmp/catalog.yaml
fly --target cartographer-team set-pipeline --pipeline woke-main --config /tmp/catalog.yaml
cd ..
