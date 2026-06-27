# Crear ECR repositorios
Write-Host "Creando repositorios ECR..."
aws ecr create-repository --repository-name tienda-perritos-frontend --region us-east-1
aws ecr create-repository --repository-name tienda-perritos-backend --region us-east-1

# VPC por defecto
$VPC_ID = (aws ec2 describe-vpcs --filters "Name=isDefault,Values=true" --query "Vpcs[0].VpcId" --output text)
$SUBNETS = (aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" --query "Subnets[*].SubnetId" --output text)

# Security Groups
Write-Host "Creando Security Groups..."
$SG_ALB = (aws ec2 create-security-group --group-name "tienda-alb-sg" --description "ALB SG" --vpc-id $VPC_ID --query "GroupId" --output text)
$SG_FRONTEND = (aws ec2 create-security-group --group-name "tienda-frontend-sg" --description "Frontend ECS SG" --vpc-id $VPC_ID --query "GroupId" --output text)
$SG_BACKEND = (aws ec2 create-security-group --group-name "tienda-backend-sg" --description "Backend ECS SG" --vpc-id $VPC_ID --query "GroupId" --output text)

# Reglas SG
aws ec2 authorize-security-group-ingress --group-id $SG_ALB --protocol tcp --port 80 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id $SG_FRONTEND --protocol tcp --port 80 --source-group $SG_ALB
aws ec2 authorize-security-group-ingress --group-id $SG_BACKEND --protocol tcp --port 3001 --source-group $SG_ALB

Write-Host "SG_ALB=$SG_ALB SG_FRONTEND=$SG_FRONTEND SG_BACKEND=$SG_BACKEND"
Write-Host "VPC=$VPC_ID SUBNETS=$SUBNETS"
