  
#!/bin/bash
#******************************************************************************
#    AWS VPC Setup Shell Script
#******************************************************************************
AWS_REGION="us-west-2"
VPC_CIDR="10.0.0.0/16"
ALL_CIDR="0.0.0.0/0"
VPC_NAME="MyTestVPC"
IGW_NAME="MyTestIGW"
NGW_NAME="MyTestNGW"
ROUTE_TABLE_NAME="WebServerRouteTable"
ROUTE_TABLE_PRI_NAME="PrivateRouteTable"

SECURITY_GROUP_WS_NAME="HTTP_SSH_Access"
SECURITY_GROUP_WS_DESC="Allow HTTP and SSH Accesses"

SECURITY_GROUP_HTTP_NAME="HTTP_Access"
SECURITY_GROUP_HTTP_DESC="Allow HTTP Accesses"

SECURITY_GROUP_SSH_NAME="SSH_Access"
SECURITY_GROUP_SSH_DESC="Allow SSH Accesses"

SECURITY_GROUP_PRI_NAME="SSH_Access_Within_VPC"
SECURITY_GROUP_PRI_DESC="Allow SSH Accesses within VPC"

AMI="ami-0a36eb8fadc976275"

AZ_A="us-west-2a"
AZ_B="us-west-2b"
AZ_C="us-west-2c"

TARGET_NAME="WebServerTargetGroup"
LOADBALANCER_NAME="WebServerLoadBalancer"

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

KEY_PAIR_NAME="MyTestKeyPair"
EIP_NAME="NATGatewayPUB"

#aws ec2 delete-vpc --vpc-id ${VPC_ID}
#aws ec2 delete-tags --resources ${VPC_ID} --tags "Key=Name"

log(){
    echo `date "+%Y-%m-%d%n%H:%M:%S\t"` $1
}

error_exit(){
    if [ $? -ne 0 ]; then 
        echo "$1" 1>&2
        exit 1
    fi
}

get_vpc_id(){
    VPC_NAME=$1
    aws ec2 describe-vpcs --filters Name=tag:Name,Values=${VPC_NAME} --query 'Vpcs[0].VpcId' --output text
}

get_igw_id(){
    IGW_NAME=$1
    aws ec2 describe-internet-gateways --filters Name=tag:Name,Values=${IGW_NAME} --query "InternetGateways[*].InternetGatewayId" --output text
}

get_ngw_id(){
    NGW_NAME=$1
    aws ec2 describe-nat-gateways --filter Name=tag:Name,Values=${NGW_NAME} --query "NatGateways[0].NatGatewayId" --output text
}

get_subnet_id() {
  SUBNET_NAME=$1
  aws ec2 describe-subnets --filters Name=tag:Name,Values=${SUBNET_NAME} --query 'Subnets[0].SubnetId' --output text
}

get_route_table_id(){
    ROUTE_TABLE_NAME=$1
    aws ec2 describe-route-tables --filters Name=tag:Name,Values=${ROUTE_TABLE_NAME} --query 'RouteTables[0].RouteTableId' --output text
}

get_security_group_id(){
    SG_NAME=$1
    aws ec2 describe-security-groups --filters Name=group-name,Values=${SG_NAME} --query 'SecurityGroups[0].GroupId' --output text
}

is_igw_attached(){
    IGW_NAME=$1
    aws ec2 describe-internet-gateways --filters Name=tag:Name,Values="${IGW_NAME}" --query 'InternetGateways[0].Attachments[0].State' --output text
}

get_instance_id(){
    INSTANCE_NAME=$1
    aws ec2 describe-instances --filters Name=tag:Name,Values=${INSTANCE_NAME} Name=instance-state-name,Values=running --query "Reservations[0].Instances[0].InstanceId" --output text
}

get_eip_id(){
    EIP_NAME=$1
    aws ec2 describe-addresses --filters Name=tag:Name,Values=${EIP_NAME} --query 'Addresses[0].AllocationId' --output text
}

create_key_pair(){
    rm -f ${KEY_PAIR_NAME}.pem
    aws ec2 delete-key-pair --key-name ${KEY_PAIR_NAME}
    aws ec2 create-key-pair --key-name ${KEY_PAIR_NAME} --query 'KeyMaterial' --output text > ${KEY_PAIR_NAME}.pem
    chmod 400 ${KEY_PAIR_NAME}.pem
    error_exit
    log "Created KeyPair ${KEY_PAIR_NAME}"
}

