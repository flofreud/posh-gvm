# posh-gvm - the POwerSHell Groovy enVironment Manager
Posh-GVM is a clone of the [GVM CLI](https://github.com/gvmtool/gvm). In most aspects its an 1:1 copy of the BASH based version.

For further information about the features of GVM please the documentation on the [GVM Project Page](http://gvmtool.net).

Posh-GVM consumes the REST-API of the offical GVM CLI and may therefore break if the API will be changed in future.

Please report any bugs and feature request on the [GitHub Issue Tracker](https://github.com/flofreud/posh-gvm/issues).

## Differences to the BASH version
- different directory used as default ~\.posh-gvm instead of ~\.gvm
- command extension are not supported
- config of auto selfupdate and auto answer is different
- selfupdate works only for same special cases and need to be implemented correctly
- not all installable candidates are useful currently in Powershell (eg the groovyserv 0.13 package is not useable because there is no client)

## Installation

TODO

## Running the Pester Tests

All posh-gvm test are written for Pester. Please see its documentation: https://github.com/pester/Pester

To run the tests in Powershell, load the Pester module and run in posh-gvm checkout dir:
	
	$ Invoke-Pester