#!/bin/bash

set -o allexport
source .env
set +o allexport

if [ -z "$RESOURCE_GROUP_LOCATION" ]; then
  echo "Missing value for ENV RESOURCE_GROUP_LOCATION"
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
    --name $CONTAINER_RESOURCE_GROUP_NAME \
    --location $RESOURCE_GROUP_LOCATION

  az group show --name $CONTAINER_RESOURCE_GROUP_NAME  
}

fn__container_registry () {
  az acr create  \
    --name $CONTAINER_REGISTRY_NAME \
    --resource-group $CONTAINER_RESOURCE_GROUP_NAME \
    --sku Basic 
}

run () {
  set -x
  fn__create_resource_group
  fn__container_registry
  set +x
}

time run