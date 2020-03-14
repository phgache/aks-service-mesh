
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
  kubectl create -f https://raw.githubusercontent.com/jaegertracing/jaeger-operator/master/deploy/crds/jaegertracing.io_jaegers_crd.yaml -n ${JAEGER_NAMESPACE}
  kubectl create -f https://raw.githubusercontent.com/jaegertracing/jaeger-operator/master/deploy/service_account.yaml -n ${JAEGER_NAMESPACE}
  kubectl create -f https://raw.githubusercontent.com/jaegertracing/jaeger-operator/master/deploy/role.yaml -n ${JAEGER_NAMESPACE}
  kubectl create -f https://raw.githubusercontent.com/jaegertracing/jaeger-operator/master/deploy/role_binding.yaml -n ${JAEGER_NAMESPACE}
  kubectl create -f https://raw.githubusercontent.com/jaegertracing/jaeger-operator/master/deploy/operator.yaml -n ${JAEGER_NAMESPACE}
fi

kubectl wait --for=condition=Ready pod -l name=jaeger-operator -n ${JAEGER_NAMESPACE}
kubectl get deployment jaeger-operator -n ${JAEGER_NAMESPACE}

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
kubectl get pods -n elastic-system

