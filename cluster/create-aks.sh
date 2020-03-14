#!/bin/bash

set -e

echo '----------------------------------'
echo '-- Cluster                      --'
echo '----------------------------------'

# Create a resource group
echo "Create resource group $RESOURCE_GROUP_NAME"
az group create --name $RESOURCE_GROUP_NAME --location $LOCATION

#
# Deploy the cluster
#

TENANT_ID=$(az account show --query tenantId -o tsv)
SUBSCRIPTION_ID=$(az account show --query id -o tsv)

# Create the AKS cluster and specify the virtual network and service principal information
# Enable network policy by using the `--network-policy` parameter

echo "*** Create AKS Cluster ***"
echo RESOURCE_GROUP_NAME : $RESOURCE_GROUP_NAME
echo CLUSTER_NAME : $CLUSTER_NAME

if [ "$AAD_INTEGRATION" = "true" ]
then
  az group deployment create --name aks \
    --resource-group $RESOURCE_GROUP_NAME \
    --mode Complete \
    --template-file cluster/aks-lb-standard-template-aad.json \
    --parameters aksClusterName=$CLUSTER_NAME \
    --parameters aksNetwork="azure" \
    --parameters aksLoadBalancer=$LB \
    --parameters spAppId=$SERVICE_PRINCIPAL_ID \
    --parameters spAppSecret=$SERVICE_PRINCIPAL_PASSWORD \
    --parameters aadTenantId=$TENANT_ID \
    --parameters aadClientAppId=$CLIENT_APPLICATION_ID \
    --parameters aadServerAppId=$SERVER_APPLICATION_ID \
    --parameters aadServerAppSecret=$SERVER_APPLICATION_SECRET \
    --parameters aksAgentCount=$NODE_COUNT \
    --parameters aksAgentVMSize=$VM_SKU \
    --parameters kubernetesVersion=$K8S_VERSION \
    --parameters aksEnableRBAC='true'
else
  az group deployment create --name aks \
    --resource-group $RESOURCE_GROUP_NAME \
    --mode Complete \
    --template-file cluster/aks-lb-standard-template.json \
    --parameters aksClusterName=$CLUSTER_NAME \
    --parameters aksNetwork="azure" \
    --parameters aksLoadBalancer=$LB \
    --parameters spAppId=$SERVICE_PRINCIPAL_ID \
    --parameters spAppSecret=$SERVICE_PRINCIPAL_PASSWORD \
    --parameters aksAgentCount=$NODE_COUNT \
    --parameters aksAgentVMSize=$VM_SKU \
    --parameters kubernetesVersion=$K8S_VERSION \
    --parameters aksEnableRBAC="true"
fi

az aks get-credentials --resource-group $RESOURCE_GROUP_NAME --name $CLUSTER_NAME --admin --overwrite-existing

# Get the resource ID of your ACR instance
az acr create -n $ACR_NAME -g $RESOURCE_GROUP_NAME --sku Basic

ACR_RESOURCE_ID=$(az acr show --resource-group $RESOURCE_GROUP_NAME --name $ACR_NAME --query "id" -o tsv)
RESOURCE_GROUP_ID=$(az group show -n ${RESOURCE_GROUP_NAME} --query id -o tsv)
VNET_ID=$(az network vnet show --resource-group ${RESOURCE_GROUP_NAME} --name ${CLUSTER_NAME}-vnt --query id -o tsv)
SUBNET_ID=$(az network vnet subnet show --resource-group ${RESOURCE_GROUP_NAME} --vnet-name ${CLUSTER_NAME}-vnt --name kubesubnet --query id -o tsv)
AKS_FQDN=$(az aks show -n $CLUSTER_NAME -g $RESOURCE_GROUP_NAME --query fqdn -o tsv)

# Create a role assignment for your AKS cluster to access the ACR instance
#az role assignment create --role AcrPull --assignee $SERVICE_PRINCIPAL_ID --scope $ACR_RESOURCE_ID
#az role assignment create --role Owner --assignee $SERVICE_PRINCIPAL_ID

#
# Namespaces
#

kubectl apply -f cluster/namespaces.yaml

#
# Create a role assignment for DNS Zone 
#

DNS_ZONE_ID=$(az network dns zone show --name $DNS_ZONE --resource-group $DNS_ZONE_RG --query "id" --output tsv)
#az role assignment create --assignee $SERVICE_PRINCIPAL_ID --role "DNS Zone Contributor" --scope $DNS_ZONE_ID
SP_PASSWORD=$(echo -n $SERVICE_PRINCIPAL_PASSWORD | base64)

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: azuredns-config
  namespace: $CERT_MANAGER_NAMESPACE
type: Opaque
data:
  client-secret: $SP_PASSWORD
EOF

# Check roles
az role assignment list --all --assignee $SERVICE_PRINCIPAL_ID -o table

#
# Storage
#

kubectl apply -f cluster/storage.yaml

#
# Helm
#

kubectl apply -f cluster/helm.yaml
helm init --tiller-namespace kube-system --service-account tiller-sa --wait
helm repo add jetstack https://charts.jetstack.io
helm repo add flagger https://flagger.app
helm repo add elastic https://helm.elastic.co
helm repo update

kubectl wait --for=condition=Ready pod -l app=helm,name=tiller -n kube-system

#
# Cert Manager
#

kubectl apply --validate=false -f https://raw.githubusercontent.com/jetstack/cert-manager/release-$CERTMANAGER_VERSION/deploy/manifests/00-crds.yaml

helm upgrade cert-manager --install \
  --namespace $CERT_MANAGER_NAMESPACE \
  --version v$CERTMANAGER_VERSION.0 \
  --set resources.requests.cpu="100m" \
  --set resources.requests.memory="128M" \
  --set resources.limits.cpu="200m" \
  --set resources.limits.memory="256M" \
  jetstack/cert-manager \
  --tiller-namespace kube-system --wait --timeout 900

cat <<EOF | kubectl apply -f -
apiVersion: cert-manager.io/v1alpha2
kind: ClusterIssuer
metadata:
  name: letsencrypt
  namespace: $CERT_MANAGER_NAMESPACE
spec:
  acme:
    email: pierrehenri.gache@outlook.com
    server: https://acme-v02.api.letsencrypt.org/directory
    privateKeySecretRef:
      name: lets-encrypt-app-cert
    solvers:
    - dns01:
        azuredns:
          clientID: $SERVICE_PRINCIPAL_ID
          clientSecretSecretRef:
            name: azuredns-config
            key: client-secret
          subscriptionID: $SUBSCRIPTION_ID
          tenantID: $TENANT_ID
          resourceGroupName: $DNS_ZONE_RG
          hostedZoneName: $DNS_ZONE
          environment: AzurePublicCloud
EOF

cat <<EOF | kubectl apply -f -
apiVersion: cert-manager.io/v1alpha2
kind: ClusterIssuer
metadata:
  name: selfsigned
  namespace: $CERT_MANAGER_NAMESPACE
spec:
  selfSigned: {}
EOF