. .\Utils.ps1
. .\Init.ps1
. .\TestUtils.ps1

Describe 'Init-Posh-Gvm' {
    Context 'PGVM-Dir with only a grails folder' {
        Mock-PGVM-Dir
        Mock Check-JAVA-HOME -verifiable
        Mock Check-GVM-API-Version -verifiable
        MOck Update-Candidates-Cache -verifiable
        Mock Init-Candidate-Cache -verifiable
        Mock Set-Env-Candidate-Version -verifiable -parameterFilter { $Candidate -eq 'grails' -and $Version -eq 'current' }
        Mock Set-Env-Candidate-Version -verifiable -parameterFilter { $Candidate -eq 'groovy' -and $Version -eq 'current' }
        Mock Set-Env-Candidate-Version -verifiable -parameterFilter { $Candidate -eq 'bla' -and $Version -eq 'current' }
        $Script:PGVM_CANDIDATES_PATH = "$Global:PGVM_DIR\.meta\candidates.txt"
        $Script:GVM_CANDIDATES = 'grails','groovy','bla'

        Init-Posh-Gvm

        It "creates .meta" {
            Test-Path "$Global:PGVM_DIR\.meta" | Should Be $true
        }

        It "creates grails" {
            Test-Path "$Global:PGVM_DIR\grails" | Should Be $true
        }

        It "creates groovy" {
            Test-Path "$Global:PGVM_DIR\groovy" | Should Be $true
        }

        It "creates bla" {
            Test-Path "$Global:PGVM_DIR\bla" | Should Be $true
        }

        It "calls methods to test JAVA_HOME, API version, loads candidate cache and setup env variables" {
            Assert-VerifiableMocks
        }

        Reset-PGVM-Dir
    }

    Context 'PGVM-Dir with only a grails folder and a candidates list' {
        Mock-PGVM-Dir
        Mock Check-JAVA-HOME -verifiable
        Mock Check-GVM-API-Version -verifiable
        MOck Update-Candidates-Cache
        Mock Init-Candidate-Cache -verifiable
        Mock Set-Env-Candidate-Version -verifiable -parameterFilter { $Candidate -eq 'grails' -and $Version -eq 'current' }
        Mock Set-Env-Candidate-Version -verifiable -parameterFilter { $Candidate -eq 'groovy' -and $Version -eq 'current' }
        Mock Set-Env-Candidate-Version -verifiable -parameterFilter { $Candidate -eq 'bla' -and $Version -eq 'current' }
        $Script:PGVM_CANDIDATES_PATH = "$Global:PGVM_DIR\.meta\candidates.txt"
        New-Item -ItemType Directory "$Global:PGVM_DIR\.meta" | Out-Null
        New-Item -ItemType File $Script:PGVM_CANDIDATES_PATH | Out-Null
        $Script:GVM_CANDIDATES = 'grails','groovy','bla'

        Init-Posh-Gvm

        It "creates .meta" {
            Test-Path "$Global:PGVM_DIR\.meta" | Should Be $true
        }

        It "creates grails" {
            Test-Path "$Global:PGVM_DIR\grails" | Should Be $true
        }

        It "creates groovy" {
            Test-Path "$Global:PGVM_DIR\groovy" | Should Be $true
        }

        It "creates bla" {
            Test-Path "$Global:PGVM_DIR\bla" | Should Be $true
        }

        It "calls methods to test JAVA_HOME, API version, loads candidate cache and setup env variables" {
            Assert-VerifiableMocks
        }

        It "does not call update-candidates-cache" {
            Assert-MockCalled Update-Candidates-Cache 0
        }

        Reset-PGVM-Dir
    }
}

Describe 'Check-JAVA-HOME' {
    Context 'JAVA_HOME is set' {
        Mock Get-Command
        Mock Test-Path { $true } -parameterFilter { $Path -eq 'env:Java_HOME' }

        Check-JAVA-HOME

        It "changes nothing" {
            Assert-MockCalled Get-Command 0
        }
    }

    Context 'JAVA_HOME is not set but javac is on path' {
        $backupJAVAHOME = [Environment]::GetEnvironmentVariable('JAVA_HOME')
        Mock Test-Path { $false } -parameterFilter { $Path -eq 'env:Java_HOME' }
        Mock Get-Command { New-Object PSObject -Property @{ Path = (Get-Item 'C:\Windows\explorer.exe') } } -parameterFilter { $Name -eq 'javac' }
        $expectedNewJAVAHOME = 'C:\'

        Check-JAVA-HOME

        It "sets JAVA_HOME to javac parent" {
            [Environment]::GetEnvironmentVariable('JAVA_HOME') | Should Be $expectedNewJAVAHOME
        }

        [Environment]::SetEnvironmentVariable('JAVA_HOME', $backupJAVAHOME)
    }

    Context 'JAVA_HOME is not set and javax is not on path' {
        Mock Test-Path { $false } -parameterFilter { $Path -eq 'env:Java_HOME' }
        Mock Get-Command { throw 'error' } -parameterFilter { $Name -eq 'javac' }

        It "throws an error" {
            { Check-JAVA-HOME } | Should Throw
        }
    }
}

