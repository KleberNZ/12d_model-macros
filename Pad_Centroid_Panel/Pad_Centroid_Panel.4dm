/*---------------------------------------------------------------------
**   Programmer:Kleber Lessa do Prado      
**   Date:20/10/25             
**   12D Model:            V15
**   Version:              004
**   Macro Name:           Pad_Centroid.4dm
**   Type:                 SOURCE
**
**   Brief description: 
**   Computes and places centroid markers for closed polygons from a chosen source. 
**   Centroid XY comes from Get_polygon_centroid. Centroid Z is the average of polygon 
**   vertex Zs plus a user Z-offset. Writes results to a target model and logs each centroid Z to the Output window.
**
---------------------------------------------------------------------
**
**   Update/Modification
**
**
**   (C) Copyright 2013-2025 by The Neil Group. All Rights
**       Reserved.
**   This macro, or parts thereof, may not be reproduced in any form
**   without permission of The Neil Group.
**---------------------------------------------------------------------
*/
#define DEBUG_FILE      0
#define ECHO_DEBUG_FILE 0
#define ECHO_LINE_NO    0
 
#define BUILD "version.0.001"
 
// ----------------------------- INCLUDES -----------------------------
#include "..\\..\\include/standard_library.h"
#include "..\\..\\include/set_ups.h"

/*global variables*/{

}
// ---------------------------HELPER FUNCTIONS-----------------------------
void add_hl_log(Log_Box lbox, Element e, Text message, Integer level)
{
  if (Element_exists(e) == 0) {
    Add_log_line(lbox, Create_text_log_line(message + " | <invalid element>", level));
    return;
  }

  Model m;
  if (Get_model(e, m) != 0) { // non-zero == failure
    Add_log_line(lbox, Create_text_log_line(message + " | <no model>", level));
    return;
  }

  Uid mid; Get_id(m, mid);    // no “= 0” initialisation
  Uid sid; Get_id(e, sid);

  Log_Line ln = Create_highlight_string_log_line(message, level, mid, sid);
  Add_log_line(lbox, ln);
}

// ---------------------------MAIN PANEL FUNCTION-----------------------------

