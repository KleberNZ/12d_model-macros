# Set working directory
Set-Location "C:\12d\12dPL_Data\Code"

# Check for changes
$status = git status --porcelain

if (-not $status) {
    Write-Host "No changes to commit."
    exit
}

# Add changes
git add .

# Commit with timestamp
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
git commit -m "Auto commit: $timestamp"

# Push to GitHub
git push

Write-Host "Changes committed and pushed."