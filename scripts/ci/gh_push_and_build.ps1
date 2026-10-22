# Push Larpgram (Telegram-iOS-master) and trigger GitHub Actions CI.
$ErrorActionPreference = "Stop"
$RepoOwner = "cursos1470-hash"
$RepoName = "telegram-ios"
$RepoRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent

$env:Path = "C:\Program Files\Git\bin;C:\Program Files\GitHub CLI;" + $env:Path
Set-Location $RepoRoot

gh auth switch -u $RepoOwner 2>$null
if (-not (git remote get-url origin 2>$null)) {
  gh repo create "$RepoOwner/$RepoName" --private --source=. --remote=origin
}
git add -A
$status = git status --porcelain
if ($status) {
  git commit -m "Larpgram: CI and local changes"
}
git push -u origin HEAD:main
gh workflow run CI --repo "$RepoOwner/$RepoName" --ref main
gh run list --repo "$RepoOwner/$RepoName" -L 3
