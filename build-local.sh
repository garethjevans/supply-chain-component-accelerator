#!/bin/bash

set -euo pipefail

ENV=$1

SVC_ADDRESS=$(kubectl get -n accelerator-system service/acc-server | grep -v NAME | awk '{print $4}')
OUTPUT=generated/$ENV

tanzu accelerator generate-from-local \
  --accelerator-path supply-chain-component-accelerator=. \
  --fragment-names tap-workload \
  --options-file tests/$ENV.json \
  --output-dir "$OUTPUT" \
  --server-url http://accelerator.$SVC_ADDRESS.nip.io

tree $OUTPUT

#cat $OUTPUT/accelerator-log.md
#cat $OUTPUT/cluster-supply-chain.yaml

DIRS="config build-templates ci"
for DIR in $DIRS; do
	echo "================================================"
	echo "$DIR Delta"
	set +e
	/usr/bin/diff -r $OUTPUT/$DIR ./$DIR
	set -e
done

cd $OUTPUT

make carvel package

echo "================================================"
grep -R catalog * | grep -v accelerator-log.md
echo "================================================"
grep -R cartographer * | grep -v accelerator-log.md
echo "================================================"
grep -R supply-chain-choreographer * | grep -v accelerator-log.md
echo "================================================"
grep -R woke * | grep -v accelerator-log.md
echo "================================================"

