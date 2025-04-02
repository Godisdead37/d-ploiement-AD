# Script de Configuration d'un Serveur Windows Server 2022

## Description
Ce script PowerShell automatise la configuration d'un serveur Windows Server 2022. Il permet de :
- Vérifier les prérequis réseau.
- Renommer le serveur.
- Installer le rôle Active Directory Domain Services (ADDS).
- Configurer une adresse IP statique après l'installation d'ADDS.
- Promouvoir le serveur en tant que contrôleur de domaine.

## Prérequis
- Exécuter le script en mode administrateur.
- Assurez-vous que le serveur dispose d'une connexion réseau fonctionnelle.
- Le service DNS local doit être opérationnel.

## Fonctionnalités
1. **Vérification des prérequis** :
   - Teste la connectivité réseau et la disponibilité du service DNS local.

2. **Renommage du serveur** :
   - Permet de renommer le serveur avant de continuer la configuration.
   - **Important** : Après le redémarrage du serveur suite au renommage, vous devez relancer ce script pour continuer la configuration.

3. **Installation du rôle ADDS** :
   - Installe le rôle Active Directory Domain Services avec journalisation.

4. **Configuration IP statique** :
   - Configure une adresse IP statique après l'installation d'ADDS.
   - Définit le DNS sur la passerelle par défaut.

5. **Promotion en contrôleur de domaine** :
   - Promeut le serveur en tant que contrôleur de domaine avec gestion des blocages et journalisation.

## Instructions d'utilisation
1. Téléchargez le script et placez-le sur le serveur Windows Server 2022.
2. Ouvrez PowerShell en tant qu'administrateur.
3. Exécutez le script :
   ```powershell
   .\fast_ad.ps1
   ```
4. Suivez les instructions affichées à l'écran :
   - Renommez le serveur si nécessaire.
   - **Relancez le script après le redémarrage si vous avez renommé le serveur.**
   - Confirmez la configuration IP statique.
   - Entrez le nom de domaine et le mot de passe SafeMode pour la promotion en contrôleur de domaine.

## Journaux
- Les journaux d'installation et de promotion sont enregistrés dans :
  - `C:\Windows\Temp\ADDSInstall.log`
  - `C:\Windows\Temp\ADDSPromotion.log`

## Dépannage
- Si l'installation ou la promotion échoue, consultez les journaux pour plus de détails.
- Assurez-vous que le service DNS est correctement configuré et accessible.

## Avertissements
- Ce script redémarrera automatiquement le serveur après certaines étapes (renommage, promotion en contrôleur de domaine).
- Vérifiez que toutes les données importantes sont sauvegardées avant d'exécuter le script.

## Auteur
- Script développé par Louis.
