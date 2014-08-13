# posh-gvm - the POwerSHell Groovy enVironment Manager
Posh-GVM is a clone of the [GVM CLI](https://github.com/gvmtool/gvm). In most aspects its an 1:1 copy of the BASH based version.

For further information about the features of GVM please the documentation on the [GVM Project Page](http://gvmtool.net).

Posh-GVM consumes the REST-API of the offical GVM CLI and may therefore break if the API will be changed in future.

Please report any bugs and feature request on the [GitHub Issue Tracker](https://github.com/flofreud/posh-gvm/issues).

## Differences to the BASH version
- different directory used as default ~\.posh-gvm instead of ~\.gvm -> posh-gvm is not directly able to manage the .gvm-dir of GVM
- command extension are not supported
- different way to configurate data-dir and auto-anwser
- not all installable candidates are useful currently in Powershell (eg the groovyserv 0.13 package is not usable because there is no client app/script in the package)

## Installation

You have multiple choices for installation of posh-gvm:

Requirements:
- Powershell 3.0+ (included in Windows 8+/Windows Server 2012+, for Windows 7 install Windows Management Framework 3.0)

### With PsGet
1. Execute `Install-Module posh-gvm`
2. Execute `Import-Module posh-gvm`(best add it to your profile.ps1)
3. Execute `gvm help` to get started!
	
### Via short script
1. Execute `(new-object Net.WebClient).DownloadString('https://raw.githubusercontent.com/flofreud/posh-gvm/master/GetPoshGvm.ps1') | iex`
2. Execute `Import-Module posh-gvm`(best add it to your profile.ps1)
3. Execute `gvm help` to get started!

### Classic way
1. Checkout this repository to your Powershell module-directory.
2. Execute `Import-Module posh-gvm`(best add it to your profile.ps1)
3. Execute `gvm help` to get started!

## Update

Newer versions of posh-gvm will notify you about new versions which can be installed by `gvm selfupdate`. If `gvm version` does not show a version of posh-gvm you have to update manually.

### How to get a update of posh-gvm manually ?
How to update depends on how you installed posh-gvm:

#### With PsGet
	
	Update-Module posh-gvm

#### Via short Script
	
	(new-object Net.WebClient).DownloadString('https://raw.githubusercontent.com/flofreud/posh-gvm/master/GetPoshGvm.ps1') | iex

#### Classic way
Go to the checkout location and pull the repository.

## Usage

For a general overview of the feature please the [GVM Project Page](http://gvmtool.net) because posh-gvm is designed to work like the original BASH client.

Add `Import-Module posh-gvm` to your powershell profile to be able to use it after each start of Powershell. If you do not know where your profile is located, execute `$Global:profile`.

### Configuration
By default posh-gvm put all the data (inclusive the to be installed executables) into ~/.posh_gvm. You can change the location by setting: 
	
	$Global:PGVM_DIR = <path>
	
n your profile BEFORE the `Import-Module posh-gvm` line.

Similar to the BASH client you can configure posh-gvm to automatically set new installed versions as default version. You do this by adding: 

	$Global:PGVM_AUTO_ANSWER = $true

in your profile.
	
## Troubleshooting
Q: Error "File xxx cannot be loaded because the execution of scripts is disabled on this system. Please see "get-help about_signing" for more details."

A: By default, PowerShell restricts execution of all scripts. This is all about security. To "fix" this run PowerShell as Administrator and call

	Set-ExecutionPolicy RemoteSigned
	
## Running the Pester Tests

All posh-gvm test are written for Pester. Please see its documentation: https://github.com/pester/Pester

To run the tests in Powershell, load the Pester module and run in posh-gvm dir:
	
	$ Invoke-Pester
