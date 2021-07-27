  
#!/bin/bash
#******************************************************************************
#    Set up Web Servers with ALB
#******************************************************************************
source myfunctions.sh
# Import shared parameters.
#source myparameters.sh

# Update Paramters
REGION="us-west-1"
VPC_NAME="WebServerVPC"
IGW_NAME="WebServerIGW"
NGW_NAME="WebServerNGW"
KEY_PAIR_NAME="WebServerKeyPair"
RT_PUB_NAME="WebServerPubRT"
RT_PRI_NAME="WebServerPriRT"

AZ_A="us-west-1a"
AZ_B="us-west-1b"
AZ_C="us-west-1c"
VPC_CIDR="10.0.0.0/16"
ALL_CIDR="0.0.0.0/0"

SG_WS_NAME="HTTP_SSH_Access"
SG_WS_DESC="Allow HTTP and SSH Accesses"

SG_PRI_NAME="SSH_Access_Within_VPC"
SG_PRI_DESC="Allow SSH Accesses within VPC"
LB_TARGET_NAME="WebServerTargetGroup"
LB_NAME="WebServerLoadBalancer"

INSTANCE_PUB1_NAME="WebServerPub1"
INSTANCE_PUB2_NAME="WebServerPub2"
INSTANCE_PUB3_NAME="WebServerPub3"

INSTANCE_PRI1_NAME="WebServerPri1"
INSTANCE_PRI2_NAME="WebServerPri2"

SUBNET_PUB1_CIDR="10.0.1.0/24"
SUBNET_PUB1_NAME="SubnetPub1"

SUBNET_PUB2_CIDR="10.0.2.0/24"
SUBNET_PUB2_NAME="SubnetPub2"

SUBNET_PUB3_CIDR="10.0.3.0/24"
SUBNET_PUB3_NAME="SubnetPub3"

SUBNET_PRI1_CIDR="10.0.11.0/24"
SUBNET_PRI1_NAME="SubnetPri1"

SUBNET_PRI2_CIDR="10.0.12.0/24"
SUBNET_PRI2_NAME="SubnetPri2"

# Main

export AWS_DEFAULT_REGION=us-west-1

# Create Key Pair
create_key_pair ${KEY_PAIR_NAME}

# create VPC
create_vpc ${VPC_CIDR} ${REGION} ${VPC_NAME}

# Create Subnet 
create_subnet ${SUBNET_PUB1_CIDR} ${AZ_A} ${SUBNET_PUB1_NAME} ${VPC_NAME}
create_subnet ${SUBNET_PUB2_CIDR} ${AZ_B} ${SUBNET_PUB2_NAME} ${VPC_NAME}
create_subnet ${SUBNET_PUB3_CIDR} ${AZ_C} ${SUBNET_PUB3_NAME} ${VPC_NAME}

# Set up Internet Gateway
create_igw ${IGW_NAME}
attach_igw ${IGW_NAME} ${VPC_NAME}

# Setup Route Table
create_route_table ${RT_PUB_NAME} ${VPC_NAME}
add_igw_to_route_table ${RT_PUB_NAME} ${IGW_NAME}

associate_route_table ${RT_PUB_NAME} ${SUBNET_PUB1_NAME}
associate_route_table ${RT_PUB_NAME} ${SUBNET_PUB2_NAME}
associate_route_table ${RT_PUB_NAME} ${SUBNET_PUB3_NAME}

# Setup Security Group
create_security_group ${SG_WS_NAME} "${SG_WS_DESC}" ${VPC_NAME}
add_rule_to_security_group ${SG_WS_NAME} 80 ${ALL_CIDR}
add_rule_to_security_group ${SG_WS_NAME} 22 ${ALL_CIDR}

# Setup Natgateway
# Setup Nat Gateway in Subnet Pub 3
create_eip ${EIP_NAME}
create_nat_gateway ${EIP_NAME} ${SUBNET_PUB3_NAME} ${NGW_NAME}
create_route_table ${RR_PRI_NAME} ${VPC_NAME}
add_ngw_to_route_table ${RT_PRI_NAME} ${NGW_NAME}
associate_route_table ${RT_PRI_NAME} ${SUBNET_PRI1_NAME}


# Create Instance
create_instance ${INSTANCE_PUB3_NAME} ${SUBNET_PUB3_NAME} ${SG_WS_NAME} "public"

# Setup Load Balancer
create_load_balancer ${SUBNET_PUB1_NAME} ${SUBNET_PUB2_NAME} ${SG_WS_NAME} ${LB_NAME}
create_target_group ${VPC_NAME} ${LB_TARGET_NAME}
register_targets ${INSTANCE_PUB1_NAME} ${INSTANCE_PUB2_NAME} ${TARGET_GROUP_ARN}
create_listener ${LB_ARN} ${TARGET_GROUP_ARN}


