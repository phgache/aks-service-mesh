#!/bin/bash
set -e 

echo '----------------------------------'
echo '-- Prometheus                   --'
echo '----------------------------------'

helm upgrade prometheus --install --namespace $PROMETHEUS_NAMESPACE --tiller-namespace kube-system \
  -f cluster/prometheus-scrape-config.yaml \
  --set kubeStateMetrics.image.tag=$KUBESTATEMETRICS_VERSION \
  --set nodeExporter.image.tag=$NODEEXPORTER_VERSION \
  --set alertmanager.image.tag=$ALERTMANAGER_VERSION \
  --set pushgateway.image.tag=$PUSHGATEWAY_VERSION \
  --set server.image.tag=$PROMETHEUS_VERSION \
  --set alertmanager.persistentVolume.storageClass='premium-lrs-sc' \
  --set pushgateway.persistentVolume.storageClass='premium-lrs-sc' \
  --set server.persistentVolume.storageClass='premium-lrs-sc' \
  --set kubeStateMetrics.resources.limits.cpu=200m \
  --set kubeStateMetrics.resources.limits.memory=256Mi \
  --set kubeStateMetrics.resources.requests.cpu=100m \
  --set kubeStateMetrics.resources.requests.memory=128Mi \
  --set nodeExporter.resources.limits.cpu=200m \
  --set nodeExporter.resources.limits.memory=50Mi \
  --set nodeExporter.resources.requests.cpu=100m \
  --set nodeExporter.resources.requests.memory=30Mi \
  --set alertmanager.resources.limits.cpu=200m \
  --set alertmanager.resources.limits.memory=50Mi \
  --set alertmanager.resources.requests.cpu=100m \
  --set alertmanager.resources.requests.memory=30Mi \
  --set pushgateway.resources.limits.cpu=10m \
  --set pushgateway.resources.limits.memory=32Mi \
  --set pushgateway.resources.requests.cpu=10m \
  --set pushgateway.resources.requests.memory=32Mi \
  --set configmapReload.resources.limits.cpu=10m \
  --set configmapReload.resources.limits.memory=32Mi \
  --set configmapReload.resources.requests.cpu=10m \
  --set configmapReload.resources.requests.memory=32Mi \
  --set server.resources.limits.cpu=1000m \
  --set server.resources.limits.memory=2048Mi \
  --set server.resources.requests.cpu=500m \
  --set server.resources.requests.memory=512Mi \
  stable/prometheus --wait --timeout 900