#!/bin/bash
# deploy-first-time.sh - Construye, sube imágenes y despliega en ECS

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REGION="us-east-1"
ECR_URI="$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com"

# Login ECR
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ECR_URI

# Build y push frontend
docker build -t $ECR_URI/tienda-perritos-frontend:latest ./frontend
docker push $ECR_URI/tienda-perritos-frontend:latest

# Build y push backend
docker build -t $ECR_URI/tienda-perritos-backend:latest ./backend
docker push $ECR_URI/tienda-perritos-backend:latest

# Build y push db
docker build -t $ECR_URI/tienda-perritos-db:latest ./db
docker push $ECR_URI/tienda-perritos-db:latest

# Obtener VPC y subnets
VPC_ID=$(aws ec2 describe-vpcs --filters "Name=isDefault,Values=true" --query "Vpcs[0].VpcId" --output text)
SUBNET_1=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" --query "Subnets[0].SubnetId" --output text)
SUBNET_2=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" --query "Subnets[1].SubnetId" --output text)

# Crear clúster
aws ecs create-cluster --cluster-name tienda-perritos-cluster --region $REGION

# Registrar task definitions
aws ecs register-task-definition --cli-input-json file://infrastructure/task-frontend.json --region $REGION
aws ecs register-task-definition --cli-input-json file://infrastructure/task-backend-db.json --region $REGION

# Crear target groups
TG_FRONTEND=$(aws elbv2 create-target-group --name tg-frontend --protocol HTTP --port 80 --target-type ip --vpc-id $VPC_ID --health-check-path / --query "TargetGroups[0].TargetGroupArn" --output text --region $REGION)
TG_BACKEND=$(aws elbv2 create-target-group --name tg-backend --protocol HTTP --port 3001 --target-type ip --vpc-id $VPC_ID --health-check-path /api/health --query "TargetGroups[0].TargetGroupArn" --output text --region $REGION)

# Crear ALB
SG_ALB=$(aws ec2 describe-security-groups --filters "Name=group-name,Values=tienda-alb-sg" --query "SecurityGroups[0].GroupId" --output text --region $REGION)
ALB_ARN=$(aws elbv2 create-load-balancer --name tienda-perritos-alb --subnets $SUBNET_1 $SUBNET_2 --security-groups $SG_ALB --scheme internet-facing --query "LoadBalancers[0].LoadBalancerArn" --output text --region $REGION)

# Crear listener
aws elbv2 create-listener --load-balancer-arn $ALB_ARN --protocol HTTP --port 80 --default-actions Type=forward,TargetGroupArn=$TG_FRONTEND --region $REGION

# Agregar regla para /api/*
LISTENER_ARN=$(aws elbv2 describe-listeners --load-balancer-arn $ALB_ARN --query "Listeners[0].ListenerArn" --output text --region $REGION)
aws elbv2 create-rule --listener-arn $LISTENER_ARN --priority 10 --conditions Field=path-pattern,Values=/api/* --actions Type=forward,TargetGroupArn=$TG_BACKEND --region $REGION

# Crear servicios ECS
SG_FRONTEND=$(aws ec2 describe-security-groups --filters "Name=group-name,Values=tienda-frontend-sg" --query "SecurityGroups[0].GroupId" --output text --region $REGION)
SG_BACKEND=$(aws ec2 describe-security-groups --filters "Name=group-name,Values=tienda-backend-sg" --query "SecurityGroups[0].GroupId" --output text --region $REGION)

aws ecs create-service --cluster tienda-perritos-cluster --service frontend-service --task-definition tienda-perritos-frontend:1 --desired-count 1 --launch-type FARGATE --network-configuration "awsvpcConfiguration={subnets=[$SUBNET_1,$SUBNET_2],securityGroups=[$SG_FRONTEND],assignPublicIp=ENABLED}" --load-balbers "targetGroupArn=$TG_FRONTEND,containerName=frontend,containerPort=80" --region $REGION

aws ecs create-service --cluster tienda-perritos-cluster --service backend-service --task-definition tienda-perritos-backend-db:1 --desired-count 1 --launch-type FARGATE --network-configuration "awsvpcConfiguration={subnets=[$SUBNET_1,$SUBNET_2],securityGroups=[$SG_BACKEND],assignPublicIp=ENABLED}" --load-balbers "targetGroupArn=$TG_BACKEND,containerName=backend,containerPort=3001" --region $REGION

echo "ALB DNS: $(aws elbv2 describe-load-balancers --load-balancer-arns $ALB_ARN --query 'LoadBalancers[0].DNSName' --output text --region $REGION)"
