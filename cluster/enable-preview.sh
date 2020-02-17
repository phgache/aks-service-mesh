#!/bin/bash
set -e

az extension add --name aks-preview

az feature register --namespace "Microsoft.ContainerService" --name "AvailabilityZonePreview"
az feature register --namespace "Microsoft.ContainerService" --name "AKSAzureStandardLoadBalancer"
az feature register --namespace "Microsoft.ContainerService" --name "VMSSPreview"
az feature register --namespace "Microsoft.ContainerService" --name "WindowsPreview"
az feature register --namespace "Microsoft.ContainerService" --name "VMSSPreview"
az feature register --namespace "Microsoft.ContainerService" --name "AKSAzureStandardLoadBalancer"
az feature register --namespace "Microsoft.ContainerService" --name "MultiAgentpoolPreview"
az feature register --namespace "Microsoft.ContainerService" --name "PodSecurityPolicyPreview"

az provider register -n Microsoft.ContainerService

az feature list -o table --query "[?contains(name, 'Microsoft.ContainerService')].{Name:name,State:properties.state}"
