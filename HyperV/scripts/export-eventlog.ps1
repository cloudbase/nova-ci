function dumpeventlog(){

	get-eventlog -list | ForEach-Object {
		$logFileName = $_.LogDisplayName
		$path = "C:\OpenStack\Logs\Eventlog\"
		$exportFileName = "eventlog_" + $logFileName + (get-date -f yyyyMMdd) + ".evt"
		$logFile = Get-WmiObject Win32_NTEventlogFile | Where-Object {$_.logfilename -eq $logFileName}
		$logFile.backupeventlog($path + $exportFileName)
	}

}

function exporteventlog(){
	$path = "C:\OpenStack\Logs\Eventlog"
	mkdir $path
	rm $path\*
	get-eventlog -list | ForEach-Object {
		$logname = $_.LogDisplayName
		$logfilename = "eventlog_" + $_.LogDisplayName + ".txt"
		Get-EventLog -Logname $logname | fl | out-file $path\$logfilename
	}
}
exporteventlog
dumpeventlog