create_vpc() {
    VPC_CIDR=$1
    AWS_REGION=$2
    VPC_NAME=$3
    VPC_ID=`get_vpc_id ${VPC_NAME}`
    if [ ${VPC_ID} != "None" ]; then
        log "Already VPC ${VPC_NAME} Exits - ID: ${VPC_ID}" ; return 0
    fi 
    VPC_ID=`aws ec2 create-vpc --cidr-block ${VPC_CIDR} --region ${AWS_REGION} --query Vpc.VpcId --output text`
    aws ec2 create-tags --resources ${VPC_ID} --tags "Key=Name,Value=${VPC_NAME}"
    error_exit
    log "Created VPC - ID: ${VPC_ID}"
}

create_subnet () {
    SUBNET_CIDR=$1
    SUBNET_AZ=$2
    SUBNET_NAME=$3
    VPC_ID=`get_vpc_id $4`
    SUBNET_ID=`get_subnet_id ${SUBNET_NAME}`
    if [ ${SUBNET_ID} != "None" ]; then
        log "Already Subnet ${SUBNET_NAME} Exits - ID: ${SUBNET_ID}" ; return 0
    fi 
    SUBNET_ID=`aws ec2 create-subnet --vpc-id ${VPC_ID} --cidr-block ${SUBNET_CIDR} --availability-zone ${SUBNET_AZ} --query Subnet.SubnetId --output text`
    aws ec2 create-tags --resources ${SUBNET_ID} --tags "Key=Name,Value=${SUBNET_NAME}" 
    log "Created Subnet ${SUBNET_NAME} - ID: ${SUBNET_ID}"

}

create_igw(){
    IGW_NAME=$1
    IGW_ID=`get_igw_id ${IGW_NAME}`
    if [ ${IGW_ID} != "None" ]; then
        log "Already IGW ${IGW_NAME} Exits - ID: ${IGW_ID}" ; return 0
    fi 
    IGW_ID=`aws ec2 create-internet-gateway --query InternetGateway.InternetGatewayId --output text`
    aws ec2 create-tags --resources ${IGW_ID} --tags "Key=Name,Value=${IGW_NAME}"
    error_exit 
    log "Created Internet Gateway - ID: ${IGW_ID}"

}

attach_igw(){
    IGW_NAME=$1
    VPC_ID=`get_vpc_id $2`
    IGW_ATTACHED=`is_igw_attached ${IGW_NAME}`
    if [ ${IGW_ATTACHED} == "available" ]; then
        log "Already IGW ${IGW_NAME} is attached to VPC - ID: ${VPC_ID}" ; return 0
    fi
    IGW_ID=`get_igw_id ${IGW_NAME}`
    RES=`aws ec2 attach-internet-gateway --vpc-id ${VPC_ID} --internet-gateway-id ${IGW_ID}`
    error_exit
    log "Attached Internet Gateway to VPC"

}

create_route_table() {
    ROUTE_TABLE_NAME=$1
    VPC_ID=`get_vpc_id $2`
    ROUTE_TABLE_ID=`get_route_table_id ${ROUTE_TABLE_NAME}`
    if [ ${ROUTE_TABLE_ID} != "None" ]; then
        log "Already VPC ${ROUTE_TABLE_NAME} Exits - ID: ${ROUTE_TABLE_ID}" ; return 0
    fi 
    ROUTE_TABLE_ID=`aws ec2 create-route-table --vpc-id ${VPC_ID} --query RouteTable.RouteTableId --output text`
    RESULT=`aws ec2 create-tags --resources ${ROUTE_TABLE_ID} --tags "Key=Name,Value=${ROUTE_TABLE_NAME}"`
    error_exit ${FUNCNAME[0]} 
    log "Created Route Table: ${ROUTE_TABLE_NAME} ID: ${ROUTE_TABLE_ID}"
}

add_igw_to_route_table(){
    ROUTE_TABLE_ID=`get_route_table_id $1`
    IGW_ID=`get_igw_id $2`
    RESULT=`aws ec2 create-route --route-table-id ${ROUTE_TABLE_ID} --destination-cidr-block 0.0.0.0/0 --gateway-id ${IGW_ID}`
    error_exit ${FUNCNAME[0]} 
    log "Added IGW to Route Table: ${ROUTE_TABLE_NAME} - ID: ${ROUTE_TABLE_ID}"
}

