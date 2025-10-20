/*---------------------------------------------------------------------
**   Programmer: ChatGPT (OpenAI)
**   Date: 03/11/2023
**   12D Model:            V15
**   Version:              001
**   Macro Name:           Polygon_Centroid_Creator.4dm
**   Type:                 SOURCE
**
**   Brief description: Creates centroid points for closed polygons
**                       from a user selected data source.
**
**---------------------------------------------------------------------
**   Description:
**   This panel driven macro asks the user to provide a data source that
**   contains polygon elements and a destination model for writing the
**   centroid points. Each element in the source is validated to ensure
**   that it forms a closed polygon. Polygons that fail this validation
**   are reported to the output window and skipped. For valid polygons the
**   centroid is calculated using the built in Get_polygon_centroid()
**   function (command id 3479) and a point element is created in the
**   nominated centroid model.
**
**---------------------------------------------------------------------
**   Update/Modification
**
**   001 - Initial release.
**
**---------------------------------------------------------------------
*/

#define DEBUG_FILE      0
#define ECHO_DEBUG_FILE 0
#define ECHO_LINE_NO    0

#define BUILD "15.0.001"

// ----------------------------- INCLUDES -----------------------------
#include "..\\..\\include\\standard_library.H"
#include "..\\..\\include\\size_of.H"

// --------------------------- CONSTANTS ------------------------------
const Real kClosureTolerance = 0.001; // metres

// --------------------------- PROTOTYPES -----------------------------
Integer read_vertex(Element element, Integer index, Real &x, Real &y, Real &z);
Integer is_polygon_closed(Element element, Real tolerance);
Integer create_centroid_point(Model model, Real cx, Real cy, Real cz);
void mainPanel();

// --------------------------------------------------------------------
// Safely returns the XYZ of the requested vertex. Tries super vertex
// coordinates first, then falls back to 3d/2d data.
Integer read_vertex(Element element, Integer index, Real &x, Real &y, Real &z)
{
    if(Get_super_vertex_coord(element, index, x, y, z) == 0)
    {
        return 0;
    }

    if(Get_3d_data(element, index, x, y, z) == 0)
    {
        return 0;
    }

    if(Get_2d_data(element, index, x, y) == 0)
    {
        z = 0.0;
        return 0;
    }

    return 1;
}

// --------------------------------------------------------------------
// Returns TRUE (1) when the element is a closed polygon.
Integer is_polygon_closed(Element element, Real tolerance)
{
    Integer num_points = 0;
    Get_points(element, num_points);

    if(num_points < 3)
    {
        return 0;
    }

    Real x_first = 0.0, y_first = 0.0, z_first = 0.0;
    Real x_last  = 0.0, y_last  = 0.0, z_last  = 0.0;

    if(read_vertex(element, 1, x_first, y_first, z_first) != 0)
    {
        return 0;
    }

    if(read_vertex(element, num_points, x_last, y_last, z_last) != 0)
    {
        return 0;
    }

    Real dx = Abs(x_last - x_first);
    Real dy = Abs(y_last - y_first);
    Real dz = Abs(z_last - z_first);

    if(dx > tolerance || dy > tolerance || dz > tolerance)
    {
        return 0;
    }

    return 1;
}

// --------------------------------------------------------------------
// Creates a point element at the supplied XYZ and appends it to model.
Integer create_centroid_point(Model model, Real cx, Real cy, Real cz)
{
    Element point_element;
    Integer rc = Create_point_element(cx, cy, cz, point_element);
    if(rc != 0)
    {
        return rc;
    }

    rc = Add_element(model, point_element);
    return rc;
}

