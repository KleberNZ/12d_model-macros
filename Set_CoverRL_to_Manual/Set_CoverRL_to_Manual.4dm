/*---------------------------------------------------------------------
**   Programmer: ChatGPT
**   Date: 08/09/2025             
**   12D Model: V15
**   Version: 001
**   Macro Name: Set_CoverRL_Mode_Manual_ID1961.4dm
**   Type: SOURCE
**
**   Brief description: Select a model via Model_Box, ensure not empty, iterate all drainage strings
**   and set each pit node attribute "cover rl mode" to 2.
**
**---------------------------------------------------------------------
**   Description: 
**   - Presents a panel with a Model_Box and Finish button.
**   - Validates the selected model must exist.
**   - If the model has no elements, informs the user and exits.
**   - Walks all elements of the model. For each Element of type "Drainage":
**       • Get number of pits
**       • For p = 1..npits: Set_drainage_pit_attribute(…, "cover rl mode", 2)
**   - Reports counts to the Output Window.
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
*/


#define DEBUG_FILE       0
#define ECHO_DEBUG_FILE  0
#define ECHO_LINE_NO     0
#define BUILD            "version.0.001"

// ---------------------------- INCLUDES ----------------------------
#include "..\\..\\include/standard_library.H"
#include "..\\..\\include/size_of.H"
#include "..\\..\\include/set_ups.h"     // Model_Box modes (e.g. CHECK_MODEL_MUST_EXIST)

/*global variables*/{
}

// References:
// - Create_model_box, Validate(Model_Box,mode,Model&) — Manual §Panels & Widgets (ID=848)
// - Wait_on_widgets loop pattern — Training Notes §16.6 (example)
// - Get_elements, Get_number_of_items — Models §5.34 (ID=132,452)
// - Get_item(Dynamic_Element,i,Element&) — Index (ID=201)
// - Get_type(Element,Text&) — Elements §5.36 (ID=64)
// - Get_drainage_pits(Element,&npits) — Drainage §5.45.3
// - Set_drainage_pit_attribute(Element,pit,Text,Integer) — Drainage §5.45.5 (ID=1007)

void main()
{
    // ---------------- Panel setup ----------------
    Panel panel = Create_panel("Set Cover RL Mode = 2 (Pits)");
    Message_Box msg_box = Create_message_box("");

    // Model_Box that requires an existing model
    Model_Box model_box = Create_model_box("Model", msg_box, CHECK_MODEL_MUST_EXIST); // ID=848

    Button run_btn    = Create_button("Run",   "run_reply");
    Button finish_btn = Create_finish_button("Finish","finish_reply");

    Vertical_Group vgroup = Create_vertical_group(0);
    Append(model_box, vgroup);
    Append(msg_box,   vgroup);

    Horizontal_Group hgroup = Create_button_group();
    Append(run_btn,    hgroup);
    Append(finish_btn, hgroup);

    Append(vgroup, panel);
    Append(hgroup, panel);

    Show_widget(panel);
    Clear_console();

    Integer doit = 1;

    // Stats
    Integer total_models_processed = 0;
    Integer total_drain_strings    = 0;
    Integer total_pits_updated     = 0;

    while (doit)
    {
        Integer id; Text cmd, msg; 
        Integer ret = Wait_on_widgets(id, cmd, msg);

        switch(id)
        {
            case Get_id(panel):
            {
                if (cmd == "Panel Quit") doit = 0; // user closed the panel
                break;
            }

            case Get_id(finish_btn):
            {
                if (cmd == "finish_reply") doit = 0;
                break;
            }

            case Get_id(run_btn):
            {
                if (cmd != "run_reply") break;

                // Validate Model_Box → Model
                Model model;
                // Using GET_MODEL_MUST_EXIST semantics. Non-zero indicates success state varies by build.
                Integer vrc = Validate(model_box, CHECK_MODEL_MUST_EXIST, model);
                if (vrc == 0 || !Model_exists(model))
                {
                    Set_data(msg_box, "Select a valid model.");
                    break;
                }

                // Check non-empty model
                Integer num_elts = 0;
                if (Get_number_of_items(model, num_elts) != 0)
                {
                    Set_data(msg_box, "Failed to query model.");
                    break;
                }
                if (num_elts <= 0)
                {
                    Set_data(msg_box, "Model is empty. Nothing to do.");
                    break;
                }

                // Walk elements
                Dynamic_Element de; Integer total_no = 0;
                if (Get_elements(model, de, total_no) != 0)
                {
                    Set_data(msg_box, "Failed to get elements.");
                    break;
                }

                Integer drain_count = 0;
                Integer pit_updates = 0;

                Element elt; Text etype;
                for (Integer i = 1; i <= total_no; i++)
                {
                    Get_item(de, i, elt);               // ID=201
                    Get_type(elt, etype);               // ID=64
                    if (etype != "Drainage") continue; // only drainage strings

                    drain_count++;

                    Integer npits = 0;
                    if (Get_drainage_pits(elt, npits) != 0 || npits <= 0) continue;

                    // Set pit attribute "cover rl mode" = 2 for each pit index
                    for (Integer p = 1; p <= npits; p++)
                    {
                        Integer rc = Set_drainage_pit_attribute(elt, p, "cover rl mode", 2); // ID=1007
                        if (rc == 0) pit_updates++;
                    }
                }

                total_models_processed++;
                total_drain_strings += drain_count;
                total_pits_updated  += pit_updates;

                Text out = "Model processed. Drainage strings: " + To_text(drain_count) +
                           ", Pit attributes set: " + To_text(pit_updates);
                Set_data(msg_box, out);
                Print(out + "\n");
                break;
            }
        }
    }

    // Final report
    Print("\nSummary\n");
    Print("Models processed: " + To_text(total_models_processed) + "\n");
    Print("Drainage strings: " + To_text(total_drain_strings) + "\n");
    Print("Pit attributes set: " + To_text(total_pits_updated) + "\n");
}

