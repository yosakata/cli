aws autoscaling create-launch-configuration --image-id ami-06fdd07438a5e200a --instance-type t3.micro --key-name AWSLabsKeyPair-b3GWatUB7JVTVp8y2SxsTB --security-groups sg-027913394a7a42829 --user-data file:///home/ec2-user/as-bootstrap.sh --launch-configuration-name lab-lc

aws autoscaling create-auto-scaling-group --auto-scaling-group-name lab-as-group --launch-configuration-name lab-lc --load-balancer-names LabStack-ElasticL-1T2B2AC0EGBKI --max-size 4 --min-size 1 --vpc-zone-identifier subnet-00dfd090007386f0d,subnet-091eb1f9b20f1e296


aws autoscaling put-notification-configuration --auto-scaling-group-name lab-as-group 
--topic-arn arn:aws:sns:us-west-2:879862353223:lab-as-topic:64d37333-c624-445d-ab31-05d675cd7359 
--notification-types autoscaling:EC2_INSTANCE_LAUNCH autoscaling:EC2_INSTANCE_TERMINATE


aws autoscaling put-notification-configuration --auto-scaling-group-name lab-as-group --topic-arn arn:aws:sns:us-west-2:879862353223:lab-as-topic --notification-types autoscaling:EC2_INSTANCE_LAUNCH autoscaling:EC2_INSTANCE_TERMINATE

aws autoscaling put-scaling-policy --policy-name lab-scale-up-policy --auto-scaling-group-name lab-as-group --scaling-adjustment 1 --adjustment-type ChangeInCapacity --cooldown 300 --query 'PolicyARN' --output text

Load Balancer + Auto Scaling 機能を備えたWeb Serverを構築。

Create a Lanuch configuration

aws autoscaling create-launch-configuration 
           --image-id AMIID 
           --instance-type t3.micro 
           --key-name KEYNAME 
           --security-groups EC2SECURITYGROUPID 
           --user-data file:///home/ec2-user/as-bootstrap.sh 
           --launch-configuration-name lab-lc


#!/bin/sh
yum -y install httpd php mysql php-mysql
chkconfig httpd on
/etc/init.d/httpd start
cd /tmp
wget https://aws-tc-largeobjects.s3.us-west-2.amazonaws.com/SPLs/04/examplefiles-as.zip
unzip examplefiles-as.zip
mv examplefiles-as/* /var/www/html

Security group
- 

Create Auto Scaling Group

aws autoscaling create-auto-scaling-group 
      --auto-scaling-group-name lab-as-group 
      --launch-configuration-name lab-lc 
      --load-balancer-names LOADBALANCER 
      --max-size 4 
      --min-size 1 
      --vpc-zone-identifier SUBNET1,SUBNET2







aws autoscaling create-or-update-tags --tags "ResourceId=lab-as-group, ResourceType=auto-scaling-group, Key=Name, Value=AS-Web-Server, PropagateAtLaunch=true"

aws autoscaling put-notification-configuration --auto-scaling-group-name lab-as-group --topic-arn SNSARN --notification-types autoscaling:EC2_INSTANCE_LAUNCH autoscaling:EC2_INSTANCE_TERMINATE


aws autoscaling put-scaling-policy --policy-name lab-scale-up-policy --auto-scaling-group-name lab-as-group --scaling-adjustment 1 --adjustment-type ChangeInCapacity --cooldown 300 --query 'PolicyARN' --output text
aws autoscaling put-scaling-policy --policy-name lab-scale-down-policy --auto-scaling-group-name lab-as-group --scaling-adjustment -1 --adjustment-type ChangeInCapacity --cooldown 300 --query 'PolicyARN' --output text


aws autoscaling describe-scaling-activities --auto-scaling-group-name lab-as-group
