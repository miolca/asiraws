#!/bin/bash
###############################################################
#This script assumes you have AWS CLI installed and configured.
#This script will help create VPC, Subnet, IGW, Route Table, RT Associations, Security Group and an EC2 Instance. 
#NOTE:  Set your region using aws configure to make sure you don't get any issues. I've used --region whereever possible. 
###############################################################
#   AUTHOR:    Nilesh Joshi
#   EMAIL:     nileshjoshi.aws@gmail.com
#   REVISIONS:
#               0.1.0  03/18/2017 - Initial release
###############################################################
 BLACK=$'\e[1;30m'
 RED=$'\e[1;31m'
 GREEN=$'\e[1;32m'
 YELLOW=$'\e[1;33m'
 BLUE=$'\e[1;34m'
 PINK=$'\e[1;33;4;35m'
 CYAN=$'\e[1;36m'
 WHITE=$'\e[1;37m'
 NOCOLOR=$'\e[1;0m'
 ###############################################################
# Decalre variables
AWS_REGION="us-east-1"
VPC_NAME="VPC_SH2"
VPC_CIDR="10.23.0.0/16"
SUBNET_CIDR="10.23.1.0/24"
SUBNET_AZ="us-east-1a"
SUBNET_NAME="subredsh2"
IGW_NAME="IGW-SH2"
RT_NAME="RT-SH2"
SG_NAME="SG-SH2"
InstName="EC2SH2"
###############################################################
# Create VPC
echo "$PINK Creating very much yours own Virtual Private Cloud... $NOCOLOR"
echo "${SEPARATOR2}"
VPC_ID=$(aws ec2 create-vpc --cidr-block $VPC_CIDR --query 'Vpc.{VpcId:VpcId}' --output text --region $AWS_REGION)
echo "$YELLOW VPCS $VPC_ID created victoriously!! $NOCOLOR"
echo "${SEPARATOR2}"
# Tag the VPC
echo "$PINK Naming your VPC.... $NOCOLOR"
echo "${SEPARATOR2}"
RESP=$(aws ec2 create-tags --resources $VPC_ID --tags "Key=Name,Value=$VPC_NAME" --region $AWS_REGION)
echo "$YELLOW VPCS $VPC_ID named as $VPC_NAME. $NOCOLOR"
echo "${SEPARATOR2}"
# Add DNS and DNS Hostname support
echo "$PINK Enabling DNS support for VPCS - $VPC_NAME $NOCOLOR"
echo "${SEPARATOR2}"
sleep 15
MOD_RESP=$(aws ec2 modify-vpc-attribute --vpc-id $VPC_ID --enable-dns-support "{\"Value\":true}")
MOD=RESP=$(aws ec2 modify-vpc-attribute --vpc-id $VPC_ID --enable-dns-hostnames "{\"Value\":true}")
echo "$YELLOW Enabled DNS support for VPC $VPC_NAME. $NOCOLOR"
echo "${SEPARATOR2}"
###############################################################
# Create IGW
echo "$PINK Creating Internet Gateway... $NOCOLOR"
echo "${SEPARATOR2}"
IGW=$(aws ec2 create-internet-gateway --output json)
IGW_ID=$(echo -e "$IGW" | /bin/jq '.InternetGateway.InternetGatewayId' | tr -d '"')
echo "$CYAN Internet Gateway ID '$IGW_ID' Created!! $NOCOLOR"
echo "${SEPARATOR2}"
# Name IGW
echo "$PINK Naming IGW... $NOCOLOR"
echo "${SEPARATOR2}"
RESP=$(aws ec2 create-tags --resources $IGW_ID --tags "Key=Name,Value=$IGW_NAME")
echo "$CYAN Internet Gateway named as $IGW_NAME. $NOCOLOR"
echo "${SEPARATOR2}"
# Attach IGW to VPC
echo "$PINK Attaching $IGW_NAME to VPC $VPC_NAME .......$NOCOLOR"
echo "${SEPARATOR2}"
RESP=$(aws ec2 attach-internet-gateway --vpc-id $VPC_ID --internet-gateway-id $IGW_ID --region $AWS_REGION)
echo "$CYAN Internet Gateway $IGW_NAME attached to $VPC_NAME. $NOCOLOR"
echo "${SEPARATOR2}"
###############################################################
# Create Public Subnet
echo "$PINK Creating the Subnet... $NOCOLOR"
echo "${SEPARATOR2}"
SUBNET_ID=$(aws ec2 create-subnet \
--vpc-id $VPC_ID \
--cidr-block $SUBNET_CIDR \
--availability-zone $SUBNET_AZ \
--query 'Subnet.{SubnetId:SubnetId}' --output text --region $AWS_REGION)
echo "$RED Subnet $SUBNET_ID is created in $SUBNET_AZ. $NOCOLOR"
echo "${SEPARATOR2}"
# Add tag to subnet
echo "$PINK Tagging the subnet.... $NOCOLOR"
echo "${SEPARATOR2}"
RESP=$(aws ec2 create-tags --resources $SUBNET_ID --tags "Key=Name,Value=$SUBNET_NAME" --region $AWS_REGION)
echo "$RED $SUBNET_ID is named as $SUBNET_NAME $NOCOLOR"
echo "${SEPARATOR2}"
###############################################################
# Create Route Table
echo "$PINK Creating the Route Table... $NOCOLOR"
echo "${SEPARATOR2}"
RT_ID=$(aws ec2 create-route-table --vpc-id $VPC_ID --query 'RouteTable.{RouteTableId:RouteTableId}' --output text --region $AWS_REGION)
echo "$GREEN Route Table ID '$RT_ID' created. $NOCOLOR"
echo "${SEPARATOR2}"
# Name the route table
echo "$PINK Naming the Route Table... $NOCOLOR"
echo "${SEPARATOR2}"
RESP=$(aws ec2 create-tags --resources $RT_ID --tags "Key=Name,Value=$RT_NAME")
echo "$GREEN Route Table ID $RT_ID named as $RT_NAME. $NOCOLOR"
echo "${SEPARATOR2}"
# Create route to IGW & associate subnet to RT
echo "$PINK Adding route to '0.0.0.0/0' via Internet Gateway and associating subnet $SUBNET_NAME to RT $RT_NAME. $NOCOLOR"
echo "${SEPARATOR2}"
OC=$(aws ec2 create-route --route-table-id $RT_ID --destination-cidr-block 0.0.0.0/0 --gateway-id $IGW_ID --region $AWS_REGION)
echo "$GREEN Favorably added route to '0.0.0.0/0' via Internet Gateway $IGW_NAME to Route Table $RT_NAME. $NOCOLOR"
OC1=$(aws ec2 associate-route-table --subnet-id $SUBNET_ID --route-table-id $RT_ID --region $AWS_REGION)
if [[ $(echo $OC1 | /bin/jq '.AssociationState.State') = *associated* ]]; then
    echo "${SEPARATOR2}"
    echo "$GREEN ALL GOOD, subnet $SUBNET_NAME is associated with Route Table $RT_NAME. $NOCOLOR"
