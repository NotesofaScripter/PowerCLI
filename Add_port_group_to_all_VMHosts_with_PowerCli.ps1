$NetworkInfo = Import-CSV C:\scripts\logs\NetworkInfo.csv
$ClusterName = "VM_Cluster"
$VMHosts = Get-Cluster $ClusterName | Get-VMHost
Foreach ($network in $NetworkInfo){
    $NewPortSwitch = $network.NewPortSwitch
    $VLANID = $Network.VLANID
    Foreach ($VMHost in $VMHosts){
        IF (($VMHost | Get-VirtualPortGroup -name $NewPortSwitch -ErrorAction SilentlyContinue) -eq $null){
            Write-host "Creating $NewPortSwitch on VMhost $VMHost" -ForegroundColor Yellow
            $NEWPortGroup = $VMhost | Get-VirtualSwitch | Select -last 1 | New-VirtualPortGroup -Name $NewPortSwitch -VLanId $VLANID
        }
    }
}