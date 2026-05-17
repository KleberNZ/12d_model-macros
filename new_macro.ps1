# ---------------------------------------------------------------------
# new_macro.ps1
#
# Creates a new 12dPL macro folder under:
#   C:\12d\12dPL_Data\Code
#
# Each macro gets:
#   <macro_name>.4dm
#   README.md
#
# Opens VS Code using the central workspace:
#   C:\12d\12dPL_Data
#
# Does NOT create individual .code-workspace files.
# ---------------------------------------------------------------------

$ErrorActionPreference = "Stop"

try {
    # ----------------------------- CONFIG -----------------------------

    $workspaceRoot = "C:\12d\12dPL_Data"
    $codeRoot      = Join-Path $workspaceRoot "Code"
    $includeRoot   = Join-Path $workspaceRoot "include"

    $vscode  = "C:\12d\VSCode-12dPL\Code.exe"
    $profile = "12dPL"

    # ----------------------------- PRE-CHECKS -----------------------------

    if (-not (Test-Path $workspaceRoot)) {
        throw "Workspace root not found: $workspaceRoot"
    }

    if (-not (Test-Path $codeRoot)) {
        Write-Host "Code folder not found. Creating: $codeRoot"
        New-Item -ItemType Directory -Path $codeRoot | Out-Null
    }

    if (-not (Test-Path $includeRoot)) {
        throw "Include folder not found: $includeRoot"
    }

    $standardLibrary = Join-Path $includeRoot "standard_library.H"
    $sizeOfHeader    = Join-Path $includeRoot "size_of.h"

    if (-not (Test-Path $standardLibrary)) {
        throw "Missing include file: $standardLibrary"
    }

    if (-not (Test-Path $sizeOfHeader)) {
        throw "Missing include file: $sizeOfHeader"
    }

    # ----------------------------- USER INPUT -----------------------------

    $name = Read-Host "Enter macro name, for example My_New_Macro_panel, or type q to cancel"

    if ([string]::IsNullOrWhiteSpace($name)) {
        Write-Host "No macro name entered. Operation cancelled."
        exit 0
    }

    $name = $name.Trim()

    if ($name.ToLower() -in @("q", "quit", "exit", "cancel")) {
        Write-Host "Operation cancelled."
        exit 0
    }

    if ($name.ToLower().EndsWith(".4dm")) {
        $name = [System.IO.Path]::GetFileNameWithoutExtension($name)
    }

    $invalidChars = [System.IO.Path]::GetInvalidFileNameChars()

    if ($name.IndexOfAny($invalidChars) -ge 0) {
        throw "Invalid macro name. The name contains characters that are not allowed in Windows file/folder names: $name"
    }

    if ($name -match "\s") {
        Write-Host "Macro name contains spaces. This is not recommended."
        $continue = Read-Host "Continue anyway? y/n"

        if ($continue.ToLower() -ne "y") {
            Write-Host "Operation cancelled."
            exit 0
        }
    }

    # ----------------------------- PATHS -----------------------------

    $folderPath = Join-Path $codeRoot $name
    $macroPath  = Join-Path $folderPath "$name.4dm"
    $readmePath = Join-Path $folderPath "README.md"

    if (Test-Path $folderPath) {
        throw "Macro folder already exists: $folderPath"
    }

    # ----------------------------- CREATE FOLDER -----------------------------

    New-Item -ItemType Directory -Path $folderPath | Out-Null

    # ----------------------------- TEMPLATE DATA -----------------------------

    $today = Get-Date -Format "yyyy-MM-dd"

    # ----------------------------- CREATE MACRO TEMPLATE -----------------------------

	$macroContent = @"
/*---------------------------------------------------------------------
**   Programmer:           KLP
**   Date:                 $today
**   12D Model:            V15
**   Version:              001
**   Macro Name:           $name.4dm
**   Type:                 SOURCE
**
**   Brief description: BriefDescription
**
**
**---------------------------------------------------------------------
**   Description: Description
**
**
**---------------------------------------------------------------------
**   Update/Modification
**
**  This macro may be reproduced, modified and used without restriction.
**  The author grants all users Unlimited Use of the source code and any 
**  associated files, for no fee. Unlimited Use includes compiling, running,
**  and modifying the code for individual or integrated purposes.
**  The author also grants 12d Solutions Pty Ltd and other users permission
**  to incorporate this macro, in whole or in part, into other macros or programs.
**---------------------------------------------------------------------
*/
#define DEBUG_FILE      0
#define ECHO_DEBUG_FILE 0
#define ECHO_LINE_NO    0
 
#define BUILD "version.0.001"
 
// ----------------------------- INCLUDES -----------------------------
#include "standard_library.h"
#include "size_of.h"
/*global variables*/{


}
// ----------------------------- PANEL -----------------------------
void mainPanel(){
 
    Text panelName="PanelName";
    Panel              panel  = Create_panel              (panelName,TRUE);
    Vertical_Group     vgroup = Create_vertical_group     (-1         );
    Colour_Message_Box cmbMsg = Create_colour_message_box (""         );

    ///////////////////CREATE INPUT WIDGETS////////////////
    //TODO: create some input fields
    
    ///////////////ADDING BUTTONS ALONG THE BOTTOM///////////////////////////
    Horizontal_Group bgroup = Create_button_group();
    Button process     = Create_button       ("&Process" ,"process");
    Button finish      = Create_finish_button("Finish"   ,"Finish" );
    Button help_button = Create_help_button  (panel      ,"Help"   );
    Append(process      ,bgroup);
    Append(finish       ,bgroup);
    Append(help_button  ,bgroup);
    ///////////////ADDING WIDGETS TO PANEL///////////////////////////
    //TODO: add your widgets to vgroup

    //Append(widget1    ,vgroup);
    //Append(widget2    ,vgroup);


    Append(cmbMsg    ,vgroup);
    Append(bgroup    ,vgroup);


    Append(vgroup,panel);
    Show_widget(panel);
	// ----------------------------- EVENT LOOP -----------------------------
    Integer doit = 1;
    while(doit)
    {
        Text cmd="",msg = "";
        Integer id,ret = Wait_on_widgets(id,cmd,msg);
 
        switch(cmd)
        {
        case "keystroke" :
        case "set_focus"  :
        case "kill_focus" :
        {
            continue;
        }
        break;
        case "CodeShutdown" :
        {
            Set_exit_code(cmd);
        }
        break;
        }
        switch(id)
        {
        case Get_id(panel) :
        {
            if(cmd == "Panel Quit") doit = 0;
            if(cmd == "Panel About") about_panel(panel);
        }
        break; 
        case Get_id(process) :
        {
            if(cmd == "process")
            {
                //TODO: declare your widget variables



                //TODO: validate widgets




                //TODO: do calc




                Set_data(cmbMsg ,"Process finished");
            }
        }
        break;
        default :
        {
            if(cmd == "Finish")doit = 0;
        }
        break; 
        }
    }
}
// ----------------------------- MAIN -----------------------------
void main(){

    // do some checks before you go to the main panel


    mainPanel();
}
"@

    # ----------------------------- CREATE README -----------------------------

    $readmeContent = @"
# $name

## Purpose

TODO: Describe what this macro does.

## Location

C:\12d\12dPL_Data\Code\$name

## Source

$name.4dm

## Compile Method

Open VS Code from:

C:\12d\12dPL_Data

Then open:

Code\$name\$name.4dm

Compile using:

Ctrl+Shift+P > 12dPL: Compile Current File

Do not use F7 unless the old task system has been deliberately updated.

## Include Setup

This macro uses clean includes:

#include "standard_library.H"
#include "size_of.h"

These rely on the central workspace setting:

12dpl.compiler.includePaths = C:\12d\12dPL_Data\include

## Inputs

TODO: Describe user inputs, selected models, strings, files, or panel options.

## Outputs

TODO: Describe created/modified models, strings, files, reports, or logs.

## Notes

TODO: Add implementation notes, assumptions, limitations, and testing notes.

## Revision History

| Version | Date | Notes |
|---|---|---|
| 001 | $today | Initial macro |
"@

    # ----------------------------- WRITE FILES -----------------------------

    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)

    [System.IO.File]::WriteAllText($macroPath,  $macroContent,  $utf8NoBom)
    [System.IO.File]::WriteAllText($readmePath, $readmeContent, $utf8NoBom)

    Write-Host ""
    Write-Host "Created new macro:"
    Write-Host "  Folder: $folderPath"
    Write-Host "  Macro:  $macroPath"
    Write-Host "  README: $readmePath"
    Write-Host ""

    # ----------------------------- OPEN VS CODE -----------------------------

    if (Test-Path $vscode) {
        Write-Host "Opening VS Code central workspace:"
        Write-Host "  $workspaceRoot"
        Write-Host ""

        Start-Process $vscode -ArgumentList "--profile", $profile, "`"$workspaceRoot`"", "`"$macroPath`""
    }
    else {
        Write-Host "VS Code executable not found:"
        Write-Host "  $vscode"
        Write-Host "Macro was created, but VS Code was not opened."
    }

    # ----------------------------- GIT STAGE ONLY -----------------------------

    try {
        Set-Location $workspaceRoot

        $gitCheck = git rev-parse --is-inside-work-tree 2>$null

        if ($LASTEXITCODE -eq 0 -and $gitCheck -eq "true") {
            git add "$folderPath"

            Write-Host ""
            Write-Host "Git:"
            Write-Host "  New macro folder staged."
            Write-Host "  Review before committing."
        }
        else {
            Write-Host ""
            Write-Host "Git:"
            Write-Host "  $workspaceRoot is not inside a Git repository."
            Write-Host "  Skipping git add."
        }
    }
    catch {
        Write-Host ""
        Write-Host "Git:"
        Write-Host "  Git staging failed or Git is not available."
        Write-Host "  You can add/commit manually later."
    }

    Write-Host ""
    Write-Host "Done."
}
catch {
    Write-Host ""
    Write-Host "ERROR:"
    Write-Host $_.Exception.Message
    Write-Host ""
    Write-Host "Script stopped before completing."
    Write-Host ""
    Read-Host "Press Enter to close"
    exit 1
}

Read-Host "Press Enter to close"