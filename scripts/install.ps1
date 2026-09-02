# install.ps1 - Install OpenCrew agents into the global OpenCode agent directory.
#
# Usage:
#   .\scripts\install.ps1          # prompt before overwriting existing files
#   .\scripts\install.ps1 -Force   # overwrite existing files without prompting

[CmdletBinding()]
param(
    [switch]$Force
)

$ErrorActionPreference = 'Stop'

# Resolve repo root (one level above this script's directory).
$RepoRoot = Split-Path -Parent $PSScriptRoot

# Target: global OpenCode agents directory.
$AgentsDir = Join-Path $HOME '.config\opencode\agents'

# Source -> destination mapping (source is relative to repo root).
$Files = @(
    @{ Source = 'crew-lead\opencode.md'; Dest = 'crew-lead.md' },
    @{ Source = 'agents\repo-scout.md';  Dest = 'repo-scout.md' },
    @{ Source = 'agents\architect.md';   Dest = 'architect.md' },
    @{ Source = 'agents\implementer.md'; Dest = 'implementer.md' },
    @{ Source = 'agents\reviewer.md';    Dest = 'reviewer.md' },
    @{ Source = 'agents\grunt.md';       Dest = 'grunt.md' }
)

function Test-OpenCodeInstalled {
    # Consider OpenCode installed if the executable is on PATH,
    # or if the global OpenCode config directory already exists.
    $cmd = Get-Command opencode -ErrorAction SilentlyContinue
    if ($null -ne $cmd) {
        return $true
    }

    $configDir = Join-Path $HOME '.config\opencode'
    if (Test-Path -LiteralPath $configDir) {
        return $true
    }

    return $false
}

Write-Host 'OpenCrew installer' -ForegroundColor Cyan

if (-not (Test-OpenCodeInstalled)) {
    Write-Warning 'OpenCode does not appear to be installed (no "opencode" on PATH and no ~/.config/opencode directory found).'
    Write-Warning 'Continuing anyway; the agents will be installed into:'
    Write-Warning "  $AgentsDir"
}

# Create the agents directory if it does not exist.
if (-not (Test-Path -LiteralPath $AgentsDir)) {
    New-Item -ItemType Directory -Path $AgentsDir -Force | Out-Null
    Write-Host "Created directory: $AgentsDir"
}

$installed = @()
$skipped = @()

foreach ($entry in $Files) {
    $src = Join-Path $RepoRoot $entry.Source
    $dst = Join-Path $AgentsDir $entry.Dest

    if (-not (Test-Path -LiteralPath $src -PathType Leaf)) {
        Write-Warning "Source file not found, skipping: $($entry.Source)"
        $skipped += $entry.Dest
        continue
    }

    $exists = Test-Path -LiteralPath $dst -PathType Leaf

    $shouldWrite = $true
    if ($exists -and -not $Force) {
        $answer = Read-Host "  $($entry.Dest) already exists. Replace? [y/N]"
        if ($answer -notmatch '^(y|yes)$') {
            Write-Host "  Skipped $($entry.Dest)."
            $skipped += $entry.Dest
            $shouldWrite = $false
        }
    }

    if ($shouldWrite) {
        Copy-Item -LiteralPath $src -Destination $dst -Force
        $installed += $entry.Dest
    }
}

Write-Host ''
if ($installed.Count -gt 0) {
    Write-Host 'Installed:' -ForegroundColor Green
    foreach ($name in $installed) {
        Write-Host "  $name"
    }
}

if ($skipped.Count -gt 0) {
    Write-Host 'Skipped:' -ForegroundColor Yellow
    foreach ($name in $skipped) {
        Write-Host "  $name"
    }
}

Write-Host ''
Write-Host 'OpenCrew installed successfully.'
Write-Host ''
Write-Host 'Try:'
Write-Host ''
Write-Host '  @crew-lead Explain how authentication works in this repository.'
