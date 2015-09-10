# Configuration file
#
# Hyper-V
#
$openstackDir = "C:\OpenStack"
$baseDir = "$openstackDir\devstack\HyperV"
$scriptdir = "$baseDir\scripts"
$configDir = "$openstackDir\etc"
$templateDir = "$baseDir\templates"
$buildDir = "$openstackDir\build\openstack"
$binDir = "$openstackDir\bin"
$novaTemplate = "$templateDir\nova.conf"
$neutronTemplate = "$templateDir\neutron_hyperv_agent.conf"
$hostname = hostname
$rabbitUser = "stackrabbit"
$pythonDir = "C:\Python27"
$pythonArchive = "python27new.tar.gz"
$pythonExec = "$pythonDir\python.exe"

$remoteLogs="\\"+$devstackIP+"\openstack\logs"
$remoteConfigs="\\"+$devstackIP+"\openstack\config"

$downloadLocation = "http://dl.openstack.tld/"
