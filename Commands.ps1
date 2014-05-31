function gvm([string]$Command, [string]$Candidate, [string]$Version, [string]$InstallPath, [switch]$Verbose, [switch]$Force) {
    $ErrorActionPreference = 'Stop'
	$ProgressPreference = 'SilentlyContinue'
	if ($Verbose) { $VerbosePreference = 'Continue' }

    if ( !( Test-Path $Global:PGVM_DIR ) ) {
        Write-Warning "$Global:PGVM_DIR does not exists. Reinitialize posh-gvm"
        Init-Posh-Gvm
    }

    $Script:GVM_AVAILABLE = $true
    if ( !($Script:GVM_FORCE_OFFLINE) -and $Command -ne 'offline' ) {
        Check-Available-Broadcast $Command

        if ( $Script:GVM_AVAILABLE ) {
            if ( $Script:FIRST_RUN ) {
                Check-GVM-API-Version
                Check-Posh-Gvm-Version
                $Script:FIRST_RUN = $false
            }
            Write-New-Version-Broadcast
        }
    }

    Init-Candidate-Cache

    Write-Verbose "Command: $Command"
    try {
        switch -regex ($Command) {
            '^i(nstall)?$'    { Install-Candidate-Version $Candidate $Version $InstallPath }
            '^(uninstall|rm)$'{ Uninstall-Candidate-Version $Candidate $Version }
            '^(ls|list)$'     { List-Candidate-Versions $Candidate }
            '^u(se)?$'        { Use-Candidate-Version $Candidate $Version }
            '^d(efault)?$'    { Set-Default-Version $Candidate $Version }
            '^c(urrent)?$'    { Show-Current-Version $Candidate }
            '^v(ersion)?$'    { Show-Posh-Gvm-Version }
            '^b(roadcast)?$'  { Show-Broadcast-Message }
            '^h(elp)?$'       { Show-Help }
            '^offline$'       { Set-Offline-Mode $Candidate }
            '^selfupdate$'    { Invoke-Self-Update($Force) }
            '^flush$'         { Flush-Cache $Candidate }
            default           { Write-Warning "Invalid command: $Command"; Show-Help }
        }
    } catch {
        Show-Help
        if ( $_.CategoryInfo.Category -eq 'OperationStopped') {
            Write-Warning $_.CategoryInfo.TargetName
        } else {
            throw
        }
    }
}

function Install-Candidate-Version($Candidate, $Version, $InstallPath) {
    Write-Verbose 'Perform Install-Candidate-Version'
    Check-Candidate-Present $Candidate

    $localInstallation = $false
    if ($Version -and $InstallPath) {
        #local installation
        try {
            $Version = Check-Candidate-Version-Available $Candidate $Version
        } catch {
            $localInstallation = $true
        }
		if ( !($localInstallation) ) {
			throw 'Stop! Local installation for $Candidate $Version not possible. It exists remote already.'
		}
    } else {
        $Version = Check-Candidate-Version-Available $Candidate $Version
    }

    if ( Is-Candidate-Version-Locally-Available $Candidate $Version ) {
        throw "Stop! $Candidate $Version is already installed."
    }

    if ( $localInstallation ) {
        Install-Local-Version $Candidate $Version $InstallPath
    } else {
        Install-Remote-Version $Candidate $Version
    }

    $default = $false
    if ( !$Global:PGVM_AUTO_ANSWER ) {
        $default = (Read-Host -Prompt "Do you want $Candidate $Version to be set as default? (Y/n)") -match '(y|\A\z)'
    } else {
        $default = $true
    }

    if ( $default ) {
        Write-Output "Setting $Candidate $Version as default."
        Set-Linked-Candidate-Version $Candidate $Version
    }
}

function Uninstall-Candidate-Version($Candidate, $Version) {
    Write-Verbose 'Perform Uninstall-Candidate-Version'
    Check-Candidate-Present $Candidate

    if ( !(Is-Candidate-Version-Locally-Available $Candidate $Version) ) {
        throw "$Candidate $Version is not installed."
    }

    $current = Get-Current-Candidate-Version $Candidate

    if ( $current -eq $Version ) {
        Write-Output "Unselecting $Candidate $Version..."
        (Get-Item "$Global:PGVM_DIR\$Candidate\current").Delete()
    }

    Write-Output "Uninstalling $Candidate $Version..."
    Remove-Item -Recurse "$Global:PGVM_DIR\$Candidate\$Version"
}

function List-Candidate-Versions($Candidate) {
    Write-Verbose 'Perform List-Candidate-Version'
    Check-Candidate-Present $Candidate
    if ( Get-Online-Mode ) {
        Write-Version-List $Candidate
    } else {
        Write-Offline-Version-List $Candidate
    }
}

