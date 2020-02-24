#!/bin/bash
set -e

source ../configuration.sh

FRONT_VERSION=1.0.0
BACK_VERSION=1.0.0

helm upgrade --tiller-namespace kube-system --namespace vote-app-dev --install \
  --set global.flagger=false \
  --set global.healthcheck=false \
  --set global.mesh.istio=true \
  --set frontend.gateway.fqdn=vote-app.$DOMAIN_NAME \
  --set frontend.image.tag=$FRONT_VERSION \
  --set frontend.service.version=$FRONT_VERSION \
  --set frontend.service.retries=0 \
  --set frontend.service.retriesTimeout=0 \
  --set frontend.service.timeout=0 \
  --set frontend.image.repository=$ACR_NAME.azurecr.io/vote-app-dev/frontend \
  --set backend.image.tag=$BACK_VERSION \
  --set backend.service.version=$BACK_VERSION \
  --set backend.service.retries=0 \
  --set backend.service.retriesTimeout=0 \
  --set backend.service.timeout=0 \
  --set backend.image.repository=$ACR_NAME.azurecr.io/vote-app-dev/backend \
  --set redis.service.version=1.0.0 \
  vote-app-dev ../vote-app --wait --timeout 900