/*---------------------------------------------------------------------
**   Programmer: Kleber Lessa do Prado
**   Date:       07/10/2026
**   12D Model:  V15
**   Version:    001
**   Macro Name: Reorder_start_vertex_closed_ss_panel.4dm
**   Type:       SOURCE
**
**   Brief description:
**   Reorder the start vertex of a closed Super String and make the
**   vertex nearest the selection point vertex 1 without reversing the
**   polygon direction.
**
**---------------------------------------------------------------------
**   Description:
**   1. The user selects a closed Super String near the desired start.
**   2. The closest stored vertex is found in XY.
**   3. The source element is duplicated and reordered.
**   4. Core Super vertex records (X,Y,Z,radius,flag) are cyclically
**      reordered using dynamic arrays.
**   5. Target_Box mode resolves original/one/prefixed model output.
**   6. Move modes remove the source only after successful output creation.
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
**---------------------------------------------------------------------*/

#define DEBUG_FILE      0
#define ECHO_DEBUG_FILE 0
#define ECHO_LINE_NO    0
#define BUILD "0.001"

// ----------------------------- INCLUDES -----------------------------
#include "standard_library.h"
#include "size_of.h"
#include "set_ups.h"

/*global variables*/
{

}

Integer nearest_super_vertex_xy(
    Element super,
    Integer number_of_vertices,
    Real pick_x,
    Real pick_y,
    Integer &nearest_vertex
)
{
    nearest_vertex = -1;
    Real minimum_distance_squared = 0.0;

    Integer i;
    for(i = 1; i <= number_of_vertices; i++)
    {
        Real x = 0.0;
        Real y = 0.0;
        Real z = 0.0;
        Real radius = 0.0;
        Integer flag = 0;

        Integer result = Get_super_data(super,i,x,y,z,radius,flag);
        if(result != 0)return result;

        Real dx = x - pick_x;
        Real dy = y - pick_y;
        Real distance_squared = dx*dx + dy*dy;

        if(nearest_vertex < 1 || distance_squared < minimum_distance_squared)
        {
            nearest_vertex = i;
            minimum_distance_squared = distance_squared;
        }
    }

    if(nearest_vertex < 1)return -1;
    return 0;
}

Integer read_super_core_data(
    Element super,
    Integer number_of_vertices,
    Dynamic_Real &xs,
    Dynamic_Real &ys,
    Dynamic_Real &zs,
    Dynamic_Real &radii,
    Dynamic_Integer &flags
)
{
    Null(xs);
    Null(ys);
    Null(zs);
    Null(radii);
    Null(flags);

    Integer i;
    for(i = 1; i <= number_of_vertices; i++)
    {
        Real x = 0.0;
        Real y = 0.0;
        Real z = 0.0;
        Real radius = 0.0;
        Integer flag = 0;

        Integer result = Get_super_data(super,i,x,y,z,radius,flag);
        if(result != 0)return result;

        Append(x,xs);
        Append(y,ys);
        Append(z,zs);
        Append(radius,radii);
        Append(flag,flags);
    }

    return 0;
}

Integer write_rotated_super_core_data(
    Element output_super,
    Integer number_of_vertices,
    Integer start_vertex,
    Dynamic_Real &xs,
    Dynamic_Real &ys,
    Dynamic_Real &zs,
    Dynamic_Real &radii,
    Dynamic_Integer &flags
)
{
    Integer output_vertex;

    for(output_vertex = 1; output_vertex <= number_of_vertices; output_vertex++)
    {
        Integer source_vertex = start_vertex + output_vertex - 1;
        while(source_vertex > number_of_vertices)
        {
            source_vertex = source_vertex - number_of_vertices;
        }

        Real x = 0.0;
        Real y = 0.0;
        Real z = 0.0;
        Real radius = 0.0;
        Integer flag = 0;

        if(Get_item(xs,source_vertex,x) != 0)return -1;
        if(Get_item(ys,source_vertex,y) != 0)return -1;
        if(Get_item(zs,source_vertex,z) != 0)return -1;
        if(Get_item(radii,source_vertex,radius) != 0)return -1;
        if(Get_item(flags,source_vertex,flag) != 0)return -1;

        Integer result = Set_super_data
        (
            output_super,
            output_vertex,
            x,
            y,
            z,
            radius,
            flag
        );

        if(result != 0)return result;
    }

    return 0;
}

