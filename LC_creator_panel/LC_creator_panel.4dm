/*---------------------------------------------------------------------
**   Programmer:KLeber Lessa do Prado
**   Date:04/11/25             
**   12D Model:            V15
**   Version:              001
**   Macro Name:           LC_creator_panel.4dm
**   Type:                 SOURCE
**
**   Brief description: 
**   Create 2D Lot Connection super strings from each
**   selected lot to the nearest drainage segment, one LC per lot.
**
**---------------------------------------------------------------------
**   Description: Description
**  The macro offsets each selected lot boundary inward by a user-defined
**  distance, evaluates the shortest perpendicular from the offset boundary
**  to the selected drainage string(s), and creates a 2-vertex 2D super
**  string (“LC”). One LC is created per lot.
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
#include "..\\..\\include/standard_library.H"
#include "..\\..\\include/size_of.H"
#include "..\\..\\include/set_ups.H"

/*global variables*/{

}

// ---------- Helpers ----------

// Point-to-segment projection in 2D. Returns distance; t_out in [0,1].
Real Point_Seg_Proj_2D(Real px, Real py, Real x1, Real y1, Real x2, Real y2, Real &t_out)
{
    Real vx = x2 - x1, vy = y2 - y1;
    Real vv = vx*vx + vy*vy;
    if (vv <= 0.0) { t_out = 0.0;
    return Sqrt((px - x1)*(px - x1) + (py - y1)*(py - y1));
    }
    Real t = ((px - x1)*vx + (py - y1)*vy) / vv;
    if (t < 0.0) t = 0.0; if (t > 1.0) t = 1.0;
    t_out = t;
    Real cx = x1 + t*vx, cy = y1 + t*vy;
    return Sqrt((px - cx)*(px - cx) + (py - cy)*(py - cy));
}

