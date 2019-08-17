# Udagram

Udagram is a simple cloud application developed alongside the Udacity Cloud Engineering Nanodegree. It allows users to register and log into a web client, post photos to the feed, and process photos using an image filtering microservice.

## Getting started

### Prerequisites
The following tools need to be installed on your machine:

- [Docker](https://www.docker.com/products/docker-desktop)
- [AWS CLI](https://aws.amazon.com/cli/)
- [Kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
- [KubeOne](https://github.com/kubermatic/kubeone)

Furthermore, you need to have:
- an [Amazon Web Services](https://console.aws.amazon.com) account
- a [DockerHub](https://hub.docker.com/) account

### Clone the repository

Clone the repository on your local machine:

```
git clone git@github.com:scarrupt/udagram.git
```

### Create an S3 bucket

The application uses an S3 bucket to store the images so an AWS S3 Bucket needs to be created

#### Permissions

Save the following policy in the Bucket policy editor:

```JSON
{
 "Version": "2012-10-17",
 "Id": "Policy1565786082197",
 "Statement": [
 {
 "Sid": "Stmt1565786073670",
 "Effect": "Allow",
 "Principal": {
 "AWS": "__YOUR_USER_ARN__"
 },
 "Action": [
 "s3:GetObject",
 "s3:PutObject"
 ],
 "Resource": "__YOUR_BUCKET_ARN__/*"
 }
 ]
}
```
Modify the variables `__YOUR_USER_ARN__` and `__YOUR_BUCKET_ARN__` by your own data.

#### CORS configuration

Save the following configuration in the CORS configuration Editor:

```XML
<?xml version="1.0" encoding="UTF-8"?>
 <CORSConfiguration xmlns="http://s3.amazonaws.com/doc/2006-03-01/">
 <CORSRule>
 <AllowedOrigin>*</AllowedOrigin>
 <AllowedMethod>GET</AllowedMethod>
 <AllowedMethod>POST</AllowedMethod>
 <AllowedMethod>DELETE</AllowedMethod>
 <AllowedMethod>PUT</AllowedMethod>
 <MaxAgeSeconds>3000</MaxAgeSeconds>
 <AllowedHeader>Authorization</AllowedHeader>
 <AllowedHeader>Content-Type</AllowedHeader>
 </CORSRule>
</CORSConfiguration>
```

## Deploy on local

`Docker` is used to start the application on the local environment

The variables below need to be added to your environment:

```
POSTGRESS_USERNAME=udagram
POSTGRESS_PASSWORD=local
POSTGRESS_DB=udagram
POSTGRESS_HOST=db
WT_SECRET=mySecret
AWS_BUCKET=__YOUR_AWS_BUCKET_NAME__
AWS_REGION=__YOUR_AWS_BUCKET_REGION__
AWS_PROFILE=__YOUR_AWS_PROFILE__
```

Replace the variables `__YOUR_AWS_BUCKET_NAME__`, `__YOUR_AWS_BUCKET_REGION__` and `__YOUR_AWS_PROFILE__` by your own information

Build the images by running:

```
docker-compose -f docker-compose-build.yaml build --parallel
```

Start the application and services:

```
docker-compose up
```

The application is now running at http://localhost:8100

## Deploy on AWS

The application is running in a Kubernetes Cluster on AWS.

### Create a Kubernetes cluster

#### Provision the infrastructure

At first, add the following variables to your environment

```
AWS_ACCESS_KEY_ID=__YOUR_AWS_ACCES_KEY_ID__
AWS_SECRET_ACCESS_KEY=__YOUR_AWS_SECRET_ACCESS_KEY__
```

Move to the directory `deployment/k8s/infrastructure` and run the following command:

```
terraform init
```

Edit the values `aws_region` and `ssh_public_key_file` in the file `terraform.tfvars` by your own data.

Store the terraform variables below in a file named `terraform.tfvars`:

```
cluster_name = "udagram"
aws_region = "__YOUR_AWS_REGION__"
worker_os = "ubuntu"
ssh_public_key_file = "~/.ssh/id_rsa.pub"
```

Modify `__YOUR_AWS_REGION__` by your AWS region.

Confirm the changes by running

```
terraform plan
```

Provision the infrastructure on AWS by executing:

```
terraform apply
```

Don't forget to enter yes shortly after running the command.

Once it's created, create the Terraform state that will be used by `KubeOne`:

```
terraform output -json > tf.json
```

#### Install Kubernetes

Execute the following command

```
kubeone install config.yaml --tfjson tf.json
```

After Kubernetes was installed, export the following variable to your environment:

```
KUBECONFIG=$PWD/udagram-kubeconfig
```

More information can be found [here](https://github.com/kubermatic/kubeone/blob/master/docs/quickstart-aws.md).

#### Delete the cluster

If you need to delete the cluster you can run these commands:

```
kubeone reset config.yaml --tfjson tf.json
```

```
terraform destroy
```

### Create a PostgreSQL Instance

The application is using `PostgreSQL` database to store the feed data.

Create a PostgresSQL instance via Amazon RDS.

Add the ```udagram_common``` VPC security group to your Database instance so the services can access it.

### Deploy the application services

Deploy and start the application and services on Kubernetes by executing:

```
./deployment/k8s/deploy_services.sh
```

### Build the production images

At first, set these variables to your environment 

```
POSTGRESS_USERNAME=__YOUR_MASTER_USERNAME__
POSTGRESS_PASSWORD=__YOUR_MASTER_PASSWORD__
POSTGRESS_DB=__YOUR_INITIAL_DATABASE_NAME__
POSTGRESS_HOST=__YOUR_AMAZON_RDS_DB_HOST__
JWT_SECRET=__YOUR_JWT_SECRET__
AWS_BUCKET=__YOUR_AWS_BUCKET_NAME__
AWS_REGION=__YOUR_AWS_BUCKET_REGION__
AWS_PROFILE=__YOUR_AWS_PROFILE__
AWS_CREDENTIALS=`cat ~/.aws/credentials`
APP_URL=http://__YOUR_FRONTEND_SERVICE_URL__:8100
```

Replace the values by your data. `__YOUR_FRONTEND_SERVICE_URL__` can be retrieved using the command:

```
kubectl get svc
```

Add the reverseproxy URL to the file `frontend/src/environments/environment.prod.ts`

You can also retrieve the reverse proxy URL by running

```
kubectl get svc
```

Create a docker build file with the following content

```YAML
version: "3"
services:
 reverseproxy:
 build:
 context: .
 image: __YOUR_DOCKERHUB_NAME__/udagram-reverseproxy
 backend_user:
 build:
 context: ../../api-user
 image: __YOUR_DOCKERHUB_NAME__/udagram-api-user
 backend_feed:
 build:
 context: ../../api-feed 
 image: __YOUR_DOCKERHUB_NAME__/udagram-api-feed
 frontend:
 build:
 context: ../../frontend 
 args:
 - BUILD_ENV=production
 image: __YOUR_DOCKERHUB_NAME__/udagram-frontend
```

Replace ```__YOUR_DOCKERHUB_NAME__``` by your own DockerHub account.

Build the images by executing:

```
docker-compose -f __YOUR_DOCKER_BUILD_FILE__ build --parallel
```

Push your images to your Docker Hub

```
docker-compose -f __YOUR_DOCKER_BUILD_FILE__ push
```

### Deploy the Kubernetes pods

For each deployment.yaml in `deployment/k8s` replace the image name by your own Docker Hub name. Example:

```YAML
containers:
 - image: __YOUR_DOCKERHUB_NAME__/udagram-api-feed
```

Deploy the Kubernetes pods by running

```
./deployment/k8s/deploy.sh
```

### Deploy the AWS CloudWatch Agent

Attach the `CloudWatchAgentServerPolicy` policy to the `udagram-host` IAM role

Run the script:
```
./deployment/k8s/deploy_fluentd.sh
```

Application, services, and container logs are now sent to CloudWatch.

### Deploy a canary version of your application

2 versions of the application can be run on parallel for A/B Testing.

Checkout the V2 branch by:

```
git checkout -b V2
```

Add the tag V2 on the frontend image in your Docker production build file and build it:

```
docker-compose -f __YOUR_DOCKER_BUILD_FILE__ build --parallel
```

Push the V2 frontend image to your Docker Hub

```
docker-compose -f __YOUR_DOCKER_BUILD_FILE__ push
```

Deploy the V2 frontend in Kubernetes

```
kubectl -f deployment/k8s/frontend-canary-deployment.yaml
```

Voilà. The load balancer will route some traffic to the version 2