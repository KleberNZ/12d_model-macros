/*---------------------------------------------------------------------
**   Programmer: ChatGPT
**   Date: 2025-10-23
**   12D Model: V15
**   Version: 001
**   Macro Name: split_polygon.4dm
**   Type: panel
**
**   Purpose:
**     Split a Super String (polygon) at a user-specified chainage.
**
**   Inputs:
**     SuperString: Element — selected polygon to split
**     Chainage: Real — distance along the string where split occurs
**
**   Outputs:
**     Two new Super Strings created at the specified chainage
**
**   Notes:
**     Manual sections: §5.38.17, §5.55, §5.61.10
---------------------------------------------------------------------*/
#define DEBUG_FILE      0
#define ECHO_DEBUG_FILE 0
#define ECHO_LINE_NO    0
#define BUILD "15.0.001"

// ----------------------------- INCLUDES -----------------------------
#include "..\\..\\include/standard_library.H"
#include "..\\..\\include/size_of.H"
/*global variables*/{
}

void mainPanel(){

    Text panelName="Split Polygon at Chainage";
    Panel              panel  = Create_panel              (panelName,TRUE);
    Vertical_Group     vgroup = Create_vertical_group     (-1);
    Colour_Message_Box cmbMsg = Create_colour_message_box ("");

    ////////////// CREATE INPUT WIDGETS //////////////
    New_Select_Box sb_string = Create_new_select_box("Select Polygon", "Select a Super String (polygon)", SELECT_STRING, cmbMsg);
    Real_Box rb_chain = Create_real_box("Chainage", cmbMsg);

    ////////////// BUTTONS //////////////
    Horizontal_Group bgroup = Create_button_group();
    Button process = Create_button("&Process","process");
    Button finish  = Create_finish_button("Finish","Finish");
    Button help_button = Create_help_button  (panel      ,"Help"   );

    Append(help_button  ,bgroup);
    Append(sb_string, vgroup);
    Append(rb_chain, vgroup);
    Append(cmbMsg, vgroup);
    Append(process,bgroup);
    Append(finish,bgroup);
    Append(bgroup,vgroup);
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
            Element superStr;
            Real chg;
            if(Validate(sb_string,superStr) == FALSE){
                Set_data(cmbMsg,"Invalid polygon selection.");
                continue;
            }
            if(Validate(rb_chain,chg) == FALSE){
                Set_data(cmbMsg,"Invalid chainage value.");
                continue;
            }

            Element leftPart, rightPart;
            Integer ierr = Split_string(superStr, chg, leftPart, rightPart); 
            // Manual: §5.38.17 Super_string_split(Element&, Real, Element&, Element&)

            if(ierr != 0){
                Set_data(cmbMsg,"Split failed at specified chainage.");
                continue;
            }

            Model mdl;
            Get_model(superStr,mdl);
            Set_model(leftPart,mdl);
            Set_model(rightPart,mdl);
            // Manual: §5.55.10 Add_element(Element&, Model&)

            Set_data(cmbMsg,"Polygon successfully split at chainage " + To_text(chg));

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
