#!/bin/bash
set -e

#
# Generate azure ad objects
# 

# source cluster/generate-creds.sh $PREFIX $AAD_INTEGRATION

#export SERVICE_PRINCIPAL_ID=
#export SERVICE_PRINCIPAL_PASSWORD=

source ./configuration.sh

#1 Create the cluster
# ./cluster/create-aks.sh

#2 Operators
# ./cluster/operators.sh

#3 Services
./cluster/istio.sh
# ./cluster/kiali.sh
# ./cluster/jaeger.sh
# ./cluster/prometheus.sh
# ./cluster/grafana.sh
# ./cluster/flagger.sh