# Check if function TabExpansion already exists and backup existing version to
# prevent breaking other TabExpansion implementations.
# Taken from posh-git https://github.com/dahlbyk/posh-git/blob/master/GitTabExpansion.ps1#L297
if (Test-Path Function:\TabExpansion) {
    Rename-Item Function:\TabExpansion TabExpansionBackup
}

function TabExpansion($line, $lastWord) {
    $lastBlock = [regex]::Split($line, '[|;]')[-1].TrimStart()

    switch -regex ($lastBlock) {
        # Execute gvm tab expansion for gvm command
        '^gvm (.*)' { gvmTabExpansion($lastBlock) }
        # Fall back on existing tab expansion
        default { if (Test-Path Function:\TabExpansionBackup) { TabExpansionBackup $line $lastWord } }
    }
}

$Script:PGVM_TAB_COMMANDS = @('install','uninstall','rm','list','use','default','current','version','broadcast','help','offline','selfupdate','flush')
function gvmTabExpansion($lastBlock) {
    if ( !($lastBlock -match '^gvm\s+(?<cmd>\S+)?(?<args> .*)?$') ) {
        return
    }
    $command = $Matches['cmd']
    $arguments = $Matches['args']

    if ( !($arguments) ) {
        # Try to complete the command
        return $Script:PGVM_TAB_COMMANDS | Where { $_.StartsWith($command) }
    }

    $arguments = $arguments.TrimStart()
    # Help add correct parameters
    switch -regex ($command) {
        '^i(nstall)?'    { gvmTabExpandion-Need-Candidate $command $arguments }
        '^(uninstall|rm)'{ gvmTabExpandion-Need-Candidate $command $arguments }
        '^(ls|list)'     { gvmTabExpandion-Need-Candidate $command $arguments }
        '^u(se)?'        { gvmTabExpandion-Need-Candidate $command $arguments }
        '^d(efault)?'    { gvmTabExpandion-Need-Candidate $command $arguments }
        '^c(urrent)?'    { gvmTabExpandion-Need-Candidate $command $arguments }
        '^offline'       { gvmTabExpansion-Offline $arguments }
        '^flush'         { gvmTabExpansion-Flush $arguments }
        default          {}
    }
}

function gvmTabExpandion-Need-Candidate($Command, $LastBlock) {
    if ( !($LastBlock -match "^(?<candidate>\S+)?(?<args> .*)?$") ) {
        return
    }
    $candidate = $Matches['candidate']
    $arguments = $Matches['args']

    Init-Candidate-Cache

    if ( !($arguments) ) {
        # Try to complete the command
        return $Script:GVM_CANDIDATES | Where { $_.StartsWith($candidate) }
    }

    if ( !($Script:GVM_CANDIDATES -contains $candidate) ) {
        return
    }

    $arguments = $arguments.TrimStart()
    # Help add correct parameters
    switch -regex ($command) {
        #'^i(nstall)?'    { gvmTabExpandion-Need-Version $candidate $arguments }
        '^(uninstall|rm)'{ gvmTabExpandion-Need-Version $candidate $arguments }
        '^u(se)?'        { gvmTabExpandion-Need-Version $candidate $arguments }
        '^d(efault)?'    { gvmTabExpandion-Need-Version $candidate $arguments }
        default          {}
    }
}

function gvmTabExpandion-Need-Version($Candidate, $LastBlock) {
    Get-Installed-Candidate-Version-List $Candidate | Where { $_.StartsWith($LastBlock) }
}

function gvmTabExpansion-Offline($Arguments) {
    @('enable','disable') | Where { ([string]$_).StartsWith($Arguments) }
}

function gvmTabExpansion-Flush($Arguments) {
    @('candidates','broadcast','archives','temp') | Where { ([string]$_).StartsWith($Arguments) }
}

Export-ModuleMember TabExpansion
Export-ModuleMember gvmTabExpansion