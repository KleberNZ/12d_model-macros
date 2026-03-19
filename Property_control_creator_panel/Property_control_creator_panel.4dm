/*---------------------------------------------------------------------
**   Programmer:Kleber Lessa do Prado
**   Date:21/10/25             
**   12D Model:            V15
**   Version:              004
**   Macro Name:           Lot_Connection_Creator.4dm
**   Type:                 SOURCE
**
**   Brief description: Creates property-control strings for lot connections
**
**
**---------------------------------------------------------------------
**   Description:
**
**   Purpose
**   The Property Control Creator macro generates two property-control
**   strings from selected closed lot boundary polygons and their
**   associated Point of Connection (PC) strings.
**
**   For each lot, the macro:
**   - Detects a PC string inside the boundary.
**   - Offsets the boundary.
**   - Splits it based on the PC location (optionally using TIN levels).
**   - Creates “Property Control 1” and “Property Control 2”.
**
**   These strings are used in “Create/Update Property Control and
**   House Connections”.
**
**   Input Requirements
**   - Lot boundaries must be closed polygons.
**   - Property Control strings inherit the lot boundary name.
**   - PC strings must start inside the lot and extend outward.
**   - The first PC vertex must be offset from the boundary by the
**     value entered in “Offset dist. from bdy”.
**
**   Panel Inputs
**   Offset dist. from bdy – Distance (m) between lot boundary and
**   first PC vertex.
**
**   Drape Polygons Option
**   If enabled, the offset lot boundary is draped to a selected TIN.
**   The split location is then determined using either:
**   - Highest TIN z – useful when the lot drains toward the connection.
**   - Lowest TIN z – useful when the lot drains away from the connection.
**
**---------------------------------------------------------------------
**   Update/Modification
**   Version 004 - Added validation of LC element after search and after duplication, with error logging
**   Versio 003 - Added explanation at the headers about draped polygons Option
**   Versio 002 - Added option to use lowest/highest Z  from specified TIN
**---------------------------------------------------------------------
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
#include "..\\..\\include/standard_library.H"
#include "..\\..\\include/size_of.H"

/*global variables*/{
#define XY_TOL 0.1         // tolerance for matching XY corners
Real minZ = 1.0e99;  Real minX = 0.0, minY = 0.0; Text minName = "";
Real maxZ = -1.0e99; Real maxX = 0.0, maxY = 0.0; Text maxName = "";
Integer colour_pc1 = 8; //orange
Integer colour_pc2 = 15; //brown
}

/*--------------------------- LOCAL HELPERS --------------------------*/

// Check LC strings to find one with exactly one vertex inside polygon e2d; return inside/outside XY
Integer find_lc_inside_outside_xy(Dynamic_Element delsLC, Element e2d, Real &ix, Real &iy, Real &ox, Real &oy, Element &lc_out)
{
    Null(lc_out);
    Integer nLC = 0;
    if (Get_number_of_items(delsLC, nLC) != 0 || nLC <= 0) return 1;

    for (Integer k = 1; k <= nLC; k++)
    {
        Element lc;
        if (Get_item(delsLC, k, lc) != 0) continue;

        Integer nv = 0;
        if (Get_points(lc, nv) != 0 || nv < 2) continue;

        // vertex 1 must be inside polygon
        Real x1=0.0, y1=0.0, z1=0.0;
        if (Get_super_vertex_coord(lc, 1, x1, y1, z1) != 0) continue;

        Integer in_flag1 = 0;
        if (XY_inside_polygon(e2d, x1, y1, in_flag1) != 0) continue;
        if (in_flag1 != 1) continue; // reject LC not starting inside

        // find an outside vertex; prefer last, else scan 2..nv
        Real xout = x1, yout = y1; Integer found_out = 0;

        Real xl=0.0, yl=0.0, zl=0.0; Integer infl=0;
        if (Get_super_vertex_coord(lc, nv, xl, yl, zl) == 0 &&
            XY_inside_polygon(e2d, xl, yl, infl) == 0 && infl == 0)
        {
            xout = xl; yout = yl; found_out = 1; 
        }
        else
        {
            for (Integer j = 2; j <= nv; j++)
            {
                Real x=0.0, y=0.0, z=0.0;
                if (Get_super_vertex_coord(lc, j, x, y, z) != 0) continue;
                Integer in_flag = 0;
                if (XY_inside_polygon(e2d, x, y, in_flag) != 0) continue;
                if (in_flag == 0) { xout = x; yout = y; found_out = 1; break; }
            }
        }

        // Accept LC if vertex 1 is inside.
        // If no outside vertex found, use last vertex as direction reference.

        if (found_out == 0)
        {
            if (Get_super_vertex_coord(lc, nv, xl, yl, zl) == 0)
            {
                xout = xl;
                yout = yl;
            }
        }

        // Accept LC
        ix = x1; iy = y1;
        ox = xout; oy = yout;
        lc_out = lc;
        return 0;

    }
    return 2; // not found
}


