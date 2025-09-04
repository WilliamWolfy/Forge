<#
============================================================
 forge-alias.ps1 — Create alias (global or local) on Windows
============================================================
#>

param(
    [string]$ProjectName = "forge"
)

$ErrorActionPreference = "Stop"

Write-Host "🔧 Running Forge alias setup on Windows..."
Write-Host "📦 Project: $ProjectName"

# --- Base directory (script location) ---
$BASE_DIR = Split-Path -Parent $MyInvocation.MyCommand.Definition
$FORGE_BIN = Join-Path $BASE_DIR "$ProjectName\$ProjectName.sh"

if (-Not (Test-Path $FORGE_BIN)) {
    Write-Error "❌ Main script not found: $FORGE_BIN"
    exit 1
}

# --- Try global install (requires admin) ---
function Install-Global {
    $targetDir = "C:\ProgramData\$ProjectName"
    $target = Join-Path $targetDir "$ProjectName.sh"

    try {
        if (-Not (Test-Path $targetDir)) {
            New-Item -ItemType Directory -Force -Path $targetDir | Out-Null
        }
        Copy-Item $FORGE_BIN $target -Force

        # Create a global wrapper: project-name.cmd
        $wrapper = Join-Path $targetDir "$ProjectName.cmd"
        "@echo off`n""$target"" %*" | Out-File -Encoding ascii $wrapper

        Write-Host "✅ $ProjectName installed globally at $targetDir"
        return $true
    } catch {
        return $false
    }
}

if (Install-Global) {
    Write-Host "🚀 Done. Run '$ProjectName' from any terminal."
    exit 0
} else {
    Write-Host "⚠️  Global install not available. Using local wrapper."
}

# --- Local wrapper install ---
$localBin = Join-Path $HOME ".${ProjectName}\bin"
if (-Not (Test-Path $localBin)) {
    New-Item -ItemType Directory -Force -Path $localBin | Out-Null
}

$wrapper = Join-Path $localBin "$ProjectName.cmd"
"@echo off`n""$FORGE_BIN"" %*" | Out-File -Encoding ascii $wrapper
Write-Host "✅ Local wrapper created at: $wrapper"

# --- Ensure PATH includes $localBin ---
$userPath = [Environment]::GetEnvironmentVariable("PATH", "User")
if ($userPath -notlike "*$localBin*") {
    [Environment]::SetEnvironmentVariable("PATH", "$localBin;$userPath", "User")
    Write-Host "✅ PATH updated. Restart your terminal to use '$ProjectName'."
} else {
    Write-Host "ℹ️ PATH already contains $localBin"
}

Write-Host "🚀 $ProjectName alias setup complete!"
