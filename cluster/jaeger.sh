#!/bin/bash
set -e

echo '----------------------------------'
echo '-- Jaeger                       --'
echo '----------------------------------'

#
# Jaeger
#

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: es-secret
  namespace: $JAEGER_NAMESPACE
type: Opaque
data:
  ES_USERNAME: $ELASTIC_USERNAME
  ES_PASSWORD: $ELASTIC_PASSPHRASE
EOF

cat <<EOF | kubectl apply -f -
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: jaeger-collector
  namespace: $JAEGER_NAMESPACE
spec:
  host: jaeger-collector.${JAEGER_NAMESPACE}.svc.cluster.local
  trafficPolicy:
    connectionPool:
      http:
        http2MaxRequests: 10000
        maxRequestsPerConnection: 10000
    portLevelSettings:
    - port:
        number: 9411
      tls:
        mode: DISABLE
    - port:
        number: 14250
      tls:
        mode: ISTIO_MUTUAL
    - port:
        number: 14267
      tls:
        mode: ISTIO_MUTUAL
    - port:
        number: 14268
      tls:
        mode: ISTIO_MUTUAL
EOF

cat <<EOF | kubectl apply -f -
apiVersion: jaegertracing.io/v1
kind: Jaeger
metadata:
  name: jaeger
  namespace: $JAEGER_NAMESPACE
spec:
  strategy: production
  collector:
    maxReplicas: 1
  annotations:
    sidecar.istio.io/inject: "true"
  storage:
    type: elasticsearch
    dependencies:
      enabled: true
      schedule: "55 23 * * *"
      resources:
        requests:
          memory: 4096Mi
        limits:
          memory: 4096Mi
    options:
      es:
        server-urls: http://elasticsearch-es-http.elastic-system.svc.cluster.local:9200
    secretName: es-secret
  resources:
    requests:
      memory: "64Mi"
      cpu: "250m"
    limits:
      memory: "512Mi"
      cpu: "500m"
  ingress:
    enabled: false
EOF

# sleep 30

# kubectl wait --for=condition=Ready pod -l app.kubernetes.io/component=all-in-one -n $JAEGER_NAMESPACE

# # https://github.com/jaegertracing/jaeger-operator/issues/742
# kubectl patch svc jaeger-query --type='json' --patch='[{"op": "replace", "path": "/spec/ports/0/name", "value":"http-query"}]' -n ${JAEGER_NAMESPACE}