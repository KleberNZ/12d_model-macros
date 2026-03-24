/*---------------------------------------------------------------------
**   Programmer:KLP
**   Date:24/03/26             
**   12D Model:            V15
**   Version:              001
**   Macro Name:           Create_GD05_SRP_trapezoidal_pond_panel.4dm
**   Type:                 SOURCE
**
**   Brief description: Creates a GD05 Sediment Retention Pond (SRP) 
**   using panel inputs, generating super string geometry for embankment,
**   crest, water surface, base, and level spreader.
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
/*global variables*/{

}

void mainPanel(){
 
    Text panelName="GD05 SRP rectangular trapezoidal pond";
    Panel              panel  = Create_panel              (panelName,TRUE);
    Vertical_Group     vgroup = Create_vertical_group     (-1         );
    Colour_Message_Box cmbMsg = Create_colour_message_box (""         );

    ///////////////////CREATE INPUT WIDGETS////////////////
    Model_Box  mb_output_model   = Create_model_box("Output model",cmbMsg,CHECK_MODEL_CREATE);
    Name_Box   nb_string_name    = Create_name_box("Pond Name",cmbMsg);
    XYZ_Box    xyzb_origin       = Create_xyz_box("Origin",cmbMsg);
    Angle_Box  ab_bearing        = Create_angle_box("Bearing (ddd.mmssfff)",cmbMsg);
    Real_Box   rb_tob_rl         = Create_real_box("Top of Enbankment RL",cmbMsg);
    Real_Box   rb_crest_width    = Create_real_box("Crest width",cmbMsg);
    Real_Box   rb_long_side      = Create_real_box("Long side length",cmbMsg);
    Real_Box   rb_ratio          = Create_real_box("Length/Width ratio (3-5)",cmbMsg);
    Real_Box   rb_storage_depth  = Create_real_box("Storage depth (1-2m)",cmbMsg);
    Real_Box   rb_spillway_base_width = Create_real_box("Spillway base width (min. 6m)",cmbMsg);

    Set_data(xyzb_origin, 0, 0, 0);
    Set_data(ab_bearing,0.0);
    Set_data(rb_crest_width,1.0);
    Set_data(rb_ratio,3.0);
    Set_data(rb_storage_depth,1.0);
    Set_data(rb_spillway_base_width,6.0);
    
    ///////////////ADDING BUTTONS ALONG THE BOTTOM///////////////////////////
    Horizontal_Group bgroup = Create_button_group();
    Button process     = Create_button       ("&Process" ,"process");
    Button finish      = Create_finish_button("Finish"   ,"Finish" );
    Button help_button = Create_help_button  (panel      ,"Help"   );
    Append(process      ,bgroup);
    Append(finish       ,bgroup);
    Append(help_button  ,bgroup);

    ///////////////ADDING WIDGETS TO PANEL///////////////////////////
    Vertical_Group vg_location_levels = Create_vertical_group(2);
    Vertical_Group vg_srp_shape       = Create_vertical_group(2);
    Vertical_Group vg_output          = Create_vertical_group(2);

    Set_border(vg_location_levels,"Location and Levels");
    Set_border(vg_srp_shape      ,"SRP Shape Parameters");
    Set_border(vg_output         ,"Output");

    Append(xyzb_origin   ,vg_location_levels);
    Append(ab_bearing    ,vg_location_levels);
    Append(rb_tob_rl     ,vg_location_levels);

    Append(rb_long_side     ,vg_srp_shape);
    Append(rb_ratio         ,vg_srp_shape);
    Append(rb_crest_width   ,vg_srp_shape);
    Append(rb_spillway_base_width ,vg_srp_shape);
    Append(rb_storage_depth ,vg_srp_shape);

    Append(mb_output_model,vg_output);
    Append(nb_string_name ,vg_output);

    Append(vg_location_levels,vgroup);
    Append(vg_srp_shape      ,vgroup);
    Append(vg_output         ,vgroup);

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
                // declare your widget variables
                Model output_model;
                if(Validate(mb_output_model,GET_MODEL_CREATE,output_model)!=MODEL_EXISTS) break;

                Text string_name;
                if(Validate(nb_string_name,string_name)==FALSE) break;

                Real origin_x=0.0,origin_y=0.0,origin_z=0.0;
                if(Validate(xyzb_origin,origin_x,origin_y,origin_z)==FALSE) break;

                Real bearing_rad=0.0;
                if(Validate(ab_bearing,bearing_rad)==FALSE) break;

                Real embankment_rl=0.0;
                if(Validate(rb_tob_rl,embankment_rl)==FALSE) break;
                
                Real crest_width=0.0;
                if(Validate(rb_crest_width,crest_width)==FALSE) break;

                Real freeboard = 0.3;
                Real spillway_rl = embankment_rl - freeboard;
                Real wse_rl = spillway_rl - 0.3;

                Real long_side=0.0;
                if(Validate(rb_long_side,long_side)==FALSE) break;

                Real ratio=0.0;
                if(Validate(rb_ratio,ratio)==FALSE) break;

                Real storage_depth=0.0;
                if(Validate(rb_storage_depth,storage_depth)==FALSE) break;

                // validate widgets
                if(long_side <= 0.0)
                {
                    Set_data(cmbMsg,"Long side length must be > 0");
                    break;
                }

                if(ratio < 3.0 || ratio > 5.0)
                {
                    Set_data(cmbMsg,"Length/Width ratio must be between 3 and 5");
                    break;
                }

                if(crest_width <= 0.5)
                {
                    Set_data(cmbMsg,"Crest width must be > 0.5");
                    break;
                }

                Real spillway_base_width = 0.0;
                if(Validate(rb_spillway_base_width,spillway_base_width)==FALSE) break;

                if(spillway_base_width < 6.0)
                {
                    Set_data(cmbMsg,"Spillway base width must be > 6");
                    break;
                }

                Real width = long_side / ratio;
                Real spillway_depth = 0.3;
                Real spillway_side_batter = 2.0;
                Real spillway_side_run = spillway_depth * spillway_side_batter;
                Real spillway_top_width = spillway_base_width + 2.0 * spillway_side_run;
                Real max_spillway_base_width = width - 2.0 * spillway_side_run;

                if(spillway_top_width > width)
                {
                    Set_data(cmbMsg,
                        "Spillway top width exceeds embankment short side. Maximum spillway base width = "
                        + To_text(max_spillway_base_width,3));
                    break;
                }

                // do calc
                Text embankment_name     = string_name + " Top of Embankment";
                Text pond_edge_name      = string_name + " Pond Edge";
                Text wse_name            = string_name + " WSE";
                Text base_name           = string_name + " Base";
                Text level_spreader_name = string_name + " Level Spreader";

                // Pond side slope batters
                Real side_batter_left  = 2.0;
                Real side_batter_right = 2.0;
                Real entry_batter      = 3.0;
                Real out_batter        = 2.0;

                Real base_rl            = wse_rl - storage_depth;
                Real level_spreader_rl  = spillway_rl + 0.15;
                Real embankment_dh      = embankment_rl - wse_rl;
                Real level_spreader_dh  = level_spreader_rl - wse_rl;

                Undo undo_add;
                Undo_List undo_list;
                Null(undo_list);
                Dynamic_Element de_all;
                Null(de_all);

                // ---------------- Unrotated geometry ----------------
                // Top of embankment rectangle extents
                Real emb_x_min = origin_x;
                Real emb_x_max = origin_x + width;
                Real emb_y_min = origin_y;
                Real emb_y_max = origin_y + long_side;

                // Emergency spillway geometry - centred on outlet side
                Real emb_centre_x = (emb_x_min + emb_x_max) / 2.0;

                Real emb_spill_top_left_x   = emb_centre_x - spillway_top_width  / 2.0;
                Real emb_spill_top_right_x  = emb_centre_x + spillway_top_width  / 2.0;
                Real emb_spill_base_left_x  = emb_centre_x - spillway_base_width / 2.0;
                Real emb_spill_base_right_x = emb_centre_x + spillway_base_width / 2.0;

                Real emb_spill_top_y  = emb_y_max;
                Real emb_spill_base_y = emb_y_max - spillway_side_run;

                // Pond crest rectangle extents
                Real crest_x_min = emb_x_min - crest_width;
                Real crest_x_max = emb_x_max + crest_width;
                Real crest_y_min = emb_y_min - crest_width;
                Real crest_y_max = emb_y_max + crest_width;

                // Crest spillway notch
                Real crest_spill_top_width  = spillway_top_width;
                Real crest_spill_base_width = spillway_base_width;
                Real crest_centre_x         = (crest_x_min + crest_x_max) / 2.0;

                Real crest_spill_top_left_x   = crest_centre_x - crest_spill_top_width  / 2.0;
                Real crest_spill_top_right_x  = crest_centre_x + crest_spill_top_width  / 2.0;
                Real crest_spill_base_left_x  = crest_centre_x - crest_spill_base_width / 2.0;
                Real crest_spill_base_right_x = crest_centre_x + crest_spill_base_width / 2.0;

                Real crest_spill_top_y  = crest_y_max;
                Real crest_spill_base_y = crest_y_max + spillway_side_run;

                // WSE rectangle inset from embankment by batter * RL drop
                Real wse_x_min = emb_x_min + side_batter_left  * embankment_dh;
                Real wse_x_max = emb_x_max - side_batter_right * embankment_dh;
                Real wse_y_min = emb_y_min + entry_batter      * embankment_dh;
                Real wse_y_max = emb_y_max - out_batter        * embankment_dh;

                Real wse_width_calc  = wse_x_max - wse_x_min;
                Real wse_length_calc = wse_y_max - wse_y_min;

                if(wse_width_calc <= 0.0)
                {
                    Set_data(cmbMsg,"WSE width <= 0. Increase width or reduce depth/freeboard.");
                    break;
                }

                if(wse_length_calc <= 0.0)
                {
                    Set_data(cmbMsg,"WSE length <= 0. Increase length or reduce depth/freeboard.");
                    break;
                }

                // Base rectangle inset from WSE by batter * storage depth
                Real base_x_min = wse_x_min + side_batter_left  * storage_depth;
                Real base_x_max = wse_x_max - side_batter_right * storage_depth;
                Real base_y_min = wse_y_min + entry_batter      * storage_depth;
                Real base_y_max = wse_y_max - out_batter        * storage_depth;

                Real base_width_calc  = base_x_max - base_x_min;
                Real base_length_calc = base_y_max - base_y_min;

                if(base_width_calc <= 0.0)
                {
                    Set_data(cmbMsg,"Base width <= 0. Increase width or reduce depth.");
                    break;
                }

                if(base_length_calc <= 0.0)
                {
                    Set_data(cmbMsg,"Base length <= 0. Increase length or reduce depth.");
                    break;
                }

                // Level spreader on entry side, centred on WSE width
                Real level_spreader_length = wse_width_calc + 1.2;
                Real level_spreader_width  = 0.05;
                Real level_spreader_offset = level_spreader_dh * entry_batter;
                Real wse_centre_x          = (wse_x_min + wse_x_max) / 2.0;

                Real ls_x_min = wse_centre_x - level_spreader_length / 2.0;
                Real ls_x_max = wse_centre_x + level_spreader_length / 2.0;
                Real ls_y_max = wse_y_min - level_spreader_offset;
                Real ls_y_min = ls_y_max - level_spreader_width;

                // ---------------- 1. Top of embankment ----------------
                Element embankment_super = Create_super(0,8);
                Set_super_use_3d_level(embankment_super,1);

                Set_super_data(embankment_super,1,emb_x_min,emb_y_min,embankment_rl,0.0,0);
                Set_super_data(embankment_super,2,emb_x_min,emb_y_max,embankment_rl,0.0,0);
                Set_super_data(embankment_super,3,emb_spill_top_left_x,emb_spill_top_y,embankment_rl,0.0,0);
                Set_super_data(embankment_super,4,emb_spill_base_left_x,emb_spill_base_y,spillway_rl,0.0,0);
                Set_super_data(embankment_super,5,emb_spill_base_right_x,emb_spill_base_y,spillway_rl,0.0,0);
                Set_super_data(embankment_super,6,emb_spill_top_right_x,emb_spill_top_y,embankment_rl,0.0,0);
                Set_super_data(embankment_super,7,emb_x_max,emb_y_max,embankment_rl,0.0,0);
                Set_super_data(embankment_super,8,emb_x_max,emb_y_min,embankment_rl,0.0,0);

                Set_name(embankment_super,embankment_name);
                Set_model(embankment_super,output_model);
                String_close(embankment_super);
                Set_colour(embankment_super,511);
                Set_super_use_segment_colour(embankment_super,1);
                Set_super_segment_colour(embankment_super,1,511);
                Set_super_segment_colour(embankment_super,2,511);
                Set_super_segment_colour(embankment_super,3,511);
                Set_super_segment_colour(embankment_super,4,511);
                Set_super_segment_colour(embankment_super,5,511);
                Set_super_segment_colour(embankment_super,6,511);
                Set_super_segment_colour(embankment_super,7,511);
                Set_super_segment_colour(embankment_super,8,511);

                Append(embankment_super,de_all);

                // ---------------- 2. Outside edge (pond crest) ----------------
                Element pond_edge_super = Create_super(0,8);
                Set_super_use_3d_level(pond_edge_super,1);

                Set_super_data(pond_edge_super,1,crest_x_min,crest_y_min,embankment_rl,0.0,0);
                Set_super_data(pond_edge_super,2,crest_x_min,crest_y_max,embankment_rl,0.0,0);
                Set_super_data(pond_edge_super,3,crest_spill_top_left_x,crest_spill_top_y,embankment_rl,0.0,0);
                Set_super_data(pond_edge_super,4,crest_spill_base_left_x,crest_spill_base_y,spillway_rl,0.0,0);
                Set_super_data(pond_edge_super,5,crest_spill_base_right_x,crest_spill_base_y,spillway_rl,0.0,0);
                Set_super_data(pond_edge_super,6,crest_spill_top_right_x,crest_spill_top_y,embankment_rl,0.0,0);
                Set_super_data(pond_edge_super,7,crest_x_max,crest_y_max,embankment_rl,0.0,0);
                Set_super_data(pond_edge_super,8,crest_x_max,crest_y_min,embankment_rl,0.0,0);

                Set_name(pond_edge_super,pond_edge_name);
                Set_model(pond_edge_super,output_model);
                String_close(pond_edge_super);
                Set_colour(pond_edge_super,511);
                Set_super_use_segment_colour(pond_edge_super,1);
                Set_super_segment_colour(pond_edge_super,1,511);
                Set_super_segment_colour(pond_edge_super,2,511);
                Set_super_segment_colour(pond_edge_super,3,511);
                Set_super_segment_colour(pond_edge_super,4,511);
                Set_super_segment_colour(pond_edge_super,5,511);
                Set_super_segment_colour(pond_edge_super,6,511);
                Set_super_segment_colour(pond_edge_super,7,511);
                Set_super_segment_colour(pond_edge_super,8,511);

                Append(pond_edge_super,de_all);

                // ---------------- 3. WSE ----------------
                Element pond_super = Create_super(0,4);
                Set_super_use_3d_level(pond_super,1);

                Set_super_data(pond_super,1,wse_x_min,wse_y_min,wse_rl,0.0,0);
                Set_super_data(pond_super,2,wse_x_min,wse_y_max,wse_rl,0.0,0);
                Set_super_data(pond_super,3,wse_x_max,wse_y_max,wse_rl,0.0,0);
                Set_super_data(pond_super,4,wse_x_max,wse_y_min,wse_rl,0.0,0);

                Set_name(pond_super,wse_name);
                Set_model(pond_super,output_model);
                String_close(pond_super);
                Set_colour(pond_super,523);
                Set_super_use_segment_colour(pond_super,1);
                Set_super_segment_colour(pond_super,1,523);
                Set_super_segment_colour(pond_super,2,523);
                Set_super_segment_colour(pond_super,3,523);
                Set_super_segment_colour(pond_super,4,523);

                Append(pond_super,de_all);

                // ---------------- 4. Pond base ----------------
                Element base_super = Create_super(0,4);
                Set_super_use_3d_level(base_super,1);

                Set_super_data(base_super,1,base_x_min,base_y_min,base_rl,0.0,0);
                Set_super_data(base_super,2,base_x_min,base_y_max,base_rl,0.0,0);
                Set_super_data(base_super,3,base_x_max,base_y_max,base_rl,0.0,0);
                Set_super_data(base_super,4,base_x_max,base_y_min,base_rl,0.0,0);

                Set_name(base_super,base_name);
                Set_model(base_super,output_model);
                String_close(base_super);
                Set_colour(base_super,515);
                Set_super_use_segment_colour(base_super,1);
                Set_super_segment_colour(base_super,1,515);
                Set_super_segment_colour(base_super,2,515);
                Set_super_segment_colour(base_super,3,515);
                Set_super_segment_colour(base_super,4,515);

                Append(base_super,de_all);

                // ---------------- 5. Level spreader ----------------
                Element level_spreader_super = Create_super(0,4);
                Set_super_use_3d_level(level_spreader_super,1);

                Set_super_data(level_spreader_super,1,ls_x_min,ls_y_min,level_spreader_rl,0.0,0);
                Set_super_data(level_spreader_super,2,ls_x_min,ls_y_max,level_spreader_rl,0.0,0);
                Set_super_data(level_spreader_super,3,ls_x_max,ls_y_max,level_spreader_rl,0.0,0);
                Set_super_data(level_spreader_super,4,ls_x_max,ls_y_min,level_spreader_rl,0.0,0);

                Set_name(level_spreader_super,level_spreader_name);
                Set_model(level_spreader_super,output_model);
                String_close(level_spreader_super);
                Set_colour(level_spreader_super,518);
                Set_super_use_segment_colour(level_spreader_super,1);
                Set_super_segment_colour(level_spreader_super,1,518);
                Set_super_segment_colour(level_spreader_super,2,518);
                Set_super_segment_colour(level_spreader_super,3,518);
                Set_super_segment_colour(level_spreader_super,4,518);

                Append(level_spreader_super,de_all);

                // ---------------- Rotate once at end ----------------
                Real rotate_ang = 0.0;
                Bearing_to_angle(bearing_rad,rotate_ang);
                Rotate(de_all,origin_x,origin_y,rotate_ang - 1.5707963267948966);

                // Add grouped undo
                undo_add = Add_undo_add("Create " + string_name,de_all);
                Append(undo_add,undo_list);
                Add_undo_list("Create " + string_name,undo_list);

                // Tell user, it is done
                Set_data(cmbMsg,"Process finished");
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

    mainPanel();
}