<#
	Paragon for the installation script is PsGet
#>
$poshGvmZipUrl = 'https://github.com/flofreud/posh-gvm/archive/master.zip'

$modulePaths = @($Env:PSModulePath -split ';')
# set module path to posh default
$targetModulePath = Join-Path -Path ([Environment]::GetFolderPath('MyDocuments')) -ChildPath WindowsPowerShell\Modules
# if its not use select the first defined
if ( $modulePaths -inotcontains $targetModulePath  ) {
	$targetModulePath = $modulePaths | Select-Object -Index 0
}

$poshGvmPath = "$targetModulePath\posh-gvm"

try {
    # create temp dir
    $tempDir = [guid]::NewGuid().ToString()
    $tempDir = "$env:TEMP\$tempDir"
    New-Item -ItemType Directory $tempDir | Out-Null

    # download current version
    $poshGvmZip = "$tempDir\posh-gvm-master.zip"
    Write-Host "Downloading posh-gvm from $poshGvmZipUrl"
    $client = (New-Object Net.WebClient)
    $client.Proxy.Credentials = [System.Net.CredentialCache]::DefaultNetworkCredentials
    $client.DownloadFile($poshGvmZipUrl, $poshGvmZip)

    # unzip archive
    $shell = New-Object -com shell.application
    $shell.namespace($tempDir).copyhere($shell.namespace($poshGvmZip).items(), 0x14)


    # check if unzip successfully
    if ( Test-Path "$tempDir\posh-gvm-master" ) {
        # remove old posh-gvm
        if ( !(Test-Path $poshGvmPath) ) {
           New-Item -ItemType Directory $poshGvmPath | Out-Null
        }

        Copy-Item "$tempDir\posh-gvm-master\*" $poshGvmPath -Force -Recurse
        Write-Host "posh-gvm installed!"
        Write-Host "Please see https://github.com/flofreud/posh-gvm#usage for details to get startet."
    } else {
        Write-Warning 'Could not unzip archive containing posh-gvm. Most likely the archive is currupt. Please try to install again.'
    }
} finally {
    # clear temp dir
    Remove-Item -Recurse -Force $tempDir
}