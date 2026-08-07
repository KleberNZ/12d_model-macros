/*---------------------------------------------------------------------
**   Programmer:           KLP
**   Date:                 2026-08-07
**   12D Model:            V15
**   Version:              001
**   Macro Name:           Change_ss_weight_panel.4dm
**   Type:                 SOURCE
**
**   Brief description: BriefDescription
**
**
**---------------------------------------------------------------------
**   Description: Description
**   Updates the display weight of selected Super Strings using
**   a user-specified weight value. Applies the new weight only to Super String
**   elements.
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

// ----------------------------- PANEL -----------------------------
void mainPanel(){

    Text panelName="Set Super String Weight";
    Panel              panel  = Create_panel              (panelName,TRUE);
    Vertical_Group     vgroup = Create_vertical_group     (-1         );
    Colour_Message_Box cmbMsg = Create_colour_message_box (""         );

    ///////////////////CREATE INPUT WIDGETS////////////////
    //TODO: create some input fields
    Source_Box sb_source = Create_source_box("Super Strings", cmbMsg, 0);
    Weight_Box wb_weight = Create_weight_box("Weight", cmbMsg);

    ///////////////ADDING BUTTONS ALONG THE BOTTOM///////////////////////////
    Horizontal_Group bgroup = Create_button_group();
    Button process     = Create_button       ("&Process" ,"process");
    Button finish      = Create_finish_button("Finish"   ,"Finish" );
    Button help_button = Create_help_button  (panel      ,"Help"   );

    Append(process     ,bgroup);
    Append(finish      ,bgroup);
    Append(help_button ,bgroup);

    ///////////////ADDING WIDGETS TO PANEL///////////////////////////
    //TODO: add your widgets to vgroup

    Append(sb_source,vgroup);
    Append(wb_weight,vgroup);

    Append(cmbMsg      ,vgroup);
    Append(bgroup      ,vgroup);

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
        case "set_focus" :
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
            if(cmd == "Panel Quit")  doit = 0;
            if(cmd == "Panel About") about_panel(panel);
        }
        break;

        case Get_id(process) :
        {
            if(cmd == "process")
            {
                //TODO: declare your widget variables
                Dynamic_Element de_source;
                if (Validate(sb_source, de_source) == FALSE)
                {
                    Set_error_message(sb_source, "");
                    break;
                }

                Integer source_count = 0;
                Get_number_of_items(de_source, source_count);

                if (source_count <= 0)
                {
                    Set_error_message(sb_source, "No Super Strings selected");
                    break;
                }

                Real weight;
                if (Validate(wb_weight, weight) == FALSE)
                {
                    break;
                }
                //TODO: do calc
                Integer modified = 0;
                Integer skipped = 0;

                for (Integer i = 1; i <= source_count; i++)
                {
                    Element e;

                    if (Get_item(de_source, i, e) != 0)
                        continue;

                    Text element_type = "";
                    Get_type(e, element_type);

                    if (element_type != "Super")
                    {
                        skipped++;
                        continue;
                    }

                    if (Set_weight(e, weight) == 0)
                    {
                        modified++;
                    }
                }
            }
        }
        break;

        default :
        {
            if(cmd == "Finish") doit = 0;
        }
        break;
        }
    }
}

// ----------------------------- MAIN -----------------------------
void main(){

    //TODO: do pre-panel checks here

    mainPanel();
}