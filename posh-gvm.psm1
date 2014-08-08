<#
posh-gvm / POwerSHell Groovy enVironment Manager

https://github.com/flofreud/posh-gvm

Needed:
- Powershell 3.0 (For Windows 7 install Windows Management Framework 3.0)
#>

#region Config
if ( !(Test-Path Variable:Global:PGVM_DIR) ) {
	$Global:PGVM_DIR = "$env:USERPROFILE\.posh_gvm"
}
if ( !(Test-Path Variable:Global:PGVM_AUTO_ANSWER) ) {
	$Global:PGVM_AUTO_ANSWER = $false
}
if ( !(Test-Path Variable:Global:PGVM_AUTO_SELFUPDATE) ) {
	$Global:PGVM_AUTO_SELFUPDATE = $false
}

$Script:PGVM_INIT = $false
$Script:PGVM_SERVICE = 'http://api.gvmtool.net'
$Script:PGVM_BROADCAST_SERVICE = 'http://cast.gvm.io'
$Script:GVM_BASE_VERSION = '1.3.13'

$Script:PGVM_CANDIDATES_PATH = "$Global:PGVM_DIR\.meta\candidates.txt"
$Script:PGVM_BROADCAST_PATH = "$Global:PGVM_DIR\.meta\broadcast.txt"
$Script:GVM_API_VERSION_PATH = "$Global:PGVM_DIR\.meta\version.txt"
$Script:PGVM_ARCHIVES_PATH = "$Global:PGVM_DIR\.meta\archives"
$Script:PGVM_TEMP_PATH = "$Global:PGVM_DIR\.meta\tmp"

$Script:GVM_API_NEW_VERSION = $false
$Script:PGVM_NEW_VERSION = $false
$Script:PGVM_VERSION_PATH = "$psScriptRoot\VERSION.txt"
$Script:PGVM_VERSION_SERVICE = "https://raw.githubusercontent.com/flofreud/posh-gvm/master/VERSION.txt"

$Script:GVM_AVAILABLE = $true
$Script:GVM_ONLINE = $true
$Script:GVM_FORCE_OFFLINE = $false
$Script:GVM_CANDIDATES = $null
$Script:FIRST_RUN = $true

$Script:UNZIP_ON_PATH = $false
#endregion

Push-Location $psScriptRoot
. .\Utils.ps1
. .\Commands.ps1
. .\Init.ps1
. .\TabExpansion.ps1
Pop-Location

Init-Posh-Gvm

Export-ModuleMember 'gvm'