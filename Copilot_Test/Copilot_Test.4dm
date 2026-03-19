#define BUILD "version.0.001"

// ----------------------------- INCLUDES -----------------------------
#include "..\\..\\include/standard_library.H"
#include "..\\..\\include/size_of.H"

/* global variables */
{
    Panel panel;
    Message_Box message_box;
    New_Select_Box select_box;
    Button process_btn;
    Button finish_btn;
}

void mainPanel()
{
    // EDITABLE: Define and assemble your panel widgets here
    // 1. Create the Panel and Message Box
    panel = Create_panel("Reverse Drainage String");
    message_box = Create_message_box(""); 

    // 2. Create the New Select Box for string picking
    // mode 1 allows picking an existing string from the project
    select_box = Create_new_select_box("Pick string", "Select Drainage string", 1, message_box);
    

    // 3. Create control buttons
    process_btn = Create_button("Process", "do_reverse");
    finish_btn = Create_button("Finish", "quit_macro");

    // 4. Assemble the panel
    Append(select_box, panel);
    Append(message_box, panel);
    Append(process_btn, panel);
    Append(finish_btn, panel);

    // 5. Display the panel
    Show_widget(panel);

    // 6. The Event Loop
    Integer id;
    Text cmd, msg;
    Integer doit = 1;
    while (doit) {
        // Wait_on_widgets pauses for user interaction
        Wait_on_widgets(id, cmd, msg);

        if (cmd == "do_reverse") {
            Element picked_elt;
            // Validate the widget selection
            if (Validate(select_box, picked_elt) == 1) {
                Text type_name;
                Get_type(picked_elt, type_name); // Get Element type metadata
                
                // Confirm the selection is a "Drainage" string
                if (type_name == "Drainage") {
                    Text name, model_name;
                    Model model_handle;

                    // Get Metadata for the Output Window
                    Get_name(picked_elt, name);
                    Get_model(picked_elt, model_handle);
                    Get_name(model_handle, model_name);

                    Print("Processing: " + name + " (Model: " + model_name + ")\n");

                    // 7. Reverse the string direction
                    // ID 1134 refers to String_reverse in the 12dPL Library
                    Element reversed_elt;
                    String_reverse(picked_elt, reversed_elt);
                    
                    Set_message_text(message_box, "Drainage string reversed successfully.");
                } else {
                    // Manual error feedback if the type is incorrect
                    Set_message_text(message_box, "Error: Selected element must be Drainage.");
                }
            }
        }

        // Handle Finish button or 'X' click
        if (cmd == "quit_macro" || cmd == "Panel Quit") {
            doit = 0;
        }
    }
}

void main()
{
    // EDITABLE: Initial setup and call to mainPanel
    mainPanel();
}
```

### Key Logic Summary
*   **Widget Creation**: `Create_new_select_box` is used with mode `1` to ensure the user picks an existing string from the 12d Model database.
*   **Validation**: The `Validate` call returns `1` (TRUE) if a valid `Element` handle was retrieved, otherwise it automatically posts an error to the linked `message_box`.
*   **Drainage Check**: `Get_type` retrieves the internal type name; the macro only proceeds if the result is `"Drainage"`.
*   **String Reversal**: The library call `String_reverse` (linked to the requested logic) is used to flip the direction of the picked string.
*   **Event Loop**: The `Wait_on_widgets` loop keeps the macro active and responsive to user input until the "Finish" button or the panel 'X' is clicked.