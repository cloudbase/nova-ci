Param(
    [Parameter(Mandatory=$true)][string]$devstackIP,
    [string]$branchName='master',
    [string]$buildFor='openstack/nova',
    [string]$isDebug='no',
    [string]$zuulChange=''
)

if ($isDebug -eq  'yes') {
    Write-Host "Debug info:"
    Write-Host "devstackIP: $devstackIP"
    Write-Host "branchName: $branchName"
    Write-Host "buildFor: $buildFor"
}
$projectName = $buildFor.split('/')[-1]

$scriptLocation = [System.IO.Path]::GetDirectoryName($myInvocation.MyCommand.Definition)
. "$scriptLocation\config.ps1"
. "$scriptLocation\utils.ps1"

$hasProject = Test-Path $buildDir\$projectName
$hasBuildDir = Test-Path $buildDir
$hasNova = Test-Path $buildDir\nova
$hasNeutron = Test-Path $buildDir\neutron
$hasNeutronTemplate = Test-Path $neutronTemplate
$hasNovaTemplate = Test-Path $novaTemplate
$hasConfigDir = Test-Path $configDir
$hasBinDir = Test-Path $binDir
$hasMkisoFs = Test-Path $binDir\mkisofs.exe
$hasQemuImg = Test-Path $binDir\qemu-img.exe
Add-Type -AssemblyName System.IO.Compression.FileSystem

$pip_conf_content = @"
[global]
index-url = http://10.20.1.8:8080/cloudbase/CI/+simple/
[install]
trusted-host = 10.20.1.8
"@

$ErrorActionPreference = "SilentlyContinue"

# Do a selective teardown
Write-Host "Ensuring nova and neutron services are stopped."
Stop-Service -Name nova-compute -Force
Stop-Service -Name neutron-hyperv-agent -Force

Write-Host "Stopping any possible python processes left."
Stop-Process -Name python -Force

# At the moment, nova may leak planned vms in case of failed live migrations.
# We'll have to clean them up, otherwise spawning instances at the same
# location will fail.
destroy_planned_vms

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

if (-not (Get-Service neutron-hyperv-agent -ErrorAction SilentlyContinue))
{
    Throw "Neutron Hyper-V Agent Service not registered"
}

if (-not (get-service nova-compute -ErrorAction SilentlyContinue))
{
    Throw "Nova Compute Service not registered"
}

if ($(Get-Service nova-compute).Status -ne "Stopped"){
    Throw "Nova service is still running"
}

