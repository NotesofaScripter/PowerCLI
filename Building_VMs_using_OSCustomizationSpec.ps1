$vms = Import-CSV "C:\Scripts\VMWare\VM Creation\NewVMs.csv" | Select -last 18
$credOSC = Get-Credential
 
foreach ($vm in $vms){
      #Assign Variables
      $Template          = Get-Template -Name $vm.Template
      $Cluster           = $vm.Cluster
      $Datastore         = Get-Datastore -Name $vm.Datastore
      $Custom            = "PowerCliOnly"
      $vCPU              = $vm.vCPU
      $Memory            = $vm.Memory
      $HardDrive         = $vm.Harddrive
      $HardDrive2        = $vm.Harddrive2
      $Network           = $vm.Network
      $Location          = $vm.Location
      $VMName            = $vm.Name
      $IP                = $vm.IP
      $SNM               = $vm.SubnetMask
      $GW                = $vm.Gateway
      $DNS1              = $vm.DNS1
      $DNS2              = $vm.DNS2
      $WINS1             = $vm.WINS1
      $WINS2             = $vm.WINS2
      $Description       = $VM.Description
      $OU                = $vm.OU
      $Agency            = $VM.Agency
      $Application       = $VM.Application
      $Billed            = $VM.Billed
      $Contact           = $VM.Contact
      $Phone             = $VM.ContactPhone
      $CreatedOn         = Get-Date -Format dd-MMM-yyyy
      $Managed           = $VM.Managed
      $RebootPolicy      = $VM.RebootPolicy
      $TicketNumber      = $VM.TicketNumber
      $IFADAccountExists = ""

      #Generate the Computer objects in AD to be able to join new VM to domain
      Write-host "Generating the AD Computer account for $VMName" -ForegroundColor Yellow
      $IFADAccountExists = get-adcomputer -Identity $VMName -Server "DC_Name_Here"
      IF ($IFADAccountExists -eq $False){
          New-ADComputer -Server "DC_Name_Here" -Name $VMName -Path $OU -Enabled $True | Out-Null
      }

      #Generate a new OSCustomizationSpec so this will add the servers to the domain, and configure the NIC
      $OSCustomizationSpecExists = Get-OSCustomizationSpec -name PowerCliOnly
      IF ($OSCustomizationSpecExists -eq $True){
          Remove-OSCustomizationSpec -OSCustomizationSpec PowerCliOnly -Confirm:$false
          }
      Write-Host "Generating OSCustomizationSpec file" -ForegroundColor Yellow
      New-OSCustomizationSpec -OrgName "Organization_Name" -OSType Windows -ChangeSid -Server 'vCenter_Server' -Name PowerCliOnly -FullName "Company_Name" -Type Persistent -AdminPassword "Password_Here" -TimeZone 'Eastern (U.S. and Canada)' -AutoLogonCount 3 -Domain "Domain_Name" -DomainCredentials $credOSC -NamingScheme Vm -Description "PowerCli Use only" -LicenseMode PerServer -LicenseMaxConnections 5 -Confirm:$false
      Write-Host "Generating OSCustomizationNicMapping file" -ForegroundColor Yellow
      Get-OSCustomizationNicMapping -OSCustomizationSpec PowerCliOnly | Set-OSCustomizationNicMapping -Position 1 -IpMode UseStaticIP -IpAddress $IP -SubnetMask $SNM -DefaultGateway $GW -Dns $DNS1,$DNS2 -Wins $WINS1,$WINS2 -Confirm:$false
            
      Write-Host "Generating new VM per spec sheet" -ForegroundColor Yellow
      New-VM -ResourcePool (Get-Cluster $Cluster | Get-ResourcePool) -Name $VMName -Location $Location -DiskStorageFormat Thin -Datastore $Datastore -Template $Template -OSCustomizationSpec $Custom -Notes $Description -confirm:$False

      #Sets the new VM as a variable to make configuration changes faster
      $NewVM = Get-VM -Name $VMName

      Write-host "Setting Memory and vCPU on $VMName" -ForegroundColor Yellow
      $NewVM | Set-VM -MemoryGB $Memory -NumCpu $vCPU -Confirm:$false
      Write-host "Setting Network Adapter on $VMName" -ForegroundColor Yellow
      $NewVM | Get-NetworkAdapter | Set-NetworkAdapter -NetworkName $Network -Confirm:$false

            
      #Primary Harddrive
      $NewVMHddSize = ($NewVM | Get-HardDisk | Where {$_.Name -eq "Hard disk 1"}).CapacityGB
      IF ($HardDrive -gt $NewVMHddSize){$NewVM | Get-HardDisk | Where {$_.Name -eq "Hard disk 1"} | Set-HardDisk -CapacityGB $HardDrive -Confirm:$false}
            
      #Secondary Harddrive
      $NewVMHdd2Size = ($NewVM | Get-HardDisk | Where {$_.Name -eq "Hard disk 2"}).CapacityGB
      IF($HardDrive2){
            Write-Host "Script is working on secondary harddrive sub routine.  VM template hdd size is $NewVMHdd2Size and the CSV is asking for $HardDrive2" -ForegroundColor Cyan
            IF($NewVMHdd2Size -eq $Null){
                Write-Host "This is the line that worked $NewVMHdd2Size -eq $Null" -ForegroundColor Yellow
                $NewVM | New-HardDisk -CapacityGB $HardDrive2 -ThinProvisioned
            }
            ElseIf($HardDrive2 -gt $NewVMHdd2Size){
                Write-Host "This is the line that worked $HardDrive2 -gt $NewVMHdd2Size" -ForegroundColor Green
                $NewVM | Get-HardDisk | Where {$_.Name -eq "Hard disk 2"} | Set-HardDisk -CapacityGB $HardDrive2 -Confirm:$false
            }
            
      }

      Write-host "Deleting the OSCustomizationSpec File" -ForegroundColor Yellow
      Remove-OSCustomizationSpec -OSCustomizationSpec PowerCliOnly -Confirm:$false
         
      #Notes and Custom Annotations             
      Write-host "Setting the notes on $VMName" -ForegroundColor Yellow
      $Description = @("$Description")
      Set-VM -vm $VMName -description "$Description" -Confirm:$false | Out-Null
      IF($Agency){$NewVM | Set-Annotation -customAttribute "Agency" -Value $Agency -Confirm:$false}
      IF($Application){$NewVM | Set-Annotation -customAttribute "Application" -Value $Application -Confirm:$false}
      IF($Billed){$NewVM | Set-Annotation -customAttribute "Billed" -Value $Billed -Confirm:$false}
      IF($Contact){$NewVM | Set-Annotation -customAttribute "Contact" -Value $Contact -Confirm:$false}
      IF($Phone){$NewVM | Set-Annotation -customAttribute "Contact Phone" -Value $Phone -Confirm:$false}
      $NewVM | Set-Annotation -customAttribute "CreatedOn" -Value $CreatedOn -Confirm:$false
      IF($Managed){$NewVM | Set-Annotation -customAttribute "Managed" -Value $Managed -Confirm:$false}
      IF($RebootPolicy){$NewVM | Set-Annotation -customAttribute "RebootPolicy" -Value $RebootPolicy -Confirm:$false}
      IF($TicketNumber){$NewVM | Set-Annotation -customAttribute "TicketNumber" -Value $TicketNumber -Confirm:$false}

      #Powers on the server
      Write-host "Powering on $VMName" -ForegroundColor Yellow
      Start-VM -VM $VMName -Confirm:$False
      
}

