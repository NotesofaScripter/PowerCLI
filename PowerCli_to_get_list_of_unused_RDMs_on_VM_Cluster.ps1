$Cluster = "Cluster name here"
#This Line gets all of the LUNs that are connected to the first host in the cluster.
$AllSCSILuns = (Get-Cluster $Cluster | Get-VMHost | Select -First 1 | Get-ScsiLun | Where {$_.LunType -eq "disk"}).CanonicalName
#This line gathers all of the Datastores Connected to the cluster.
$DataStores = (Get-Cluster $Cluster | Get-VMHost | Get-Datastore | where {$_.Type -eq "VMFS"} | Get-View).info.VMFS.Extent.diskname
#This does the first compare and removes the Datastores from the master list
$DSRemoved = (Compare-Object -ReferenceObject $AllSCSILUNs -DifferenceObject $DataStoreVolumes).InputObject
#This line gets all of the used RDM LUNs from the cluster
$UsedSCSILUNs = (Get-Cluster $Cluster | Get-VMHost | Get-VM | Get-HardDisk -DiskType "RawPhysical","RawVirtual").ScsiCanonicalName | Sort -Unique
#This does the final compare and removes the used RDM LUNs from the master list
(Compare-Object -ReferenceObject $DSRemoved -DifferenceObject $UsedSCSILUNs).InputObject