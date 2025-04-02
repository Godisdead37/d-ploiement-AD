# Vérifier si le script est exécuté avec des privilèges administratifs
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Error "Ce script doit être exécuté en tant qu'administrateur."
    exit
}

# Renommer le PC
$computerName = Read-Host "Entrez le nouveau nom NetBIOS pour ce PC"
Rename-Computer -NewName $computerName -Force -Restart:$false
Write-Host "Le PC a été renommé en '$computerName'."

# Configurer une IP fixe
$ipAddress = Read-Host "Entrez l'adresse IP fixe (ex: 192.168.1.100)"
$subnetMask = Read-Host "Entrez le masque de sous-réseau (ex: 255.255.255.0)"
$defaultGateway = Read-Host "Entrez la passerelle par défaut (ex: 192.168.1.1)"
$dnsServer = Read-Host "Entrez l'adresse du serveur DNS (ex: 192.168.1.1)"
New-NetIPAddress -IPAddress $ipAddress -PrefixLength ($subnetMask -split '\.').Count * 8 -DefaultGateway $defaultGateway -InterfaceAlias (Get-NetAdapter | Where-Object {$_.Status -eq "Up"}).InterfaceAlias
Set-DnsClientServerAddress -InterfaceAlias (Get-NetAdapter | Where-Object {$_.Status -eq "Up"}).InterfaceAlias -ServerAddresses $dnsServer
Write-Host "L'adresse IP fixe a été configurée."

# Installer le rôle AD DS si nécessaire
if (-not (Get-WindowsFeature -Name AD-Domain-Services).Installed) {
    Write-Host "Installation du rôle Active Directory Domain Services..."
    Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools
}

# Demander si l'utilisateur souhaite créer une forêt
$createForest = Read-Host "Souhaitez-vous créer une nouvelle forêt Active Directory ? (Oui/Non)"
if ($createForest -eq "Oui") {
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
} else {
    Write-Host "Création de la forêt ignorée."
}

# Importer les utilisateurs depuis un fichier CSV
Write-Host "Importation des utilisateurs depuis des fichiers CSV..."
while ($true) {
    $csvPath = Read-Host "Entrez le chemin du fichier CSV contenant les utilisateurs (ou appuyez sur Entrée pour terminer)"
    if ([string]::IsNullOrWhiteSpace($csvPath)) {
        break
    }
    if (-not (Test-Path $csvPath)) {
        Write-Host "Le fichier '$csvPath' n'existe pas. Veuillez réessayer."
        continue
    }
    $ouPath = Read-Host "Entrez le chemin de l'OU où importer les utilisateurs (ex: OU=Users,DC=example,DC=com)"
    $users = Import-Csv -Path $csvPath
    foreach ($user in $users) {
        New-ADUser -Name $user.Name -GivenName $user.FirstName -Surname $user.LastName -SamAccountName $user.SamAccountName -UserPrincipalName $user.UserPrincipalName -Path $ouPath -AccountPassword (ConvertTo-SecureString $user.Password -AsPlainText -Force) -Enabled $true
        Write-Host "Utilisateur '$($user.Name)' importé avec succès dans '$ouPath'."
    }
}

Write-Host "Importation des utilisateurs terminée."

Write-Host "Déploiement terminé."
