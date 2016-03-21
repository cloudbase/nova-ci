# Loading config

. "C:\OpenStack\nova-ci\HyperV\scripts\config.ps1"

function dumpeventlog($path){
	
	Get-Eventlog -list | ForEach-Object {
		$logFileName = $_.LogDisplayName
		$exportFileName = "\eventlog_" + $logFileName + (get-date -f yyyyMMdd) + ".evt"
		$exportFileName = $exportFileName.replace(" ","_")
		$logFile = Get-WmiObject Win32_NTEventlogFile | Where-Object {$_.logfilename -eq $logFileName}
		$logFile.backupeventlog($path + $exportFileName) -ErrorAction SilentlyContinue
	}
}

function exporteventlog($path){

	Get-Eventlog -list | ForEach-Object {
		$logname = $_.LogDisplayName
		$logfilename = "eventlog_" + $_.LogDisplayName + ".txt"
		$logfilename = $logfilename.replace(" ","_")
		Get-EventLog -Logname $logname | fl | out-file $path\$logfilename -ErrorAction SilentlyContinue
	}
}

function cleareventlog(){
	Get-Eventlog -list | ForEach-Object {
		Clear-Eventlog $_.LogDisplayName -ErrorAction SilentlyContinue
	}
}



$hasEventlogDir = Test-Path -PathType Container $eventlogPath
if (!$hasEventlogDir){
	New-Item -ItemType Directory -Force -Path $eventlogPath
}
else {
	Remove-Item $eventlogPath\* -recurse
}

exporteventlog $eventlogPath
dumpeventlog $eventlogPath
cleareventlog