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

fn__delete_container_registry () {
  az acr delete \
    --name $CONTAINER_REGISTRY_NAME \
    --resource-group $CONTAINER_RESOURCE_GROUP_NAME
}

fn__delete_resource_group () {
  az group delete \
    --resource-group $CONTAINER_RESOURCE_GROUP_NAME 
}

run () {
  echo "Current active account:"
  az account show | grep "    \"name\""
  echo ""

  read -p "Continue (y/n)? " CONT
  if [ "$CONT" = "n" ]; then
    exit 1
  fi

  set -x
  fn__delete_container_registry
  fn__delete_resource_group
  set +x
}

time run