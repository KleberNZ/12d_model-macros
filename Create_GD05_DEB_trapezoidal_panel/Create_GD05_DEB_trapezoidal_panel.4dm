/*---------------------------------------------------------------------
**   Programmer:           KLP
**   Date:                 2026-06-15
**   12D Model:            V15
**   Version:              001
**   Macro Name:           Create_GD05_DEB_trapezoidal_panel.4dm
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
#include "standard_library.h"
#include "size_of.h"

/*global variables*/{


}

// ----------------------------- PANEL -----------------------------
void mainPanel(){

    Text panelName="GD05 DEB strings creator";
    Panel              panel  = Create_panel              (panelName,TRUE);
    Vertical_Group     vgroup = Create_vertical_group     (-1         );
    Colour_Message_Box cmbMsg = Create_colour_message_box (""         );

    ///////////////////CREATE INPUT WIDGETS////////////////
    //TODO: create some input fields
    Model_Box mb_output_model = Create_model_box("Output model",cmbMsg,CHECK_MODEL_CREATE);
    Name_Box  nb_deb_name     = Create_name_box ("Output DEB name",cmbMsg);

    XYZ_Box   xyz_origin      = Create_xyz_box  ("Origin X Y Z",cmbMsg);
    Angle_Box ab_bearing      = Create_angle_box("Bearing ddd.mmssfff",cmbMsg);

    Real_Box  rb_tob_length  = Create_real_box("TOB length",cmbMsg);
    Real_Box  rb_lw_ratio     = Create_real_box ("Length / width ratio",cmbMsg);
    Real_Box  rb_crest_width  = Create_real_box ("Crest width",cmbMsg);
    Real_Box  rb_spill_width  = Create_real_box ("Spillway base width",cmbMsg);
    Real_Box  rb_storage_depth= Create_real_box ("Storage depth",cmbMsg);
    Real_Box  rb_tob_rl       = Create_real_box ("TOB RL",cmbMsg);

    Set_data(nb_deb_name      ,"DEB_001");
    Set_data(xyz_origin       ,0.0,0.0,0.0);
    Set_data(ab_bearing       ,0.0);
    Set_data(rb_tob_length           ,19.75);
    Set_data(rb_lw_ratio      ,3.0);
    Set_data(rb_crest_width   ,1.0);
    Set_data(rb_spill_width   ,1.5);
    Set_data(rb_storage_depth ,1.0);
    Set_data(rb_tob_rl        ,0.0);


    ///////////////ADDING BUTTONS ALONG THE BOTTOM///////////////////////////
    Horizontal_Group bgroup = Create_button_group();
    Button process     = Create_button       ("&Process" ,"process");
    Button finish      = Create_finish_button("Finish"   ,"Finish" );
    Button help_button = Create_help_button  (panel      ,"Help"   );

    Append(process     ,bgroup);
    Append(finish      ,bgroup);
    Append(help_button ,bgroup);

    ///////////////ADDING WIDGETS TO PANEL///////////////////////////
    //TODO: add your widgets to vgroup
    Append(mb_output_model ,vgroup);
    Append(nb_deb_name     ,vgroup);
    Append(xyz_origin      ,vgroup);
    Append(ab_bearing      ,vgroup);
    Append(rb_tob_length        ,vgroup);
    Append(rb_lw_ratio     ,vgroup);
    Append(rb_crest_width  ,vgroup);
    Append(rb_spill_width  ,vgroup);
    Append(rb_storage_depth,vgroup);
    Append(rb_tob_rl       ,vgroup);

    Append(cmbMsg      ,vgroup);
    Append(bgroup      ,vgroup);

    Append(vgroup,panel);
    Show_widget(panel);

    // ----------------------------- EVENT LOOP -----------------------------
    Integer doit = 1;

    while(doit)
    {
        Text cmd="",msg = "";
        Integer id,ret = Wait_on_widgets(id,cmd,msg);

        switch(cmd)
        {
        case "keystroke" :
        case "set_focus" :
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
            if(cmd == "Panel Quit")  doit = 0;
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

                    Text deb_name;
                    if(Validate(nb_deb_name,deb_name)==FALSE) break;

                    Real origin_x=0.0,origin_y=0.0,origin_z=0.0;
                    if(Validate(xyz_origin,origin_x,origin_y,origin_z)==FALSE) break;

                    Real bearing_rad=0.0;
                    if(Validate(ab_bearing,bearing_rad)==FALSE) break;

                    Real tob_length=0.0;
                    if(Validate(rb_tob_length,tob_length)==FALSE) break;

                    Real lw_ratio=0.0;
                    if(Validate(rb_lw_ratio,lw_ratio)==FALSE) break;

                    Real crest_width=0.0;
                    if(Validate(rb_crest_width,crest_width)==FALSE) break;

                    Real spillway_base_width=0.0;
                    if(Validate(rb_spill_width,spillway_base_width)==FALSE) break;

                    Real storage_depth=0.0;
                    if(Validate(rb_storage_depth,storage_depth)==FALSE) break;

                    Real tob_rl=0.0;
                    if(Validate(rb_tob_rl,tob_rl)==FALSE) break;


                    // fixed DEB batters from SRP trapezoidal macro pattern
                    Real side_batter_left  = 2.0;
                    Real side_batter_right = 2.0;
                    Real entry_batter      = 3.0;
                    Real outlet_batter     = 2.0;
                    Real spillway_batter   = 2.0;

                    Real length_growth = entry_batter + outlet_batter;
                    Real width_growth  = side_batter_left + side_batter_right;
                    Real primary_spillway_drop = 0.35;


                    // validate widgets
                    if(lw_ratio < 3.0 || lw_ratio > 5.0)
                    {
                        Set_data(cmbMsg,"Length / width ratio must be between 3 and 5");
                        Set_focus(rb_lw_ratio);
                        break;
                    }

                    if(crest_width <= 0.0)
                    {
                        Set_data(cmbMsg,"Crest width must be > 0.0 m");
                        Set_focus(rb_crest_width);
                        break;
                    }

                    if(spillway_base_width < 1.5)
                    {
                        Set_data(cmbMsg,"Spillway base width must be >= 1.5 m");
                        Set_focus(rb_spill_width);
                        break;
                    }

                    if(storage_depth <= 0.0)
                    {
                        Set_data(cmbMsg,"Storage depth must be > 0.0 m");
                        Set_focus(rb_storage_depth);
                        break;
                    }

                    if(storage_depth > 1.0)
                    {
                        Set_data(cmbMsg,"Storage depth must be <= 1.0 m");
                        Set_focus(rb_storage_depth);
                        break;
                    }

                    Real top_storage_length = tob_length - primary_spillway_drop * length_growth;

                    if(top_storage_length <= 0.0)
                    {
                        Set_data(cmbMsg,"Calculated top storage length must be > 0.0 m");
                        Set_focus(rb_tob_length);
                        break;
                    }

                    Real top_storage_width = top_storage_length / lw_ratio;

                    Real base_length = top_storage_length - length_growth * storage_depth;
                    Real base_width  = top_storage_width  - width_growth  * storage_depth;

                    Real minimum_top_storage_width  = 2.0 + width_growth * storage_depth;
                    Real minimum_top_storage_length = lw_ratio * minimum_top_storage_width;
                    Real minimum_tob_length = minimum_top_storage_length + primary_spillway_drop * length_growth;

                    if(tob_length < minimum_tob_length)
                    {
                        Set_data(cmbMsg,
                            "TOB length too short. Minimum = "
                            + To_text(minimum_tob_length,3)
                            + " m for selected depth and ratio");
                        Set_focus(rb_tob_length);
                        break;
                    }

                    if(base_width < 2.0)
                    {
                        Set_data(cmbMsg,"Calculated base width must be >= 2.0 m");
                        Set_focus(rb_tob_length);
                        break;
                    }

                    if(base_length <= 0.0)
                    {
                        Set_data(cmbMsg,"Calculated base length must be > 0.0 m");
                        Set_focus(rb_tob_length);
                        break;
                    }


                    // do calc

                    Real storage_rl = tob_rl - primary_spillway_drop;
                    Real spillway_base_rl = storage_rl + 0.10;
                    Real entry_weir_rl = tob_rl - 0.10;
                    Real invert_rl  = storage_rl - storage_depth;

                    Real crest_outer_length = tob_length + 2.0 * crest_width;
                    Real crest_outer_width  = top_storage_width + primary_spillway_drop * width_growth + 2.0 * crest_width;

                    Real storage_volume =
                        base_length * base_width * storage_depth
                        + 0.5 * (base_length * width_growth + base_width * length_growth)
                        * storage_depth * storage_depth
                        + (length_growth * width_growth / 3.0)
                        * storage_depth * storage_depth * storage_depth;

                    Text tob_name      = deb_name + " TOB";
                    Text crest_name    = deb_name + " Crest Outer";
                    Text storage_name  = deb_name + " Top Storage";
                    Text base_name     = deb_name + " Base";
                    Text spillway_name = deb_name + " Spillway";

                    Undo undo_add;
                    Undo_List undo_list;
                    Null(undo_list);

                    Dynamic_Element de_all;
                    Null(de_all);

                    // ---------------- Unrotated geometry ----------------
                    // Long side runs in Y direction, width runs in X direction.

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
                    // The spillway inside base is 0.10 m above storage RL and is
                    // offset 0.2 m outwards from the top storage line.
                    Real spillway_inside_offset = 0.2;
                    Real entry_weir_offset = 0.10 * entry_batter;   // 0.10 * 3.0 = 0.30
                    Real spill_base_y = storage_y_max + spillway_inside_offset;

                    // The outside base of the emergency spillway is offset outwards
                    // from the spillway inside edge by 0.25 m plus crest width.
                    Real spill_outer_base_y = spill_base_y + 1.0 + crest_width;

                    // Spillway side width at TOB level uses the vertical difference
                    // between TOB RL and spillway base RL.
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
                            "Spillway top width exceeds crest outer width. Reduce spillway width.");
                        Set_focus(rb_spill_width);
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

                    // Outer crest entry weir mirrors the inner TOB entry weir outwards.
                    Real entry_outer_top_y  = crest_y_min;
                    Real entry_outer_base_y = crest_y_min - entry_weir_offset;

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

                    Set_name(entry_weir_super,deb_name + " Entry Weir");
                    Set_model(entry_weir_super,output_model);
                    Set_colour(entry_weir_super,518);
                    Set_super_use_segment_colour(entry_weir_super,1);
                    Set_super_segment_colour(entry_weir_super,1,518);

                    Append(entry_weir_super,de_all);

                    if(entry_weir_top_width > top_storage_width)
                    {
                        Set_data(cmbMsg,"Entry weir top width exceeds top storage width. Reduce spillway width.");
                        Set_focus(rb_spill_width);
                        break;
                    }

                    // ---------------- Rotate once at end ----------------
                    Real rotate_ang = 0.0;
                    Bearing_to_angle(bearing_rad,rotate_ang);
                    Rotate(de_all,origin_x,origin_y,rotate_ang - 1.5707963267948966);

                    // ---------------- Add grouped undo ----------------
                    undo_add = Add_undo_add("Create " + deb_name,de_all);
                    Append(undo_add,undo_list);
                    Add_undo_list("Create " + deb_name,undo_list);

                    Set_data(cmbMsg,
                        "Strings created. TOB length="
                        + To_text(tob_length,3)
                        + "m, Top storage="
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
        break;

        default :
        {
            if(cmd == "Finish") doit = 0;
        }
        break;
        }
    }
}

// ----------------------------- MAIN -----------------------------
void main(){

    //TODO: do pre-panel checks here

    mainPanel();
}