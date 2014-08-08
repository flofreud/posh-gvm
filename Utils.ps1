function Write-Offline-Broadcast() {
    Write-Output @"
==== BROADCAST =================================================================

OFFLINE MODE ENABLED! Some functionality is now disabled.

================================================================================
"@
}

function Write-Online-Broadcast() {
    Write-Output @"
==== BROADCAST =================================================================

ONLINE MODE RE-ENABLED! All functionality now restored.

================================================================================

"@
}

function Write-New-Version-Broadcast() {
    if ( $Script:GVM_API_NEW_VERSION -or $Script:PGVM_NEW_VERSION ) {
Write-Output @"
==== UPDATE AVAILABLE ==========================================================

A new version is available. Please consider to execute:

    gvm selfupdate

================================================================================
"@
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

function Get-Posh-Gvm-Version() {
    return Get-Content $Script:PGVM_VERSION_PATH
}

function Is-New-Posh-GVM-Version-Available() {
    try {
        $localVersion = Get-Posh-Gvm-Version
        $currentVersion = Invoke-RestMethod $Script:PGVM_VERSION_SERVICE

        return ( $currentVersion -gt $localVersion )
    } catch {
        return $false
    }
}

function Get-GVM-API-Version() {
	if ( !(Test-Path $Script:GVM_API_VERSION_PATH) ) {
		return $null
	}
    return Get-Content $Script:GVM_API_VERSION_PATH
}

function Check-Available-Broadcast($Command) {
    $version = Get-GVM-API-Version
    if ( !( $version ) ) {
        return
    }

    $liveBroadcast = Invoke-Broadcast-API-Call

	Write-Verbose "Online-Mode: $Script:GVM_AVAILABLE"

	if ( $Script:GVM_ONLINE -and !($Script:GVM_AVAILABLE) ) {
		Write-Offline-Broadcast
	} elseif ( !($Script:GVM_ONLINE) -and $Script:GVM_AVAILABLE ) {
		Write-Online-Broadcast
	}
	$Script:GVM_ONLINE = $Script:GVM_AVAILABLE

	if ( $liveBroadcast ) {
		Handle-Broadcast $Command $liveBroadcast
	}
}

function Invoke-Broadcast-API-Call {
    try {
        $target = "$Script:PGVM_BROADCAST_SERVICE/broadcast/latest"
        Write-Verbose "Broadcast API call to: $target"
        return Invoke-RestMethod $target
    } catch {
        Write-Verbose "Could not reached broadcast API"
        $Script:GVM_AVAILABLE = $false
        return $null
    }
}

function Invoke-Self-Update($Force) {
    Write-Verbose 'Perform Invoke-Self-Update'
    Write-Output 'Update list of available candidates...'
    Update-Candidates-Cache
    $Script:GVM_API_NEW_VERSION = $false
    if ( $Force ) {
        Invoke-Posh-Gvm-Update
    } else {
        if ( Is-New-Posh-GVM-Version-Available ) {
            Invoke-Posh-Gvm-Update
        }
    }
    $Script:PGVM_NEW_VERSION = $false
}

function Invoke-Posh-Gvm-Update {
    Write-Output 'Update posh-gvm...'
    . "$psScriptRoot\GetPoshGvm.ps1"
}

function Check-Candidate-Present($Candidate) {
    if ( !($Candidate) ) {
        throw 'No candidate provided.'
    }

    if ( !($Script:GVM_CANDIDATES -contains $Candidate) ) {
        throw "Stop! $Candidate is no valid candidate!"
    }
}

function Check-Candidate-Version-Available($Candidate, $Version) {
    Check-Candidate-Present $Candidate

    $UseDefault = $false
    if ( !($Version) ) {
        Write-Verbose 'No version provided. Fallback to default version!'
        $UseDefault = $true
    }

    # Check locally
    elseif ( Is-Candidate-Version-Locally-Available $Candidate $Version ) {
        return $Version
    }

    # Check if offline
    if ( ! (Get-Online-Mode) ) {
        if ( $UseDefault ) {
            $Version = Get-Current-Candidate-Version $Candidate
            if ( $Version ) {
                return $Version
            } else {
                throw "Stop! No local default version for $Candidate and in offline mode."
            }
        }

        throw "Stop! $Candidate $Version is not available in offline mode."
    }

    if ( $UseDefault ) {
        Write-Verbose 'Try to get default version from remote'
        return Invoke-API-Call "candidates/$Candidate/default"
    }

    $VersionAvailable = Invoke-API-Call "candidates/$Candidate/$Version"

    if ( $VersionAvailable -eq 'valid' ) {
        return $Version
    } else {
        throw "Stop! $Version is not a valid $Candidate version."
    }
}

function Get-Current-Candidate-Version($Candidate) {
    $currentLink = "$Global:PGVM_DIR\$Candidate\current"

    if ( Test-Path $currentLink ) {
        try {
            return (Get-Item (Get-Item $currentLink).ReparsePoint.Target).Name
        } catch {
            return $null
        }
    } else {
        return $null
    }
}

function Get-Env-Candidate-Version($Candidate) {
    $envLink = [System.Environment]::GetEnvironmentVariable(([string]$Candidate).ToUpper() + "_HOME")

    if ( $envLink -match '(.*)current$' ) {
        Get-Current-Candidate-Version $Candidate
    } else {
        return (Get-Item $envLink).Name
    }
}

function Check-Candidate-Version-Locally-Available($Candidate, $Version) {
    if ( !(Is-Candidate-Version-Locally-Available $Candidate $Version) ) {
        throw "Stop! $Candidate $Version is not installed."
    }
}

function Is-Candidate-Version-Locally-Available($Candidate, $Version) {
    if ( $Version ) {
        return Test-Path "$Global:PGVM_DIR\$Candidate\$Version"
    } else {
        return $false
    }
}

function Get-Installed-Candidate-Version-List($Candidate) {
    return Get-ChildItem "$Global:PGVM_DIR\$Candidate" | ?{ $_.PSIsContainer -and $_.Name -ne 'current' } | Foreach { $_.Name }
}

function Set-Env-Candidate-Version($Candidate, $Version) {
    $candidateEnv = ([string]$candidate).ToUpper() + "_HOME"
    $candidateDir = "$Global:PGVM_DIR\$candidate"
    $candidateHome = "$candidateDir\$Version"
    $candidateBin = "$candidateHome\bin"

    if ( !([Environment]::GetEnvironmentVariable($candidateEnv) -eq $candidateHome) ) {
        [Environment]::SetEnvironmentVariable($candidateEnv, $candidateHome)
    }

    $env:PATH = "$candidateBin;$env:PATH"
}

function Set-Linked-Candidate-Version($Candidate, $Version) {
    $Link = "$Global:PGVM_DIR\$Candidate\current"
    $Target = "$Global:PGVM_DIR\$Candidate\$Version"
    Set-Junction-Via-Mklink $Link $Target
}

function Set-Junction-Via-Mklink($Link, $Target) {
    if ( Test-Path $Link ) {
        (Get-Item $Link).Delete()
    }

    Invoke-Expression -Command "cmd.exe /c mklink /J '$Link' '$Target'" | Out-Null
}

function Get-Online-Mode() {
    return $Script:GVM_AVAILABLE -and ! ($Script:GVM_FORCE_OFFLINE)
}

function Check-Online-Mode() {
    if ( ! (Get-Online-Mode) ) {
        throw 'This command is not available in offline mode.'
    }
}

function Invoke-API-Call([string]$Path, [string]$FileTarget, [switch]$IgnoreFailure) {
    try {
        $target = "$Script:PGVM_SERVICE/$Path"

        if ( $FileTarget ) {
            return Invoke-RestMethod $target -OutFile $FileTarget
        }

        return Invoke-RestMethod $target
    } catch {
        $Script:GVM_AVAILABLE = $false
        if ( ! ($IgnoreFailure) ) {
            Check-Online-Mode
        } else {
			return $null
		}
    }
}

function Cleanup-Directory($Path) {
    $dirStats = Get-ChildItem $Path -Recurse | Measure-Object -property length -sum
    Remove-Item -Force -Recurse $Path
    $count = $dirStats.Count
    $size = $dirStats.Sum/(1024*1024)
    Write-Output "$count archive(s) flushed, freeing $size MB"
}

function Handle-Broadcast($Command, $Broadcast) {
    $oldBroadcast = $null
    if (Test-Path $Script:PGVM_BROADCAST_PATH) {
        $oldBroadcast = (Get-Content $Script:PGVM_BROADCAST_PATH) -join "`n"
        Write-Verbose 'Old broadcast message loaded'
    }

    if ($oldBroadcast -ne $Broadcast -and !($Command -match 'b(roadcast)?') -and $Command -ne 'selfupdate' -and $Command -ne 'flush' ) {
        Write-Verbose 'Showing the new broadcast message'
        Set-Content $Script:PGVM_BROADCAST_PATH $Broadcast
        Write-Output $Broadcast
    }
}

function Init-Candidate-Cache() {
    if ( !(Test-Path $Script:PGVM_CANDIDATES_PATH) ) {
        throw 'Can not retrieve list of candidates'
    }

    $Script:GVM_CANDIDATES = (Get-Content $Script:PGVM_CANDIDATES_PATH).Split(',')
    Write-Verbose "Available candidates: $Script:GVM_CANDIDATES"
}

function Update-Candidates-Cache() {
    Write-Verbose 'Update candidates-cache from GVM-API'
    Check-Online-Mode
    Invoke-Api-Call 'app/version' $Script:GVM_API_VERSION_PATH
    Invoke-API-Call 'candidates' $Script:PGVM_CANDIDATES_PATH
}

function Write-Offline-Version-List($Candidate) {
    Write-Verbose 'Get version list from directory'

    Write-Output '------------------------------------------------------------'
    Write-Output "Offline Mode: only showing installed ${Candidate} versions"
    Write-Output '------------------------------------------------------------'
    Write-Output ''

    $current = Get-Current-Candidate-Version $Candidate
    $versions = Get-Installed-Candidate-Version-List $Candidate

    if ($versions) {
        foreach ($version in $versions) {
            if ($version -eq $current) {
                Write-Output " > $version"
            } else {
                Write-Output " * $version"
            }
        }
    } else {
        Write-Output '    None installed!'
    }

    Write-Output '------------------------------------------------------------'
	Write-Output '* - installed                                               '
	Write-Output '> - currently in use                                        '
	Write-Output '------------------------------------------------------------'
}

function Write-Version-List($Candidate) {
    Write-Verbose 'Get version list from API'

    $current = Get-Current-Candidate-Version $Candidate
    $versions = (Get-Installed-Candidate-Version-List $Candidate) -join ','
    Invoke-API-Call "candidates/$Candidate/list?platform=posh&current=$current&installed=$versions" | Write-Output
}

function Install-Local-Version($Candidate, $Version, $LocalPath) {
    $dir = Get-Item $LocalPath

    if ( !(Test-Path $dir -PathType Container) ) {
        throw "Local installation path $LocalPath is no directory"
    }

    Write-Output "Linking $Candidate $Version to $LocalPath"
    $link = "$Global:PGVM_DIR\$Candidate\$Version"
    Set-Junction-Via-Mklink $link $LocalPath
    Write-Output "Done installing!"
}

function Install-Remote-Version($Candidate, $Version) {

    if ( !(Test-Path $Script:PGVM_ARCHIVES_PATH) ) {
        New-Item -ItemType Directory $Script:PGVM_ARCHIVES_PATH | Out-Null
    }

    $archive = "$Script:PGVM_ARCHIVES_PATH\$Candidate-$Version.zip"
    if ( Test-Path $archive ) {
        Write-Output "Found a previously downloaded $Candidate $Version archive. Not downloading it again..."
    } else {
		Check-Online-Mode
        Write-Output "`nDownloading: $Candidate $Version`n"
        Download-File "$Script:PGVM_SERVICE/download/$Candidate/$Version`?platform=posh" $archive
    }

    Write-Output "Installing: $Candidate $Version"

    # create temp dir if necessary
    if ( !(Test-Path $Script:PGVM_TEMP_PATH) ) {
        New-Item -ItemType Directory $Script:PGVM_TEMP_PATH | Out-Null
    }

    # unzip downloaded archive
    Unzip-Archive $archive $Script:PGVM_TEMP_PATH

	# check if unzip successfully
	if ( !(Test-Path "$Script:PGVM_TEMP_PATH\*-$Version") ) {
		throw "Could not unzip the archive of $Candidate $Version. Please delete archive from $Script:PGVM_ARCHIVES_PATH (or delete all with 'gvm flush archives'"
	}

    # move to target location
    Move-Item "$Script:PGVM_TEMP_PATH\*-$Version" "$Global:PGVM_DIR\$Candidate\$Version"
    Write-Output "Done installing!"
}

function Unzip-Archive($Archive, $Target) {
    if ( $Script:UNZIP_ON_PATH ) {
        unzip.exe -oq $Archive -d $Target
    } else {
        # use the windows shell as general fallback (no working on Windows Server Core because there is no shell)
        $shell = New-Object -com shell.application
        $shell.namespace($Target).copyhere($shell.namespace($Archive).items(), 0x10)
    }
}

function Download-File($Url, $TargetFile) {
	<#
		Adepted from http://blogs.msdn.com/b/jasonn/archive/2008/06/13/downloading-files-from-the-internet-in-powershell-with-progress.aspx
	#>
    Write-Verbose "Try to download $Url with HttpWebRequest"
	$uri = New-Object "System.Uri" $Url
    $request = [System.Net.HttpWebRequest]::Create($uri)
    $request.set_Timeout(15000)
    $response = $request.GetResponse()
	$totalLength = [System.Math]::Floor($response.get_ContentLength()/1024)
	$responseStream = $response.GetResponseStream()
    $targetStream = New-Object -TypeName System.IO.FileStream -ArgumentList $targetFile, Create
	$buffer = new-object byte[] 10KB
    $count = $responseStream.Read($buffer,0,$buffer.length)
    $downloadedBytes = $count
	while ($count -gt 0)
    {
        [System.Console]::CursorLeft = 0
        [System.Console]::Write("Downloaded {0}K of {1}K", [System.Math]::Floor($downloadedBytes/1024), $totalLength)
        $targetStream.Write($buffer, 0, $count)
        $count = $responseStream.Read($buffer,0,$buffer.length)
        $downloadedBytes = $downloadedBytes + $count
    }
    $targetStream.Flush()
    $targetStream.Close()
    $targetStream.Dispose()
    $responseStream.Dispose()
    Write-Output ''
}