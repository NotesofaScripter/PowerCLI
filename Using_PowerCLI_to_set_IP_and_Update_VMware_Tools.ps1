$vms = Import-CSV "C:\Scripts\VMWare\VM Creation\NewVMs.csv"
$GC = $Host.UI.PromptForCredential("Please enter credentials", "Enter Guest credentials for VM", "Administrator", "")


foreach ($vm in $vms){
        $VMName = $vm.Name
        $IP = $vm.IP
        $SNM = $vm.SubnetMask
        $GW = $vm.Gateway
        $DNS1 = $vm.DNS1
        $DNS2 = $vm.DNS2
        $WINS1 = $vm.WINS1
        $WINS2 = $vm.WINS2
        $Network = $vm.Network
        $Template = $vm.Template

        DO {(Get-VMGuest $VMName).HostName}
        while (((Get-VMGuest $VMName).HostName) -Ne "$VMName")

        Get-VM $VMName | Update-Tools
        $VMTool = Get-VM $VMName | Out-Null
        $VMTool | Select -ExpandProperty ExtensionData | Select -ExpandProperty guest
        $VMToolStatus = $VMTool.ToolsRunningStatus
        Write-host "Checking that VMWare Tools are running on"$VMName -ForegroundColor Yellow
        Sleep -Seconds 5
        Do {Write-host "Still checking for VMWare Tools on"$VMName -ForegroundColor Yellow; sleep -Seconds 5}
        While ($VMToolStatus -eq "guestToolsRunning")
        Write-Host "VMWare tools are now running on"$VMName -ForegroundColor Green
      
        
        $Network = Invoke-VMScript -VM $VMName -ScriptType Powershell -ScriptText "(gwmi Win32_NetworkAdapter -filter 'netconnectionid is not null').netconnectionid" -GuestUser administrator -GuestPassword Oicunow2
        $NetworkName = $Network.ScriptOutput
        $NetworkName = $NetworkName.Trim()
        Write-Host "Setting IP address for $VMname..." -ForegroundColor Yellow
        Sleep -Seconds 60
        $netsh = "c:\windows\system32\netsh.exe interface ip set address ""$NetworkName"" static $IP $SNM $GW" 
        $netsh2 = "c:\windows\system32\netsh.exe interface ip set dnsservers ""$NetworkName"" static $DNS1"
        $netsh3 = "c:\windows\system32\netsh.exe interface ip add dnsservers ""$NetworkName"" $DNS2"
        $netsh4 = "c:\windows\system32\netsh.exe interface ip set winsservers ""$NetworkName"" static $WINS1"
        $netsh5 = "c:\windows\system32\netsh.exe interface ip add winsservers ""$NetworkName"" $WINS2"
        Invoke-VMScript -VM $VMname -GuestCredential $GC -ScriptType bat -ScriptText $netsh 
        Invoke-VMScript -VM $VMname -GuestCredential $GC -ScriptType bat -ScriptText $netsh2  
        Invoke-VMScript -VM $VMname -GuestCredential $GC -ScriptType bat -ScriptText $netsh3 
        Invoke-VMScript -VM $VMname -GuestCredential $GC -ScriptType bat -ScriptText $netsh4
        Invoke-VMScript -VM $VMname -GuestCredential $GC -ScriptType bat -ScriptText $netsh5 
        Write-Host "Setting IP address completed." -ForegroundColor Green
        
    
        }