else
    echo "${SEPARATOR2}"
    echo "$RED Something went wrong... Bad luck, check this manually please.... $NOCOLOR"
fi
echo "${SEPARATOR2}"
###############################################################
# Create Security Group and add apt rules to allow legitimate traffic
echo "$BLACK Creating Security Group..... $NOCOLOR"
echo "${SEPARATOR2}"
SG=$(aws ec2 create-security-group --group-name $SG_NAME --description "Allow SSH & ICMP Traffic" --vpc-id $VPC_ID --output json)
SG_ID=$(echo -e "$SG" |  /usr/bin/jq '.GroupId' | tr -d '"')
echo "$BLACK Security Group created fortuitously. $NOCOLOR"
echo "${SEPARATOR2}"
# Tagging 
echo "$BLACK Naming the Security Group... $NOCOLOR"
echo "${SEPARATOR2}"
RESP=$(aws ec2 create-tags --resources $SG_ID --tags "Key=Name,Value=$SG_NAME")
echo "$BLACK Security Group ID $SG_ID named as $SG_NAME. $NOCOLOR"
echo "${SEPARATOR2}"
# Enable Ingress traffic for SSH and ICMP
RESP=$(aws ec2 authorize-security-group-ingress --group-id $SG_ID --protocol tcp --port 22 --cidr 0.0.0.0/0)
RESP=$(aws ec2 authorize-security-group-ingress --group-id $SG_ID --protocol icmp --port -1 --cidr 0.0.0.0/0)
###############################################################
echo " "
printf "\n    ......\n  VPC '$VPC_NAME = $VPC_ID' is now ready.\n"
echo "${SEPARATOR2}"
echo "$PINK Use $SUBNET_NAME and Security Group $SG_NAME to create your AWS EC2 Instances. $NOCOLOR"
echo "${SEPARATOR2}"
###############################################################
# Create Key Pair and EC2 Instance
echo "$PINK Creating EC2 Instance.... $NOCOLOR"
echo "${SEPARATOR2}"
RESP=$(aws ec2 run-instances \
--image-id $(aws ssm get-parameters --names /aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2 --region $AWS_REGION --query 'Parameters[0].[Value]' --output text) \
--count 1 \
--instance-type t2.micro \
--key-name vockey \
--security-group-ids  $SG_ID \
--subnet-id $SUBNET_ID \
--associate-public-ip-address \
--tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value='$InstName'}]' \
--region $AWS_REGION)
INSTANCEID=$(aws ec2 describe-instances \
  --filter "Name=tag:Name,Values=$InstName" \
  --query "reverse(sort_by(Reservations, &Instances[0].LaunchTime)) | [0].Instances[0].InstanceId" \
  --output text)
RESP=$(aws ec2 wait instance-running --instance-ids $INSTANCEID)
PUB_IP=$(aws ec2 describe-instances --instance-ids $INSTANCEID \
  --query "Reservations[0].Instances[0].PublicIpAddress" --output text)
PUBDNS=$(aws ec2 describe-instances --instance-ids $INSTANCEID \
  --query "Reservations[0].Instances[0].PublicDnsName" --output text)
echo "$PINK EC2 Instance $InstName is ready to conenct, please use: ssh -i <PATH_TO_KEY> ec2-user@$PUB_IP OR $PUBDNS $NOCOLOR"
echo "${SEPARATOR2}"
###############################################################
