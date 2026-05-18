# ---------------------------------------------------------------------
# sync.ps1
#
# Safer Git sync helper for:
#   C:\12d\12dPL_Data\Code
#
# This script:
#   - Shows current Git status
#   - Warns about ignored/generated file types
#   - Asks before staging
#   - Shows staged changes
#   - Asks before committing
#   - Asks before pushing
#
# It does NOT blindly commit without review.
# ---------------------------------------------------------------------

$ErrorActionPreference = "Stop"

$repoRoot = "C:\12d\12dPL_Data\Code"

function Stop-IfNotYes {
    param(
        [string]$Prompt
    )

    $answer = Read-Host $Prompt

    if ($answer.ToLower() -notin @("y", "yes")) {
        Write-Host "Cancelled."
        exit 0
    }
}

try {
    if (-not (Test-Path $repoRoot)) {
        throw "Repo folder not found: $repoRoot"
    }

    Set-Location $repoRoot

    $insideRepo = git rev-parse --is-inside-work-tree 2>$null

    if ($LASTEXITCODE -ne 0 -or $insideRepo -ne "true") {
        throw "Not inside a Git repository: $repoRoot"
    }

    Write-Host ""
    Write-Host "Repo:"
    Write-Host "  $repoRoot"
    Write-Host ""

    # -----------------------------------------------------------------
    # CHECK STATUS
    # -----------------------------------------------------------------

    $status = git status --short

    if (-not $status) {
        Write-Host "No changes to commit."
        exit 0
    }

    Write-Host "Current Git status:"
    Write-Host ""
    git status --short
    Write-Host ""

    # -----------------------------------------------------------------
    # CHECK FOR TRACKED FILE TYPES THAT SHOULD USUALLY NOT BE TRACKED
    # -----------------------------------------------------------------

    Write-Host "Checking for tracked generated/local file types..."
    $trackedGenerated = git ls-files "*.4do" "*.4dl" "*.tmp" "*.pdf" "*.json" "*.txt" "*.log"

    if ($trackedGenerated) {
        Write-Host ""
        Write-Host "WARNING: The following generated/local file types are tracked by Git:"
        Write-Host ""
        $trackedGenerated
        Write-Host ""
        Write-Host "Review these before continuing."
        Stop-IfNotYes "Continue anyway? y/n"
    }
    else {
        Write-Host "No tracked generated/local file types found."
    }

    Write-Host ""

    # -----------------------------------------------------------------
    # STAGE
    # -----------------------------------------------------------------

    Stop-IfNotYes "Stage all current changes with git add -A? y/n"

    git add -A

    Write-Host ""
    Write-Host "Staged changes:"
    Write-Host ""
    git status --short
    Write-Host ""

    # -----------------------------------------------------------------
    # COMMIT
    # -----------------------------------------------------------------

    Stop-IfNotYes "Commit these staged changes? y/n"

    $message = Read-Host "Enter commit message, or leave blank for timestamp message"

    if ([string]::IsNullOrWhiteSpace($message)) {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $message = "Update macros: $timestamp"
    }

    git commit -m $message

    # -----------------------------------------------------------------
    # PUSH
    # -----------------------------------------------------------------

    Write-Host ""
    Stop-IfNotYes "Push to GitHub now? y/n"

    git push

    Write-Host ""
    Write-Host "Done. Changes committed and pushed."
    Write-Host ""
    git status --short
}
catch {
    Write-Host ""
    Write-Host "ERROR:"
    Write-Host $_.Exception.Message
    Write-Host ""
    exit 1
}