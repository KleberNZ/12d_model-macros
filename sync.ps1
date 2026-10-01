# ---------------------------------------------------------------------
# sync.ps1
#
# 1. Copy repository to SharePoint Knowledge Base
# 2. Copy .4do files to UserLib
# 3. Git add / commit / push
# ---------------------------------------------------------------------

$ErrorActionPreference = "Stop"

$repoRoot = "C:\12d\12dPL_Data\Code"

$knowledgeBaseRoot = "C:\Users\kprado\The Neil Group Ltd\12d Macro Knowledge Base - 12d_KB_MACROS"

$userLibRoot = "F:\DATA\12d\15.00\User_Lib"

function Ask-YesNo
{
    param([string]$Prompt)

    $answer = Read-Host $Prompt

    if ($answer.ToLower() -notin @("y","yes"))
    {
        Write-Host "Cancelled."
        exit
    }
}

try
{
    Write-Host ""
    Write-Host "=== Publishing to Knowledge Base ==="
    Write-Host ""

    robocopy `
        $repoRoot `
        $knowledgeBaseRoot `
        /E `
        /MIR `
        /XD ".git" ".vs" "Test"

    Write-Host ""
    Write-Host "=== Publishing .4do files to UserLib ==="
    Write-Host ""

    $macros = Get-ChildItem `
        $knowledgeBaseRoot `
        -Filter *.4do `
        -Recurse `
        -File

    foreach ($macro in $macros)
    {
        $relativePath = $macro.FullName.Substring($knowledgeBaseRoot.Length).TrimStart("\")

        $destination = Join-Path $userLibRoot $relativePath

        $destinationFolder = Split-Path $destination -Parent

        if (!(Test-Path $destinationFolder))
        {
            New-Item `
                -ItemType Directory `
                -Path $destinationFolder `
                -Force | Out-Null
        }

        Copy-Item `
            $macro.FullName `
            $destination `
            -Force

        Write-Host "Published: $relativePath"
    }

    Write-Host ""
    Write-Host "=== Git Status ==="
    Write-Host ""

    Set-Location $repoRoot

    git status --short

    Ask-YesNo "Stage all changes? (y/n)"

    git add -A

    git status --short

	# -----------------------------------------------------------------
	# COMMIT
	# -----------------------------------------------------------------

	Ask-YesNo "Commit changes? (y/n)"

	$message = Read-Host "Commit message"

	if ([string]::IsNullOrWhiteSpace($message))
	{
		$message = "Update macros $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
	}

	git commit -m $message

    Ask-YesNo "Push to GitHub? (y/n)"

    git push

    Write-Host ""
    Write-Host "====================================="
    Write-Host "Knowledge Base updated"
    Write-Host "UserLib updated"
    Write-Host "GitHub updated"
    Write-Host "====================================="
}
catch
{
    Write-Host ""
    Write-Host "ERROR:"
    Write-Host $_.Exception.Message
}