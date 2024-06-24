mkdir "$env:USERPROFILE\Documents\wgcf\" *>$null
cd "$env:USERPROFILE\Documents\wgcf\"
Invoke-RestMethod 'https://api.github.com/repos/ViRb3/wgcf/releases/latest' | % assets | ? name -like "*_windows_amd64.exe" | % { Invoke-WebRequest $_.browser_download_url -OutFile wgcf.exe }
Start-Process -FilePath .\wgcf.exe register -Wait -NoNewWindow
Start-Process -FilePath .\wgcf.exe generate -Wait -NoNewWindow
echo "Finished, config file can be found in $env:USERPROFILE\Documents\wgcf\wgcf-profile.conf"
explorer .
