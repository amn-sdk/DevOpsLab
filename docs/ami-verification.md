# Vérification et Mise à Jour des AMI IDs

Ce document explique comment vérifier et mettre à jour les AMI IDs dans les différents fichiers du projet.

## État Actuel des AMI IDs

### Scripts Bash ✅

Les scripts Bash utilisent **SSM Parameter Store** pour obtenir l'AMI Amazon Linux 2023 à jour dynamiquement :

```bash
# deploy-ec2-instance.sh (lignes 29-32)
AMI_ID=$(aws ssm get-parameters --names \
  /aws/service/ami-amazon-linux-latest/al2023-ami-kernel-6.1-x86_64 \
  --query 'Parameters[0].Value' --output text)
```

**Statut** : ✅ Pas de mise à jour nécessaire (résolution dynamique)

### Ansible

**Fichier** : `scripts/ansible/create_ec2_instance_playbook.yml`  
**AMI ID actuel** : `ami-0900fe555666598a2`  
**Ligne** : 7

**Statut** : ⚠️ Peut nécessiter une mise à jour

### Packer

**Fichier** : `scripts/packer/sample-app.pkr.hcl`  
**AMI ID actuel** : `ami-0900fe555666598a2` (source AMI)  
**Ligne** : 15

**Statut** : ⚠️ Peut nécessiter une mise à jour

### OpenTofu

**Fichiers** :
- `scripts/tofu/live/sample-app/main.tf` (lignes 9, 18)
- `scripts/tofu/live/sample-app-github/main.tf` (lignes 9, 18)

**AMI ID actuel** : `ami-09a9ad4735def0515`

**Statut** : 🟡 Provient d'un build Packer précédent (à mettre à jour après nouveau build Packer)

## Comment Vérifier les AMI IDs

### Option 1 : Via AWS CLI (Recommandé)

```bash
# Obtenir l'AMI Amazon Linux 2023 à jour
aws ssm get-parameters \
  --names /aws/service/ami-amazon-linux-latest/al2023-ami-kernel-6.1-x86_64 \
  --region us-east-2 \
  --query 'Parameters[0].Value' \
  --output text
```

### Option 2 : Vérifier Manuellement

```bash
# Vérifier si un AMI existe
aws ec2 describe-images \
  --image-ids ami-0900fe555666598a2 \
  --region us-east-2
  
# Si l'AMI n'existe pas, vous obtiendrez une erreur
```

### Option 3 : Script Automatique

Utilisez le script fourni :

```bash
cd scripts/bash
./update-ami-ids.sh
```

Ce script :
1. Récupère l'AMI Amazon Linux 2023 actuelle
2. Liste tous les AMI IDs hardcodés
3. Vérifie leur validité
4. Propose de les mettre à jour

## Processus de Mise à Jour

### 1. Mettre à Jour Ansible et Packer (Source AMI)

**Méthode Manuelle** :

1. Obtenir l'AMI actuelle :
   ```bash
   CURRENT_AMI=$(aws ssm get-parameters \
     --names /aws/service/ami-amazon-linux-latest/al2023-ami-kernel-6.1-x86_64 \
     --query 'Parameters[0].Value' --output text)
   echo $CURRENT_AMI
   ```

2. Mettre à jour `scripts/ansible/create_ec2_instance_playbook.yml` :
   ```yaml
   # Ligne 7
   image_id: ami-xxxxxxxxxxxxxxxxx  # Remplacer par $CURRENT_AMI
   ```

3. Mettre à jour `scripts/packer/sample-app.pkr.hcl` :
   ```hcl
   # Ligne 15
   source_ami = "ami-xxxxxxxxxxxxxxxxx"  # Remplacer par $CURRENT_AMI
   ```

4. Committer les changements :
   ```bash
   git add scripts/ansible/create_ec2_instance_playbook.yml scripts/packer/sample-app.pkr.hcl
   git commit -m "chore: update Ansible and Packer AMI IDs to latest AL2023"
   ```

**Méthode Automatique** :

```bash
# Le script propose la mise à jour interactive
./scripts/bash/update-ami-ids.sh
```

### 2. Construire une Nouvelle AMI avec Packer

Après avoir mis à jour le source AMI dans Packer :

```bash
cd scripts/packer

# Valider le template
packer validate sample-app.pkr.hcl

# Construire l'AMI
packer build sample-app.pkr.hcl

# Sauvegarder l'AMI ID affiché à la fin
# Exemple de sortie :
# ==> amazon-ebs.amazon_linux: Creating AMI: sample-app-packer-abc12345-...
# ...
# ==> Builds finished. The artifacts of successful builds are:
# --> amazon-ebs.amazon_linux: AMIs were created:
# us-east-2: ami-0a1b2c3d4e5f67890  # ← COPIER CET ID
```

