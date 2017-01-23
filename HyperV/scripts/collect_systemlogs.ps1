$scriptLocation = [System.IO.Path]::GetDirectoryName($myInvocation.MyCommand.Definition)
. "$scriptLocation\config.ps1"

systeminfo >> "$openstackLogs\systeminfo.log"
wmic qfe list >> "$openstackLogs\windows_hotfixes.log"
pip freeze >> "$openstackLogs\pip_freeze.log"
ipconfig /all >> "$openstackLogs\ipconfig.log"

get-netadapter | Select-object * >> "$openstackLogs\get_netadapter.log"
get-vmswitch | Select-object * >> "$openstackLogs\get_vmswitch.log"
get-WmiObject win32_logicaldisk | Select-object * >> "$openstackLogs\disk_free.log"
get-netfirewallprofile | Select-Object * >> "$openstackLogs\firewall.log"
get-process | Select-Object * >> "$openstackLogs\get_process.log"
get-service | Select-Object * >> "$openstackLogs\get_service.log"

sc qc nova-compute >> "$openstackLogs\nova_compute_service.log"
sc qc neutron-hyperv-agent >> "$openstackLogs\neutron_hyperv_agent_service.log"