void mainPanel(){
 
    Text panelName="Polygon Centroids";
    Panel              panel  = Create_panel              (panelName,TRUE);
    Vertical_Group     vgroup = Create_vertical_group     (BALANCE_WIDGETS_OVER_HEIGHT);
    Colour_Message_Box cmbMsg = Create_colour_message_box (""         );

    ///////////////////CREATE INPUT WIDGETS////////////////
    // create some input fields
    Source_Box         sb_source    = Create_source_box("Data Source",cmbMsg,0);
    Model_Box          mb_target    = Create_model_box ("Centroid Model",cmbMsg,CHECK_MODEL_CREATE);
    Real_Box           rb_zoff      = Create_real_box("Z offset",cmbMsg);
    Log_Box            lbox         = Create_log_box("Log", 700, 200);
    Set_data(rb_zoff, 0.1); // default 0.1
    
    ///////////////ADDING BUTTONS ALONG THE BOTTOM///////////////////////////
    Horizontal_Group bgroup = Create_button_group();
    Button process     = Create_button       ("&Process" ,"process");
    Button finish      = Create_finish_button("Finish"   ,"Finish" );
    Button help_button = Create_help_button  (panel      ,"Help"   );
    Append(process      ,bgroup);
    Append(finish       ,bgroup);
    Append(help_button  ,bgroup);
    ///////////////ADDING WIDGETS TO PANEL///////////////////////////
    // add your widgets to vgroup
    Append(sb_source ,vgroup);
    Append(mb_target ,vgroup);
    Append(rb_zoff   ,vgroup);
    Append(cmbMsg    ,vgroup);
    Append(bgroup    ,vgroup);


    Append(vgroup,panel);
    Append(lbox, vgroup);
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
                // Validate Source_Box → Dynamic_Element list
                // Manual: §5.61.10.35 Validate(Source_Box, Dynamic_Element&)
                Dynamic_Element dels;
                if (Validate(sb_source, dels) != TRUE)
                {
                    Set_data(cmbMsg, "Source selection is invalid.");
                    continue;
                }
                // Validate Model_Box → GET_MODEL and ensure MODEL_EXISTS
                // Manual: §5.61.10.21 Validate(Model_Box, Integer mode, Model&)
                // Get or create target model
                Text target_name = "";
                if (Get_data(mb_target, target_name) != 0 || Text_length(target_name) == 0) {
                    Set_data(cmbMsg, "Enter a model name.");
                    continue;
                }
                Model target_model = Get_model_create(target_name);  // creates or returns handle

                Real z_offset = 0.0;
                if (Validate(rb_zoff, z_offset) != TRUE) {
                    Set_data(cmbMsg, "Enter a valid Z offset.");
                    continue;
                }

                Integer n = 0;
                // Manual: §5.19.1 Get_number_of_items(Dynamic_Element&)
                if (Get_number_of_items(dels, n) != 0 || n <= 0)
                {
                    Set_data(cmbMsg, "No elements in source.");
                    continue;
                }

                //do calc
                Integer placed = 0, skipped = 0;
                Dynamic_Element all_cp_elts;

                for (Integer i = 1; i <= n; i++)
                {
                    Element e;
                    // Manual: §5.19.1 Get_item(Dynamic_Element&, i, Element&)
                    if (Get_item(dels, i, e) != 0) 
                    {
                        skipped++; continue; 
                    }

                    // Optional: ensure it is a string-like element
                    // Manual: §5.36.2.1 Get_type(Element, Text&)
                    Text etype; 
                    Get_type(e, etype);
                    Text mname;
                    Get_name(target_model, mname);
                    //Print("debug model=<" + mname + "> newEltType=<" + etype + ">\n");

                    // Check closed
                    // Manual: §5.55.3 String_closed(Element, Integer &closed)
                    Integer is_closed = 0;
                    Integer cerr = String_closed(e, is_closed);
                    if (cerr != 0 || is_closed != TRUE)
                    {
                        Text nm;
                        Get_name(e, nm);
                        Print("polygon not closed: <" + nm + ">\n");
                        skipped++;
                        continue;
                    }

                    // Optional sanity: >=3 vertices
                    // Manual: §5.36.2.1 Get_points(Element, Integer &num_verts)
                    Integer vcount = 0;
                    if (Get_points(e, vcount) == 0 && vcount >= 3)
                    {
                        // ok
                    }
                    else
                    {
                        Text nm;
                        Get_name(e, nm);
                        add_hl_log(lbox, e, "no vertices", 2);          // warning
                        Print("polygon has insufficient vertices: <" + nm + ">\n");
                        skipped++;
                        continue;
                    }
                    // ----- average Z of vertices -----
                    Real avgz = 0.0;
                    {
                        Real sumz = 0.0;
                        Integer cnt = 0;
                        if (etype == "Super")
                        {
                            for (Integer vi = 1; vi <= vcount; vi++)
                            {
                                Real vx, vy, vz;
                                if (Get_super_vertex_coord(e, vi, vx, vy, vz) == 0)
                                {
                                    sumz += (vz + z_offset);   // apply offset per-vertex
                                    cnt++;
                                }
                            }
                        }
                        if (cnt > 0)
                        avgz = sumz / cnt;        // avg(vz + offset) = avg(vz) + offset
                    }
                     // ---------------------------------


                    // Create a centroid element
                    // Manual: §5.63.11 
                    // XY from medial axis with fallback to centroid
                    Real cx = 0.0, cy = 0.0, r = 0.0;
                    Real tol = 0.01;                 // or read from a panel widget
                    Integer rc = Medial_axis_polygon(e, cx, cy, r, tol);   // 0 == success
                    if (rc != 0) 
                    {
                        if (Get_polygon_centroid(e, cx, cy) != 0)
                        {
                            add_hl_log(lbox, e, "center failed (medial+centroid)", 3);
                            skipped++;
                            continue;
                        }
                        else
                        {
                        add_hl_log(lbox, e, "medial axis failed; used centroid", 2);
                        }
                    } 
                    else
                    {
                    add_hl_log(lbox, e, "medial axis center used (r="+To_text(r,3)+")", 1);
                    }

                    Text nm = "";
                    Integer rc_nm = Get_name(e, nm);

                    Text new_name = "Centroid_of_" + nm;
                    Valid_string_name(new_name, new_name);

                    // Create a 1-vertex 2D element at centroid
                    // Manual: §5.53 Create_2d(Integer num_pts), Set_2d_data(Element, idx, x, y), Set_2d_data(Element, z)
                    Element pt = Create_2d(1);
                    Set_name(pt, new_name);

                    // then write name & coords
                    Set_2d_data(pt, 1, cx, cy);
                    Set_2d_data(pt, avgz);
                    Calc_extent(pt);  // recalc extent after coord change

                    Append(pt, all_cp_elts); // ADD THEM TO THE list of elements

                    Print("Polygon <" + nm + "> centroid Z value is " + To_text(avgz, 3) + "m\n");

                    add_hl_log(lbox, pt, "Centroid created <" + nm + ">. RL is " + To_text(avgz, 3) + "m", 1); // success
                    placed++;
                }

                // Place into target model
                // Manual: §5.36.2.1 Set_model(Element, Model)
                // save them all in one go
                if (Set_model(all_cp_elts, target_model) != 0)
                {
                    Print("failed to set model for centroid element\n");
                    skipped++;
                    continue;
                }
                Calc_extent(target_model); // recalc extent after adding new element

                Null(all_cp_elts);
                Null(target_model);
                Null(dels);
                Null(all_cp_elts);

                Add_log_line(lbox, Create_text_log_line("Created points: " + To_text(placed), 1));
                Set_data(cmbMsg, "Process finished");

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