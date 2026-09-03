# install.ps1 - Render and install OpenCrew agents for a chosen runtime.
#
# Usage:
#   .\scripts\install.ps1                      # prompts for runtime
#   .\scripts\install.ps1 -Runtime claude
#   .\scripts\install.ps1 -Runtime opencode -Force

[CmdletBinding()]
param(
    [ValidateSet('claude', 'opencode')]
    [string]$Runtime,

    # Where runtime-level permission rules are written.
    #   project - <current directory>\.claude\settings.json  (default)
    #   user    - the runtime's user-global settings.json
    #   none    - do not write permission rules at all
    [ValidateSet('project', 'user', 'none')]
    [string]$PermissionScope = 'project',

    [switch]$Force
)

$ErrorActionPreference = 'Stop'

$RepoRoot = Split-Path -Parent $PSScriptRoot

# Agent name -> source file (relative to repo root). Names are identical across
# runtimes by design; only frontmatter and model assignment vary.
$Agents = [ordered]@{
    'crew-lead'   = 'crew-lead\body.md'
    'repo-scout'  = 'agents\repo-scout.md'
    'architect'   = 'agents\architect.md'
    'implementer' = 'agents\implementer.md'
    'reviewer'    = 'agents\reviewer.md'
    'grunt'       = 'agents\grunt.md'
}

function Expand-HomePath {
    param([string]$Path)
    $expanded = $Path -replace '^~', $HOME
    return $expanded -replace '/', '\'
}

function Read-RuntimeConf {
    param([string]$Path)
    $conf = @{}
    foreach ($line in [System.IO.File]::ReadAllLines($Path)) {
        $trimmed = $line.Trim()
        if ($trimmed -eq '' -or $trimmed.StartsWith('#')) { continue }
        $idx = $trimmed.IndexOf('=')
        if ($idx -lt 1) { continue }
        $key = $trimmed.Substring(0, $idx).Trim()
        $val = $trimmed.Substring($idx + 1).Trim()
        $conf[$key] = $val
    }
    return $conf
}

function Read-AgentSource {
    param([string]$Path)
    $text = [System.IO.File]::ReadAllText($Path)
    $normalized = $text -replace "`r`n", "`n"
    if (-not $normalized.StartsWith("---`n")) {
        throw "Missing frontmatter in $Path"
    }
    $end = $normalized.IndexOf("`n---`n", 3)
    if ($end -lt 0) { throw "Unterminated frontmatter in $Path" }

    $fm = $normalized.Substring(4, $end - 3)
    $body = $normalized.Substring($end + 5).TrimStart("`n")

    $result = @{ Description = ''; Capability = ''; Body = $body }
    foreach ($line in $fm -split "`n") {
        if ($line -match '^description:\s*(.+)$') { $result.Description = $Matches[1].Trim() }
        if ($line -match '^capability:\s*(.+)$') { $result.Capability = $Matches[1].Trim() }
    }
    if ($result.Capability -eq '') { throw "No 'capability' declared in $Path" }
    return $result
}

function Write-Utf8NoBom {
    param([string]$Path, [string]$Content)
    $encoding = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($Path, $Content, $encoding)
}

Write-Host 'OpenCrew installer' -ForegroundColor Cyan
Write-Host ''

# --- Runtime selection -------------------------------------------------------

