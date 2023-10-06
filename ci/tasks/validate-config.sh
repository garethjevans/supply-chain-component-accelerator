#!/bin/sh

set -ex

cd repo
cp carvel/config.yaml carvel/config.orig

kustomize build config/catalog > carvel/config.yaml

if cmp -s "carvel/config.yaml" "carvel/config.orig"; then
  printf 'The file "%s" up to date\n' "carvel/config.yaml"
else
  printf 'The file "%s" is different from "%s"\n' "carvel/config.yaml" "carvel/config.orig"

  echo "========================================="
  diff carvel/config.yaml carvel/config.orig
  echo "========================================="
  exit 1
fi
