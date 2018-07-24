###
###
#  This file contains the variables necessary to run the HCI Setup Scripts
#
#
###



# SolidFire Cluster
$mvip = "172.16.107.106"
$svip = "172.17.107.106"
$SFadmin = "admin"
$SFaccount = "CPOCadmin"
$SFvag = "NetApp-HCI"

$SFpassword = "cpocHCIs7!"


#Volume Size and Attributes
$volSize = "100"
$numVols = 4
$minIOPS = 5000
$maxIOPS = 100000
$burstIOPS = 100000

# vCenter
$vCenter="172.16.107.12"
$vCenterUser="administrator@vsphere.local"
$vCenterUserPassword=$SFpassword

#ESX host for cloning
$esxhost ="172.16.107.103"

# Name of template to be used as source for cloning
$VMclone = "centos_kit_local"


#ESX Host Password
$HCpassword = ConvertTo-SecureString -AsPlainText -Force $SFpassword

#Guest VM Password - Template
$GCpassword = ConvertTo-SecureString -AsPlainText -Force "cpoc99977"

# Create Credentials
$hc = New-Object System.Management.Automation.PSCredential -ArgumentList "root", $HCpassword
$gc = New-Object System.Management.Automation.PSCredential -ArgumentList "root", $GCpassword


# $ipstart is the lowest last octet MINUS 1
$ipStartPerf = 170
$ipBasePerf = "172.16.175."
$ipGatewayPerf = "172.16.0.1" 
$ipDNSPerf = "172.16.0.5" 

# Targets for NFS mounts
$pocshare = "10.61.100.105:/vol/poc/"

$infra_ds = "infrastructure"



#Perf VM Attributes
$vmStartPerf =1
$vmCountPerf = 8
$numVols = 5
$minIOPS = 2000
$maxIOPS = 100000
$burstIOPS = 100000

$vmNamePerf = "hcis7-bully"
$vm_namesPerf = @("","","","","","","","","","","","","","","","","","","","","","","","","","","","","" )

# $ipstart is the lowest last octet MINUS 1
$ipStartPerf = 180
$ipBasePerf = "172.16.175."

