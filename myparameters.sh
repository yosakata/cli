  
#!/bin/bash
#******************************************************************************
#    AWS VPC Setup Shell Script
#******************************************************************************
# Default
AWS_REGION="us-west-2"
VPC_CIDR="10.0.0.0/16"
ALL_CIDR="0.0.0.0/0"
VPC_NAME="MyTestVPC"
IGW_NAME="MyTestIGW"
NGW_NAME="MyTestNGW"
KEY_PAIR_NAME="MyTestKeyPair"
RT_NAME="MyTestRT"
RT_PRI_NAME="MyTestPriRT"
SG_WS_NAME="HTTP_SSH_Access"
SG_WS_DESC="Allow HTTP and SSH Accesses"
SG_PRI_NAME="SSH_Access_Within_VPC"
SG_PRI_DESC="Allow SSH Accesses within VPC"
LB_TARGET_NAME="WebServerTargetGroup"
LB_NAME="WebServerLoadBalancer"

AMI="ami-0a36eb8fadc976275"

AZ_A="us-west-2a"
AZ_B="us-west-2b"
AZ_C="us-west-2c"

INSTANCE_PUB1_NAME="WebServerPub1"
INSTANCE_PUB2_NAME="WebServerPub2"
INSTANCE_PUB3_NAME="WebServerPub3"

INSTANCE_PRI1_NAME="WebServerPri1"
INSTANCE_PRI2_NAME="WebServerPri2"

SUBNET_PUB1_CIDR="10.0.1.0/24"
SUBNET_PUB1_AZ=${AZ_A}
SUBNET_PUB1_NAME="SubnetPub1"

SUBNET_PUB2_CIDR="10.0.2.0/24"
SUBNET_PUB2_AZ=${AZ_B}
SUBNET_PUB2_NAME="SubnetPub2"

SUBNET_PUB3_CIDR="10.0.3.0/24"
SUBNET_PUB3_AZ=${AZ_A}
SUBNET_PUB3_NAME="SubnetPub3"

SUBNET_PUB4_CIDR="10.0.4.0/24"
SUBNET_PUB4_AZ=${AZ_B}
SUBNET_PUB4_NAME="SubnetPub4"

SUBNET_PUB5_CIDR="10.0.5.0/24"
SUBNET_PUB5_AZ=${AZ_A}
SUBNET_PUB5_NAME="SubnetPub5"

SUBNET_PRI1_CIDR="10.0.11.0/24"
SUBNET_PRI1_AZ=${AZ_A}
SUBNET_PRI1_NAME="SubnetPri1"

SUBNET_PRI2_CIDR="10.0.12.0/24"
SUBNET_PRI2_AZ=${AZ_B}
SUBNET_PRI2_NAME="SubnetPri2"

EIP_NAME="NATGatewayPUB"

