# TD2 - Infrastructure as Code Lab

Lab complet d'Infrastructure as Code (IaC) couvrant 4 approches différentes : scripts ad hoc, configuration management, server templating, et provisioning tools.

## 📋 Vue d'Ensemble

Ce TD explore 4 catégories d'outils IaC :
1. **Scripts ad hoc** (Bash) - Automatisation basique
2. **Configuration management** (Ansible) - Gestion de configuration
3. **Server templating** (Packer) - Création d'images immutables  
4. **Provisioning tools** (OpenTofu) - Infrastructure déclarative

## 🎯 Objectifs

- Comprendre les avantages de l'Infrastructure as Code
- Déployer des instances EC2 de 4 manières différentes
- Comparer les approches procédurales vs déclaratives
- Maîtriser les concepts d'idempotence et d'immutabilité
- Gérer le cycle de vie complet de l'infrastructure

## 📁 Structure du Projet

```
td2/
├── docs/
│   ├── aws-setup.md           # Guide de configuration AWS
│   └── td2-exercises.md        # Réponses aux exercices
├── scripts/
│   ├── bash/
│   │   ├── deploy-ec2-instance.sh     # Déploiement simple
│   │   ├── deploy-ec2-multi.sh        # Multi-instances
│   │   ├── cleanup-instances.sh       # Nettoyage
│   │   └── user-data.sh                # Bootstrap Node.js
│   ├── ansible/
│   │   ├── create_ec2_instance_playbook.yml
│   │   ├── configure_sample_app_playbook.yml
│   │   ├── inventory.aws_ec2.yml
│   │   ├── group_vars/
│   │   └── roles/sample-app/
│   ├── packer/
│   │   ├── sample-app.pkr.hcl
│   │   └── app.js
│   └── tofu/
│       ├── ec2-instance/              # Config standalone
│       ├── modules/ec2-instance/      # Module réutilisable
│       └── live/
│           ├── sample-app/            # Déploiement multi-module
│           └── sample-app-github/     # Module externe
└── README.md
```

## 🚀 Démarrage Rapide

### Prérequis

1. **Compte AWS** avec utilisateur IAM (AdministratorAccess)
2. **AWS CLI** configuré
3. **Outils IaC** installés :
   ```bash
   # macOS
   brew install awscli ansible packer opentofu
   
   # Ansible AWS collection
   ansible-galaxy collection install amazon.aws
   ```

4. **Credentials AWS** :
   ```bash
   export AWS_ACCESS_KEY_ID="votre_access_key"
   export AWS_SECRET_ACCESS_KEY="votre_secret_key"
   export AWS_DEFAULT_REGION="us-east-2"
   ```

📖 **Guide détaillé** : [docs/aws-setup.md](docs/aws-setup.md)

### Vérification

```bash
# AWS CLI
aws sts get-caller-identity

# Ansible
ansible-galaxy collection list | grep amazon.aws

# Packer
packer version

# OpenTofu
tofu version
```

## 📚 Sections du Lab

### Section 1 : Authentification AWS

Configuration des credentials AWS et vérification de l'accès.

- 📄 Voir [docs/aws-setup.md](docs/aws-setup.md)

### Section 2 : Bash Scripts

Déploiement d'instances EC2 avec des scripts Bash.

```bash
cd scripts/bash

# Déployer une instance
./deploy-ec2-instance.sh

# Déployer 3 instances
./deploy-ec2-multi.sh 3

# Tester
curl http://<PUBLIC_IP>
```

**Exercices** :
- ✅ Exercice 1 : Que se passe-t-il à la 2e exécution ?
- ✅ Exercice 2 : Déployer plusieurs instances

### Section 3 : Ansible

Déploiement et configuration avec Ansible.

```bash
cd scripts/ansible

# Créer les instances EC2
ansible-playbook create_ec2_instance_playbook.yml

# Configurer l'application
ansible-playbook -i inventory.aws_ec2.yml configure_sample_app_playbook.yml

# Tester
curl http://<PUBLIC_DNS>:8080
```

**Exercices** :
- ✅ Exercice 3 : Comportement à la 2e exécution (idempotence)
- ✅ Exercice 4 : Déployer plusieurs instances

### Section 4 : Packer

Création d'AMIs préconfigurées.

```bash
cd scripts/packer

# Valider le template
packer validate sample-app.pkr.hcl

# Construire l'AMI
packer build sample-app.pkr.hcl

# Sauvegarder l'AMI ID affiché à la fin
# Exemple : ami-0a1b2c3d4e5f67890
```

**Exercices** :
- ✅ Exercice 5 : Que se passe-t-il au 2e build ?
- ⚠️ Exercice 6 : Template VirtualBox (optionnel)

### Section 5 : OpenTofu - Configuration de Base

Provisioning déclaratif avec OpenTofu.

