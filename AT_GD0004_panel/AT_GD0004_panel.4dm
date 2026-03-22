/*---------------------------------------------------------------------
**   Programmer:KLP
**   Date:10/03/26             
**   12D Model:            V15
**   Version:              001
**   Macro Name:           AT_GD0004_panel.4dm
**   Type:                 SOURCE
**
**   Brief description: Creates a SA kerb return using computators (parts). Based on AT TDM GD0004 standard drawing
**
**---------------------------------------------------------------------
**   Description:
**  Creates a Super Alignment kerb return between two selected centreline strings using GD0004 compound curve geometry.
**  The user selects the approach and departure strings with direction, specifies carriageway widths and curve type,
**  and the macro generates the full horizontal and vertical SA geometry.
**  Use offset 6.4 for residential type and 13.5 for commercial type, as per GD0004.
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
/*global variables*/{


}
//============================HELPER FUNCTIONS==========================`
// helper: validate selected string and return its name
Integer get_selected_string_name
(
    New_Select_Box nsb,
    Text &string_name
)
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
    Uid element_uid, model_uid;
    Text element_name = "";
    Text model_name = "";
    Text element_id = "";
    Text model_id = "";

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
Integer build_horz_line_2_points_part
(
    Integer part_id,
    Text part_name,
    Text start_ref,
    Real start_offset,
    Real start_ext,
    Text start_cut_ref,
    Integer start_cut_index,
    Text end_ref,
    Real end_offset,
    Real end_ext,
    Text end_cut_ref,
    Integer end_cut_index,
    Text &part_text
)
{
    Text name_block = "";

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

// helper: build free_arc_length part text
Integer build_free_arc_length_part
(
    Integer part_id,
    Real length,
    Text &part_text
)
{
    part_text =
        "free_arc_length { "
        + "id " + To_text(part_id) + " "
        + "l " + To_text(length,3) + " "
        + "}";

    return 0;
}

// helper: build two_centred_curve part text
Integer build_two_centred_curve_part
(
    Integer part_id,
    Real approaching_radius,
    Real departing_radius,
    Real ratio,
    Real curve_offset,
    Text &part_text
)
{
    part_text =
        "two_centred_curve { "
        + "id " + To_text(part_id) + " "
        + "approaching_radius " + To_text(approaching_radius,3) + " "
        + "departing_radius " + To_text(departing_radius,3) + " "
        + "ratio " + To_text(ratio,3) + " "
        + "curve_offset " + To_text(curve_offset,3) + " "
        + "}";

    return 0;
}

// helper: build computator_vertical_offset part text
Integer build_computator_vertical_offset_part
(
    Integer part_id,
    Text part_name,
    Text reference_text,
    Real slope,
    Real interval,
    Integer chainage_direction,
    Text start_ch_text,
    Text end_ch_text,
    Text &part_text
)
{
    Text name_block = "";
    Text direction_block = "";

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
Integer build_free_parabola_compound_part
(
    Integer part_id,
    Real ratio,
    Real length,
    Text &part_text
)
{
    part_text =
        "free_parabola_compound { "
        + "id " + To_text(part_id) + " "
        + "ratio " + To_text(ratio,3) + " "
        + "length " + To_text(length,3) + " "
        + "}";

    return 0;
}

// helper: build SA name from approach and departure strings and counter
Integer build_sa_name
(
    Element approach,
    Element departure,
    Integer counter,
    Text &sa_name
)
{
    Text approach_name  = "";
    Text departure_name = "";

    Get_name(approach ,approach_name);
    Get_name(departure,departure_name);

    if(approach_name == "" || departure_name == "")
    {
        sa_name = "";
        return 1;
    }


    return 0;
}

// helper: get trailing integer from name text, if present
Integer get_trailing_counter
(
    Text name_text,
    Integer &counter
)
{
    Integer len = Text_length(name_text);
    Integer i = 0;
    Integer ch = 0;
    Integer last_space = 0;
    Text tail = "";

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
Integer update_sa_name_suggestion
(
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

// helper: apply approach line sign
Integer apply_approach_line_sign
(
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
Integer apply_departure_line_sign
(
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

// helper: add created SA to undo list
Integer add_created_sa_undo(Text undo_name, Element &sa)
{
    Add_undo_add(undo_name,sa);
    return 0;
}

void mainPanel(){
 
    Text panelName="Create SA kerb return as per AT TDM GD0004";
    Panel              panel  = Create_panel              (panelName,TRUE);
    Vertical_Group     vgroup = Create_vertical_group     (-1         );
    Colour_Message_Box cmbMsg = Create_colour_message_box (""         );
    Integer sa_name_counter = 1;

    ///////////////////CREATE INPUT WIDGETS////////////////
    New_Select_Box nsb_approach  = Create_new_select_box("Pick CL   " ,"Select approach string (pick with direction)" ,SELECT_STRING,cmbMsg);
    New_Select_Box nsb_departure = Create_new_select_box("Pick CL   " ,"Select departure string (pick with direction)",SELECT_STRING,cmbMsg);

    Model_Box   mb_output                   = Create_model_box("Model Name",cmbMsg,CHECK_MODEL_CREATE);
    Input_Box ib_sa_name                    = Create_input_box("String Name",cmbMsg);
    Named_Tick_Box ntb_include_end_parts    = Create_named_tick_box("Include 1m transition end parts",1,"");
    Set_data(ib_sa_name,"");
    
    Real_Box rb_approach_width      = Create_real_box   ("Lane Width",cmbMsg);
    Real_Box rb_departure_width     = Create_real_box   ("Lane Width",cmbMsg);
    Real_Box rb_curve_offset        = Create_real_box   ("Curve Offset",cmbMsg);

    Integer no_choices = 2;
    Text choices[2];

    choices[1] = "RESIDENTIAL COMPOUND CURVE";
    choices[2] = "COMMERCIAL COMPOUND CURVE";

    Choice_Box cb_curve_type = Create_choice_box("Curve Type",cmbMsg);
    Set_data(cb_curve_type,no_choices,choices);
    Set_data(cb_curve_type,choices[1]);
    Set_data(rb_curve_offset,6.4);

    Set_data(rb_approach_width ,3.6);
    Set_data(rb_departure_width,3.6);
    
    ///////////////ADDING BUTTONS ALONG THE BOTTOM///////////////////////////
    Horizontal_Group bgroup = Create_button_group();
    Button process     = Create_button       ("&Process" ,"process");
    Button finish      = Create_finish_button("Finish"   ,"Finish" );
    Button help_button = Create_help_button  (panel      ,"Help"   );
    Append(process      ,bgroup);
    Append(finish       ,bgroup);
    Append(help_button  ,bgroup);
    ///////////////ADDING WIDGETS TO PANEL///////////////////////////
    Vertical_Group curve_group = Create_vertical_group(-1);
    Horizontal_Group curve_row = Create_horizontal_group(1);

    Vertical_Group approach_group = Create_vertical_group(-1);
    Horizontal_Group approach_row = Create_horizontal_group(2);

    Vertical_Group departure_group = Create_vertical_group(-1);
    Horizontal_Group departure_row = Create_horizontal_group(2);

    Vertical_Group output_group = Create_vertical_group(-1);

    // Curve parameters
    Append(rb_curve_offset,curve_row);
    Append(cb_curve_type  ,curve_row);
    Append(curve_row      ,curve_group);
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
    Append(ntb_include_end_parts ,output_group);
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
            if(cmd == "Panel Quit") doit = 0;
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
        
        case Get_id(cb_curve_type) :
        {
            Text curve_type = "";

            if(Get_data(cb_curve_type,curve_type) == 0)
            {
                if(curve_type == choices[1])
                {
                    Set_data(rb_curve_offset,6.4);
                }
                else if(curve_type == choices[2])
                {
                    Set_data(rb_curve_offset,13.5);
                }
            }
        }
        break; 

        case Get_id(process) :
        {
            if(cmd == "process")
            {
                // declare your widget variables
                // Selection widgets
                Element approach;
                Element departure;
                Integer approach_dir = 1;
                Integer departure_dir = 1;

                // Selection metadata
                Model   approach_model;
                Model   departure_model;
                Text    approach_name = "";
                Text    departure_name = "";
                Text    approach_type = "";
                Text    departure_type = "";
                Text    approach_model_name = "";
                Text    departure_model_name = "";

                // Output / created SA
                Element sa;
                Model   output_model;
                Text    output_model_text = "";
                Text    output_model_name = "";
                Text    sa_name = "";
                Integer include_end_parts = 1;

                // User inputs
                Integer counter = sa_name_counter;
                Real    approach_width = 0.0;
                Real    departure_width = 0.0;
                Real    curve_offset = 0.0;
                Text    curve_type = "";

                // Part / vertical data
                Integer part_id = 100;
                Integer vert_part_id = 800;
                Text    part_text = "";
                Text    vert_part_text = "";
                Text    start_ch_text = "";
                Text    end_ch_text = "";

                // Derived references
                Text    approach_ref = "";
                Text    departure_ref = "";

                // Geometric controls
                Real    ratio = 0.5;
                Real    approaching_radius = 0.0;
                Real    departing_radius = 0.0;

                // Offset distances
                Real    approach_offset_start = 0.0;
                Real    approach_offset_end   = 0.0;
                Real    app2_offset_start     = 0.0;
                Real    app2_offset_end       = 0.0;
                Real    dep_offset_start      = 0.0;
                Real    dep_offset_end        = 0.0;
                Real    dep2_offset_start     = 0.0;
                Real    dep2_offset_end       = 0.0;

                // Extension distances
                Real    approach_ext_start = 0.0;
                Real    approach_ext_end   = 0.0;
                Real    app2_ext_start     = 0.0;
                Real    app2_ext_end       = 0.0;
                Real    dep_ext_start      = 0.0;
                Real    dep_ext_end        = 0.0;
                Real    dep2_ext_start     = 0.0;
                Real    dep2_ext_end       = 0.0;

                // Widget validation / reads
                Integer rc1 = Validate(nsb_approach, approach);
                Integer rc2 = Validate(nsb_departure, departure);
                Integer rc_dir1 = Get_select_direction(nsb_approach, approach_dir);
                Integer rc_dir2 = Get_select_direction(nsb_departure, departure_dir);

                Integer rc3 = Validate(mb_output, CHECK_MODEL_CREATE, output_model);
                Integer rc5 = Validate(rb_approach_width, approach_width);
                Integer rc6 = Validate(rb_departure_width, departure_width);
                Integer rc7 = Get_data(cb_curve_type, curve_type);
                Integer rc8 = Validate(rb_curve_offset, curve_offset);

                // validate widgets
                if(rc_dir1 != 0){Set_data(cmbMsg,"Failed to get approach direction"); continue;}

                if(rc_dir2 != 0){Set_data(cmbMsg,"Failed to get departure direction"); continue;}

                if(rc1 == 0){Set_data(cmbMsg,"Select a valid approach centreline string"); continue;}

                if(rc2 == 0){Set_data(cmbMsg,"Select a valid departure centreline string"); continue;}

                Get_name(approach,approach_name);
                Get_name(departure,departure_name);
                Get_type(approach,approach_type);
                Get_type(departure,departure_type);

                Get_model(approach,approach_model);
                Get_model(departure,departure_model);
                Get_name(approach_model,approach_model_name);
                Get_name(departure_model,departure_model_name);
                Null(approach_model);
                Null(departure_model);

                if(approach_name == ""){Set_data(cmbMsg,"Approach name is blank");continue;}

                if(departure_name == ""){Set_data(cmbMsg,"Departure name is blank");continue;}

                if(approach_name == departure_name && approach_model_name == departure_model_name){Set_data(cmbMsg,"Approach and departure must be different strings");continue;}

                if(rc3 == NO_NAME){Set_data(cmbMsg,"No model specified"); continue;}

                if(rc3 == 0){ Set_data(cmbMsg,"Model validation error");continue;}

                if(rc3 == NO_MODEL)
                {
                    if(Get_data(mb_output,output_model_text) != 0 || output_model_text == "")
                    {
                        Set_data(cmbMsg,"No model specified");
                        continue;
                    }
                    output_model = Get_model_create(output_model_text);
                }

                Get_name(output_model,output_model_name);

                if(rc5 == 0){Set_data(cmbMsg,"Enter a valid approach carriageway width");continue;}

                if(rc6 == 0) {Set_data(cmbMsg,"Enter a valid departure carriageway width"); continue;}

                if(approach_width <= 0.0)
                {
                    Set_data(cmbMsg,"Approach carriageway width must be greater than zero");
                    continue;
                }

                if(departure_width <= 0.0)
                {
                    Set_data(cmbMsg,"Departure carriageway width must be greater than zero");
                    continue;
                }

                if(rc7 == -1 || curve_type == ""){Set_data(cmbMsg,"Select a valid curve type");continue;}

                if(rc8 == 0)
                {
                    Set_data(cmbMsg,"Enter a valid curve offset");
                    continue;
                }

                if(curve_offset <= 0.0)
                {
                    Set_data(cmbMsg,"Curve offset must be greater than zero");
                    continue;
                }

                approach_offset_start = approach_width;
                approach_offset_end   = approach_width;

                app2_offset_start     = approach_width;
                app2_offset_end       = approach_width + 0.5;

                dep_offset_start      = departure_width + 0.5;
                dep_offset_end        = departure_width;

                dep2_offset_start     = departure_width;
                dep2_offset_end       = departure_width;

                if(curve_type == "RESIDENTIAL COMPOUND CURVE")
                {
                    approach_ext_start = approach_width + 5.1 + 10.0 + 2.0;
                    approach_ext_end   = approach_width + 5.1 + 10.0 + 1.0;

                    app2_ext_start     = approach_width + 5.1 + 10.0;
                    app2_ext_end       = approach_width + 5.1;

                    dep_ext_start      = departure_width + 7.9;
                    dep_ext_end        = departure_width + 7.9 + 10.0;

                    dep2_ext_start     = departure_width + 7.9 + 10.0 + 1.0;
                    dep2_ext_end       = departure_width + 7.9 + 10.0 + 2.0;

                    approaching_radius = -4.0;
                    departing_radius   = -15.0;
                }
                else if(curve_type == "COMMERCIAL COMPOUND CURVE")
                {
                    approach_ext_start = approach_width + 8.5 + 10.0 + 2.0;
                    approach_ext_end   = approach_width + 8.5 + 10.0 + 1.0;

                    app2_ext_start     = approach_width + 8.5 + 10.0;
                    app2_ext_end       = approach_width + 8.5;

                    dep_ext_start      = departure_width + 14.9;
                    dep_ext_end        = departure_width + 14.9 + 10.0;

                    dep2_ext_start     = departure_width + 14.9 + 10.0 + 1.0;
                    dep2_ext_end       = departure_width + 14.9 + 10.0 + 2.0;

                    approaching_radius = -7.0;
                    departing_radius   = -30.0;
                }
                else
                {
                    Set_data(cmbMsg,"Unsupported curve type");
                    continue;
                }

                if(apply_approach_line_sign(approach_dir,approach_offset_start,approach_ext_start) != 0)
                {
                    Set_data(cmbMsg,"Invalid approach direction");
                    continue;
                }

                if(apply_approach_line_sign(approach_dir,approach_offset_end,approach_ext_end) != 0)
                {
                    Set_data(cmbMsg,"Invalid approach direction");
                    continue;
                }

                if(apply_approach_line_sign(approach_dir,app2_offset_start,app2_ext_start) != 0)
                {
                    Set_data(cmbMsg,"Invalid approach direction");
                    continue;
                }

                if(apply_approach_line_sign(approach_dir,app2_offset_end,app2_ext_end) != 0)
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

                if(apply_departure_line_sign(departure_dir,dep2_offset_start,dep2_ext_start) != 0)
                {
                    Set_data(cmbMsg,"Invalid departure direction");
                    continue;
                }

                if(apply_departure_line_sign(departure_dir,dep2_offset_end,dep2_ext_end) != 0)
                {
                    Set_data(cmbMsg,"Invalid departure direction");
                    continue;
                }

                Integer rc_name = Get_data(ib_sa_name, sa_name);

                if(rc_name != 0 || sa_name == "")
                {
                    Set_data(cmbMsg,"Kerb Return Name cannot be blank");
                    continue;
                }

                sa = Create_super_alignment();

                if(Set_name(sa,sa_name) != 0)
                {
                    Set_data(cmbMsg,"Failed to set super alignment name");
                    continue;
                }

                if(Validate(ntb_include_end_parts,include_end_parts) == 0)
                {
                    Set_data(cmbMsg,"Invalid end parts option");
                    continue;
                }

                //Processing

                sa_reference_text(approach,approach_ref);
                sa_reference_text(departure,departure_ref);
                
                // Optional start parts to give better transition
                if(include_end_parts == 1)
                {
                    build_horz_line_2_points_part
                    (
                        part_id,
                        "",
                        approach_ref,
                        approach_offset_start,
                        approach_ext_start,
                        departure_ref,
                        0,
                        approach_ref,
                        approach_offset_end,
                        approach_ext_end,
                        departure_ref,
                        0,
                        part_text
                    );
                    // Append first fixed horizontal part (kerb return start)
                    if(Super_alignment_horz_part_append(sa,part_text) != 0)
                    {
                        Set_data(cmbMsg,"Failed to append first fixed horizontal part");
                        continue;
                    }

                    part_id += 100;

                    build_free_arc_length_part
                    (
                        part_id,
                        1.0,
                        part_text
                    );

                    if(Super_alignment_horz_part_append(sa,part_text) != 0)
                    {
                        Set_data(cmbMsg,"Failed to append first free arc length part");
                        continue;
                    }

                    part_id += 100;
                }

                // GD0004 10m long taper (1 in 20 offset change) approach side, with departure string as reference to control transition from curve back to straight
                build_horz_line_2_points_part
                (
                    part_id,
                    "KerbReturnApp",
                    approach_ref,
                    app2_offset_start,
                    app2_ext_start,
                    departure_ref,
                    0,
                    approach_ref,
                    app2_offset_end,
                    app2_ext_end,
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

                // GD0004 compound curve part (2 centered curve with ratio to control transition)
                build_two_centred_curve_part
                (
                    part_id,
                    approaching_radius,
                    departing_radius,
                    ratio,
                    curve_offset,
                    part_text
                );

                if(Super_alignment_horz_part_append(sa,part_text) != 0)
                {
                    Set_data(cmbMsg,"Failed to append two centred curve part");
                    continue;
                }

                part_id += 100;

                // GD0004 10m long taper (1 in 20 offset change) for departure side, with approach string as reference to control transition from curve back to straight
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

                part_id += 100;

                // Optional end parts to give better transition
                if(include_end_parts == 1)
                {
                    build_free_arc_length_part
                    (
                        part_id,
                        1.0,
                        part_text
                    );

                    if(Super_alignment_horz_part_append(sa,part_text) != 0)
                    {
                        Set_data(cmbMsg,"Failed to append second free arc length part");
                        continue;
                    }

                    part_id += 100;

                    build_horz_line_2_points_part
                    (
                        part_id,
                        "",
                        departure_ref,
                        dep2_offset_start,
                        dep2_ext_start,
                        approach_ref,
                        0,
                        departure_ref,
                        dep2_offset_end,
                        dep2_ext_end,
                        approach_ref,
                        0,
                        part_text
                    );

                    if(Super_alignment_horz_part_append(sa,part_text) != 0)
                    {
                        Set_data(cmbMsg,"Failed to append final fixed horizontal part");
                        continue;
                    }
                }
                // Calculate horizontal geometry
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

                // First vertical part - 3% slope from approach string, starting at kerb return start and finishing at start of curve (using approach string as reference for both start and end chainage to control transition)
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

                // Free parabola compound part to give a smooth vertical curve through the kerb return, using default of length of leading curve of 50%.
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
                // Second vertical part - 3% slope to departure string, starting at end of curve and finishing at kerb return end (using departure string as reference for both start and end chainage to control transition)
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
                // Calculate vertical geometry
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
                
                Text undo_name;
                undo_name = "Undo Create Kerb Return SA " + sa_name;
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
                    "Created kerb return SA (" + curve_type + "): "
                    + output_model_name + " -> " + sa_name
                );
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