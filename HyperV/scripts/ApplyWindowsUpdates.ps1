$UpdateSession = New-Object -Com Microsoft.Update.Session
$UpdateSearcher = $UpdateSession.CreateUpdateSearcher()

$SearchResult = $UpdateSearcher.Search("IsInstalled=0 and Type='Software'")

Write-Host("List of applicable items on the machine:")
For ($X = 0; $X -lt $SearchResult.Updates.Count; $X++){
    $Update = $SearchResult.Updates.Item($X)
    Write-Host( ($X + 1).ToString() + "&gt; " + $Update.Title)
}
 
If ($SearchResult.Updates.Count -eq 0) {
    Write-Host("There are no applicable updates.")
    Exit 0
}

$UpdatesToDownload = New-Object -Com Microsoft.Update.UpdateColl

For ($X = 0; $X -lt $SearchResult.Updates.Count; $X++){
    $Update = $SearchResult.Updates.Item($X)
    #Write-Host( ($X + 1).ToString() + "&gt; Adding: " + $Update.Title)
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
    Start-Sleep -s 10
    (Get-WMIObject -Class Win32_OperatingSystem).Reboot()
}
