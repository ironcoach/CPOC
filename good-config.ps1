## Good-Config.ps1 - 
##
##  This script will configure the newly clone centos template.
##

$ScriptRoot = Split-Path $MyInvocation.MyCommand.Path
. "$ScriptRoot\good-variables.ps1"



write-host “Connecting to vCenter Server $vCenter” -foreground green
Connect-viserver $vCenter -user $vCenterUser -password $vCenterUserPassword -WarningAction 0

 ##########
# Now start customizing VM to your specs.

for ($i = $vmstartPerf; $i -lt $vmCountPerf + $vmstartPerf; $i++) {

  $pad_i = "{0:00}" -f $i
  $name = $vmNamePerf + $pad_i
  write-host "Starting VM  $i  - $name"
 
  start-vm $name -RunAsync | out-null
  
 do
 {
   write-host "          Waiting for startup..."
   Start-Sleep -Seconds 5; 
   $vm = Get-VM $name
   $toolsStatus = $vm.extensionData.Guest.ToolsStatus;
  } while( $toolsStatus -ne "toolsOK" -and $toolsStatus -ne "toolsOld" );
}

Sleep 10 
write-host "  "
write-host "Starting configuration now that systems are started"
write-host " "

write-host "Create /etc/hosts and .rhosts files..."
write-host " "

"127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4" | out-file 'hostcfg.txt' -encoding ascii
"::1         localhost localhost.localdomain localhost6 localhost6.localdomain6" | out-file 'hostcfg.txt' -append -encoding ascii

$first = $true

for ($i = $vmstartPerf; $i -lt $vmCountPerf + $vmstartPerf; $i++) {
  $pad_i = "{0:00}" -f $i
  $name = $vmNamePerf + $pad_i
  $ipNum = $ipStartPerf + $pad_i
  $ipAddr = $ipBasePerf + $ipNum
                   
  $outstr = $ipAddr + "   " + $name + "    " + $name + ".cpoc.local"
  $outstr  | out-file hostcfg.txt -append -encoding ascii

  if ($first)  {   
    $ipAddr | out-file 'rhostcfg.txt' -encoding ascii 
    $first = $false
    }
  else
    {
      $ipAddr | out-file 'rhostcfg.txt' -append -encoding ascii
    }

}


for ($i = $vmstartPerf; $i -lt $vmCountPerf + $vmstartPerf; $i++) {
  $pad_i = "{0:00}" -f $i
  $name = $vmNamePerf + $pad_i
   write-host "Configuring VM - $name"
 
  $ipNum = $ipStartPerf + $i  
  $ipAddr = $ipBasePerf + $ipNum

  "DEVICE=eth0" | out-file 'ethcfg0.txt' -encoding ascii
  "BOOTPROTO=static" | out-file 'ethcfg0.txt' -append -encoding ascii
  "IPADDR=$ipAddr" | out-file 'ethcfg0.txt' -append -encoding ascii
  "NETMASK=255.255.0.0" | out-file 'ethcfg0.txt' -append -encoding ascii
  "GATEWAY=" + $ipGatewayPerf | out-file 'ethcfg0.txt' -append -encoding ascii
  "DNS1=" + $ipDNSPerf | out-file 'ethcfg0.txt' -append -encoding ascii
  "MTU=1500" | out-file 'ethcfg0.txt' -append -encoding ascii
  "IPV6INIT=no" | out-file 'ethcfg0.txt' -append -encoding ascii
  "ONBOOT=yes" | out-file 'ethcfg0.txt' -append -encoding ascii
  "TYPE=Ethernet" | out-file 'ethcfg0.txt' -append -encoding ascii
  

  write-host "     Updating ifcfg-eth0 file..."

  "NETWORKING=yes" | out-file 'netcfg.txt' -encoding ascii
  "HOSTNAME=$name" | out-file 'netcfg.txt' -append -encoding ascii
  
  write-host "     Updating network file..."

  write-host "     Updating hosts file..."
  
  write-host "     Updating .rhosts file..."
  
  write-host "     Clear 70-persistent-net.rules..."

  write-host "     Create NFS mounts..."
  
# "hostnamectl set-hostname " + $name  | out-file 'mounts.txt' -encoding ascii

  write-host "  Creating ZIP file"
  zip configset.zip *.txt

  write-host "Copying ZIP file to $name"
  Copy-VMGuestFile -VM $name -LocalToGuest -Source configset.zip -Destination /root/configset.zip -GuestCredential $gc -force

  write-host "Copying vmconfig.sh file to $name"
  Copy-VMGuestFile -VM $name -LocalToGuest -Source vmconfig.sh -Destination /root/vmconfig.sh -GuestCredential $gc -force
  invoke-vmscript -vm $name -hostcredential $hc -guestcredential $gc "dos2unix vmconfig.sh"
  invoke-vmscript -vm $name -hostcredential $hc -guestcredential $gc "chmod +x /root/vmconfig.sh"
  invoke-vmscript -vm $name -hostcredential $hc -guestcredential $gc "/root/vmconfig.sh"

  Restart-VM -VM $name -RunAsync -Confirm:$false

}


write-host "VM configuration complete."