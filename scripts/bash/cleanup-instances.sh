#!/usr/bin/env bash
set -euo pipefail

# Script de nettoyage des ressources AWS créées pendant le TD2
# Usage: ./cleanup-instances.sh [TAG_VALUE]

TAG_VALUE="${1:-sample-app}"
REGION="${AWS_DEFAULT_REGION:-us-east-2}"

echo "========================================="
echo "  AWS TD2 Cleanup Script"
echo "========================================="
echo "Region: ${REGION}"
echo "Tag filter: Name=tag:Name,Values=${TAG_VALUE}*"
echo ""

# 1) Lister et terminer les instances
echo "[1/4] Checking for running instances..."
INSTANCE_IDS=$(aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=${TAG_VALUE}*" "Name=instance-state-name,Values=running,stopped,pending" \
  --query 'Reservations[*].Instances[*].InstanceId' \
  --output text)

if [ -z "$INSTANCE_IDS" ]; then
  echo "    No instances found with tag ${TAG_VALUE}*"
else
  echo "    Found instances: ${INSTANCE_IDS}"
  echo "    Terminating instances..."
  aws ec2 terminate-instances --instance-ids ${INSTANCE_IDS} > /dev/null
  echo "    ✅ Instances terminated"
  
  # Attendre que les instances soient bien terminées
  echo "    Waiting for instances to terminate..."
  aws ec2 wait instance-terminated --instance-ids ${INSTANCE_IDS}
  echo "    ✅ Instances fully terminated"
fi

# 2) Supprimer les security groups
echo ""
echo "[2/4] Checking for security groups..."
SG_IDS=$(aws ec2 describe-security-groups \
  --filters "Name=group-name,Values=${TAG_VALUE}*" \
  --query 'SecurityGroups[*].GroupId' \
  --output text 2>/dev/null || true)

if [ -z "$SG_IDS" ]; then
  echo "    No security groups found with name ${TAG_VALUE}*"
else
  echo "    Found security groups: ${SG_IDS}"
  for SG_ID in $SG_IDS; do
    echo "    Deleting security group ${SG_ID}..."
    aws ec2 delete-security-group --group-id "${SG_ID}" 2>/dev/null || {
      echo "    ⚠️  Could not delete ${SG_ID} (may have dependencies or in use)"
    }
  done
  echo "    ✅ Security groups cleanup attempted"
fi

# 3) Lister les AMIs Packer (optionnel - ne les supprime pas par défaut)
echo ""
echo "[3/4] Checking for Packer AMIs..."
AMI_IDS=$(aws ec2 describe-images \
  --owners self \
  --filters "Name=name,Values=sample-app-packer-*" \
  --query 'Images[*].[ImageId,Name,CreationDate]' \
  --output text 2>/dev/null || true)

if [ -z "$AMI_IDS" ]; then
  echo "    No Packer AMIs found"
else
  echo "    Found Packer AMIs:"
  echo "$AMI_IDS" | while read -r LINE; do
    echo "      - $LINE"
  done
  echo ""
  echo "    ⚠️  AMIs NOT deleted automatically (to prevent accidental data loss)"
  echo "    To delete an AMI manually:"
  echo "      aws ec2 deregister-image --image-id ami-xxxxxxxxxxxxx"
fi

# 4) Lister les key pairs Ansible
echo ""
echo "[4/4] Checking for Ansible key pairs..."
KEY_NAMES=$(aws ec2 describe-key-pairs \
  --filters "Name=key-name,Values=ansible-ch2" \
  --query 'KeyPairs[*].KeyName' \
  --output text 2>/dev/null || true)

if [ -z "$KEY_NAMES" ]; then
  echo "    No Ansible key pairs found"
else
  echo "    Found key pairs: ${KEY_NAMES}"
  for KEY_NAME in $KEY_NAMES; do
    echo "    Deleting key pair ${KEY_NAME}..."
    aws ec2 delete-key-pair --key-name "${KEY_NAME}"
  done
  echo "    ✅ Key pairs deleted"
  
  # Supprimer le fichier .key local s'il existe
  if [ -f "../../ansible/ansible-ch2.key" ]; then
    rm -f "../../ansible/ansible-ch2.key"
    echo "    ✅ Local key file removed"
  fi
fi

echo ""
echo "========================================="
echo "  Cleanup Complete"
echo "========================================="
echo ""
echo "Verification commands:"
echo "  aws ec2 describe-instances --filters \"Name=tag:Name,Values=${TAG_VALUE}*\""
echo "  aws ec2 describe-security-groups --filters \"Name=group-name,Values=${TAG_VALUE}*\""
echo "  aws ec2 describe-images --owners self --filters \"Name=name,Values=sample-app-packer-*\""
echo ""
