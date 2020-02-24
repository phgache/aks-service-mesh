#!/bin/bash
set -e

source ../configuration.sh

az acr import --name $ACR_NAME --source quay.io/phgache/vote-app-frontend:release_1.0.0 -t vote-app-dev/frontend:1.0.0 --force
az acr import --name $ACR_NAME --source quay.io/phgache/vote-app-frontend:release_2.0.0 -t vote-app-dev/frontend:2.0.0 --force

az acr import --name $ACR_NAME --source quay.io/phgache/vote-app-backend:release_1.0.0 -t vote-app-dev/backend:1.0.0 --force
az acr import --name $ACR_NAME --source quay.io/phgache/vote-app-backend:release_2.0.0 -t vote-app-dev/backend:2.0.0 --force

for repo in $(az acr repository list --name $ACR_NAME -o tsv)
do
  echo "**** $repo ****"
  az acr repository show-tags --name $ACR_NAME --repository $repo -o tsv
done