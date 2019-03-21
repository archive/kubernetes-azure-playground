#!/bin/bash

set -o allexport
source .env
set +o allexport

if [ -z "$RESOURCE_GROUP_LOCATION" ]; then
  echo "Missing value for ENV RESOURCE_GROUP_LOCATION"
  exit 1
fi  

if [ -z "$CLUSTER_RESOURCE_GROUP_NAME" ]; then
  echo "Missing value for ENV CLUSTER_RESOURCE_GROUP_NAME"
  exit 1
fi  

if [ -z "$CLUSTER_NAME" ]; then
  echo "Missing value for ENV CLUSTER_NAME"
  exit 1
fi  

if [ -z "$CONTAINER_RESOURCE_GROUP_NAME" ]; then
  echo "Missing value for ENV CONTAINER_RESOURCE_GROUP_NAME"
  exit 1
fi  

if [ -z "$CONTAINER_REGISTRY_NAME" ]; then
  echo "Missing value for ENV CONTAINER_REGISTRY_NAME"
  exit 1
fi  

fn__create_resource_group () {
  az group create \
    --name $CLUSTER_RESOURCE_GROUP_NAME \
    --location $RESOURCE_GROUP_LOCATION

  az group show --name $CLUSTER_RESOURCE_GROUP_NAME
}

fn__create_cluster () {
  echo ""

  time az aks create \
    --resource-group $CLUSTER_RESOURCE_GROUP_NAME \
    --name $CLUSTER_NAME \
    --node-count 1 \
    --enable-addons monitoring \
    --generate-ssh-keys \
    --node-vm-size Standard_B2s \
    --kubernetes-version 1.12.6

  az aks list | grep "\"name\":"
}

fn__get_credentials () {
  az aks get-credentials \
    --name $CLUSTER_NAME \
    --resource-group $CLUSTER_RESOURCE_GROUP_NAME 
    #--overwrite-existing

  kubectl config use-context $CLUSTER_NAME
}

fn__login_container_registry () {
  az acr login --name $CONTAINER_REGISTRY_NAME
}

fn__grant_access_to_container_registry () {
  #https://docs.microsoft.com/en-us/azure/container-registry/container-registry-auth-aks

  # Get the id of the service principal configured for AKS
  clientId=$(az aks show --resource-group $CLUSTER_RESOURCE_GROUP_NAME --name $CLUSTER_NAME --query "servicePrincipalProfile.clientId" --output tsv)

  # Get the ACR registry resource id
  acrId=$(az acr show --name $CONTAINER_REGISTRY_NAME --resource-group $CONTAINER_RESOURCE_GROUP_NAME --query "id" --output tsv)

  # Create role assignment
  az role assignment create --assignee $clientId --role acrpull --scope $acrId
}

fn__build_and_push_nodejs_service () {
  docker-compose -f nodejs/docker-compose.yml build
  docker tag nodejs-test-svc-app-image $CONTAINER_REGISTRY_NAME.azurecr.io/nodejs-test-svc-app-image
  docker push $CONTAINER_REGISTRY_NAME.azurecr.io/nodejs-test-svc-app-image:latest
}

fn__nodejs_deployment () {
  cat nodejs/.kube/deployment.yaml | sed 's/\$CONTAINER_REGISTRY_NAME'"/$CONTAINER_REGISTRY_NAME/g" | kubectl apply -f -
  kubectl get pods
  
  echo ""
  kubectl apply -f nodejs/.kube/service.yaml
  kubectl get services
}

fn__build_and_push_dotnetcore_service () {
  docker-compose -f dotnetcore/docker-compose.yml build
  docker tag dotnetcore-testsvc-app-image $CONTAINER_REGISTRY_NAME.azurecr.io/dotnetcore-testsvc-app-image
  docker push $CONTAINER_REGISTRY_NAME.azurecr.io/dotnetcore-testsvc-app-image:latest
}

fn__dotnetcore_deployment () {
  cat dotnetcore/.kube/deployment.yaml | sed 's/\$CONTAINER_REGISTRY_NAME'"/$CONTAINER_REGISTRY_NAME/g" | kubectl apply -f -
  kubectl get pods

  echo ""
  kubectl apply -f dotnetcore/.kube/service.yaml
  kubectl get services
}

run () {
  set -x
  fn__create_resource_group
  fn__create_cluster
  fn__get_credentials
  fn__login_container_registry
  fn__grant_access_to_container_registry

  fn__build_and_push_nodejs_service
  fn__nodejs_deployment
  
  fn__build_and_push_dotnetcore_service
  fn__dotnetcore_deployment
  set +x
}

time run
