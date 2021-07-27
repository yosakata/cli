  
#!/bin/bash
#******************************************************************************
#    AWS VPC Setup Shell Script
#******************************************************************************
AWS_REGION="us-west-2"
VPC_NAME="MyTestVPC"
VPC_CIDR="10.0.0.0/16"
RT_NAME='MyRouteTable'
IGW_NAME='MyTestIGW'
INS_NAME='MyTestInstance'

SUBNET_PUB1_CIDR="10.0.1.0/24"
SUBNET_PUB1_AZ="us-west-2a"
SUBNET_PUB1_NAME="PUB1"
SUBNET_PRI1_CIDR="10.0.11.0/24"
SUBNET_PRI1_AZ="us-west-2b"
SUBNET_PRI1_NAME="PRI1"
SUBNET_PRI2_CIDR="10.0.12.0/24"
SUBNET_PRI2_AZ="us-west-2c"
SUBNET_PRI2_NAME="PRI2"


# Create Security Group

SG_NAME="SG_WebServer_SSH"
SG_DESC="Security Group for WebServer"

# Get VPC ID
VPC_ID=`aws ec2 describe-vpcs --filters Name=tag:Name,Values=MyTestVPC --query 'Vpcs[0].VpcId' --output text`
echo ${VPC_ID}

# Create Security Group
echo "Creating Security Group"
SG_ID=`aws ec2 create-security-group --group-name "${SG_NAME}" --description "${SG_DESC}" --vpc-id ${VPC_ID} --query GroupId --output text`
echo "Security Group ${SG_ID}"

# Grant Port 22
aws ec2 authorize-security-group-ingress --group-id ${SG_ID} --protocol tcp --port 80 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id ${SG_ID} --protocol tcp --port 22 --cidr 0.0.0.0/0

# Create Launch Template

SG_ID="sg-0c0aaa778396633be"
Temp_Data='{"ImageId":"ami-0a36eb8fadc976275","InstanceType":"t2.micro","SecurityGroupIds":["'${SG_ID}'"]}'
echo ${Temp_Data}
aws ec2 create-launch-template --launch-template-name my-template-for-auto-scaling --version-description version1 --launch-template-data ${Temp_Data}

# or use json as template data

aws ec2 create-launch-template --launch-template-name my-template-for-auto-scaling --version-description version1 \
  --launch-template-data file://config.json

# { 
#    "ImageId":"ami-0a36eb8fadc976275",
#    "InstanceType":"t3.micro",
#    "SecurityGroupIds":["${SG_ID}"]
# }

aws ec2 create-launch-template --launch-template-name my-template-for-auto-scaling --version-description version1 \
  --launch-template-data '{"ImageId":"ami-04d5cc9b88example","InstanceType":"t2.micro","SecurityGroupIds":["sg-903004f88example"],"TagSpecifications":[{"ResourceType":"instance","Tags":[{"Key":"purpose","Value":"webserver"}]}]}'


