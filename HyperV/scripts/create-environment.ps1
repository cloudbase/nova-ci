# Loading config

. "C:\OpenStack\HyperV\scripts\config.ps1"
. "C:\OpenStack\HyperV\scripts\utils.ps1"

# end Loading config

Param(
    [Parameter(Mandatory=$true)][string]$devstackIP,
    [string]$branchName='master',
    [string]$buildFor='openstack/nova'
)

function FixExecScript([String] $ExecScriptPath)
{
    ############################################################################
    # temporary fix for pbr bug: https://review.openstack.org/#/c/151595/      #
    ############################################################################
    $ExecScript = (gc "$ExecScriptPath").Replace("#!c:OpenStackvirtualenvScriptspython.exe","#!c:\OpenStack\virtualenv\Scripts\python.exe")
    Set-Content $ExecScriptPath $ExecScript
}

############################################################################
#  virtualenv and pip install must be run via cmd. There is a bug in the   #
#  activate.ps1 that actually installs packages in the system site package #
#  folder                                                                  #
############################################################################

$projectName = $buildFor.split('/')[-1]

$hasProject = Test-Path $buildDir\$projectName
$hasVirtualenv = Test-Path $virtualenv
$hasNova = Test-Path $buildDir\nova
$hasNeutron = Test-Path $buildDir\neutron
$hasNeutronTemplate = Test-Path $neutronTemplate
$hasNovaTemplate = Test-Path $novaTemplate
$hasConfigDir = Test-Path $configDir
$hasBinDir = Test-Path $binDir
$hasMkisoFs = Test-Path $binDir\mkisofs.exe
$hasQemuImg = Test-Path $binDir\qemu-img.exe

$ErrorActionPreference = "SilentlyContinue"

$ErrorActionPreference = "SilentlyContinue"

# Do a selective teardown
Write-Host "Ensuring nova and neutron services are stopped."
Stop-Service -Name nova-compute -Force
Stop-Service -Name neutron-hyperv-agent -Force

Write-Host "Stopping any possible python processes left."
Stop-Process -Name python -Force

if (Get-Process -Name nova-compute){
    Throw "Nova is still running on this host"
}

if (Get-Process -Name neutron-hyperv-agent){
    Throw "Neutron is still running on this host"
}

if (Get-Process -Name python){
    Throw "Python processes still running on this host"
}

$ErrorActionPreference = "Stop"

if ($(Get-Service nova-compute).Status -ne "Stopped"){
    Throw "Nova service is still running"
}

if ($(Get-Service neutron-hyperv-agent).Status -ne "Stopped"){
    Throw "Neutron service is still running"
}

Write-Host "Removing any stale virtenv folder."
if ($hasVirtualenv -eq $true){
    Try
    {
        Remove-Item -Recurse -Force $virtualenv
        $hasVirtualenv = Test-Path $virtualenv
    }
    Catch
    {
        Throw "Vrtualenv already exists. Environment not clean."
    }
}

Write-Host "Cleaning up the config folder."
if ($hasConfigDir -eq $false) {
    mkdir $configDir
}else{
    Try
    {
        Remove-Item -Recurse -Force $configDir\*
    }
    Catch
    {
        Throw "Can not clean the config folder"
    }
}

if ($hasProject -eq $false){
    Throw "$projectName repository was not found. Please run gerrit-git-pref for this project first"
}

if ($hasBinDir -eq $false){
    mkdir $binDir
}

if (($hasMkisoFs -eq $false) -or ($hasQemuImg -eq $false)){
    Invoke-WebRequest -Uri "http://dl.openstack.tld/openstack_bin.zip" -OutFile "$bindir\openstack_bin.zip"
    if (Test-Path "C:\Program Files\7-Zip\7z.exe"){
        pushd $bindir
        & "C:\Program Files\7-Zip\7z.exe" x -y "$bindir\openstack_bin.zip"
        Remove-Item -Force "$bindir\openstack_bin.zip"
        popd
    } else {
        Throw "Required binary files (mkisofs, qemuimg etc.)  are missing"
    }
}

if ($hasVirtualenv -eq $true){
    Throw "Vrtualenv already exists. Environment not clean."
}

if ($hasNovaTemplate -eq $false){
    Throw "Nova template not found"
}

if ($hasNeutronTemplate -eq $false){
    Throw "Neutron template not found"
}

git config --global user.email "hyper-v_ci@microsoft.com"
git config --global user.name "Hyper-V CI"


