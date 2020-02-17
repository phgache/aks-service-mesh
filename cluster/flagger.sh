#!/bin/bash
set -e

echo '----------------------------------'
echo '-- Flagger                      --'
echo '----------------------------------'

kubectl apply -f https://raw.githubusercontent.com/weaveworks/flagger/master/artifacts/flagger/crd.yaml

helm upgrade --install flagger flagger/flagger \
  --namespace=${ISTIO_NAMESPACE} \
  --set crd.create=false \
  --set meshProvider=istio \
  --set resources.limits.cpu=250m \
  --set resources.limits.memory=256Mi \
  --set resources.requests.cpu=100m \
  --set resources.requests.memory=128Mi \
  --set metricsServer=http://prometheus-server.${PROMETHEUS_NAMESPACE}.svc:80