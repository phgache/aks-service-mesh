export PREFIX=demoaks

export KIALI_NAMESPACE=kiali-system
export GRAFANA_NAMESPACE=grafana-system
export PROMETHEUS_NAMESPACE=prometheus-system
export JAEGER_NAMESPACE=jaeger-system
export ISTIO_NAMESPACE=istio-system
export CERT_MANAGER_NAMESPACE=cert-manager

export LOCATION=westeurope
export RESOURCE_GROUP_NAME=${PREFIX}-rg
export CLUSTER_NAME=${PREFIX}-cluster
export ACR_NAME=${PREFIX}reg
export AAD_INTEGRATION=false

export DNS_ZONE=aks-demo.org
export DNS_ZONE_RG=aksdomainname-rg
export DOMAIN_NAME=aks-demo.org

export NODE_COUNT=3
export LB="standard"
export K8S_VERSION="1.15.7"
export VM_SKU="Standard_F4s_v2"

export CERTMANAGER_VERSION=0.12

export ISTIO_VERSION=1.4.4
export KIALI_VERSION=v1.13.1

export KUBESTATEMETRICS_VERSION=v1.9.2
export NODEEXPORTER_VERSION=v0.18.1
export ALERTMANAGER_VERSION=v0.20.0
export PUSHGATEWAY_VERSION=v1.0.1
export PROMETHEUS_VERSION=v2.16.0

export GRAFANA_VERSION=6.6.1

export PASSWORD="meetup2020"

export GRAFANA_USERNAME=$(echo -n "grafana" | base64)
export GRAFANA_PASSPHRASE=$(echo -n $PASSWORD | base64)

export KIALI_USERNAME=$(echo -n "kiali" | base64)
export KIALI_PASSPHRASE=$(echo -n $PASSWORD | base64)

export SP_PASSWORD=$(openssl rand -base64 16 | md5 | head -c16;echo)

#
# Generate azure ad objects
# 

source cluster/generate-creds.sh $PREFIX $AAD_INTEGRATION

#export SERVICE_PRINCIPAL_ID=
#export SERVICE_PRINCIPAL_PASSWORD=