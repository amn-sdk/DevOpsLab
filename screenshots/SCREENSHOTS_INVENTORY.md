# Screenshots Reçus pour le Rapport TD2

## ✅ Screenshots Déjà Collectés

### 1. EC2 Instance Details
**Fichier**: `aws-ec2-instance-details.png`  
**Contenu**: 
- Instance ID: i-01c061cb3e6d2d139
- IP Publique: 3.21.168.251
- Type: t3.micro
- État: En cours d'exécution

![EC2 Instance Details](file:///Users/aminesaddik/Documents/ESIEE/E4/DevOps/td2/screenshots/aws-ec2-instance-details.png)

### 2. Security Group Inbound Rules
**Fichier**: `aws-security-group-rules.png`  
**Contenu**:
- Security Group: sg-01d7dd198b51a0d48 (sample-app-tofu)
- Règle entrante: Port 8080, TCP, 0.0.0.0/0

![Security Group Rules](file:///Users/aminesaddik/Documents/ESIEE/E4/DevOps/td2/screenshots/aws-security-group-rules.png)

### 3. Application Hello World
**Fichier**: `browser-hello-world.png`  
**Contenu**:
- URL: http://3.21.168.251:8080
- Réponse: "Hello, World!"

![Browser Hello World](file:///Users/aminesaddik/Documents/ESIEE/E4/DevOps/td2/screenshots/browser-hello-world.png)

---

## 📋 Screenshots Manquants (À Capturer)

### 4. AMI Packer - Liste
**Besoin**: Vue de la liste des AMIs dans AWS Console
**Contenu attendu**: ami-09a734dddd73e45a3 avec nom "sample-app-packer-..."

### 5. AMI Packer - Détails
**Besoin**: Détails de l'AMI
**Contenu attendu**: Description "Amazon Linux 2023 AMI with a Node.js sample app"

### 6. EC2 Instances - Vue Liste (Optionnel)
**Besoin**: Vue d'ensemble de toutes les instances
**Contenu attendu**: Liste montrant instance avec tag "sample-app-tofu"

---

## 🎯 Statut Global

**Screenshots Collectés**: 3/6 (50%)  
**Suffisant pour rapport minimum**: ✅ OUI  
**Recommandé pour rapport complet**: Ajouter AMI screenshots

---

## 📍 Où Trouver les Screenshots Manquants

### AMI List & Details
**URL**: https://us-east-2.console.aws.amazon.com/ec2/home?region=us-east-2#Images:visibility=owned-by-me

**Actions**:
1. Ouvrir cette URL (connecté à AWS)
2. Chercher AMI: `ami-09a734dddd73e45a3`
3. Screenshot 1: Vue liste
4. Cliquer sur l'AMI
5. Screenshot 2: Onglet "Details" avec description

### EC2 Instances List (Optionnel)
**URL**: https://us-east-2.console.aws.amazon.com/ec2/home?region=us-east-2#Instances:

**Actions**:
1. Ouvrir cette URL
2. Screenshot: Vue d'ensemble des instances en cours

---

## 💾 Tous les Fichiers

Disponibles dans: `/Users/aminesaddik/Documents/ESIEE/E4/DevOps/td2/screenshots/`

1. ✅ `aws-ec2-instance-details.png`
2. ✅ `aws-security-group-rules.png`
3. ✅ `browser-hello-world.png`
4. ⏳ `aws-ami-list.png` (à capturer)
5. ⏳ `aws-ami-details.png` (à capturer)
6. ⏳ `aws-ec2-instances-list.png` (optionnel)

---

## ✅ Conclusion

**Les 3 screenshots actuels SUFFISENT pour démontrer** :
- ✅ Déploiement EC2 réussi
- ✅ Configuration security group fonctionnelle
- ✅ Application accessible et fonctionnelle

**Pour un rapport COMPLET**, ajouter :
- 📸 AMI Packer (2 screenshots)
- 📸 Vue liste instances (1 screenshot optionnel)

**Je vais maintenant tenter de capturer les AMI screenshots automatiquement via le browser.**
