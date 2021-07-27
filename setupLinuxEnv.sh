  
#!/bin/bash
#******************************************************************************
#    AWS VPC Setup Shell Script
#******************************************************************************
source myfunctions.sh
# Import shared parameters.
source myparameters.sh

# update local parameters.
AWS_REGION="us-west-2"
VPC_NAME="LinuxEnvVPC"
VPC_CIDR="10.0.0.0/16"
RT_NAME='LinuxEnvRT'
IGW_NAME='LinuxEnvIGW'
INSTANCE_NAME='LinuxEnvInstance'
SG_NAME="LinuxEnvSG"
SG_DESC="Allow HTTP and SSH Access"
KEYPAIR_NAME='LinuxEnvKeyPair'
SUBNET_PUB_CIDR="10.0.1.0/24"
SUBNET_PUB_AZ="us-west-2a"
SUBNET_PUB_NAME="LinuxEnvSubnet"
KEY_PAIR_NAME="LinuxEnvKeyPair"

# create VPC
create_vpc ${VPC_CIDR} ${AWS_REGION} ${VPC_NAME}

# Create Subnet 
create_subnet ${SUBNET_PUB_CIDR} ${SUBNET_PUB_AZ} ${SUBNET_PUB_NAME} ${VPC_NAME}

# Set up Internet Gateway
create_igw ${IGW_NAME}
attach_igw ${IGW_NAME} ${VPC_NAME}

# Setup Route Table
create_route_table ${RT_NAME} ${VPC_NAME}
add_igw_to_route_table ${RT_NAME} ${IGW_NAME}
associate_route_table ${RT_NAME} ${SUBNET_PUB_NAME}


# Create key pair
create_key_pair ${KEY_PAIR_NAME}

# Create Security Group
create_security_group ${SG_NAME} "${SG_DESC}" ${VPC_NAME}
add_rule_to_security_group ${SG_NAME} 80 ${ALL_CIDR}
add_rule_to_security_group ${SG_NAME} 22 ${ALL_CIDR}

# Create Instance
create_instance ${INSTANCE_NAME} ${SUBNET_PUB_NAME} ${SG_NAME} "WebServer"





