# Loading config

. "C:\OpenStack\nova-ci\HyperV\scripts\config.ps1"



function dumpeventlog($path){
	
	Get-Eventlog -list | Where-Object { $_.Entries -ne '0' } | ForEach-Object {
		$logFileName = $_.LogDisplayName
		$exportFileName =$path + "\eventlog_" + $logFileName + ".evt"
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

	Get-Eventlog -list | Where-Object { $_.Entries -ne '0' } | ForEach-Object {
		$logfilename = "eventlog_" + $_.LogDisplayName + ".txt"
		$logfilename = $logfilename.replace(" ","_")
		Get-EventLog -Logname $_.LogDisplayName | fl | out-file $path\$logfilename -ErrorAction SilentlyContinue
	}
}

function exporthtmleventlog($path){
	$css = Get-Content $eventlogcsspath -Raw
	$js = Get-Content $eventlogjspath -Raw
	$HTMLHeader = @"
	<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
	<script type="text/javascript">$js</script>
	<style type="text/css">$css</style>
	"@

	foreach ($i in (Get-EventLog -List | Where-Object { $_.Entries -ne '0' }).Log) {
		$Report = Get-EventLog $i
		$Report = $Report | ConvertTo-Html -Title "${i}" -Head $HTMLHeader -As Table
		$Report = $Report | ForEach-Object {$_ -replace "<body>", '<body id="body">'}
		$Report = $Report | ForEach-Object {$_ -replace "<table>", '<table class="sortable" id="table" cellspacing="0">'}
		$logName = $i  + ".html"
		$logName = $logName.replace(" ","_")
		$bkup = Join-Path $path $logName
		$Report = $Report | Set-Content $bkup
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

#exporteventlog $eventlogPath
dumpeventlog $eventlogPath
exporthtmleventlog $eventlogPath
cleareventlog
