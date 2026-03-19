/*---------------------------------------------------------------------
**   Programmer: User
**   Date: 18/08/25             
**   12D Model: V15
**   Version: 001
**   Macro Name: rename_elements.4dm
**   Type: SOURCE
**
**   Brief description: Rename all super elements in selected model
**
**---------------------------------------------------------------------
**   Description: This macro loops through all elements in a 
**               selected model and renames them with sequential 
**               numbers starting from user defined start number. The increment 
**               can also be defined by the user but ,ust be a positive number.
**               The macro allows for optional prefix and suffix to be added to the names.
**               It also provides a message box to display the number of elements renamed.
**
**---------------------------------------------------------------------
**   Update/Modification
**
**   (C) Copyright 2025. All Rights Reserved.
**---------------------------------------------------------------------
*/

#define DEBUG_FILE      0
#define ECHO_DEBUG_FILE 0 
#define ECHO_LINE_NO    0

#define BUILD "15.0.001"

// ----------------------------- INCLUDES -----------------------------
#include "..\\..\\include\\standard_library.H"
#include "..\\..\\include\\size_of.H"
/*global variables*/{


}

// Function prototype
void mainPanel();

void mainPanel(){
    
    Text panelName = "Rename Super Strings";
    Panel panel = Create_panel(panelName, TRUE);
    Vertical_Group vgroup = Create_vertical_group(-1);
    Colour_Message_Box cmbMsg = Create_colour_message_box("");

    ///////////////////CREATE INPUT WIDGETS////////////////
    Source_Box sb_source = Create_source_box("Super Strings", cmbMsg, 0);
    Input_Box ipb_prefix = Create_input_box("Prefix", cmbMsg);
    Input_Box ipb_suffix = Create_input_box("Suffix", cmbMsg);
    Integer_Box ib_start = Create_integer_box("Starting Number", cmbMsg);
    Integer_Box ib_increment = Create_integer_box("Increment", cmbMsg);
    
    // Set default values
    Set_data(ipb_prefix, "");
    Set_data(ipb_suffix, "");
    Set_data(ib_start, 1);
    Set_data(ib_increment, 1);
    
    ///////////////ADDING BUTTONS ALONG THE BOTTOM///////////////////////////
    Horizontal_Group bgroup = Create_button_group();
    Button process = Create_button("&Process", "process");
    Button finish = Create_finish_button("Finish", "Finish");
    Button help_button = Create_help_button(panel, "Help");
    
    Append(process, bgroup);
    Append(finish, bgroup);
    Append(help_button, bgroup);
    
    ///////////////ADDING WIDGETS TO PANEL///////////////////////////
    Append(sb_source, vgroup);
    Append(ipb_prefix, vgroup);
    Append(ipb_suffix, vgroup);
    Append(ib_start, vgroup);
    Append(ib_increment, vgroup);
    Append(cmbMsg, vgroup);
    Append(bgroup, vgroup);

    Append(vgroup, panel);
    Show_widget(panel);
    
    Integer doit = 1;
    while(doit)
    {
        Text cmd = "", msg = "";
        Integer id, ret = Wait_on_widgets(id, cmd, msg);

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
                if(cmd == "Panel Quit") doit = 0;
            }
            break;
            
            case Get_id(process):
            {
                if(cmd == "process")
                {
                    // Validate source box
                    Dynamic_Element de_source;
                    if(Validate(sb_source, de_source) == FALSE)
                    {
                        Set_error_message(sb_source, "");
                        break;
                    }
                    
                    Integer source_count = 0;
                    Get_number_of_items(de_source, source_count);
                    if(source_count <= 0)
                    {
                        Set_error_message(sb_source, "No super strings selected");
                        break;
                    }

                    // Get input widget values (optional fields)
                    Text prefix_text = "";
                    Get_data(ipb_prefix, prefix_text);
                    
                    Text suffix_text = "";
                    Get_data(ipb_suffix, suffix_text);
                    
                    Integer start_num = 1;
                    if(Validate(ib_start, start_num) == FALSE) break;
                    
                    Integer increment_num = 1;
                    if(Validate(ib_increment, increment_num) == FALSE) break;
                    
                    // Validate increment is positive
                    if(increment_num <= 0)
                    {
                        Set_error_message(ib_increment, "Increment must be positive");
                        break;
                    }

                    // Process the renaming
                    Integer current_number = start_num;
                    Integer processed = 0;
                    
                    for(Integer i = 1; i <= source_count; i++)
                    {
                        Element element;
                        if(Get_item(de_source, i, element) == 0)
                        {
                            // Check if it's a super string
                            Text element_type = "";
                            Get_type(element, element_type);
                            
                            if(element_type == "Super")
                            {
                                // Convert number to text and create new name
                                Text number_text = To_text(current_number);
                                Text new_name = prefix_text + number_text + suffix_text;
                                
                                // Rename the element
                                if(Set_name(element, new_name) == 0)
                                {
                                    current_number += increment_num;
                                    processed++;
                                }
                            }
                        }
                    }
                    
                    Text result_msg = "Process completed. Renamed " + To_text(processed) + " super strings.";
                    Set_data(cmbMsg, result_msg);
                }
            }
            break;
            
            default:
            {
                if(cmd == "Finish") doit = 0;
            }
            break;
        }
    }
}

void main(){
    // Check if we have a valid project
    Text project_name = "";
    Get_project_name(project_name);
    
    if(project_name == "")
    {
        Print("Error: No project is open.\n");
        return;
    }
    
    Print("Super String Rename Macro - Build " + BUILD + "\n");
    mainPanel();
    Print("Macro finished\n");
}