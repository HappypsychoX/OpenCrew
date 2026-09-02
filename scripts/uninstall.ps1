# uninstall.ps1 - Remove OpenCrew-managed agent files from the global OpenCode
# agent directory. Only OpenCrew files are removed; the agents directory itself
# and any unrelated user-created agents are left untouched.

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$AgentsDir = Join-Path $HOME '.config\opencode\agents'

$ManagedFiles = @(
    'crew-lead.md',
    'repo-scout.md',
    'architect.md',
    'implementer.md',
    'reviewer.md',
    'grunt.md'
)

Write-Host 'OpenCrew uninstaller' -ForegroundColor Cyan

if (-not (Test-Path -LiteralPath $AgentsDir)) {
    Write-Host 'No OpenCode agents directory found. Nothing to remove.'
    Write-Host "  $AgentsDir"
    exit 0
}

$removed = @()
$notFound = @()

foreach ($name in $ManagedFiles) {
    $path = Join-Path $AgentsDir $name
    if (Test-Path -LiteralPath $path -PathType Leaf) {
        Remove-Item -LiteralPath $path -Force
        Write-Host "Removed: $name"
        $removed += $name
    }
    else {
        Write-Host "Not present: $name"
        $notFound += $name
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
