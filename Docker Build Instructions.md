#Docker Build Instructions (Notes to myself)...

1. Use Terminal + Powershell 7...
  - Powershell 7 Install docs (winget): https://learn.microsoft.com/en-us/powershell/scripting/install/install-powershell-on-windows?view=powershell-7.5#winget
  - Install Command (needed to use WIX to get Terminal to recognize it): `winget install Microsoft.PowerShell --installer-type WIX --source winget`
2. Run `Build-OpenRGB.ps1`
  - NOTE: Docker Desktop must be running! Otherwise you will get error about `ERROR: failed to connect to the docker API at npipe:////./pipe/dockerDesktopLinuxEngine; . . .` 
  - You will be prompted to select the OpenRGB version to build and other details...
  - Commands:
	- Local Build Only: `.\Build-OpenRGB.ps1`
	- Build and Publish: `.\Build-OpenRGB.ps1 -Push -AlsoTagLatest`