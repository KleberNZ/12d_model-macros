$root = "C:\12d\12dPL_Data\Code"
$vscode = "C:\12d\VSCode-12dPL\Code.exe"
$profile = "12dPL"

$name = Read-Host "Enter macro name (or type 'q' to cancel)"

if ([string]::IsNullOrWhiteSpace($name) -or $name.Trim().ToLower() -in @('q','quit','exit')) {
    Write-Host "Operation cancelled."
    exit 0
}

if ($name.IndexOfAny(([System.IO.Path]::GetInvalidFileNameChars())) -ge 0) {
    Write-Host "Macro name contains invalid file/folder characters."
    exit 1
}

$folderPath = Join-Path $root $name
$workspacePath = Join-Path $folderPath "$name.code-workspace"
$macroPath = Join-Path $folderPath "$name.4dm"
$readmePath = Join-Path $folderPath "README.md"

if (Test-Path $folderPath) {
    Write-Host "Folder already exists: $folderPath"
    exit 1
}

New-Item -ItemType Directory -Path $folderPath | Out-Null

$workspaceContent = @'
{
	"folders": [
		{
			"path": "."
		},
		{
			"path": "../../include"
		}
	],
	"settings": {}
}
'@

$today = Get-Date -Format "yy/MM/dd"

$macroContent = @"
/*---------------------------------------------------------------------
**   Programmer:user_name
**   Date:$today             
**   12D Model:            Vversion
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
#include "..\\..\\include/standard_library.H"
#include "..\\..\\include/size_of.H"
/*global variables*/{


}

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
void main(){

    // do some checks before you go to the main panel


    mainPanel();
}
"@

$readmeContent = @"
# $name

## Purpose
Describe what the macro does.

## Inputs
Describe panel inputs / selected data.

## Outputs
Describe created or modified data.

## Notes
Add compile/runtime notes here.
"@

Set-Content -Path $workspacePath -Value $workspaceContent -Encoding UTF8
Set-Content -Path $macroPath -Value $macroContent -Encoding UTF8
Set-Content -Path $readmePath -Value $readmeContent -Encoding UTF8

Write-Host "Created:"
Write-Host "  Folder: $folderPath"
Write-Host "  Workspace: $workspacePath"
Write-Host "  Macro file: $macroPath"
Write-Host "  README: $readmePath"

Start-Process $vscode -ArgumentList "--profile", $profile, "`"$workspacePath`""

# ---------------- GIT AUTO ADD + COMMIT ----------------
try {
    Set-Location $root

    git add "$folderPath"

    $commitMsg = "Add macro: $name"
    git commit -m $commitMsg

    Write-Host "Git: added and committed '$commitMsg'"
}
catch {
    Write-Host "Git operation failed. You may need to commit manually."
}