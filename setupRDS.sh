  
#!/bin/bash
#******************************************************************************
#    AWS Setup RDS
#******************************************************************************
VPC_NAME="MyTestVPC"
SUBNET_PUB1_NAME="PUB1"
SUBNET_PUB2_NAME="PUB2"
SUBNET_PRI1_NAME="PRI1"
SUBNET_PRI2_NAME="PRI2"


# Allow Public Instance in VPC access DB

create_subnet_group() {
    SUBNET_PRI1_ID=`aws ec2 describe-subnets --filters Name=tag:Name,Values=${SUBNET_PRI1_NAME} --query 'Subnets[0].SubnetId' --output text`
    SUBNET_PRI2_ID=`aws ec2 describe-subnets --filters Name=tag:Name,Values=${SUBNET_PRI2_NAME} --query 'Subnets[0].SubnetId' --output text`

    # Create Subnet Group
    aws rds create-db-subnet-group --db-subnet-group-name 'MySubnetGroup' --db-subnet-group-description 'My Subnet Group' --subnet-ids "[\""${SUBNET_PRI1_ID}\"","\"${SUBNET_PRI2_ID}\""]"
}

create_security_group() {
    SG_NAME='DBAccess'
    SG_DESC='Security group for DB Access'

    SOURCE_GROUP_NAME="SSHAccess"
    SOURCE_GROUP_ID=`aws ec2 describe-security-groups --filters Name=group-name,Values=${SOURCE_GROUP_NAME} --query "SecurityGroups[0].GroupId" --output text`
    VPC_ID=`aws ec2 describe-vpcs --filters Name=tag:Name,Values=${VPC_NAME} --query 'Vpcs[0].VpcId' --output text`

    SG_ID=`aws ec2 create-security-group --group-name ${SG_NAME} --description "${SG_DESC}" --vpc-id ${VPC_ID} --output text`

    echo "Created ${SG_NAME} Security Gruop. ID: ${SG_ID}"
    aws ec2 authorize-security-group-ingress --group-id ${SG_ID} --protocol tcp --port 3306 --source-group ${SOURCE_GROUP_ID}
}

create_db_instance() {
    aws rds create-db-instance --db-instance-identifier myrds \
        --db-instance-class db.t3.micro \
        --engine mysql \
        --master-username admin \
        --master-user-password secret99 \
        --allocated-storage 20 \
        --db-subnet-group-name 'MySubnetGroup' \
        --vpc-security-group-ids ${SG_ID}
}

create_subnet_group
create_security_group
create_db_instance