#!/bin/bash

set -e

# List of product directories in the repo
PRODUCTS=(
  pingfederate
  pingaccess
  pingdirectory
  pingauthorize
  pingdataconsole
  pingcentral
  pingdatasync
  pingdelegator
  pingdirectoryproxy
  pingintelligence
  ldap-sdk-tools
  pd-replication-timing
  pingtoolkit
)

echo "Building rebased Ping Identity containers using Chainguard images..."

for product in "${PRODUCTS[@]}"; do
  if [ -d "$product" ]; then
    echo "Building $product..."
    docker build --build-arg REGISTRY=localhost --build-arg GIT_TAG=latest --build-arg ARCH=amd64 -t "${product}-rebased:local" "./$product"
  else
    echo "Directory $product not found, skipping..."
  fi
done

echo "All builds completed."
