## Good-Init.ps1 - 
##
##  This script will clone the source VM and create volumes that are added to the VM as RDM luns.
##


$ScriptRoot = Split-Path $MyInvocation.MyCommand.Path
. "$ScriptRoot\good-variables.ps1"


Write-host “Connecting to vCenter Server $vCenter” -foreground green
Connect-viserver $vCenter -user $vCenterUser -password $vCenterUserPassword -WarningAction 0

###  Connect to SolidFire Cluster
write-host "Connecting to SolidFire cluster...."
Connect-sfcluster -target $mvip -username $SFadmin -password $SFpassword

$Account = Get-SFAccount $SFaccount


# Get VAG Identifier
$vagID = (Get-SFVolumeAccessGroup $SFvag).VolumeAccessGroupID

for ($i = $vmstartPerf; $i -lt $vmCountPerf + $vmstartPerf; $i++) {
    
  $pad_i = "{0:00}" -f $i
  $name = $vmNamePerf + $pad_i
  write-host "VMname $i  - $name"

  ###  Clone VM from source copy
  New-VM -Name $name -VM $VMclonePerf -VMhost $esxhost -Datastore $infra_ds 
  
  ### Create SolidFire Volumes
  ############################################# 
 

  for ($vNum = 1; $vNum -le $numVols; $vNum++) {
    $pad_v = "{0:000}" -f $vNum
    $volname = $name + "-v" + $pad_v
    Get-SFVolume -Name $volname | Remove-SFVolume -Confirm:$false
    Get-SFDeletedVolume -Name $volname | Remove-SFDeletedVolume -Confirm:$false
    New-SFVolume -Name $volname -AccountID $Account.AccountID -TotalSize $volSize -GB -Enable512e:$true -MinIOPS $minIOPS -MaxIOPS $maxIOPS -BurstIOPS $burstIOPS 
  }
 
  
  ###  Rescan VM Host for new storage devices.
  write-host "Rescan ESX host for new storage...."
  Get-VMHostStorage -vmhost $esxhost -RescanAllHba | out-null
 
  $strTemp = $name + "*"
  write-host $strTemp -foregroundcolor Green

  $volumes = Get-SFVolume $strTemp
  $volumes | Add-SFVolumeToVolumeAccessGroup -VolumeAccessGroupID $vagID

  
  ###  Rescan VM Host for new storage.
  write-host "Rescan ESX host for new storage...."
  Get-VMHostStorage -vmhost $esxhost -RescanAllHba | out-null


  foreach ($vol in $volumes) {
    #$deviceName = ($vmhost | Get-ScsiLun | Where {$_.CanonicalName -match "naa"})[0].ConsoleDeviceName

    $devTemp = "/vmfs/devices/disks/naa." + $vol.ScsiNAADeviceID
    write-host "Found..." + $devTemp
    new-harddisk -vm $name -Disktype RawPhysical -DeviceName $devTemp -Controller "SCSI controller 1"
  }


}

write-host "Rescan ALL ESX hosts for new storage...."
Get-VMHost | Get-VMHostStorage -RescanAllHba | out-null

write-host "VM and test LUN creation complete."
   