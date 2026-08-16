/*---------------------------------------------------------------------
**   Programmer:           KLP
**   Date:                 2026-08-17
**   12D Model:            V15
**   Version:              001
**   Macro Name:           Create_mini_roundabout_SA_panel.4dm
**   Type:                 SOURCE
**
**   Brief description: BriefDescription
**
**
**---------------------------------------------------------------------
**   Description: Description
**
**  Create and calculate the mini-roundabout kerb return Super Alignment,
**  including horizontal geometry, vertical tie-ins, model assignment,
**  undo support and user feedback.
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

//============================HELPER FUNCTIONS==========================
// helper: validate selected string and return its name
Integer get_selected_string_name(New_Select_Box nsb,
                                 Text &string_name)
{
    Element e;

    string_name = "";

    if(Validate(nsb,e) != 1)
    {
        return 1;
    }

    if(Get_name(e,string_name) != 0)
    {
        string_name = "";
        return 1;
    }

    if(string_name == "")
    {
        return 1;
    }

    return 0;
}

// helper: build SA reference block text from an element
Integer sa_reference_text(Element &e, Text &ref_text)
{
    Model m;
    Uid element_uid;
    Uid model_uid;
    Text element_name;
    Text model_name;
    Text element_id;
    Text model_id;

    element_name = "";
    model_name = "";
    element_id = "";
    model_id = "";

    Get_name(e,element_name);
    Get_model(e,m);
    Get_name(m,model_name);
    Get_id(e,element_uid);
    Get_id(m,model_uid);
    Convert_uid(element_uid,element_id);
    Convert_uid(model_uid,model_id);

    ref_text =
        "reference { "
        + "model_name \"" + model_name + "\" "
        + "model_id " + model_id + " "
        + "name \"" + element_name + "\" "
        + "id " + element_id + " "
        + "}";

    Null(m);

    return 0;
}

// helper: build computator_horz_line_2_points part text
Integer build_horz_line_2_points_part(Integer part_id, Text part_name, Text start_ref, Real start_offset, Real start_ext, Text start_cut_ref, Integer start_cut_index, Text end_ref, Real end_offset, Real end_ext, Text end_cut_ref, Integer end_cut_index, Text &part_text)
{
    Text name_block;

    name_block = "";

    if(part_name != "")
    {
        name_block = "name \"" + part_name + "\" ";
    }

    part_text =
        "computator { "
        + "id " + To_text(part_id) + " "
        + name_block
        + "computator_horz_line_2_points { "
        + "valid true "
        + "start { "
        + "computator_horz_point_reference { "
        + "valid true "
        + "offset " + To_text(start_offset,3) + " "
        + "computator_horz_reference { "
        + "valid true "
        + "direction 1 "
        + "start_ext " + To_text(start_ext,3) + " "
        + start_ref + " "
        + "cut { "
        + start_cut_ref + " "
        + "index " + To_text(start_cut_index) + " "
        + "} "
        + "} "
        + "} "
        + "} "
        + "end { "
        + "computator_horz_point_reference { "
        + "valid true "
        + "offset " + To_text(end_offset,3) + " "
        + "computator_horz_reference { "
        + "valid true "
        + "direction 1 "
        + "start_ext " + To_text(end_ext,3) + " "
        + end_ref + " "
        + "cut { "
        + end_cut_ref + " "
        + "index " + To_text(end_cut_index) + " "
        + "} "
        + "} "
        + "} "
        + "} "
        + "} "
        + "}";

    return 0;
}
// helper: build floating_arc_end_radius_length part text
Integer build_floating_arc_end_radius_length_part(Integer part_id, Real radius, Real length, Text attach_to, Text &part_text)
{
    part_text =
        "floating_arc_end_radius_length { "
        + "id " + To_text(part_id) + " "
        + "radius " + To_text(radius,3) + " "
        + "length " + To_text(length,3) + " "
        + "attach_to " + attach_to + " "
        + "}";

    return 0;
}

// helper: build free_arc_radius part text
Integer build_free_arc_radius_part(Integer part_id, Real radius, Text &part_text)
{
    part_text =
        "free_arc_radius { "
        + "id " + To_text(part_id) + " "
        + "r " + To_text(radius,3) + " "
        + "}";

    return 0;
}

// helper: build computator_vertical_offset_part text
Integer build_computator_vertical_offset_part(Integer part_id, Text part_name, Text reference_text, Real slope, Real interval, Integer chainage_direction, Text start_ch_text, Text end_ch_text, Text &part_text)
{
    Text name_block;
    Text direction_block;

    name_block = "";
    direction_block = "";

    if(part_name != "")
    {
        name_block = "name \"" + part_name + "\" ";
    }

    if(chainage_direction != 0)
    {
        direction_block = "chainage_direction " + To_text(chainage_direction) + " ";
    }

    part_text =
        "computator { "
        + "id " + To_text(part_id) + " "
        + name_block
        + "computator_vertical_offset { "
        + "valid true "
        + direction_block
        + reference_text + " "
        + "slope " + To_text(slope,6) + " "
        + "interval " + To_text(interval,3) + " "
        + "start_ch { "
        + start_ch_text + " "
        + "} "
        + "end_ch { "
        + end_ch_text + " "
        + "} "
        + "} "
        + "}";

    return 0;
}

// helper: build free_parabola_compound part text
Integer build_free_parabola_compound_part(Integer part_id, Real ratio, Real length, Text &part_text)
{
    part_text =
        "free_parabola_compound { "
        + "id " + To_text(part_id) + " "
        + "ratio " + To_text(ratio,3) + " "
        + "length " + To_text(length,3) + " "
        + "}";

    return 0;
}

// helper: apply approach line sign
Integer apply_approach_line_sign(
    Integer dir,
    Real &offset_value,
    Real &ext_value
)
{
    if(dir == -1)
    {
        offset_value = Absolute(offset_value);
        ext_value    = Absolute(ext_value);
        return 0;
    }

    if(dir == 1)
    {
        offset_value = -Absolute(offset_value);
        ext_value    = -Absolute(ext_value);
        return 0;
    }

    return 1;
}

// helper: apply departure line sign
Integer apply_departure_line_sign(
    Integer dir,
    Real &offset_value,
    Real &ext_value
)
{
    if(dir == -1)
    {
        // against string direction:
        // RHS offset positive, distance negative
        offset_value = Absolute(offset_value);
        ext_value    = -Absolute(ext_value);
        return 0;
    }

    if(dir == 1)
    {
        // with string direction:
        // RHS offset negative, distance positive
        offset_value = -Absolute(offset_value);
        ext_value    = Absolute(ext_value);
        return 0;
    }

    return 1;
}

// helper: get trailing counter from string name, return 1 if no counter found
Integer get_trailing_counter(Text name_text, Integer &counter)
{
    Integer len;
    Integer i;
    Integer ch;
    Integer last_space;
    Text tail;

    len = Text_length(name_text);
    i = 0;
    ch = 0;
    last_space = 0;
    tail = "";
    counter = 0;

    if(len <= 0)
    {
        return 1;
    }

    for(i = len; i >= 1; i--)
    {
        if(Get_char(name_text,i,ch) != 0)
        {
            return 1;
        }

        if(ch == 32)
        {
            last_space = i;
            break;
        }
    }

    if(last_space <= 0 || last_space >= len)
    {
        return 1;
    }

    tail = Get_subtext(name_text,last_space + 1,len);

    if(From_text(tail,counter) != 0)
    {
        counter = 0;
        return 1;
    }

    return 0;
}

// helper: update kerb return name display from selected strings and internal counter
Integer update_sa_name_suggestion(
    New_Select_Box nsb_approach,
    New_Select_Box nsb_departure,
    Integer counter,
    Input_Box ib_sa_name
)
{
    Text approach_name = "";
    Text departure_name = "";
    Text sa_name = "";

    Set_data(ib_sa_name,"");

    if(get_selected_string_name(nsb_approach,approach_name) != 0)
    {
        return 0;
    }

    if(get_selected_string_name(nsb_departure,departure_name) != 0)
    {
        return 0;
    }

    sa_name = approach_name + " to " + departure_name + " " + To_text(counter);
    Set_data(ib_sa_name,sa_name);

    return 0;
}
// helper: add undo for created SA
Integer add_created_sa_undo(Text undo_name, Element &sa)
{
    Add_undo_add(undo_name,sa);
    return 0;
}
// ----------------------------- PANEL -----------------------------
void mainPanel(){

    Text panelName="Create Mini Roundabout SA";
    Panel              panel  = Create_panel              (panelName,TRUE);
    Vertical_Group     vgroup = Create_vertical_group     (-1         );
    Colour_Message_Box cmbMsg = Create_colour_message_box (""         );
    Integer sa_name_counter = 1;

    ///////////////////CREATE INPUT WIDGETS////////////////
    //Create some input fields
    New_Select_Box nsb_approach = Create_new_select_box("Pick CL   " ,"Select approach string (pick with direction)" ,SELECT_STRING,cmbMsg);
    New_Select_Box nsb_departure = Create_new_select_box("Pick CL   " ,"Select departure string (pick with direction)" ,SELECT_STRING,cmbMsg);

    Model_Box   mb_output                   = Create_model_box("Model Name",cmbMsg,CHECK_MODEL_CREATE);
    Input_Box ib_sa_name                    = Create_input_box("String Name",cmbMsg);
    Set_data(ib_sa_name,"");
    
    Real_Box rb_approach_width      = Create_real_box   ("Lane Width",cmbMsg);
    Real_Box rb_departure_width     = Create_real_box   ("Lane Width",cmbMsg);
    Real_Box rb_tangent_offset     = Create_real_box   ("Tangent Offset",cmbMsg);

    Real_Box rb_radius = Create_real_box("Radius",cmbMsg);
    Real_Box rb_arc_length = Create_real_box("Arc Length",cmbMsg);

    Set_data(rb_tangent_offset, 10.5);
    Set_data(rb_approach_width, 2.7);
    Set_data(rb_departure_width, 2.7);
    Set_data(rb_radius, 4.0);
    Set_data(rb_arc_length, 4.0);

    ///////////////ADDING BUTTONS ALONG THE BOTTOM///////////////////////////
    Horizontal_Group bgroup = Create_button_group();
    Button process     = Create_button       ("&Process" ,"process");
    Button finish      = Create_finish_button("Finish"   ,"Finish" );
    Button help_button = Create_help_button  (panel      ,"Help"   );
    Append(process     ,bgroup);
    Append(finish      ,bgroup);
    Append(help_button ,bgroup);

    ///////////////ADDING WIDGETS TO PANEL///////////////////////////
    //Add your widgets to vgroup
    Vertical_Group curve_group = Create_vertical_group(-1);
    Horizontal_Group curve_row = Create_horizontal_group(1);

    Vertical_Group approach_group = Create_vertical_group(-1);
    Horizontal_Group approach_row = Create_horizontal_group(2);

    Vertical_Group departure_group = Create_vertical_group(-1);
    Horizontal_Group departure_row = Create_horizontal_group(2);

    Vertical_Group output_group = Create_vertical_group(-1);
    
    // Curve parameters
    Append(rb_tangent_offset     ,curve_group);
    Append(curve_row      ,curve_group);
    Append(rb_radius             ,curve_group);
    Append(rb_arc_length         ,curve_group);
    Set_border(curve_group,"Curve Parameters");

    // Approach section
    Append(rb_approach_width,approach_row);
    Append(nsb_approach     ,approach_row);
    Append(approach_row     ,approach_group);
    Set_border(approach_group,"Approach");


    // Departure section
    Append(rb_departure_width,departure_row);
    Append(nsb_departure     ,departure_row);
    Append(departure_row     ,departure_group);
    Set_border(departure_group,"Departure");

    // Output section
    Append(ib_sa_name            ,output_group);
    Append(mb_output             ,output_group);
    Set_border(output_group,"Output");

    Append(curve_group     ,vgroup);
    Append(approach_group  ,vgroup);
    Append(departure_group ,vgroup);
    Append(output_group    ,vgroup);

    update_sa_name_suggestion
    (
        nsb_approach,
        nsb_departure,
        sa_name_counter,
        ib_sa_name
    );

    Append(cmbMsg ,vgroup);
    Append(bgroup ,vgroup);
    Append(vgroup ,panel);
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
        case Get_id(nsb_approach) :
        {
            update_sa_name_suggestion
            (
                nsb_approach,
                nsb_departure,
                sa_name_counter,
                ib_sa_name
            );
        }
        break;

        case Get_id(nsb_departure) :
        {
            update_sa_name_suggestion
            (
                nsb_approach,
                nsb_departure,
                sa_name_counter,
                ib_sa_name
            );
        }
        break;

        case Get_id(process) :
        {
            if(cmd == "process")
            {
                Element approach;
                Element departure;
                Element sa;

                Integer approach_dir = 1;
                Integer departure_dir = 1;

                Model approach_model;
                Model departure_model;
                Model output_model;

                Text approach_name = "";
                Text departure_name = "";
                Text approach_model_name = "";
                Text departure_model_name = "";
                Text output_model_name = "";
                Text sa_name = "";
                Text undo_name = "";

                Real approach_width = 0.0;
                Real departure_width = 0.0;
                Real tangent_offset = 0.0;
                Real radius = 0.0;
                Real arc_length = 0.0;

                Text approach_ref = "";
                Text departure_ref = "";
                Text part_text = "";
                Text vert_part_text = "";
                Text start_ch_text = "";
                Text end_ch_text = "";

                Integer part_id = 100;
                Integer vert_part_id = 800;
                Integer counter = sa_name_counter;

                Real app_offset_start = 0.0;
                Real app_offset_end = 0.0;
                Real dep_offset_start = 0.0;
                Real dep_offset_end = 0.0;

                Real app_ext_start = 0.0;
                Real app_ext_end = 0.0;
                Real dep_ext_start = 0.0;
                Real dep_ext_end = 0.0;

                Integer rc1 = Validate(nsb_approach,approach);
                Integer rc2 = Validate(nsb_departure,departure);
                Integer rc_dir1 = Get_select_direction(nsb_approach,approach_dir);
                Integer rc_dir2 = Get_select_direction(nsb_departure,departure_dir);
                Integer rc3 = Validate(mb_output,GET_MODEL_CREATE,output_model);
                Integer rc4 = Validate(rb_approach_width,approach_width);
                Integer rc5 = Validate(rb_departure_width,departure_width);
                Integer rc6 = Validate(rb_tangent_offset,tangent_offset);
                Integer rc7 = Validate(rb_radius,radius);
                Integer rc8 = Validate(rb_arc_length,arc_length);
                Integer rc_name = Get_data(ib_sa_name,sa_name);

                if(rc_dir1 != 0){Set_data(cmbMsg,"Failed to get approach direction"); continue;}
                if(rc_dir2 != 0){Set_data(cmbMsg,"Failed to get departure direction"); continue;}

                if(rc1 != TRUE){Set_data(cmbMsg,"Select a valid approach string"); continue;}
                if(rc2 != TRUE){Set_data(cmbMsg,"Select a valid departure string"); continue;}

                if(rc3 != MODEL_EXISTS){Set_data(cmbMsg,"Select or enter a valid output model"); continue;}

                if(rc4 == FALSE){Set_data(cmbMsg,"Enter a valid approach lane width"); continue;}
                if(rc5 == FALSE){Set_data(cmbMsg,"Enter a valid departure lane width"); continue;}
                if(rc6 == FALSE){Set_data(cmbMsg,"Enter a valid tangent offset"); continue;}
                if(rc7 == FALSE){Set_data(cmbMsg,"Enter a valid radius"); continue;}
                if(rc8 == FALSE){Set_data(cmbMsg,"Enter a valid arc length"); continue;}

                if(approach_width <= 0.0){Set_data(cmbMsg,"Approach lane width must be greater than zero"); continue;}
                if(departure_width <= 0.0){Set_data(cmbMsg,"Departure lane width must be greater than zero"); continue;}
                if(tangent_offset <= 0.0){Set_data(cmbMsg,"Tangent offset must be greater than zero"); continue;}
                if(radius <= 0.0){Set_data(cmbMsg,"Radius must be greater than zero"); continue;}
                if(arc_length <= 0.0){Set_data(cmbMsg,"Arc length must be greater than zero"); continue;}

                if(rc_name != 0 || sa_name == "")
                {
                    Set_data(cmbMsg,"String Name cannot be blank");
                    continue;
                }

                Get_name(approach,approach_name);
                Get_name(departure,departure_name);

                Get_model(approach,approach_model);
                Get_model(departure,departure_model);

                Get_name(approach_model,approach_model_name);
                Get_name(departure_model,departure_model_name);
                Get_name(output_model,output_model_name);

                Null(approach_model);
                Null(departure_model);

                if(approach_name == ""){Set_data(cmbMsg,"Approach name is blank"); continue;}
                if(departure_name == ""){Set_data(cmbMsg,"Departure name is blank"); continue;}

                if(approach_name == departure_name && approach_model_name == departure_model_name)
                {
                    Set_data(cmbMsg,"Approach and departure must be different strings");
                    continue;
                }

                sa_reference_text(approach,approach_ref);
                sa_reference_text(departure,departure_ref);

                app_offset_start = approach_width;
                app_offset_end = approach_width;
                app_ext_start = tangent_offset + 1.0;
                app_ext_end = tangent_offset;

                dep_offset_start = departure_width;
                dep_offset_end = departure_width;
                dep_ext_start = tangent_offset;
                dep_ext_end = tangent_offset + 1.0;

                if(apply_approach_line_sign(approach_dir,app_offset_start,app_ext_start) != 0)
                {
                    Set_data(cmbMsg,"Invalid approach direction");
                    continue;
                }

                if(apply_approach_line_sign(approach_dir,app_offset_end,app_ext_end) != 0)
                {
                    Set_data(cmbMsg,"Invalid approach direction");
                    continue;
                }

                if(apply_departure_line_sign(departure_dir,dep_offset_start,dep_ext_start) != 0)
                {
                    Set_data(cmbMsg,"Invalid departure direction");
                    continue;
                }

                if(apply_departure_line_sign(departure_dir,dep_offset_end,dep_ext_end) != 0)
                {
                    Set_data(cmbMsg,"Invalid departure direction");
                    continue;
                }

                sa = Create_super_alignment();

                if(Set_name(sa,sa_name) != 0)
                {
                    Set_data(cmbMsg,"Failed to set super alignment name");
                    continue;
                }

                build_horz_line_2_points_part
                (
                    part_id,
                    "KerbReturnApp",
                    approach_ref,
                    app_offset_start,
                    app_ext_start,
                    departure_ref,
                    0,
                    approach_ref,
                    app_offset_end,
                    app_ext_end,
                    departure_ref,
                    0,
                    part_text
                );

                if(Super_alignment_horz_part_append(sa,part_text) != 0)
                {
                    Set_data(cmbMsg,"Failed to append KerbReturnApp part");
                    continue;
                }

                part_id += 100;

                build_floating_arc_end_radius_length_part
                (
                    part_id,
                    -radius,
                    arc_length,
                    "previous_part",
                    part_text
                );

                if(Super_alignment_horz_part_append(sa,part_text) != 0)
                {
                    Set_data(cmbMsg,"Failed to append first floating arc part");
                    continue;
                }

                part_id += 100;

                build_free_arc_radius_part
                (
                    part_id,
                    radius,
                    part_text
                );

                if(Super_alignment_horz_part_append(sa,part_text) != 0)
                {
                    Set_data(cmbMsg,"Failed to append free arc radius part");
                    continue;
                }

                part_id += 100;

                build_floating_arc_end_radius_length_part
                (
                    part_id,
                    -radius,
                    arc_length,
                    "next_part",
                    part_text
                );

                if(Super_alignment_horz_part_append(sa,part_text) != 0)
                {
                    Set_data(cmbMsg,"Failed to append second floating arc part");
                    continue;
                }

                part_id += 100;

                build_horz_line_2_points_part
                (
                    part_id,
                    "KerbReturnDep",
                    departure_ref,
                    dep_offset_start,
                    dep_ext_start,
                    approach_ref,
                    0,
                    departure_ref,
                    dep_offset_end,
                    dep_ext_end,
                    approach_ref,
                    0,
                    part_text
                );

                if(Super_alignment_horz_part_append(sa,part_text) != 0)
                {
                    Set_data(cmbMsg,"Failed to append KerbReturnDep part");
                    continue;
                }

                if(Calc_super_alignment_horz(sa) != 0)
                {
                    Set_data(cmbMsg,"Failed to calculate horizontal geometry");
                    continue;
                }

                start_ch_text =
                    "computator_start_horz_chainage { "
                    + "valid true "
                    + "start_hg { "
                    + "} "
                    + "}";

                end_ch_text =
                    "computator_named_part_chainage { "
                    + "valid true "
                    + "name { "
                    + "name \"KerbReturnApp.P.S.S\" "
                    + "} "
                    + "}";

                build_computator_vertical_offset_part
                (
                    vert_part_id,
                    "",
                    approach_ref,
                    -0.03,
                    1.0,
                    0,
                    start_ch_text,
                    end_ch_text,
                    vert_part_text
                );

                if(Super_alignment_vert_part_append(sa,vert_part_text) != 0)
                {
                    Set_data(cmbMsg,"Failed to append first vertical part");
                    continue;
                }

                vert_part_id += 100;

                build_free_parabola_compound_part
                (
                    vert_part_id,
                    0.5,
                    0.0,
                    vert_part_text
                );

                if(Super_alignment_vert_part_append(sa,vert_part_text) != 0)
                {
                    Set_data(cmbMsg,"Failed to append free parabola compound part");
                    continue;
                }

                vert_part_id += 100;

                start_ch_text =
                    "computator_named_part_chainage { "
                    + "valid true "
                    + "name { "
                    + "name \"KerbReturnDep.P.E.E\" "
                    + "} "
                    + "}";

                end_ch_text =
                    "computator_end_horz_chainage { "
                    + "valid true "
                    + "end_hg { "
                    + "} "
                    + "}";

                build_computator_vertical_offset_part
                (
                    vert_part_id,
                    "",
                    departure_ref,
                    -0.03,
                    1.0,
                    -1,
                    start_ch_text,
                    end_ch_text,
                    vert_part_text
                );

                if(Super_alignment_vert_part_append(sa,vert_part_text) != 0)
                {
                    Set_data(cmbMsg,"Failed to append second vertical part");
                    continue;
                }

                if(Calc_super_alignment_vert(sa) != 0)
                {
                    Set_data(cmbMsg,"Failed to calculate vertical geometry");
                    continue;
                }

                Calc_extent(sa);

                if(Set_model(sa,output_model) != 0)
                {
                    Set_data(cmbMsg,"Failed to finalise super alignment in output model");
                    continue;
                }

                undo_name = "Undo Create Mini Roundabout SA " + sa_name;
                add_created_sa_undo(undo_name,sa);

                if(get_trailing_counter(sa_name,counter) == 0)
                {
                    sa_name_counter = counter + 1;
                }
                else
                {
                    sa_name_counter = 1;
                }

                Set_data
                (
                    cmbMsg,
                    "Created mini roundabout SA: " + output_model_name + " -> " + sa_name
                );
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

    mainPanel();
}