if (-not $Runtime) {
    Write-Host 'Which runtime should fill the crew-lead role?'
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

$RuntimeDir = Join-Path $RepoRoot "runtimes\$Runtime"
if (-not (Test-Path -LiteralPath $RuntimeDir)) {
    throw "No runtime manifest found at $RuntimeDir"
}

$conf = Read-RuntimeConf (Join-Path $RuntimeDir 'runtime.conf')
$AgentsDir = Expand-HomePath $conf['target']
$DisplayName = $conf['display']

Write-Host "Runtime: $DisplayName" -ForegroundColor Cyan
Write-Host "Target:  $AgentsDir"
Write-Host ''

# --- Runtime detection -------------------------------------------------------

$found = $false
if ($conf.ContainsKey('detect_command')) {
    if ($null -ne (Get-Command $conf['detect_command'] -ErrorAction SilentlyContinue)) { $found = $true }
}
if (-not $found -and $conf.ContainsKey('detect_dir')) {
    if (Test-Path -LiteralPath (Expand-HomePath $conf['detect_dir'])) { $found = $true }
}
if (-not $found) {
    Write-Warning "$DisplayName does not appear to be installed. Continuing anyway."
}

if (-not (Test-Path -LiteralPath $AgentsDir)) {
    New-Item -ItemType Directory -Path $AgentsDir -Force | Out-Null
    Write-Host "Created directory: $AgentsDir"
}

# --- Render ------------------------------------------------------------------

$delegationPath = Join-Path $RuntimeDir 'delegation.md'
$delegation = ''
if (Test-Path -LiteralPath $delegationPath) {
    $delegation = ([System.IO.File]::ReadAllText($delegationPath) -replace "`r`n", "`n").Trim()
}

$delegationInline = ''
if ($conf.ContainsKey('delegation_inline')) { $delegationInline = $conf['delegation_inline'] }

$installed = @()
$skipped = @()

foreach ($name in $Agents.Keys) {
    $srcPath = Join-Path $RepoRoot $Agents[$name]
    if (-not (Test-Path -LiteralPath $srcPath -PathType Leaf)) {
        Write-Warning "Source not found, skipping: $($Agents[$name])"
        $skipped += $name
        continue
    }

    $src = Read-AgentSource $srcPath

    # A runtime may override a single agent's frontmatter by name when the
    # capability class is not precise enough (e.g. grunt is deliberately
    # narrower than implementer). Per-agent file wins; class is the default.
    $fmPath = Join-Path $RuntimeDir "frontmatter\$name.yml"
    if (-not (Test-Path -LiteralPath $fmPath -PathType Leaf)) {
        $fmPath = Join-Path $RuntimeDir "frontmatter\$($src.Capability).yml"
    }
    if (-not (Test-Path -LiteralPath $fmPath -PathType Leaf)) {
        throw "Runtime '$Runtime' has no template for '$name' or capability '$($src.Capability)' (expected $fmPath)"
    }

    $modelKey = "model.$name"
    if (-not $conf.ContainsKey($modelKey)) {
        throw "Runtime '$Runtime' does not assign a model for '$name' (missing $modelKey in runtime.conf)"
    }

    # Temperature is optional and per-agent; runtimes that don't expose the
    # knob (Claude Code) simply omit {{TEMPERATURE}} from their templates.
    $tempKey = "temperature.$name"
    $temperature = '0.1'
    if ($conf.ContainsKey($tempKey)) { $temperature = $conf[$tempKey] }

    $frontmatter = ([System.IO.File]::ReadAllText($fmPath) -replace "`r`n", "`n")
    $frontmatter = $frontmatter.Replace('{{NAME}}', $name)
    $frontmatter = $frontmatter.Replace('{{DESCRIPTION}}', $src.Description)
    $frontmatter = $frontmatter.Replace('{{MODEL}}', $conf[$modelKey])
    $frontmatter = $frontmatter.Replace('{{TEMPERATURE}}', $temperature)

    $body = $src.Body.Replace('{{DELEGATION}}', $delegation)
    $body = $body.Replace('{{DELEGATION_INLINE}}', $delegationInline)
    $body = $body.Replace('{{RUNTIME}}', $DisplayName)
    $rendered = "---`n" + $frontmatter.TrimEnd("`n") + "`n---`n`n" + $body.TrimEnd("`n") + "`n"

    # A typo'd or unknown token would otherwise ship verbatim into an agent
    # file, silently. Fail loudly instead.
    if ($rendered -match '\{\{[A-Z_]+\}\}') {
        throw "Unsubstituted token $($Matches[0]) while rendering '$name' for runtime '$Runtime'"
    }

    $dstPath = Join-Path $AgentsDir "$name.md"
    if ((Test-Path -LiteralPath $dstPath -PathType Leaf) -and (-not $Force)) {
        $answer = Read-Host "  $name.md already exists. Replace? [y/N]"
        if ($answer -notmatch '^(y|yes)$') {
            Write-Host "  Skipped $name.md."
            $skipped += $name
            continue
        }
    }

    Write-Utf8NoBom -Path $dstPath -Content $rendered
    $installed += $name
}

# --- Runtime-level permissions ----------------------------------------------

$permPath = Join-Path $RuntimeDir 'settings-permissions.json'
if ((Test-Path -LiteralPath $permPath -PathType Leaf) -and ($PermissionScope -ne 'none')) {
    # Project scope keeps the deny rules confined to the repository you are
    # working in. User scope applies them to every session on the machine,
    # which is rarely what you want for a tool-scoped safety rule.
    if ($PermissionScope -eq 'project') {
        $settingsDir = Join-Path (Get-Location).Path '.claude'
    }
    else {
        $settingsDir = Split-Path -Parent $AgentsDir
    }
    if (-not (Test-Path -LiteralPath $settingsDir)) {
        New-Item -ItemType Directory -Path $settingsDir -Force | Out-Null
    }
    $settingsPath = Join-Path $settingsDir 'settings.json'
    $required = (Get-Content -LiteralPath $permPath -Raw | ConvertFrom-Json).permissions.deny

    $settings = $null
    if (Test-Path -LiteralPath $settingsPath -PathType Leaf) {
        $settings = Get-Content -LiteralPath $settingsPath -Raw | ConvertFrom-Json
    }
    if ($null -eq $settings) { $settings = [PSCustomObject]@{} }
    if ($null -eq $settings.PSObject.Properties['permissions']) {
        $settings | Add-Member -NotePropertyName 'permissions' -NotePropertyValue ([PSCustomObject]@{})
    }
    if ($null -eq $settings.permissions.PSObject.Properties['deny']) {
        $settings.permissions | Add-Member -NotePropertyName 'deny' -NotePropertyValue @()
    }

    $deny = @($settings.permissions.deny)
    $added = @()
    foreach ($rule in $required) {
        if ($deny -notcontains $rule) {
            $deny += $rule
            $added += $rule
        }
    }

    if ($added.Count -gt 0) {
        $settings.permissions.deny = $deny
        Write-Utf8NoBom -Path $settingsPath -Content (($settings | ConvertTo-Json -Depth 10) + "`n")
        Write-Host ''
        Write-Host "Added git-safety rules ($PermissionScope scope):" -ForegroundColor Green
        Write-Host "  $settingsPath"
        foreach ($rule in $added) { Write-Host "  deny $rule" }
        if ($PermissionScope -eq 'project') {
            Write-Host '  Re-run in each repository where you want these rules.'
        }
    }
    else {
        Write-Host ''
        Write-Host "Git-safety rules already present in $settingsPath"
    }
}

# --- Report ------------------------------------------------------------------

Write-Host ''
if ($installed.Count -gt 0) {
    Write-Host 'Installed:' -ForegroundColor Green
    foreach ($name in $installed) { Write-Host "  $name" }
}
if ($skipped.Count -gt 0) {
    Write-Host 'Skipped:' -ForegroundColor Yellow
    foreach ($name in $skipped) { Write-Host "  $name" }
}

Write-Host ''
Write-Host "OpenCrew installed for $DisplayName."
Write-Host ''
Write-Host 'Try:'
Write-Host ''
Write-Host '  @crew-lead Explain how authentication works in this repository.'
