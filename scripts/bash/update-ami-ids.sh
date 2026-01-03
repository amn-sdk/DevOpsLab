#!/usr/bin/env bash
set -euo pipefail

# Script pour vérifier et mettre à jour les AMI IDs dans tous les fichiers
# Usage: ./update-ami-ids.sh

REGION="${AWS_DEFAULT_REGION:-us-east-2}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo "========================================="
echo "  AMI ID Verification and Update Script"
echo "========================================="
echo "Region: ${REGION}"
echo "Project root: ${PROJECT_ROOT}"
echo ""

# 1) Obtenir l'AMI Amazon Linux 2023 actuelle
echo "[1/3] Fetching current Amazon Linux 2023 AMI..."
CURRENT_AMI=$(aws ssm get-parameters \
  --names /aws/service/ami-amazon-linux-latest/al2023-ami-kernel-6.1-x86_64 \
  --query 'Parameters[0].Value' \
  --output text 2>/dev/null || echo "")

if [ -z "$CURRENT_AMI" ]; then
  echo "    ❌ Failed to fetch AMI from SSM"
  echo "    Check your AWS credentials and region"
  exit 1
fi

echo "    Current AL2023 AMI: ${CURRENT_AMI}"
echo ""

# 2) Lister tous les AMI IDs hardcodés dans le projet
echo "[2/3] Scanning project files for hardcoded AMI IDs..."
echo ""

echo "    Files with AMI IDs:"
grep -r "ami-[0-9a-f]\{17\}" "$PROJECT_ROOT/scripts" \
  --include="*.sh" --include="*.yml" --include="*.hcl" --include="*.tf" \
  | grep -v "ami-xxxxxxxxxxxxx" \
  | while IFS=: read -r file line; do
      ami_id=$(echo "$line" | grep -o "ami-[0-9a-f]\{17\}" | head -1)
      echo "      $file"
      echo "        Current: $ami_id"
      
      # Vérifier si l'AMI existe
      if aws ec2 describe-images --image-ids "$ami_id" --region "$REGION" &>/dev/null; then
        echo "        Status: ✅ Valid"
      else
        echo "        Status: ❌ Invalid/Not found"
      fi
    done

echo ""

# 3) Proposer la mise à jour
echo "[3/3] Update recommendations:"
echo ""
echo "    ✅ Bash scripts use SSM lookup (dynamic, always up-to-date)"
echo "    ⚠️  Ansible playbook: ami-0900fe555666598a2"
echo "    ⚠️  Packer template: ami-0900fe555666598a2 (source AMI)"
echo "    ⚠️  OpenTofu configs: ami-09a9ad4735def0515 (from Packer build)"
echo ""
echo "Recommendations:"
echo "  1. Ansible: Update to use SSM lookup or current AMI: ${CURRENT_AMI}"
echo "  2. Packer: Update source_ami to: ${CURRENT_AMI}"
echo "  3. OpenTofu: Use AMI ID from Packer build output"
echo ""

# Demander confirmation pour mettre à jour
read -p "Update Ansible and Packer AMI IDs to ${CURRENT_AMI}? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo "No changes made."
  exit 0
fi

# Mise à jour Ansible
echo ""
echo "Updating Ansible playbook..."
sed -i.bak "s/ami-[0-9a-f]\{17\}/${CURRENT_AMI}/g" \
  "$PROJECT_ROOT/scripts/ansible/create_ec2_instance_playbook.yml"
echo "  ✅ Updated: scripts/ansible/create_ec2_instance_playbook.yml"

# Mise à jour Packer
echo "Updating Packer template..."
sed -i.bak "s/source_ami[[:space:]]*=[[:space:]]*\"ami-[0-9a-f]\{17\}\"/source_ami      = \"${CURRENT_AMI}\"/g" \
  "$PROJECT_ROOT/scripts/packer/sample-app.pkr.hcl"
echo "  ✅ Updated: scripts/packer/sample-app.pkr.hcl"

# Nettoyer les backups
rm -f "$PROJECT_ROOT"/scripts/ansible/*.bak "$PROJECT_ROOT"/scripts/packer/*.bak

echo ""
echo "========================================="
echo "  Update Complete"
echo "========================================="
echo ""
echo "Next steps:"
echo "  1. Review changes: git diff"
echo "  2. Build new AMI with Packer: cd scripts/packer && packer build sample-app.pkr.hcl"
echo "  3. Update OpenTofu configs with new Packer AMI ID"
echo "  4. Commit: git add -A && git commit -m 'chore: update AMI IDs'"
echo ""
