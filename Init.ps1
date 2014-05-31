#region Initialization
function Init-Posh-Gvm() {
    Write-Verbose 'Init posh-gvm'

    $ErrorActionPreference = 'Stop'
    $ProgressPreference = 'SilentlyContinue'

    Check-Posh-Gvm-Version
    Check-JAVA-HOME

    # Check if $Global:PGVM_DIR is available, if not create it
    if ( !( Test-Path "$Global:PGVM_DIR\.meta" ) ) {
        New-Item -ItemType Directory "$Global:PGVM_DIR\.meta" | Out-Null
    }

    # Load candidates cache
    if ( ! (Test-Path $Script:PGVM_CANDIDATES_PATH) ) {
        Update-Candidates-Cache
    }

    Check-GVM-API-Version

    Init-Candidate-Cache

    #Setup default paths
    Foreach ( $candidate in $Script:GVM_CANDIDATES ) {
		if ( !( Test-Path "$Global:PGVM_DIR\$candidate" ) ) {
			New-Item -ItemType Directory "$Global:PGVM_DIR\$candidate" | Out-Null
		}

        Set-Env-Candidate-Version $candidate 'current'
    }

    # Check if we can use unzip (which is much faster)
    Check-Unzip-On-Path
}

function Check-JAVA-HOME() {
	# Check for JAVA_HOME, If not set, try to interfere it
    if ( ! (Test-Path env:JAVA_HOME) ) {
        try {
            [Environment]::SetEnvironmentVariable('JAVA_HOME', (Get-Item (Get-Command 'javac').Path).Directory.Parent.FullName)
        } catch {
            throw "Could not find java, please set JAVA_HOME"
        }
    }
}

function Check-Unzip-On-Path() {
    try {
        Get-Command 'unzip.exe' | Out-Null
        $Script:UNZIP_ON_PATH = $true
    } catch {
        $Script:UNZIP_ON_PATH = $false
    }
}

function Check-GVM-API-Version() {
    Write-Verbose 'Checking GVM-API version'
    try {
        $apiVersion = Get-GVM-API-Version
        $gvmRemoteVersion = Invoke-API-Call "app/version"

        if ( $gvmRemoteVersion -gt $apiVersion) {
            if ( $Global:PGVM_AUTO_SELFUPDATE ) {
                Invoke-Self-Update
            } else {
                $Script:GVM_API_NEW_VERSION = $true
            }
        }
    } catch {
        $Script:GVM_AVAILABLE = $false
    }
}

function Check-Posh-Gvm-Version() {
    Write-Verbose 'Checking posh-gvm version'
    if ( Is-New-Posh-GVM-Version-Available ) {
        if ( $Global:PGVM_AUTO_SELFUPDATE ) {
            Invoke-Self-Update
        } else {
            $Script:PGVM_NEW_VERSION = $true
        }
    }
}

#endregion