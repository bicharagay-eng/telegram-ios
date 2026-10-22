# Push Larpgram to backup GitHub accounts and trigger CI where runners may be free.
$ErrorActionPreference = "Stop"
$env:Path = "C:\Program Files\Git\bin;C:\Program Files\GitHub CLI;" + $env:Path
$Root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
Set-Location $Root

$remotes = @(
  @{ User = "cursos1470-hash"; Repo = "telegram-ios" }
  @{ User = "bicharagay-eng"; Repo = "telegram-ios" }
)

foreach ($r in $remotes) {
  $url = "https://github.com/$($r.User)/$($r.Repo).git"
  $name = "backup-$($r.User)"
  git remote remove $name 2>$null
  git remote add $name $url
  Write-Host "Pushing to $url ..."
  git push $name HEAD:main --force-with-lease
  gh auth switch -u $r.User 2>$null
  gh workflow run CI --repo "$($r.User)/$($r.Repo)" -f runner_label=macos-26 2>$null
  gh run list --repo "$($r.User)/$($r.Repo)" -L 1
}
