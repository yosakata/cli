  
#!/bin/bash
#******************************************************************************
#    Set up Web Servers with ALB
#******************************************************************************
source myfunctions.sh
# Import shared parameters.
source myparameters.sh

# Update Paramters
VPC_NAME="WebServerVPC"
IGW_NAME="WebServerIGW"
NGW_NAME="WebServerNGW"
KEY_PAIR_NAME="WebServerKeyPair1"
RT_NAME="WebServerRT"

create_key_pair ${KEY_PAIR_NAME}
create_instance ${INSTANCE_PRI1_NAME} ${SUBNET_PRI1_NAME} ${SG_WS_NAME} "PrivateWebServer"
exit



# Setup Nat Gateway in Subnet Pub 3
create_subnet ${SUBNET_PUB5_CIDR} ${SUBNET_PUB5_AZ} ${SUBNET_PUB5_NAME} ${VPC_NAME}
create_subnet ${SUBNET_PRI1_CIDR} ${SUBNET_PRI1_AZ} ${SUBNET_PRI1_NAME} ${VPC_NAME}

# Set up Internet Gateway
create_igw ${IGW_NAME}
attach_igw ${IGW_NAME} ${VPC_NAME}

# Create Route Table for Subnet Pub 3
create_route_table ${RT_NAME} ${VPC_NAME}
add_igw_to_route_table ${RT_NAME} ${IGW_NAME}
associate_route_table ${RT_NAME} ${SUBNET_PUB5_NAME}

# Create EIP
create_eip ${EIP_NAME}

# Create Nat Gateway
create_nat_gateway ${EIP_NAME} ${SUBNET_PUB5_NAME} ${NGW_NAME}

create_route_table ${RT_PRI_NAME} ${VPC_NAME}
add_ngw_to_route_table ${RT_PRI_NAME} ${NGW_NAME}
associate_route_table ${RT_PRI_NAME} ${SUBNET_PRI1_NAME}

# Add Instance
create_instance ${INSTANCE_PRI1_NAME} ${SUBNET_PRI1_NAME} ${SG_WS_NAME} "PrivateWebServer"




# Create Key Pair
#create_key_pair ${KEY_PAIR_NAME}
