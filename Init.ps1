#region Initialization
function Init-Posh-Gvm() {
    Write-Verbose 'Init posh-gvm'

	Check-JAVA-HOME
	
    # Check if $Global:PGVM_DIR is available, if not create it
    if ( !( Test-Path "$Global:PGVM_DIR\.meta" ) ) {
        New-Item -ItemType Directory "$Global:PGVM_DIR\.meta" | Out-Null
    }

    Check-GVM-API-Version

    # Load candidates cache
    if ( ! (Test-Path $Script:PGVM_CANDIDATES_PATH) ) { 
        Update-Candidates-Cache
    }

    Init-Candidate-Cache
    
    #Setup default paths
    Foreach ( $candidate in $Script:GVM_CANDIDATES ) {
		if ( !( Test-Path "$Global:PGVM_DIR\$candidate" ) ) {
			New-Item -ItemType Directory "$Global:PGVM_DIR\$candidate" | Out-Null
		}
		
        Set-Env-Candidate-Version $candidate 'current'
    }
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

function Check-GVM-API-Version() {
    Write-Verbose 'Checking GVM-API version'
    try {
        $apiVersion = Get-GVM-API-Version
        $gvmRemoteVersion = Invoke-API-Call "app/version"

        if ( $gvmRemoteVersion -gt $apiVersion) {
            if ( $Global:PGVM_AUTO_SELFUPDATE ) {
                Invoke-Self-Update
            } else {
                Write-Warning 'New GVM-API version. Please execute "gvm selfupdate" and read instructions'
            }
        }
    } catch {
        $Script:GVM_AVAILABLE = $false
    }
}
#endregion