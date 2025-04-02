# Vérifier si le script est exécuté avec des privilèges administratifs
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Error "Ce script doit être exécuté en tant qu'administrateur."
    exit
}

# Demander si l'utilisateur souhaite renommer le PC
$renamePC = Read-Host "Souhaitez-vous renommer ce PC ? (Oui/Non)"
if ($renamePC -eq "Oui") {
    $computerName = Read-Host "Entrez le nouveau nom NetBIOS pour ce PC"
    Rename-Computer -NewName $computerName -Force -Restart:$false
    Write-Host "Le PC a été renommé en '$computerName'."
} else {
    Write-Host "Renommage du PC ignoré."
}

# Configurer une IP fixe basée sur l'IP actuelle attribuée par le DHCP
$adapter = Get-NetAdapter | Where-Object {$_.Status -eq "Up"}
$dhcpInfo = Get-NetIPAddress -InterfaceAlias $adapter.InterfaceAlias | Where-Object {$_.AddressFamily -eq "IPv4"}
if ($dhcpInfo) {
    $defaultGateway = if ($dhcpInfo.DefaultGateway) { $dhcpInfo.DefaultGateway } else { $null }
    New-NetIPAddress -IPAddress $dhcpInfo.IPAddress -PrefixLength $dhcpInfo.PrefixLength -InterfaceAlias $adapter.InterfaceAlias -DefaultGateway $defaultGateway
    Set-DnsClientServerAddress -InterfaceAlias $adapter.InterfaceAlias -ServerAddresses $dhcpInfo.DNSServer
    Write-Host "L'adresse IP fixe a été configurée en utilisant l'IP attribuée par le DHCP."
} else {
    Write-Error "Impossible de récupérer les informations DHCP. Vérifiez la connectivité réseau."
    exit
}

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

    # Configurer la nouvelle forêt et promouvoir le PC en contrôleur de domaine
    Write-Host "Configuration de la forêt Active Directory et promotion en contrôleur de domaine..."
    Install-ADDSForest -DomainName $forestName -Force -SafeModeAdministratorPassword (ConvertTo-SecureString -AsPlainText (Read-Host "Entrez un mot de passe pour le mode restauration AD" -AsSecureString) -Force)
} else {
    Write-Host "Création de la forêt ignorée."
}

Write-Host "Déploiement terminé."
