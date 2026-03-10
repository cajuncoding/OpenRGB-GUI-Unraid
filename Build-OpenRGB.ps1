<#
.SYNOPSIS
  Build (and optionally push) the OpenRGB GUI Docker image with an interactive version selector.

.DESCRIPTION
  - Fetches latest OpenRGB tags from GitLab (stable + RC)
  - Lets you choose: Latest Stable, Latest RC, pick from a list, or enter custom
  - Builds for linux/amd64 (standard docker build)
  - Optional push to Docker Hub and :latest tag

.EXAMPLES
  .\Build-OpenRGB.ps1
  .\Build-OpenRGB.ps1 -Push
  .\Build-OpenRGB.ps1 -Push -AlsoTagLatest
  .\Build-OpenRGB.ps1 -Version "release_candidate_1.0rc2" -Push
#>

[CmdletBinding()]
param(
  [string]$Repo = "cajuncoding/openrgb-gui-unraid",
  [string]$Dockerfile = "Dockerfile.gui",
  [string]$Context = ".",
  [string]$Version,              # If provided, skips interactive selection
  [switch]$Push,
  [switch]$AlsoTagLatest,
  [switch]$VerboseOutput
)

$ErrorActionPreference = "Stop"

function Write-Info { param([string]$msg) Write-Host "[INFO]  $msg" -ForegroundColor Cyan }
function Write-Warn { param([string]$msg) Write-Host "[WARN]  $msg" -ForegroundColor Yellow }
function Write-Err  { param([string]$msg) Write-Host "[ERROR] $msg" -ForegroundColor Red }

function Ensure-Docker {
  try { docker version | Out-Null }
  catch {
    Write-Err "Docker Desktop is not installed or not running."
    throw
  }
}

function Ensure-File { param([string]$path)
  if (-not (Test-Path -LiteralPath $path)) {
    Write-Err "Required file not found: $path"
    throw "Missing file: $path"
  }
}

function Get-OpenRGBTags {
  # Returns array of PSCustomObjects: @{ name=<string>; date=<datetime> }
  $tags = @()
  try {
    try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 } catch {}

    $base = "https://gitlab.com/api/v4/projects/CalcProgrammer1%2FOpenRGB"
    $tagsUrl = "$base/repository/tags?per_page=100"

    if ($VerboseOutput) { Write-Info "Fetching $tagsUrl" }
    $resp = Invoke-RestMethod -Uri $tagsUrl -Method GET -TimeoutSec 30

    foreach ($t in $resp) {
      $date = if ($t.commit -and $t.commit.created_at) {
        [datetime]$t.commit.created_at
      } elseif ($t.commit -and $t.commit.committed_date) {
        [datetime]$t.commit.committed_date
      } else {
        Get-Date
      }

      # Keep only release tags (stable + RC)
      if ($t.name -match '^release(_candidate)?_') {
        $tags += [pscustomobject]@{ name = $t.name; date = $date }
      }
    }

    # Newest first
    $tags | Sort-Object date -Descending
  } catch {
    Write-Warn "Failed to query GitLab tags (network/API). You can still enter a version manually."
    @()
  }
}

