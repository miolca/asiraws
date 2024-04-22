###############################################################################
#      Creación de una VPC y una instancia EC2 Ubuntu Server 22.04
#      con IPs elásticas
#      en AWS con AWS CLI
#
#      Utilizado para AWS Academy Learning Lab
###############################################################################

AWS_VPC_CIDR_BLOCK=10.22.0.0/16
AWS_Subred_CIDR_BLOCK=10.22.1.0/24
AWS_IP_UbuntuServer=10.22.1.100
AWS_Proyecto=DAW

echo "######################################################################"
echo "Creación de una VPC y una instancia EC2 Ubuntu Server 22.04 "
echo "Se van a crear con los siguientes valores:"
echo "AWS_VPC_CIDR_BLOCK:    " $AWS_VPC_CIDR_BLOCK
echo "AWS_Subred_CIDR_BLOCK: " $AWS_Subred_CIDR_BLOCK
echo "AWS_IP_UbuntuServer:   " $AWS_IP_UbuntuServer
echo "AWS_Proyecto:          " $AWS_Proyecto
echo "######################################################################"
echo "############## Crear VPC, Subred #####################"
echo "######################################################################"
echo "Creando VPC..."

AWS_ID_VPC=$(aws ec2 create-vpc \
  --cidr-block $AWS_VPC_CIDR_BLOCK \
  --amazon-provided-ipv6-cidr-block \
  --query 'Vpc.{VpcId:VpcId}' \
  --output text)

## Habilitar los nombres DNS para la VPC
aws ec2 modify-vpc-attribute \
  --vpc-id $AWS_ID_VPC \
  --enable-dns-hostnames "{\"Value\":true}"

## Crear una subred publica con su etiqueta
echo "Creando Subred..."
AWS_ID_SubredPublica=$(aws ec2 create-subnet \
  --vpc-id $AWS_ID_VPC \
  --cidr-block $AWS_Subred_CIDR_BLOCK \
  --availability-zone us-east-1a \
  --query 'Subnet.{SubnetId:SubnetId}' \
  --output text)

## Habilitar la asignación automática de IPs públicas en la subred pública
aws ec2 modify-subnet-attribute \
  --subnet-id $AWS_ID_SubredPublica \
  --map-public-ip-on-launch

###############################################################################
####################       UBUNTU SERVER     ##################################
###############################################################################

## Crear un grupo de seguridad Ubuntu Server
echo "########################### Ubuntu Server ############################"
echo "######################################################################"
echo "Creando grupo de seguridad Ubuntu Server..."
AWS_ID_GrupoSeguridad_Ubuntu=$(aws ec2 create-security-group \
  --vpc-id $AWS_ID_VPC \
  --group-name $AWS_Proyecto-us-sg \
  --description "$AWS_Proyecto-us-sg" \
  --output text)

echo "ID Grupo de seguridad de ubuntu: " $AWS_ID_GrupoSeguridad_Ubuntu

echo "Añadiendo reglas de seguridad al grupo de seguridad Ubuntu Server..."
## Abrir los puertos de acceso a la instancia
aws ec2 authorize-security-group-ingress \
  --group-id $AWS_ID_GrupoSeguridad_Ubuntu \
  --ip-permissions '[{"IpProtocol": "tcp", "FromPort": 22, "ToPort": 22, "IpRanges": [{"CidrIp": "0.0.0.0/0", "Description": "Allow SSH"}]}]'

aws ec2 authorize-security-group-ingress \
  --group-id $AWS_ID_GrupoSeguridad_Ubuntu \
  --ip-permissions '[{"IpProtocol": "tcp", "FromPort": 80, "ToPort": 80, "IpRanges": [{"CidrIp": "0.0.0.0/0", "Description": "Allow HTTP"}]}]'

aws ec2 authorize-security-group-ingress \
  --group-id $AWS_ID_GrupoSeguridad_Ubuntu \
  --ip-permissions '[{"IpProtocol": "tcp", "FromPort": 53, "ToPort": 53, "IpRanges": [{"CidrIp": "0.0.0.0/0", "Description": "Allow DNS(TCP)"}]}]'

aws ec2 authorize-security-group-ingress \
  --group-id $AWS_ID_GrupoSeguridad_Ubuntu \
  --ip-permissions '[{"IpProtocol": "UDP", "FromPort": 53, "ToPort": 53, "IpRanges": [{"CidrIp": "0.0.0.0/0", "Description": "Allow DNS(UDP)"}]}]'

## Añadirle etiqueta al grupo de seguridad
echo "Añadiendo etiqueta al grupo de seguridad Ubuntu Server..."
aws ec2 create-tags \
--resources $AWS_ID_GrupoSeguridad_Ubuntu \
--tags "Key=Name,Value=$AWS_Proyecto-us-sg" 

###############################################################################
## Crear una instancia EC2  (con una imagen de ubuntu 22.04)
###############################################################################
echo ""
echo "Creando instancia EC2 Ubuntu  ##################################"
AWS_AMI_Ubuntu_ID=ami-052efd3df9dad4825
AWS_EC2_INSTANCE_ID=$(aws ec2 run-instances \
  --image-id $AWS_AMI_Ubuntu_ID \
  --instance-type t2.micro \
  --key-name vockey \
  --monitoring "Enabled=false" \
  --security-group-ids $AWS_ID_GrupoSeguridad_Ubuntu \
  --subnet-id $AWS_ID_SubredPublica \
  --private-ip-address $AWS_IP_UbuntuServer \
  --query 'Instances[0].InstanceId' \
  --output text)


