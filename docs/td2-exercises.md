# TD2 - Lab Exercises: Réponses et Explications

Ce document contient les réponses détaillées aux exercices du TD2 Infrastructure as Code.

---

## Section 2 : Bash Scripts

### Exercice 1 : Deuxième Exécution du Script

**Question** : Que se passe-t-il si vous exécutez le script une deuxième fois ?

**Réponse** :

Lors de la **deuxième exécution** de `deploy-ec2-instance.sh`, le script échoue avec une erreur :

```
An error occurred (InvalidGroup.Duplicate) when calling the CreateSecurityGroup operation:
The security group 'sample-app' already exists for VPC 'vpc-xxxxx'
```

**Explication** :

1. AWS Security Groups doivent avoir des **noms uniques** au sein d'un VPC
2. Le script crée un security group nommé `"sample-app"` lors de la première exécution
3. À la deuxième exécution, il tente de créer un SG avec le même nom → **conflit**
4. Le script n'est **pas idempotent** dans sa version de base

**Solutions possibles** :

1. **Vérifier l'existence avant création** (comme dans notre version améliorée) :
   ```bash
   SG_ID=$(aws ec2 describe-security-groups --filters "Name=group-name,Values=${NAME}" ...)
   if [ -z "${SG_ID}" ]; then
     # Créer seulement s'il n'existe pas
   fi
   ```

2. **Utiliser des noms uniques** avec timestamp/UUID :
   ```bash
   NAME="sample-app-$(date +%s)"
   ```

3. **Nettoyer les ressources** avant chaque exécution (non recommandé en prod)

**Ce qu'on apprend** :
- L'infrastructure n'est pas forcément idempotente par défaut
- Il faut gérer explicitement l'état existant
- Les outils IaC (Terraform/OpenTofu) gèrent cela automatiquement

---

### Exercice 2 : Déploiement Multi-Instances

**Question** : Comment modifier le script pour déployer plusieurs instances EC2 ?

**Réponse** :

✅ **Implémenté dans** `deploy-ec2-multi.sh`

**Modifications clés** :

1. **Paramètre COUNT** :
   ```bash
   COUNT="${1:-1}"  # 1 par défaut, ou valeur passée en $1
   ```

2. **Flag --count dans run-instances** :
   ```bash
   aws ec2 run-instances \
     --count "${COUNT}" \
     ...
   ```

3. **Gestion de plusieurs IDs** :
   ```bash
   INSTANCE_IDS=$(... --query 'Instances[].InstanceId' --output text)
   # Résultat : "i-xxx i-yyy i-zzz"
   
   aws ec2 wait instance-running --instance-ids ${INSTANCE_IDS}
   ```

4. **Affichage en tableau** :
   ```bash
   aws ec2 describe-instances --instance-ids "$@" \
     --query 'Reservations[].Instances[].[InstanceId,PublicIpAddress,...]' \
     --output table
   ```

**Usage** :
```bash
./deploy-ec2-multi.sh 3  # Déploie 3 instances
```

**Avantages vs boucle shell** :
- Une seule requête API (plus rapide)
- Toutes les instances lancées en parallèle
- Gestion atomique (soit tout réussit, soit tout échoue)

---

## Section 3 : Ansible

### Exercice 3 : Idempotence d'Ansible

**Question** : Que se passe-t-il si vous exécutez le playbook de configuration une deuxième fois ?

**Réponse** :

À la **deuxième exécution**, Ansible affiche :

```
TASK [sample-app : Install Node.js] ****************************
ok: [ec2-instance]

TASK [sample-app : Copy sample app] ****************************
ok: [ec2-instance]

TASK [sample-app : Start sample app] ***************************
ok: [ec2-instance]

PLAY RECAP ******************************************************
ec2-instance : ok=3    changed=0    unreachable=0    failed=0
```

**Points clés** :
- `changed=0` : **Aucun changement** n'a été appliqué
- `ok=3` : Les 3 tâches ont vérifié l'état et constaté qu'il est déjà conforme
- L'application continue de fonctionner normalement

**Explication de l'idempotence** :

1. **Install Node.js (yum module)** :
   - Ansible vérifie si le package est installé
   - Si déjà présent → `ok`, pas de réinstallation

2. **Copy sample app (copy module)** :
   - Ansible compare le checksum du fichier source et destination
   - Si identiques → `ok`, pas de copie

3. **Start sample app (shell avec creates)** :
   - Le paramètre `creates: /tmp/node-app.pid` fait qu'Ansible saute l'exécution si le fichier existe
   - Si le fichier existe → `ok`, pas de relance

**Ce qu'on apprend** :
- Ansible est **déclaratif** : vous décrivez l'état désiré
- Le moteur Ansible **converge vers cet état** sans actions inutiles
- C'est **safe** d'exécuter plusieurs fois le même playbook
- En production, on peut automatiser les déploiements sans risque de corruption

