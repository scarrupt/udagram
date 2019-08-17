#!/bin/bash

set -e

# Trick to get directory that script is located in
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

configmap=`cat "$DIR/env-configmap.yaml" | sed "s/{{AWS_BUCKET}}/$AWS_BUCKET/g;s/{{AWS_PROFILE}}/$AWS_PROFILE/g;s/{{AWS_REGION}}/$AWS_REGION/g;s/{{POSTGRESS_DB}}/$POSTGRESS_DB/g;s/{{POSTGRESS_HOST}}/$POSTGRESS_HOST/g;s#{{APP_URL}}#$APP_URL#g"`
echo "$configmap" | kubectl apply -f -

secret=`cat "$DIR/env-secret.yaml" | sed "s/{{JWT_SECRET}}/$JWT_SECRET/g;s/{{POSTGRESS_USERNAME}}/$POSTGRESS_USERNAME/g;s/{{POSTGRESS_PASSWORD}}/$POSTGRESS_PASSWORD/g"`
echo "$secret" | kubectl apply -f -

awsSecret=`cat "$DIR/aws-secret.yaml" | sed "s/{{AWS_CREDENTIALS}}/$AWS_CREDENTIALS/g"`
echo "$awsSecret" | kubectl apply -f -

kubectl apply -f $DIR/backend-feed-deployment.yaml

kubectl apply -f $DIR/backend-user-deployment.yaml

kubectl apply -f $DIR/reverseproxy-deployment.yaml

kubectl apply -f $DIR/frontend-deployment.yaml