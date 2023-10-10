#Importation du module PowerCLI
Import-Module VMware.PowerCLI

#Declaration du Vcenter & du Template
$vcenter = "vcenter"
$templateName = "template"
$datastoreName = "datastore"
$clusterName = "cluster"

#Déclaration de la nouvelle VM
$newVMName = Read-Host -Prompt "Nom de la nouvelle VM"
$newIP = Read-Host -Prompt " Nouvelle IP de la VM"

#Connexion a VCO
$domcredentials = Get-Credential -Message "Entrez vos identifiants du domaine pour vCenter"
Connect-VIServer -Server $vcenter -Credential $domcredentials

#Création de la VM
New-VM -Name $newVMName -Template $templateName -ResourcePool (Get-Cluster $clusterName) -Datastore $datastoreName

# Démarrer la VM
Start-VM -VM $newVMName

#Connexion A la VM
$vmIP = "ip par defautl du template"
$localUsername = "Utilisateur local du template"
$localPassword = ConvertTo-SecureString "mot de passe de l'utilisateur " -AsPlainText -Force
$localCredential = New-Object System.Management.Automation.PSCredential($localUsername, $localPassword)

# Attente du boot de la VM
do {
    $ping = Test-Connection -ComputerName $vmIP -Count 1 -Quiet -ErrorAction SilentlyContinue
    if (-not $ping) {
        Write-Output "En attente que $vmIP soit joignable..."
        Start-Sleep -Seconds 5
    }
} while (-not $ping)
Write-Output "$vmIP est joignable. Poursuite du script..."

# Ouvrir une PSSession pour renomer la machine et ajouter l'IP
$session = New-PSSession -ComputerName $vmIP -Credential $localCredential

# Modification de l'IP de la vm
Invoke-Command -Session $session -ScriptBlock {
    New-NetIPAddress -InterfaceIndex 12 -IPAddress $using:newIP -PrefixLength 24
}

# Ouverture d'une nouvelle session pour la jonction au domaine
$session = New-PSSession -ComputerName $newIP -Credential $localCredential

Invoke-Command -Session $session -ScriptBlock {
    Remove-NetIPAddress -InterfaceIndex 12 -IPAddress X.X.X.X -PrefixLength 24
    ename-Computer -NewName $using:newVMName #Pour rename uniquement la machine
    Add-Computer -DomainName domaine.local -NewName $using:newVMName -Credential $using:domcredentials #Pour rename et joindre le domaine
    shutdown.exe /r /f
}
Remove-PSSession -Session $session
