# Vérifier si le script est exécuté avec des privilèges administratifs
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Error "Ce script doit être exécuté en tant qu'administrateur."
    exit
}

# Installer le rôle AD DS si nécessaire
if (-not (Get-WindowsFeature -Name AD-Domain-Services).Installed) {
    Write-Host "Installation du rôle Active Directory Domain Services..."
    Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools
}

# Demander le nom de la forêt à l'utilisateur
$forestName = Read-Host "Entrez le nom de la forêt à créer (ex: example.com)"

# Configurer la nouvelle forêt
Write-Host "Configuration de la forêt Active Directory..."
Install-ADDSForest -DomainName $forestName -Force -SafeModeAdministratorPassword (ConvertTo-SecureString -AsPlainText (Read-Host "Entrez un mot de passe pour le mode restauration AD" -AsSecureString) -Force)

# Création des OUs
Write-Host "Création des Unités Organisationnelles (OU)..."
while ($true) {
    $ouName = Read-Host "Entrez le nom de l'OU à créer (ou appuyez sur Entrée pour terminer)"
    if ([string]::IsNullOrWhiteSpace($ouName)) {
        break
    }
    New-ADOrganizationalUnit -Name $ouName -Path "DC=$($forestName -replace '\.', ',DC=')"
    Write-Host "OU '$ouName' créée avec succès."
}

Write-Host "Déploiement terminé."