void mainPanel(){
 
    Text panelName="Lot Connections (LC) Creator";
    Panel              panel  = Create_panel              (panelName,TRUE);
    Vertical_Group     vgroup = Create_vertical_group     (-1         );
    Colour_Message_Box cmbMsg = Create_colour_message_box (""         );

    ///////////////////CREATE INPUT WIDGETS////////////////
    Source_Box         sb_drain         = Create_source_box(" of drainage strings",cmbMsg,0);
    Source_Box         sb_lots          = Create_source_box("lot boundaries",cmbMsg,0);
    Real_Box           rb_g_lot_offset  = Create_real_box("Offset from bdy",cmbMsg); Set_data(rb_g_lot_offset, 1.0);// default offset = 1.0 m
    Real_Box           rb_tol           = Create_real_box("Search distance",cmbMsg); Set_data(rb_tol, 5);// default offset = 5.0 m
    Model_Box          mb_LC            = Create_model_box("Model for LC strings",cmbMsg,CHECK_MODEL_CREATE);
    
    ///////////////ADDING BUTTONS ALONG THE BOTTOM///////////////////////////
    Horizontal_Group bgroup = Create_button_group();
    Button process          = Create_button       ("&Process" ,"process");
    Button finish           = Create_finish_button("Finish"   ,"Finish" );
    Button help_button      = Create_help_button  (panel      ,"Help"   );
    Append(process      ,bgroup);
    Append(finish       ,bgroup);
    Append(help_button  ,bgroup);
    ///////////////ADDING WIDGETS TO PANEL///////////////////////////
    Append(sb_drain         , panel);
    Append(sb_lots          , panel);
    Append(rb_g_lot_offset  , panel);
    Append(rb_tol           , panel);
    Append(mb_LC            , panel);

    Append(cmbMsg       ,vgroup);
    Append(bgroup       ,vgroup);
    Append(vgroup       ,panel);
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
                Print ("=== Lot Connections Creator Macro ===\n");  
                // Validate widget inputs
                Dynamic_Element drains;
                Integer rc_drain = Validate(sb_drain, drains);
                if (rc_drain == 0) { Print("Drainage source: drastic error\n"); break; } // FALSE
                if (rc_drain ==-2) { Print("At least 1 drainage element is needed!\n"); break; } // FALSE cmbMsg = "At least 1 drainage element is needed!" 
                Integer n_drains = 0; Get_number_of_items(drains, n_drains);       // dynamic array size
                if (n_drains == 0) { Print("No drainage elements selected\n"); break; }

                Dynamic_Element lots; if (Validate(sb_lots, lots) != 1) { Print("Lot source invalid\n"); continue; }
                Real tol; if (Validate(rb_tol, tol) != 1 || tol <= 0.0) { Print("Search distance must be > 0\n"); continue; }
                Real g_lot_offset; if (Validate(rb_g_lot_offset, g_lot_offset) != 1 || g_lot_offset <= 0.0) {Print("Offset from bdy must be > 0\n"); continue; }

                Model lc_model;
                Integer rc_mb = Validate(mb_LC, CHECK_MODEL_CREATE, lc_model);
                //Print("rc_mb = " + To_text(rc_mb) + "\n");

                // If rc_mb == NO_NAME, model name exists as text but not in project
                if (rc_mb == NO_MODEL) {
                    Text lc_model_name;
                    Get_data(mb_LC, lc_model_name);  // fetch text from widget
                    if (Text_length(lc_model_name) > 0) {
                        lc_model = Get_model_create(lc_model_name);  // create and assign model handle
                        //Print("Created new LC model: " + lc_model_name + "\n");
                        rc_mb = MODEL_EXISTS;  // normalise return for rest of macro
                    }
                }

                // handle invalid case
                if (rc_mb == NO_NAME) {
                    Print("Invalid or blank LC model selection.\n");
                    break;
                }
              
                //User inputs were validated. Proceed.
                Print ("<User inputs were validated. Ok to proceed.>\n");

                // Prepare models
                Model temp_off_mdl = Get_model_create("TEMP OFFSET MODEL TO BE DELETED"); 

                // Start counter -  Number of LC created
                Integer lc_created = 0;

                // ---- Precompute inward offsets for each lot ----
                Dynamic_Element lots_off;
                Integer n_lots = 0; Get_number_of_items(lots, n_lots);
                Print(To_text(n_lots) + " Lot boundary(s) were selected.\n");

                Undo_List undo_list;

                // Loop through lot bdys and create offsets
                for (Integer pre_li = 1; pre_li <= n_lots; pre_li = pre_li + 1)
                {
                    Element lot_elt; if (Get_item(lots, pre_li, lot_elt) != 0) continue;
                    Text lot_name; if (Get_name(lot_elt, lot_name) != 0) lot_name = "unnamed_lot";

                   // Validate polygon (ID 3544: success==0; good==1)
                    Integer good_poly = 1;
                    Element poly_out;
                    if (Check_polygon(lot_elt, good_poly, poly_out) != 0 || good_poly != 1) {
                    Print("Bad polygon: "); Print(lot_name); Print("\n");
                    continue;
                    }

                    // Build inward offset once per lot
                    Element lot_off;
                    Integer rc = Super_offset(lot_elt, g_lot_offset, 2, lot_off);   // success == 0
                    if (rc != 0) rc = Super_offset(lot_elt, -g_lot_offset, 2, lot_off);
                    if (rc != 0) continue;

                    // Decide inward vs outward using midpoint test against ORIGINAL polygon
                    Integer inward_ok = 0;
                    Real ox, oy, oz;
                    if (Get_super_vertex_coord(lot_off, 1, ox, oy, oz) == 0)        // success == 0
                    {
                        Real sx, sy, sz;
                        if (Get_super_vertex_coord(lot_elt, 1, sx, sy, sz) != 0) { sx = ox; sy = oy; } // fallback

                        // Midpoint between original v1 and offset v1 avoids “on boundary” ambiguity
                        Real mx = 0.5 * (ox + sx);
                        Real my = 0.5 * (oy + sy);

                        // Use ORIGINAL polygon for inside test; returns 1 if inside
                        Integer inside_status;
                        inward_ok = (XY_inside_polygon(lot_elt, mx, my, inside_status) == 0);

                        // If not inside, rebuild with opposite offset sign
                        if (inside_status != 1) {
                        rc = Super_offset(lot_elt, -g_lot_offset, 2, lot_off);
                        if (rc != 0) continue;
                        }
                    }

                    // Keep original name and move to temp model
                    Set_name(lot_off, lot_name);
                    Set_model(lot_off, temp_off_mdl);

                    // Store for reuse
                    Append(lot_off, lots_off);
                }// ---- Finished precompute inward offsets for each lot ----
                
                // Refresh n_lots to match offsets count
                n_lots = 0; Get_number_of_items(lots_off, n_lots);
                // Print(To_text(n_lots) + " lots processed (offset). \n");

                // ---- Drainage loop ----
                for (Integer di = 1; di <= n_drains; di = di + 1)
                {
                    Element drain; Get_item(drains, di, drain);// fetch element
                    Text t; Get_type(drain, t);

                    // Type check - Is type drainage?
                    Text et; Get_type(drain, et);
                    if (et != "Drainage") { Print("Element is not Drainage\n"); continue; }

                    // Get drainage string flow direction
                    Integer flow_dir;
                    Get_drainage_flow(drain, flow_dir); 
                    if(flow_dir == 0);//Flow direction is opposite to string direction
                    if (flow_dir = 1);// Flow direction is the same as the string direction
                    
                    // Drainage segments
                    Integer n_drain_segs = 0; if (Get_segments(drain, n_drain_segs) != 0 || n_drain_segs <= 0) { Print("No drain segs\n"); continue; }
                    Text drain_name; if (Get_name(drain, drain_name) != 0) drain_name = "unnamed";

                    for (Integer i = n_drain_segs; i >= 1; i = i - 1)
                    {
                        Segment dseg; if (Get_segment(drain, i, dseg) != 0) continue;
                        Point dA, dB; if (Get_start(dseg, dA) != 0) continue; if (Get_end(dseg, dB) != 0) continue;

                        // Pipe name via attribute (ID 1020; success == 1)
                        Text seg_name; if (Get_drainage_pipe_attribute(drain, i, "pipe name", seg_name) != 0) seg_name = "unnamed_pipe";
                        // Print("Processing pipe [" + seg_name + "]\n");

                        // Downstream reference for metric and projected point calc
                        Real ax = Get_x(dA), ay = Get_y(dA);
                        Real bx = Get_x(dB), by = Get_y(dB);
                        Real seg_dx = bx - ax, seg_dy = by - ay;
                        Real seg_len = Sqrt(seg_dx*seg_dx + seg_dy*seg_dy);
                        if (seg_len <= 0.0) continue;

                        // ---- Each lot (using prebuilt offsets) ----
                        for (Integer li = 1; li <= n_lots; li = li + 1)
                        {
                            Element lot_off; if (Get_item(lots_off, li, lot_off) != 0) continue;
                            Element lot_elt; if (Get_item(lots,     li, lot_elt) != 0) continue; // original
                            Text lot_name; if (Get_name(lot_off, lot_name) != 0) lot_name = "unnamed_lot";
                            //Print(lot_name + " and " + seg_name + " being processed.\n" );

                            // Best candidate accumulators
                            Integer have_best = 0;
                            Real best_metric = 1.0e99;
                            Real best_dmin   = 1.0e99;
                            Real best_vx = 0.0, best_vy = 0.0, best_z = 0.0;
                            Real best_tpar = 0.0;

                            // Iterate vertices of offset super
                            Integer vi = 1;
                            while (1)
                            {
                                Real vx, vy, vz;
                                if (Get_super_vertex_coord(lot_off, vi, vx, vy, vz) != 0) break;

                                Real tpar;
                                Real dmin = Point_Seg_Proj_2D(vx, vy, ax, ay, bx, by, tpar);
                                if (dmin <= tol)
                                {
                                // metric from downstream end
                                Real metric = (flow_dir == 0 ? (1.0 - tpar) : tpar) * seg_len;

                                // Interpolate pipe invert for info (not used for LC Z)
                                Real lhs, rhs, z_at = vz;
                                if (Get_drainage_pipe_inverts(drain, i, lhs, rhs) == 0)
                                    z_at = lhs + tpar * (rhs - lhs);

                                if (have_best == 0 || metric < best_metric || (metric == best_metric && dmin < best_dmin)) {
                                    have_best  = 1;
                                    best_metric = metric;
                                    best_dmin   = dmin;
                                    best_vx = vx; best_vy = vy; best_z = z_at;
                                    best_tpar = tpar;
                                }
                                }
                                vi = vi + 1;
                            } // vertex loop

                            if (have_best == 1)
                            {
                                // --- Skip if this lot already has an LC (by name prefix) ---
                                //Print("Checking if LC existing for " + lot_name + "\n");
                                Text lc_model_name = "";
                                Get_data(mb_LC, lc_model_name);
                                Text lc_name; lc_name = lot_name + "-PC";
                                Element lc_found;
                                Integer lc_count = 0;

                                // Find_element(Text model_name, Text element_name, Element &first_found, Integer &count)
                                // returns 0 on success. If lc_count > 0, an LC with this exact name exists.
                                Integer rc_fe = Find_element(lc_model_name, lc_name, lc_found, lc_count);
                                //Print("rc_fe = [" + To_text(rc_fe) + "]\n");
                                //Print("Total no of elements found is " + To_text(lc_count) + "\n");
                                
                                if (rc_fe == 0 && lc_count > 0) {
                                //Print(lot_name + "connection already exist. [" + To_text(lc_count) + "]\n");
                                // Skip creating another LC for this lot+pipe
                                continue;
                                }// End of skipping

                                //Print(lc_name + " Does not exist. Create one.\n");
                                // Build projected point on pipe
                                Real lc_x2 = ax + best_tpar * (bx - ax);
                                Real lc_y2 = ay + best_tpar * (by - ay);

                                // Zero-length guard
                                Real dx12 = lc_x2 - best_vx;
                                Real dy12 = lc_y2 - best_vy;
                                if (Sqrt(dx12*dx12 + dy12*dy12) < 0.01) {
                                // Skip degenerate
                                continue;
                                }

                                // Create 2D LC super (flags=0 -> XY only)
                                Integer flags = 0;
                                Integer mode  = 0;
                                Integer npts  = 2;
                                Element lc_super = Create_super(flags, mode, npts);

                                if (Set_super_vertex_coord(lc_super, 1, best_vx, best_vy, 0.0) != 0) { Print("LC v1 set fail\n"); continue; }
                                if (Set_super_vertex_coord(lc_super, 2, lc_x2,  lc_y2,  0.0) != 0) { Print("LC v2 set fail\n");continue; }

                                // Name then attach to output model immediately so later segments detect duplicates
                                Integer drain_colour = 0;
                                Set_name(lc_super, lc_name);
                                Model lc_mdl = Get_model(lc_model_name);
                                Set_model(lc_super, lc_mdl);
                                Get_colour(drain, drain_colour);
                                Set_colour(lc_super, drain_colour);

                                // ensure dimensions on
                                Set_super_use_2d_level(lc_super, 1);   // harmless if already 1

                                // recompute element extents
                                Integer rc_ext = Calc_extent(lc_super);

                                lc_created = lc_created + 1;
                                
                                // Create Undo list
                                Undo u_add = Add_undo_add("Create LC " + lc_name, lc_super);
                                // Add to list of undo
                                Append(u_add, undo_list); 

                            }
                        }// lots loop
                    }// drain seg loop
                }// drain data set loop
                // recompute model extents so views refresh correctly
                Calc_extent(lc_model);

                // Print number of LC created
                if(lc_created > 0) Print("Total LC created: " + To_text(lc_created) + ".\n");
                    else
                Print("No LC string created.\n");

                // delete temp offset model
                Model_delete(temp_off_mdl);
                // at the end of processing all lots/drainage
                Integer u_no = 0;
                Get_number_of_items(undo_list, u_no);
                if (u_no > 0) {
                    Add_undo_list("Create Lot Connections", undo_list);
                    Null(undo_list);  // clear list for safety
                }
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
void main()
{
    mainPanel();
}