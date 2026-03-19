/*---------------------------------------------------------------------
**   Programmer: 12d Model Macro Assistant
**   Date: 07/09/25
**   12D Model:            V15
**   Version:              001
**   Macro Name:           drainage_flow_direction.4dm
**   Type:                 SOURCE
**
**   Brief description: Reports drainage string flow direction
**
**---------------------------------------------------------------------
**   Description:
**   Asks user to pick a drainage string, validates, then reports the
**   flow direction to the output window.
**   Flow direction: 1 = same as string chainage; 0 = opposite.
**
**---------------------------------------------------------------------
**   References (manual sections)
**   - Output window Print() — §5.17.1 【19†12d_Model_PL_Manual.txt†L172-L176】
**   - Panels: Input widgets (New_Select_Box, Wait_on_widgets, etc.) — §5.61.10 【19†12d_Model_PL_Manual.txt†L967-L973】
**   - Selecting strings: Validate(...) — §5.55.1 【19†12d_Model_PL_Manual.txt†L887-L893】
**   - Drainage String → General functions (flow) — §5.45.2 【19†12d_Model_PL_Manual.txt†L651-L657】
**   - Models: Get_model(...) — §5.34 (ID=540) 【19†12d_Model_PL_Manual.txt†L306-L326】
**---------------------------------------------------------------------*/

// ----------------------------- MAIN -----------------------------
#include "..\\..\\include\standard_library.h"
#include "..\\..\\include\set_ups.h"          // Appendix A Set_ups.h

void main()
{
    // Panel and widgets
    Panel        panel = Create_panel("Drainage Flow Direction",TRUE);            // §5.61
    Message_Box  msg   = Create_message_box("");                                   // §5.61.10
    New_Select_Box pick = Create_new_select_box("Select drainage string",
                                               "Pick a drainage string",
                                               SELECT_STRING,                      // Appendix A Set_ups.h
                                               msg);
    Button finish = Create_finish_button("Finish", "finish");
    Vertical_Group v = Create_vertical_group(-1);
    Horizontal_Group hb = Create_button_group();
    Append(pick, v);
    Append(msg,  v);
    Append(finish, hb);
    Append(hb, v);
    Append(v, panel);
    Show_widget(panel);

    Clear_console();
    Print("Drainage Flow Direction Reporter\n");                                      // §5.17.1

    Integer running = 1;
    while(running)
    {
        Integer id; Text cmd, s; Integer ret = Wait_on_widgets(id, cmd, s);        // §5.61

        switch(id)
        {
        case Get_id(panel):
        {
            if(cmd == "Panel Quit") running = 0;                                   // close
        }
        break;

        case Get_id(finish):
        {
            if(cmd == "finish") running = 0;
        }
        break;

        case Get_id(pick):
        {
            if(cmd != "accept select") break;

            Element drain;
            Integer ok = Validate(pick, drain);                                     // §5.55.1
            if(ok != TRUE)
            {
                Set_data(msg, "Invalid pick");
                break;
            }

            // Optional: context info for citation ID=540
            Model m; Text mname=""; Text ename="";
            if(Get_model(drain, m) == 0)                                           // §5.34 (ID=540)
            {
                Get_name(m, mname);
                Get_name(drain, ename);
            }

            Integer dir = -1;
            Integer rc = Get_drainage_flow(drain, dir);                             // §5.45.2 (General Drainage String Functions)
            if(rc != 0)
            {
                Set_data(msg, "Not a drainage string or cannot read flow");
                Print("Could not obtain drainage flow for selected element\n");
                break;
            }

            Text hdr = "Flow direction = " + To_text(dir) + "  (1=same, 0=opposite)";
            Set_data(msg, hdr);

            if(mname != "" || ename != "")
            {
                Print("Model: <"+mname+">  Element: <"+ename+">\n");
            }
            Print(hdr + "\n");                                                     // §5.17.1
        }
        break;
        }
    }
}
