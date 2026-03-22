/*---------------------------------------------------------------------
**   Programmer:KLP
**   Date:26/11/25             
**   12D Model:            15version
**   Version:              001
**   Macro Name:           Label_point_name_panel
**   Type:                 TEXT
**
**   Brief description: Creates a text label for each selected point 
**                      (Super with 1 vertex) and exports the point 
**                      name and coordinates to a CSV file.

**
**---------------------------------------------------------------------
**   Description: This macro processes point-type Super strings (Supers with exactly one vertex) from a user-defined Source Box. 
**                For each valid point, it creates an individual Text String element in the specified output model.
**
**                The macro also writes a CSV file containing, for every labelled point: string_name, X, Y, Z. 
**                Only true point Supers (1-vertex elements) are labelled; all other element types are ignored.
**                Undo support is provided so all created labels can be removed in a single operation.
**
**---------------------------------------------------------------------
**   Update/Modification
**
**  This macro may be reproduced, modified and used without restriction.
**  The author grants all users Unlimited Use of the source code and any 
**  associated files, for no fee. Unlimited Use includes compiling, running,
**  and modifying the code for individual or integrated purposes.
**  The author also grants 12d Solutions Pty Ltd and other users permission
**  to incorporate this macro, in whole or in part, into other macros or programs..
**---------------------------------------------------------------------
*/
#define DEBUG_FILE      0
#define ECHO_DEBUG_FILE 0
#define ECHO_LINE_NO    0
 
#define BUILD "version.0.001"
 
// ----------------------------- INCLUDES -----------------------------
#include "..\\..\\include/standard_library.H"
#include "..\\..\\include/size_of.H"
#include "..\\..\\include/set_ups.h"
#include "..\\..\\include/Matt_set_ups.H"
/*global variables*/{


}

