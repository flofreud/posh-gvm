### Version 1.2.1
* BUGFIX: fixed wrong url construction for broadcast api

### Version 1.2.0
* IMPROVE: update to the new broadcast api for GVM

### Version 1.1.4
* IMPROVE: version check requests where executed on module import and took some time, these checks will now be executed on first gvm-call

### Version 1.1.3
* IMPROVE: the new version messaging

### Version 1.1.2
* BUGFIX: installation routine in GetPoshGvm.ps1 broken

### Version 1.1.1
* BUGFIX: default of $Global:PGVM_AUTO_SELFUPDATE was $true but should have been $false

### Version 1.1.0
* FEATURE: use unzip.exe if available on path for better install performance
* FEATURE: self-update 
* FEATURE: automatic check for new posh-gvm versions

### Version 1.0.0
* posh-gvm before it has self-update functionality