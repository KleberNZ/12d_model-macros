/*---------------------------------------------------------------------
**   Programmer:           KLP
**   Date:                 2026-06-16
**   12D Model:            V15
**   Version:              001
**   Macro Name:           Create_GD05_SRP_DEB_trapezoidal_panel.4dm
**   Type:                 SOURCE
**
**   Brief description: BriefDescription
**
**
**---------------------------------------------------------------------
**   Description: Creates GD05-compliant trapezoidal sediment control devices
**                from user-defined panel inputs. The macro supports both
**                Sediment Retention Pond (SRP) and Decanting Earth Bund (DEB)
**                layouts, with separate device-specific geometry, freeboard,
**                spillway, forebay, entry-weir and depth rules.
**
**                SRP mode includes forebay geometry and storage-depth checks.
**                DEB mode disables the forebay input, applies DEB base-width
**                and total-depth checks, and creates an entry weir opposite
**                the outlet spillway.
**
**                The macro creates the required 12d strings in the selected
**                output model and reports calculated storage volume to the
**                panel message box.
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

#define BUILD "version.0.001"

// ----------------------------- INCLUDES -----------------------------
#include "standard_library.H"
#include "size_of.h"

/*global variables*/{


}


void mainPanel(){

    Text panelName="GD05 SRP / DEB rectangular trapezoidal device";
    Panel              panel  = Create_panel              (panelName,TRUE);
    Vertical_Group     vgroup = Create_vertical_group     (-1         );
    Colour_Message_Box cmbMsg = Create_colour_message_box (""         );

    ///////////////////CREATE INPUT WIDGETS////////////////
    //TODO: create some input fields
    Choice_Box cb_device_type = Create_choice_box("Device Type",cmbMsg);
    Text device_choices[2];
    device_choices[1] = "SRP";
    device_choices[2] = "DEB";
    Set_data(cb_device_type,2,device_choices);
    Set_data(cb_device_type,"SRP");

    Model_Box  mb_output_model   = Create_model_box("Output model",cmbMsg,CHECK_MODEL_CREATE);
    Name_Box   nb_string_name    = Create_name_box("Pond Name",cmbMsg);
    XYZ_Box    xyzb_origin       = Create_xyz_box("Origin",cmbMsg);
    Angle_Box  ab_bearing        = Create_angle_box("Bearing (ddd.mmssfff)",cmbMsg);
    Real_Box   rb_tob_rl         = Create_real_box("Top of Embankment RL",cmbMsg);
    Real_Box   rb_crest_width    = Create_real_box("Crest width",cmbMsg);
    Real_Box   rb_long_side      = Create_real_box("Primary spillway (storage) length",cmbMsg);
    Real_Box   rb_ratio          = Create_real_box("Length/Width ratio (3-5)",cmbMsg);
    Real_Box   rb_storage_depth  = Create_real_box("Storage depth",cmbMsg);
    Real_Box   rb_spillway_base_width = Create_real_box("Spillway base width",cmbMsg);
    Real_Box   rb_forebay_width  = Create_real_box("Forebay Width",cmbMsg);

    Set_data(xyzb_origin, 0.0, 0.0, 0.0);
    Set_data(ab_bearing,0.0);
    Set_data(rb_crest_width,1.0);
    Set_data(rb_ratio,3.0);
    Set_data(rb_storage_depth,1.0);
    Set_data(rb_spillway_base_width,6.0);
    Set_data(rb_forebay_width,2.0);

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
    Vertical_Group vg_device          = Create_vertical_group(2);
    Vertical_Group vg_location_levels = Create_vertical_group(2);
    Vertical_Group vg_srp_shape       = Create_vertical_group(2);
    Vertical_Group vg_output          = Create_vertical_group(2);

    Set_border(vg_device         ,"Device");
    Set_border(vg_location_levels,"Location and Levels");
    Set_border(vg_srp_shape      ,"SRP / DEB Shape Parameters");
    Set_border(vg_output         ,"Output");

    Append(cb_device_type,vg_device);

    Append(xyzb_origin   ,vg_location_levels);
    Append(ab_bearing    ,vg_location_levels);
    Append(rb_tob_rl     ,vg_location_levels);

    Append(rb_long_side     ,vg_srp_shape);
    Append(rb_ratio         ,vg_srp_shape);
    Append(rb_crest_width   ,vg_srp_shape);
    Append(rb_spillway_base_width ,vg_srp_shape);
    Append(rb_storage_depth ,vg_srp_shape);
    Append(rb_forebay_width ,vg_srp_shape);

    Append(mb_output_model,vg_output);
    Append(nb_string_name ,vg_output);

    Append(vg_device         ,vgroup);
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
        case Get_id(cb_device_type) :
        {
            Text selected_device;
            if(Validate(cb_device_type,selected_device)==TRUE)
            {
                if(selected_device == "DEB")
                {
                    Set_enable(rb_forebay_width,FALSE);
                    Set_data(cmbMsg,"DEB selected: Forebay Width disabled and will be ignored.");
                }
                else
                {
                    Set_enable(rb_forebay_width,TRUE);
                    Set_data(cmbMsg,"SRP selected: Forebay Width enabled.");
                }
            }
        }
        break;
        case Get_id(process) :
        {
            if(cmd == "process")
            {
                //TODO: declare your widget variables
                Text selected_device;
                if(Validate(cb_device_type,selected_device)==FALSE) break;

                Model output_model;
                if(Validate(mb_output_model,GET_MODEL_CREATE,output_model)!=MODEL_EXISTS) break;

                Text string_name;
                if(Validate(nb_string_name,string_name)==FALSE) break;

                Real origin_x=0.0,origin_y=0.0,origin_z=0.0;
                if(Validate(xyzb_origin,origin_x,origin_y,origin_z)==FALSE) break;

                Real bearing_rad=0.0;
                if(Validate(ab_bearing,bearing_rad)==FALSE) break;

                Real tob_rl=0.0;
                if(Validate(rb_tob_rl,tob_rl)==FALSE) break;

                Real crest_width=0.0;
                if(Validate(rb_crest_width,crest_width)==FALSE) break;

                Real long_side=0.0;
                if(Validate(rb_long_side,long_side)==FALSE) break;

                Real ratio=0.0;
                if(Validate(rb_ratio,ratio)==FALSE) break;

                Real storage_depth=0.0;
                if(Validate(rb_storage_depth,storage_depth)==FALSE) break;

                Real spillway_base_width = 0.0;
                if(Validate(rb_spillway_base_width,spillway_base_width)==FALSE) break;

                Real forebay_width=0.0;
                if(selected_device == "SRP")
                {
                    if(Validate(rb_forebay_width,forebay_width)==FALSE) break;
                }

                //TODO: validate widgets
                if(selected_device != "SRP" && selected_device != "DEB")
                {
                    Set_data(cmbMsg,"Device Type must be SRP or DEB");
                    Set_focus(cb_device_type);
                    break;
                }

                if(long_side <= 0.0)
                {
                    Set_data(cmbMsg,"Primary spillway (storage) length must be > 0");
                    Set_focus(rb_long_side);
                    break;
                }

                if(ratio < 3.0 || ratio > 5.0)
                {
                    Set_data(cmbMsg,"Length/Width ratio must be between 3 and 5 at storage height");
                    Set_focus(rb_ratio);
                    break;
                }

                if(crest_width <= 0.0)
                {
                    Set_data(cmbMsg,"Crest width must be > 0.0 m");
                    Set_focus(rb_crest_width);
                    break;
                }

                if(storage_depth <= 0.0)
                {
                    Set_data(cmbMsg,"Storage depth must be > 0.0 m");
                    Set_focus(rb_storage_depth);
                    break;
                }

                //TODO: do calc

                if(selected_device == "SRP")
                {
                    if(storage_depth > 2.0)
                    {
                        Set_data(cmbMsg,"SRP storage depth must be <= 2.0 m from storage WSL RL to base");
                        Set_focus(rb_storage_depth);
                        break;
                    }

                    if(spillway_base_width < 6.0)
                    {
                        Set_data(cmbMsg,"SRP spillway base width must be >= 6.0 m");
                        Set_focus(rb_spillway_base_width);
                        break;
                    }

                    if(forebay_width < 2.0)
                    {
                        Set_data(cmbMsg,"SRP Forebay Width must be >= 2.0 m");
                        Set_focus(rb_forebay_width);
                        break;
                    }

                    Text embankment_name     = string_name + " Top of Embankment";
                    Text pond_edge_name      = string_name + " Pond Edge";
                    Text wse_name            = string_name + " WSE";
                    Text base_name           = string_name + " Base";
                    Text level_spreader_name = string_name + " Level Spreader";
                    Text forebay_top_name    = string_name + " Forebay Top";
                    Text forebay_base_name   = string_name + " Forebay Base";

                    Real side_batter_left  = 2.0;
                    Real side_batter_right = 2.0;
                    Real entry_batter      = 3.0;
                    Real out_batter        = 2.0;

                    Real embankment_rl      = tob_rl;
                    Real spillway_rl        = embankment_rl - 0.3;
                    Real wse_rl             = spillway_rl - 0.3;
                    Real base_rl            = wse_rl - storage_depth;
                    Real level_spreader_rl  = spillway_rl + 0.15;
                    Real embankment_dh      = embankment_rl - wse_rl;
                    Real level_spreader_dh  = level_spreader_rl - wse_rl;

                    Real wse_length_input = long_side;
                    Real wse_width_input  = long_side / ratio;

                    Real spillway_depth = 0.3;
                    Real spillway_side_batter = 2.0;
                    Real spillway_side_run = spillway_depth * spillway_side_batter;
                    Real spillway_top_width = spillway_base_width + 2.0 * spillway_side_run;
                    Real max_spillway_base_width = wse_width_input - 2.0 * spillway_side_run;

                    if(spillway_top_width > wse_width_input)
                    {
                        Set_data(cmbMsg,
                            "SRP spillway top width exceeds storage width. Maximum spillway base width = "
                            + To_text(max_spillway_base_width,3));
                        Set_focus(rb_spillway_base_width);
                        break;
                    }

                    Undo undo_add;
                    Undo_List undo_list;
                    Null(undo_list);
                    Dynamic_Element de_all;
                    Null(de_all);

                    // ---------------- Unrotated geometry ----------------
                    // Long side runs in Y direction, width runs in X direction.
                    // Length/width ratio is measured at storage WSL.
                    Real wse_x_min = origin_x;
                    Real wse_x_max = origin_x + wse_width_input;
                    Real wse_y_min = origin_y;
                    Real wse_y_max = origin_y + wse_length_input;

                    Real emb_x_min = wse_x_min - side_batter_left  * embankment_dh;
                    Real emb_x_max = wse_x_max + side_batter_right * embankment_dh;
                    Real emb_y_min = wse_y_min - entry_batter      * embankment_dh;
                    Real emb_y_max = wse_y_max + out_batter        * embankment_dh;

                    Real emb_width_calc = emb_x_max - emb_x_min;

                    if(spillway_top_width > emb_width_calc)
                    {
                        Set_data(cmbMsg,"SRP spillway top width exceeds embankment width.");
                        Set_focus(rb_spillway_base_width);
                        break;
                    }

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

                    Real crest_centre_x = (crest_x_min + crest_x_max) / 2.0;
                    Real crest_spill_top_left_x   = crest_centre_x - spillway_top_width  / 2.0;
                    Real crest_spill_top_right_x  = crest_centre_x + spillway_top_width  / 2.0;
                    Real crest_spill_base_left_x  = crest_centre_x - spillway_base_width / 2.0;
                    Real crest_spill_base_right_x = crest_centre_x + spillway_base_width / 2.0;

                    Real crest_spill_top_y  = crest_y_max;
                    Real crest_spill_base_y = crest_y_max + spillway_side_run;

                    // Base rectangle inset from storage WSL by batter * storage depth
                    Real base_x_min = wse_x_min + side_batter_left  * storage_depth;
                    Real base_x_max = wse_x_max - side_batter_right * storage_depth;
                    Real base_y_min = wse_y_min + entry_batter      * storage_depth;
                    Real base_y_max = wse_y_max - out_batter        * storage_depth;

                    Real base_width_calc  = base_x_max - base_x_min;
                    Real base_length_calc = base_y_max - base_y_min;

                    if(base_width_calc <= 0.0)
                    {
                        Set_data(cmbMsg,"SRP base width <= 0. Increase long side or reduce storage depth.");
                        Set_focus(rb_long_side);
                        break;
                    }

                    if(base_length_calc <= 0.0)
                    {
                        Set_data(cmbMsg,"SRP base length <= 0. Increase long side or reduce storage depth.");
                        Set_focus(rb_long_side);
                        break;
                    }

                    // Spreadsheet frustum formula:
                    // V = (D/6) * ((L_storage*W_storage) + (L_base*W_base)
                    //     + ((L_storage+L_base) * (W_storage+W_base)))
                    Real srp_storage_volume =
                        (storage_depth / 6.0)
                        * ((wse_length_input * wse_width_input)
                        +  (base_length_calc * base_width_calc)
                        + ((wse_length_input + base_length_calc)
                        *  (wse_width_input + base_width_calc)));

                    // Level spreader on entry side, centred on WSE width
                    Real level_spreader_length = wse_width_input + 1.2;
                    Real level_spreader_width  = 0.05;
                    Real level_spreader_offset = level_spreader_dh * entry_batter;
                    Real wse_centre_x          = (wse_x_min + wse_x_max) / 2.0;

                    Real ls_x_min = wse_centre_x - level_spreader_length / 2.0;
                    Real ls_x_max = wse_centre_x + level_spreader_length / 2.0;
                    Real ls_y_max = wse_y_min - level_spreader_offset;
                    Real ls_y_min = ls_y_max - level_spreader_width;

                    // Forebay geometry
                    Real forebay_depth = 1.0;
                    Real forebay_batter = 1.0;
                    Real forebay_inset = forebay_depth * forebay_batter;

                    Real forebay_top_rl = embankment_rl;
                    Real forebay_base_rl = level_spreader_rl - 1.0;

                    Real fb_top_x_min = emb_x_min;
                    Real fb_top_x_max = emb_x_max;
                    Real fb_top_y_max = emb_y_min;
                    Real fb_top_y_min = emb_y_min - forebay_width;

                    Real fb_base_x_min = fb_top_x_min + forebay_inset;
                    Real fb_base_x_max = fb_top_x_max - forebay_inset;
                    Real fb_base_y_max = fb_top_y_max - forebay_inset;
                    Real fb_base_y_min = fb_top_y_min + forebay_inset;

                    if(fb_base_x_max <= fb_base_x_min)
                    {
                        Set_data(cmbMsg,"SRP forebay base width <= 0. Increase long side.");
                        Set_focus(rb_long_side);
                        break;
                    }

                    if(fb_base_y_max < fb_base_y_min)
                    {
                        Set_data(cmbMsg,"SRP forebay base length < 0. Increase Forebay Width.");
                        Set_focus(rb_forebay_width);
                        break;
                    }

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

                    Set_super_data(pond_edge_super,1,crest_x_min,crest_y_min - forebay_width,embankment_rl,0.0,0);
                    Set_super_data(pond_edge_super,2,crest_x_min,crest_y_max,embankment_rl,0.0,0);
                    Set_super_data(pond_edge_super,3,crest_spill_top_left_x,crest_spill_top_y,embankment_rl,0.0,0);
                    Set_super_data(pond_edge_super,4,crest_spill_base_left_x,crest_spill_base_y,spillway_rl,0.0,0);
                    Set_super_data(pond_edge_super,5,crest_spill_base_right_x,crest_spill_base_y,spillway_rl,0.0,0);
                    Set_super_data(pond_edge_super,6,crest_spill_top_right_x,crest_spill_top_y,embankment_rl,0.0,0);
                    Set_super_data(pond_edge_super,7,crest_x_max,crest_y_max,embankment_rl,0.0,0);
                    Set_super_data(pond_edge_super,8,crest_x_max,crest_y_min - forebay_width,embankment_rl,0.0,0);

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

                    // ---------------- 4. Forebay top ----------------
                    Element forebay_top_super = Create_super(0,4);
                    Set_super_use_3d_level(forebay_top_super,1);

                    Set_super_data(forebay_top_super,1,fb_top_x_max,fb_top_y_max,forebay_top_rl,0.0,0);
                    Set_super_data(forebay_top_super,2,fb_top_x_max,fb_top_y_min,forebay_top_rl,0.0,0);
                    Set_super_data(forebay_top_super,3,fb_top_x_min,fb_top_y_min,forebay_top_rl,0.0,0);
                    Set_super_data(forebay_top_super,4,fb_top_x_min,fb_top_y_max,forebay_top_rl,0.0,0);

                    Set_name(forebay_top_super,forebay_top_name);
                    Set_model(forebay_top_super,output_model);
                    Set_colour(forebay_top_super,511);

                    Append(forebay_top_super,de_all);

                    // ---------------- 5. Forebay base ----------------
                    Element forebay_base_super = Create_super(0,4);
                    Set_super_use_3d_level(forebay_base_super,1);

                    Set_super_data(forebay_base_super,1,fb_base_x_min,fb_base_y_min,forebay_base_rl,0.0,0);
                    Set_super_data(forebay_base_super,2,fb_base_x_min,fb_base_y_max,forebay_base_rl,0.0,0);
                    Set_super_data(forebay_base_super,3,fb_base_x_max,fb_base_y_max,forebay_base_rl,0.0,0);
                    Set_super_data(forebay_base_super,4,fb_base_x_max,fb_base_y_min,forebay_base_rl,0.0,0);

                    Set_name(forebay_base_super,forebay_base_name);
                    Set_model(forebay_base_super,output_model);
                    String_close(forebay_base_super);
                    Set_colour(forebay_base_super,515);

                    Append(forebay_base_super,de_all);

                    // ---------------- 6. Pond base ----------------
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

                    // ---------------- 7. Level spreader ----------------
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

                    Set_data(cmbMsg,
                        "SRP strings created. Storage="
                        + To_text(wse_length_input,3)
                        + " x "
                        + To_text(wse_width_input,3)
                        + "m, Base="
                        + To_text(base_length_calc,3)
                        + " x "
                        + To_text(base_width_calc,3)
                        + "m, Vol="
                        + To_text(srp_storage_volume,3)
                        + "m3, WSE RL="
                        + To_text(wse_rl,3)
                        + ", Spillway RL="
                        + To_text(spillway_rl,3));
                }

                else
                {
                    Real side_batter_left  = 2.0;
                    Real side_batter_right = 2.0;
                    Real entry_batter      = 3.0;
                    Real outlet_batter     = 2.0;
                    Real spillway_batter   = 2.0;

                    Real length_growth = entry_batter + outlet_batter;
                    Real width_growth  = side_batter_left + side_batter_right;
                    Real primary_spillway_drop = 0.35;

                    if((storage_depth + primary_spillway_drop) > 1.0)
                    {
                        Set_data(cmbMsg,"DEB maximum depth from TOB RL to base RL must be <= 1.0 m");
                        Set_focus(rb_storage_depth);
                        break;
                    }

                    if(spillway_base_width < 1.5)
                    {
                        Set_data(cmbMsg,"DEB spillway base width must be >= 1.5 m");
                        Set_focus(rb_spillway_base_width);
                        break;
                    }

                    Real top_storage_length = long_side;
                    Real top_storage_width = top_storage_length / ratio;

                    // DEB storage_depth is the storage WSL / primary spillway RL to base depth.
                    Real base_length = top_storage_length - length_growth * storage_depth;
                    Real base_width  = top_storage_width  - width_growth  * storage_depth;

                    Real minimum_top_storage_width  = 2.0 + width_growth * storage_depth;
                    Real minimum_top_storage_length = ratio * minimum_top_storage_width;

                    if(top_storage_length < minimum_top_storage_length)
                    {
                        Set_data(cmbMsg,
                            "DEB storage length too short. Minimum = "
                            + To_text(minimum_top_storage_length,3)
                            + " m for selected depth and ratio");
                        Set_focus(rb_long_side);
                        break;
                    }

                    if(base_width < 2.0)
                    {
                        Set_data(cmbMsg,"DEB calculated base width must be >= 2.0 m");
                        Set_focus(rb_long_side);
                        break;
                    }

                    if(base_length <= 0.0)
                    {
                        Set_data(cmbMsg,"DEB calculated base length must be > 0.0 m");
                        Set_focus(rb_long_side);
                        break;
                    }

                    Real storage_rl = tob_rl - primary_spillway_drop;
                    Real spillway_base_rl = storage_rl + 0.10;
                    Real entry_weir_rl = tob_rl - 0.10;
                    Real invert_rl  = storage_rl - storage_depth;

                    Real crest_outer_length = top_storage_length + primary_spillway_drop * length_growth + 2.0 * crest_width;
                    Real crest_outer_width  = top_storage_width + primary_spillway_drop * width_growth + 2.0 * crest_width;

                    // Spreadsheet frustum formula:
                    // V = (D/6) * ((L_storage*W_storage) + (L_base*W_base)
                    //     + ((L_storage+L_base) * (W_storage+W_base)))
                    Real storage_volume =
                        (storage_depth / 6.0)
                        * ((top_storage_length * top_storage_width)
                        +  (base_length * base_width)
                        + ((top_storage_length + base_length)
                        *  (top_storage_width + base_width)));

                    Text tob_name      = string_name + " TOB";
                    Text crest_name    = string_name + " Crest Outer";
                    Text storage_name  = string_name + " Top Storage";
                    Text base_name     = string_name + " Base";
                    Text spillway_name = string_name + " Spillway";

                    Undo undo_add;
                    Undo_List undo_list;
                    Null(undo_list);

                    Dynamic_Element de_all;
                    Null(de_all);

                    // ---------------- Unrotated geometry ----------------
                    // Long side runs in Y direction, width runs in X direction.
                    // Length/width ratio is measured at storage height.

                    Real storage_x_min = origin_x;
                    Real storage_x_max = origin_x + top_storage_width;
                    Real storage_y_min = origin_y;
                    Real storage_y_max = origin_y + top_storage_length;

                    Real base_x_min = storage_x_min + side_batter_left  * storage_depth;
                    Real base_x_max = storage_x_max - side_batter_right * storage_depth;
                    Real base_y_min = storage_y_min + entry_batter      * storage_depth;
                    Real base_y_max = storage_y_max - outlet_batter     * storage_depth;

                    Real tob_side_left_offset  = primary_spillway_drop * side_batter_left;
                    Real tob_side_right_offset = primary_spillway_drop * side_batter_right;
                    Real tob_entry_offset      = primary_spillway_drop * entry_batter;
                    Real tob_outlet_offset     = primary_spillway_drop * outlet_batter;

                    Real tob_x_min = storage_x_min - tob_side_left_offset;
                    Real tob_x_max = storage_x_max + tob_side_right_offset;
                    Real tob_y_min = storage_y_min - tob_entry_offset;
                    Real tob_y_max = storage_y_max + tob_outlet_offset;

                    Real crest_x_min = tob_x_min - crest_width;
                    Real crest_x_max = tob_x_max + crest_width;
                    Real crest_y_min = tob_y_min - crest_width;
                    Real crest_y_max = tob_y_max + crest_width;

                    // Emergency spillway centred on outlet side.
                    Real spillway_inside_offset = 0.2;
                    Real entry_weir_offset = 0.10 * entry_batter;
                    Real spill_base_y = storage_y_max + spillway_inside_offset;

                    Real spill_outer_base_y = spill_base_y + 1.0 + crest_width;

                    Real spillway_depth = tob_rl - spillway_base_rl;
                    Real spillway_side_run = spillway_depth * spillway_batter;
                    Real spillway_top_width = spillway_base_width + 2.0 * spillway_side_run;

                    Real storage_centre_x = (storage_x_min + storage_x_max) / 2.0;

                    Real spill_top_left_x   = storage_centre_x - spillway_top_width  / 2.0;
                    Real spill_top_right_x  = storage_centre_x + spillway_top_width  / 2.0;
                    Real spill_base_left_x  = storage_centre_x - spillway_base_width / 2.0;
                    Real spill_base_right_x = storage_centre_x + spillway_base_width / 2.0;

                    Real spill_top_y = tob_y_max;

                    if(spillway_top_width > (crest_x_max - crest_x_min))
                    {
                        Set_data(cmbMsg,
                            "DEB spillway top width exceeds crest outer width. Reduce spillway width.");
                        Set_focus(rb_spillway_base_width);
                        break;
                    }

                    // Entry weir centred on entry side, opposite emergency spillway.
                    Real entry_weir_top_width = spillway_base_width + 2.0 * entry_weir_offset;

                    Real entry_centre_x = (tob_x_min + tob_x_max) / 2.0;

                    Real entry_top_left_x   = entry_centre_x - entry_weir_top_width  / 2.0;
                    Real entry_top_right_x  = entry_centre_x + entry_weir_top_width  / 2.0;
                    Real entry_base_left_x  = entry_centre_x - spillway_base_width / 2.0;
                    Real entry_base_right_x = entry_centre_x + spillway_base_width / 2.0;

                    Real entry_top_y  = tob_y_min;
                    Real entry_base_y = tob_y_min + entry_weir_offset;

                    Real entry_outer_top_y  = crest_y_min;
                    Real entry_outer_base_y = crest_y_min - entry_weir_offset;

                    if(entry_weir_top_width > top_storage_width)
                    {
                        Set_data(cmbMsg,"DEB entry weir top width exceeds top storage width. Reduce spillway width.");
                        Set_focus(rb_spillway_base_width);
                        break;
                    }

                    // ---------------- 1. TOB with spillway notch ----------------
                    Element tob_super = Create_super(0,12);
                    Set_super_use_3d_level(tob_super,1);

                    Set_super_data(tob_super,1,tob_x_min,tob_y_min,tob_rl,0.0,0);
                    Set_super_data(tob_super,2,entry_top_left_x,entry_top_y,tob_rl,0.0,0);
                    Set_super_data(tob_super,3,entry_base_left_x,entry_base_y,entry_weir_rl,0.0,0);
                    Set_super_data(tob_super,4,entry_base_right_x,entry_base_y,entry_weir_rl,0.0,0);
                    Set_super_data(tob_super,5,entry_top_right_x,entry_top_y,tob_rl,0.0,0);
                    Set_super_data(tob_super,6,tob_x_max,tob_y_min,tob_rl,0.0,0);
                    Set_super_data(tob_super,7,tob_x_max,tob_y_max,tob_rl,0.0,0);
                    Set_super_data(tob_super,8,spill_top_right_x,spill_top_y,tob_rl,0.0,0);
                    Set_super_data(tob_super,9,spill_base_right_x,spill_base_y,spillway_base_rl,0.0,0);
                    Set_super_data(tob_super,10,spill_base_left_x,spill_base_y,spillway_base_rl,0.0,0);
                    Set_super_data(tob_super,11,spill_top_left_x,spill_top_y,tob_rl,0.0,0);
                    Set_super_data(tob_super,12,tob_x_min,tob_y_max,tob_rl,0.0,0);

                    Set_name(tob_super,tob_name);
                    Set_model(tob_super,output_model);
                    String_close(tob_super);
                    Set_colour(tob_super,511);
                    Set_super_use_segment_colour(tob_super,1);
                    Set_super_segment_colour(tob_super,1,511);
                    Set_super_segment_colour(tob_super,2,511);
                    Set_super_segment_colour(tob_super,3,511);
                    Set_super_segment_colour(tob_super,4,511);
                    Set_super_segment_colour(tob_super,5,511);
                    Set_super_segment_colour(tob_super,6,511);
                    Set_super_segment_colour(tob_super,7,511);
                    Set_super_segment_colour(tob_super,8,511);
                    Set_super_segment_colour(tob_super,9,511);
                    Set_super_segment_colour(tob_super,10,511);
                    Set_super_segment_colour(tob_super,11,511);
                    Set_super_segment_colour(tob_super,12,511);

                    Append(tob_super,de_all);

                    // ---------------- 2. Crest outer with emergency spillway and entry weir shapes ----------------
                    Element crest_super = Create_super(0,12);
                    Set_super_use_3d_level(crest_super,1);

                    Set_super_data(crest_super,1,crest_x_min,crest_y_min,tob_rl,0.0,0);
                    Set_super_data(crest_super,2,crest_x_min,crest_y_max,tob_rl,0.0,0);
                    Set_super_data(crest_super,3,spill_top_left_x,crest_y_max,tob_rl,0.0,0);
                    Set_super_data(crest_super,4,spill_base_left_x,spill_outer_base_y,spillway_base_rl,0.0,0);
                    Set_super_data(crest_super,5,spill_base_right_x,spill_outer_base_y,spillway_base_rl,0.0,0);
                    Set_super_data(crest_super,6,spill_top_right_x,crest_y_max,tob_rl,0.0,0);
                    Set_super_data(crest_super,7,crest_x_max,crest_y_max,tob_rl,0.0,0);
                    Set_super_data(crest_super,8,crest_x_max,crest_y_min,tob_rl,0.0,0);
                    Set_super_data(crest_super,9,entry_top_right_x,entry_outer_top_y,tob_rl,0.0,0);
                    Set_super_data(crest_super,10,entry_base_right_x,entry_outer_base_y,entry_weir_rl,0.0,0);
                    Set_super_data(crest_super,11,entry_base_left_x,entry_outer_base_y,entry_weir_rl,0.0,0);
                    Set_super_data(crest_super,12,entry_top_left_x,entry_outer_top_y,tob_rl,0.0,0);

                    Set_name(crest_super,crest_name);
                    Set_model(crest_super,output_model);
                    String_close(crest_super);
                    Set_colour(crest_super,511);
                    Set_super_use_segment_colour(crest_super,1);
                    Set_super_segment_colour(crest_super,1,511);
                    Set_super_segment_colour(crest_super,2,511);
                    Set_super_segment_colour(crest_super,3,511);
                    Set_super_segment_colour(crest_super,4,511);
                    Set_super_segment_colour(crest_super,5,511);
                    Set_super_segment_colour(crest_super,6,511);
                    Set_super_segment_colour(crest_super,7,511);
                    Set_super_segment_colour(crest_super,8,511);
                    Set_super_segment_colour(crest_super,9,511);
                    Set_super_segment_colour(crest_super,10,511);
                    Set_super_segment_colour(crest_super,11,511);
                    Set_super_segment_colour(crest_super,12,511);

                    Append(crest_super,de_all);

                    // ---------------- 3. Top storage ----------------
                    Element storage_super = Create_super(0,4);
                    Set_super_use_3d_level(storage_super,1);

                    Set_super_data(storage_super,1,storage_x_min,storage_y_min,storage_rl,0.0,0);
                    Set_super_data(storage_super,2,storage_x_min,storage_y_max,storage_rl,0.0,0);
                    Set_super_data(storage_super,3,storage_x_max,storage_y_max,storage_rl,0.0,0);
                    Set_super_data(storage_super,4,storage_x_max,storage_y_min,storage_rl,0.0,0);

                    Set_name(storage_super,storage_name);
                    Set_model(storage_super,output_model);
                    String_close(storage_super);
                    Set_colour(storage_super,523);
                    Set_super_use_segment_colour(storage_super,1);
                    Set_super_segment_colour(storage_super,1,523);
                    Set_super_segment_colour(storage_super,2,523);
                    Set_super_segment_colour(storage_super,3,523);
                    Set_super_segment_colour(storage_super,4,523);

                    Append(storage_super,de_all);

                    // ---------------- 4. Base / invert ----------------
                    Element base_super = Create_super(0,4);
                    Set_super_use_3d_level(base_super,1);

                    Set_super_data(base_super,1,base_x_min,base_y_min,invert_rl,0.0,0);
                    Set_super_data(base_super,2,base_x_min,base_y_max,invert_rl,0.0,0);
                    Set_super_data(base_super,3,base_x_max,base_y_max,invert_rl,0.0,0);
                    Set_super_data(base_super,4,base_x_max,base_y_min,invert_rl,0.0,0);

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

                    // ---------------- 5. Spillway base line ----------------
                    Element spillway_super = Create_super(0,2);
                    Set_super_use_3d_level(spillway_super,1);

                    Set_super_data(spillway_super,1,spill_base_left_x,spill_base_y,spillway_base_rl,0.0,0);
                    Set_super_data(spillway_super,2,spill_base_right_x,spill_base_y,spillway_base_rl,0.0,0);

                    Set_name(spillway_super,spillway_name);
                    Set_model(spillway_super,output_model);
                    Set_colour(spillway_super,518);
                    Set_super_use_segment_colour(spillway_super,1);
                    Set_super_segment_colour(spillway_super,1,518);

                    Append(spillway_super,de_all);

                    // ---------------- 6. Entry weir base line ----------------
                    Element entry_weir_super = Create_super(0,2);
                    Set_super_use_3d_level(entry_weir_super,1);

                    Set_super_data(entry_weir_super,1,entry_base_left_x,entry_base_y,entry_weir_rl,0.0,0);
                    Set_super_data(entry_weir_super,2,entry_base_right_x,entry_base_y,entry_weir_rl,0.0,0);

                    Set_name(entry_weir_super,string_name + " Entry Weir");
                    Set_model(entry_weir_super,output_model);
                    Set_colour(entry_weir_super,518);
                    Set_super_use_segment_colour(entry_weir_super,1);
                    Set_super_segment_colour(entry_weir_super,1,518);

                    Append(entry_weir_super,de_all);

                    // ---------------- Rotate once at end ----------------
                    Real rotate_ang = 0.0;
                    Bearing_to_angle(bearing_rad,rotate_ang);
                    Rotate(de_all,origin_x,origin_y,rotate_ang - 1.5707963267948966);

                    // ---------------- Add grouped undo ----------------
                    undo_add = Add_undo_add("Create " + string_name,de_all);
                    Append(undo_add,undo_list);
                    Add_undo_list("Create " + string_name,undo_list);

                    Set_data(cmbMsg,
                        "DEB strings created. Storage="
                        + To_text(top_storage_length,3)
                        + " x "
                        + To_text(top_storage_width,3)
                        + "m, Base="
                        + To_text(base_length,3)
                        + " x "
                        + To_text(base_width,3)
                        + "m, Vol="
                        + To_text(storage_volume,3)
                        + "m3, Storage RL="
                        + To_text(storage_rl,3)
                        + ", Spillway RL="
                        + To_text(spillway_base_rl,3));
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
void main(){

    // do some checks before you go to the main panel


    mainPanel();
}
