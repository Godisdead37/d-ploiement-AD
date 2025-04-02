# Déploiement Active Directory Automatisé

Ce script PowerShell permet d'automatiser plusieurs étapes nécessaires pour configurer un contrôleur de domaine Active Directory (AD). Il inclut les fonctionnalités suivantes :

## Fonctionnalités

1. **Vérification des privilèges administratifs**  
   Le script vérifie si l'utilisateur dispose des droits administratifs avant de continuer.

2. **Renommage du PC**  
   Demande à l'utilisateur un nouveau nom NetBIOS pour le PC et applique le changement.

3. **Configuration d'une adresse IP fixe**  
   Permet de configurer une adresse IP, un masque de sous-réseau, une passerelle par défaut et un serveur DNS.

4. **Installation du rôle Active Directory Domain Services (AD DS)**  
   Installe le rôle AD DS si celui-ci n'est pas déjà installé.

5. **Création d'une forêt Active Directory (optionnel)**  
   L'utilisateur peut choisir de créer une nouvelle forêt AD. Si cette option est sélectionnée :
   - Le script demande le nom de la forêt.
   - Configure la forêt.
   - Permet de créer des Unités Organisationnelles (OU) personnalisées.

6. **Importation des utilisateurs depuis des fichiers CSV**  
   L'utilisateur peut importer des utilisateurs dans des OUs spécifiques en fournissant un fichier CSV contenant les informations des utilisateurs.

## Prérequis

- Windows Server avec PowerShell installé.
- Droits administratifs pour exécuter le script.
- Les modules nécessaires pour gérer Active Directory doivent être disponibles (ex. `Active Directory Module for Windows PowerShell`).

## Utilisation

1. **Exécution du script**  
   Lancez le script avec des privilèges administratifs :
   ```powershell
   .\fast_ad.ps1
   ```

2. **Renommage du PC**  
   Fournissez un nouveau nom NetBIOS lorsque le script le demande.

3. **Configuration réseau**  
   Entrez les informations réseau (IP, masque, passerelle, DNS) lorsque le script le demande.

4. **Installation du rôle AD DS**  
   Le script installe automatiquement le rôle si nécessaire.

5. **Création de la forêt (optionnel)**  
   Répondez "Oui" ou "Non" lorsque le script demande si vous souhaitez créer une forêt. Si "Oui", fournissez le nom de la forêt et configurez les OUs.

6. **Importation des utilisateurs**  
   Fournissez le chemin des fichiers CSV contenant les utilisateurs et spécifiez l'OU cible pour chaque fichier.

### Format du fichier CSV

Le fichier CSV doit contenir les colonnes suivantes :
- `Name` : Nom complet de l'utilisateur.
- `FirstName` : Prénom.
- `LastName` : Nom de famille.
- `SamAccountName` : Nom de connexion.
- `UserPrincipalName` : Nom principal de l'utilisateur (ex. `user@example.com`).
- `Password` : Mot de passe de l'utilisateur.

Exemple :
```csv
Name,FirstName,LastName,SamAccountName,UserPrincipalName,Password
John Doe,John,Doe,jdoe,jdoe@example.com,P@ssw0rd!
Jane Smith,Jane,Smith,jsmith,jsmith@example.com,P@ssw0rd!
```

## Notes

- Assurez-vous que le fichier CSV est correctement formaté avant de l'importer.
- Si vous choisissez de ne pas créer une forêt, vous pouvez toujours importer des utilisateurs dans une forêt existante.

## Avertissement

Ce script effectue des modifications importantes sur le système. Utilisez-le uniquement dans un environnement contrôlé ou après avoir effectué une sauvegarde complète.

## Auteur

Créé par Louis.