// --------------------------------------------------------------------
void mainPanel()
{
    Text panelName = "Polygon Centroid Creator";
    Panel panel = Create_panel(panelName, TRUE);
    Vertical_Group vgroup = Create_vertical_group(-1);
    Colour_Message_Box cmbMsg = Create_colour_message_box("");

    Source_Box sb_source = Create_source_box("Source polygons", cmbMsg, 0);
    Model_Box mb_centroid = Create_model_box("Centroid model", cmbMsg, CHECK_MODEL_CREATE);

    Horizontal_Group bgroup = Create_button_group();
    Button process = Create_button("&Process", "process");
    Button finish = Create_finish_button("Finish", "Finish");
    Button help_button = Create_help_button(panel, "Help");

    Append(process, bgroup);
    Append(finish, bgroup);
    Append(help_button, bgroup);

    Append(sb_source, vgroup);
    Append(mb_centroid, vgroup);
    Append(cmbMsg, vgroup);
    Append(bgroup, vgroup);

    Append(vgroup, panel);
    Show_widget(panel);

    Clear_console();

    Integer doit = 1;
    while(doit)
    {
        Text cmd = "", msg = "";
        Integer id = 0;
        Integer ret = Wait_on_widgets(id, cmd, msg);

        switch(cmd)
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

        switch(id)
        {
            case Get_id(panel):
            {
                if(cmd == "Panel Quit")
                {
                    doit = 0;
                }
                else if(cmd == "Panel About")
                {
                    about_panel(panel);
                }
            }
            break;

            case Get_id(process):
            {
                if(cmd == "process")
                {
                    Dynamic_Element de_source;
                    if(Validate(sb_source, de_source) == FALSE)
                    {
                        Set_error_message(sb_source, "Please choose a source containing polygons");
                        break;
                    }

                    Integer source_count = 0;
                    Get_number_of_items(de_source, source_count);
                    if(source_count <= 0)
                    {
                        Set_error_message(sb_source, "No elements in source");
                        break;
                    }

                    Model centroid_model;
                    Integer model_status = Validate(mb_centroid, CHECK_MODEL_CREATE, centroid_model);
                    if(model_status == 0)
                    {
                        Set_error_message(mb_centroid, "Please nominate a centroid model");
                        break;
                    }

                    Print("--- Polygon Centroid Creator ---\n");
                    Integer total_processed = 0;
                    Integer total_created = 0;
                    Integer total_skipped = 0;

                    for(Integer i = 1; i <= source_count; i++)
                    {
                        Element polygon_element;
                        if(Get_item(de_source, i, polygon_element) != 0)
                        {
                            continue;
                        }

                        Text poly_name = "";
                        Get_name(polygon_element, poly_name);
                        if(Text_length(poly_name) == 0)
                        {
                            poly_name = "<no name>";
                        }

                        total_processed = total_processed + 1;

                        if(!is_polygon_closed(polygon_element, kClosureTolerance))
                        {
                            Print("SKIP | Polygon \"" + poly_name + "\" is not closed\n");
                            total_skipped = total_skipped + 1;
                            continue;
                        }

                        Real cx = 0.0, cy = 0.0, cz = 0.0;
                        Integer centroid_rc = Get_polygon_centroid(polygon_element, cx, cy, cz);
                        if(centroid_rc != 0)
                        {
                            Print("SKIP | Failed to calculate centroid for \"" + poly_name + "\" (rc=" + To_text(centroid_rc) + ")\n");
                            total_skipped = total_skipped + 1;
                            continue;
                        }

                        Integer create_rc = create_centroid_point(centroid_model, cx, cy, cz);
                        if(create_rc != 0)
                        {
                            Print("SKIP | Failed to create centroid for \"" + poly_name + "\" (rc=" + To_text(create_rc) + ")\n");
                            total_skipped = total_skipped + 1;
                            continue;
                        }

                        Print("OK   | Centroid created for \"" + poly_name + "\" at (" + To_text(cx, 3) + ", " + To_text(cy, 3) + ", " + To_text(cz, 3) + ")\n");
                        total_created = total_created + 1;
                    }

                    RefreshModelViews(centroid_model);

                    Text summary = "Processed=" + To_text(total_processed)
                                    + ", created=" + To_text(total_created)
                                    + ", skipped=" + To_text(total_skipped);
                    Set_data(cmbMsg, summary);
                    Print(summary + "\n");
                }
            }
            break;

            default:
            {
                if(cmd == "Finish")
                {
                    doit = 0;
                }
            }
            break;
        }
    }
}

void main()
{
    Text project_name = "";
    Get_project_name(project_name);

    if(project_name == "")
    {
        Print("Error: No project is open.\n");
        return;
    }

    Print("Polygon Centroid Creator - Build " + BUILD + "\n");
    mainPanel();
    Print("Macro finished\n");
}