void mainPanel(){
 
    Text panelName="Label Points & Export CSV";
    Panel              panel  = Create_panel              (panelName,TRUE);
    Vertical_Group     vgroup = Create_vertical_group     (-1         );
    Colour_Message_Box cmbMsg = Create_colour_message_box (""         );

    ///////////////////CREATE INPUT WIDGETS////////////////
    // Input widgets
    Source_Box         src_box = Create_source_box         ("Source"            ,cmbMsg,0        );
    Model_Box          model_box = Create_model_box        ("Output text model" ,cmbMsg,0        );
    Textstyle_Data_Box ts_box = Create_textstyle_data_box  ("Text style", cmbMsg, Show_std_boxes, Optional_std_boxes);



    File_Box           csv_box  = Create_file_box          ("CSV file"          ,cmbMsg,0,"*.csv");
    
    ///////////////ADDING BUTTONS ALONG THE BOTTOM///////////////////////////
    Horizontal_Group bgroup = Create_button_group();
    Button process     = Create_button       ("&Process" ,"process");
    Button finish      = Create_finish_button("Finish"   ,"Finish" );
    Button help_button = Create_help_button  (panel      ,"Help"   );
    Append(process      ,bgroup);
    Append(finish       ,bgroup);
    Append(help_button  ,bgroup);
    ///////////////ADDING WIDGETS TO PANEL///////////////////////////
    // Add widgets to main vertical group
    Append(src_box ,vgroup);
    Append(model_box ,vgroup);
    Append(ts_box ,vgroup);
    Append(csv_box ,vgroup);

    Append(cmbMsg ,vgroup);
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
                // -------------------------------------------------
                // DECLARE WIDGET DATA / VALIDATION VARIABLES
                // -------------------------------------------------
                Dynamic_Element de_src;
                Model           out_model;
                Textstyle_Data  tsd;
                Text            csv_name   = "";
                Integer         src_count  = 0;
                Integer         ierr       = 0;

                // Clear message box
                Set_data(cmbMsg,"");

                // Single-pass block so we can 'break' on any error
                do
                {
                    // ---------------- Source_Box ----------------
                    ierr = Validate(src_box,de_src);
                    // For Source_Box: FALSE (0) = error
                    if(ierr == FALSE)
                    {
                        Set_error_message(src_box,"");
                        break;
                    }

                    ierr = Get_number_of_items(de_src,src_count);
                    // Get_number_of_items: 0 = success
                    if(ierr != 0)
                    {
                        Set_error_message(src_box,"Source error");
                        break;
                    }
                    if(src_count <= 0)
                    {
                        Set_error_message(src_box,"No elements selected");
                        break;
                    }

                    // ---------------- Model_Box -----------------
                    ierr = Validate(model_box,GET_MODEL_CREATE,out_model);
                    // For Model_Box: FALSE (0) = error
                    if(ierr == FALSE)
                    {
                        Set_error_message(model_box,"");
                        break;
                    }

                    // ---------- Textstyle_Data_Box --------------
                    ierr = Validate(ts_box,tsd);
                    // For Textstyle_Data_Box: FALSE (0) = error, NO_NAME/TRUE ok
                    if(ierr == FALSE)
                    {
                        Set_error_message(ts_box,"");
                        break;
                    }

                    // ---------------- File_Box ------------------
                    ierr = Validate(csv_box,GET_FILE_WRITE,csv_name);
                    // For File_Box: FALSE (0) = error
                    if(ierr == FALSE)
                    {
                        Set_error_message(csv_box,"");
                        break;
                    }

                    // ---------------- Count point supers --------
                    Integer total_pts = 0;
                    Integer n_elts    = src_count;
                    Integer e_index   = 0;

                    Element sel_elt;
                    Integer numpts = 0;
                    Text    etype  = "";

                    for(e_index = 1; e_index <= n_elts; e_index++)
                    {
                        ierr = Get_item(de_src,e_index,sel_elt);
                        // Get_item: 0 = success
                        if(ierr != 0)
                            continue;

                        etype = "";
                        ierr = Get_type(sel_elt,etype);
                        // Get_type: 0 = success
                        if(ierr != 0)
                            continue;

                        // only Super elements
                        if(etype != "Super")
                            continue;

                        numpts = 0;
                        ierr = Get_points(sel_elt,numpts);
                        // Get_points: 0 = success
                        if(ierr != 0)
                            continue;

                        // POINT ONLY: Super with exactly 1 vertex
                        if(numpts == 1)
                            total_pts = total_pts + 1;
                    }

                    if(total_pts <= 0)
                    {
                        Set_data(cmbMsg,"No Super points (Super with 1 vertex) found in selection");
                        break;
                    }

                    // ---------------- Open CSV file -------------
                    File csv_file;
                    Text mode = "w";
                    ierr = File_open(csv_name,mode,csv_file);
                    // File_open: 0 = success
                    if(ierr != 0)
                    {
                        Set_data(cmbMsg,"Failed to open CSV file for writing");
                        break;
                    }

                    // Write header
                    File_write_line(csv_file,"string_name,x,y,z");

                    // ---------------- Create text + CSV ---------
                    Integer pt_index = 0;
                    Real x = 0.0;
                    Real y = 0.0;
                    Real z = 0.0;
                    Text elt_name = "";

                    Undo      u;
                    Undo_List ulist;

                    for(e_index = 1; e_index <= n_elts; e_index++)
                    {
                        ierr = Get_item(de_src,e_index,sel_elt);
                        if(ierr != 0)
                            continue;

                        etype = "";
                        ierr = Get_type(sel_elt,etype);
                        if(ierr != 0)
                            continue;

                        if(etype != "Super")
                            continue;

                        numpts = 0;
                        ierr = Get_points(sel_elt,numpts);
                        if(ierr != 0)
                            continue;

                        // only Supers with exactly 1 vertex (points)
                        if(numpts != 1)
                            continue;

                        elt_name = "";
                        Get_name(sel_elt,elt_name);

                        // vertex 1
                        ierr = Get_super_vertex_coord(sel_elt,1,x,y,z);
                        // Get_super_vertex_coord: 0 = success
                        if(ierr != 0)
                            continue;

                        // Create a Text String Element at this point
                        // Create_text(..) uses x,y; we then set full xyz
                        Element txt = Create_text(elt_name,x,y,1.0,1);
                        Set_text_xyz(txt,x,y,z);
                        Set_text_textstyle_data(txt,tsd);
                        Set_name(txt,elt_name);
                        Set_model(txt,out_model);

                        // CSV line
                        Text line = "";
                        line = elt_name
                               + ","
                               + To_text(x,3)
                               + ","
                               + To_text(y,3)
                               + ","
                               + To_text(z,3);
                        File_write_line(csv_file,line);

                        // Undo
                        u = Add_undo_add("Label points & CSV",txt);
                        Append(u,ulist);

                        pt_index = pt_index + 1;
                    }

                    // Close CSV
                    File_close(csv_file);

                    if(pt_index <= 0)
                    {
                        Set_data(cmbMsg,"No valid Super points created (check selection)");
                        break;
                    }

                    // ---------------- Undo support --------------
                    Add_undo_list("Label points & CSV",ulist);

                    // -------------- Final message ---------------
                    Integer n_pts_done = pt_index;
                    Text msg_text = "";
                    Text model_name = "";
                    Text style_name = "";

                    Get_name(out_model,model_name);
                    // Try to get style name from Textstyle_Data (for info only)
                    Get_textstyle(tsd,style_name);

                    msg_text = "Done: "
                              + To_text(n_pts_done)
                              + " point supers labelled in model "
                              + model_name
                              + "; CSV: "
                              + csv_name;

                    if(style_name != "")
                        msg_text = msg_text + "; style: " + style_name;

                    Set_data(cmbMsg,msg_text);

                } while(FALSE);
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