// Project XY to the closest segment of a (closed) super string and return chainage and distance
Integer chainage_at_xy(Element e, Real px, Real py, Real &out_chain, Real &out_dist)
{
    Integer nv = 0; if (Get_points(e, nv) != 0 || nv < 2) return 1;

    Real best_d2 = 1.0e99; Real best_chain = 0.0;

    Real x1=0.0, y1=0.0, z1=0.0;
    if (Get_super_vertex_coord(e, 1, x1, y1, z1) != 0) return 2;

    Real acc = 0.0;
    for (Integer j = 1; j <= nv; j++)
    {
        Real x2=0.0, y2=0.0, z2=0.0;
        Integer jp1 = (j == nv) ? 1 : (j + 1);
        if (Get_super_vertex_coord(e, jp1, x2, y2, z2) != 0) return 3;

        Real vx = x2 - x1, vy = y2 - y1;
        Real wx = px - x1, wy = py - y1;
        Real vv = vx*vx + vy*vy;
        Real t = (vv > 0.0) ? ((wx*vx + wy*vy) / vv) : 0.0;
        if (t < 0.0) t = 0.0; if (t > 1.0) t = 1.0;

        Real qx = x1 + t*vx;
        Real qy = y1 + t*vy;
        Real dx = px - qx, dy = py - qy;
        Real d2 = dx*dx + dy*dy;

        if (d2 < best_d2)
        {
            best_d2 = d2;
            // chainage to start of this segment + local length to q
            Real seg_len = Sqrt(vv);
            best_chain = acc + t*seg_len;
        }

        acc += Sqrt(vv);
        x1 = x2; y1 = y2; z1 = z2;
    }

    out_chain = best_chain;
    out_dist  = Sqrt(best_d2);
    return 0;
}

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


