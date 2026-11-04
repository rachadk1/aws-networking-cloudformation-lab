# Sauvegarder et nettoyer

[Accueil](../README.md) · [Déploiement](deployment-guide.md)

Le template ne définit pas de politique de rétention de la base. Supprimer la stack termine les instances ; le volume racine standard du backend est normalement supprimé à la terminaison. **Sauvegarder les données utiles et contrôler la sauvegarde avant toute suppression.** Basculer `LaunchEc2Instances=false` supprime également les instances.

## 1. Export SQL facultatif — depuis votre ordinateur

Si la base contient des données à conserver, utiliser une destination **hors du dépôt**, par exemple :

```bash
umask 077
mkdir -p "$HOME/aws-lab-backups"
LAB_BACKUP="$HOME/aws-lab-backups/network_lab-$(date +%Y%m%d-%H%M%S).sql"
ssh aws-lab-backend 'sudo mariadb-dump --protocol=socket --single-transaction --databases network_lab' > "$LAB_BACKUP"
```

Vérifier le code de sortie avant de poursuivre, la présence des instructions SQL et les données attendues. Tester la restauration sur une base isolée si les données sont importantes. Ne pas considérer un fichier non vide comme une preuve suffisante. Pour garantir la cohérence avec d'éventuelles tables non transactionnelles, suspendre les écritures pendant l'export.

Ce dump exporte la base, pas le compte `network_app` ni son mot de passe. Le script permet de recréer l'utilisateur sur un nouveau serveur. Garder le dump privé ; le conserver peut exposer toutes les données qu'il contient.

## 2. Identifier précisément la stack à supprimer

Dans le terminal où les variables sont définies :

```bash
aws sts get-caller-identity
aws cloudformation describe-stacks \
  --stack-name "$LAB_STACK" --region "$AWS_REGION" \
  --query 'Stacks[0].[StackId,StackStatus]' --output table
```

Vérifier le compte, la région, le nom de stack et la sauvegarde avant la commande suivante.

## 3. Supprimer la stack

```bash
aws cloudformation delete-stack --stack-name "$LAB_STACK" --region "$AWS_REGION"
aws cloudformation wait stack-delete-complete --stack-name "$LAB_STACK" --region "$AWS_REGION"
```

La suppression peut prendre plusieurs minutes, en particulier si NAT était activé. En cas de `DELETE_FAILED`, lire les événements et résoudre la dépendance signalée ; ne pas supposer que les ressources restantes ont cessé d'être facturées.

```bash
aws cloudformation describe-stack-events \
  --stack-name "$LAB_STACK" --region "$AWS_REGION" \
  --query 'StackEvents[].[LogicalResourceId,ResourceStatus,ResourceStatusReason]' \
  --output table
```

## 4. Contrôler les ressources restantes

Dans la console AWS, vérifier les instances, volumes EBS, snapshots, NAT Gateways et Elastic IP de votre lab. Les ressources créées hors de CloudFormation — snapshots manuels, fichiers S3, clés EC2, sauvegardes — ne sont pas nécessairement supprimées avec la stack. Ne supprimer que celles identifiées comme appartenant à votre lab.

L'arrêt des EC2 réduit certains frais mais ne supprime ni les volumes EBS ni un NAT Gateway. Le frontend et le bastion peuvent changer d'IPv4 publique au redémarrage. Le suivi de facturation peut être différé : consulter Billing/Cost Explorer après le nettoyage.

Les sauvegardes locales et les entrées SSH peuvent être conservées ou retirées selon votre besoin. Ne pas supprimer une clé partagée avec un autre environnement.

Sources : [suppression d'une stack](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/cfn-console-delete-stack.html), [tarification VPC](https://aws.amazon.com/vpc/pricing/).
