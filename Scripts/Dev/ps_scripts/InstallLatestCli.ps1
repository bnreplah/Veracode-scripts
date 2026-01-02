Write-Output "Downloading the latest version of the Veracode CLI"
Set-ExecutionPolicy AllSigned -Scope Process -Force
$ProgressPreference = "silentlyContinue"; Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://tools.veracode.com/veracode-cli/install.ps1'))
Get-ChildItem ./
veracode