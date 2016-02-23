$oldntpservers='192.168.0.1','192.168.0.2'
$newntpservers='0.vmware.pool.ntp.org','1.vmware.pool.ntp.org','2.vmware.pool.ntp.org'

foreach($vmhost in get-vmhost){
#stops ntpd service
$vmhost|Get-VMHostService |?{$_.key -eq 'ntpd'}|Stop-VMHostService -Confirm:$false

#remove existing ntpservers
$vmhost|Remove-VMHostNtpServer -NtpServer $oldntpservers -Confirm:$false

#adds new ntpservers
$vmhost|Add-VmHostNtpServer -NtpServer $newntpservers

#start ntpd service
$vmhost|Get-VMHostService |?{$_.key -eq 'ntpd'}|Start-VMHostService
}
