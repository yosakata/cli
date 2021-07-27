#!/bin/bash

log(){
    echo `date "+%Y-%m-%d%n%H:%M:%S\t"` $1
}

error_exit(){
    if [ $? -ne 0 ]; then 
        echo "$1" 1>&2
        exit 1
    fi
}

get_file_system_id(){
    FILE_SYSTEM_NAME=$1
    aws efs describe-file-systems --filters Name=tag:Name,Values=${FILE_SYSTEM_NAME} --query 'FileSystems[0].FileSystemId' --output text
}

get_vpc_id(){
    VPC_NAME=$1
    aws ec2 describe-vpcs --filters Name=tag:Name,Values=${VPC_NAME} --query 'Vpcs[0].VpcId' --output text
}

get_igw_id(){
    IGW_NAME=$1
    aws ec2 describe-internet-gateways --filters Name=tag:Name,Values=${IGW_NAME} --query "InternetGateways[0].InternetGatewayId" --output text
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
    KEY_PAIR_NAME=$1
    rm -f ${KEY_PAIR_NAME}.pem
    aws ec2 delete-key-pair --key-name ${KEY_PAIR_NAME}
    aws ec2 create-key-pair --key-name ${KEY_PAIR_NAME} --query 'KeyMaterial' --output text > ${KEY_PAIR_NAME}.pem
    chmod 400 ${KEY_PAIR_NAME}.pem
    error_exit
    log "Created KeyPair ${KEY_PAIR_NAME}"
}

create_vpc() {
    VPC_CIDR=$1
    VPC_NAME=$2
    VPC_ID=`get_vpc_id ${VPC_NAME}`
    if [ ${VPC_ID} != "None" ]; then
        log "Already VPC ${VPC_NAME} Exits - ID: ${VPC_ID}" ; return 0
    fi
    VPC_ID=`aws ec2 create-vpc --cidr-block ${VPC_CIDR} --query Vpc.VpcId --output text`
    aws ec2 create-tags --resources ${VPC_ID} --tags "Key=Name,Value=${VPC_NAME}"
    error_exit
    log "Created VPC - ID: ${VPC_ID}"
}

create_subnet () {
    SUBNET_CIDR=$1
    AZ=$2
    SUBNET_NAME=$3
    VPC_ID=`get_vpc_id $4`
    SUBNET_ID=`get_subnet_id ${SUBNET_NAME}`
    if [ ${SUBNET_ID} != "None" ]; then
        log "Already Subnet ${SUBNET_NAME} Exits - ID: ${SUBNET_ID}" ; return 0
    fi 
    SUBNET_ID=`aws ec2 create-subnet --vpc-id ${VPC_ID} --cidr-block ${SUBNET_CIDR} --availability-zone ${AZ} --query Subnet.SubnetId --output text`
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
    RESULT=`aws ec2 create-tags --resources ${ROUTE_TABLE_ID}  --tags "Key=Name,Value=${ROUTE_TABLE_NAME}"`
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
    SG_NAME=$1
    SG_DESC=$2
    VPC_ID=`get_vpc_id $3`
    SECURITY_GROUP_ID=`get_security_group_id ${SG_NAME}`
    if [ ${SECURITY_GROUP_ID} != "None" ]; then
        log "Already VPC ${SG_NAME} Exits - ID: ${SECURITY_GROUP_ID}" ; return 0
    fi 
    SECURITY_GROUP_ID=`aws ec2 create-security-group --group-name ${SG_NAME} --description "${SG_DESC}" --vpc-id ${VPC_ID} --query GroupId --output text`
    aws ec2 create-tags --resources ${SECURITY_GROUP_ID} --tags "Key=Name,Value=${SG_NAME}" 
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
        INSTANCE_ID=`aws ec2 run-instances --image-id ${AMI} --count 1 --instance-type t3.micro --key-name ${KEY_PAIR_NAME} --security-group-ids ${SG_ID} --subnet-id ${SUBNET_ID} --associate-public-ip-address --user-data file://userdata/webserver_setup.sh --query Instances[0].InstanceId --output text`
    elif [ "$4" == "public" ]; then
        INSTANCE_ID=`aws ec2 run-instances --image-id ${AMI} --count 1 --instance-type t3.micro --key-name ${KEY_PAIR_NAME} --security-group-ids ${SG_ID} --subnet-id ${SUBNET_ID}  --associate-public-ip-address --query Instances[0].InstanceId --output text`
    elif [ "$4" == "PrivateWebServer" ]; then
        INSTANCE_ID=`aws ec2 run-instances --image-id ${AMI} --count 1 --instance-type t3.micro --key-name ${KEY_PAIR_NAME} --security-group-ids ${SG_ID} --subnet-id ${SUBNET_ID} --user-data file://userdata/webserver_setup.sh --query Instances[0].InstanceId --output text`
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
    #NGW_ID=`get_ngw_id ${NGW_NAME}`
    NGW_ID="nat-016e0c1641ee659d9"
    RESULT=`aws ec2 create-route --route-table-id ${ROUTE_TABLE_ID} --destination-cidr-block 0.0.0.0/0 --gateway-id ${NGW_ID}`
    error_exit
    log "Added New Route to Route Table - ID: ${ROUTE_TABLE_ID}"
}


create_file_system() {
    FILE_SYSTEM_NAME=$1
    FILE_SYSTEM_ID=`aws efs create-file-system --creation-token ${FILE_SYSTEM_NAME} --performance-mode generalPurpose --throughput-mode bursting --tags Key=Name,Value=${FILE_SYSTEM_NAME} --query 'FileSystemId' --output text`
    error_exit
    log "Created EFS File System - ID: ${FILE_SYSTEM_ID}"
}

create_mount_target() {
    SUBNET_ID=`get_subnet_id $1`
#    FILE_SYSTEM_ID=`get_file_system_id $2` <-- This does not work.
    FILE_SYSTEM_ID=$2
    SG_ID=`get_security_group_id $3`

    aws efs create-mount-target \
        --file-system-id ${FILE_SYSTEM_ID} \
        --subnet-id ${SUBNET_ID} \
        --security-group ${SG_ID} 
    error_exit
    log "Created Mount Target"
}