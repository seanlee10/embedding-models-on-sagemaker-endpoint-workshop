#!/usr/bin/env bash

# This script shows how to build the Docker image and push it to ECR to be ready for use
# by SageMaker.

# The argument to this script is the image name. This will be used as the image on the local
# machine and combined with the account and region to form the repository name for ECR.
IMAGE=$1

if [ "$IMAGE" == "" ]
then
    echo "Usage: $0 <image-name>"
    exit 1
fi

chmod +x src/predictor.py

# Get the account number associated with the current IAM credentials
ACCOUNT=$(aws sts get-caller-identity --query Account --output text)

if [ $? -ne 0 ]
then
    exit 255
fi


# Get the region defined in the current configuration (default to us-west-2 if none defined)
REGION=$(aws configure get region)
REGION=${REGION:-us-west-2}

FULLNAME="${ACCOUNT}.dkr.ecr.${REGION}.amazonaws.com/${IMAGE}:latest"

# If the repository doesn't exist in ECR, create it.

aws ecr describe-repositories --repository-names "${IMAGE}" > /dev/null 2>&1

if [ $? -ne 0 ]
then
    aws ecr create-repository --repository-name "${IMAGE}" > /dev/null
fi

# Get the login command from ECR and execute it directly
aws ecr get-login-password --region "${REGION}" | docker login --username AWS --password-stdin "${ACCOUNT}".dkr.ecr."${REGION}".amazonaws.com

# Build the docker image locally with the image name and then push it to ECR
# with the full name.

docker build  -t ${IMAGE} .
docker tag ${IMAGE} ${FULLNAME}

docker push ${FULLNAME}
