
#!/bin/bash
set -e

echo '----------------------------------'
echo '-- Operators                    --'
echo '----------------------------------'

#
# Jaeger Operator
#

if [ $(kubectl get crd jaegers.jaegertracing.io --ignore-not-found=true -o name) ]
then
  echo "Jaeger Operator already setup"
else
  mkdir -p cluster/jaeger-operator/base
  curl https://raw.githubusercontent.com/jaegertracing/jaeger-operator/master/deploy/crds/jaegertracing.io_jaegers_crd.yaml > cluster/jaeger-operator/base/jaegertracing.io_jaegers_crd.yaml
  curl https://raw.githubusercontent.com/jaegertracing/jaeger-operator/master/deploy/service_account.yaml > cluster/jaeger-operator/base/service_account.yaml
  curl https://raw.githubusercontent.com/jaegertracing/jaeger-operator/master/deploy/role.yaml > cluster/jaeger-operator/base/role.yaml
  curl https://raw.githubusercontent.com/jaegertracing/jaeger-operator/master/deploy/role_binding.yaml > cluster/jaeger-operator/base/role_binding.yaml
  curl https://raw.githubusercontent.com/jaegertracing/jaeger-operator/master/deploy/operator.yaml > cluster/jaeger-operator/base/operator.yaml
  curl https://raw.githubusercontent.com/jaegertracing/jaeger-operator/master/deploy/cluster_role.yaml > cluster/jaeger-operator/base/cluster_role.yaml 
  curl https://raw.githubusercontent.com/jaegertracing/jaeger-operator/master/deploy/cluster_role_binding.yaml > cluster/jaeger-operator/base/cluster_role_binding.yaml
  kubectl apply -k cluster/jaeger-operator
fi

kubectl wait --for=condition=Ready pod -l name=jaeger-operator -n ${OPERATOR_NAMESPACE}
kubectl get deployment jaeger-operator -n ${OPERATOR_NAMESPACE}

#
# Kiali Operator
#

if [ $(kubectl get crd kialis.kiali.io --ignore-not-found=true -o name) ]
then
  echo "Kiali Operator already setup"
else
  curl -L https://git.io/getLatestKialiOperator | bash -s -- --operator-install-kiali false --operator-namespace ${KIALI_NAMESPACE}
fi

kubectl wait --for=condition=Ready pod -l app=kiali-operator -n ${KIALI_NAMESPACE}
kubectl get deployment kiali-operator -n ${KIALI_NAMESPACE}

#
# ECK Operator
#

kubectl apply -f https://download.elastic.co/downloads/eck/1.0.1/all-in-one.yaml
kubectl wait --for=condition=Ready pod -l control-plane=elastic-operator -n ${ELASTIC_NAMESPACE}

kubectl apply -f cluster/namespaces.yaml
