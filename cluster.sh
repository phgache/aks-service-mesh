#!/bin/bash
set -e

source ./configuration.sh

#
# Generate azure ad objects
# 

#source cluster/generate-creds.sh $PREFIX $AAD_INTEGRATION

#export SERVICE_PRINCIPAL_ID=
#export SERVICE_PRINCIPAL_PASSWORD=

export SERVICE_PRINCIPAL_ID=e35d90c8-30b8-4e4f-bbef-be6ef8253e20
export SERVICE_PRINCIPAL_PASSWORD=10eccdd3-58b4-4b15-851f-32527d5a8c00

#1 Create the cluster
# ./cluster/create-aks.sh

#2 Operators
# ./cluster/operators.sh

#3 Services
# ./cluster/istio.sh
# ./cluster/eck.sh
./cluster/kiali.sh
# ./cluster/jaeger.sh
# ./cluster/prometheus.sh
# ./cluster/grafana.sh
# ./cluster/flagger.sh