# Loading config and utils

$scriptLocation = [System.IO.Path]::GetDirectoryName($myInvocation.MyCommand.Definition)
 . "$scriptLocation\config.ps1"
 . "$scriptLocation\utils.ps1"


if (Test-Path $eventlogPath){
	Remove-Item $eventlogPath -recurse -force
}

New-Item -ItemType Directory -Force -Path $eventlogPath

dumpeventlog $eventlogPath
exporthtmleventlog $eventlogPath

