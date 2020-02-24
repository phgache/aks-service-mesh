#!/bin/bash
set -e

VERSION=1.0.0

source ./configuration.sh

az acr build --registry $ACR_NAME --image $ACR_NAME.azurecr.io/vote-app-dev/backend:$VERSION vote-app/charts/backend/app

az acr build --registry $ACR_NAME --image $ACR_NAME.azurecr.io/vote-app-dev/frontend:$VERSION vote-app/charts/frontend/app