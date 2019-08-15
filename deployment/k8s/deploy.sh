#!/bin/bash

set -e

configmap=`cat "./env-configmap.yaml" | sed "s/{{AWS_BUCKET}}/$AWS_BUCKET/g;s/{{AWS_PROFILE}}/$AWS_PROFILE/g;s/{{AWS_REGION}}/$AWS_REGION/g;s/{{POSTGRESS_DB}}/$POSTGRESS_DB/g;s/{{POSTGRESS_HOST}}/$POSTGRESS_HOST/g;s#{{APP_URL}}#$APP_URL#g"`
echo "$configmap" | kubectl apply -f -

secret=`cat "./env-secret.yaml" | sed "s/{{JWT_SECRET}}/$JWT_SECRET/g;s/{{POSTGRESS_USERNAME}}/$POSTGRESS_USERNAME/g;s/{{POSTGRESS_PASSWORD}}/$POSTGRESS_PASSWORD/g"`
echo "$secret" | kubectl apply -f -

awsCredentials=`cat ~/.aws/credentials | base64`
awsSecret=`cat "./aws-secret.yaml" | sed "s/{{AWS_CREDENTIALS}}/$awsCredentials/g"`
echo "$awsSecret" | kubectl apply -f -

kubectl apply -f ./backend-feed-deployment.yaml

kubectl apply -f ./backend-user-deployment.yaml

kubectl apply -f ./reverseproxy-deployment.yaml

kubectl apply -f ./frontend-deployment.yaml