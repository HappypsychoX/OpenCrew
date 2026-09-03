# uninstall.ps1 - Remove OpenCrew-managed agent files for a chosen runtime.
# Only OpenCrew files are removed; the agents directory itself and any
# unrelated user-created agents are left untouched.
#
# Usage:
#   .\scripts\uninstall.ps1                     # prompts for runtime
#   .\scripts\uninstall.ps1 -Runtime claude

[CmdletBinding()]
param(
    [ValidateSet('claude', 'opencode')]
    [string]$Runtime
)

$ErrorActionPreference = 'Stop'

$RepoRoot = Split-Path -Parent $PSScriptRoot

$ManagedFiles = @(
    'crew-lead.md',
    'repo-scout.md',
    'architect.md',
    'implementer.md',
    'reviewer.md',
    'grunt.md'
)

function Expand-HomePath {
    param([string]$Path)
    $expanded = $Path -replace '^~', $HOME
    return $expanded -replace '/', '\'
}

Write-Host 'OpenCrew uninstaller' -ForegroundColor Cyan
Write-Host ''

if (-not $Runtime) {
    Write-Host 'Which runtime should OpenCrew be removed from?'
    Write-Host '  [1] Claude Code'
    Write-Host '  [2] OpenCode'
    Write-Host ''
    $choice = Read-Host 'Select [1/2]'
    if ($choice -eq '1') {
        $Runtime = 'claude'
    }
    elseif ($choice -eq '2') {
        $Runtime = 'opencode'
    }
    else {
        throw "Unrecognized selection. Re-run with -Runtime claude or -Runtime opencode."
    }
}

$confPath = Join-Path $RepoRoot "runtimes\$Runtime\runtime.conf"
if (-not (Test-Path -LiteralPath $confPath -PathType Leaf)) {
    throw "No runtime manifest found at $confPath"
}

$target = $null
foreach ($line in [System.IO.File]::ReadAllLines($confPath)) {
    if ($line.Trim() -match '^target=(.+)$') { $target = $Matches[1].Trim() }
}
if (-not $target) { throw "No 'target' declared in $confPath" }

$AgentsDir = Expand-HomePath $target
Write-Host "Target: $AgentsDir"
Write-Host ''

if (-not (Test-Path -LiteralPath $AgentsDir)) {
    Write-Host 'No agents directory found. Nothing to remove.'
    exit 0
}

$removed = @()

foreach ($name in $ManagedFiles) {
    $path = Join-Path $AgentsDir $name
    if (Test-Path -LiteralPath $path -PathType Leaf) {
        Remove-Item -LiteralPath $path -Force
        Write-Host "Removed: $name"
        $removed += $name
    }
    else {
        Write-Host "Not present: $name"
    }
}

Write-Host ''

if ($removed.Count -eq $ManagedFiles.Count) {
    Write-Host 'All OpenCrew agent files removed.'
}
elseif ($removed.Count -gt 0) {
    Write-Host 'OpenCrew agent files removed. Some files were not present.'
}
else {
    Write-Host 'No OpenCrew agent files were present.'
}

Write-Host 'The agents directory and any unrelated agents were left untouched.'
Write-Host ''
Write-Host 'Note: git-safety rules added to settings.json are left in place.'
Write-Host 'Remove them by hand if you no longer want them.'
