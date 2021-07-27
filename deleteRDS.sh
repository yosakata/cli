  
#!/bin/bash
#******************************************************************************
#    AWS Setup RDS
#******************************************************************************
VPC_NAME="MyTestVPC"
SUBNET_PUB1_NAME="PUB1"
SUBNET_PUB2_NAME="PUB2"
SUBNET_PRI1_NAME="PRI1"
SUBNET_PRI2_NAME="PRI2"
DB_NAME="myrds"
SG_NAME="DBAccess"

# Delete Security Group
delete_security_group (){

    SG_ID=`aws ec2 describe-security-groups --filters Name=group-name,Values=${SG_NAME} --query "SecurityGroups[*].[GroupId]" --output text`
    if [ ! -z ${SG_ID} ]; then
        aws ec2 delete-security-group --group-id ${SG_ID}
        echo "Deleted Security Group"
    else
        echo "No Security Group avaiable"
    fi
}

delete_subnet_group () {
    SUBNET_GROUP=`aws rds describe-db-subnet-groups --query DBSubnetGroups --output text | head -n 1 | cut -c-5`
    if [ ! -z ${SUBNET_GROUP} ]; then
        aws rds delete-db-subnet-group --db-subnet-group-name "MySubnetGroup"
        echo "Deleted Subnet Group"
    else
        echo "No Subnet Group exists"
    fi
}

delete_db_instance() {
    DEL_RESULT=`aws rds delete-db-instance --db-instance-identifier ${DB_NAME} --skip-final-snapshot`
    if [ -z ${DEL_RESULT} ]; then
        echo "No DB avaiable."
        return 
    fi 
    DB_STATUS=`aws ${DB_NAME} describe-db-instances --query DBInstances --output text | head -n 1 | cut -c-5`
    until [ ! -z "${DB_STATUS}" ]; do
        echo "DB Instance Status: ${DB_STATUS}"; sleep 60
        DB_STATUS=`aws ${DB_NAME} describe-db-instances --query DBInstances`
    done
    echo "Deleted DB Instance"

}

delete_db_instance
delete_security_group 
delete_subnet_group

