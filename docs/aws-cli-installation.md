# Installer AWS CLI v2 sur votre ordinateur

[Français](aws-cli-installation.md) | [English](en/aws-cli-installation.md)

[Accueil](../README.fr.md) · [Prérequis et configuration AWS](prerequisites.md) · [Déploiement](deployment-guide.md)

## À quoi sert AWS CLI dans ce lab ?

AWS CLI est l'outil qui permet d'exécuter les commandes `aws` depuis votre ordinateur : valider le template, créer une stack CloudFormation, retrouver les adresses EC2 et supprimer le lab. **Installez AWS CLI v2 sur le PC utilisé pour suivre le guide, avant toute commande AWS.** L'installation du logiciel ne crée aucune ressource AWS et ne connecte pas automatiquement votre compte.

Git Bash, PowerShell et Terminal sont des environnements de commande ; ils ne remplacent pas AWS CLI. Le parcours de déploiement de ce dépôt utilise Bash / Git Bash.

## 1. Windows — installateur officiel

1. Téléchargez l'[installateur AWS CLI v2 pour Windows 64 bits](https://awscli.amazonaws.com/AWSCLIV2.msi).
2. Ouvrez le fichier `.msi`, suivez l'assistant et autorisez l'installation administrateur si Windows le demande.
3. Fermez puis rouvrez PowerShell **et Git Bash** pour charger le nouveau `PATH`. Si vous utilisez le terminal de VS Code, redémarrez aussi VS Code.
4. Dans le nouveau terminal, vérifiez :

```powershell
aws --version
```

La sortie doit commencer par `aws-cli/2.` ; le numéro précis peut varier. Autre méthode, depuis **PowerShell** :

```powershell
msiexec.exe /i https://awscli.amazonaws.com/AWSCLIV2.msi
```

Cette commande ouvre l'assistant d'installation. Terminez-le avant de rouvrir votre terminal. Si vous ne disposez pas des droits administrateur, AWS propose aussi un [installateur pour l'utilisateur courant](https://awscli.amazonaws.com/AWSCLIV2-User.msi).

Le MSI s'installe depuis Windows ; n'exécutez pas les commandes Linux ci-dessous dans Git Bash. Une fois installé, le même programme `aws` est utilisable depuis PowerShell, l'invite de commandes et Git Bash si son dossier est dans leur `PATH`.

## 2. macOS — paquet officiel

Depuis Terminal, téléchargez le paquet et lancez l'installateur système :

```bash
curl -fL "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "AWSCLIV2.pkg"
sudo installer -pkg ./AWSCLIV2.pkg -target /
aws --version
```

Le mot de passe demandé par `sudo` est celui de votre compte macOS. La sortie de vérification doit commencer par `aws-cli/2.`. Vous pouvez également télécharger le [paquet PKG officiel](https://awscli.amazonaws.com/AWSCLIV2.pkg) dans le navigateur et l'ouvrir pour suivre l'assistant graphique. Consultez les exigences macOS actuelles dans la documentation AWS avant l'installation.

## 3. Linux — choisir l'architecture

Ces commandes concernent un Linux compatible avec l'installateur AWS et la bibliothèque glibc. Pour connaître l'architecture de votre ordinateur :

```bash
uname -m
```

| Résultat | Archive AWS à utiliser |
| --- | --- |
| `x86_64` | `awscli-exe-linux-x86_64.zip` |
| `aarch64` ou `arm64` | `awscli-exe-linux-aarch64.zip` |

Il faut disposer de `curl`, `unzip` et des droits `sudo` pour l'installation système. Exemple d'installation de ces outils sur Ubuntu/Debian :

```bash
sudo apt-get update
sudo apt-get install -y curl unzip
```

Téléchargez et installez ensuite **une seule** archive correspondant à votre architecture. Exécutez ces commandes dans un dossier temporaire ou de téléchargement, hors du dépôt Git.

Pour Linux x86_64 :

```bash
curl -fL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
aws --version
```

Pour Linux ARM64 :

```bash
curl -fL "https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
aws --version
```

AWS documente également la vérification de signature PGP des archives dans ses [instructions détaillées](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html). Si une vérification de signature échoue, n'installez pas le paquet.

## 4. Vérifier la version et le chemin

Dans le terminal que vous utiliserez pour le lab :

```bash
aws --version
```

Attendu : `aws-cli/2.` suivi de la version et d'informations sur le système. Pour retrouver l'exécutable :

| Terminal | Commande |
| --- | --- |
| PowerShell | `Get-Command aws` |
| Invite de commandes Windows | `where aws` |
| Bash / Git Bash / Terminal macOS | `command -v aws` |

| Problème | Action |
| --- | --- |
| `aws: command not found` ou commande non reconnue | Fermer et rouvrir le terminal ; redémarrer VS Code si nécessaire ; vérifier le `PATH` |
| AWS CLI fonctionne dans PowerShell mais pas Git Bash | Rouvrir Git Bash après l'installation et vérifier `command -v aws` |
| La sortie commence par `aws-cli/1.` | Une ancienne version est prioritaire ; identifier son chemin et suivre le guide officiel de migration vers v2 |
| Le programme d'installation détecte une installation existante | Suivre les instructions officielles de mise à jour correspondant à votre méthode d'installation |
| `Unable to locate credentials` | Le logiciel est installé, mais l'identité AWS reste à configurer |
| `ExpiredToken` | Renouveler la session temporaire ou SSO utilisée |

## 5. Configurer l'accès AWS avant le déploiement

Revenez aux [prérequis](prerequisites.md) pour configurer l'identité autorisée de votre compte : profil SSO ou méthode d'authentification adaptée à votre lab. Les identifiants AWS ne sont pas installés avec le logiciel. Le mot de passe de la console AWS n'est pas une Secret Access Key.

Le lab utilise la région **`us-east-2` (Ohio)** et le format **`json`**. Après la configuration de votre identité, vérifiez l'accès :

```bash
aws sts get-caller-identity
```

Cette commande doit afficher l'identité et le compte attendus. En cas d'erreur, résolvez l'authentification avant de lancer CloudFormation. Ne partagez et ne versionnez jamais vos clés d'accès ou fichiers d'identifiants.

## Sources officielles

- [Installation et mise à jour d'AWS CLI v2 — Windows, macOS et Linux](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
- [Configuration et authentification d'AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-quickstart.html)
- [Migration depuis AWS CLI v1](https://docs.aws.amazon.com/cli/latest/userguide/cliv2-migration.html)