### 3. Mettre à Jour OpenTofu avec le Nouvel AMI Packer

**Fichiers à modifier** :
- `scripts/tofu/live/sample-app/main.tf`
- `scripts/tofu/live/sample-app-github/main.tf`

**Exemple** (remplacer `ami-0a1b2c3d4e5f67890` par l'ID de votre build Packer) :

```hcl
# scripts/tofu/live/sample-app/main.tf

module "sample_app_1" {
  source = "../../modules/ec2-instance"
  
  # Mettre à jour avec l'AMI ID du build Packer
  ami_id = "ami-0a1b2c3d4e5f67890"  # ← Nouvelle valeur
  
  name = "sample-app-tofu-1"
}

module "sample_app_2" {
  source = "../../modules/ec2-instance"
  
  # Mettre à jour avec l'AMI ID du build Packer
  ami_id = "ami-0a1b2c3d4e5f67890"  # ← Nouvelle valeur
  
  name = "sample-app-tofu-2"
}
```

Committer :
```bash
git add scripts/tofu/live/
git commit -m "chore: update OpenTofu configs with new Packer AMI"
```

## Workflow Recommandé

```
1. Vérifier AMI Amazon Linux 2023 à jour
   ↓
2. Mettre à jour Ansible + Packer source AMI
   ↓
3. Builder nouvelle AMI avec Packer
   ↓
4. Mettre à jour OpenTofu avec AMI Packer
   ↓
5. Tester tous les déploiements
```

## Pourquoi Plusieurs AMI IDs ?

1. **Bash scripts** : Utilisent l'AMI Amazon Linux de base (SSM lookup)
2. **Ansible** : Utilise l'AMI Amazon Linux de base
3. **Packer source_ami** : AMI Amazon Linux de base (input)
4. **Packer output AMI** : AMI **personnalisée** avec Node.js pré-installé
5. **OpenTofu** : Utilise l'AMI Packer (avec Node.js) pour démarrage rapide

## Fréquence de Mise à Jour

- **AMI Amazon Linux** : AWS publie des mises à jour mensuelles (patches de sécurité)
- **AMI Packer** : Reconstruire après chaque mise à jour de l'AMI de base ou du code applicatif
- **Pour un lab/TP** : Pas critique tant que l'AMI existe et fonctionne

## Dépannage

### Erreur "InvalidAMIID.NotFound"

L'AMI n'existe pas ou n'est pas disponible dans votre région.

**Solution** :
```bash
# Vérifier la région actuelle
echo $AWS_DEFAULT_REGION

# S'assurer que vous utilisez us-east-2
export AWS_DEFAULT_REGION=us-east-2

# Obtenir l'AMI valide
aws ssm get-parameters \
  --names /aws/service/ami-amazon-linux-latest/al2023-ami-kernel-6.1-x86_64 \
  --query 'Parameters[0].Value' --output text
```

### Packer Build Échoue

Si le source AMI est invalide :

1. Mettre à jour `source_ami` dans `sample-app.pkr.hcl`
2. Relancer `packer build sample-app.pkr.hcl`

### OpenTofu Apply Échoue (AMI)

L'AMI Packer n'existe pas ou a été supprimée :

1. Rebuild avec Packer : `cd scripts/packer && packer build sample-app.pkr.hcl`
2. Mettre à jour l'AMI ID dans `live/*/main.tf`
3. Relancer `tofu apply`

## Commandes Utiles

```bash
# Lister toutes les AMIs que vous possédez
aws ec2 describe-images --owners self --region us-east-2

# Lister les AMIs Packer
aws ec2 describe-images --owners self \
  --filters "Name=name,Values=sample-app-packer-*" \
  --query 'Images[*].[ImageId,Name,CreationDate]' \
  --output table

# Supprimer une ancienne AMI
aws ec2 deregister-image --image-id ami-xxxxxxxxxxxxx
```

## Références

- [AWS SSM Parameter Store - Public Parameters](https://docs.aws.amazon.com/systems-manager/latest/userguide/parameter-store-public-parameters-ami.html)
- [Amazon Linux 2023 Release Notes](https://docs.aws.amazon.com/linux/al2023/release-notes/)
- [Packer AWS Builder](https://www.packer.io/plugins/builders/amazon/ebs)
