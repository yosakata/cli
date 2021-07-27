  
#!/bin/bash
#******************************************************************************
#    AWS Setup RDS
#******************************************************************************
call_API(){
  RES=`$1`
  echo `date "+%Y-%m-%dT%H:%M:%S,"; echo $1`
}

ACL_NAME="my-deny-acl"
#ACL_NAME="my-allow-acl"
echo ${ACL_NAME}
SUBNET_1_ID="subnet-0ee85a0aad353003c"

ACL_ID=`aws ec2 describe-network-acls --filters Name=tag:Name,Values=${ACL_NAME} --query 'NetworkAcls[0].NetworkAclId' --output text`

#ASSO_ID=`aws ec2 describe-network-acls --filters Name=association.subnet-id,Values=${SUBNET_1_ID} Name=association.network-acl-id,values=${ACL_ID} --query 'NetworkAcls[0].Associations[0].NetworkAclAssociationId' --output text`

aws ec2 describe-network-acls --filters Name=association.subnet-id,Values=${SUBNET_1_ID} 

exit 


ACL_ID=`aws ec2 describe-network-acls --filters Name=tag:Name,Values=${ACL_NAME} --query 'NetworkAcls[0].NetworkAclId' --output text`
echo ${ASSO_ID}
echo ${ACL_ID}

aws ec2 replace-network-acl-association --association-id ${ASSO_ID} --network-acl-id ${ACL_ID}



ACL_NAME="my-allow-acl"
SUBNET_2_ID="subnet-0e26ecdfb05b0bc90"
echo ${ACL_NAME}

ASSO_ID=`aws ec2 describe-network-acls --filters Name=association.subnet-id,Values=${SUBNET_2_ID} --query 'NetworkAcls[0].Associations[0].NetworkAclAssociationId' --output text`
ACL_ID=`aws ec2 describe-network-acls --filters Name=tag:Name,Values=${ACL_NAME} --query 'NetworkAcls[0].NetworkAclId' --output text`

echo ${ASSO_ID}
echo ${ACL_ID}

aws ec2 replace-network-acl-association --association-id ${ASSO_ID} --network-acl-id ${ACL_ID}
