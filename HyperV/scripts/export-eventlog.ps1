# Loading config

. "C:\OpenStack\nova-ci\HyperV\scripts\config.ps1"

function dumpeventlog($path){
	
	Get-Eventlog -list | ForEach-Object {
		$logFileName = $_.LogDisplayName
		$exportFileName =$path + "\eventlog_" + $logFileName + (get-date -f yyyyMMdd) + ".evt"
		$exportFileName = $exportFileName.replace(" ","_")
		$logFile = Get-WmiObject Win32_NTEventlogFile | Where-Object {$_.logfilename -eq $logFileName}
		try{
			$logFile.backupeventlog($exportFileName)
		} catch {
			Write-Host "Could not dump $_.LogDisplayName (it might not exist)."
		}
	}
}

function exporteventlog($path){

	Get-Eventlog -list | ForEach-Object {
		$logfilename = "eventlog_" + $_.LogDisplayName + ".txt"
		$logfilename = $logfilename.replace(" ","_")
		Get-EventLog -Logname $_.LogDisplayName | fl | out-file $path\$logfilename -ErrorAction SilentlyContinue
	}
}

function cleareventlog(){
	Get-Eventlog -list | ForEach-Object {
		Clear-Eventlog $_.LogDisplayName -ErrorAction SilentlyContinue
	}
}




if (Test-Path $eventlogPath){
	Remove-Item $eventlogPath -recurse -force
}

New-Item -ItemType Directory -Force -Path $eventlogPath

exporteventlog $eventlogPath
dumpeventlog $eventlogPath
cleareventlog