function Use-Candidate-Version($Candidate, $Version) {
    Write-Verbose 'Perform Use-Candidate-Version'
    $Version = Check-Candidate-Version-Available $Candidate $Version

    if ( $Version -eq (Get-Env-Candidate-Version $Candidate) ) {
        Write-Output "$Candidate $Version is used. Nothing changed."
    } else {
        Check-Candidate-Version-Locally-Available $Candidate $Version
        Set-Env-Candidate-Version $Candidate $Version
		Write-Output "Using $CANDIDATE version $Version in this shell."
    }
}

function Set-Default-Version($Candidate, $Version) {
    Write-Verbose 'Perform Set-Default-Version'
    $Version = Check-Candidate-Version-Available $Candidate $Version

    if ( $Version -eq (Get-Current-Candidate-Version $Candidate) ) {
        Write-Output "$Candidate $Version is already default. Nothing changed."
    } else {
        Check-Candidate-Version-Locally-Available $Candidate $Version
        Set-Linked-Candidate-Version $Candidate $Version
        Write-Output "Default $Candidate version set to $Version"
    }
}

function Show-Current-Version($Candidate) {
    Write-Verbose 'Perform Set-Current-Version'

    if ( !($Candidate) ) {
        Write-Output 'Using:'
        foreach ( $c in $Script:GVM_CANDIDATES ) {
            $v = Get-Env-Candidate-Version $c
            if ($v) {
                Write-Output "$c`: $v"
            }
        }
        return
    }

    Check-Candidate-Present $Candidate
    $Version = Get-Env-Candidate-Version $Candidate
    if ( $Version ) {
        Write-Output "Using $Candidate version $Version"
    } else {
        Write-Output "Not using any version of $Candidate"
    }
}

function Show-Posh-Gvm-Version() {
    $poshGvmVersion = Get-Posh-Gvm-Version
    $apiVersion = Get-GVM-API-Version
    Write-Output "posh-gvm (POwer SHell Groovy enVironment Manager) $poshGvmVersion base on GVM $GVM_BASE_VERSION and GVM API $apiVersion"
}

function Show-Broadcast-Message() {
    Write-Verbose 'Perform Show-Broadcast-Message'
    Get-Content $Script:PGVM_BROADCAST_PATH | Write-Output
}

function Set-Offline-Mode($Flag) {
    Write-Verbose 'Perform Set-Offline-Mode'
    switch ($Flag) {
        'enable'  { $Script:GVM_FORCE_OFFLINE = $true; Write-Output 'Forced offline mode enabled.' }
        'disable' { $Script:GVM_FORCE_OFFLINE = $false; $Script:GVM_ONLINE = $true; Write-Output 'Online mode re-enabled!' }
        default   { throws "Stop! $Flag is not a valid offline offline mode." }
    }
}

function Flush-Cache($DataType) {
    Write-Verbose 'Perform Flush-Cache'
    switch ($DataType) {
        'candidates' {
                        if ( Test-Path $Script:PGVM_CANDIDATES_PATH ) {
                            Remove-Item $Script:PGVM_CANDIDATES_PATH
                            Write-Output 'Candidates have been flushed.'
                        } else {
                            Write-Warning 'No candidate list found so not flushed.'
                        }
                     }
        'broadcast'  {
                        if ( Test-Path $Script:PGVM_BROADCAST_PATH ) {
                            Remove-Item $Script:PGVM_BROADCAST_PATH
                            Write-Output 'Broadcast have been flushed.'
                        } else {
                            Write-Warning 'No prior broadcast found so not flushed.'
                        }
                     }
        'version'    {
                        if ( Test-Path $Script:GVM_API_VERSION_PATH ) {
                            Remove-Item $Script:GVM_API_VERSION_PATH
                            Write-Output 'Version Token have been flushed.'
                        } else {
                            Write-Warning 'No prior Remote Version found so not flushed.'
                        }
                     }
        'archives'   { Cleanup-Directory $Script:PGVM_ARCHIVES_PATH }
        'temp'       { Cleanup-Directory $Script:PGVM_TEMP_PATH }
        'tmp'        { Cleanup-Directory $Script:PGVM_TEMP_PATH }
        default      { throws 'Stop! Please specify what you want to flush.' }
    }
}

function Show-Help() {
    Write-Output @"
Usage: gvm <command> <candidate> [version]
    gvm offline <enable|disable>

    commands:
        install   or i    <candidate> [version]
        uninstall or rm   <candidate> <version>
        list      or ls   <candidate>
        use       or u    <candidate> [version]
        default   or d    <candidate> [version]
        current   or c    [candidate]
        version   or v
        broadcast or b
        help      or h
        offline           <enable|disable>
        selfupdate        [-Force]
        flush             <candidates|broadcast|archives|temp>
    candidate  :  $($Script:GVM_CANDIDATES -join ', ')

    version    :  where optional, defaults to latest stable if not provided

eg: gvm install groovy
"@
}