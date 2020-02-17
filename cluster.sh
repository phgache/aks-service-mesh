#!/bin/bash
set -e

source ./configuration.sh

#1 Create the cluster
./cluster/create-aks.sh

#2 Operators
./cluster/operators.sh

#3 Services
./cluster/istio.sh
./cluster/kiali.sh
./cluster/jaeger.sh
./cluster/prometheus.sh
./cluster/grafana.sh
./cluster/flagger.sh