**Différence avec Bash** :
Un script Bash s'exécuterait "bêtement" à chaque fois :
- Réinstaller Node.js (même déjà présent)
- Re-copier le fichier
- Relancer l'app (créant potentiellement plusieurs processus)

---

### Exercice 4 : Multi-Instances avec Ansible

**Question** : Comment déployer et configurer plusieurs instances ?

**Réponse** :

✅ **Implémenté dans** `create_ec2_instance_playbook.yml`

**Approche** :

1. **Utiliser le paramètre `count`** dans `ec2_instance` :
   ```yaml
   - name: Launch EC2 instances
     amazon.aws.ec2_instance:
       count: 3  # ou {{ desired_count }}
       ...
   ```

2. **Inventaire dynamique** (`inventory.aws_ec2.yml`) :
   ```yaml
   plugin: amazon.aws.aws_ec2
   keyed_groups:
     - key: tags.Ansible
       leading_separator: ''
   ```
   
   Cela regroupe automatiquement toutes les instances avec le tag `Ansible=ch2` dans le groupe `ch2_instances`.

3. **Exécuter le playbook de configuration** :
   ```bash
   ansible-playbook -i inventory.aws_ec2.yml configure_sample_app_playbook.yml
   ```
   
   Ansible détecte dynamiquement toutes les instances du groupe et applique la config en parallèle.

**Avantages** :
- **Scalabilité** : facile de passer de 1 à 10+ instances
- **Automatisation** : pas besoin de lister manuellement les IPs
- **Parallélisation** : Ansible configure toutes les instances simultanément
- **Consistance** : la configuration est strictement identique partout

---

## Section 4 : Packer

### Exercice 5 : Deuxième Build avec Packer

**Question** : Que se passe-t-il si vous exécutez `packer build` une deuxième fois ?

**Réponse** :

À la **deuxième exécution**, Packer **crée une nouvelle AMI** avec un nom différent.

**Exemple** :
- 1er build : `sample-app-packer-a1b2c3d4-e5f6-7890-1234-567890abcdef`
- 2ème build : `sample-app-packer-f9e8d7c6-b5a4-3210-9876-543210fedcba`

**Explication** :

Le template utilise **`uuidv4()`** dans le nom de l'AMI :
```hcl
ami_name = "sample-app-packer-${uuidv4()}"
```

- `uuidv4()` génère un **UUID aléatoire unique** à chaque build
- Cela garantit qu'il n'y a **jamais de conflit** de nom
- Chaque build crée un nouvel artefact indépendant

**Implications** :

✅ **Avantages** :
- **Immutable infrastructure** : chaque version est un snapshot distinct
- **Rollback facile** : on peut revenir à une ancienne AMI
- **Testing** : plusieurs versions peuvent coexister

⚠️ **Inconvénients** :
- **Prolifération d'AMIs** : il faut nettoyer régulièrement les anciennes
- **Coût** : chaque AMI compte comme du stockage EBS (snapshot)
- **Difficulté à retrouver** : il faut tagguer ou nommer intelligemment

**Alternatives** :

1. **Nom fixe avec écrasement** (non recommandé) :
   ```hcl
   ami_name = "sample-app-packer-latest"
   force_deregister = true
   force_delete_snapshot = true
   ```

2. **Nom avec timestamp** :
   ```hcl
   ami_name = "sample-app-packer-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"
   ```

3. **Nom avec version Git** :
   ```hcl
   ami_name = "sample-app-packer-${env("GIT_COMMIT")}"
   ```

**Ce qu'on apprend** :
- Packer encourage l'**immutabilité**
- L'infrastructure est versionnée comme du code
- On ne modifie jamais une AMI existante, on en crée une nouvelle

---

## Section 5 : OpenTofu (Terraform)

### Exercice 7 : Apply après Destroy

**Question** : Que se passe-t-il si vous exécutez `tofu apply` après avoir détruit les ressources ?

**Réponse** :

Après `tofu destroy`, si on exécute `tofu apply`, **OpenTofu recrée toutes les ressources**.

**Exemple de sortie** :

```
$ tofu destroy
...
Destroy complete! Resources: 3 destroyed.

$ tofu apply
...
Plan: 3 to add, 0 to change, 0 to destroy.
...
Apply complete! Resources: 3 added, 0 changed, 0 destroyed.
```

**Explication** :

1. **State file** (`terraform.tfstate`) :
   - Après `destroy`, le state est vide (`resources: []`)
   - OpenTofu "sait" qu'il n'y a plus rien

2. **Plan** :
   - OpenTofu compare le **state actuel** (vide) avec la **config déclarée** (main.tf)
   - Résultat : tout doit être créé (`+ create`)

3. **Apply** :
   - OpenTofu crée les ressources exactement comme au premier `apply`
   - Comportement **totalement prévisible** et **idempotent**