Integer create_reordered_copy(
    Element source_polygon,
    Real pick_x,
    Real pick_y,
    Model output_model,
    Element &output_polygon,
    Integer &old_start_vertex
)
{
    Null(output_polygon);
    old_start_vertex = -1;

    Integer closed = 0;
    Integer result = String_closed(source_polygon,closed);
    if(result != 0)return result;
    if(!closed)return -2;

    Integer number_of_vertices = 0;
    result = Get_points(source_polygon,number_of_vertices);
    if(result != 0)return result;
    if(number_of_vertices < 3)return -3;

    result = nearest_super_vertex_xy
    (
        source_polygon,
        number_of_vertices,
        pick_x,
        pick_y,
        old_start_vertex
    );
    if(result != 0)return result;

    Dynamic_Real xs;
    Dynamic_Real ys;
    Dynamic_Real zs;
    Dynamic_Real radii;
    Dynamic_Integer flags;

    result = read_super_core_data
    (
        source_polygon,
        number_of_vertices,
        xs,
        ys,
        zs,
        radii,
        flags
    );
    if(result != 0)return result;

    // Duplicate preserves element-level presentation and source properties.
    result = Element_duplicate(source_polygon,output_polygon);
    if(result != 0)return result;

    result = write_rotated_super_core_data
    (
        output_polygon,
        number_of_vertices,
        old_start_vertex,
        xs,
        ys,
        zs,
        radii,
        flags
    );
    if(result != 0)
    {
        Element_delete(output_polygon);
        Null(output_polygon);
        return result;
    }

    result = Set_model(output_polygon,output_model);
    if(result != 0)
    {
        Element_delete(output_polygon);
        Null(output_polygon);
        return result;
    }

    // Element_duplicate preserves the source closed state. Do not call
    // String_close again because the element is already closed.
    Element_draw(output_polygon);
    Add_undo_add("Reordered closed polygon copy",output_polygon);

    return 0;
}


Integer resolve_target_model(
    Element source_polygon,
    Integer target_mode,
    Text target_data,
    Model &output_model,
    Text &output_model_name,
    Integer &delete_source
)
{
    Null(output_model);
    output_model_name = "";
    delete_source = FALSE;

    Model source_model;
    if(Get_model(source_polygon,source_model) != 0)return -20;
    if(!Model_exists(source_model))return -21;

    Text source_model_name = "";
    if(Get_name(source_model,source_model_name) != 0)return -22;

    switch(target_mode)
    {
        case Target_Box_Move_To_Original_Model:
        {
            output_model = source_model;
            output_model_name = source_model_name;
            delete_source = TRUE;
        }
        break;

        case Target_Box_Move_To_One_Model:
        {
            if(Text_length(target_data) < 1)return -23;

            output_model_name = target_data;
            output_model = Get_model_create(output_model_name);
            if(!Model_exists(output_model))return -24;

            delete_source = TRUE;
        }
        break;

        case Target_Box_Move_To_Many_Models:
        {
            if(Text_length(target_data) < 1)return -25;

            output_model_name = target_data + source_model_name;
            output_model = Get_model_create(output_model_name);
            if(!Model_exists(output_model))return -26;

            delete_source = TRUE;
        }
        break;

        case Target_Box_Copy_To_Original_Model:
        {
            output_model = source_model;
            output_model_name = source_model_name;
            delete_source = FALSE;
        }
        break;

        case Target_Box_Copy_To_One_Model:
        {
            if(Text_length(target_data) < 1)return -27;

            output_model_name = target_data;
            output_model = Get_model_create(output_model_name);
            if(!Model_exists(output_model))return -28;

            delete_source = FALSE;
        }
        break;

        case Target_Box_Copy_To_Many_Models:
        {
            if(Text_length(target_data) < 1)return -29;

            output_model_name = target_data + source_model_name;
            output_model = Get_model_create(output_model_name);
            if(!Model_exists(output_model))return -30;

            delete_source = FALSE;
        }
        break;

        default:
        {
            return -31;
        }
        break;
    }

    return 0;
}

