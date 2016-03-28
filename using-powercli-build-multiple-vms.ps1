$vms = Import-CSV "C:\Scripts\NewVMs.csv"

foreach ($vm in $vms){
#Assign Variables
$Template = Get-Template -Name $vm.Template
$Cluster = $vm.Cluster
$Datastore = Get-Datastore -Name $vm.Datastore
$Custom = Get-OSCustomizationSpec -Name $vm.Customization
$vCPU = $vm.vCPU
$Memory = $vm.Memory
$Network = $vm.Network
$Location = $vm.Location
$VMName = $vm.Name

#Where the VM gets built
New-VM -Name $VMName -Template $Template -ResourcePool (Get-Cluster $Cluster | Get-ResourcePool) -Location $Location -StorageFormat Thin -Datastore $Datastore -OSCustomizationSpec $Custom
Start-Sleep -Seconds 10

#Where the vCPU, memory, and network gets set
$NewVM = Get-VM -Name $VMName
$NewVM | Set-VM -MemoryGB $Memory -NumCpu $vCPU -Confirm:$false
$NewVM | Get-NetworkAdapter | Set-NetworkAdapter -NetworkName $Network -Confirm:$false
}