**Différence avec Bash** :

Un script Bash ne "sait" pas ce qui existe :
- Il essaierait de créer → échouerait si déjà existant
- Ou créerait un doublon si les noms sont dynamiques

Avec OpenTofu :
- Le **state** est la source de vérité
- On peut `apply` autant de fois qu'on veut
- Le résultat est **toujours convergent**

**Ce qu'on apprend** :
- OpenTofu gère un **cycle de vie complet** : create → update → destroy
- Le state tracking permet l'**idempotence** totale
- On peut recréer l'infrastructure à l'identique à tout moment (disaster recovery)

---

### Exercice 8 : Déploiement Multi-Instances avec OpenTofu

**Question** : Comment déployer plusieurs instances avec OpenTofu ?

**Réponse** :

✅ **Implémenté dans** `live/sample-app/main.tf`

**Approche 1 : Modules multiples (fichier actuel)** :

```hcl
module "sample_app_1" {
  source = "../../modules/ec2-instance"
  ami_id = var.ami_id
  name   = "sample-app-tofu-1"
}

module "sample_app_2" {
  source = "../../modules/ec2-instance"
  ami_id = var.ami_id
  name   = "sample-app-tofu-2"
}
```

**Avantages** :
- Chaque instance peut avoir une config différente
- Flexibilité maximale

**Inconvénients** :
- Code répétitif si beaucoup d'instances
- Difficile de scaler dynamiquement

---

**Approche 2 : count (recommandée pour instances identiques)** :

```hcl
module "sample_app" {
  source = "../../modules/ec2-instance"
  
  count  = 3
  ami_id = var.ami_id
  name   = "sample-app-tofu-${count.index + 1}"
}
```

Résultat : 3 instances `sample-app-tofu-1`, `sample-app-tofu-2`, `sample-app-tofu-3`.

**Accès aux outputs** :
```hcl
output "all_public_ips" {
  value = module.sample_app[*].public_ip
}
```

---

**Approche 3 : for_each (plus flexible)** :

```hcl
variable "instances" {
  type = map(object({
    instance_type = string
    http_port     = number
  }))
  default = {
    "web" = {
      instance_type = "t2.micro"
      http_port     = 8080
    }
    "api" = {
      instance_type = "t3.small"
      http_port     = 3000
    }
  }
}

module "sample_app" {
  source = "../../modules/ec2-instance"
  
  for_each      = var.instances
  ami_id        = var.ami_id
  name          = "sample-app-${each.key}"
  instance_type = each.value.instance_type
  http_port     = each.value.http_port
}
```

**Avantages** :
- Chaque instance peut avoir une config unique
- Ajout/suppression sans réindexation
- Accès par clé : `module.sample_app["web"].public_ip`

---

**Ce qu'on apprend** :
- OpenTofu/Terraform offre plusieurs patterns pour gérer la scalabilité
- `count` = bon pour N instances identiques
- `for_each` = meilleur pour instances avec configs variées
- Les modules rendent le code DRY (Don't Repeat Yourself)

---

## Comparaison des Outils IaC

| Critère | Bash | Ansible | Packer | OpenTofu |
|---------|------|---------|--------|----------|
| **Idempotence** | ⚠️ Manuelle | ✅ Native | ✅ Build immutable | ✅ State tracking |
| **Déclaratif** | ❌ Procédural | ✅ Oui | ✅ Oui | ✅ Oui |
| **State** | ❌ Aucun | ⚠️ Check runtime | 🟢 AMI = artefact | ✅ tfstate |
| **Rollback** | ❌ | ⚠️ Playbook inverse | ✅ AMI précédente | ✅ `destroy` |
| **Courbe d'apprentissage** | ✅ Simple | 🟡 Moyenne | 🟡 Moyenne | 🟠 Plus raide |
| **Use case** | Scripts rapides | Config management | VM images | Provisioning infra |

**Recommandation** :
- **Bash** : Prototypage, scripts one-shot
- **Ansible** : Configuration de serveurs existants, orchestration applicative
- **Packer** : Création d'images immuables (AMIs, Docker, etc.)
- **OpenTofu/Terraform** : Provisioning complet de l'infrastructure cloud

**Meilleure pratique** : **Combiner les outils** !
1. **Packer** : Créer une AMI préconfigurée
2. **OpenTofu** : Provisionner l'infra (VPC, instances, load balancers...)
3. **Ansible** : Configuration applicative finale et déploiements

---

## Références

- [AWS CLI Documentation](https://docs.aws.amazon.com/cli/)
- [Ansible Best Practices](https://docs.ansible.com/ansible/latest/user_guide/playbooks_best_practices.html)
- [Packer Documentation](https://www.packer.io/docs)
- [OpenTofu Documentation](https://opentofu.org/docs/)
- [12 Factor App](https://12factor.net/)
