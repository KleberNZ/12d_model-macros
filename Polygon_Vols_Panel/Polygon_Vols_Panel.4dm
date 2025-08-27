/*---------------------------------------------------------------------
**   Programmer:Kleber Lessa
**   Date:18/08/25             
**   12D Model:            V15
**   Version:              001
**   Macro Name:           Polygon_Vols_Panel.4dm
**   Type:                 SOURCE
**
**   Brief description: Creates text in polygons with volume
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
#include "..\\..\\include\standard_library.H"
#include "..\\..\\include\size_of.H"
/*global variables*/{


}

void mainPanel(){
 
    Text panelName="Polygon Volumes";
    Panel              panel  = Create_panel              (panelName,TRUE);
    Vertical_Group     vgroup = Create_vertical_group     (-1         );
    Colour_Message_Box cmbMsg = Create_colour_message_box (""         );

    ///////////////////CREATE INPUT WIDGETS////////////////
    //TODO: create some input fields
    Source_Box         sb_polys = Create_source_box("of polygons",cmbMsg,0);
    Tin_Box            tb_orig = Create_tin_box("Original tin",cmbMsg,CHECK_TIN_MUST_EXIST);
    Tin_Box            tb_new = Create_tin_box("New tin",cmbMsg,CHECK_TIN_MUST_EXIST);
    Textstyle_Data_Box tb_style = Create_textstyle_data_box("Text Style",cmbMsg,V10_Show_std_boxes,V10_Optional_std_boxes);
    Model_Box          mb_text = Create_model_box("Results",cmbMsg,CHECK_MODEL_CREATE);
    Named_Tick_Box     ntb_clean = Create_named_tick_box("Clean model",FALSE,"");
    

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

    Append(sb_polys    ,vgroup);
    Append(tb_orig    ,vgroup);
    Append(tb_new    ,vgroup);
    Append(tb_style   ,vgroup);
    Append(mb_text   ,vgroup);
    Append(ntb_clean   ,vgroup);


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