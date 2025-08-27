/*---------------------------------------------------------------------
**   Programmer: Kleber lessa
**   Date: 25/08/25             
**   12D Model: V15
**   Version: 001
**   Macro Name: drainage_flow_direction.4dm
**   Type: SOURCE
**
**   Brief description: Reports drainage string flow direction
**
**---------------------------------------------------------------------
**   Description: 
**   Asks user to pick a drainage string, validates it's a drainage type,
**   then reports the flow direction to the output window.
**   Flow direction: 1 = same as string chainage direction
**                  0 = opposite to string chainage direction
**
**---------------------------------------------------------------------
**   Update/Modification
**
**---------------------------------------------------------------------
*/

void usage()
{
    Print("12d macro ... drainage_flow_direction\n\n");
    Print("Usage: Pick a drainage string to report its flow direction\n");
    Print("Flow direction: 1 = same as chainage direction, 0 = opposite\n");
    return;
}

void main()
{
    Print("12d macro \"drainage_flow_direction.4dm\" started\n");
    usage();
    
    // Ask user to pick a string using correct 12D PL function
    Element selected_element;
    Text msg = "Pick drainage string";
    
    // Use Select_string function as per manual section 5.5.5.1
    Integer result = Select_string(msg, selected_element);
    
    if(result != 1)  // 1 means pick was successful
    {
        if(result == -1)
        {
            Print("User cancelled selection ... aborting\n");
        }
        else if(result == 0)
        {
            Print("ERROR: Pick unsuccessful ... aborting\n");
        }
        else if(result == 2)
        {
            Print("ERROR: Cursor pick occurred ... aborting\n");
        }
        else
        {
            Print("ERROR: Unknown selection result ... aborting\n");
        }
        return;
    }
    
    // Check if the selected element is a drainage string
    Text element_type;
    Get_type(selected_element, element_type);
    
    if(element_type != "Drainage")
    {
        Print("ERROR: Selected string is not a drainage type\n");
        Print("Selected string type: \"" + element_type + "\"\n");
        Print("Please select a drainage string ... aborting\n");
        return;
    }
    
    Print("Selected drainage string confirmed\n");
    
    // Get the flow direction
    Integer flow_direction;
    Get_drainage_flow(selected_element, flow_direction);
    
    // Report the flow direction
    Print("Flow Direction Report:\n");
    Print("---------------------\n");
    
    if(flow_direction == 1)
    {
        Print("Flow direction: 1 (same as drainage string chainage direction)\n");
        Print("The flow direction matches the chainage direction of the string\n");
    }
    else if(flow_direction == 0)
    {
        Print("Flow direction: 0 (opposite to drainage string chainage direction)\n");
        Print("The flow direction is opposite to the chainage direction of the string\n");
    }
    else
    {
        Print("Unexpected flow direction value: " + To_text(flow_direction) + "\n");
    }
    
    Print("12d macro \"drainage_flow_direction.4dm\" finished\n");
    return;
}