/*---------------------------------------------------------------------
**   Programmer:KLP
**   Date:12/02/26             
**   12D Model:            V15
**   Version:              002
**   Macro Name:           Drainage_Set_Design_Grade_By_Self_Cleaning_Flow.4dm
**   Type:                 SOURCE
**
**   Brief description: BriefDescription
**
**
**---------------------------------------------------------------------
**   Description:
**   This macro sets the minimum design grade (%) of drainage pipe
**   segments based on nominal diameter and the pipe attribute
**   "Self-cleaning/pipe flow".
**
**   Watercare minimum grade requirements (Table 5.4 os CoP) are applied using peak
**   self-cleaning flow thresholds. The calculated percentage grade
**   is written to the segment attribute "design grade".
**
**   Pipe inverts are not modified. Final grading should be applied
**   using WNE → Regrade Links.
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
 
#define BUILD "15.0.001"
 
// ----------------------------- INCLUDES -----------------------------
#include "..\\..\\include//standard_library.H"
#include "..\\..\\include//size_of.H"
/*global variables*/{


}

void mainPanel(){
 
    Text panelName="Drainage - Set Design Grade (Self Cleaning Flow)";
    Panel              panel  = Create_panel              (panelName,TRUE);
    Vertical_Group     vgroup = Create_vertical_group     (-1         );
    Colour_Message_Box cmbMsg = Create_colour_message_box (""         );

    ///////////////////CREATE INPUT WIDGETS////////////////
    
    Model_Box          mb_model = Create_model_box("Select drainage model",cmbMsg,CHECK_MODEL_MUST_EXIST);

    ///////////////ADDING BUTTONS ALONG THE BOTTOM///////////////////////////
    Horizontal_Group bgroup = Create_button_group();
    Button process     = Create_button       ("&Process" ,"process");
    Button finish      = Create_finish_button("Finish"   ,"Finish" );
    Button help_button = Create_help_button  (panel      ,"Help"   );
    Append(process      ,bgroup);
    Append(finish       ,bgroup);
    Append(help_button  ,bgroup);
    ///////////////ADDING WIDGETS TO PANEL///////////////////////////
    

    Append(mb_model ,vgroup);
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
                Integer has_error = 0;
                Integer non_drainage_count = 0;
                Integer drainage_count = 0;
                Integer pipes_updated = 0;


                // ---- Validate Model_Box ----
                Set_error_message(mb_model,"");

                Model model;
                Integer ierr = Validate(mb_model,GET_MODEL_ERROR,model);
                if(ierr != MODEL_EXISTS)
                {
                    Set_error_message(mb_model,"Select a valid model");
                    break;
                }

                // ---- Loop elements in model ----
                Dynamic_Element elems;
                Integer ne = 0;
                Get_elements(model, elems, ne);

                if(ne <= 0)
                {
                    Set_data(cmbMsg,
                        "Selected model contains no elements");
                    break;
                }

                for(Integer e = 1; e <= ne; e++)
                {
                    Element drain;
                    Get_item(elems, e, drain);

                    // Process only drainage strings
                    Text str_type = "";
                    Get_type(drain, str_type);

                    if(str_type != "Drainage")
                    {
                        non_drainage_count++;
                        continue;
                    }
                    drainage_count++;

                    Integer nsegs = 0;
                    Get_segments(drain, nsegs);

                    for(Integer s = 1; s <= nsegs; s++)
                    {
                        // Get pipe name
                        Text pipe_name = "";
                        Get_drainage_pipe_attribute(drain, s, "pipe name", pipe_name);

                        // Get pipe DN
                        Real dn = 0.0;
                            if(Get_drainage_pipe_attribute(drain, s, "nominal diameter", dn) != 0)
                            continue;

                        // Get self-cleaning peak flow (m3/s)
                        Real peak_flow = 0.0;
                        if(Get_drainage_pipe_attribute(drain, s,
                        "Self-cleaning/pipe flow", peak_flow) != 0)
                            continue;
                        
                        // Watercare logic
                        Real grade_percent = 0.0;

                        Real flow_20  = 0.000375;
                        Real flow_200 = 0.00375;

                        if(Absolute(dn - 150.0) < 0.1)
                        {
                            if(peak_flow < flow_20)
                                grade_percent = 1.0;
                            else if(peak_flow < flow_200)
                                grade_percent = 0.75;
                            else
                                grade_percent = 0.75;
                        }
                        else if(Absolute(dn - 225.0) < 0.1)
                        {
                            grade_percent = 0.45;
                        }
                        else if(Absolute(dn - 300.0) < 0.1)
                        {
                            grade_percent = 0.30;
                        }
                        else
                        {
                            continue;
                        }

                        // Write design grade (percentage)
                        Attributes att;
                        if(Get_drainage_pipe_attributes(drain, s, att) != 0)
                            continue;

                        Set_attribute(att, "design grade", grade_percent);
                        Set_drainage_pipe_attributes(drain, s, att);
                        pipes_updated++;

                        // Output
                        Real flow_ls = peak_flow * 1000.0;

                        Text out = "[" + pipe_name + "] DN=" +
                                To_text(dn,0) +
                                " Flow=" + To_text(flow_ls,3) +
                                " L/s. Grade set =" +
                                To_text(grade_percent,2) + "%";

                        Print(out);
                        Print();

                    }
                }

                Text summary = "";

                if(drainage_count == 0)
                {
                    summary = "No drainage strings found in selected model.";
                }
                else
                {
                    summary = "Design grade update complete. Pipes updated = " +
                            To_text(pipes_updated);

                    if(non_drainage_count > 0)
                    {
                        summary = summary +
                                " | Non-drainage elements skipped = " +
                                To_text(non_drainage_count);
                    }
                }

                Set_data(cmbMsg, summary);

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