void mainPanel()
{
    Text panelName="Reorder Closed Polygon Start Vertex";

    Panel              panel  = Create_panel(panelName,FALSE);
    Vertical_Group     vgroup = Create_vertical_group(-1);
    Colour_Message_Box cmbMsg = Create_colour_message_box("");

    ////////////////////////////// WIDGETS //////////////////////////////
    // create input widgets here
    New_Select_Box nsb_polygon = Create_new_select_box
    (
        "Source closed polygon",
        "Select the closed polygon near the required vertex 1",
        SELECT_STRING,
        cmbMsg
    );

    Target_Box tb_output = Create_target_box
    (
        "Target",
        cmbMsg,
        Target_Box_Move_Copy_All
    );

    ////////////////////////// BUTTON ROW //////////////////////////////
    // standard buttons and ids
    Horizontal_Group bgroup   = Create_button_group();
    Button process            = Create_button("&Process","process");
    Button finish             = Create_finish_button("Finish","Finish");
    Button help_button        = Create_help_button(panel,"Help");

    Append(process     ,bgroup);
    Append(finish      ,bgroup);
    Append(help_button ,bgroup);

    /////////////////////// PANEL LAYOUT ///////////////////////////////
    // append widgets to vgroup in desired order
    Append(nsb_polygon,vgroup);
    Append(tb_output,vgroup);
    Append(cmbMsg   ,vgroup);
    Append(bgroup   ,vgroup);
    Append(vgroup,panel);
    Show_widget(panel);

    /////////////////////// EVENT LOOP /////////////////////////////////
    Integer doit = 1;
    while(doit)
    {
        Text cmd = "", msg = "";
        Integer id, ret = Wait_on_widgets(id,cmd,msg);

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
                    /////////////////// INPUT + VALIDATION /////////////////
                    Element source_polygon;
                    Integer source_result = Validate(nsb_polygon,source_polygon);
                    if(source_result != TRUE || !Element_exists(source_polygon))
                    {
                        Set_data(cmbMsg,"Select one valid closed polygon.");
                        break;
                    }

                    Real pick_x = 0.0;
                    Real pick_y = 0.0;
                    Real pick_z = 0.0;
                    Real pick_chainage = 0.0;
                    Real pick_height = 0.0;

                    if(Get_select_coordinate
                    (
                        nsb_polygon,
                        pick_x,
                        pick_y,
                        pick_z,
                        pick_chainage,
                        pick_height
                    ) != 0)
                    {
                        Set_data(cmbMsg,"Unable to read the source selection coordinate.");
                        break;
                    }

                    Integer target_mode = 0;
                    Text target_data = "";
                    if(Validate(tb_output,target_mode,target_data) != 0)
                    {
                        Set_data(cmbMsg,"Select a valid target option.");
                        break;
                    }

                    Model output_model;
                    Text output_model_name = "";
                    Integer delete_source = FALSE;

                    Integer target_result = resolve_target_model
                    (
                        source_polygon,
                        target_mode,
                        target_data,
                        output_model,
                        output_model_name,
                        delete_source
                    );

                    if(target_result != 0)
                    {
                        Set_data
                        (
                            cmbMsg,
                            "Invalid target selection or target text. Return code: "
                            + To_text(target_result)
                        );
                        break;
                    }

                    /////////////////// MAIN PROCESSING ////////////////////
                    Element output_polygon;
                    Integer old_start_vertex = -1;

                    Integer process_result = create_reordered_copy
                    (
                        source_polygon,
                        pick_x,
                        pick_y,
                        output_model,
                        output_polygon,
                        old_start_vertex
                    );

                    if(process_result == -2)
                    {
                        Set_data(cmbMsg,"The selected string is not closed.");
                        break;
                    }

                    if(process_result == -3)
                    {
                        Set_data(cmbMsg,"The selected polygon has fewer than three vertices.");
                        break;
                    }

                    if(process_result != 0)
                    {
                        Set_data
                        (
                            cmbMsg,
                            "Could not create the reordered polygon. Return code: "
                            + To_text(process_result)
                        );
                        break;
                    }

                    if(delete_source)
                    {
                        Add_undo_delete
                        (
                            "Remove original polygon after reordered move",
                            source_polygon,
                            1
                        );

                        if(Element_delete(source_polygon) != 0)
                        {
                            Set_data
                            (
                                cmbMsg,
                                "Output created in "
                                + output_model_name
                                + ", but the original polygon could not be deleted."
                            );
                            break;
                        }
                    }

                    /////////////////// STATUS MESSAGE /////////////////////
                    Text completion_message =
                        "Created reordered polygon in model "
                        + output_model_name
                        + ". Old vertex "
                        + To_text(old_start_vertex)
                        + " is now vertex 1.";

                    if(delete_source)
                    {
                        completion_message = completion_message + " Original removed.";
                    }
                    else
                    {
                        completion_message = completion_message + " Original retained.";
                    }

                    Set_data(cmbMsg,completion_message);
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
    // add pre-checks or environment checks here if needed
    mainPanel();
}
