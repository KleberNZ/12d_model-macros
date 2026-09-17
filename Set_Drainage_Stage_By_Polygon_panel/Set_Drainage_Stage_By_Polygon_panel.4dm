/*---------------------------------------------------------------------
**   Programmer:           KLP
**   Date:                 2026-09-17
**   12D Model:            V15
**   Version:              001
**   Macro Name:           Set_Drainage_Stage_By_Polygon_panel.4dm
**   Type:                 SOURCE
**
**   Brief description: BriefDescription
**   Assigns construction stage attributes to drainage pits and pipes
**   based on their spatial relationship to named stage boundary
**   polygons.
**---------------------------------------------------------------------
**   Description: Description
**
**   This macro updates drainage network attributes using the names
**   of selected stage boundary polygons.
**
**   For drainage pits:
**       - The pit XY coordinate is tested against the selected
**         stage polygons.
**       - If the pit lies inside a polygon, the attribute
**         "pit stage" is set to the polygon name.
**
**   For drainage pipes:
**       - The midpoint of each drainage segment is tested against
**         the selected stage polygons.
**       - If the midpoint lies inside a polygon, the attribute
**         "pipe stage" is set to the polygon name.
**
**   Polygon names become the stage values stored on the drainage
**   network, allowing reports, schedules, and construction staging
**   information to be generated directly from the model.
**
**   Existing attribute values are updated when a match is found.
**   Items outside all selected polygons are left unchanged.
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
#include "size_of.H"
#include "set_ups.H"

/*global variables*/
{
    Text PIT_STAGE_ATTRIBUTE  = "pit stage";
    Text PIPE_STAGE_ATTRIBUTE = "pipe stage";
}
/*---------------------------------------------------------------------
    Validate and pre-filter the selected stage polygons.

    Only valid polygons with non-blank names are appended to valid_polys.
---------------------------------------------------------------------*/
Integer Build_valid_polygon_list(
    Dynamic_Element selected_polys,
    Dynamic_Element &valid_polys,
    Integer &invalid_count,
    Integer &blank_name_count
)
{
    Integer n_polys = 0;
    Integer i;

    Null(valid_polys);
    invalid_count = 0;
    blank_name_count = 0;

    Get_number_of_items(selected_polys,n_polys);

    for(i = 1; i <= n_polys; i = i + 1)
    {
        Element polygon;
        Element checked_polygon;
        Integer good_polygon = 0;
        Text polygon_name = "";

        if(Get_item(selected_polys,i,polygon) != 0)
        {
            invalid_count = invalid_count + 1;
            continue;
        }

        if(Check_polygon(polygon,good_polygon,checked_polygon) != 0 ||
           good_polygon != 1)
        {
            invalid_count = invalid_count + 1;
            continue;
        }

        if(Get_name(polygon,polygon_name) != 0 || polygon_name == "")
        {
            blank_name_count = blank_name_count + 1;
            continue;
        }

        /*
           Use the selected polygon itself. Check_polygon is used here as
           validation, matching the established macro pattern.
        */
        Append(polygon,valid_polys);
    }

    Integer n_valid = 0;
    Get_number_of_items(valid_polys,n_valid);

    if(n_valid <= 0)
        return(FALSE);

    return(TRUE);
}


/*---------------------------------------------------------------------
    Find the first stage polygon containing x,y.

    Returns TRUE when a match is found and writes its polygon name to
    stage_name. Source Box order defines priority where polygons overlap.
---------------------------------------------------------------------*/
Integer Find_stage_at_xy
(
    Dynamic_Element valid_polys,
    Real x,
    Real y,
    Text &stage_name
)
{
    Integer n_polys = 0;
    Integer i;

    stage_name = "";
    Get_number_of_items(valid_polys,n_polys);

    for(i = 1; i <= n_polys; i = i + 1)
    {
        Element polygon;
        Text polygon_name = "";
        Integer inside_status = 0;

        if(Get_item(valid_polys,i,polygon) != 0)
            continue;

        if(Get_name(polygon,polygon_name) != 0 || polygon_name == "")
            continue;

        if(XY_inside_polygon(polygon,x,y,inside_status) != 0)
            continue;

        if(inside_status == 1)
        {
            stage_name = polygon_name;
            return(TRUE);
        }
    }

    return(FALSE);
}


