# Script pour configurer un serveur Windows Server 2022
# Exécuter en mode administrateur

# Demander si l'utilisateur veut renommer le serveur
$renameChoice = Read-Host "Voulez-vous renommer le serveur ? (Oui/Non)"
if ($renameChoice -eq "Oui" -or $renameChoice -eq "oui") {
    $newName = Read-Host "Entrez le nouveau nom du serveur"
    Rename-Computer -NewName $newName -Force -Restart
    Write-Host "Le serveur va redémarrer avec le nouveau nom : $newName"
    exit
}

# Récupérer les informations IP actuelles attribuées par DHCP
$interface = Get-NetIPConfiguration
$currentIP = $interface.IPv4Address.IPAddress
$gateway = $interface.IPv4DefaultGateway.NextHop
$dns = $interface.DNSServer.ServerAddresses
$interfaceIndex = (Get-NetAdapter).ifIndex

# Afficher les informations récupérées
Write-Host "IP actuelle (DHCP) : $currentIP"
Write-Host "Passerelle : $gateway"
Write-Host "DNS : $dns"

# Demander la confirmation pour passer en IP statique
$ipChoice = Read-Host "Voulez-vous passer cette configuration en statique ? (Oui/Non)"
if ($ipChoice -eq "Oui" -or $ipChoice -eq "oui") {
    # Désactiver le DHCP sur l'interface
    Set-NetIPInterface -InterfaceIndex $interfaceIndex -Dhcp Disabled
    Write-Host "DHCP désactivé sur l'interface."

    # Supprimer l'adresse IP existante pour éviter les conflits
    $existingIP = Get-NetIPAddress -InterfaceIndex $interfaceIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue
    if ($existingIP -and $existingIP.IPAddress -eq $currentIP) {
        Remove-NetIPAddress -InterfaceIndex $interfaceIndex -IPAddress $currentIP -Confirm:$false
        Write-Host "Adresse IP existante supprimée."
    }

    # Configurer l'IP statique avec les valeurs récupérées
    New-NetIPAddress -InterfaceIndex $interfaceIndex -IPAddress $currentIP -PrefixLength 24 -DefaultGateway $gateway
    Set-DnsClientServerAddress -InterfaceIndex $interfaceIndex -ServerAddresses $dns
    Write-Host "Configuration IP statique appliquée avec succès : $currentIP"
}

# Installation du rôle ADDS
Write-Host "Installation du rôle Active Directory Domain Services..."
$addsInstall = Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools
if ($addsInstall.Success) {
    Write-Host "Rôle ADDS installé avec succès."
} else {
    Write-Host "Échec de l'installation du rôle ADDS. Erreur : $($addsInstall.ExitCode)"
    exit
}

# Promotion en contrôleur de domaine
$domainName = Read-Host "Entrez le nom de domaine (ex: contoso.local)"
$safeModePassword = Read-Host "Entrez le mot de passe SafeMode (sécurisé)" -AsSecureString

Write-Host "Démarrage de la promotion du serveur en contrôleur de domaine..."
try {
    Install-ADDSForest `
        -DomainName $domainName `
        -SafeModeAdministratorPassword $safeModePassword `
        -InstallDns `
        -Force `
        -NoRebootOnCompletion `
        -ErrorAction Stop
    Write-Host "Promotion du contrôleur de domaine réussie."
} catch {
    Write-Host "Erreur lors de la promotion du DC : $_"
    exit
}

Write-Host "Configuration terminée. Le serveur va redémarrer pour finaliser la promotion."
Restart-Computer -Force