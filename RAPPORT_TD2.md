# Rapport TD2 - Infrastructure as Code (IaC)

**Étudiant** : Amine SADDIK  
**Formation** : DevOps Data for SWE - ESIEE  
**Date** : Janvier 2026  
**Enseignant** : Badr TAJINI

---

## Introduction

Ce rapport présente le travail réalisé dans le cadre du TD2 sur l'Infrastructure as Code. L'objectif était de découvrir et utiliser différents outils permettant d'automatiser le déploiement et la gestion d'infrastructure cloud. J'ai travaillé avec quatre catégories d'outils : les scripts ad hoc (Bash), les outils de configuration (Ansible), les outils de templating (Packer), et les outils de provisioning (OpenTofu).

Toutes les manipulations ont été réalisées sur AWS dans la région us-east-2, en utilisant principalement des instances t3.micro éligibles au Free Tier pour minimiser les coûts.

---

## Section 1 : Authentification AWS

La première étape consistait à configurer l'accès à AWS via la ligne de commande. J'ai créé une access key depuis la console IAM et configuré les variables d'environnement nécessaires.

Voici les commandes utilisées pour l'authentification :

```bash
export AWS_ACCESS_KEY_ID="YOUR_ACCESS_KEY_ID"
export AWS_SECRET_ACCESS_KEY="YOUR_SECRET_ACCESS_KEY"
export AWS_DEFAULT_REGION="us-east-2"
```

La vérification de l'authentification s'est faite avec la commande `aws sts get-caller-identity` qui a confirmé l'accès au compte AWS 241474165125 avec l'utilisateur amn-sdk.

Cette configuration a été utilisée pour toutes les sections suivantes du lab.

---

## Section 2 : Déploiement avec un script Bash

### Principe et approche

Cette section m'a permis de créer un script Bash automatisant le déploiement d'une instance EC2. Le script gère la création du security group, le lancement de l'instance et l'affichage des informations importantes comme l'IP publique.

### Implémentation

J'ai créé deux scripts principaux :
- `deploy-ec2-instance.sh` pour déployer une seule instance
- `deploy-ec2-multi.sh` pour gérer plusieurs instances simultanément

Mon script utilise l'API AWS CLI pour :
1. Vérifier ou créer un security group nommé "sample-app"
2. Autoriser le trafic HTTP sur le port 80
3. Récupérer l'AMI Amazon Linux 2023 via SSM (pour avoir toujours la version à jour)
4. Lancer l'instance EC2 avec un script user-data pour installer Node.js
5. Attendre que l'instance soit en état "running"
6. Récupérer et afficher l'IP publique

Voici un extrait du script montrant la résolution dynamique de l'AMI :

```bash
AMI_ID=$(aws ssm get-parameters --names \
  /aws/service/ami-amazon-linux-latest/al2023-ami-kernel-6.1-x86_64 \
  --query 'Parameters[0].Value' --output text)
```

### Résultats

L'exécution du script a créé l'instance i-063a625c04bb24a89 avec l'IP publique 18.118.159.58. Après quelques minutes d'initialisation, l'application Node.js était accessible et affichait bien "Hello, World!" comme attendu.

