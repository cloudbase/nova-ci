
$UpdateSession = New-Object -Com Microsoft.Update.Session
$UpdateSearcher = $UpdateSession.CreateUpdateSearcher()
$SearchResult = $UpdateSearcher.Search("IsInstalled=0 and Type='Software'")

If ($SearchResult.Updates.Count -eq 0) {
    Write-Host("There are no applicable updates.")
    $updates=$False
}
else {
    Write-Host("Updates available")
    $updates=$True
}

$jenkins_config="C:\ProgramData\jenkins-slave\jenkinsslave.xml"
$process=(get-process "vmtoolsd" -ErrorAction SilentlyContinue )
$config=(test-path $jenkins_config)
if ( $config -eq $True -and $process -ne $NULL) {
    write-host("Jenkins running and config file found")
    $jenkins=$True
    }
elseif ( $process -ne $NULL ){
    write-host("Jenkins running, but config file not found")
    $jenkins=$True
   }
elseif ( $config -ne 0){
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
}

If ($InstallationResult.RebootRequired -eq $True){
    Start-Sleep -s 10
    (Get-WMIObject -Class Win32_OperatingSystem).Reboot()
}
if ($jenkins -and $updates) {
    echo "jenkins and updates"
    #copy jenkins config file
    #set jenkins label to temporary and restart jenkins
    #enable schtask
    schtasks /create /f /tn "Auto-Updates" /tr "powershell.exe -executionpolicy unrestricted -file C:\auto-updates.ps1" /sc onstart /ru system
    go_update
}
elseif ($jenkins -and -not ($updates)){
    #revert jenkins config file to original and restart jenkins
    #disable schtask
    schtasks /delete /f /tn "Auto-Updates"
}
elseif (-not($jenkins) -and $updates){
    #enable schtask
    schtasks /create /f /tn "Auto-Updates" /tr "powershell.exe -executionpolicy unrestricted -file C:\auto-updates.ps1" /sc onstart /ru system
    go_update
}
elseif ( -not ($jenkins -and $updates) ) {
    echo "Done updating"
    #disable schtask
    schtasks /delete /f /tn "Auto-Updates"
}