if ($(Get-Service neutron-hyperv-agent).Status -ne "Stopped"){
    Throw "Neutron service is still running"
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
if ($hasBuildDir -eq $false){
   mkdir $buildDir
}
if ($hasProject -eq $false){
    Get-ChildItem $buildDir
    Get-ChildItem ( Get-Item $buildDir ).Parent.FullName
    Throw "$projectName repository was not found. Please run gerrit-git-prep.sh for this project first"
}

if ($hasBinDir -eq $false){
    mkdir $binDir
}

if (($hasMkisoFs -eq $false) -or ($hasQemuImg -eq $false)){
    Invoke-WebRequest -Uri "http://10.20.1.14:8080/openstack_bin.zip" -OutFile "$bindir\openstack_bin.zip"
    [System.IO.Compression.ZipFile]::ExtractToDirectory("$bindir\openstack_bin.zip", "$bindir")
    Remove-Item -Force "$bindir\openstack_bin.zip"
}

if ($hasNovaTemplate -eq $false){
    Throw "Nova template not found"
}

if ($hasNeutronTemplate -eq $false){
    Throw "Neutron template not found"
}

if ($isDebug -eq  'yes') {
    Write-Host "Status of $buildDir before GitClonePull"
    Get-ChildItem $buildDir
}

git config --global user.email "hyper-v_ci@microsoft.com"
git config --global user.name "Hyper-V CI"


if ($buildFor -eq "openstack/nova"){
    ExecRetry {
        GitClonePull "$buildDir\neutron" "https://git.openstack.org/openstack/neutron.git" $branchName
    }
    Get-ChildItem $buildDir
    ExecRetry {
        GitClonePull "$buildDir\networking-hyperv" "https://git.openstack.org/openstack/networking-hyperv.git" $branchName
    }
    Get-ChildItem $buildDir
    ExecRetry {
        GitClonePull "$buildDir\os-win" "https://git.openstack.org/openstack/os-win.git" $branchName
    }
    Get-ChildItem $buildDir
    ExecRetry {
        GitClonePull "$buildDir\requirements" "https://git.openstack.org/openstack/requirements.git" $branchName
    }
    Get-ChildItem $buildDir
}else{
    Throw "Cannot build for project: $buildFor"
}

$hasLogDir = Test-Path $openstackLogs
if ($hasLogDir -eq $false){
    mkdir $openstackLogs
}

pushd C:\
if (Test-Path $pythonArchive)
{
    Remove-Item -Force $pythonArchive
}
Invoke-WebRequest -Uri http://10.20.1.14:8080/python.zip -OutFile $pythonArchive
if (Test-Path $pythonDir)
{
    Cmd /C "rmdir /S /Q $pythonDir"
    #Remove-Item -Recurse -Force $pythonDir
}
Write-Host "Ensure Python folder is up to date"
Write-Host "Extracting archive.."
[System.IO.Compression.ZipFile]::ExtractToDirectory("C:\$pythonArchive", "C:\")

$hasPipConf = Test-Path "$env:APPDATA\pip"
if ($hasPipConf -eq $false){
    mkdir "$env:APPDATA\pip"
}
else 
{
    Remove-Item -Force "$env:APPDATA\pip\*"
}
Add-Content "$env:APPDATA\pip\pip.ini" $pip_conf_content

$ErrorActionPreference = "Continue"
& easy_install -U pip
& pip install setuptools==26.0.0
& pip install pymi
& pip install cffi
& pip install numpy
& pip install pycrypto
& pip install amqp==1.4.9
& pip install cffi==1.6.0
$ErrorActionPreference = "Stop"

popd

$hasPipConf = Test-Path "$env:APPDATA\pip"
if ($hasPipConf -eq $false){
    mkdir "$env:APPDATA\pip"
}
else 
{
    Remove-Item -Force "$env:APPDATA\pip\*"
}
Add-Content "$env:APPDATA\pip\pip.ini" $pip_conf_content

cp $templateDir\distutils.cfg "$pythonDir\Lib\distutils\distutils.cfg"

function cherry_pick($commit) {
    $eapSet = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    git cherry-pick $commit

    if ($LastExitCode) {
        echo "Ignoring failed git cherry-pick $commit"
        git checkout --force
    }
    $ErrorActionPreference = $eapSet
}

if ($isDebug -eq  'yes') {
    Write-Host "BuildDir is: $buildDir"
    Write-Host "ProjectName is: $projectName"
    Write-Host "Listing $buildDir parent directory:"
    Get-ChildItem ( Get-Item $buildDir ).Parent.FullName
    Write-Host "Listing $buildDir before install"
    Get-ChildItem $buildDir
}

ExecRetry {
    pushd "$buildDir\requirements"
    Write-Host "Installing OpenStack/Requirements..."
    & pip install -c upper-constraints.txt -U pbr virtualenv httplib2 prettytable>=0.7 setuptools
    & pip install -c upper-constraints.txt -U .
    if ($LastExitCode) { Throw "Failed to install openstack/requirements from repo" }
    popd
}

ExecRetry {
    if ($isDebug -eq  'yes') {
        Write-Host "Content of $buildDir\neutron"
        Get-ChildItem $buildDir\neutron
    }
    pushd $buildDir\neutron
    Write-Host "Installing openstack/neutron..."
    & update-requirements.exe --source $buildDir\requirements .
    & pip install -c $buildDir\requirements\upper-constraints.txt -U .
    if ($LastExitCode) { Throw "Failed to install neutron from repo" }
    popd
}

ExecRetry {
    if ($isDebug -eq  'yes') {
        Write-Host "Content of $buildDir\networking-hyperv"
        Get-ChildItem $buildDir\networking-hyperv
    }
    pushd $buildDir\networking-hyperv
    Write-Host "Installing openstack/networking-hyperv..."
    & update-requirements.exe --source $buildDir\requirements .
    if (($branchName -eq 'stable/liberty') -or ($branchName -eq 'stable/mitaka')) {
        & pip install -c $buildDir\requirements\upper-constraints.txt -U .
    } else {
        & pip install -e $buildDir\networking-hyperv
    }
    if ($LastExitCode) { Throw "Failed to install networking-hyperv from repo" }
    popd
}

ExecRetry {
    pushd "$buildDir\os-win"
    Write-Host "Installing OpenStack/os-win..."

    git fetch git://git.openstack.org/openstack/os-win refs/changes/67/421867/1
    git cherry-pick FETCH_HEAD

    & pip install -U .
    if ($LastExitCode) { Throw "Failed to install openstack/os-win from repo" }
    popd
}

if ($zuulChange -eq '273504') {
    ExecRetry {
        GitClonePull "$buildDir\os-brick" "https://git.openstack.org/openstack/os-brick.git" $branchName

        pushd $buildDir\os-brick

        & pip install $buildDir\os-brick
        popd
    }
}

ExecRetry {
    if ($isDebug -eq  'yes') {
        Write-Host "Content of $buildDir\nova"
        Get-ChildItem $buildDir\nova
    }
    pushd $buildDir\nova

    Write-Host "Installing openstack/nova..."
    & update-requirements.exe --source $buildDir\requirements .

    & pip install -c $buildDir\requirements\upper-constraints.txt -U .
    if ($LastExitCode) { Throw "Failed to install nova fom repo" }
    popd
}

# Note: be careful as WMI queries may return only one element, in which case we
# won't get an array. To make it easier, we can just make sure we always have an
# array.
$cpu_array = ([array](gwmi -class Win32_Processor))
$cores_count = $cpu_array.count * $cpu_array[0].NumberOfCores
$novaConfig = (gc "$templateDir\nova.conf").replace('[DEVSTACK_IP]', "$devstackIP").Replace('[LOGDIR]', "$openstackLogs").Replace('[RABBITUSER]', $rabbitUser)
$neutronConfig = (gc "$templateDir\neutron_hyperv_agent.conf").replace('[DEVSTACK_IP]', "$devstackIP").Replace('[LOGDIR]', "$openstackLogs").Replace('[RABBITUSER]', $rabbitUser).replace('[CORES_COUNT]', "$cores_count")

if (($branchName -ne 'stable/liberty') -and ($branchName -ne 'stable/mitaka')) {
    $novaConfig = $novaConfig.replace('network_api_class', '#network_api_class')
}

Set-Content $configDir\nova.conf $novaConfig
if ($? -eq $false){
    Throw "Error writting $configDir\nova.conf"
}

Set-Content $configDir\neutron_hyperv_agent.conf $neutronConfig
if ($? -eq $false){
    Throw "Error writting $configDir\neutron_hyperv_agent.conf"
}

cp "$templateDir\policy.json" "$configDir\"
cp "$templateDir\interfaces.template" "$configDir\"

$hasNovaExec = Test-Path "$pythonScripts\nova-compute.exe"
if ($hasNovaExec -eq $false){
    Throw "No nova-compute.exe found"
}

$hasNeutronExec = Test-Path "$pythonScripts\neutron-hyperv-agent.exe"
if ($hasNeutronExec -eq $false){
    Throw "No neutron-hyperv-agent.exe found"
}


#Remove-Item -Recurse -Force "$remoteConfigs\$hostname\*"
#Copy-Item -Recurse $configDir "$remoteConfigs\$hostname"

Write-Host "Starting the services"

$currDate = (Get-Date).ToString()
Write-Host "$currDate Starting nova-compute service"
Try
{
    Start-Service nova-compute
}
Catch
{
    Write-Host "Can not start the nova-compute service."
}
Start-Sleep -s 30
if ($(get-service nova-compute).Status -eq "Stopped")
{
    Write-Host "nova-compute service is not running."
    $currDate = (Get-Date).ToString()
    Write-Host "$currDate We try to start:"
    Write-Host Start-Process -PassThru -RedirectStandardError "$openstackLogs\process_error.txt" -RedirectStandardOutput "$openstackLogs\process_output.txt" -FilePath "$pythonDir\Scripts\nova-compute.exe" -ArgumentList "--config-file $configDir\nova.conf"
    $currDate = (Get-Date).ToString()
    Add-Content "$openstackLogs\nova-compute.log" "`n$currDate Starting nova-compute as a python process."
    Try
    {
    	$proc = Start-Process -PassThru -RedirectStandardError "$openstackLogs\process_error.txt" -RedirectStandardOutput "$openstackLogs\process_output.txt" -FilePath "$pythonDir\Scripts\nova-compute.exe" -ArgumentList "--config-file $configDir\nova.conf"
    }
    Catch
    {
    	Throw "Could not start the process manually"
    }
    Start-Sleep -s 30
    if (! $proc.HasExited)
    {
    	Stop-Process -Id $proc.Id -Force
    	Throw "Process started fine when run manually."
    }
    else
    {
    	Throw "Can not start the nova-compute service. The manual run failed as well."
    }
}

$currDate = (Get-Date).ToString()
Write-Host "$currDate Starting neutron-hyperv-agent service"
Try
{
    Start-Service neutron-hyperv-agent
}
Catch
{
    Write-Host "Can not start the neutron-hyperv-agent service."
}
Start-Sleep -s 30
if ($(get-service neutron-hyperv-agent).Status -eq "Stopped")
{
    Write-Host "neutron-hyperv-agent service is not running."
    $currDate = (Get-Date).ToString()
    Write-Host "$currDate We try to start:"
     Write-Host Start-Process -PassThru -RedirectStandardError "$openstackLogs\process_error.txt" -RedirectStandardOutput "$openstackLogs\process_output.txt" -FilePath "$pythonScripts\neutron-hyperv-agent.exe" -ArgumentList "--config-file $configDir\neutron_hyperv_agent.conf"
    $currDate = (Get-Date).ToString()
    Add-Content "$openstackLogs\neutron-hyperv-agent.log" "`n$currDate starting neutron-hyperv-agent as a python process."
    Try
    {
    	$proc = Start-Process -PassThru -RedirectStandardError "$openstackLogs\process_error.txt" -RedirectStandardOutput "$openstackLogs\process_output.txt" -FilePath "$pythonScripts\neutron-hyperv-agent.exe" -ArgumentList "--config-file $configDir\neutron_hyperv_agent.conf"
    }
    Catch
    {
    	Throw "Could not start the process manually"
    }
    Start-Sleep -s 30
    if (! $proc.HasExited)
    {
    	Stop-Process -Id $proc.Id -Force
    	Throw "Process started fine when run manually."
    }
    else
    {
    	Throw "Can not start the neutron-hyperv-agent service. The manual run failed as well."
    }
}
