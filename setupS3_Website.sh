  
#!/bin/bash
#******************************************************************************
#    AWS Setup RDS
#******************************************************************************
VPC_NAME="MyTestVPC"
SUBNET_PUB1_NAME="PUB1"
SUBNET_PUB2_NAME="PUB2"
SUBNET_PRI1_NAME="PRI1"
SUBNET_PRI2_NAME="PRI2"
AWS_REGION="us-west-2"
BCT_NAME="yo-sakata-bucket"

aws s3api create-bucket --bucket ${BCT_NAME} --region ${AWS_REGION} --create-bucket-configuration LocationConstraint=${AWS_REGION}

#!/bin/bash

echo '{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "PublicReadGetObject",
            "Effect": "Allow",
            "Principal": "*",
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::happy-bunny/*"
        }
    ]
}' > /tmp/bucket_policy.json

aws s3api create-bucket --bucket happy-bunny --region eu-west-1  --create-bucket-configuration LocationConstraint=eu-west-1 --profile equivalent \
  && aws s3api put-bucket-policy --bucket happy-bunny --policy file:///tmp/bucket_policy.json --profile equivalent \
  && aws s3 sync /home/tomas/folder-where-you-keep-your-projects/happy-bunny s3://happy-bunny/  --profile equivalent \
  && aws s3 website s3://happy-bunny/ --index-document index.html --error-document error.html --profile equivalent

  

#BUCKET="yosakata998877"
#aws s3api create-bucket --bucket $BUCKET --region us-west-2  --create-bucket-configuration LocationConstraint=us-west-2
#aws s3api put-bucket-policy --bucket $BUCKET --policy file://s3policy.json
