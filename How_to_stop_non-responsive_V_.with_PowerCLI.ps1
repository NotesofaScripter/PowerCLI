# This script is originally from http://www.virtu-al.net/2011/09/08/esxcli-and-killing-a-stuck-vm/
# http://notesofascripter.com/2016/02/02/how-to-stop-unrepostive-vm-with-powercli/

Function Kill-VM {
      <# .SYNOPSIS Kills a Virtual Machine. .DESCRIPTION Kills a virtual machine at the lowest level, use when Stop-VM fails. .PARAMETER VM The Virtual Machine to Kill. .PARAMETER KillType The type of kill operation to attempt. There are three types of VM kills that can be attempted: [soft, hard, force]. Users should always attempt 'soft' kills first, which will give the VMX process a chance to shutdown cleanly (like kill or kill -SIGTERM). If that does not work move to 'hard' kills which will shutdown the process immediately (like kill -9 or kill -SIGKILL). 'force' should be used as a last resort attempt to kill the VM. If all three fail then a reboot is required. .EXAMPLE PS C:\> Kill-VM -VM (Get-VM VM1) -KillType soft
  
      .EXAMPLE
         PS C:\> Get-VM VM* | Kill-VM
  
      .EXAMPLE
         PS C:\> Get-VM VM* | Kill-VM -KillType hard
   #>
   param (
      [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
      $VM, $KillType
   )
   PROCESS {
      if ($VM.PowerState -eq "PoweredOff") {
         Write-Host "$($VM.Name) is already Powered Off"
      } Else {
         $esxcli = Get-EsxCli -vmhost ($VM.VMHost)
         $WorldID = ($esxcli.vm.process.list() | Where { $_.DisplayName -eq $VM.Name}).WorldID
         if (-not $KillType) {
            $KillType = "soft"
         }
         $result = $esxcli.vm.process.kill($KillType, $WorldID)
         if ($result -eq "true"){
            Write-Host "$($VM.Name) killed via a $KillType kill"
         } Else {
            $result
         }
      }
   }
}