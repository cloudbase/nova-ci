$scriptLocation = [System.IO.Path]::GetDirectoryName($myInvocation.MyCommand.Definition)
. "$scriptLocation\config.ps1"

systeminfo >> "$openstackLogs\systeminfo.log"
wmic qfe list >> "$openstackLogs\windows_hotfixes.log"
pip freeze >> "$openstackLogs\pip_freeze.log"
ipconfig /all >> "$openstackLogs\ipconfig.log"

powershell -executionpolicy remotesigned get-netadapter ^| Select-object * >> "$openstackLogs\get_netadapter.log"
powershell -executionpolicy remotesigned get-vmswitch ^| Select-object * >> "$openstackLogs\get_vmswitch.log"
powershell -executionpolicy remotesigned get-WmiObject win32_logicaldisk ^| Select-object * >> "$openstackLogs\disk_free.log"
powershell -executionpolicy remotesigned get-netfirewallprofile ^| Select-Object * >> "$openstackLogs\firewall.log"
powershell -executionpolicy remotesigned get-process ^| Select-Object * >> "$openstackLogs\get_process.log"
powershell -executionpolicy remotesigned get-service ^| Select-Object * >> "$openstackLogs\get_service.log"

sc qc nova-compute >> "$openstackLogs\nova_compute_service.log"
sc qc neutron-hyperv-agent >> "$openstackLogs\neutron_hyperv_agent_service.log"
