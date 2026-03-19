/*---------------------------------------------------------------------
**   Programmer:KLeber Lessa do Prado
**   Date:04/11/25             
**   12D Model:            V15
**   Version:              001
**   Macro Name:           LC_creator_panel.4dm
**   Type:                 SOURCE
**
**   Brief description: Create 2D LC super strings from lot-offset vertex to
**            perpendicular projection on drainage pipe.
**
**
**---------------------------------------------------------------------
**   Description: Description
**
**
**---------------------------------------------------------------------
**   Update/Modification
**
**
**   (C) Copyright 2013-2025 by your_company Pty Ltd. All Rights
**       Reserved.
**   This macro, or parts thereof, may not be reproduced in any form
**   without permission of your_company.
**---------------------------------------------------------------------
*/
#define DEBUG_FILE      0
#define ECHO_DEBUG_FILE 0
#define ECHO_LINE_NO    0
 
#define BUILD "15.0.001"
 
// ----------------------------- INCLUDES -----------------------------
#include "..\\..\\include/standard_library.H"
#include "..\\..\\include/size_of.H"
#include "..\\..\\include/set_ups.H"

/*global variables*/{

}

// ---------- Helpers ----------

void mainPanel(){
 
    Text panelName="Lot Connections Creator";
    Panel              panel  = Create_panel              (panelName,TRUE);
    Vertical_Group     vgroup = Create_vertical_group     (-1         );
    Colour_Message_Box cmbMsg = Create_colour_message_box (""         );

    ///////////////////CREATE INPUT WIDGETS////////////////
    Model_Box    mdl_box = Create_model_box("Lots model", cmbMsg, CHECK_MODEL_MUST_EXIST);
    Name_Box     name_box = Create_name_box("Element name", cmbMsg); 
    
    ///////////////ADDING BUTTONS ALONG THE BOTTOM///////////////////////////
    Horizontal_Group bgroup = Create_button_group();
    Button process     = Create_button       ("&Process" ,"process");
    Button finish      = Create_finish_button("Finish"   ,"Finish" );
    Button help_button = Create_help_button  (panel      ,"Help"   );
    Append(process      ,bgroup);
    Append(finish       ,bgroup);
    Append(help_button  ,bgroup);
    ///////////////ADDING WIDGETS TO PANEL///////////////////////////
    Append(mdl_box, panel);
    Append(name_box,  panel);

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
                // Validate name box
                Text elt_name_text;
                Integer vret_n = Validate(name_box, elt_name_text);                          // Validate(Name_Box,Text&)
                if (vret_n == 0) {                                                           // zero indicates error (per Name_Box)
                    Set_data(cmbMsg, "Error: invalid name.");
                    break;
                }
                if (elt_name_text == "") {
                    Set_data(cmbMsg, "Error: name is empty.");
                    break;
                }

                // We need the model name as Text for Find_element. Get from the Model_Box or from sel_model.
                Text model_text;
                Get_data(mdl_box, model_text);                                               // Get_data(Model_Box,Text&)

                // Call Find_element
                Element first_found;
                Integer count = 0;
                Integer fret = Find_element(model_text, elt_name_text, first_found, count);   // Find_element ID=3922
                Print("fret = " + To_text(fret) + "\n");

                if (fret == 0 && count > 0) {
                    Set_data(cmbMsg, "Found. Matches: " + To_text(count));
                    Print("Found " + elt_name_text + "\n");
                } else {
                    Set_data(cmbMsg, "Not found.");
                }
            
            


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