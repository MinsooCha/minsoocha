#Change DOMAIN to your Active directory domain name for example CONTOSO.
$Domain = "DOMAIN"
 
Write-Host -ForegroundColor Green "Searching for VMs not connected to for 2 months." 
Write-Host -ForegroundColor Green "Found VMs will be put in maintenance mode and shutdown." 
Write-Host -ForegroundColor Green "Script tested on XenDesktop 7x controller." 
 
#Load Citrix PS snappins
Add-PSSnapin Citrix*
 
$Lastused =((Get-Date).AddMonths(-2).ToString('yyyy-MM-dd HH:mm:s'))
$machines = Get-BrokerMachine -MachineName "$Domain\*" | 
Where-Object {$_.LastConnectionTime -lt $Lastused -and $_.LastConnectionTime -gt "1999-12-30 00:00:00" -and $_.InMaintenanceMode -match "False" -and $_.SessionCount -lt "1" } 
#Exit script if null
IF([string]::IsNullOrWhiteSpace($machines)) {            
    Write-Host -ForegroundColor Red "No machines in scope, exiting script."
    Exit            
} 
Write-Output $machines | select DNSName,LastConnectionTime
#Export list to CSV file.
$machines | select DNSName,LastConnectionTime,{$_.AssociatedUserNames} | Export-CSV "$PSScriptRoot\$(get-date -f yyyy-MM-dd) Unused VDIs.csv"
 
#Add a tag to the VM
$machines_tags = Get-BrokerDesktop -MachineName "$Domain\*" | 
Where-Object {$_.LastConnectionTime -lt $Lastused -and $_.LastConnectionTime -gt "1999-12-30 00:00:00" -and $_.InMaintenanceMode -match "False"} 
$tag = "VM put in maintenance mode by script $(get-date -f yyyy-MM-dd-hh-mm)"
New-Brokertag -name $tag 
Foreach ($machines_tag in $machines_tags){ 
    Add-BrokerTag -name $tag -Desktop $machines_tag
}
 
#Put VM in maintenance mode.
Set-BrokerMachineMaintenanceMode -InputObject $machines $true
 
#Shut down VM.
Foreach ($machine in $machines){ 
New-BrokerHostingPowerAction -MachineName $machine.MachineName -Action Shutdown
}
 
Write-Host -ForegroundColor Green "Script finished."