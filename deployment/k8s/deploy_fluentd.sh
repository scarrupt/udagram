#!/bin/bash

set -e

kubectl apply -f cloudwatch-namespace.yaml

kubectl create configmap cluster-info \
--from-literal=cluster.name=udagram \
--from-literal=logs.region=us-west-2 -n amazon-cloudwatch

kubectl apply -f fluentd.yml