![Détails de l'instance EC2](file:///Users/aminesaddik/Documents/ESIEE/E4/DevOps/td2/screenshots/aws-ec2-instance-details.png)

![Déploiement Bash - Étape 2.0](file:///Users/aminesaddik/Documents/ESIEE/E4/DevOps/td2/Etapes_2.0.png)

![Instance EC2 en cours d'exécution](file:///Users/aminesaddik/Documents/ESIEE/E4/DevOps/td2/instance3.png)

### Exercice 1 : Deuxième exécution

En exécutant le script une deuxième fois, le comportement dépend de l'implémentation. Dans le script de base du lab, AWS renvoie une erreur `InvalidGroup.Duplicate` car le security group existe déjà. J'ai amélioré mon script pour qu'il détecte d'abord si le security group existe avant de tenter de le créer. Ainsi, à la deuxième exécution, le script trouve le security group existant et le réutilise plutôt que de planter.

![Résultat première exécution Section 2](file:///Users/aminesaddik/Documents/ESIEE/E4/DevOps/td2/Etape2.0_image204.png)

### Exercice 2 : Multi-instances

Pour déployer plusieurs instances, j'ai créé le script `deploy-ec2-multi.sh` qui accepte un paramètre indiquant le nombre d'instances souhaitées. Le script utilise le flag `--count` de la commande `run-instances` qui permet de lancer plusieurs instances identiques en une seule requête API. Cette approche est plus efficace qu'une boucle car toutes les instances démarrent en parallèle.

![Exercice 2 - Configuration multi-instances](file:///Users/aminesaddik/Documents/ESIEE/E4/DevOps/td2/exercice2etape2.png)

![Exercice 2 - Test HTTP 200](file:///Users/aminesaddik/Documents/ESIEE/E4/DevOps/td2/exercice2http200.png)

---

## Section 3 : Déploiement avec Ansible

### Configuration initiale

Ansible m'a permis d'automatiser non seulement la création d'instances mais aussi leur configuration. J'ai créé plusieurs fichiers :
- Un playbook de création (`create_ec2_instance_playbook.yml`)
- Un fichier d'inventaire dynamique (`inventory.aws_ec2.yml`)
- Un playbook de configuration (`configure_sample_app_playbook.yml`)
- Un rôle Ansible (`roles/sample-app`) pour installer et démarrer l'application

### Déploiement de l'instance

Le premier playbook crée le security group et lance une instance EC2. J'ai configuré le playbook pour déployer une seule instance avec le tag `Ansible: ch2`. Au départ, j'avais essayé avec 3 instances mais j'ai rencontré une limite de vCPUs sur mon compte AWS (maximum 16 vCPUs). J'ai donc ajusté le paramètre `desired_count` à 1.

```yaml
- name: Launch EC2 instances
  amazon.aws.ec2_instance:
    region: "{{ aws_region }}"
    image_id: "{{ image_id }}"
    instance_type: "{{ instance_type }}"
    key_name: "{{ key_name }}"
    count: 1  # Ajusté de 3 à 1 à cause de la limite vCPU
    tags:
      Name: sample-app-ansible
      Ansible: ch2
```

### Configuration de l'application

Le deuxième playbook utilise l'inventaire dynamique pour détecter automatiquement les instances avec le tag `Ansible: ch2`. Le rôle `sample-app` installe Node.js 18, copie le fichier app.js sur l'instance et démarre l'application. J'ai utilisé un service systemd pour que l'application démarre automatiquement.

L'exécution du playbook de configuration a montré 6 changements appliqués (installation de Node.js, création du répertoire, copie du fichier, etc.).

![Section 3 - Configuration Ansible](file:///Users/aminesaddik/Documents/ESIEE/E4/DevOps/td2/etape3.png)

### Exercice 3 : Idempotence

L'idempotence est un concept clé d'Ansible. En exécutant le playbook de configuration une deuxième fois, aucun changement ne serait appliqué (changed=0) car Ansible détecte que l'état souhaité est déjà atteint. Par exemple, le module `yum` vérifie si Node.js est déjà installé avant de tenter l'installation. Le paramètre `creates` dans la tâche de démarrage de l'app empêche de relancer le processus s'il tourne déjà.

![Section 3 - Exercice 3 sur l'idempotence](file:///Users/aminesaddik/Documents/ESIEE/E4/DevOps/td2/stection3exercice3.png)

### Exercice 4 : Multi-instances

Pour déployer plusieurs instances avec Ansible, il suffit d'utiliser le paramètre `count` dans le module `ec2_instance`. L'inventaire dynamique récupère ensuite automatiquement toutes les instances ayant le même tag. Ansible peut alors configurer toutes les instances en parallèle, ce qui est beaucoup plus rapide qu'une approche séquentielle.

---

## Section 4 : Création d'AMI avec Packer

### Principe

Packer permet de créer des images de machines virtuelles (AMI pour AWS) préconfigurées. L'idée est de construire une AMI contenant déjà Node.js et l'application, ce qui accélère le démarrage des instances futures.

### Template Packer

J'ai créé le fichier `sample-app.pkr.hcl` avec la configuration suivante :
- Source AMI : Amazon Linux 2023 (AMI de base)
- Type d'instance pour le build : t3.micro
- Provisioners : copie du fichier app.js et installation de Node.js

Le nom de l'AMI utilise la fonction `uuidv4()` pour garantir l'unicité :

```hcl
ami_name = "sample-app-packer-${uuidv4()}"
```

### Build de l'AMI

Après avoir initialisé Packer avec `packer init`, j'ai lancé le build. Le processus a pris environ 4 minutes et 45 secondes. Packer a :
1. Créé une instance temporaire
2. Connecté via SSH
3. Copié le fichier app.js
4. Installé Node.js 21
5. Arrêté l'instance
6. Créé l'AMI à partir du disque
7. Nettoyé les ressources temporaires

L'AMI créée porte l'ID `ami-09a734dddd73e45a3` et le nom `sample-app-packer-be3743f5-9bd5-44a0-80e3-bcc5e7212b76`.

![Liste des AMIs](file:///Users/aminesaddik/Documents/ESIEE/E4/DevOps/td2/screenshots/aws-ami-list.png)

![Détails de l'AMI Packer](file:///Users/aminesaddik/Documents/ESIEE/E4/DevOps/td2/screenshots/aws-ami-details.png)

### Exercice 5 : Deuxième build

Si je lance `packer build` une deuxième fois, Packer créera une nouvelle AMI avec un nom différent grâce à la fonction `uuidv4()`. Chaque build génère un UUID unique, donc il n'y a jamais de conflit de nom. Cette approche suit le principe d'infrastructure immutable : au lieu de modifier une AMI existante, on en crée une nouvelle version. Cela permet de garder l'ancienne AMI pour un éventuel rollback.

---

## Section 5 : Déploiement avec OpenTofu

### Configuration

OpenTofu (fork open-source de Terraform) permet de gérer l'infrastructure de manière déclarative. J'ai créé plusieurs fichiers :
- `main.tf` : ressources principales (security group, instance)
- `variables.tf` : variable pour l'AMI ID
- `outputs.tf` : valeurs à afficher après déploiement
- `user-data.sh` : script de démarrage de l'application

Mon fichier main.tf définit trois ressources :
```hcl
resource "aws_security_group" "sample_app" {
  name        = "sample-app-tofu"
  description = "Allow HTTP traffic into the sample app"
}

resource "aws_security_group_rule" "allow_http_inbound" {
  type        = "ingress"
  protocol    = "tcp"
  from_port   = 8080
  to_port     = 8080
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = aws_security_group.sample_app.id
}

resource "aws_instance" "sample_app" {
  ami           = var.ami_id
  instance_type = "t3.micro"
  vpc_security_group_ids = [aws_security_group.sample_app.id]
  user_data     = file("${path.module}/user-data.sh")
  tags = {
    Name = "sample-app-tofu"
  }
}
```

### Déploiement

Après l'initialisation avec `tofu init`, j'ai déployé l'infrastructure avec `tofu apply` en passant l'AMI ID créée avec Packer. OpenTofu a affiché un plan détaillé montrant les 3 ressources à créer. Après confirmation, le déploiement s'est fait en environ 15 secondes.

L'instance créée (i-052575be8f034246c) est accessible sur l'IP 3.21.127.184. Le test HTTP confirme que l'application fonctionne correctement.

![Security Group avec règle port 8080](file:///Users/aminesaddik/Documents/ESIEE/E4/DevOps/td2/screenshots/aws-security-group-rules.png)

![Application Hello World](file:///Users/aminesaddik/Documents/ESIEE/E4/DevOps/td2/screenshots/browser-hello-world.png)

### Mise à jour

J'ai testé la mise à jour en ajoutant un nouveau tag dans main.tf :

```hcl
tags = {
  Name = "sample-app-tofu"
  Test = "update"
}
```

En relançant `tofu apply`, OpenTofu a détecté le changement et proposé une mise à jour "in-place" plutôt qu'un remplacement complet de l'instance. Cette capacité de gestion incrémentale est un avantage majeur par rapport aux scripts Bash.

### Destruction

La commande `tofu destroy` a supprimé toutes les ressources gérées (instance, security group, règle). Le fichier de state maintenu par OpenTofu permet de tracker précisément quelles ressources doivent être détruites.

### Exercice 7 : Apply après destroy

Après avoir détruit les ressources, si j'exécute à nouveau `tofu apply`, OpenTofu recrée exactement la même infrastructure. Le state file étant vide après le destroy, OpenTofu compare la configuration souhaitée (dans main.tf) avec l'état réel (rien) et planifie la création de toutes les ressources. C'est un comportement totalement prévisible et reproductible.

### Exercice 8 : Multi-instances

Pour déployer plusieurs instances avec OpenTofu, il existe plusieurs approches. La plus simple est d'utiliser le paramètre `count` :

```hcl
resource "aws_instance" "sample_app" {
  count         = 3
  ami           = var.ami_id
  instance_type = "t3.micro"
  # ...
  tags = {
    Name = "sample-app-tofu-${count.index + 1}"
  }
}
```

Une autre approche, plus flexible, utilise `for_each` avec une map pour configurer chaque instance différemment. J'ai implémenté cette fonctionnalité dans la section suivante avec les modules.

---

## Section 6 : Modules OpenTofu

### Principe des modules

Les modules OpenTofu permettent de réutiliser du code. Au lieu de dupliquer la configuration pour chaque instance, on crée un module générique et on l'appelle plusieurs fois avec des paramètres différents.

### Structure du module

J'ai créé un module dans `modules/ec2-instance/` avec :
- `main.tf` : définition des ressources
- `variables.tf` : paramètres configurables (name, ami_id, instance_type, http_port)
- `outputs.tf` : valeurs retournées par le module

Le module accepte plusieurs paramètres, ce qui le rend flexible :

```hcl
variable "name" {
  description = "The base name for the instance and all other resources"
  type        = string
}

variable "ami_id" {
  description = "The ID of the AMI to run"
  type        = string
}

variable "instance_type" {
  description = "The type of EC2 instance"
  type        = string
  default     = "t3.micro"
}

variable "http_port" {
  description = "The port for HTTP traffic"
  type        = number
  default     = 8080
}
```

### Utilisation du module

Dans `live/sample-app/main.tf`, j'ai appelé le module deux fois pour créer deux instances différentes :

```hcl
module "sample_app_1" {
  source = "../../modules/ec2-instance"
  ami_id = "ami-09a734dddd73e45a3"
  name   = "sample-app-tofu-1"
}

module "sample_app_2" {
  source = "../../modules/ec2-instance"
  ami_id = "ami-09a734dddd73e45a3"
  name   = "sample-app-tofu-2"
}
```

Cette approche évite la duplication de code et rend la configuration plus maintenable. Si je dois changer quelque chose dans la définition des ressources, je le fais une seule fois dans le module.

### Exercice 9 : Paramètres additionnels

Mon module accepte déjà des paramètres comme `instance_type` et `http_port`, donc cet exercice est résolu. Par exemple, je peux facilement créer une instance avec un type différent :

```hcl
module "sample_app_large" {
  source        = "../../modules/ec2-instance"
  ami_id        = "ami-09a734dddd73e45a3"
  name          = "sample-app-large"
  instance_type = "t3.small"
  http_port     = 3000
}
```

### Exercice 10 : Count et for_each

Au lieu de définir manuellement plusieurs modules, on peut utiliser `count` ou `for_each` sur le module lui-même. Voici un exemple avec `count` :

```hcl
module "sample_app" {
  count  = 3
  source = "../../modules/ec2-instance"
  ami_id = "ami-09a734dddd73e45a3"
  name   = "sample-app-tofu-${count.index + 1}"
}
```

L'approche `for_each` est encore plus puissante car elle permet de passer des configurations différentes pour chaque instance via une map.

---

## Comparaison des outils

Après avoir utilisé ces quatre outils, voici mes observations :

### Bash
**Avantages** :
- Simplicité et rapidité pour des scripts ponctuels
- Pas de dépendance externe à installer
- Contrôle total sur l'exécution

**Inconvénients** :
- Pas d'idempotence par défaut
- Gestion d'état manuelle
- Code rapidement complexe pour des infrastructures importantes
- Difficile à tester

### Ansible
**Avantages** :
- Idempotence native
- Syntaxe déclarative (YAML) facile à lire
- Excellent pour la configuration de serveurs
- Inventaire dynamique très pratique

**Inconvénients** :
- Nécessite un accès SSH aux machines
- Moins adapté au provisioning pur qu'à la configuration
- Gestion d'état limitée (vérifie à chaque exécution)

### Packer
**Avantages** :
- Images immutables et versionnées
- Build reproductible
- Accélère le déploiement des instances

**Inconvénients** :
- Temps de build significatif
- Nécessite de rebuilder pour chaque changement
- Gestion du cycle de vie des AMIs à prévoir

### OpenTofu
**Avantages** :
- Gestion d'état complète
- Idempotence et détection automatique des changements
- Modules réutilisables
- Plan avant exécution (visibilité)
- Destruction propre de l'infrastructure

**Inconvénients** :
- Courbe d'apprentissage plus raide
- State file à gérer (risque de désynchronisation)
- Syntaxe HCL parfois verbeuse

### Recommandation

Pour un projet réel, la meilleure approche serait de combiner ces outils :
1. Packer pour créer des AMIs avec l'OS et les dépendances de base
2. OpenTofu pour provisionner l'infrastructure (instances, réseaux, etc.)
3. Ansible pour la configuration applicative finale et les déploiements

Cette combinaison exploite les forces de chaque outil.

---

## Difficultés rencontrées

### Limite de vCPUs
Lors du déploiement multi-instances avec Ansible, j'ai atteint la limite de 16 vCPUs de mon compte AWS. J'ai dû réduire le nombre d'instances déployées simultanément.

### AMI IDs obsolètes
Les AMI IDs fournis dans le lab initial (`ami-0900fe555666598a2`) étaient obsolètes. J'ai résolu ce problème en :
- Utilisant SSM Parameter Store dans les scripts Bash pour obtenir l'AMI à jour dynamiquement
- Mettant à jour manuellement les AMI IDs dans Packer et Ansible

### Instances t2.micro non éligibles
Dans certaines régions et configurations, AWS considère que les instances t2.micro ne sont pas éligibles au Free Tier. J'ai systématiquement utilisé t3.micro qui fonctionne partout.

### Lock file OpenTofu
Lors de la première initialisation d'OpenTofu, j'ai eu un problème de checksums dans le lock file. J'ai dû nettoyer le répertoire `.terraform` et relancer `tofu init -upgrade` pour résoudre le problème.

---

## Nettoyage des ressources

Pour éviter des frais inattendus, j'ai systématiquement nettoyé les ressources après chaque section. J'ai créé un script `cleanup-instances.sh` qui :
- Termine toutes les instances avec le tag "sample-app"
- Attend que les instances soient complètement terminées
- Supprime les security groups associés
- Liste les AMIs Packer (sans les supprimer automatiquement)
- Supprime les key pairs Ansible

Au total, le script a nettoyé 8 instances, 3 security groups et 1 key pair. L'AMI Packer a été conservée pour référence mais peut être supprimée manuellement si nécessaire.

---

## Conclusion

Ce TD m'a permis de découvrir et comparer quatre approches différentes pour gérer l'infrastructure as code. Chaque outil a ses cas d'usage spécifiques et je comprends maintenant mieux quand utiliser l'un plutôt que l'autre.

L'automatisation via l'IaC apporte de nombreux avantages :
- Reproductibilité : le même code produit toujours la même infrastructure
- Versionnement : l'infrastructure évolue comme du code applicatif
- Documentation : le code décrit l'infrastructure de manière exhaustive
- Rapidité : déployer des environnements complets en quelques minutes

J'ai également appris l'importance de l'idempotence et de la gestion d'état. OpenTofu est particulièrement impressionnant de ce point de vue avec sa capacité à détecter précisément les changements nécessaires.

Pour des projets futurs, je privilégierais une approche hybride combinant Packer pour les images, OpenTofu pour le provisioning et Ansible pour la configuration applicative. Cette combinaison offre le meilleur équilibre entre contrôle, reproductibilité et facilité de maintenance.

---

## Annexes

### Fichiers créés

**Scripts Bash** :
- `scripts/bash/deploy-ec2-instance.sh` : déploiement simple
- `scripts/bash/deploy-ec2-multi.sh` : déploiement multi-instances
- `scripts/bash/cleanup-instances.sh` : nettoyage des ressources
- `scripts/bash/user-data.sh` : script d'initialisation

**Ansible** :
- `scripts/ansible/create_ec2_instance_playbook.yml` : création instances
- `scripts/ansible/configure_sample_app_playbook.yml` : configuration app
- `scripts/ansible/inventory.aws_ec2.yml` : inventaire dynamique
- `scripts/ansible/roles/sample-app/` : rôle de configuration

**Packer** :
- `scripts/packer/sample-app.pkr.hcl` : template AMI
- `scripts/packer/app.js` : application Node.js

**OpenTofu** :
- `scripts/tofu/ec2-instance/` : configuration de base
- `scripts/tofu/modules/ec2-instance/` : module réutilisable
- `scripts/tofu/live/sample-app/` : déploiement multi-instances

### Ressources créées et nettoyées

| Type | Quantité | Statut |
|------|----------|--------|
| Instances EC2 | 8 | Terminées |
| Security Groups | 3 | Supprimés |
| AMIs Packer | 1 | Conservée |
| Key Pairs | 1 | Supprimé |

### Commandes principales utilisées

```bash
# Authentification
aws sts get-caller-identity

# Bash
./deploy-ec2-instance.sh
./deploy-ec2-multi.sh 3

# Ansible
ansible-playbook create_ec2_instance_playbook.yml
ansible-playbook -i inventory.aws_ec2.yml configure_sample_app_playbook.yml

# Packer
packer init sample-app.pkr.hcl
packer build sample-app.pkr.hcl

# OpenTofu
tofu init
tofu apply -var="ami_id=ami-09a734dddd73e45a3"
tofu destroy

# Nettoyage
./cleanup-instances.sh
```
