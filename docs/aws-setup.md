# TD2 - Infrastructure as Code Lab
## Configuration AWS et Authentification

Ce guide explique comment configurer l'authentification AWS pour exécuter les labs du TD2.

## Prérequis

- Un compte AWS (gratuit - Free Tier)
- Un utilisateur IAM avec les permissions appropriées
- AWS CLI installé

## Installation AWS CLI

### macOS
```bash
brew install awscli
```

### Vérification
```bash
aws --version
# Devrait afficher : aws-cli/2.x.x ...
```

## Configuration de l'Authentification

### Étape 1 : Créer une Access Key

1. **Connectez-vous à la Console AWS** en tant que votre utilisateur IAM (pas root)

2. **Allez dans IAM** → Users → Votre utilisateur

3. **Security credentials** → Access keys → **Create access key**

4. **Sélectionnez** "Command Line Interface (CLI)" comme use case

5. **Cochez** la case de confirmation et cliquez sur **Next**

6. **Note** : AWS vous affiche :
   - `Access Key ID` : AKIAXXXXXXXXXXXXXXXX
   - `Secret Access Key` : xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
   
   ⚠️ **IMPORTANT** : Sauvegardez immédiatement ces credentials dans un gestionnaire de mots de passe. Le Secret Access Key ne sera plus jamais affiché.

### Étape 2 : Configurer les Variables d'Environnement

#### Option 1 : Variables d'environnement (session temporaire)

```bash
export AWS_ACCESS_KEY_ID="AKIAXXXXXXXXXXXXXXXX"
export AWS_SECRET_ACCESS_KEY="xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
export AWS_DEFAULT_REGION="us-east-2"
```

> ⚠️ Ces variables sont valables uniquement dans la session shell actuelle.

#### Option 2 : AWS CLI Configure (permanent)

```bash
aws configure
```

Entrez :
- AWS Access Key ID : `AKIAXXXXXXXXXXXXXXXX`
- AWS Secret Access Key : `xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx`
- Default region : `us-east-2`
- Default output format : `json`

Cela crée les fichiers :
- `~/.aws/credentials`
- `~/.aws/config`

### Étape 3 : Vérifier la Configuration

```bash
# Vérifier l'identité actuelle
aws sts get-caller-identity

# Devrait afficher :
# {
#     "UserId": "AIDAXXXXXXXXXXXXXXXXX",
#     "Account": "123456789012",
#     "Arn": "arn:aws:iam::123456789012:user/ton-user"
# }
```

```bash
# Lister les régions disponibles
aws ec2 describe-regions --output table
```

## Régions AWS

Pour ce TD, on utilise **us-east-2** (Ohio) :
- Free tier friendly
- Proche de l'Europe (latence acceptable)
- Compatible avec tous les exemples du lab

## Sécurité

### ✅ Bonnes Pratiques

1. **Ne jamais utiliser le compte root** pour les opérations quotidiennes
2. **Créer un utilisateur IAM** avec les permissions nécessaires uniquement
3. **Stocker les credentials de manière sécurisée** (gestionnaire de mots de passe)
4. **Utiliser MFA** (Multi-Factor Authentication) sur votre compte AWS
5. **Configurer des alertes de facturation** pour éviter les surprises

### ⚠️ Permissions Requises

Pour ce TD, l'utilisateur IAM doit avoir :
- `AdministratorAccess` (politique managée AWS)

Ou les permissions spécifiques :
- `ec2:*` (EC2 full access)
- `iam:PassRole`, `iam:CreateRole` (pour Packer/Ansible)
- Accès au Systems Manager (SSM) pour résoudre les AMI IDs

### Configuration des Alertes de Facturation

1. **Billing Console** → Billing Preferences
2. Cochez **Receive Free Tier Usage Alerts**
3. Cochez **Receive Billing Alerts**
4. Entrez votre email
5. Configurez des alarmes CloudWatch pour les budgets

Exemple d'alerte : notification si le coût mensuel dépasse 5$.

## Cleanup des Ressources

⚠️ **CRITIQUE** : Toujours nettoyer les ressources AWS après les tests !

```bash
# Lister toutes les instances en cours
aws ec2 describe-instances \
  --filters "Name=instance-state-name,Values=running" \
  --query 'Reservations[*].Instances[*].[InstanceId,Tags[?Key==`Name`].Value|[0]]' \
  --output table

# Terminer une instance
aws ec2 terminate-instances --instance-ids i-xxxxxxxxxxxxx

# Lister les security groups non-default
aws ec2 describe-security-groups \
  --filters "Name=group-name,Values=sample-app*" \
  --query 'SecurityGroups[*].[GroupId,GroupName]' \
  --output table

# Supprimer un security group
aws ec2 delete-security-group --group-id sg-xxxxxxxxxxxxx
```

## Dépannage

### Erreur "Unable to locate credentials"

```bash
# Vérifier que les credentials sont bien définis
env | grep AWS

# Ou vérifier le fichier de config
cat ~/.aws/credentials
```

### Erreur "Access Denied"

- Vérifiez que votre utilisateur IAM a les bonnes permissions
- Vérifiez la région (doit être us-east-2)
- Assurez-vous que les credentials sont bien ceux de l'utilisateur IAM

### Erreur "InvalidAMIID.NotFound"

L'AMI ID est spécifique à une région. Utilisez SSM pour obtenir l'AMI à jour :

```bash
aws ssm get-parameters \
  --names /aws/service/ami-amazon-linux-latest/al2023-ami-kernel-6.1-x86_64 \
  --query 'Parameters[0].Value' \
  --output text
```

## Ressources Utiles

- [AWS CLI Documentation](https://docs.aws.amazon.com/cli/)
- [AWS Free Tier](https://aws.amazon.com/free/)
- [IAM Best Practices](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)
- [EC2 Pricing](https://aws.amazon.com/ec2/pricing/)