associate_route_table() {
    ROUTE_TABLE_ID=`get_route_table_id $1`
    SUBNET_ID=`get_subnet_id $2`
    RES=`aws ec2 associate-route-table  --subnet-id ${SUBNET_ID} --route-table-id ${ROUTE_TABLE_ID}`
    error_exit
    log "Associated Route Table to Subnet ${SUBNET_ID}"
}

create_security_group() {
    SECURITY_GROUP_NAME=$1
    SECURITY_GROUP_DESC=$2
    VPC_ID=`get_vpc_id $3`
    SECURITY_GROUP_ID=`get_security_group_id ${SECURITY_GROUP_NAME}`
    if [ ${SECURITY_GROUP_ID} != "None" ]; then
        log "Already VPC ${SECURITY_GROUP_NAME} Exits - ID: ${SECURITY_GROUP_ID}" ; return 0
    fi 
    SECURITY_GROUP_ID=`aws ec2 create-security-group --group-name ${SECURITY_GROUP_NAME} --description "${SECURITY_GROUP_DESC}" --vpc-id ${VPC_ID} --query GroupId --output text`
    aws ec2 create-tags --resources ${SECURITY_GROUP_ID} --tags "Key=Name,Value=${SECURITY_GROUP_NAME}" 
    error_exit
    log "Created ${SECURITY_GRUOP_NAME} - ID: ${SECURITY_GROUP_ID}"
}

add_rule_to_security_group(){
    SG_ID=`get_security_group_id $1`
    PORT=$2
    CIDR=$3
    RESULT=`aws ec2 authorize-security-group-ingress --group-id ${SG_ID} --protocol tcp --port ${PORT} --cidr ${CIDR}`
    #error_exit
    log "Granted ${PORT} on ${CIDR} Rules to Security Group - ID: ${SG_ID}"
}

create_instance() {
    INSTANCE_NAME=$1
    SUBNET_ID=`get_subnet_id $2`
    SG_ID=`get_security_group_id $3`

    INSTANCE_ID=`get_instance_id ${INSTANCE_NAME}`
    if [ ${INSTANCE_ID} != "None" ]; then
        log "Already VPC ${INSTANCE_NAME} Exits - ID: ${INSTANCE_ID}" ; return 0
    fi 

    if [ "$4" == "WebServer" ]; then
        INSTANCE_ID=`aws ec2 run-instances --image-id ${AMI} --count 1 --instance-type t3.micro --key-name ${KEY_PAIR_NAME} --security-group-ids ${SG_ID} --subnet-id ${SUBNET_ID} --associate-public-ip-address --user-data file://webserver_setup.sh --query Instances[0].InstanceId --output text`
    else
        INSTANCE_ID=`aws ec2 run-instances --image-id ${AMI} --count 1 --instance-type t3.micro --key-name ${KEY_PAIR_NAME} --security-group-ids ${SG_PRI_ID} --subnet-id ${SUBNET_ID} --query Instances[0].InstanceId --output text`
    fi
    error_exit
    aws ec2 create-tags --resources ${INSTANCE_ID} --tags "Key=Name,Value=${INSTANCE_NAME}"
    aws ec2 create-tags --resources ${INSTANCE_ID} --tags "Key=auto-delete,Value=no"
    log "Created Instance ${INSTANCE_NAME} - ID: ${INSTANCE_ID}"
}

is_instance_ready() {
    INSTANCE_ID=`get_instance_id $1`
    INSTANCE_STATUS=`aws ec2 describe-instance-status --instance-id ${INSTANCE_ID} --query 'InstanceStatuses[0].InstanceStatus.Details[0].Status' --output text`
    until [ ${INSTANCE_STATUS} = "passed" ]
    do
        log "Instance Status: ${INSTANCE_STATUS}"
        sleep 10
        INSTANCE_STATUS=`aws ec2 describe-instance-status --instance-id ${INSTANCE_ID} --query 'InstanceStatuses[0].InstanceStatus.Details[0].Status' --output text`
    done
    log "Ready Instance. ID: ${INSTANCE_ID}"
}

create_eip(){
    EIP_NAME=$1
    EIP_ID=`get_eip_id ${EIP_NAME}`
    if [ ${EIP_ID} != "None" ]; then
        log "Already EIP ${EIP_NAME} Exits - ID: ${EIP_ID}" ; return 0
    fi 
    EIP_ID=`aws ec2 allocate-address --domain vpc --query '{AllocationId:AllocationId}' --output text`
    aws ec2 create-tags --resources ${EIP_ID} --tags "Key=Name,Value=${EIP_NAME}"
    error_exit
    echo ${EIP_ID}
}

