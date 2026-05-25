/*---------------------------------------------------------------------
**   Programmer:           KLP
**   Date:                 2026-05-26
**   12D Model:            V15
**   Version:              001
**   Macro Name:           JunkCleanUp.4dm
**   Type:                 SOURCE
**
**   Brief description: BriefDescription
**
**
**   Brief description:
**   Silently removes unnecessary backup, report, temporary, and log files
**   from the current 12d project folder at project startup.
**
**---------------------------------------------------------------------
**   Description:
**   This macro is intended to be run automatically from the 12d
**   environment configuration when a project is opened.
**
**   It performs a background cleanup of common unwanted project files:
**     - all files inside the options_logs folder
**     - .bak backup files
**     - .Temp_mtf temporary files
**     - .4de files
**     - .rpt report files
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
#include "standard_library.H"
#include "size_of.h"

/*global variables*/{


}

// helper: delete files matching one wildcard pattern
Integer junk_delete_match(Text name_match)
{
    Integer rc;

    // Signature: Integer Delete_files(Text name_match)
    rc = Delete_files(name_match);

    return(rc);
}

void main(){

    Text project_folder;
    Integer rc;

    // Signature: Integer Get_project_folder(Text &name)
    rc = Get_project_folder(project_folder);

    if(rc != 0) {
        return;
    }

    // Delete files inside project options_logs folder.
    junk_delete_match(project_folder + "\\options_logs\\*.*");

    // Delete junk files in project working folder.
    junk_delete_match(project_folder + "\\*.bak");
    junk_delete_match(project_folder + "\\*.Temp_mtf");
    junk_delete_match(project_folder + "\\*.4de");
    junk_delete_match(project_folder + "\\*.rpt");

    return;
}