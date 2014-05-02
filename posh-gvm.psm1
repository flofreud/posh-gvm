<#
posh-gvm / POwerSHell Groovy enVironment Manager

Equal to GVM:
- command interface
- use same API to get binaries

Different to GVM:
- different directory ~\.posh-gvm instead of ~\.gvm
- command extension are not supported

Needed:
- Powershell 3.0 (For Windows 7 install Windows Management Framework 3.0)
#>

#region Config
$Global:PGVM_DIR = "$env:USERPROFILE\.posh_gvm"
$Global:PGVM_AUTO_ANSWER = $false
$Global:PGVM_AUTO_SELFUPDATE = $true

$Script:PGVM_INIT = $false
$Script:PGVM_SERVICE = 'http://api.gvmtool.net'
$Script:PGVM_VERSION = '1.3.13'

$Script:PGVM_CANDIDATES_PATH = "$Global:PGVM_DIR\.meta\candidates.txt"
$Script:PGVM_BROADCAST_PATH = "$Global:PGVM_DIR\.meta\broadcast.txt"
$Script:PGVM_VERSION_PATH = "$Global:PGVM_DIR\.meta\version.txt"
$Script:PGVM_ARCHIVES_PATH = "$Global:PGVM_DIR\.meta\archives"
$Script:PGVM_TEMP_PATH = "$Global:PGVM_DIR\.meta\tmp"

$Script:GVM_AVAILABLE = $true
$Script:GVM_ONLINE = $true
$Script:GVM_FORCE_OFFLINE = $false
$Script:GVM_CANDIDATES = $null

$ErrorActionPreference = "Stop"
#endregion

Push-Location $psScriptRoot
. .\Utils.ps1
. .\Commands.ps1
. .\Init.ps1
. .\TabExpansion.ps1
Pop-Location 

Init-Posh-Gvm

Export-ModuleMember 'gvm'