```bash
cd scripts/tofu/ec2-instance

# Initialiser
tofu init

# Planifier (il vous demandera l'AMI ID de Packer)
tofu plan -var="ami_id=ami-xxx"

# Appliquer
tofu apply -var="ami_id=ami-xxx"

# Tester
curl http://<PUBLIC_IP>:8080

# Détruire
tofu destroy -var="ami_id=ami-xxx"
```

**Exercices** :
- ✅ Exercice 7 : `tofu apply` après `tofu destroy`
- ✅ Exercice 8 : Déployer plusieurs instances

### Section 6 : OpenTofu - Modules

Utilisation de modules pour réutilisabilité.

```bash
cd scripts/tofu/live/sample-app

# Mettre à jour l'AMI ID dans main.tf (ligne 9 et 18)

# Déployer 2 instances via modules
tofu init
tofu plan
tofu apply

# Outputs
tofu output
```

## 🧹 Nettoyage

⚠️ **CRITIQUE** : Toujours nettoyer les ressources AWS !

```bash
cd scripts/bash
./cleanup-instances.sh
```

Ou manuellement :
```bash
# Terminer les instances
aws ec2 terminate-instances --instance-ids i-xxx i-yyy

# Supprimer les security groups
aws ec2 delete-security-group --group-id sg-xxx

# Supprimer les key pairs
aws ec2 delete-key-pair --key-name ansible-ch2

# (Optionnel) Désenregistrer les AMIs Packer
aws ec2 deregister-image --image-id ami-xxx
```

## 📊 Exercices et Réponses

Toutes les réponses détaillées sont dans [docs/td2-exercises.md](docs/td2-exercises.md)

| Section | Exercice | Status |
|---------|----------|--------|
| 2 - Bash | Exercice 1 : 2e exécution | ✅ Répondu |
| 2 - Bash | Exercice 2 : Multi-instances | ✅ Implémenté |
| 3 - Ansible | Exercice 3 : Idempotence | ✅ Répondu |
| 3 - Ansible | Exercice 4 : Multi-instances | ✅ Implémenté |
| 4 - Packer | Exercice 5 : 2e build | ✅ Répondu |
| 4 - Packer | Exercice 6 : VirtualBox | ⚠️ Optionnel |
| 5 - OpenTofu | Exercice 7 : Apply after destroy | ✅ Répondu |
| 5 - OpenTofu | Exercice 8 : Multi-instances | ✅ Implémenté |

## 🔍 Comparaison des Outils

| Outil | Type | Idempotence | State | Use Case |
|-------|------|-------------|-------|----------|
| **Bash** | Procédural | ⚠️ Manuelle | ❌ | Scripts rapides, prototypage |
| **Ansible** | Déclaratif | ✅ Native | ⚠️ Runtime | Configuration, orchestration |
| **Packer** | Déclaratif | ✅ Build | 🟢 AMI | Images immutables |
| **OpenTofu** | Déclaratif | ✅ Native | ✅ tfstate | Provisioning infrastructure |

**Meilleure pratique** : Combiner les outils !
1. **Packer** → Créer des AMIs préconfigurées
2. **OpenTofu** → Provisionner l'infrastructure
3. **Ansible** → Configuration applicative finale

## 🛠 Dépannage

### Erreur "Unable to locate credentials"
```bash
# Vérifier les credentials
env | grep AWS
aws configure list
```

### Erreur "InvalidAMIID.NotFound"
```bash
# Obtenir l'AMI Amazon Linux 2023 à jour
aws ssm get-parameters \
  --names /aws/service/ami-amazon-linux-latest/al2023-ami-kernel-6.1-x86_64 \
  --query 'Parameters[0].Value' \
  --output text
```

### Instance inaccessible (HTTP timeout)
- Vérifier que le security group autorise le port (80 ou 8080)
- Vérifier que l'instance a une IP publique
- Attendre 1-2 minutes après le lancement (initialisation)

### Ansible "host key checking failed"
```bash
# Ajouter dans ansible.cfg
[defaults]
host_key_checking = False
```

## 📖 Ressources

- [AWS CLI Reference](https://docs.aws.amazon.com/cli/)
- [Ansible AWS Guide](https://docs.ansible.com/ansible/latest/collections/amazon/aws/)
- [Packer AWS Builder](https://www.packer.io/plugins/builders/amazon/ebs)
- [OpenTofu Documentation](https://opentofu.org/docs/)
- [Infrastructure as Code Principles](https://infrastructure-as-code.com/)

## 🎓 Points Clés Appris

1. **Idempotence** : Ansible et OpenTofu gèrent automatiquement l'état existant
2. **Déclaratif vs Procédural** : Décrire "ce qu'on veut" vs "comment le faire"
3. **Immutabilité** : Packer crée des artefacts versionnés (AMIs)
4. **State Tracking** : OpenTofu maintient un state file pour la cohérence
5. **Infrastructure as Code** : L'infra est versionnée, testable, reproductible

---

**Auteur** : Badr TAJINI - DevOps Data for SWE - ESIEE - 2025  
**Lab** : TD2 - Infrastructure as Code
