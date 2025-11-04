#!/usr/bin/env bash
set -euo pipefail

REGION="${AWS_DEFAULT_REGION:-us-east-2}"
NAME="sample-app"
echo "[*] Region = ${REGION}"

# VPC par défaut (juste pour log)
DEFAULT_VPC=$(aws ec2 describe-vpcs --filters Name=isDefault,Values=true \
  --query 'Vpcs[0].VpcId' --output text)
echo "    Default VPC: ${DEFAULT_VPC}"

# SG : créer s'il n'existe pas
echo "[*] Checking/creating Security Group '${NAME}'..."
SG_ID=$(aws ec2 describe-security-groups --filters "Name=group-name,Values=${NAME}" \
  --query 'SecurityGroups[0].GroupId' --output text 2>/dev/null || true)
if [ -z "${SG_ID}" ] || [ "${SG_ID}" = "None" ]; then
  SG_ID=$(aws ec2 create-security-group --group-name "${NAME}" \
    --description "Allow HTTP traffic into ${NAME}" --query 'GroupId' --output text)
  echo "    Created SG: ${SG_ID}"
  aws ec2 authorize-security-group-ingress --group-id "${SG_ID}" \
    --protocol tcp --port 80 --cidr 0.0.0.0/0 >/dev/null
  echo "    Ingress 80/tcp opened to 0.0.0.0/0"
else
  echo "    Found SG: ${SG_ID}"
fi

# AMI Amazon Linux 2023 (kernel 6.1)
echo "[*] Resolving AL2023 AMI via SSM..."
AMI_ID=$(aws ssm get-parameters --names \
  /aws/service/ami-amazon-linux-latest/al2023-ami-kernel-6.1-x86_64 \
  --query 'Parameters[0].Value' --output text)
echo "    AMI_ID = ${AMI_ID}"

# Instance Free Tier
INSTANCE_TYPE="t3.micro"
echo "    INSTANCE_TYPE = ${INSTANCE_TYPE}"

# Lancer l'instance
echo "[*] Launching EC2 instance..."
INSTANCE_ID=$(aws ec2 run-instances \
  --image-id "${AMI_ID}" \
  --instance-type "${INSTANCE_TYPE}" \
  --security-group-ids "${SG_ID}" \
  --user-data file://user-data.sh \
  --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=${NAME}}]" \
  --query 'Instances[0].InstanceId' --output text)
echo "    Instance = ${INSTANCE_ID}"

# Attendre running
echo "[*] Waiting for instance to be running..."
aws ec2 wait instance-running --instance-ids "${INSTANCE_ID}"
echo "    Instance is running."

# IP publique
PUBLIC_IP=$(aws ec2 describe-instances --instance-ids "${INSTANCE_ID}" \
  --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)

echo "---------------------------------------"
echo "INSTANCE_ID      = ${INSTANCE_ID}"
echo "SG_ID            = ${SG_ID}"
echo "PUBLIC_IP        = ${PUBLIC_IP}"
echo "---------------------------------------"
echo "Test:  http://${PUBLIC_IP}"
