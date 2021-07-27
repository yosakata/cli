#!/bin/bash

# Created by Telly Umada 
# This script creates an EC2 instance in the specified region 
# The ssh key needs to exist in the specified region. 
# Otherwise, it gives an error (or you cannot connect to the instance)

REGION=ap-northeast-1
PEM_FILE=/Users/utetsumi/ssh_pem/ap-northeast-1.pem

# if [ "$1" != "" ]
#   then
#     REGION=$1
# fi

echo Crating an instance in $REGION
START_RESULT=$(aws ec2 run-instances \
    --image-id ami-0ca38c7440de1749a \
    --instance-type t2.micro \
    --key-name ap-northeast-1 \
    --region $REGION)


INSTANCE_ID=$(echo $START_RESULT | jq -r '.Instances[].InstanceId')
echo $INSTANCE_ID is created 

INSTANCE_PUBLIC_IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID \
												--region $REGION \
                                                --query 'Reservations[*].Instances[*].PublicIpAddress' \
                                                --output text)

echo Public IP: $INSTANCE_PUBLIC_IP 

# https://docs.aws.amazon.com/cli/latest/reference/ec2/wait/instance-running.html
echo Wiating for the instance to be running ... 
aws ec2 wait instance-running \
	--instance-ids  $INSTANCE_ID \
    --region $REGION


echo Getting ready to ssh...
sleep 10

echo SSH to the instance at $INSTANCE_PUBLIC_IP 
ssh -i $PEM_FILE ec2-user@$INSTANCE_PUBLIC_IP 

