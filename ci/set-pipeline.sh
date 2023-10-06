#!/bin/sh

set -euo pipefail

#fly --target cartographer login --team-name cartographer --concourse-url https://runway-ci.eng.vmware.com/

cd template
./setup.sh > /tmp/catalog.yaml
fly --target cartographer set-pipeline --pipeline catalog-main --config /tmp/catalog.yaml
cd ..
