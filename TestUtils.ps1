. .\Utils.ps1

function Mock-Check-Candidate-Grails {
    Mock Check-Candidate-Present -verifiable -parameterFilter { $Candidate -eq 'grails' }
}

function Mock-Online {
    Mock Get-Online-Mode { return $true }
}

function Mock-Offline {
    Mock Get-Online-Mode { return $false }
}

function Mock-Grails-1.1.1-Locally-Available($Available) {
    if ( $Available ) {
        Mock Is-Candidate-Version-Locally-Available { return $true }  -parameterFilter { $Candidate -eq 'grails' -and $Version -eq '1.1.1' }
    } else {
        Mock Is-Candidate-Version-Locally-Available { return $false }  -parameterFilter { $Candidate -eq 'grails' -and $Version -eq '1.1.1' }
    }
}

function Mock-Current-Grails-1.2 {
    Mock Get-Current-Candidate-Version { return 1.2 } -parameterFilter { $Candidate -eq 'grails' }
}

function Mock-No-Current-Grails {
    Mock Get-Current-Candidate-Version { return $null } -parameterFilter { $Candidate -eq 'grails' }
}

function Mock-Api-Call-Default-Grails-2.2 {
    Mock Invoke-API-Call { return 2.2 } -parameterFilter { $Path -eq 'candidates/grails/default' }
}

function Mock-Api-Call-Grails-1.1.1-Available($Available) {
    if ( $Available ) {
        Mock Invoke-API-Call { return $true } -parameterFilter { $Path -eq 'candidates/grails/1.1.1' }
    } else {
        Mock Invoke-API-Call { return $false } -parameterFilter { $Path -eq 'candidates/grails/1.1.1' }
    }
}

function Mock-PGVM-Dir {
    $Script:backup_PGVM_DIR = $Global:PGVM_DIR
    New-Item -ItemType Directory "TestDrive:.posh-gvm" | Out-Null
    $Global:PGVM_DIR = (Get-Item "TestDrive:.posh-gvm").FullName
    New-Item -ItemType Directory "$Global:PGVM_DIR\grails" | Out-Null
}

function Reset-PGVM-Dir {
    $link = "$Global:PGVM_DIR\grails\current"
    if ( Test-Path $link ) {
        (Get-Item $link).Delete()
    }

    $Global:PGVM_DIR = $Script:backup_PGVM_DIR
}

function Mock-Grails-Home($Version) {
    $Script:backup_GRAILS_HOME = [System.Environment]::GetEnvironmentVariable('GRAILS_HOME')
    [System.Environment]::SetEnvironmentVariable('GRAILS_HOME', "$Global:PGVM_DIR\grails\$Version")
}

function Reset-Grails-Home {
    [System.Environment]::SetEnvironmentVariable('GRAILS_HOME', $Script:backup_GRAILS_HOME)
}

function Mock-Dispatcher-Test([switch]$Offline) {
    Mock-PGVM-Dir
    $Script:GVM_FORCE_OFFLINE = $false
    $Script:FIRST_RUN = $false
    if ( !($Offline) ) {
        Mock Check-Available-Broadcast -verifiable
        Write-New-Version-Broadcast -verifiable
    }
    Mock Init-Candidate-Cache -verifiable
}

function Reset-Dispatcher-Test {
    Reset-PGVM-Dir
}