/*--------------------------- MAIN PANEL --------------------------*/
void mainPanel(){
 
    Text panelName="Lot Connections Creator";
    Panel              panel  = Create_panel              (panelName,TRUE);
    Vertical_Group     vgroup = Create_vertical_group     (-1         );
    Colour_Message_Box cmbMsg = Create_colour_message_box (""         );

    ///////////////////CREATE INPUT WIDGETS////////////////
    //TODO: create some input fields
    Source_Box          sb_bdys2d   = Create_source_box("of 2D lot boundaries",cmbMsg,0);
    Choice_Box          cb_drape    = Create_choice_box("Drape Polygons?",cmbMsg);
    Tin_Box             tb_surface  = Create_tin_box("TIN for draping polygons",cmbMsg,CHECK_TIN_MUST_EXIST);
    Real_Box            rb_off      = Create_real_box("Offset distance from bdy",cmbMsg);
    Source_Box          sb_acadLC   = Create_source_box("Point of connection", cmbMsg, 0);
    Model_Box           mb_model    = Create_model_box("Output model for property controls", cmbMsg, CHECK_MODEL_CREATE);
    Log_Box             lb          = Create_log_box("Log", 520, 80); 
    
    ///////////////ADDING BUTTONS ALONG THE BOTTOM///////////////////////////
    Horizontal_Group bgroup = Create_button_group();
    Button process          = Create_button       ("&Process" ,"process");
    Button finish           = Create_finish_button("Finish"   ,"Finish" );
    Button help_button      = Create_help_button  (panel      ,"Help"   );
    Button info_button      = Create_button("Click for instructions","Info");

    Append(info_button  ,bgroup);
    Append(process      ,bgroup);
    Append(finish       ,bgroup);
    Append(help_button  ,bgroup);

    //Choice box Drape Polygons choices
    Text choices[3];
    choices[1] = "No";
    choices[2] = "Highest TIN z";
    choices[3] = "Lowest TIN z";
    Set_data(cb_drape, 3, choices);
    ///////////////ADDING WIDGETS TO PANEL///////////////////////////
    //TODO: add your widgets to vgroup

    Append(sb_bdys2d    ,vgroup);
    Append(cb_drape     ,vgroup);
    Append(tb_surface   ,vgroup);
    Append(rb_off       ,vgroup);
    Append(sb_acadLC    ,vgroup);
    Append(mb_model     ,vgroup);
    Append(lb           ,vgroup);
    Append(cmbMsg       ,vgroup);
    Append(bgroup       ,vgroup);

    Append(vgroup,panel);
    Show_widget(panel);
    Set_data(cb_drape, "No", 1);
    Set_enable(tb_surface, 0);
   
    Integer doit = 1;
    while(doit)
    {
        Text cmd="",msg = "";
        Integer id,ret = Wait_on_widgets(id,cmd,msg);

        if (id == Get_id(info_button) && cmd == "Info")
        {
        Clear(lb);
        Add_log_line(lb, Create_text_log_line("Macro: Lot_Connection_Creator", 1));
        Add_log_line(lb, Create_text_log_line("Purpose: Create property-control super strings for lot connection.", 1));
        Add_log_line(lb, Create_text_log_line("Data required:", 1));
        Add_log_line(lb, Create_text_log_line(" -> Use closed polygons for lot bdys.", 1));
        Add_log_line(lb, Create_text_log_line(" -> Point of connection (PC) data drawn from inside to outside lots.", 1));
        Add_log_line(lb, Create_text_log_line("Outputs:", 1));
        Add_log_line(lb, Create_text_log_line(" -> Two coloured PC strings placed in the output model.", 1));
        Add_log_line(lb, Create_text_log_line(" -> PC strings take the polygon [lot] name.", 1));
        }

        //Get choice from Drape polygon widget
        Text drape_txt = "";
        Get_data(cb_drape, drape_txt);

        //Disable or enable TIN widget
        if(drape_txt == "No")
        {
            Set_enable(tb_surface, 0); //disable
        }
        else
        {
            Set_enable(tb_surface, 1); //enable
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
            if(cmd == "Help") doit = 0;
            {
                Print("Help is on the way");
            }
        }
        break; 
        case Get_id(process) :
        {
            if(cmd == "process")
            {
                Clear(lb);
                // Validate Source_Box → Dynamic_Element list
                Dynamic_Element dels2d, delsLC;
                if (Validate(sb_bdys2d, dels2d) != TRUE) { Set_data(cmbMsg, "Select 2D lot boundaries."); continue; }
                if (Validate(sb_acadLC, delsLC) != TRUE) { Set_data(cmbMsg, "Select lot connections (acad_LC)."); continue; }

                // Resolve model reliably
                Text model_name = "";
                Get_data(mb_model, model_name);
                if (model_name == "") { Set_data(cmbMsg, "Provide an output model name."); continue; }
                Model out_model = Get_model_create(model_name);
                if (!Model_exists(out_model)) { Set_data(cmbMsg, "Cannot create or get output model."); continue; }

                // Count
                Integer n2d = 0, nLC = 0;
                if (Get_number_of_items(dels2d, n2d) != 0 || n2d <= 0) { Set_data(cmbMsg, "No 2D elements selected."); continue; }
                if (Get_number_of_items(delsLC, nLC) != 0 || nLC <= 0) { Set_data(cmbMsg, "No acad_LC elements."); continue; }

                // Create a temp model to drape, find lowest/highest Z then delete model
                Text tmp_name = "TEMP DRAPED POLYGONS";
                Model tmp = Get_model_create(tmp_name); // create temp model

                Undo_List _ul;   // collects all “added” elements for one grouped Undo

                Integer made = 0, skipped = 0;
                for(Integer i=1; i<= n2d; i++)
                {
                    Element e2d;
                    Text nm = "";
                    Get_name(e2d, nm);

                    if(Get_item(dels2d, i, e2d) != 0) { skipped++; continue; }

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
                    
                    // Inward side by signed area
                    Real sarea = 0.0;
                    Real offset_from_bdy = 0.0;
                    if(Validate(rb_off, offset_from_bdy) == FALSE) break;

                    if (Plan_area_signed(e2d, sarea) != 0) { Print("area fail: <" + nm + ">\n"); skipped++; continue; }
                    Real ofs = (sarea > 0.0) ? +offset_from_bdy : -offset_from_bdy;

                    // Offset
                    Element e_off;
                    if (Super_offset(e2d, ofs, 2, e_off) != 0) { Print("offset failed: <" + nm + ">\n"); skipped++; continue; }

                    // Check choice box if using draped polygons
                    //Get choice from Drape polygon widget
                    Get_data(cb_drape, drape_txt);
                    if(drape_txt != "No")
                    {
                        // Validate TIN_Box → TIN Element
                        Tin tin; 
                        if (Validate(tb_surface,CHECK_TIN_MUST_EXIST, tin) == CHECK_TIN_MUST_EXIST) continue; // 8 = must exist
                        Text tname; Get_name(tin,tname);
                        // Print("Using TIN: " + tname + "\n");

                        // Drape e_off onto TIN
                        Dynamic_Element draped_poly;
                        Integer drc = Drape(tin, e_off, draped_poly);
                        if (drc != 0) { Print("Drape failed: <" + nm + ">\n"); skipped++; continue; }

                        // Set to temp model
                        Set_model(draped_poly, tmp);

                        // If draped success 
                        Integer nd=0; 
                        if (Get_number_of_items(draped_poly, nd) != 0 || nd == 0)
                        {
                            Print("No draped geometry for <" + nm + ">\n"); skipped++; continue;  
                        }
                        else
                        {
                            // Scan all vertices to find minZ and maxZ
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

                    }
                    
                    // two-split on original string with wrapped opposite chainage ---
                    Real inx=0.0, iny=0.0, outx=0.0, outy=0.0;
                    Element lc_found; Null(lc_found);
                    Integer f_rc = find_lc_inside_outside_xy(delsLC, e2d, inx, iny, outx, outy, lc_found);
                    
                    // validate lc_found (Element -> Uid -> Is_null)
                    Uid lc_uid; 
                    Get_id(lc_found, lc_uid);

                    if (f_rc != 0 || Is_null(lc_uid))
                    {
                        Text sname;
                        Get_name(e2d, sname);
                        log_err(lb, "No LC found inside " + sname);
                        continue;
                    }

                    // Duplicate LC twice
                    Element lc_copy1, lc_copy2;
                    Integer rLCcopy1 = Element_duplicate(lc_found, lc_copy1);
                    Integer rLCcopy2 = Element_duplicate(lc_found, lc_copy2);

                    if (rLCcopy1 != 0 || rLCcopy2 != 0)
                    {
                        log_err(lb, "Element_duplicate failed for this lot.");
                        continue;
                    }

                    Text scrStyle = "FLOW LINE REVERSE"; // or "LOT CONNECTION"
                    Set_style(lc_copy1, scrStyle);
                    Set_colour(lc_copy1,colour_pc1); // orange
                    Set_style(lc_copy2, scrStyle);
                    Set_colour(lc_copy2,colour_pc2); // brown

                    //get x y z of lc_copy
                    Real LCx1, LCy1, LCz1;
                    Integer rLC = Get_super_vertex_coord(lc_copy1, 1, LCx1, LCy1, LCz1);       // first vertex of lc_copy1

                    if (f_rc == 0)
                    {
                        Real L=0.0, chSA=0.0, d=0.0;
                        Integer rcL = Get_length(e_off, L);

                        Integer rch = chainage_at_xy(e_off, inx, iny, chSA, d);
                        //Print("diag: L=" + To_text(L) + " rcL=" + To_text(rcL) + " ch=" + To_text(chSA) + " rch=" + To_text(rch) + " d=" + To_text(d) + "\n");
                        if (rcL == 0 && rch == 0 && L > 0.0)
                        {
                            Real halfL = L * 0.5;

                            // Split @ chSA
                            Element sA, sB;
                            Element s_pre, s_post;
                            Integer rcS = Split_string(e_off, chSA, sA, sB);
                            
                            if(rcS != 0)
                            {
                                Set_data(cmbMsg,"Split failed at specified chainage.");
                                continue;
                            }
                            // 2) Pick the “true split” piece = one with more vertices than the original
                            Integer n0,nA,nB;
                            Get_points(e_off, n0);
                            Get_points(sA, nA);
                            Get_points(sB, nB);

                            // Determine which part gained the extra vertex
                            Element keep;
                            if (nA > n0 && nA > nB)
                                keep = sA;
                            else if (nB > n0 && nB > nA)
                                keep = sB;
                            else
                                keep = sA; // fallback if counts equal
                            // Save the true split piece
                            e_off = keep;

                            // Inputs available: Element keep; Real chSA, L, halfL;
                            // Compute chainage to split at
                            Real chSplit = chSA - L + halfL;

                            //Check if using TIN z values for split location
                            Real chTarget = chSplit;
                            Integer rc2 = 0;
                           
                            // If lowest TIN z choice is selected
                            if(drape_txt == "Lowest TIN z")
                            {
                                Real dtmp = 0.0;
                                Integer rc_ch = chainage_at_xy(keep, minX, minY, chTarget, dtmp);
                                if(rc_ch == 0)
                                {
                                    Real ch_low = chSA - L + chTarget;
                                    rc2 = Split_string(keep,ch_low, s_pre, s_post);
                                }
                                if (rc_ch != 0) { Print("chainage_at_xy(lowest Z) failed\n"); }
                            }
                            else if (drape_txt == "Highest TIN z")
                            {
                                Real dtmp = 0.0;
                                Integer rc_ch = chainage_at_xy(keep, maxX, maxY, chTarget, dtmp);
                                if(rc_ch == 0)
                                {
                                    Real ch_high = chSA - L + chTarget;
                                    rc2 = Split_string(keep,ch_high, s_pre, s_post);
                                }
                                if (rc_ch != 0) { Print("chainage_at_xy(highest Z) failed\n"); }
                            }
                            
                            // split using the selected chainage
                            if(drape_txt == "No")
                            {
                                rc2 = Split_string(keep, chTarget, s_pre, s_post); // §5.62.11 Strings Edits
                            }

                            // Handle result
                            if (rc2 == 0)
                            {
                                // Successful split: keep both pieces
                                Text sname;
                                Get_name(e2d, sname);
                                
                                // Check names, styles, colours
                                Set_name(s_pre, sname);
                                Set_style(s_pre, scrStyle);
                                Set_colour(s_pre,colour_pc1); // orange
                                Set_name(s_post, sname);
                                Set_style(s_post, scrStyle);
                                Set_colour(s_post,colour_pc2); // brown

                                //Set start chainage to zero
                                Real ch_end_pre = 0, ch_end_post = 0;
                                Set_chainage(s_pre,  ch_end_pre); // start = 0
                                Set_chainage(s_post, ch_end_post); // start = 0

                                //Reverse string so they go from the furthest inside the lot to the outside
                                Element s_pre_rev;
                                if(String_reverse(s_pre, s_pre_rev) == 0);
                                {
                                    Real x1, y1, z1;
                                    Integer s_pre_v = 0, s_post_v = 0;

                                    // join s_pre (its LAST vertex is the split)
                                    Get_points(s_pre_rev, s_pre_v);
                                    Get_super_vertex_coord(s_pre_rev,s_pre_v, x1, y1, z1);       // last vertex of s_pre_rev 
                                    Element joined_pre;
                                    Join_strings(s_pre_rev,x1, y1, z1, lc_copy1, LCx1, LCy1, LCz1, joined_pre);    // §5.62.11 Strings Edits
                                    
                                    // join s_post_rev (its LAST vertex is now the split)                                  
                                    Get_points(s_post, s_post_v);
                                    Get_super_vertex_coord(s_post,s_post_v, x1, y1, z1);       // last vertex of s_post

                                    Element joined_post;
                                    Join_strings(s_post,x1, y1, z1, lc_copy2,LCx1, LCy1, LCz1, joined_post); 

                                    //Reverse both so it flows opposite string direction
                                    Element joined_pre_rev;
                                    Element joined_post_rev;
                                    String_reverse(joined_pre, joined_pre_rev);
                                    String_reverse(joined_post, joined_post_rev);

                                    // Set to model
                                    Set_model(joined_pre_rev, out_model);
                                    Set_model(joined_post_rev, out_model);
                                    Element_delete(s_pre);

                                    if (Element_exists(joined_pre_rev) != 0) {            // Check if Element_exists
                                    Undo u_pre  = Add_undo_add("Create property control: pre",  joined_pre_rev);   // tells Undo system “this was added”
                                    Append(u_pre,  _ul);                                                       // §5.66.2 Append ID=1560
                                    }
                                    if (Element_exists(joined_post_rev) != 0) {
                                    Undo u_post = Add_undo_add("Create property control: post", joined_post_rev);
                                    Append(u_post, _ul); 
                                    }

                                    {
                                    // highlight both results
                                    Uid m1, s1, m2, s2; Model mx;
                                    Get_model(joined_pre_rev, mx);  Get_id(mx, m1);  Get_id(joined_pre_rev, s1);  Null(mx);
                                    Get_model(joined_post_rev, mx); Get_id(mx, m2);  Get_id(joined_post_rev, s2); Null(mx);

                                    Log_Line hl1 = Create_highlight_string_log_line("Created <" + sname + "> PC 1", 1, m1, s1); // ID 2664
                                    Log_Line hl2 = Create_highlight_string_log_line("Created <" + sname + "> PC 2", 1, m2, s2); // ID 2664
                                    Add_log_line(lb, hl1);
                                    Add_log_line(lb, hl2);
                                    }
                                }
                            }
                            else
                            {
                                Print("Split failed @ch=" + To_text(chSplit) + "\n");
                            }
                        }

                    }
                     made++;
                }
                // --- tidy up temp drape model ---
                if (Model_exists(tmp_name) != 0)   // §5.34 Models
                {
                    tmp = Get_model(tmp_name);
                    Model_delete(tmp);                // §5.34 Models
                }
                // Manual: §5.66.2 Add_undo_list() — groups many items into a single Ctrl-Z entry ID=1568
                if (made > 0) 
                {
                Add_undo_list("Create Property Controls", _ul);  // one Edit ⇒ Undo removes all created strings
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
