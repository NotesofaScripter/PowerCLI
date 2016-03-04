function Get-FreeSpace ($clustername) {
get-cluster $clustername | Get-Datastore | Where {$_.Name -notlike "*ISO*" -and $_.Name -notlike "*template*" } | sort -Property FreeSpaceGB -Descending
}