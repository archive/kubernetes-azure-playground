#!/bin/bash

set -o allexport
source .env
set +o allexport

if [ -z "$CLUSTER_RESOURCE_GROUP_NAME" ]; then
  echo "Missing value for ENV CLUSTER_RESOURCE_GROUP_NAME"
  exit 1
fi  

if [ -z "$CLUSTER_NAME" ]; then
  echo "Missing value for ENV CLUSTER_NAME"
  exit 1
fi  

fn__delete_cluster () {
  az aks delete \
    --name $CLUSTER_NAME \
    --resource-group $CLUSTER_RESOURCE_GROUP_NAME

  kubectl config delete-cluster $CLUSTER_NAME
  kubectl config delete-context $CLUSTER_NAME
}

fn__delete_resource_group () {
   az group delete \
    --name $CLUSTER_RESOURCE_GROUP_NAME 
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
  fn__delete_cluster
  fn__delete_resource_group
  set +x
}

time run