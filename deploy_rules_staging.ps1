<#
PowerShell helper to deploy proposed Firestore rules to a staging project
Usage:
  .\deploy_rules_staging.ps1 -ProjectId your-staging-project-id

What it does:
- Creates a timestamped backup of the current `firestore.rules` in the repo
- Replaces `firestore.rules` with `firestore.rules.proposed`
- Runs `firebase deploy --only firestore:rules --project <ProjectId>`
- If deployment fails, restores the backup and aborts

Important: run this from the repo root where `firestore.rules` is located.
#>

param(
  [Parameter(Mandatory=$true)]
  [string]$ProjectId
)

$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $MyInvocation.MyCommand.Definition
Set-Location $root

$timestamp = (Get-Date).ToString('yyyyMMdd-HHmmss')
$backup = "firestore.rules.backup.$timestamp"

if (-not (Test-Path -Path './firestore.rules.proposed')) {
  Write-Error "File 'firestore.rules.proposed' not found in $root. Place the proposed file there first."
  exit 1
}

Write-Host "Backing up current firestore.rules -> $backup"
Copy-Item -Path './firestore.rules' -Destination "./$backup" -Force

Write-Host "Applying proposed rules (copy firestore.rules.proposed -> firestore.rules)"
Copy-Item -Path './firestore.rules.proposed' -Destination './firestore.rules' -Force

try {
  Write-Host "Deploying rules to project: $ProjectId"
  & firebase deploy --only firestore:rules --project $ProjectId
  if ($LASTEXITCODE -ne 0) {
    throw "firebase deploy exited with code $LASTEXITCODE"
  }
  Write-Host "Deployment succeeded. Keep the backup at $backup if you need rollback."
} catch {
  Write-Error "Deployment failed: $_"
  Write-Host "Restoring backup firestore.rules from $backup"
  Copy-Item -Path "./$backup" -Destination './firestore.rules' -Force
  Write-Host "Attempting to redeploy previous rules to restore behavior"
  try {
    & firebase deploy --only firestore:rules --project $ProjectId
    Write-Host "Rollback deploy attempted. Check firebase CLI output for status."
  } catch {
    Write-Error "Rollback redeploy failed: $_. You may need to restore rules manually."
  }
  exit 1
}

Write-Host "DONE"