/*---------------------------------------------------------------------
    Set pit Stage attributes using drainage pit XY coordinates.
---------------------------------------------------------------------*/
void Assign_pit_stages (
    Element drain,
    Dynamic_Element valid_polys,
    Integer &pit_updates,
    Integer &pit_unmatched,
    Integer &errors,
    Integer &element_changed
)
{
    Integer n_pits = 0;
    Integer pit;

    if(Get_drainage_pits(drain,n_pits) != 0)
    {
        errors = errors + 1;
        return;
    }

    for(pit = 1; pit <= n_pits; pit = pit + 1)
    {
        Real x = 0.0;
        Real y = 0.0;
        Real z = 0.0;
        Text stage_name = "";

        if(Get_drainage_pit(drain,pit,x,y,z) != 0)
        {
            errors = errors + 1;
            continue;
        }

        if(Find_stage_at_xy(valid_polys,x,y,stage_name) == TRUE)
        {
            if(Set_drainage_pit_attribute
               (
                   drain,
                   pit,
                   PIT_STAGE_ATTRIBUTE,
                   stage_name
               ) == 0)
            {
                pit_updates = pit_updates + 1;
                element_changed = 1;
            }
            else
            {
                errors = errors + 1;
            }
        }
        else
        {
            pit_unmatched = pit_unmatched + 1;
        }
    }
}


/*---------------------------------------------------------------------
    Set pipe Stage attributes using the actual drainage segment midpoint.
---------------------------------------------------------------------*/
void Assign_pipe_stages(
    Element drain,
    Dynamic_Element valid_polys,
    Integer &pipe_updates,
    Integer &pipe_unmatched,
    Integer &errors,
    Integer &element_changed
)
{
    Integer n_segments = 0;
    Integer pipe;

    if(Get_segments(drain,n_segments) != 0 || n_segments <= 0)
    {
        errors = errors + 1;
        return;
    }

    for(pipe = 1; pipe <= n_segments; pipe = pipe + 1)
    {
        Segment dseg;
        Point p1;
        Point p2;
        Real midpoint_x = 0.0;
        Real midpoint_y = 0.0;
        Text stage_name = "";

        if(Get_segment(drain,pipe,dseg) != 0)
        {
            errors = errors + 1;
            continue;
        }

        if(Get_start(dseg,p1) != 0 || Get_end(dseg,p2) != 0)
        {
            errors = errors + 1;
            continue;
        }

        midpoint_x = 0.5 * (Get_x(p1) + Get_x(p2));
        midpoint_y = 0.5 * (Get_y(p1) + Get_y(p2));

        if(Find_stage_at_xy
           (
               valid_polys,
               midpoint_x,
               midpoint_y,
               stage_name
           ) == TRUE)
        {
            if(Set_drainage_pipe_attribute
               (
                   drain,
                   pipe,
                   PIPE_STAGE_ATTRIBUTE,
                   stage_name
               ) == 0)
            {
                pipe_updates = pipe_updates + 1;
                element_changed = 1;
            }
            else
            {
                errors = errors + 1;
            }
        }
        else
        {
            pipe_unmatched = pipe_unmatched + 1;
        }
    }
}


/*---------------------------------------------------------------------
    Process all selected drainage strings and create one combined undo.
---------------------------------------------------------------------*/
Integer Process_stage_assignment(
    Dynamic_Element drains,
    Dynamic_Element valid_polys,
    Integer &strings_processed,
    Integer &strings_skipped,
    Integer &pit_updates,
    Integer &pipe_updates,
    Integer &pit_unmatched,
    Integer &pipe_unmatched,
    Integer &errors
)
{
    Integer n_drains = 0;
    Integer di;
    Undo_List undo_list;

    strings_processed = 0;
    strings_skipped = 0;
    pit_updates = 0;
    pipe_updates = 0;
    pit_unmatched = 0;
    pipe_unmatched = 0;
    errors = 0;

    Get_number_of_items(drains,n_drains);

    for(di = 1; di <= n_drains; di = di + 1)
    {
        Element drain;
        Element original;
        Text element_type = "";
        Text drain_name = "unnamed drainage";
        Integer element_changed = 0;

        if(Get_item(drains,di,drain) != 0)
        {
            errors = errors + 1;
            strings_skipped = strings_skipped + 1;
            continue;
        }

        if(Get_type(drain,element_type) != 0 || element_type != "Drainage")
        {
            Print("Skipped non-drainage element.\n");
            strings_skipped = strings_skipped + 1;
            continue;
        }

        if(Get_name(drain,drain_name) != 0)
            drain_name = "unnamed drainage";

        /* Keep an unmodified duplicate for Add_undo_change. */
        if(Element_duplicate(drain,original) != 0)
        {
            Print("Could not duplicate drainage element: " + drain_name + "\n");
            errors = errors + 1;
            strings_skipped = strings_skipped + 1;
            continue;
        }

        Assign_pit_stages
        (
            drain,
            valid_polys,
            pit_updates,
            pit_unmatched,
            errors,
            element_changed
        );

        Assign_pipe_stages
        (
            drain,
            valid_polys,
            pipe_updates,
            pipe_unmatched,
            errors,
            element_changed
        );

        if(element_changed == 1)
        {
            Undo u_change = Add_undo_change
            (
                "Set Stage - " + drain_name,
                original,
                drain
            );

            Append(u_change,undo_list);
        }

        strings_processed = strings_processed + 1;
    }

    Integer undo_count = 0;
    Get_number_of_items(undo_list,undo_count);

    if(undo_count > 0)
    {
        Add_undo_list("Set Drainage Stage Attributes",undo_list);
        Null(undo_list);
    }

    return(TRUE);
}

