/*---------------------------------------------------------------------
**   Programmer:          Kleber Lessa do Prado
**   Date:                21/09/26
**   12D Model:           V15
**   Version:             003
**   Macro Name:          Rename_Supers_From_Lot_Text.4dm
**   Type:                SOURCE
**
**   Brief description:
**       Rename allotment polygons and optional LC/PC Super strings from
**       the lot-number Text element located inside each polygon.
**
**   Description:
**       Allotment polygons are selected with a Source_Box. The lot-number
**       Text model is required. Lot Connection and Property Control models
**       are optional; a blank optional model field is skipped.
**
**       The polygon name uses the existing prefix/template input.
**       Lot Connections are named:  <lot text> + " LC"
**       Property Controls are named: <lot text> + " PC"
**
**       LC matching uses vertex 1 only. PC matching uses vertex 1 and may
**       use the final vertex as a fallback. Intermediate vertices are ignored.
**
**       If no lot text, or more than one lot text, is found inside a polygon,
**       that polygon and its related LC/PC strings are skipped.
**
**---------------------------------------------------------------------
*/
#define DEBUG_FILE       0
#define ECHO_DEBUG_FILE  0
#define ECHO_LINE_NO     0
#define BUILD            "15.0.006"

// ----------------------------- INCLUDES -----------------------------
#include "standard_library.h"
#include "size_of.h"

/*global variables*/{
    Integer MAX_POLYGON_POINTS = 10000;
}

void Get_template_parts(Text template_text, Text &prefix_text, Text &suffix_text)
{
    prefix_text = "";
    suffix_text = "";
    Integer star_position = Find_text(template_text, "*");
    if (star_position <= 0)
    {
        prefix_text = template_text;
        return;
    }
    Integer template_length = Text_length(template_text);
    if (star_position > 1)
        prefix_text = Get_subtext(template_text, 1, star_position - 1);
    if (star_position < template_length)
        suffix_text = Get_subtext(template_text, star_position + 1, template_length);
}

Integer Point_inside_super(Element polygon, Real test_x, Real test_y)
{
    Text polygon_type = "";
    if (Get_type(polygon, polygon_type) != 0) return FALSE;
    if (polygon_type != "Super") return FALSE;

    Integer is_closed = 0;
    if (String_closed(polygon, is_closed) != 0) return FALSE;
    if (is_closed == 0) return FALSE;

    Integer point_count = 0;
    if (Get_points(polygon, point_count) != 0) return FALSE;
    if (point_count < 3 || point_count > MAX_POLYGON_POINTS) return FALSE;

    Integer inside = FALSE;
    Integer j = point_count;
    for (Integer i = 1; i <= point_count; i++)
    {
        Real xi = 0.0, yi = 0.0, zi = 0.0;
        Real xj = 0.0, yj = 0.0, zj = 0.0;
        if (Get_super_vertex_coord(polygon, i, xi, yi, zi) != 0) return FALSE;
        if (Get_super_vertex_coord(polygon, j, xj, yj, zj) != 0) return FALSE;

        Integer crosses_y =
            (((yi > test_y) && (yj <= test_y)) ||
             ((yj > test_y) && (yi <= test_y)));
        if (crosses_y)
        {
            Real delta_y = yj - yi;
            if (delta_y != 0.0)
            {
                Real intersection_x = xi + ((test_y - yi) * (xj - xi) / delta_y);
                if (test_x < intersection_x) inside = !inside;
            }
        }
        j = i;
    }
    return inside;
}

Integer Get_text_information(Element text_element, Text &text_contents, Real &text_x, Real &text_y)
{
    text_contents = "";
    text_x = 0.0;
    text_y = 0.0;
    Text element_type = "";
    if (Get_type(text_element, element_type) != 0) return FALSE;
    if (element_type != "Text") return FALSE;

    Real text_size = 0.0, text_angle = 0.0;
    Integer text_colour = 0, text_justification = 0, text_type = 0;
    Real offset_distance = 0.0, rise_distance = 0.0;
    if (Get_text_data(text_element, text_contents, text_x, text_y,
                      text_size, text_colour, text_angle, text_justification,
                      text_type, offset_distance, rise_distance) != 0)
        return FALSE;
    if (text_contents == "") return FALSE;
    return TRUE;
}

