
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
  kubectl create -f https://raw.githubusercontent.com/jaegertracing/jaeger-operator/master/deploy/crds/jaegertracing.io_jaegers_crd.yaml
  kubectl create -f https://raw.githubusercontent.com/jaegertracing/jaeger-operator/master/deploy/service_account.yaml
  kubectl create -f https://raw.githubusercontent.com/jaegertracing/jaeger-operator/master/deploy/role.yaml
  kubectl create -f https://raw.githubusercontent.com/jaegertracing/jaeger-operator/master/deploy/role_binding.yaml
  kubectl create -f https://raw.githubusercontent.com/jaegertracing/jaeger-operator/master/deploy/operator.yaml
fi

kubectl wait --for=condition=Ready pod -l name=jaeger-operator -n observability
kubectl get deployment jaeger-operator -n observability

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
