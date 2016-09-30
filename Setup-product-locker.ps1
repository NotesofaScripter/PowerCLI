$Cluster         = "VMClusterName"
$DataStoreName   = "DataStore_with_Downloaded_VMTools"
$VMhosts         = Get-Cluster $Cluster | Get-VMHost -Datastore $DataStoreName | Where {$_.ConnectionState -eq "Connected"}
$Datastore       = Get-Datastore $DataStoreName
$PL_Folder       = "productLocker"
$plink           = "C:\Scripts\Applications\plink.exe"
$plinkfolder     = Get-ChildItem $plink
$creds           = (Get-Credential -Message "What is the login for your ESXi Hosts?")
$username        = $creds.UserName
$PW              = $creds.GetNetworkCredential().Password


# Full Path to ProductLockerLocation
Write-host "Full path to ProductLockerLocation: [vmfs/volumes/$($datastore.name)/$PL_Folder]" -ForegroundColor Green

# Set value on all hosts that access shared datastore
Get-AdvancedSetting -entity (Get-Cluster $Cluster | Get-VMHost -Datastore $DataStoreName) -Name 'UserVars.ProductLockerLocation'| Set-AdvancedSetting -Value "vmfs/volumes/$($datastore.name)/$PL_Folder" -confirm:$False

# Each host needs to have SSH enabled to continue
$SSHON = @()
 
# Foreach ESXi Host, see if SSH is running, if it is, add the host to the array
$VMHosts | % {
    if ($_ |Get-VMHostService | ?{$_.key -eq “TSM-SSH”} | ?{$_.Running -eq $true}) {
        $SSHON += $_.Name
        Write-host "SSH is already running on $($_.Name). adding to array to not be turned off at end of script" -ForegroundColor Yellow
    }

# if not, start SSH
    else {
        Write-host "Starting SSH on $($_.Name)" -ForegroundColor Yellow
        Start-VMHostService -HostService ($_ | Get-VMHostService | ?{ $_.Key -eq “TSM-SSH”} ) -Confirm:$false
    }
}

# Change directory to Plink location for ease of use
cd $plinkfolder.directoryname
$VMhosts | foreach {

# Run Plink remote SSH commands for each host
Write-host "Running remote SSH commands on $($_.Name)." -ForegroundColor Yellow
Echo Y | ./plink.exe $_.Name -pw $PW -l $username 'rm /productLocker'
Echo Y | ./plink.exe $_.Name -pw $PW -l $username "ln -s /vmfs/volumes/$($datastore.name)/$PL_Folder /productLocker"
}

write-host ""
write-host "Remote SSH Commands complete" -ForegroundColor Green
write-host ""

# Turn off SSH on hosts where SSH wasn't already enabled
$VMhosts | foreach { 
if ($SSHON -notcontains $_.name) {
Write-host "Turning off SSH for $($_.Name)." -ForegroundColor Yellow
Stop-VMHostService -HostService ($_ | Get-VMHostService | ?{ $_.Key -eq “TSM-SSH”} ) -Confirm:$false
} else {
Write-host "$($_.Name) already had SSH on before running the script. leaving SSH running on host..." -ForegroundColor Yellow
}
}