associate_eip(){
    EIP_ID=`get_eip_id $1`
    INSTANCE_ID=`get_instance_id $2`
    aws ec2 associate-address --instance-id ${INSTANCE_ID} --allocation-id ${EIP_ID}
}

create_load_balancer() {
  SUBNET_1_ID=`get_subnet_id $1`
  SUBNET_2_ID=`get_subnet_id $2`
  SG_ID=`get_security_group_id $3`
  LOADBALANCER_NAME=$4
  LB_ARN=`aws elbv2 create-load-balancer --name ${LOADBALANCER_NAME} --subnets ${SUBNET_1_ID} ${SUBNET_2_ID} --security-groups ${SG_ID} --query 'LoadBalancers[0].LoadBalancerArn' --output text`
}

create_target_group(){
  VPC_ID=`get_vpc_id $1`
  TARGET_NAME=$2
  TARGET_GROUP_ARN=`aws elbv2 create-target-group --name ${TARGET_NAME} --protocol HTTP --port 80 --vpc-id ${VPC_ID} --query 'TargetGroups[0].TargetGroupArn' --output text`
  echo ${TARGET_GROUP_ARN}
}

register_targets(){
  INSTANCE_1_ID=`get_instance_id $1`
  INSTANCE_2_ID=`get_instance_id $2`
  TARGET_GROUP_ARN=$3
  aws elbv2 register-targets --target-group-arn ${TARGET_GROUP_ARN} --targets Id=${INSTANCE_1_ID} Id=${INSTANCE_2_ID}
}

create_listener(){
  LB_ARN=$1
  TARGET_GROUP_ARN=$2
  aws elbv2 create-listener --load-balancer-arn ${LB_ARN} --protocol HTTP --port 80  --default-actions Type=forward,TargetGroupArn=${TARGET_GROUP_ARN}
}

create_nat_gateway(){
    EIP_ID=`get_eip_id $1`
    SUBNET_ID=`get_subnet_id $2`
    NGW_NAME=$3
    NGW_ID=`get_ngw_id ${NGW_NAME}`
#    if [ ${NGW_ID} != "None" ]; then
#        log "Already EIP ${NGW_NAME} Exits - ID: ${NGW_ID}" ; return 0
#    fi 
    NGW_ID=`aws ec2 create-nat-gateway --subnet-id ${SUBNET_ID} --allocation-id ${EIP_ID} --query 'NatGateway.NatGatewayId' --output text`
    aws ec2 create-tags --resources ${NGW_ID} --tags "Key=Name,Value=${NGW_NAME}"
 }

add_ngw_to_route_table(){
    ROUTE_TABLE_ID=`get_route_table_id $1`
#    NGW_ID=`get_ngw_id $2`
    NGW_ID="nat-0fc9da85c72873f7d"
    RESULT=`aws ec2 create-route --route-table-id ${ROUTE_TABLE_ID} --destination-cidr-block 0.0.0.0/0 --gateway-id ${NGW_ID}`
    error_exit
    log "Added New Route to Route Table - ID: ${ROUTE_TABLE_ID}"
}

#==========================
# Main
#==========================

# create VPC
create_vpc ${VPC_CIDR} ${AWS_REGION} ${VPC_NAME}

# Create Subnet 
create_subnet ${SUBNET_PUB1_CIDR} ${SUBNET_PUB1_AZ} ${SUBNET_PUB1_NAME} ${VPC_NAME}
create_subnet ${SUBNET_PUB2_CIDR} ${SUBNET_PUB2_AZ} ${SUBNET_PUB2_NAME} ${VPC_NAME}
create_subnet ${SUBNET_PUB3_CIDR} ${SUBNET_PUB3_AZ} ${SUBNET_PUB3_NAME} ${VPC_NAME}
create_subnet ${SUBNET_PUB4_CIDR} ${SUBNET_PUB4_AZ} ${SUBNET_PUB4_NAME} ${VPC_NAME}
create_subnet ${SUBNET_PUB5_CIDR} ${SUBNET_PUB5_AZ} ${SUBNET_PUB5_NAME} ${VPC_NAME}
create_subnet ${SUBNET_PRI1_CIDR} ${SUBNET_PRI1_AZ} ${SUBNET_PRI1_NAME} ${VPC_NAME}
create_subnet ${SUBNET_PRI2_CIDR} ${SUBNET_PRI2_AZ} ${SUBNET_PRI2_NAME} ${VPC_NAME}

