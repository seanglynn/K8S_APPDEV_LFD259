#!/usr/bin/env bash

NAMESPACE=$1
SVC_ACC_NAME=sglynnbot

echo -e "Executing hard delete on Kubernetes Namespace: ${NAMESPACE}"
JSON_REQ_BODY="/Users/sglynn/DEV/K8S_AppDev/LFD259/terraform/tmp.json"

# Check all possible clusters, as your .KUBECONFIG may have multiple contexts:
kubectl config view -o jsonpath='{"Cluster name\tServer\n"}{range .clusters[*]}{.name}{"\t"}{.cluster.server}{"\n"}{end}'

# Select name of cluster you want to interact with from above output:
export CLUSTER_NAME="gcp-development"

# Point to the API server referring the cluster name
APISERVER=$(kubectl config view -o jsonpath="{.clusters[?(@.name==\"$CLUSTER_NAME\")].cluster.server}")
echo $API_SERVER_URL

# Gets the token value
TOKEN=$(kubectl get secrets -o jsonpath="{.items[?(@.metadata.annotations['kubernetes\.io/service-account\.name']=='$SVC_ACC_NAME')].data.token}" | base64 --decode)
echo $TOKEN

# Explore the API with TOKEN
curl -X GET $APISERVER/api --header "Authorization: Bearer $TOKEN" --insecure

curl -k -H "Content-Type: application/json" -H "Authorization: Bearer $TOKEN" --insecure -X PUT --data-binary @$JSON_REQ_BODY $API_SERVER_URL/api/v1/namespaces/$NAMESPACE/finalize
