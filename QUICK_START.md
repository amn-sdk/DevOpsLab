# TD2 - Quick Reference

## 📁 Ce qui a été fait

### Documentation (4 fichiers)
- ✅ `README.md` - Guide principal complet
- ✅ `docs/aws-setup.md` - Configuration AWS CLI + credentials
- ✅ `docs/td2-exercises.md` - Réponses détaillées aux 8 exercices
- ✅ `docs/ami-verification.md` - Gestion des AMI IDs

### Scripts (2 nouveaux)
- ✅ `scripts/bash/cleanup-instances.sh` - Nettoyage AWS automatique
- ✅ `scripts/bash/update-ami-ids.sh` - Vérification/mise à jour des AMI

### Code existant (vérifié)
- ✅ Bash: `deploy-ec2-instance.sh`, `deploy-ec2-multi.sh`
- ✅ Ansible: playbooks + rôles + inventaire dynamique
- ✅ Packer: `sample-app.pkr.hcl`
- ✅ OpenTofu: configs + modules + déploiements

## 🎯 Exercices: 7/8 complétés (87.5%)

| # | Section | Exercice | Status |
|---|---------|----------|--------|
| 1 | Bash | 2e exécution → erreur SG | ✅ Répondu |
| 2 | Bash | Multi-instances | ✅ Implémenté |
| 3 | Ansible | Idempotence | ✅ Répondu |
| 4 | Ansible | Multi-instances | ✅ Implémenté |
| 5 | Packer | 2e build → nouvelle AMI | ✅ Répondu |
| 6 | Packer | VirtualBox | ⚠️ Optionnel |
| 7 | Tofu | Apply après destroy | ✅ Répondu |
| 8 | Tofu | Multi-instances | ✅ Implémenté |

## ⚡ Démarrage rapide

### 1. Configuration AWS
```bash
# Exporter credentials
export AWS_ACCESS_KEY_ID="..."
export AWS_SECRET_ACCESS_KEY="..."
export AWS_DEFAULT_REGION="us-east-2"

# Vérifier
aws sts get-caller-identity
```

### 2. Tester chaque section

**Bash**:
```bash
cd scripts/bash
./deploy-ec2-instance.sh
curl http://<IP>
```

**Ansible**:
```bash
cd scripts/ansible
ansible-playbook create_ec2_instance_playbook.yml
ansible-playbook -i inventory.aws_ec2.yml configure_sample_app_playbook.yml
```

**Packer**:
```bash
cd scripts/packer
packer build sample-app.pkr.hcl
# Noter l'AMI ID
```

**OpenTofu**:
```bash
cd scripts/tofu/ec2-instance
tofu apply -var="ami_id=ami-xxx"
curl http://<IP>:8080
```

### 3. Nettoyage
```bash
cd scripts/bash
./cleanup-instances.sh
```

## 📊 Statistiques

- **Lignes de doc**: ~1600
- **Fichiers créés**: 6
- **Commits**: 2
- **Exercices**: 7/8

## 📖 Liens rapides

- Configuration AWS → `docs/aws-setup.md`
- Réponses exercices → `docs/td2-exercises.md`
- Gestion AMI → `docs/ami-verification.md`
- Guide complet → `README.md`