Integer Add_rename_undo(Element changed, Text undo_name, Undo_List &ul)
{
    Element original_copy;
    if (Element_duplicate(changed, original_copy) != 0) return FALSE;
    Model null_model;
    Null(null_model);
    Set_model(original_copy, null_model);
    Undo u = Add_undo_change(undo_name, original_copy, changed);
    Append(u, ul);
    return TRUE;
}

Integer Rename_super(Element super_element, Text new_name, Text undo_name,
                     Undo_List &ul, Integer &rename_error_count)
{
    Element original_copy;
    if (Element_duplicate(super_element, original_copy) != 0)
    {
        rename_error_count++;
        return FALSE;
    }
    Model null_model;
    Null(null_model);
    Set_model(original_copy, null_model);

    if (Set_name(super_element, new_name) != 0)
    {
        rename_error_count++;
        return FALSE;
    }

    Undo u = Add_undo_change(undo_name, original_copy, super_element);
    Append(u, ul);
    return TRUE;
}

void Rename_model_supers_by_first_vertex(
    Dynamic_Element model_elements,
    Integer model_element_count,
    Element polygon,
    Text new_name,
    Text undo_name,
    Undo_List &ul,
    Integer allow_last_vertex_fallback,
    Integer &renamed_count,
    Integer &invalid_element_count,
    Integer &rename_error_count)
{
    for (Integer element_index = 1; element_index <= model_element_count; element_index++)
    {
        Element candidate;
        if (Get_item(model_elements, element_index, candidate) != 0)
        {
            invalid_element_count++;
            continue;
        }
        // Test geometry capability instead of rejecting an element solely
        // because Get_type() does not return the exact text "Super".
        Integer point_count = 0;
        if (Get_points(candidate, point_count) != 0 || point_count < 1)
        {
            invalid_element_count++;
            continue;
        }

        // Vertex 1 is always the ownership point for LC strings.
        Real first_x = 0.0, first_y = 0.0, first_z = 0.0;
        if (Get_super_vertex_coord(candidate, 1, first_x, first_y, first_z) != 0)
        {
            invalid_element_count++;
            continue;
        }

        Integer matched_polygon = Point_inside_super(polygon, first_x, first_y);

        // The last-vertex fallback is enabled only for PC strings.
        // LC strings must never be assigned from vertex 2 or any later vertex.
        if (allow_last_vertex_fallback && matched_polygon == FALSE && point_count > 1)
        {
            Real last_x = 0.0, last_y = 0.0, last_z = 0.0;
            if (Get_super_vertex_coord(candidate, point_count, last_x, last_y, last_z) == 0)
                matched_polygon = Point_inside_super(polygon, last_x, last_y);
        }

        if (matched_polygon)
        {
            if (Rename_super(candidate, new_name, undo_name, ul, rename_error_count))
                renamed_count++;
        }
    }
}