// ----------------------------- PANEL -----------------------------
void mainPanel(){

    Text panelName="Set Drainage Stage by Polygon";
    Panel              panel  = Create_panel              (panelName,TRUE);
    Vertical_Group     vgroup = Create_vertical_group     (-1         );
    Colour_Message_Box cmbMsg = Create_colour_message_box (""         );

    ///////////////////CREATE INPUT WIDGETS////////////////
    Source_Box sb_drainage = Create_source_box
    (
        "Drainage strings",
        cmbMsg,
        0
    );

    Source_Box sb_stage_polygons = Create_source_box
    (
        "Named stage boundary polygons",
        cmbMsg,
        0
    );

    ///////////////ADDING BUTTONS ALONG THE BOTTOM///////////////////////////
    Horizontal_Group bgroup = Create_button_group();
    Button process     = Create_button       ("&Process" ,"process");
    Button finish      = Create_finish_button("Finish"   ,"Finish" );
    Button help_button = Create_help_button  (panel      ,"Help"   );

    Append(process     ,bgroup);
    Append(finish      ,bgroup);
    Append(help_button ,bgroup);

    /////////////////////// PANEL LAYOUT ///////////////////////////////

    Append(sb_drainage,panel);
    Append(sb_stage_polygons,panel);
    Append(cmbMsg,vgroup);
    Append(bgroup,vgroup);
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
                    Print("=== Set Drainage Stage by Polygon ===\n");

                    Dynamic_Element drains;
                    Dynamic_Element selected_polys;
                    Dynamic_Element valid_polys;

                    Integer rc_drain = Validate(sb_drainage,drains);

                    if(rc_drain == 0)
                    {
                        Set_data(cmbMsg,"Drainage source validation failed.");
                        Print("Drainage source: drastic validation error.\n");
                        break;
                    }

                    if(rc_drain == -2)
                    {
                        Set_data(cmbMsg,"At least one drainage string is required.");
                        Print("At least one drainage string is required.\n");
                        break;
                    }

                    Integer n_drains = 0;
                    Get_number_of_items(drains,n_drains);

                    if(n_drains <= 0)
                    {
                        Set_data(cmbMsg,"No drainage strings selected.");
                        Print("No drainage strings selected.\n");
                        break;
                    }

                    Integer rc_poly = Validate
                    (
                        sb_stage_polygons,
                        selected_polys
                    );

                    if(rc_poly == 0)
                    {
                        Set_data(cmbMsg,"Stage polygon source validation failed.");
                        Print("Stage polygon source: drastic validation error.\n");
                        break;
                    }

                    if(rc_poly == -2)
                    {
                        Set_data(cmbMsg,"At least one named stage polygon is required.");
                        Print("At least one named stage polygon is required.\n");
                        break;
                    }

                    Integer n_selected_polys = 0;
                    Get_number_of_items(selected_polys,n_selected_polys);

                    if(n_selected_polys <= 0)
                    {
                        Set_data(cmbMsg,"No stage polygons selected.");
                        Print("No stage polygons selected.\n");
                        break;
                    }

                    Integer invalid_polys = 0;
                    Integer blank_polygon_names = 0;

                    if(Build_valid_polygon_list
                       (
                           selected_polys,
                           valid_polys,
                           invalid_polys,
                           blank_polygon_names
                       ) == FALSE)
                    {
                        Set_data
                        (
                            cmbMsg,
                            "No valid named stage polygons were found."
                        );
                        Print("No valid named stage polygons were found.\n");
                        break;
                    }

                    Integer strings_processed = 0;
                    Integer strings_skipped = 0;
                    Integer pit_updates = 0;
                    Integer pipe_updates = 0;
                    Integer pit_unmatched = 0;
                    Integer pipe_unmatched = 0;
                    Integer errors = 0;

                    Set_data(cmbMsg,"Assigning Stage attributes...");

                    Process_stage_assignment
                    (
                        drains,
                        valid_polys,
                        strings_processed,
                        strings_skipped,
                        pit_updates,
                        pipe_updates,
                        pit_unmatched,
                        pipe_unmatched,
                        errors
                    );

                    Text status =
                          "Finished. Strings processed: "
                        + To_text(strings_processed)
                        + ", skipped: "
                        + To_text(strings_skipped)
                        + ", pits updated: "
                        + To_text(pit_updates)
                        + ", pipes updated: "
                        + To_text(pipe_updates)
                        + ", pits outside: "
                        + To_text(pit_unmatched)
                        + ", pipes outside: "
                        + To_text(pipe_unmatched)
                        + ", invalid polygons: "
                        + To_text(invalid_polys)
                        + ", blank polygon names: "
                        + To_text(blank_polygon_names)
                        + ", errors: "
                        + To_text(errors);

                    Set_data(cmbMsg,status);
                    Print(status + "\n");
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