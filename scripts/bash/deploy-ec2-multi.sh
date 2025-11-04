#!/usr/bin/env bash
set -euo pipefail

REGION="${AWS_DEFAULT_REGION:-us-east-2}"
COUNT="${1:-1}"            # Nombre d'instances à lancer (paramètre $1), défaut = 1
NAME="sample-app"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
USER_DATA_FILE="$SCRIPT_DIR/user-data.sh"

if [ ! -f "$USER_DATA_FILE" ]; then
  echo "ERROR: user-data file not found: $USER_DATA_FILE"
  exit 1
fi

echo "[*] Region = ${REGION}"
echo "[*] Count  = ${COUNT}"
echo "    Default VPC: $(aws ec2 describe-vpcs --filters Name=isDefault,Values=true --query 'Vpcs[0].VpcId' --output text)"

# 1) Security group (create if missing)
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

# 2) AMI (Amazon Linux 2023 via SSM) + instance type (free tier-friendly)
echo "[*] Resolving AL2023 AMI via SSM..."
AMI_ID=$(aws ssm get-parameters --names /aws/service/ami-amazon-linux-latest/al2023-ami-kernel-6.1-x86_64 \
  --query 'Parameters[0].Value' --output text)
echo "    AMI_ID = ${AMI_ID}"

INSTANCE_TYPE="t3.micro"
echo "    INSTANCE_TYPE = ${INSTANCE_TYPE}"

# 3) Lancer instances
echo "[*] Launching ${COUNT} EC2 instance(s)..."
INSTANCE_IDS=$(aws ec2 run-instances \
  --image-id "${AMI_ID}" \
  --instance-type "${INSTANCE_TYPE}" \
  --security-group-ids "${SG_ID}" \
  --user-data file://"$USER_DATA_FILE" \
  --count "${COUNT}" \
  --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=${NAME}},{Key=Group,Value=${NAME}}]" \
  --query 'Instances[].InstanceId' --output text)

# split on whitespace into $@
set -- $INSTANCE_IDS
if [ $# -eq 0 ]; then
  echo "ERROR: no instances launched."
  exit 1
fi

echo "    Launched instance IDs: $@"

# 4) Attendre qu'elles soient running
echo "[*] Waiting for instances to be running..."
aws ec2 wait instance-running --instance-ids "$@"
echo "    Instances are running."

# 5) Afficher IPs / état
echo "[*] Instances (ID / PublicIp / State / LaunchTime):"
aws ec2 describe-instances --instance-ids "$@" \
  --query 'Reservations[].Instances[].[InstanceId,PublicIpAddress,State.Name,LaunchTime]' --output table

echo "---------------------------------------"
echo "Group = ${NAME}"
echo "SG_ID = ${SG_ID}"
echo "Count = ${COUNT}"
echo "---------------------------------------"
echo "Tu peux vérifier avec : aws ec2 describe-instances --filters Name=tag:Group,Values=${NAME}"