# Set up Internet Gateway
create_igw ${IGW_NAME}
attach_igw ${IGW_NAME} ${VPC_NAME}

# Setup Route Table
create_route_table ${ROUTE_TABLE_NAME} ${VPC_NAME}
add_igw_to_route_table ${ROUTE_TABLE_NAME} ${IGW_NAME}

associate_route_table ${ROUTE_TABLE_NAME} ${SUBNET_PUB1_NAME}
associate_route_table ${ROUTE_TABLE_NAME} ${SUBNET_PUB2_NAME}
associate_route_table ${ROUTE_TABLE_NAME} ${SUBNET_PUB3_NAME}
associate_route_table ${ROUTE_TABLE_NAME} ${SUBNET_PUB4_NAME}
associate_route_table ${ROUTE_TABLE_NAME} ${SUBNET_PUB5_NAME}

# Setup Security Group
create_security_group ${SECURITY_GROUP_WS_NAME} "${SECURITY_GROUP_WS_DESC}" ${VPC_NAME}
create_security_group ${SECURITY_GROUP_HTTP_NAME} "${SECURITY_GROUP_HTTP_DESC}" ${VPC_NAME}
create_security_group ${SECURITY_GROUP_SSH_NAME} "${SECURITY_GROUP_SSH_DESC}" ${VPC_NAME}
create_security_group ${SECURITY_GROUP_PRI_NAME} "${SECURITY_GROUP_PRI_DESC}" ${VPC_NAME}

add_rule_to_security_group ${SECURITY_GROUP_WS_NAME} 80 ${ALL_CIDR}
add_rule_to_security_group ${SECURITY_GROUP_WS_NAME} 22 ${ALL_CIDR}
add_rule_to_security_group ${SECURITY_GROUP_HTTP_NAME} 80 ${ALL_CIDR}
add_rule_to_security_group ${SECURITY_GROUP_SSH_NAME} 22 ${ALL_CIDR}
add_rule_to_security_group ${SECURITY_GROUP_PRI_NAME} 22 ${VPC_CIDR}

# Create Instance
create_instance ${INSTANCE_PUB1_NAME} ${SUBNET_PUB1_NAME} ${SECURITY_GROUP_WS_NAME} "WebServer"
create_instance ${INSTANCE_PUB2_NAME} ${SUBNET_PUB2_NAME} ${SECURITY_GROUP_WS_NAME} "WebServer"
create_instance ${INSTANCE_PUB3_NAME} ${SUBNET_PUB3_NAME} ${SECURITY_GROUP_WS_NAME} "WebServer"
create_instance ${INSTANCE_PRI1_NAME} ${SUBNET_PRI1_NAME} ${SECURITY_GROUP_WS_NAME} "WebServer"
create_instance ${INSTANCE_PRI2_NAME} ${SUBNET_PRI2_NAME} ${SECURITY_GROUP_WS_NAME} "WebServer"

#is_instance_ready ${INSTANCE_PUB1_NAME}

# Setup Load Balancer
create_load_balancer ${SUBNET_PUB4_NAME} ${SUBNET_PUB5_NAME} ${SECURITY_GROUP_HTTP_NAME} ${LOADBALANCER_NAME}
create_target_group ${VPC_NAME} ${TARGET_NAME}
register_targets ${INSTANCE_PUB1_NAME} ${INSTANCE_PUB2_NAME} ${TARGET_GROUP_ARN}
create_listener ${LB_ARN} ${TARGET_GROUP_ARN}

# Setup Nat Gateway in Subnet Pub 3
#create_eip ${EIP_NAME}
#create_nat_gateway ${EIP_NAME} ${SUBNET_PUB3_NAME} ${NGW_NAME}
create_route_table ${ROUTE_TABLE_PRI_NAME} ${VPC_NAME}
add_ngw_to_route_table ${ROUTE_TABLE_PRI_NAME} ${NGW_NAME}
associate_route_table ${ROUTE_TABLE_PRI_NAME} ${SUBNET_PRI1_NAME}
associate_route_table ${ROUTE_TABLE_PRI_NAME} ${SUBNET_PRI2_NAME}

# Create Key Pair
create_key_pair ${KEY_PAIR_NAME}

#------
#associate_eip ${EIP_NAME} ${INSTANCE_PUB3_NAME}
