$UpdateSession = New-Object -Com Microsoft.Update.Session
$UpdateSearcher = $UpdateSession.CreateUpdateSearcher()
$SearchResult = $UpdateSearcher.Search("IsInstalled=0 and Type='Software'")
$MyDir = [System.IO.Path]::GetDirectoryName($myInvocation.MyCommand.Definition)

$script_location="$MyDir\ApplyWindowsUpdates.ps1"
$log_file="$MyDir\ApplyWindowsUpdates.log"
$jenkins_labels = "hv-icehouse", "manila"

If ($SearchResult.Updates.Count -eq 0) {
    Write-Host("There are no applicable updates.")
    $updates=$False
}
else {
    Write-Host("Updates available")
    $updates=$True
}

$jenkins_config_location="C:\ProgramData\jenkins-slave\jenkinsslave.xml"
$process_exists=(get-process "jenkinsslave" -ErrorAction SilentlyContinue )
$config_present=(test-path $jenkins_config_location)
if ( $config_present -eq $True -and $process_exists -ne $NULL) {
    write-host("Jenkins running and config file found")
    $jenkins=$True
    }
elseif ( $process_exists -ne $NULL ){
    write-host("Jenkins running, but config file not found")
    $jenkins=$True
   }
elseif ( $config_present -ne 0){
    write-host("Jenkins config file found, but the process doesnt exists")
    $jenkins=$True
   }
else {
    write-host("Neither jenkins process was running nor jenkins config was found")
    $jenkins=$False
}

function go_update {

    Write-Host("List of applicable items on the machine:")
    For ($X = 0; $X -lt $SearchResult.Updates.Count; $X++){
        $Update = $SearchResult.Updates.Item($X)
        Write-Host( ($X + 1).ToString() + "&gt; " + $Update.Title)
    }

    $UpdatesToDownload = New-Object -Com Microsoft.Update.UpdateColl

    For ($X = 0; $X -lt $SearchResult.Updates.Count; $X++){
        $Update = $SearchResult.Updates.Item($X)
        Write-Host( ($X + 1).ToString() + "&gt; Adding: " + $Update.Title)
        $Null = $UpdatesToDownload.Add($Update)
    }


    Write-Host("Downloading Updates...")

    $Downloader = $UpdateSession.CreateUpdateDownloader()
    $Downloader.Updates = $UpdatesToDownload
    $Null = $Downloader.Download()

    $UpdatesToInstall = New-Object -Com Microsoft.Update.UpdateColl

    For ($X = 0; $X -lt $SearchResult.Updates.Count; $X++){
        $Update = $SearchResult.Updates.Item($X)
        If ($Update.IsDownloaded) {
            Write-Host( ($X + 1).ToString() + "&gt; " + $Update.Title)
            $Null = $UpdatesToInstall.Add($Update)
        }
    }

    Write-Host("Installing Updates...")
    $Installer = $UpdateSession.CreateUpdateInstaller()
    $Installer.Updates = $UpdatesToInstall

    $InstallationResult = $Installer.Install()

    For ($X = 0; $X -lt $UpdatesToInstall.Count; $X++){
        Write-Host($UpdatesToInstall.Item($X).Title + ": " + $InstallationResult.GetUpdateResult($X).ResultCode)
    }

    Write-Host("Installation Result: " + $InstallationResult.ResultCode)
    Write-Host("    Reboot Required: " + $InstallationResult.RebootRequired)
    If ($InstallationResult.RebootRequired -eq $True){
        $system=Get-WMIObject -Class Win32_OperatingSystem
        $system.Scope.Options.EnablePrivileges=$True
        $system.Reboot()
        echo "RebootRequired" >> $log_file
    }
    else {
        powershell.exe -executionpolicy unrestricted -file $script_location
        echo "Calling script again" >> $log_file
    }
}

if ($jenkins -and $updates) {
    echo "Updates available and jenkins present" >> $log_file
    net stop jenkinsslave
    if (-not (test-path "$jenkins_config_location.bk")){
        Copy-Item $jenkins_config_location "$jenkins_config_location.bk"
    }
    Foreach($label in $jenkins_labels){
        (Get-Content $jenkins_config_location) | Foreach-Object {$_ -replace "`"$label`"", "`"updates-in-progress`""} | Set-Content $jenkins_config_location
    }
    net start jenkinsslave
    schtasks /create /f /tn "Auto-Updates" /tr "powershell.exe -executionpolicy unrestricted -file $script_location" /sc onstart /ru system
    go_update
}
elseif ($jenkins -and -not ($updates)){
    echo "Updates not available, jenkins present" >> $log_file
    net stop jenkinsslave
    Copy-Item "$jenkins_config_location.bk" $jenkins_config_location
    Remove-Item "$jenkins_config_location.bk"
    net start jenkinsslave
    schtasks /delete /f /tn "Auto-Updates"
}
elseif (-not($jenkins) -and $updates){
    echo "Updates available, jenkins not present" >> $log_file
    schtasks /create /f /tn "Auto-Updates" /tr "powershell.exe -executionpolicy unrestricted -file $script_location" /sc onstart /ru system
    go_update
}
elseif ( -not ($jenkins -and $updates) ) {
    echo "Done updating" >> $log_file
    schtasks /delete /f /tn "Auto-Updates"
}