void mainPanel()
{
    Text panelName = "Rename Lot, LC and PC Strings from Text";
    Panel panel = Create_panel(panelName, TRUE);
    Vertical_Group vgroup = Create_vertical_group(-1);
    Colour_Message_Box cmbMsg = Create_colour_message_box("");

    ////////////////////////////// WIDGETS //////////////////////////////
    Source_Box sb_polygons = Create_source_box("Allotment polygons", cmbMsg, 0);
    Model_Box mb_text_model = Create_model_box("Lot-number text model", cmbMsg, CHECK_MODEL_MUST_EXIST);
    Model_Box mb_lc_model = Create_model_box("Lot Connection model (optional)", cmbMsg, CHECK_MODEL_EXISTS);
    Model_Box mb_pc_model = Create_model_box("Property Control model (optional)", cmbMsg, CHECK_MODEL_EXISTS);
    Input_Box ipb_template = Create_input_box("Polygon prefix/template, optional * separates suffix", cmbMsg);
    
    Set_data(ipb_template, "Lot ");
    Set_optional(mb_lc_model, TRUE);
    Set_optional(mb_pc_model, TRUE);

    ////////////////////////// BUTTON ROW //////////////////////////////
    Horizontal_Group bgroup = Create_button_group();
    Button process = Create_button("&Process", "process");
    Button finish = Create_finish_button("Finish", "Finish");
    Button help_button = Create_help_button(panel, "Help");
    Append(process, bgroup);
    Append(finish, bgroup);
    Append(help_button, bgroup);

    /////////////////////// PANEL LAYOUT ///////////////////////////////
    Append(sb_polygons, vgroup);
    Append(mb_text_model, vgroup);
    Append(mb_lc_model, vgroup);
    Append(mb_pc_model, vgroup);
    Append(ipb_template, vgroup);
    Append(cmbMsg, vgroup);
    Append(bgroup, vgroup);
    Append(vgroup, panel);
    Show_widget(panel);

    /////////////////////// EVENT LOOP /////////////////////////////////
    Integer doit = 1;
    while (doit)
    {
        Text cmd = "", msg = "";
        Integer id, ret = Wait_on_widgets(id, cmd, msg);
        switch (cmd)
        {
            case "keystroke":
            case "set_focus":
            case "kill_focus":
            {
                continue;
            }
            break;
            case "CodeShutdown":
            {
                Set_exit_code(cmd);
            }
            break;
        }

        switch (id)
        {
            case Get_id(panel):
            {
                if (cmd == "Panel Quit") doit = 0;
                if (cmd == "Panel About") about_panel(panel);
            }
            break;

            case Get_id(process):
            {
                if (cmd == "process")
                {
                    Set_data(cmbMsg, "Validating inputs...");

                    Dynamic_Element polygon_list;
                    if (Validate(sb_polygons, polygon_list) == FALSE)
                    {
                        Set_error_message(sb_polygons, "Select the closed Super-string allotments.");
                        break;
                    }
                    Integer polygon_count = 0;
                    if (Get_number_of_items(polygon_list, polygon_count) != 0 || polygon_count <= 0)
                    {
                        Set_error_message(sb_polygons, "No allotment polygons were selected.");
                        break;
                    }

                    Model text_model;
                    if (Validate(mb_text_model, GET_MODEL, text_model) != MODEL_EXISTS)
                        break;


                    Model lc_model;
                    Integer lc_status = Validate(mb_lc_model, GET_MODEL, lc_model);
                    Integer use_lc_model = FALSE;

                    if (lc_status == MODEL_EXISTS)
                    {
                        use_lc_model = TRUE;
                    }
                    else if (lc_status != NO_NAME)
                    {
                        break;
                    }

                    Model pc_model;
                    Integer pc_status = Validate(mb_pc_model, GET_MODEL, pc_model);
                    Integer use_pc_model = FALSE;

                    if (pc_status == MODEL_EXISTS)
                    {
                        use_pc_model = TRUE;
                    }
                    else if (pc_status != NO_NAME)
                    {
                        break;
                    }

                    Text template_text = "", prefix_text = "", suffix_text = "";
                    Get_data(ipb_template, template_text);
                    Get_template_parts(template_text, prefix_text, suffix_text);

                    Dynamic_Element text_elements, lc_elements, pc_elements;
                    Integer text_element_count = 0, lc_element_count = 0, pc_element_count = 0;
                    if (Get_elements(text_model, text_elements, text_element_count) != 0 || text_element_count <= 0)
                    {
                        Set_error_message(mb_text_model, "Unable to retrieve lot-number Text elements.");
                        break;
                    }
                    if (use_lc_model)
                    {
                        if (Get_elements(lc_model, lc_elements, lc_element_count) != 0)
                        {
                            Set_error_message(mb_lc_model, "Unable to retrieve Lot Connection elements.");
                            break;
                        }
                    }
                    if (use_pc_model)
                    {
                        if (Get_elements(pc_model, pc_elements, pc_element_count) != 0)
                        {
                            Set_error_message(mb_pc_model, "Unable to retrieve Property Control elements.");
                            break;
                        }
                    }

                    Integer polygon_renamed_count = 0;
                    Integer lc_renamed_count = 0;
                    Integer pc_renamed_count = 0;
                    Integer no_text_count = 0;
                    Integer multiple_text_count = 0;
                    Integer invalid_polygon_count = 0;
                    Integer invalid_lc_count = 0;
                    Integer invalid_pc_count = 0;
                    Integer rename_error_count = 0;
                    Undo_List ul;

                    for (Integer polygon_index = 1; polygon_index <= polygon_count; polygon_index++)
                    {
                        Element polygon;
                        if (Get_item(polygon_list, polygon_index, polygon) != 0)
                        {
                            invalid_polygon_count++;
                            continue;
                        }
                        Text polygon_type = "";
                        Integer polygon_closed = 0;
                        if (Get_type(polygon, polygon_type) != 0 || polygon_type != "Super" ||
                            String_closed(polygon, polygon_closed) != 0 || polygon_closed == 0)
                        {
                            invalid_polygon_count++;
                            continue;
                        }

                        Integer matching_text_count = 0;
                        Text matching_text = "";
                        for (Integer text_index = 1; text_index <= text_element_count; text_index++)
                        {
                            Element text_element;
                            if (Get_item(text_elements, text_index, text_element) != 0) continue;
                            Text text_contents = "";
                            Real text_x = 0.0, text_y = 0.0;
                            if (Get_text_information(text_element, text_contents, text_x, text_y) == FALSE)
                                continue;
                            if (Point_inside_super(polygon, text_x, text_y))
                            {
                                matching_text_count++;
                                matching_text = text_contents;
                            }
                        }

                        if (matching_text_count == 0)
                        {
                            no_text_count++;
                            continue;
                        }
                        if (matching_text_count > 1)
                        {
                            multiple_text_count++;
                            continue;
                        }

                        Text polygon_name = prefix_text + matching_text + suffix_text;
                        if (Rename_super(polygon, polygon_name, "Rename allotment", ul, rename_error_count))
                            polygon_renamed_count++;

                        if (use_lc_model)
                        {
                            Rename_model_supers_by_first_vertex(
                                lc_elements, lc_element_count, polygon,
                                matching_text + " LC", "Rename lot connection",
                                ul, FALSE, lc_renamed_count, invalid_lc_count, rename_error_count);
                        }
                        if (use_pc_model)
                        {
                            Rename_model_supers_by_first_vertex(
                                pc_elements, pc_element_count, polygon,
                                matching_text + " PC", "Rename property control",
                                ul, TRUE, pc_renamed_count, invalid_pc_count, rename_error_count);
                        }
                    }

                    Integer total_renamed = polygon_renamed_count + lc_renamed_count + pc_renamed_count;
                    if (total_renamed > 0)
                        Add_undo_list("Rename allotments, lot connections and property controls", ul);

                    Text result_message =
                        "Finished. Lots: " + To_text(polygon_renamed_count) +
                        ", LC: " + To_text(lc_renamed_count) +
                        ", PC: " + To_text(pc_renamed_count) +
                        ". No text: " + To_text(no_text_count) +
                        ". Multiple texts: " + To_text(multiple_text_count) +
                        ". Invalid/open lots: " + To_text(invalid_polygon_count) +
                        ". Invalid LC: " + To_text(invalid_lc_count) +
                        ". Invalid PC: " + To_text(invalid_pc_count) +
                        ". Rename errors: " + To_text(rename_error_count) + ".";
                    Set_data(cmbMsg, result_message);
                }
            }
            break;

            default:
            {
                if (cmd == "Finish") doit = 0;
            }
            break;
        }
    }
}

void main()
{
    Text project_name = "";
    Get_project_name(project_name);
    if (project_name == "")
    {
        Print("Error: No project is open.\n");
        return;
    }
    Print("Rename Lot, LC and PC Strings from Text - Build " + BUILD + "\n");
    mainPanel();
    Print("Macro finished.\n");
}
