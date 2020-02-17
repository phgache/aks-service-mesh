#!/bin/bash
set -e

echo '----------------------------------'
echo '-- Jaeger                       --'
echo '----------------------------------'

helm upgrade elasticsearch elastic/elasticsearch --install --namespace $JAEGER_NAMESPACE \
  --set replicas=2 \
  --set volumeClaimTemplate.storageClassName='premium-lrs-sc' \
  --set esJavaOpts="-Xmx512m -Xms512m" \
  --set resources.requests.cpu="100m" \
  --set resources.requests.memory="1G" \
  --set resources.limits.cpu="1000m" \
  --set resources.limits.memory="1G" \
  --tiller-namespace kube-system --wait --timeout 900

#
# Jaeger
#

cat <<EOF | kubectl apply -f -
apiVersion: jaegertracing.io/v1
kind: Jaeger
metadata:
  name: jaeger
  namespace: $JAEGER_NAMESPACE
spec:
  agent:
    strategy: DaemonSet
  storage:
    type: elasticsearch
    options:
      es:
        server-urls: http://elasticsearch-master:9200
  resources:
    requests:
      memory: "64Mi"
      cpu: "250m"
    limits:
      memory: "128Mi"
      cpu: "250m"
  ingress:
    enabled: false
EOF

sleep 30

kubectl wait --for=condition=Ready pod -l app.kubernetes.io/component=all-in-one -n $JAEGER_NAMESPACE

# https://github.com/jaegertracing/jaeger-operator/issues/742
kubectl patch svc jaeger-query --type='json' --patch='[{"op": "replace", "path": "/spec/ports/0/name", "value":"http-query"}]' -n ${JAEGER_NAMESPACE}