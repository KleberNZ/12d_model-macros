/*---------------------------------------------------------------------
**   Programmer:KLP
**   Date:19/02/26             
**   12D Model:            V15
**   Version:              001
**   Macro Name:           Add_to_mtf_snippet_panel.4dm
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
**
**   (C) Copyright 2013-2026 by your_company Pty Ltd. All Rights
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
/*global variables*/{
Element pit;
Element super_str;
}

void mainPanel(){
 
    Text panelName="Add_to_mtf_snippet_panel";
    Panel              panel  = Create_panel              (panelName,TRUE);
    Vertical_Group     vgroup = Create_vertical_group     (-1         );
    Colour_Message_Box cmbMsg = Create_colour_message_box (""         );

    ///////////////////CREATE INPUT WIDGETS////////////////
    New_Select_Box    nsb_pit =  Create_new_select_box("Select cesspit","pick a drainage pit",SELECT_STRING,cmbMsg);
    New_Select_Box    sb_super = Create_new_select_box("Select road strings","pick a super string",SELECT_STRING,cmbMsg);
    
    ///////////////ADDING BUTTONS ALONG THE BOTTOM///////////////////////////
    Horizontal_Group bgroup = Create_button_group();
    Button process     = Create_button       ("&Process" ,"process");
    Button finish      = Create_finish_button("Finish"   ,"Finish" );
    Button help_button = Create_help_button  (panel      ,"Help"   );
    Append(process      ,bgroup);
    Append(finish       ,bgroup);
    Append(help_button  ,bgroup);
    ///////////////ADDING WIDGETS TO PANEL///////////////////////////
    Append(nsb_pit    ,vgroup);
    Append(sb_super   ,vgroup);

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
        case Get_id(nsb_pit) :
        {
            if(cmd == "accept select")
            {
                Element tmp;
                Text t="";

                if(Validate(nsb_pit,tmp))
                {
                    if(Get_type(tmp,t)==0 && t=="Drainage")
                    {
                        pit = tmp;
                        Set_data(cmbMsg,"OK: Drainage selected");
                    }
                    else
                    {
                        Null(pit);
                        Set_data(nsb_pit,"");          // clear selection
                        Set_data(cmbMsg,"Pick a DRAINAGE string");
                        Select_start(nsb_pit);         // immediately reprompt
                    }
                }
                else
                {
                    Null(pit);
                    Set_data(nsb_pit,"");
                    Set_data(cmbMsg,"No valid selection");
                }
            }
        }
        break;

        case Get_id(sb_super) :
        {
            if(cmd == "accept select")
            {
                Element tmp;
                Text t="";

                if(Validate(sb_super,tmp))
                {
                    if(Get_type(tmp,t)==0 && t=="Super")
                    {
                        super_str = tmp;
                        Set_data(cmbMsg,"OK: Super string selected");
                    }
                    else
                    {
                        Null(super_str);
                        Set_data(sb_super,"");
                        Set_data(cmbMsg,"Pick a SUPER string");
                        Select_start(sb_super);
                    }
                }
                else
                {
                    Null(super_str);
                    Set_data(sb_super,"");
                    Set_data(cmbMsg,"No valid selection");
                }
            }
        }
        break;


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
                Print("Processing...");
                //TODO: declare your widget variables
                Text pit_type="", super_type="";
                if(Get_type(pit,pit_type)!=0 || pit_type!="Drainage")
                { Set_data(cmbMsg,"Select a valid Drainage first"); break; }

                if(Get_type(super_str,super_type)!=0 || super_type!="Super")
                { Set_data(cmbMsg,"Select a valid Super first"); break; }


                //TODO: do calc
                Integer pit_no = 2;   // ASSUMPTION: cesspit is the 2nd pit in drainage string

                Text pit_name = "";
                if(Get_drainage_pit_name(pit,pit_no,pit_name) != 0)
                {
                    Set_data(cmbMsg,"Failed to get drainage pit name (pit #2)");
                    break;
                }

                Integer pit_id = 0;
                if(Get_drainage_pit_attribute(pit,pit_no,"pit id",pit_id) != 0)
                {
                    Set_data(cmbMsg,"Failed to get drainage pit id attribute (pit #2)");
                    break;
                }

                Set_data(cmbMsg ,"Pit #2 name=" + pit_name + " id=" + To_text(pit_id));

                                Model pit_model;
                Text model_name = "";

                if(Get_model(pit,pit_model) != 0)
                {
                    Set_data(cmbMsg,"Failed to get model from drainage");
                    break;
                }

                if(Get_name(pit_model,model_name) != 0)
                {
                    Set_data(cmbMsg,"Failed to get model name");
                    break;
                }

                Text drainage_ref = model_name
                                    + "->"
                                    + pit_name
                                    + ";"
                                    + To_text(pit_id);

                Print("drainage_ref = " + drainage_ref);
                Set_data(cmbMsg,"Ref built: " + drainage_ref);

                //Get mtf name and side of road from super string
                Text mtf_file_name = "";
                Text link_side     = "";

                if(Get_attribute(super_str,"apply_mtf_details/mtf_file_name",mtf_file_name) != 0)
                {
                    Set_data(cmbMsg,"Failed to get mtf_file_name attribute");
                    break;
                }

                if(Get_attribute(super_str,"apply_mtf_details/link_side",link_side) != 0)
                {
                    Set_data(cmbMsg,"Failed to get link_side attribute");
                    break;
                }

                Set_data(cmbMsg, "MTF file = " + mtf_file_name + " Road Side = " + link_side);

                                Text kinv = "";
                Text adj  = "";

                if(link_side == "left")
                {
                    kinv = "KIL";
                    adj  = "FPL";
                }
                else if(link_side == "right")
                {
                    kinv = "KIR";
                    adj  = "FPR";
                }
                else
                {
                    Set_data(cmbMsg,"Unknown link_side value");
                    break;
                }

                Text snippet_line =
                    "  snippet \"SEMI_RECESSED_KERB.mtfsnippet\" drainage_ref \"" + drainage_ref + "\" 0 $null \"CP_TYPE\" \"Single\" \"KINV\" \"" + kinv + "\" \"ADJ\" \"" + adj + "\" extra_start extra_end ";

                Set_data(cmbMsg,"Snippet ready");
                Set_data(cmbMsg,snippet_line);
                Print(snippet_line);

                // ------------------ READ FILE ------------------

                Text project_path = Get_absolute_path("");
                Text mtf_full_path = project_path + mtf_file_name;

                if(File_exists(mtf_full_path) == 0)
                {
                    Set_data(cmbMsg,"MTF file not found: " + mtf_full_path);
                    break;
                }

                File f;
                Text lines[20000];
                Integer n = 0;
                Text line = "";

                if(File_open(mtf_full_path,"r",f) != 0)
                {
                    Set_data(cmbMsg,"Failed to open MTF file for reading");
                    break;
                }

                while(File_read_line(f,line) == 0)
                {
                    lines[++n] = line;
                }

                File_close(f);


                // ------------------ DETERMINE SIDE ------------------

                Text side_modifier = "";
                Text pavements_region = "";

                if(link_side == "left")
                {
                    side_modifier = "left_side_modifier";
                    pavements_region = "LHS PAVEMENTS";
                }
                else
                {
                    side_modifier = "right_side_modifier";
                    pavements_region = "RHS PAVEMENTS";
                }


                // ------------------ LOCATE INSERTION POINT ------------------

                Integer insert_index = 0;
                Integer inside_side = 0;
                Integer cesspit_region_found = 0;
                Integer last_line_inside_side = 0;

                for(Integer i=1; i<=n; i++)
                {
                    if(Find_text(lines[i], side_modifier) > 0)
                    {
                        inside_side = 1;
                        continue;
                    }

                    if(inside_side)
                    {
                        // If we hit another side modifier, stop
                        if((side_modifier == "left_side_modifier" &&
                            Find_text(lines[i], "right_side_modifier") > 0) ||
                        (side_modifier == "right_side_modifier" &&
                            Find_text(lines[i], "left_side_modifier") > 0))
                        {
                            insert_index = i;   // insert before other side starts
                            break;
                        }

                        last_line_inside_side = i;

                        if(Find_text(lines[i], "region \"CESSPITS\"") > 0)
                        {
                            cesspit_region_found = 1;
                            insert_index = i + 1;
                            break;
                        }

                        if(Find_text(lines[i], pavements_region) > 0)
                        {
                            insert_index = i;
                            break;
                        }
                    }
                }

                if(insert_index == 0 && inside_side)
                {
                    // no regions found — insert at end of side block
                    insert_index = last_line_inside_side + 1;
                }

                if(insert_index == 0)
                {
                    Set_data(cmbMsg,"Failed to locate insertion point");
                    break;
                }

                // ------------------ INSERT LOGIC ------------------

                if(!cesspit_region_found)
                {
                    // Create CESSPITS region (no braces)
                    for(Integer j=n; j>=insert_index; j--)
                    {
                        lines[j+2] = lines[j];
                    }

                    lines[insert_index]   = "  region \"CESSPITS\" \"CESSPITS\" 1";
                    lines[insert_index+1] = snippet_line;

                    n += 2;
                }
                else
                {
                    // Insert under existing region
                    for(Integer j=n; j>=insert_index; j--)
                    {
                        lines[j+1] = lines[j];
                    }

                    lines[insert_index] = snippet_line;
                    n++;
                }



                // ------------------ WRITE FILE ------------------

                if(File_open(mtf_full_path,"w",f) != 0)
                {
                    Set_data(cmbMsg,"Failed to open MTF file for writing");
                    break;
                }

                for(Integer i_line=1; i_line<=n; i_line++)
                {
                    File_write_line(f,lines[i_line]);
                }

                File_close(f);

                Set_data(cmbMsg,"MTF updated successfully");

                



                // Set_data(cmbMsg ,"Process finished");
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