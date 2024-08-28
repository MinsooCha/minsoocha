asnp citrix*

$Path="C:\temp\info.csv"
Get-BrokerMachine -DesktopGroupName "Static Dedi" | Select-Object MachineName, DesktopGroupName, HostedMachineName, CatalogName | Export-csv -Path $Path -Encoding UTF8 
$VMList = Import-Csv -Path $Path

foreach ($VMInfo in $VMList) {
    $ADSID = Get-ProvVM -VMName $VMInfo.HostedMachineName | Select-Object ADAccountSid
    Get-BrokerMachine -MachineName $VMInfo.MachineName | Remove-BrokerMachine -DesktopGroup $VMInfo.DesktopGroupName
    Get-ProvVM -VMName $VMInfo.HostedMachineName | Unlock-ProvVM
    Get-ProvVM -VMName $VMInfo.HostedMachineName | Remove-ProvVM
    Get-BrokerMachine $VMInfo.MachineName | Remove-BrokerMachine
    Remove-AcctADAccount -ADAccountSid $ADSID.ADAccountSid -IdentityPoolName $VMinfo.CatalogName -RemovalOption "delete"
}