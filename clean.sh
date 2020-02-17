
#!/bin/bash
set -e

source ./configuration.sh

for release in $(helm list -q )
do
    echo "purge helm release $release"
    helm delete --purge $release --tiller-namespace kube-system
done

kubectl delete all --all -n $KIALI_NAMESPACE
kubectl delete all --all -n $GRAFANA_NAMESPACE
kubectl delete all --all -n $PROMETHEUS_NAMESPACE
kubectl delete all --all -n $JAEGER_NAMESPACE
kubectl delete all --all -n $ISTIO_NAMESPACE
kubectl delete all --all -n $CERT_MANAGER_NAMESPACE
kubectl delete all --all -n observability
kubectl delete all --all -n vote-app-dev

kubectl delete pvc --all
kubectl delete pv --all
kubectl delete sc premium-lrs-sc --ignore-not-found=true

kubectl delete virtualservice --all -n vote-app-dev
kubectl delete destinationrule --all -n vote-app-dev
kubectl delete gateway --all -n vote-app-dev
