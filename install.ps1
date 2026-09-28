$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

if ([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT) {
  throw "This installer supports Windows only."
}

$appName = if ($env:TINY_NVIM_APPNAME) { $env:TINY_NVIM_APPNAME } else { "tiny-nvim" }
if ($appName -notmatch "^[A-Za-z0-9][A-Za-z0-9._-]*$") {
  throw "TINY_NVIM_APPNAME must contain only letters, numbers, dots, underscores, and hyphens."
}

function Get-CurrentPath {
  $machinePath = [Environment]::GetEnvironmentVariable("Path", "Machine")
  $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
  return @($machinePath, $userPath) -join ";"
}

function Install-WingetPackage {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Id
  )

  & winget install --id $Id --exact --accept-package-agreements --accept-source-agreements
  if ($LASTEXITCODE -ne 0) {
    throw "winget could not install $Id (exit code $LASTEXITCODE)."
  }
  $env:Path = Get-CurrentPath
}

if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
  throw "winget is required. Install or update App Installer from Microsoft Store, then run this command again."
}

if (-not (Get-Command git.exe -ErrorAction SilentlyContinue)) {
  Write-Output "Installing Git..."
  Install-WingetPackage "Git.Git"
}

if (-not (Get-Command nvim.exe -ErrorAction SilentlyContinue)) {
  Write-Output "Installing Neovim..."
  Install-WingetPackage "Neovim.Neovim"
}

$git = (Get-Command git.exe -ErrorAction Stop).Source
$nvim = (Get-Command nvim.exe -ErrorAction Stop).Source
$versionLine = (& $nvim --version | Select-Object -First 1)
if ($versionLine -notmatch "NVIM v(\d+)\.(\d+)") {
  throw "Could not determine the installed Neovim version from: $versionLine"
}

$nvimVersion = [version]("{0}.{1}" -f $Matches[1], $Matches[2])
if ($nvimVersion -lt [version]"0.11") {
  throw "tiny-nvim requires Neovim 0.11.0 or newer. Installed version: $nvimVersion"
}

$configPath = Join-Path $env:LOCALAPPDATA $appName
$backupPath = $null
if (Test-Path -LiteralPath $configPath) {
  $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
  $backupPath = "${configPath}_backup_$timestamp"
  Write-Output "Backing up the existing config to $backupPath..."
  Move-Item -LiteralPath $configPath -Destination $backupPath
}

Write-Output "Cloning tiny-nvim to $configPath..."
& $git clone https://github.com/jellydn/tiny-nvim.git $configPath
if ($LASTEXITCODE -ne 0) {
  if (Test-Path -LiteralPath $configPath) {
    Remove-Item -LiteralPath $configPath -Recurse -Force
  }
  if ($backupPath) {
    Move-Item -LiteralPath $backupPath -Destination $configPath
  }
  throw "Could not clone tiny-nvim (exit code $LASTEXITCODE)."
}

$env:NVIM_APPNAME = $appName
[Environment]::SetEnvironmentVariable("NVIM_APPNAME", $appName, "User")

Write-Output "Installing plugins..."
Push-Location $configPath
try {
  & $nvim --headless -c "Lazy! install" -c "qa"
  if ($LASTEXITCODE -ne 0) {
    throw "Neovim could not install plugins (exit code $LASTEXITCODE)."
  }
} finally {
  Pop-Location
}

Write-Output "tiny-nvim installation completed."
Write-Output "Open a new PowerShell window, then run: nvim"
