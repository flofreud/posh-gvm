<#
	Paragon for the installation script is PsGet
#>

function Install-Posh-Gvm() {
    $poshGvmZipUrl = 'https://github.com/flofreud/posh-gvm/archive/master.zip'

    $poshGvmPath = Find-Module-Location

    try {
        # create temp dir
        $tempDir = [guid]::NewGuid().ToString()
        $tempDir = "$env:TEMP\$tempDir"
        New-Item -ItemType Directory $tempDir | Out-Null

        # download current version
        $poshGvmZip = "$tempDir\posh-gvm-master.zip"
        Write-Output "Downloading posh-gvm from $poshGvmZipUrl"

        $client = (New-Object Net.WebClient)
        $client.Proxy.Credentials = [System.Net.CredentialCache]::DefaultNetworkCredentials
        $client.DownloadFile($poshGvmZipUrl, $poshGvmZip)

        # unzip archive
        $shell = New-Object -com shell.application
        $shell.namespace($tempDir).copyhere($shell.namespace($poshGvmZip).items(), 0x14)

        # check if unzip successfully
        if ( Test-Path "$tempDir\posh-gvm-master" ) {
            if ( !(Test-Path $poshGvmPath) ) {
               New-Item -ItemType Directory $poshGvmPath | Out-Null
            }

            Copy-Item "$tempDir\posh-gvm-master\*" $poshGvmPath -Force -Recurse
            Write-Output "posh-gvm installed!"
            Write-Output "Please see https://github.com/flofreud/posh-gvm#usage for details to get started."
            Write-Warning "Execute 'Import-Module posh-gvm -Force' so changes take effect!"
        } else {
            Write-Warning 'Could not unzip archive containing posh-gvm. Most likely the archive is currupt. Please try to install again.'
        }
    } finally {
        # clear temp dir
        Remove-Item -Recurse -Force $tempDir
    }
}

function Find-Module-Location {
    $moduleDescriptor = Get-Module posh-gvm

    if ( $moduleDescriptor ) {
        return (Get-Item ($moduleDescriptor).Path).Directory.FullName
    } else {
        $modulePaths = @($Env:PSModulePath -split ';')
        # set module path to posh default
        $targetModulePath = Join-Path -Path ([Environment]::GetFolderPath('MyDocuments')) -ChildPath WindowsPowerShell\Modules
        # if its not use select the first defined
        if ( $modulePaths -inotcontains $targetModulePath  ) {
            $targetModulePath = $modulePaths | Select-Object -Index 0
        }

        return "$targetModulePath\posh-gvm"
    }
}

Install-Posh-Gvm