  
#!/bin/bash
#******************************************************************************
#    Delete My Test Web Server Test Environment
#******************************************************************************

AWS_REGION="us-west-2"
VPC_NAME="WebServerVPC"
RT_NAME="WebServerRouteTable"
IGW_NAME="WebServerIGW"

SECURITY_GROUP_NAME="WebserverSSHAccess"
SECURITY_GROUP_PRI_NAME="SSHAccessWithinVPC"

KEY_PAIR_NAME="WebServerKeyPair"

SUBNET_PUB1_NAME="WebServerPub1"
SUBNET_PUB2_NAME="WebServerPub2"
SUBNET_PRI1_NAME="WebServerPri1"
SUBNET_PRI2_NAME="WebServerPri2"

INSTANCE_PUB1_NAME="WebServerInstancePub1"
INSTANCE_PUB2_NAME="WebServerInstancePub2"
INSTANCE_PRI1_NAME="WebServerInstancePri1"
INSTANCE_PRI2_NAME="WebServerInstancePri2"


error_exit(){
    if [ $? -ne 0 ]; then 
        echo "$1" 1>&2
        exit 1
    fi
}

log(){
    echo `date "+%Y-%m-%d%n%H:%M:%S\t"` $1
}

delete_key_pair(){
    KEYPAIR_NAME=$1
    aws ec2 delete-key-pair --key-name ${KEYPAIR_NAME}
    rm -f ${KEYPAIR}.pem
    log "Deleted Key Pair"
}

terminate_instance (){
    INSTANCE_NAME=$1
    INSTANCE_ID=`aws ec2 describe-instances --filters Name=tag:Name,Values=${INSTANCE_NAME} Name=instance-state-name,Values=running --query "Reservations[0].Instances[0].InstanceId" --output text`
    if [ ${INSTANCE_ID} != "None" ]; then 
        result=`aws ec2 terminate-instances --instance-ids ${INSTANCE_ID}`
        error_exit
        INSTANCE_STATUS=`aws ec2 describe-instances --instance-id ${INSTANCE_ID} --query "Reservations[0].Instances[0].State.Name" --output text`
        until [ ${INSTANCE_STATUS} = "terminated" ]
        do
            log "${INSTANCE_NAME} ${INSTANCE_ID} Status: ${INSTANCE_STATUS}" ; sleep 10
            INSTANCE_STATUS=`aws ec2 describe-instances --instance-id ${INSTANCE_ID} --query "Reservations[0].Instances[0].State.Name" --output text`
        done
        log "${INSTANCE_NAME} ${INSTANCE_ID} Status: Terminated"
    fi
}

release_EIP () {
    EIP_ID=`aws ec2 describe-addresses --query 'Addresses[0].AllocationId' --output text`
    while [ ${EIP_ID} != "None" ]
    do
        aws ec2 release-address --allocation-id ${EIP_ID}
        if [ $? -eq 0 ]; then
            log "EIP Released"
        fi
        EIP_ID=`aws ec2 describe-addresses --query 'Addresses[0].AllocationId' --output text`
    done
}

delete_security_group (){
    SG_ID=`aws ec2 describe-security-groups --filters Name=group-name,Values=$1 --query "SecurityGroups[*].[GroupId]" --output text`
    if [ ! -z ${SG_ID} ]; then
        aws ec2 delete-security-group --group-id ${SG_ID}
        error_exit
        log "Deleted Security Group - ID: ${SG_ID}"
    fi
}

delete_igw () {
    IGW_ID=`aws ec2 describe-internet-gateways --filters Name=tag:Name,Values=$1 --query 'InternetGateways[0].InternetGatewayId' --output text`
    VPC_ID=`aws ec2 describe-internet-gateways --filters Name=tag:Name,Values=$1 --query 'InternetGateways[0].Attachments[0].VpcId' --output text`
    if [ ${IGW_ID} != "None" ]; then
        aws ec2 detach-internet-gateway --internet-gateway-id ${IGW_ID} --vpc-id ${VPC_ID}
        aws ec2 delete-internet-gateway --internet-gateway-id ${IGW_ID}
        error_exit
        log "Deleted Internet Gateway - ID: ${IGW_ID}"
    fi
}

delete_subnet() {
    SUBNET_NAME=$1
    SUBNET_ID=`aws ec2 describe-subnets --filters Name=tag:Name,Values=${SUBNET_NAME} --query 'Subnets[0].SubnetId' --output text`
    if [ ${SUBNET_ID} != "None" ]; then
        aws ec2 delete-subnet --subnet-id ${SUBNET_ID}
        error_exit
        log "Deleted Subnet ${SUBNET_NAME} - ID: ${SUBNET_ID}"
    fi
}

delete_route_table() {
    RT_ID=`aws ec2 describe-route-tables --filters Name=tag:Name,Values=$1 --query 'RouteTables[0].RouteTableId' --output text`
    if [ ${RT_ID} != "None" ]; then
        aws ec2 delete-route-table --route-table-id ${RT_ID} ; 
        error_exit; log "Deleted Route Table - ID: ${RT_ID}"
    fi 
}

delete_vpc() {
    VPC_ID=`aws ec2 describe-vpcs --filters Name=tag:Name,Values=$1 --query 'Vpcs[0].VpcId' --output text`
    if [ ${VPC_ID} != "None" ]; then
        aws ec2 delete-vpc --vpc-id ${VPC_ID}
        error_exit
        log "Deleted VPC - ID: ${VPC_ID}"
    fi 
}

terminate_instance ${INSTANCE_PUB1_NAME}
terminate_instance ${INSTANCE_PUB2_NAME}
terminate_instance ${INSTANCE_PRI1_NAME}
terminate_instance ${INSTANCE_PRI2_NAME}

release_EIP
delete_security_group ${SECURITY_GROUP_NAME}
delete_security_group ${SECURITY_GROUP_PRI_NAME}
delete_igw ${IGW_NAME}
delete_subnet ${SUBNET_PUB1_NAME} 
delete_subnet ${SUBNET_PUB2_NAME} 
delete_subnet ${SUBNET_PRI1_NAME} 
delete_subnet ${SUBNET_PRI2_NAME} 
delete_route_table ${RT_NAME}
delete_vpc ${VPC_NAME}
delete_key_pair ${KEYPAIR_NAME}