if ($buildFor -eq "openstack/nova"){
    ExecRetry {
        GitClonePull "$buildDir\neutron" "https://github.com/openstack/neutron.git" $branchName
    }
    ExecRetry {
        GitClonePull "$buildDir\networking-hyperv" "https://github.com/stackforge/networking-hyperv.git" "master"
    }
}elseif ($buildFor -eq "openstack/neutron" -or $buildFor -eq "openstack/quantum"){
    ExecRetry {
        GitClonePull "$buildDir\nova" "https://github.com/openstack/nova.git" $branchName
    }
    ExecRetry {
        GitClonePull "$buildDir\networking-hyperv" "https://github.com/stackforge/networking-hyperv.git" "master"
    }
}elseif ($buildFor -eq "stackforge/networking-hyperv"){
    ExecRetry {
        GitClonePull "$buildDir\nova" "https://github.com/openstack/nova.git" $branchName
    }
    ExecRetry {
        GitClonePull "$buildDir\neutron" "https://github.com/openstack/neutron.git" $branchName
    }
}else{
    Throw "Cannot build for project: $buildFor"
}

$hasLogDir = Test-Path $remoteLogs\$hostname
if ($hasLogDir -eq $false){
    mkdir $remoteLogs\$hostname
}

$hasConfigDir = Test-Path $remoteConfigs\$hostname
if ($hasConfigDir -eq $false){
    mkdir $remoteConfigs\$hostname
}

cmd.exe /C virtualenv --system-site-packages $virtualenv

if ($? -eq $false){
    Throw "Failed to create virtualenv"
}

cp $templateDir\distutils.cfg $virtualenv\Lib\distutils\distutils.cfg

# Hack due to cicso patch problem:
$missingPath="C:\Openstack\build\openstack\neutron\etc\neutron\plugins\cisco\cisco_cfg_agent.ini"
if(!(Test-Path -Path $missingPath)){
    new-item -Path $missingPath -Value ' ' –itemtype file
}

#FixExecScript "$virtualenv\Scripts\nova-compute-script.py"
#FixExecScript "$virtualenv\Scripts\neutron-hyperv-agent-script.py"

ExecRetry {
    cmd.exe /C $scriptdir\install_openstack_from_repo.bat $buildDir\networking-hyperv
    if ($LastExitCode) { Throw "Failed to install networking-hyperv from repo" }
}

ExecRetry {
    cmd.exe /C $scriptdir\install_openstack_from_repo.bat $buildDir\neutron
    if ($LastExitCode) { Throw "Failed to install neutron from repo" }
}

ExecRetry {
    cmd.exe /C $scriptdir\install_openstack_from_repo.bat $buildDir\nova
    if ($LastExitCode) { Throw "Failed to install nova fom repo" }
}

if (($branchName.ToLower().CompareTo($('stable/juno').ToLower()) -eq 0) -or ($branchName.ToLower().CompareTo($('stable/icehouse').ToLower()) -eq 0)) {
    $rabbitUser = "guest"
}

$novaConfig = (gc "$templateDir\nova.conf").replace('[DEVSTACK_IP]', "$devstackIP").Replace('[LOGDIR]', "$($remoteLogs)\$($hostname)").Replace('[RABBITUSER]', $rabbitUser)
$neutronConfig = (gc "$templateDir\neutron_hyperv_agent.conf").replace('[DEVSTACK_IP]', "$devstackIP").Replace('[LOGDIR]', "$($remoteLogs)\$($hostname)").Replace('[RABBITUSER]', $rabbitUser)

Set-Content C:\OpenStack\etc\nova.conf $novaConfig
if ($? -eq $false){
    Throw "Error writting $templateDir\nova.conf"
}

Set-Content C:\OpenStack\etc\neutron_hyperv_agent.conf $neutronConfig
if ($? -eq $false){
    Throw "Error writting neutron_hyperv_agent.conf"
}

cp "$templateDir\policy.json" "$configDir\"
cp "$buildDir\interfaces.template" "$configDir\"

$hasNovaExec = Test-Path c:\OpenStack\virtualenv\Scripts\nova-compute.exe
if ($hasNovaExec -eq $false){
    Throw "No nova exe found"
}else{
    $novaExec = "$virtualenv\Scripts\nova-compute.exe"
}

FixExecScript "$virtualenv\Scripts\nova-compute-script.py"

$hasNeutronExec = Test-Path "$virtualenv\Scripts\neutron-hyperv-agent.exe"
if ($hasNeutronExec -eq $false){
    Throw "No neutron exe found"
}else{
    $neutronExe = "$virtualenv\Scripts\neutron-hyperv-agent.exe"
}

FixExecScript "$virtualenv\Scripts\neutron-hyperv-agent-script.py"

Remove-Item -Recurse -Force "$remoteConfigs\$hostname\*"
Copy-Item -Recurse $configDir "$remoteConfigs\$hostname"

Write-Host "Starting the services"
Try
{
    Start-Service nova-compute
}
Catch
{
    Throw "Can not start the nova service"
}
Start-Sleep -s 15
Try
{
    Start-Service neutron-hyperv-agent
}
Catch
{
    Throw "Can not start neutron agent service"
}
Write-Host "Environment initialization done."
