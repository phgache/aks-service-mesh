#!/bin/bash
set -e

source ./configuration.sh

# FRONT_VERSION=elastic-v1
# BACK_VERSION=elastic-v1

FRONT_VERSION=elastic-v1
BACK_VERSION=elastic-v1

ELASTIC_APM_TOKEN=$(kubectl get secret/apmserver-apm-token -n elastic-system -o go-template='{{index .data "secret-token" | base64decode}}')

helm upgrade --tiller-namespace kube-system --namespace vote-app-dev --install --recreate-pods --force \
  --set global.flagger=false \
  --set global.healthcheck=false \
  --set global.mesh.istio=true \
  --set frontend.gateway.fqdn=vote-app.$DOMAIN_NAME \
  --set frontend.image.tag=$FRONT_VERSION \
  --set frontend.service.version=$FRONT_VERSION \
  --set frontend.service.retries=0 \
  --set frontend.service.retriesTimeout=0 \
  --set frontend.service.timeout=0 \
  --set frontend.autoscale.min=1 \
  --set frontend.autoscale.max=1 \
  --set frontend.image.repository=quay.io/phgache/vote-app-frontend \
  --set backend.image.tag=$BACK_VERSION \
  --set backend.service.version=$BACK_VERSION \
  --set backend.image.repository=quay.io/phgache/vote-app-backend \
  --set backend.autoscale.min=1 \
  --set backend.autoscale.max=1 \
  --set frontend.apm.token=$ELASTIC_APM_TOKEN \
  --set backend.apm.token=$ELASTIC_APM_TOKEN \
  --set redis.service.version=1.0.0 \
  vote-app-dev ./vote-app

kubectl delete pods -n vote-app-dev -l app=frontend
kubectl delete pods -n vote-app-dev -l app=backend