# Script pour configurer un serveur Windows Server 2022
# Exécuter en mode administrateur

# Vérifications préalables
Write-Host "Vérification des prérequis..."
if (-not (Test-NetConnection -ComputerName "localhost" -Port 53 -ErrorAction SilentlyContinue)) {
    Write-Host "Attention : Le service DNS local ne semble pas répondre. Vérifiez la configuration réseau."
}

# Vérifier si le rôle ADDS est déjà installé
if (Get-WindowsFeature -Name AD-Domain-Services | Where-Object { $_.Installed }) {
    Write-Host "Le rôle ADDS est déjà installé. Aucune action nécessaire."
    exit
}

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

# Test de connectivité réseau
Write-Host "Test de la connectivité réseau..."
if (Test-NetConnection -ComputerName $currentIP -Port 53 -ErrorAction SilentlyContinue) {
    Write-Host "DNS local répond correctement."
} else {
    Write-Host "Attention : Problème potentiel avec le DNS. Vérifiez la configuration."
}

# Installation du rôle ADDS avec journalisation
Write-Host "Installation du rôle Active Directory Domain Services..."
$logFile = "C:\Windows\Temp\ADDSInstall.log"
$addsInstall = Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools -LogPath $logFile
if ($addsInstall.Success) {
    Write-Host "Rôle ADDS installé avec succès. Consultez le journal : $logFile"
} else {
    Write-Host "Échec de l'installation du rôle ADDS. Erreur : $($addsInstall.ExitCode)"
    Write-Host "Consultez le journal pour plus de détails : $logFile"
    exit
}

# Configurer l'IP statique après l'installation d'ADDS
Write-Host "Configuration de l'IP statique..."
$ipChoice = Read-Host "Voulez-vous configurer une IP statique maintenant ? (Oui/Non)"
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
    Set-DnsClientServerAddress -InterfaceIndex $interfaceIndex -ServerAddresses $gateway
    Write-Host "Configuration IP statique appliquée avec succès : $currentIP"
    Write-Host "DNS configuré sur la passerelle : $gateway"
}

# Promotion en contrôleur de domaine avec gestion des blocages
$domainName = Read-Host "Entrez le nom de domaine (ex: contoso.local)"
$safeModePassword = Read-Host "Entrez le mot de passe SafeMode (sécurisé)" -AsSecureString

Write-Host "Démarrage de la promotion du serveur en contrôleur de domaine..."
$promotionLog = "C:\Windows\Temp\ADDSPromotion.log"
try {
    $promotionTask = Start-Job -ScriptBlock {
        Install-ADDSForest `
            -DomainName $using:domainName `
            -SafeModeAdministratorPassword $using:safeModePassword `
            -CreateDnsDelegation:$false `
            -InstallDns `
            -Force `
            -ErrorAction Stop `
            -LogPath $using:promotionLog
    }

    # Attendre la fin de la tâche avec un délai maximum
    $timeout = 1800 # 30 minutes
    $elapsed = 0
    while ($promotionTask.State -eq "Running" -and $elapsed -lt $timeout) {
        Start-Sleep -Seconds 10
        $elapsed += 10
    }

    if ($promotionTask.State -eq "Running") {
        Write-Host "La promotion semble bloquée après 30 minutes. Consultez le journal : $promotionLog"
        Stop-Job -Job $promotionTask -Force
        exit
    }

    # Vérifier le résultat de la tâche
    $result = Receive-Job -Job $promotionTask
    if ($result) {
        Write-Host "Promotion lancée avec succès. Le serveur va redémarrer pour finaliser."
    } else {
        Write-Host "Erreur lors de la promotion du DC. Consultez le journal : $promotionLog"
        exit
    }
} catch {
    Write-Host "Erreur inattendue lors de la promotion : $_"
    Write-Host "Consultez le journal pour plus de détails : $promotionLog"
    exit
}

# Forcer le redémarrage après un court délai
Start-Sleep -Seconds 10
Write-Host "Redémarrage du serveur..."
Restart-Computer -Force