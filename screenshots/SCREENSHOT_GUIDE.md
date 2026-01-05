# Guide de Capture de Screenshots pour Rapport TD2

## 📸 Screenshots à Prendre MAINTENANT

### ⏰ PENDANT LE DÉPLOIEMENT (URGENT - dans les 2 prochaines minutes)

#### 1. Console AWS - EC2 Instances
**URL** : https://us-east-2.console.aws.amazon.com/ec2/home?region=us-east-2#Instances:

**Quand** : MAINTENANT (pendant que l'instance se lance)

**Captures à prendre** :
- ✅ Vue de la liste des instances avec statut "pending" ou "initializing"
- ✅ Détails d'une instance (cliquer sur l'instance lancée)
- ✅ Tags de l'instance (onglet "Tags")
- ✅ Security groups associés (onglet "Security")

#### 2. Console AWS - Security Groups
**URL** : https://us-east-2.console.aws.amazon.com/ec2/home?region=us-east-2#SecurityGroups:

**Quand** : Après déploiement

**Captures à prendre** :
- ✅ Liste des security groups "sample-app-tofu"
- ✅ Détails du security group avec les règles inbound (port 8080)

#### 3. Console AWS - AMIs
**URL** : https://us-east-2.console.aws.amazon.com/ec2/home?region=us-east-2#Images:visibility=owned-by-me

**Quand** : N'importe quand

**Captures à prendre** :
- ✅ Liste de l'AMI Packer créée (ami-09a734dddd73e45a3)
- ✅ Détails de l'AMI avec description "Amazon Linux 2023 AMI with a Node.js sample app"

---

## 🌐 Screenshots à Prendre APRÈS DÉPLOIEMENT (dans ~2 minutes)

### 4. Navigateur - Test HTTP
**URL** : http://3.21.127.184:8080 (je te donnerai l'IP exacte)

**Quand** : Après que je te confirme que l'instance est "running"

**Captures à prendre** :
- ✅ Page web affichant "Hello, World!"
- ✅ URL visible dans la barre d'adresse
- ✅ Console développeur (F12) montrant status 200 OK (optionnel mais bien)

---

## 📋 Checklist de Captures

### AWS Console
- [ ] EC2 Instances - Vue liste (statut pending/running)
- [ ] EC2 Instance - Détails (onglet Details)
- [ ] EC2 Instance - Tags
- [ ] EC2 Instance - Security groups
- [ ] Security Groups - Liste
- [ ] Security Group - Règles inbound (port 8080)
- [ ] AMIs - Liste (AMI Packer)
- [ ] AMI - Détails

### Application
- [ ] Navigateur - Page "Hello, World!" avec URL visible
- [ ] (Optionnel) Console dev - Network tab avec 200 OK

### Logs Terminal (si besoin)
- [ ] Output de `tofu apply` (déjà dans les logs .log)
- [ ] Output de `packer build` (déjà dans section4-packer-build-retry.log)

---

## 💡 Conseils

1. **Fenêtre plein écran** pour captures AWS Console
2. **Zoom 100%** dans le navigateur
3. **Mode clair** (pas dark mode) pour meilleure lisibilité
4. **Nom de fichier descriptif** : 
   - `aws-ec2-instances-list.png`
   - `aws-security-group-rules.png`
   - `browser-hello-world.png`

---

## ⚡ Actions MAINTENANT

**ÉTAPE 1** : Ouvre https://us-east-2.console.aws.amazon.com/ec2/home?region=us-east-2#Instances: dans ton navigateur

**ÉTAPE 2** : Attends ma confirmation que l'instance est déployée

**ÉTAPE 3** : Je te donnerai l'URL HTTP pour tester

---

**Note** : Le déploiement prend ~30 secondes. Je te préviens dès que c'est prêt !
