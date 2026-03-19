/*---------------------------------------------------------------------
**   Programmer:Kleber Lessa do Prado
**   Date:28/10/25             
**   12D Model:            V15
**   Version:              001
**   Macro Name:           Lowest_point_along_polygon_panel.4dm
**   Type:                 SOURCE
**
**   Brief description: Drape lowest point along polygon panel
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
/*global variables*/{
Real minZ = 1.0e99;  Real minX = 0.0, minY = 0.0; Text minName = "";
Real maxZ = -1.0e99; Real maxX = 0.0, maxY = 0.0; Text maxName = "";

}
// ----------------------------- HELPER FUNCTIONS -----------------------------

// simple wrappers
void log_ok(Log_Box lb, Text msg)
{
  Log_Line ln = Create_text_log_line(msg, 1);
  Add_log_line(lb, ln);
}

void log_warn(Log_Box lb, Text msg)
{
  Log_Line ln = Create_text_log_line(msg, 2);
  Add_log_line(lb, ln);
}

void log_err(Log_Box lb, Text msg)
{
  Log_Line ln = Create_text_log_line(msg, 3);
  Add_log_line(lb, ln);
  Print_log_line(ln, 1); // also flash Output Window (ID 2670)
}

void mainPanel(){
 
    Text panelName="Polygon Lowest Z";
    Panel              panel  = Create_panel              (panelName,TRUE);
    Vertical_Group     vgroup = Create_vertical_group     (-1         );
    Colour_Message_Box cmbMsg = Create_colour_message_box (""         );
    Log_Box            lb = Create_log_box("Results",700, 260);

    ///////////////////CREATE INPUT WIDGETS////////////////
    //TODO: create some input fields
    Source_Box         sb_polys = Create_source_box(" of polygons",cmbMsg,0);
    Named_Tick_Box     ntb_low = Create_named_tick_box("Use lowest Z from TIN",FALSE,"");
    Named_Tick_Box     ntb_high = Create_named_tick_box("Use highest Z from TIN",FALSE,"");
    Tin_Box            tb_surface = Create_tin_box("TIN to drape polygons",cmbMsg,CHECK_TIN_MUST_EXIST);
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
    Append(sb_polys   ,vgroup);
    Append(ntb_low   ,vgroup);
    Append(ntb_high   ,vgroup);
    Append(tb_surface ,vgroup);
    Append(lb, vgroup);


    Append(cmbMsg    ,vgroup);
    Append(bgroup    ,vgroup);


    Append(vgroup,panel);
    Show_widget(panel);
    Set_visible(tb_surface,FALSE); // hide TIN box initially
    

    Integer doit = 1;
    while(doit)
    {
        Text cmd="",msg = "";
        Integer id,ret = Wait_on_widgets(id,cmd,msg);
        
        // Handle tick boxes to show/hide TIN box
        Integer ev = 0;            // 0 = other, 1 = low, 2 = high
        if (id == Get_id(ntb_low))  ev = 1;
        if (id == Get_id(ntb_high)) ev = 2;

        switch (ev) {              // §2.8.5 Switch
        case 1: { // low toggled
            Integer vLow = 0;  Validate(ntb_low, vLow);
            if (vLow == TRUE) {
                Set_data(ntb_high, FALSE);     // untick the other
                Set_visible(tb_surface,TRUE);  // show TIN when any is ticked
                Set_data(cmbMsg, "Select TIN to drape polygons.");
            } else {
               Set_visible(tb_surface, FALSE); // 
            }
            break;
        }
        case 2: { // high toggled
            Integer vHigh = 0; Validate(ntb_high, vHigh);
            if (vHigh == TRUE) {
                Set_data(ntb_low, FALSE);      // untick the other
                Show_widget(tb_surface);       // show TIN when any is ticked
            } else {
                // high now unticked
                Integer vLow = 0; Validate(ntb_low, vLow);
                Set_visible(tb_surface, FALSE); // 
            }
            break;
        }
        default : { // other widgets
            // no-op
            break;
        }
        }
 
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
                //TODO: validate widgets
                Clear(lb);
                
                // Validate Source_Box → Dynamic_Element list
                Dynamic_Element dels2d;
                if (Validate(sb_polys, dels2d) != TRUE) { Set_data(cmbMsg, "Select 2D lot boundaries."); continue; }
                Print("2D elements selected.\n");
               
                // Count
                Integer n2d = 0;
                if (Get_number_of_items(dels2d, n2d) != 0 || n2d == 0) { Set_data(cmbMsg, "No 2D elements selected."); continue; }
                Print ("Number of 2D elements: " + To_text(n2d) + "\n");
                
                // Validate TIN_Box → TIN Element
                Tin tin; 
                if (Validate(tb_surface,CHECK_TIN_MUST_EXIST, tin) == CHECK_TIN_MUST_EXIST) continue; // 8 = must exist
                Text tname; Get_name(tin,tname);
                Print("Using TIN: " + tname + "\n");

                // Drape, place in temp model, scan, log, delete model
                Text tmp_name = "TEMP DRAPED LOWEST POLYGONS";
                Model tmp = Get_model_create(tmp_name); // create temp model

                //TODO: do calc
                Integer made = 0, skipped = 0;
                for(Integer i=1; i<= n2d; i++)
                    {
                        Element e2d;
                        if(Get_item(dels2d, i, e2d) != 0) { skipped++; continue; }

                        Text nm = ""; Get_name(e2d, nm);
                        Print("Processing polygon: <" + nm + ">\n");

                        // --- Polygon validation (manual IDs 3543, 3544) ---
                        Integer rc, good_polygon;
                        Element poly_fixed;

                        rc = Check_polygon(e2d, good_polygon, poly_fixed);   // 0 = ok
                        if (rc != 0) { Print("Check_polygon failed" + nm + "\n"); return; }

                        if (good_polygon != 1) { Print("Not a valid simple polygon" + nm + "\n"); return; }
                        // Use fixed polygon if provided
                        if (Element_exists(poly_fixed)) { e2d = poly_fixed; }

                        // 2D validity checks for offset
                        Integer is_closed = 0;
                        if (String_closed(e2d, is_closed) != 0 || is_closed != TRUE) { Print("not closed: <" + nm + ">\n"); skipped++; continue; }
                        Integer vcount = 0;
                        if (Get_points(e2d, vcount) != 0 || vcount < 3) { Print("not polygon: <" + nm + ">\n"); skipped++; continue; }

                        // --- Drape to TIN ---
                        Dynamic_Element draped_poly;
                        Integer drc = Drape(tin, e2d, draped_poly);
                        if (drc != 0) { Print("Drape failed: <" + nm + ">\n"); skipped++; continue; }

                        // Set to temp model
                        Set_model(draped_poly, tmp);

                        // If draped success 
                        Integer nd=0; 
                        if (Get_number_of_items(draped_poly, nd) != 0 || nd == 0) { Print("No draped geometry for <" + nm + ">\n"); skipped++; continue; }

                        for (Integer k = 1; k <= nd; k++)
                            {
                                Element e3d;
                                if (Get_item(draped_poly, k, e3d) != 0) continue;

                                Integer nvert = 0;
                                if (Get_points(e3d, nvert) != 0 || nvert == 0) continue;  // §5.36.2.1

                                for (Integer vi = 1; vi <= nvert; vi++)
                                {
                                    Real x, y, z;
                                    if (Get_3d_data(e3d, vi, x, y, z) != 0) continue;     // §5.53

                                    if (z < minZ)
                                    {
                                        minZ = z; minX = x; minY = y; minName = nm;
                                    }
                                    if (z > maxZ)
                                    {
                                        maxZ = z; maxX = x; maxY = y; maxName = nm;
                                    }
                                }
                            }
                    }
                    made++;
                    // Report
                    if (made == 0)
                    {
                        log_warn(lb, "No polygons processed.");
                    }
                    else if (minZ >= 1.0e99 - 1.0)
                    {
                        log_err(lb, "No vertices found after drape.");
                    }
                    else
                    {
                        Text Log_msg = "Lowest draped point: " + Real_to_text(minX, 3) + ", " + Real_to_text(minY, 3) + ", " + Real_to_text(minZ,3)
                                + "  on <" + minName + ">";
                        Log_Line ln = Create_highlight_point_log_line(msg, 0, minX, minY, minZ);  // §5.61.12
                        Add_log_line(lb, ln);
                        log_ok(lb, Log_msg);
                        // Print(Log_msg + "\n");
                        if (maxZ > -1.0e99 + 1.0) {
                            Text msgMax = "Highest draped point: " + Real_to_text(maxX, 3) + ", " + Real_to_text(maxY, 3) + ", " + Real_to_text(maxZ, 3)
                                        + "  on <" + maxName + ">";
                            Log_Line lnMax = Create_highlight_point_log_line(msgMax, 0, maxX, maxY, maxZ);
                            Add_log_line(lb, lnMax);
                            Print(msgMax + "\n");
                        }
                    }
                    
                }
                Set_data(cmbMsg ,"Process finished");
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