#!/bin/bash
set -e

echo '----------------------------------'
echo '-- Istio                        --'
echo '----------------------------------'

#
# Istio
#

curl -L https://istio.io/downloadIstio | sh -

helm upgrade istio-init ./istio-$ISTIO_VERSION/install/kubernetes/helm/istio-init --install --namespace $ISTIO_NAMESPACE \
  --tiller-namespace kube-system --wait --timeout 900

kubectl wait --for=condition=Complete job -n $ISTIO_NAMESPACE --all

# helm upgrade istio-cni ./istio-$ISTIO_VERSION/install/kubernetes/helm/istio-cni --install \
#   --tiller-namespace kube-system --wait --timeout 900

# avoid move ingressgateway in case of scale out
for node in $(kubectl get nodes -o name)
do
    echo "label node $node"
    kubectl label $node kind=ingressgateway --overwrite
done

# loglevel : trace|debug|info|warning|error|critical|off

helm upgrade istio ./istio-$ISTIO_VERSION/install/kubernetes/helm/istio --install --namespace $ISTIO_NAMESPACE \
  --set global.proxy.logLevel="info" \
  --set global.controlPlaneSecurityEnabled=true \
  --set global.mtls.enabled=true \
  --set global.mtls.auto=true \
  --set sidecarInjectorWebhook.rewriteAppHTTPProbe=true \
  --set grafana.enabled=false \
  --set global.tracer.zipkin.address="jaeger-collector.${JAEGER_NAMESPACE}.svc.cluster.local:9411" \
  --set tracing.enabled=false \
  --set kiali.enabled=false \
  --set prometheus.enabled=false \
  --set gateways.enabled=true \
  --set istio_cni.enabled=false \
  --set ingress.enabled=false \
  --set gateways.istio-ingressgateway.enabled=true \
  --set gateways.istio-ingressgateway.sds.enabled=true \
  --set gateways.istio-ingressgateway.nodeSelector.kind=ingressgateway \
  --set gateways.istio-ingressgateway.autoscaleMin=1 \
  --set gateways.istio-ingressgateway.autoscaleMax=3 \
  --set gateways.istio-egressgateway.enabled=true \
  --set gateways.istio-ingressgateway.sds.resources.requests.cpu=100m	\
  --set gateways.istio-ingressgateway.sds.resources.requests.memory=128Mi	\
  --set gateways.istio-ingressgateway.sds.resources.limits.cpu=500m \
  --set gateways.istio-ingressgateway.sds.resources.limits.memory=512Mi \
  --set gateways.istio-ingressgateway.resources.requests.cpu=100m \
  --set gateways.istio-ingressgateway.resources.requests.memory=128Mi \
  --set gateways.istio-ingressgateway.resources.limits.cpu=300m \
  --set gateways.istio-ingressgateway.resources.limits.memory=512Mi \
  --set gateways.istio-egressgateway.resources.requests.cpu=100m \
  --set gateways.istio-egressgateway.resources.requests.memory=128Mi \
  --set gateways.istio-egressgateway.resources.limits.cpu=200m \
  --set gateways.istio-egressgateway.resources.limits.memory=256Mi \
  --set global.proxy.init.resources.limits.cpu=100m	\
  --set global.proxy.init.resources.limits.memory=50Mi \
  --set global.proxy.init.resources.requests.cpu=10m \
  --set global.proxy.init.resources.requests.memory=10Mi \
  --set global.controlPlaneSecurityEnabled=true \
  --set global.proxy.resources.requests.cpu=100m \
  --set global.proxy.resources.requests.memory=128Mi \
  --set global.proxy.resources.limits.cpu=300m \
  --set global.proxy.resources.limits.memory=256Mi \
  --tiller-namespace kube-system --wait --timeout 900

kubectl apply -f cluster/routes

# rm -Rf istio-$ISTIO_VERSION

#
# Manage DNS Zone
#

NODE_RG=$(az aks show -n $CLUSTER_NAME -g $RESOURCE_GROUP_NAME --query nodeResourceGroup -o tsv)
PUBLIC_IP=$(az network public-ip list -g $NODE_RG --query "[?tags.service=='$ISTIO_NAMESPACE/istio-ingressgateway'].ipAddress" -o tsv)
echo "Public IP : $PUBLIC_IP"

apps=( "grafana" "jaeger" "kiali" "prometheus" "kibana" "apm" "vote-app" )
 
for app in "${apps[@]}"
do
  echo "Add a records for $app in dns zone $DNS_ZONE"
  found=false

  for record in $(az network dns record-set a show --zone-name $DNS_ZONE --resource-group $DNS_ZONE_RG --name $app --query "arecords" -o tsv)
  do
    if [ "$PUBLIC_IP" = "$record" ]
    then
      echo "keep existing $record"
      found=true
    else
      echo "remove $record"
      az network dns record-set a remove-record --zone-name $DNS_ZONE --resource-group $DNS_ZONE_RG --record-set-name $app --ipv4-address $record
    fi
  done

  if [ "$found" = "false" ]
  then
    echo "create $PUBLIC_IP"
    az network dns record-set a add-record --zone-name $DNS_ZONE --resource-group $DNS_ZONE_RG --record-set-name $app --ipv4-address $PUBLIC_IP
  fi
done

az network dns record-set a list --zone-name $DNS_ZONE --resource-group $DNS_ZONE_RG -o table