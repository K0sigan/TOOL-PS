$CompName = Read-Host 'Nom du pc'
$Cred = Get-Credential 
Enter-PSSession -ComputerName $CompName -Credential $Cred