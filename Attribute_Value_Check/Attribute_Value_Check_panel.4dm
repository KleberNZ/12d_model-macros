/*---------------------------------------------------------------------
**   Programmer:           KLP
**   Date:                 2026-06-05
**   12D Model:            V15
**   Version:              001
**   Macro Name:           Attribute_Value_Check.4dm
**   Type:                 SOURCE
**
**   Brief description: Check selected strings for matching node/vertex or link/segment attributes.
**
**---------------------------------------------------------------------
**   Description:
**      This macro scans user-selected 12d elements and reports attribute
**      values that match one or more user-defined tests.
**
**      Tests are entered in a GridCtrl_Box, allowing multiple attribute
**      checks to be run at once. Each test specifies the target attribute
**      location, attribute name, data type, comparison operation, and test
**      value.
**
**      Supported targets:
**         - String/element attributes: Element attributes accessed via Get_attribute
**         - Drainage strings: Node attributes and Link attributes
**         - Super strings:    Vertex attributes and Segment attributes
**
**      Matching results are reported in a grouped Log_Box. Each flagged
**      item includes the element name, item index, attribute value found,
**      comparison operation, and test value. Where coordinates can be
**      resolved, clicking the Log_Box result line highlights / zooms to
**      the matching node, vertex, or segment midpoint.
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
/////////////////////HELPERS/////////////////////

// Helper: cast
Widget cast(Widget w) { return w;}

// Helper: grid_row_is_blank
Integer grid_row_is_blank(Text att_name, Text test_value)
{
    if(att_name == "" && test_value == "") return 1;
    return 0;
}

// Helper: report_selected_elements
void report_selected_elements(Log_Box lb_report, Dynamic_Element &selected_elements)
{
    Integer count;
    Integer i;
    Element elt;
    Text name;
    Text type;
    Text msg;

    Get_number_of_items(selected_elements, count);

    for(i = 1; i <= count; i++)
    {
        Get_item(selected_elements, i, elt);

        name = "";
        type = "";

        Get_name(elt, name);
        Get_type(elt, type);

        msg = "Element " + To_text(i) + ": " + name + " [" + type + "]";

        Log_Line line = Create_text_log_line(msg, 0);
        Add_log_line(lb_report, line);

        Null(elt);
    }
}

// Helper: compare_real_value
Integer compare_real_value(Real found, Text operation, Real test_value)
{
    if(operation == "equal to")                 { if(found == test_value) return 1; }
    if(operation == "not equal to")             { if(found != test_value) return 1; }
    if(operation == "less than")                { if(found <  test_value) return 1; }
    if(operation == "less than or equal to")    { if(found <= test_value) return 1; }
    if(operation == "greater than")             { if(found >  test_value) return 1; }
    if(operation == "greater than or equal to") { if(found >= test_value) return 1; }

    return 0;
}

// Helper: compare_integer_value
Integer compare_integer_value(Integer found, Text operation, Integer test_value)
{
    if(operation == "equal to")                 { if(found == test_value) return 1; }
    if(operation == "not equal to")             { if(found != test_value) return 1; }
    if(operation == "less than")                { if(found <  test_value) return 1; }
    if(operation == "less than or equal to")    { if(found <= test_value) return 1; }
    if(operation == "greater than")             { if(found >  test_value) return 1; }
    if(operation == "greater than or equal to") { if(found >= test_value) return 1; }

    return 0;
}

// Helper: compare_text_value
Integer compare_text_value(Text found, Text operation, Text test_value)
{
    Integer pos;

    if(operation == "equal to")          { if(found == test_value) return 1; }
    if(operation == "not equal to")      { if(found != test_value) return 1; }

    if(operation == "contains")
    {
        //pos = Find_text(found, test_value);
        pos = Find_text(Text_lower(found), Text_lower(test_value)); // case insensitive search for contains
        if(pos != 0) return 1;
    }

    if(operation == "does not contain")
    {
        //pos = Find_text(found, test_value);
        pos = Find_text(Text_lower(found), Text_lower(test_value)); // case insensitive search for does not contain
        if(pos == 0) return 1;
    }

    return 0;
}

// Helper: read_compare_attribute
Integer read_compare_attribute(Element elt, Text elt_type, Text target, Text att_name, Text att_type, Text operation, Text test_value, Integer item, Text &found_text)
{
    Integer rc;
    Integer found_integer;
    Integer test_integer;
    Real found_real;
    Real test_real;
    Text found_string;

    rc = -1;
    found_text = "";

    if(target == "String / element attributes")
    {
        if(att_type == "real")
        {
            if(From_text(test_value, test_real) != 0) return 0;
            rc = Get_attribute(elt, att_name, found_real);
            if(rc != 0) return 0;

            found_text = To_text(found_real, 6);
            return compare_real_value(found_real, operation, test_real);
        }

        if(att_type == "integer")
        {
            if(From_text(test_value, test_integer) != 0) return 0;
            rc = Get_attribute(elt, att_name, found_integer);
            if(rc != 0) return 0;

            found_text = To_text(found_integer);
            return compare_integer_value(found_integer, operation, test_integer);
        }

        if(att_type == "text")
        {
            rc = Get_attribute(elt, att_name, found_string);
            if(rc != 0) return 0;

            found_text = found_string;
            return compare_text_value(found_string, operation, test_value);
        }

        return 0;
    }

    if(att_type == "real")
    {
        if(From_text(test_value, test_real) != 0) return 0;

        if(elt_type == "Drainage")
        {
            if(target == "Vertex / node attributes")  rc = Get_drainage_pit_attribute(elt, item, att_name, found_real);
            if(target == "Segment / link attributes") rc = Get_drainage_pipe_attribute(elt, item, att_name, found_real);
        }
        else
        {
            if(target == "Vertex / node attributes")  rc = Get_super_vertex_attribute(elt, item, att_name, found_real);
            if(target == "Segment / link attributes") rc = Get_super_segment_attribute(elt, item, att_name, found_real);
        }

        if(rc != 0) return 0;

        found_text = To_text(found_real, 6);
        return compare_real_value(found_real, operation, test_real);
    }

    if(att_type == "integer")
    {
        if(From_text(test_value, test_integer) != 0) return 0;

        if(elt_type == "Drainage")
        {
            if(target == "Vertex / node attributes")  rc = Get_drainage_pit_attribute(elt, item, att_name, found_integer);
            if(target == "Segment / link attributes") rc = Get_drainage_pipe_attribute(elt, item, att_name, found_integer);
        }
        else
        {
            if(target == "Vertex / node attributes")  rc = Get_super_vertex_attribute(elt, item, att_name, found_integer);
            if(target == "Segment / link attributes") rc = Get_super_segment_attribute(elt, item, att_name, found_integer);
        }

        if(rc != 0) return 0;

        found_text = To_text(found_integer);
        return compare_integer_value(found_integer, operation, test_integer);
    }

    if(att_type == "text")
    {
        if(elt_type == "Drainage")
        {
            if(target == "Vertex / node attributes")  rc = Get_drainage_pit_attribute(elt, item, att_name, found_string);
            if(target == "Segment / link attributes") rc = Get_drainage_pipe_attribute(elt, item, att_name, found_string);
        }
        else
        {
            if(target == "Vertex / node attributes")  rc = Get_super_vertex_attribute(elt, item, att_name, found_string);
            if(target == "Segment / link attributes") rc = Get_super_segment_attribute(elt, item, att_name, found_string);
        }

        if(rc != 0) return 0;

        found_text = found_string;
        return compare_text_value(found_string, operation, test_value);
    }

    return 0;
}

// Helper: get_target_item_count
Integer get_target_item_count(Element elt, Text elt_type, Text target, Integer &count)
{
    count = 0;
    if(target == "String / element attributes")
    {
        count = 1;
        return 0;
    }

    if(elt_type == "Drainage")
    {
        if(target == "Vertex / node attributes")  return Get_drainage_pits(elt, count);
        if(target == "Segment / link attributes") return Get_segments(elt, count);
    }
    else
    {
        if(target == "Vertex / node attributes")  return Get_points(elt, count);
        if(target == "Segment / link attributes") return Get_segments(elt, count);
    }

    return 1;
}

// Helper: get_item_highlight_coord
Integer get_item_highlight_coord(Element elt, Text elt_type, Text target, Integer item, Real &x, Real &y, Real &z)
{
    Integer pit_count;
    Real x1;
    Real y1;
    Real z1;
    Real x2;
    Real y2;
    Real z2;

    x = 0.;
    y = 0.;
    z = 0.;

    if(elt_type == "Drainage")
    {
        if(target == "String / element attributes")
        {
            return 1;
        }
        if(target == "Vertex / node attributes")
        {
            return Get_drainage_pit(elt, item, x, y, z);
        }

        if(target == "Segment / link attributes")
        {
            Get_drainage_pits(elt, pit_count);

            if(item + 1 > pit_count) return 1;

            if(Get_drainage_pit(elt, item,     x1, y1, z1) != 0) return 1;
            if(Get_drainage_pit(elt, item + 1, x2, y2, z2) != 0) return 1;

            x = (x1 + x2) / 2.;
            y = (y1 + y2) / 2.;
            z = (z1 + z2) / 2.;

            return 0;
        }
    }
    else
    {
        if(target == "String / element attributes")
        {
            return 1;
        }
        if(target == "Vertex / node attributes")
        {
            return Get_super_vertex_coord(elt, item, x, y, z);
        }

        if(target == "Segment / link attributes")
        {
            if(Get_super_vertex_coord(elt, item,     x1, y1, z1) != 0) return 1;
            if(Get_super_vertex_coord(elt, item + 1, x2, y2, z2) != 0) return 1;

            x = (x1 + x2) / 2.;
            y = (y1 + y2) / 2.;
            z = (z1 + z2) / 2.;

            return 0;
        }
    }

    return 1;
}

// Helper: valid_operation_for_type
Integer valid_operation_for_type(Text att_type, Text operation)
{
    if(att_type == "real" || att_type == "integer")
    {
        if(operation == "equal to") return 1;
        if(operation == "not equal to") return 1;
        if(operation == "less than") return 1;
        if(operation == "less than or equal to") return 1;
        if(operation == "greater than") return 1;
        if(operation == "greater than or equal to") return 1;

        return 0;
    }

    if(att_type == "text")
    {
        if(operation == "equal to") return 1;
        if(operation == "not equal to") return 1;
        if(operation == "contains") return 1;
        if(operation == "does not contain") return 1;

        return 0;
    }

    return 0;
}

// ----------------------------- PANEL -----------------------------
void mainPanel(){

    Text panelName="Attribute Value Check";
    Panel              panel  = Create_panel              (panelName,TRUE);
    Vertical_Group     vgroup = Create_vertical_group     (-1         );
    Colour_Message_Box cmbMsg = Create_colour_message_box (""         );

    ///////////////////CREATE INPUT WIDGETS////////////////
    // create some input fields
    Source_Box sb_data = Create_source_box("Data to test", cmbMsg, 0);

    Integer num_rows = 1;
    Integer num_cols = 5;
    Integer show_nav = 1;

    Widget column_widgets[num_cols];

        // Signature: Choice_Box Create_choice_box(Text title,Message_Box message)
    Choice_Box cb_grid_target = Create_choice_box("Target", cmbMsg);
    {
        Integer nchoices = 3;
        Text choices[nchoices];
        choices[1] = "String / element attributes";
        choices[2] = "Vertex / node attributes";
        choices[3] = "Segment / link attributes";
        
        Set_data(cb_grid_target, nchoices, choices);
    }

    // Signature: Input_Box Create_input_box(Text title,Message_Box message)
    Input_Box ib_grid_att_name = Create_input_box("Attribute Name", cmbMsg);

    // Signature: Choice_Box Create_choice_box(Text title,Message_Box message)
    Choice_Box cb_grid_type = Create_choice_box("Type", cmbMsg);
    {
        Integer nchoices = 3;
        Text choices[nchoices];
        choices[1] = "real";
        choices[2] = "integer";
        choices[3] = "text";
        Set_data(cb_grid_type, nchoices, choices);
    }

    // Signature: Choice_Box Create_choice_box(Text title,Message_Box message)
    Choice_Box cb_grid_operation = Create_choice_box("Operation", cmbMsg);
    {
        Integer nchoices = 8;
        Text choices[nchoices];
        choices[1] = "equal to";
        choices[2] = "not equal to";
        choices[3] = "less than";
        choices[4] = "less than or equal to";
        choices[5] = "greater than";
        choices[6] = "greater than or equal to";
        choices[7] = "contains";
        choices[8] = "does not contain";
        Set_data(cb_grid_operation, nchoices, choices);
    }

    // Signature: Input_Box Create_input_box(Text title,Message_Box message)
    Input_Box ib_grid_test_value = Create_input_box("Test Value", cmbMsg);

    column_widgets[1] = cast(cb_grid_target);
    column_widgets[2] = cast(ib_grid_att_name);
    column_widgets[3] = cast(cb_grid_type);
    column_widgets[4] = cast(cb_grid_operation);
    column_widgets[5] = cast(ib_grid_test_value);

    // Signature: GridCtrl_Box Create_gridctrl_box(Text name,Integer num_rows,Integer num_columns,Widget column_widgets[],Integer show_nav,Message_Box messages,Integer width,Integer height)
    GridCtrl_Box gb_tests = Create_gridctrl_box("Attribute Tests", num_rows, num_cols, column_widgets, show_nav, cmbMsg, 600, 160);

    // Signature: Log_Box Create_log_box(Text name,Integer width,Integer height)
    Log_Box lb_report = Create_log_box("Attribute Value Check Report", 100, 16);

    ///////////////ADDING BUTTONS ALONG THE BOTTOM///////////////////////////
    Horizontal_Group bgroup = Create_button_group();
    Button process     = Create_button       ("&Process" ,"process");
    Button finish      = Create_finish_button("Finish"   ,"Finish" );
    Button help_button = Create_help_button  (panel      ,"Help"   );

    Append(process     ,bgroup);
    Append(finish      ,bgroup);
    Append(help_button ,bgroup);

    ///////////////ADDING WIDGETS TO PANEL///////////////////////////
    // add your widgets to vgroup

    Append(sb_data   ,vgroup);
    Append(gb_tests  ,vgroup);
    Append(lb_report ,vgroup);

    Append(cmbMsg      ,vgroup);
    Append(bgroup      ,vgroup);

    Append(vgroup,panel);
    Show_widget(panel);

    // GridCtrl_Box setup after Show_widget(panel).

    Set_column_width(gb_tests, 1, 170);
    Set_column_width(gb_tests, 2, 180);
    Set_column_width(gb_tests, 3, 80);
    Set_column_width(gb_tests, 4, 150);
    Set_column_width(gb_tests, 5, 140);

    Format_grid(gb_tests);
    Set_modified(gb_tests, 0);
    Set_warn_on_modified(gb_tests, 0);

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

                Dynamic_Element selected_elements;
                Integer source_rc;
                Integer source_count;
                Integer row_count;
                Integer row;
                Integer valid_tests;
                Text target;
                Text att_name;
                Text att_type;
                Text operation;
                Text test_value;

                Integer element_count;
                Integer element_index;
                Integer item_count;
                Integer item;
                Integer matched;
                Integer element_matches;
                Element elt;
                Text elt_name;
                Text elt_type;
                Text found_value;
                Text item_label;
                Text line_text;
                Real hx;
                Real hy;
                Real hz;
                Log_Line element_group;
                Log_Line item_line;

                valid_tests = 0;
                matched = 0;

                // validate widgets

                Clear(lb_report);
                Null(selected_elements);

                source_rc = Validate(sb_data, selected_elements);
                Get_number_of_items(selected_elements, source_count);

                if(source_rc == 0)
                {
                    Set_data(cmbMsg, "Source_Box drastic error", 2);
                    continue;
                }

                if(source_count == 0)
                {
                    Set_data(cmbMsg, "No elements selected in source data", 2);
                    continue;
                }

                row_count = Get_row_count(gb_tests);

                for(row = 1; row <= row_count; row++)
                {
                    Load_widgets_from_row(gb_tests, row);

                    Validate(cb_grid_target, target);
                    Validate(ib_grid_att_name, att_name);
                    Validate(cb_grid_type, att_type);
                    Validate(cb_grid_operation, operation);
                    Validate(ib_grid_test_value, test_value);

                    if(grid_row_is_blank(att_name, test_value))
                    {
                        continue;
                    }

                    if(att_name == "")
                    {
                        Set_data(cmbMsg, "Row " + To_text(row) + ": Attribute Name is blank", 2);
                        continue;
                    }

                    if(test_value == "")
                    {
                        Set_data(cmbMsg, "Row " + To_text(row) + ": Test Value is blank", 2);
                        continue;
                    }

                    if(valid_operation_for_type(att_type, operation) == 0)
                    {
                        Set_data(cmbMsg, "Row " + To_text(row) + ": Operation is not valid for type " + att_type, 2);
                        continue;
                    }

                    valid_tests++;
                }

                if(valid_tests == 0)
                {
                    Set_data(cmbMsg, "No valid test rows found", 2);
                    continue;
                }

                // do calc

                Get_number_of_items(selected_elements, element_count);

                for(element_index = 1; element_index <= element_count; element_index++)
                {
                    Get_item(selected_elements, element_index, elt);

                    elt_name = "";
                    elt_type = "";

                    Get_name(elt, elt_name);
                    Get_type(elt, elt_type);

                    element_matches = 0;
                    element_group = Create_group_log_line(elt_name + " [" + elt_type + "]", 0);

                    for(row = 1; row <= row_count; row++)
                    {
                        Load_widgets_from_row(gb_tests, row);

                        Validate(cb_grid_target, target);
                        Validate(ib_grid_att_name, att_name);
                        Validate(cb_grid_type, att_type);
                        Validate(cb_grid_operation, operation);
                        Validate(ib_grid_test_value, test_value);

                        if(grid_row_is_blank(att_name, test_value)) continue;
                        if(att_name == "") continue;
                        if(test_value == "") continue;
                        if(valid_operation_for_type(att_type, operation) == 0) continue;

                        item_count = 0;
                        if(get_target_item_count(elt, elt_type, target, item_count) != 0) continue;

                        for(item = 1; item <= item_count; item++)
                        {
                            if(read_compare_attribute(elt, elt_type, target, att_name, att_type, operation, test_value, item, found_value))
                            {
                                if(target == "Vertex / node attributes")       item_label = "Node/Vertex ";
                                else if(target == "Segment / link attributes") item_label = "Link/Segment ";
                                else                                           item_label = "String/Element ";
                                line_text = item_label + To_text(item) +
                                            " | " + att_name +
                                            " | found " + found_value +
                                            " | " + operation +
                                            " | test " + test_value;

                                if(get_item_highlight_coord(elt, elt_type, target, item, hx, hy, hz) == 0)
                                {
                                    item_line = Create_highlight_point_log_line(line_text, 0, hx, hy, hz);
                                }
                                else
                                {
                                    item_line = Create_text_log_line(line_text, 0);
                                }

                                Append_log_line(item_line, element_group);

                                matched++;
                                element_matches++;
                            }
                        }
                    }

                    if(element_matches > 0)
                    {
                        Add_log_line(lb_report, element_group);
                    }

                    Null(elt);
                }

                Set_data(cmbMsg, "Process finished. Matches = " + To_text(matched), 0);
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