Describe 'Check-GVM-API-Version' {
    Context 'API offline' {
        $Script:GVM_AVAILABLE = $true
        $Script:GVM_API_NEW_VERSION = $false
        Mock Get-GVM-API-Version
        Mock Invoke-API-Call { throw 'error' }  -parameterFilter { $Path -eq 'app/Version' }

        Check-GVM-API-Version

        It 'the error handling set the app in offline mode' {
            $Script:GVM_AVAILABLE | Should be $false
        }

        It 'does not informs about new version' {
            $Script:GVM_API_NEW_VERSION | Should Be $false
        }
    }

    Context 'No new version' {
        $backup_Global_PGVM_AUTO_SELFUPDTE = $Global:PGVM_AUTO_SELFUPDATE
        $Global:PGVM_AUTO_SELFUPDATE = $true
        $Script:GVM_API_NEW_VERSION = $false

        Mock Get-GVM-API-Version { 1.2.2 }
        Mock Invoke-API-Call { 1.2.2 } -parameterFilter { $Path -eq 'app/Version' }
        Mock Invoke-Self-Update

        Check-GVM-API-Version

        It 'do nothing' {
            Assert-MockCalled Invoke-Self-Update 0
        }

        It 'does not informs about new version' {
            $Script:GVM_API_NEW_VERSION | Should Be $false
        }

        $Global:PGVM_AUTO_SELFUPDATE = $backup_Global_PGVM_AUTO_SELFUPDTE
    }

    Context 'New version and no auto selfupdate' {
        $backup_Global_PGVM_AUTO_SELFUPDTE = $Global:PGVM_AUTO_SELFUPDATE
        $Global:PGVM_AUTO_SELFUPDATE = $false
        $Script:GVM_API_NEW_VERSION = $false

        Mock Get-GVM-API-Version { '1.2.2' }
        Mock Invoke-API-Call { '1.2.3' } -parameterFilter { $Path -eq 'app/Version' }

        Check-GVM-API-Version

        It 'informs about new version' {
            $Script:GVM_API_NEW_VERSION | Should Be $true
        }

        It 'write a warning about needed update' {
            Assert-VerifiableMocks
        }

        $Global:PGVM_AUTO_SELFUPDATE = $backup_Global_PGVM_AUTO_SELFUPDTE
    }

    Context 'New version and auto selfupdate' {
        $backup_Global_PGVM_AUTO_SELFUPDTE = $Global:PGVM_AUTO_SELFUPDATE
        $Global:PGVM_AUTO_SELFUPDATE = $true
        $Script:GVM_API_NEW_VERSION = $false

        Mock Get-GVM-API-Version { '1.2.2' }
        Mock Invoke-API-Call { '1.2.3' } -parameterFilter { $Path -eq 'app/Version' }
        Mock Invoke-Self-Update -verifiable

        Check-GVM-API-Version

        It 'updates self' {
            Assert-VerifiableMocks
        }

        It 'does not informs about new version' {
            $Script:GVM_API_NEW_VERSION | Should Be $false
        }

        $Global:PGVM_AUTO_SELFUPDATE = $backup_Global_PGVM_AUTO_SELFUPDTE
    }
}

Describe 'Check-Posh-Gvm-Version' {
    Context 'No new Version' {
        $backup_Global_PGVM_AUTO_SELFUPDTE = $Global:PGVM_AUTO_SELFUPDATE
        $Global:PGVM_AUTO_SELFUPDATE = $false
        $Script:PGVM_NEW_VERSION = $false

        Mock Is-New-Posh-GVM-Version-Available { $false }
        Mock Invoke-Self-Update

        Check-Posh-Gvm-Version

        It 'does not update itself' {
            Assert-MockCalled Invoke-Self-Update -Times 0
        }

        It 'does not informs about new version' {
            $Script:PGVM_NEW_VERSION | Should Be $false
        }

        $Global:PGVM_AUTO_SELFUPDATE = $backup_Global_PGVM_AUTO_SELFUPDTE
    }

    Context 'New version and no auto selfupdate' {
        $backup_Global_PGVM_AUTO_SELFUPDTE = $Global:PGVM_AUTO_SELFUPDATE
        $Global:PGVM_AUTO_SELFUPDATE = $false
        $Script:PGVM_NEW_VERSION = $false

        Mock Is-New-Posh-GVM-Version-Available { $true }
        Mock Invoke-Self-Update

        Check-Posh-Gvm-Version

        It 'informs about new version' {
            $Script:PGVM_NEW_VERSION | Should Be $true
        }

        It 'does not update itself' {
            Assert-MockCalled Invoke-Self-Update -Times 0
        }

        $Global:PGVM_AUTO_SELFUPDATE = $backup_Global_PGVM_AUTO_SELFUPDTE
    }

    Context 'New version and auto selfupdate' {
        $backup_Global_PGVM_AUTO_SELFUPDTE = $Global:PGVM_AUTO_SELFUPDATE
        $Global:PGVM_AUTO_SELFUPDATE = $true
        $Script:PGVM_NEW_VERSION = $false

        Mock Is-New-Posh-GVM-Version-Available { $true }
        Mock Invoke-Self-Update -verifiable

        Check-Posh-Gvm-Version

        It 'updates self' {
            Assert-VerifiableMocks
        }

        It 'does not informs about new version' {
            $Script:PGVM_NEW_VERSION | Should Be $false
        }

        $Global:PGVM_AUTO_SELFUPDATE = $backup_Global_PGVM_AUTO_SELFUPDTE
    }
}