function Choose-OpenRGBVersion {
  param([string]$Preselected)
  if ($Preselected) { return $Preselected }

  $tags = Get-OpenRGBTags
  $stable = $tags | Where-Object { $_.name -match '^release_\d' }
  $rc     = $tags | Where-Object { $_.name -match '^release_candidate_' }

  Write-Host ""
  Write-Host "Select OpenRGB version to build:" -ForegroundColor Green

  $menu = @()
  if ($stable.Count -gt 0) { $menu += @{ Key="1"; Label="Latest STABLE: $($stable[0].name)"; Value=$stable[0].name } }
  if ($rc.Count -gt 0)     { $menu += @{ Key="2"; Label="Latest RC:     $($rc[0].name)";     Value=$rc[0].name     } }
  $menu += @{ Key="3"; Label="Choose from a list..."; Value="list" }
  $menu += @{ Key="4"; Label="Enter custom (tag)";  Value="custom" }

  foreach ($m in $menu) { Write-Host ("  {0}. {1}" -f $m.Key, $m.Label) }

  $choice = Read-Host ("Enter choice [1-{0}]" -f $menu.Count)
  if ([string]::IsNullOrWhiteSpace($choice)) { $choice = "1" }

  switch ($choice) {
    "1" {
      if ($stable.Count -gt 0) { return $stable[0].name }
      Write-Warn "No stable releases found."
    }
    "2" {
      if ($rc.Count -gt 0) { return $rc[0].name }
      Write-Warn "No RC releases found."
    }
    "3" {
      $list = $tags | Select-Object -First 30
      if ($list.Count -eq 0) {
        Write-Warn "No tags available from API. Choose custom."
      } else {
        Write-Host ""
        Write-Host "Latest tags (most recent first):" -ForegroundColor Green
        for ($i = 0; $i -lt $list.Count; $i++) {
          $num = $i + 1
          Write-Host ("  {0,2}. {1}" -f $num, $list[$i].name)
        }
        $sel = Read-Host ("Pick a number [1-{0}]" -f $list.Count)
        if ($sel -as [int] -and $sel -ge 1 -and $sel -le $list.Count) {
          return $list[$sel - 1].name
        } else {
          Write-Warn "Invalid selection."
        }
      }
    }
    default {
      # fall through to custom
    }
  }

  $manual = Read-Host "Enter tag (e.g., release_candidate_1.0rc2 or release_0.9)"
  if ([string]::IsNullOrWhiteSpace($manual)) {
    throw "No version selected."
  }
  return $manual
}

function Try-Push {
  param([string]$ImageTag)
  try {
    docker push $ImageTag
    if ($LASTEXITCODE -eq 0) { return }
    throw "First push failed."
  } catch {
    Write-Warn "Push failed. Attempting 'docker login' and retry..."
    docker login
    docker push $ImageTag
    if ($LASTEXITCODE -ne 0) {
      throw "Push failed after login."
    }
  }
}

# -------------------- MAIN --------------------
Ensure-Docker
Ensure-File -path $Dockerfile

try {
  $selectedVersion = Choose-OpenRGBVersion -Preselected $Version
  Write-Host ""
  Write-Info "Selected OpenRGB tag: $selectedVersion"
} catch {
  Write-Err $_.Exception.Message
  exit 1
}

$tag = "$($Repo):$selectedVersion"
$latestTag = "$($Repo):latest"

# Build args
$buildArgs = @("--build-arg", "OPENRGB_VERSION=$selectedVersion")

# Show summary
Write-Host ""
Write-Host "Build Plan" -ForegroundColor Green
Write-Host "  Repo:        $Repo"
Write-Host "  Tag:         $tag"
Write-Host "  Dockerfile:  $Dockerfile"
Write-Host "  Context:     $Context"
Write-Host "  Build-Arg:   OPENRGB_VERSION=$selectedVersion"
if ($AlsoTagLatest) { Write-Host "  Also:        $latestTag" }
Write-Host ""

# Build (amd64 local)
$cmd = @("build","--file",$Dockerfile,"--tag",$tag) + $buildArgs + @($Context)
if ($VerboseOutput) { $cmd += "--progress=plain" }

Write-Info "Running: docker $($cmd -join ' ')"
docker @cmd

if ($LASTEXITCODE -ne 0) {
  Write-Err "Build failed."
  exit 1
}

if ($AlsoTagLatest) {
  Write-Info "Tagging as latest..."
  docker tag $tag $latestTag
}

if ($Push) {
  Write-Info "Pushing $tag..."
  Try-Push -ImageTag $tag
  if ($AlsoTagLatest) {
    Write-Info "Pushing $latestTag..."
    Try-Push -ImageTag $latestTag
  }
}

Write-Host ""
Write-Host "Done." -ForegroundColor Green