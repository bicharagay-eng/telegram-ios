# GitHub: bicharagay-eng/telegram-ios — Telegram stock (sem LARP/Swiftgram), IPA unsigned.
#
#   cd "C:\Users\twink\Desktop\larpgram ipa\Telegram-iOS-master"
#   .\scripts\ci\gh_push_and_build.ps1

param(
    [switch]$LoginOnly,
    [switch]$SkipPush
)

$ErrorActionPreference = "Stop"
$RepoRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
Set-Location $RepoRoot

$RepoOwner = "bicharagay-eng"
$RepoName = "telegram-ios"
$FullRepo = "$RepoOwner/$RepoName"
$WorkflowName = "CI"
$ArtifactName = "Telegram-unsigned-ipa"

function Invoke-Gh {
    param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Args)
    $prev = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    & gh @Args
    $code = $LASTEXITCODE
    $ErrorActionPreference = $prev
    if ($code -ne 0) { throw "gh exited with $code (args: gh $($Args -join ' '))" }
}

function Test-GhAuth {
    $prev = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    & gh auth status *> $null
    $ok = ($LASTEXITCODE -eq 0)
    $ErrorActionPreference = $prev
    return $ok
}

function Get-GhActiveLogin {
    $prev = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    $login = gh api user -q .login 2>$null
    $ErrorActionPreference = $prev
    if ($LASTEXITCODE -ne 0) { return $null }
    return $login
}

function Invoke-GhBrowserLogin {
    Write-Host "=== GitHub login: use $RepoOwner ===" -ForegroundColor Cyan
    $prev = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    gh auth login -h github.com -p https -w -s repo,workflow,read:org
    if ($LASTEXITCODE -ne 0) { throw "gh auth login failed" }
    $ErrorActionPreference = $prev
}

function Ensure-GhLoggedInAsOwner {
    Remove-Item Env:GH_TOKEN -ErrorAction SilentlyContinue
    Remove-Item Env:GITHUB_TOKEN -ErrorAction SilentlyContinue
    if (-not (Test-GhAuth)) { Invoke-GhBrowserLogin }
    $active = Get-GhActiveLogin
    if ($active -eq $RepoOwner) {
        Write-Host "GitHub: $active" -ForegroundColor Green
        return
    }
    if ($active) {
        Write-Host "Current: $active, need: $RepoOwner" -ForegroundColor Yellow
        $prev = $ErrorActionPreference
        $ErrorActionPreference = "Continue"
        gh auth switch -u $RepoOwner 2>$null | Out-Null
        $ErrorActionPreference = $prev
        if ((Get-GhActiveLogin) -eq $RepoOwner) { return }
    }
    gh auth logout -h github.com 2>$null | Out-Null
    Invoke-GhBrowserLogin
    if ((Get-GhActiveLogin) -ne $RepoOwner) {
        throw "Login as $RepoOwner required (gh auth login)."
    }
}

if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    throw "Install GitHub CLI: winget install GitHub.cli"
}

Ensure-GhLoggedInAsOwner
Invoke-Gh auth setup-git

if ($LoginOnly) {
    Write-Host "OK. Run again without -LoginOnly to push and build."
    exit 0
}

if (-not (Test-Path (Join-Path $RepoRoot ".git"))) {
    Write-Host "Initializing git repository..."
    git init -b main
    git add -A
    git commit -m "Telegram iOS stock: CI sideload (api 8, sem mods LARP)."
}

Write-Host "Remote -> https://github.com/$FullRepo.git"
git remote remove origin 2>$null
git remote add origin "https://github.com/$FullRepo.git"

$prev = $ErrorActionPreference
$ErrorActionPreference = "Continue"
gh repo view $FullRepo 2>$null | Out-Null
$repoOk = ($LASTEXITCODE -eq 0)
$ErrorActionPreference = $prev
if (-not $repoOk) {
    Write-Host "Creating private repo $FullRepo ..."
    gh repo create $FullRepo --private --source=. --remote=origin
    git remote set-url origin "https://github.com/$FullRepo.git"
}

if (-not $SkipPush) {
    Write-Host "Pushing main..."
    git add -A
    $status = git status --porcelain
    if ($status) {
        git commit -m "CI: Telegram stock unsigned IPA (bicharagay-eng)."
    }
    git push -u origin main
}

Write-Host "Starting workflow: $WorkflowName"
Invoke-Gh workflow run $WorkflowName --repo $FullRepo --ref main
Start-Sleep -Seconds 4
Invoke-Gh run list --repo $FullRepo --workflow=$WorkflowName --limit 3
Write-Host ""
Write-Host "IPA artifact: $ArtifactName"
Write-Host "  gh run download --repo $FullRepo --name $ArtifactName"
Write-Host "https://github.com/$FullRepo/actions"
