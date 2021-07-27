  #!/bin/bash
#******************************************************************************
#  This script set up environment to test EFS services
#  * 1 VPC
#  * 2 Subnets
#  * 2 EC instances (1 instance each subnet)
#  * 1 EFS file system
#******************************************************************************
source myfunctions.sh
source myparameters.sh
# Import shared parameters.

VPC_NAME="LinuxEnvVPC"
SUBNET_PUB_NAME="LinuxEnvSubnet"
FILE_SYSTEM_NAME='MyEFSTest'
SECURITY_GROUP_EFS_NAME="EFS_Access"
SECURITY_GROUP_EFS_DESC="Allow EFS Access"

#---------
# Main
#---------
#create_file_system ${FILE_SYSTEM_NAME}

# This does not work becasue --filters is not supported.
# get_file_system_id ${FILE_SYSTEM_NAME}

create_security_group ${SECURITY_GROUP_EFS_NAME} "${SECURITY_GROUP_EFS_DESC}" ${VPC_NAME}
add_rule_to_security_group ${SECURITY_GROUP_EFS_NAME} 2049 ${VPC_CIDR}

FILE_SYSTEM_ID=fs-9bac2d9f
create_mount_target ${SUBNET_PUB_NAME} ${FILE_SYSTEM_ID} ${SECURITY_GROUP_EFS_NAME}



