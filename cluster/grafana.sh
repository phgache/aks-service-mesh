#!/bin/bash
set -e 

echo '----------------------------------'
echo '-- Grafana                      --'
echo '----------------------------------'

kubectl apply -f cluster/grafana-config.yaml --namespace $GRAFANA_NAMESPACE

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: grafana-admin
  namespace: $GRAFANA_NAMESPACE
  labels:
    app: grafana
type: Opaque
data:
  admin-user: $GRAFANA_USERNAME
  admin-password: $GRAFANA_PASSPHRASE
EOF

helm upgrade grafana --install --namespace $GRAFANA_NAMESPACE --tiller-namespace kube-system \
  --set image.tag=$GRAFANA_VERSION \
  --set persistence.enabled=true \
  --set persistence.type=pvc \
  --set persistence.storageClassName='premium-lrs-sc' \
  --set sidecar.dashboards.enabled=true \
  --set sidecar.dashboards.label='grafana_dashboard' \
  --set sidecar.datasources.enabled=true \
  --set sidecar.datasources.label='grafana_datasource' \
  --set admin.existingSecret='grafana-admin' \
  --set initChownData.resources.limits.cpu=100m \
  --set initChownData.resources.limits.memory=64Mi \
  --set initChownData.resources.requests.cpu=50m \
  --set initChownData.resources.requests.memory=32Mi \
  --set sidecar.resources.limits.cpu=100m \
  --set sidecar.resources.limits.memory=64Mi \
  --set sidecar.resources.requests.cpu=50m \
  --set sidecar.resources.requests.memory=32Mi \
  --set resources.limits.cpu=500m \
  --set resources.limits.memory=512Mi \
  --set resources.requests.cpu=250m \
  --set resources.requests.memory=256Mi \
  --set service.port=80 \
  --set service.portName=http-grafana \
  --set service.targetPort=3000 \
  stable/grafana --wait --timeout 900
