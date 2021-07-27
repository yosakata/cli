  
#!/bin/bash
#******************************************************************************
#    AWS EBS Setup
#******************************************************************************

# Create EBS Volume
echo "Create EBS Volume"
VOL_ID=`aws ec2 create-volume --size 10 --region us-west-2 --availability-zone us-west-2a --volume-type gp2 --query "VolumeId" --output text`
INS_ID=`aws ec2 describe-instances --filters Name=tag:Name,Values='MyTestInstance' --query "Reservations[0].Instances[0].InstanceId" --output text`

echo "Attach EBS Volume to instance"
aws ec2 attach-volume --volume-id ${VOL_ID} --instance-id ${INS_ID} --device /dev/sdf

# On Linux
#ファイルシステムを作成
sudo mkfs -t ext4 /dev/sdf

# EC2内で、Mount
sudo mkdir /mnt/ebstest2
sudo mount /dev/sdf /mnt/data-store/

sudo mount /dev/sdg /mnt/ebstest2

# Snapshotを作成
aws ec2 create-snapshot --volume-id $VOL_ID --description "MySnapshot"

# EC2内で、Unmount
sudo umount -d /dev/sdf


# Detach 
aws ec2 detach-volume --volume-id $VOL_ID

# Delete
aws ec2 delete-volume --volume-id $VOL_ID


# Create Volume from Snapshot
#aws ec2 create-volume --size 80 --region us-west-2 --availability-zone us-west-2a --snapshot-id {ID} --volume-type io1 --iops 1000
