#!/bin/bash
set -e

VERSION=v1

source ./configuration.sh

#az acr build --registry $ACR_NAME --image $ACR_NAME.azurecr.io/vote-app-dev/backend:$VERSION vote-app/charts/backend/app
docker build -t quay.io/phgache/vote-app-backend:elastic-$VERSION vote-app/charts/backend/app-elastic
docker build -t quay.io/phgache/vote-app-backend:jaeger-$VERSION vote-app/charts/backend/app-jaeger
docker push quay.io/phgache/vote-app-backend:elastic-$VERSION
docker push quay.io/phgache/vote-app-backend:jaeger-$VERSION

#az acr build --registry $ACR_NAME --image $ACR_NAME.azurecr.io/vote-app-dev/frontend:$VERSION vote-app/charts/frontend/app
docker build -t quay.io/phgache/vote-app-frontend:elastic-$VERSION  vote-app/charts/frontend/app-elastic
docker build -t quay.io/phgache/vote-app-frontend:jaeger-$VERSION  vote-app/charts/frontend/app-jaeger
docker push quay.io/phgache/vote-app-frontend:elastic-$VERSION
docker push quay.io/phgache/vote-app-frontend:jaeger-$VERSION