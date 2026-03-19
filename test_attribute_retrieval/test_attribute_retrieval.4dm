/*---------------------------------------------------------------------
**   Programmer: Test
**   12D Model: V15
**   Macro Name: Test_Design_String_UID_Resolution.4dm
**
**   Purpose:
**   Test retrieval of "design model id" and "design string id"
**   from drainage pits and resolve setout string via UID lookup.
**---------------------------------------------------------------------*/

#define DEBUG_FILE      0
#define ECHO_DEBUG_FILE 0
#define ECHO_LINE_NO    0

#include "..\\..\\include/standard_library.H"
#include "..\\..\\include/size_of.H"

void mainPanel()
{
    Panel panel = Create_panel("Test Design String UID Resolution", TRUE);
    Vertical_Group vgroup = Create_vertical_group(-1);
    Colour_Message_Box cmbMsg = Create_colour_message_box("");

    // --- Selection ---
    New_Select_Box nsb =
        Create_new_select_box("Select Drainage String",
                              "Pick drainage string",
                              SELECT_STRING,
                              cmbMsg);

    // --- Buttons ---
    Horizontal_Group bgroup = Create_button_group();
    Button process = Create_button("&Process", "process");
    Button finish  = Create_finish_button("Finish", "Finish");

    Append(process, bgroup);
    Append(finish , bgroup);

    Append(nsb, vgroup);
    Append(cmbMsg, vgroup);
    Append(bgroup, vgroup);
    Append(vgroup, panel);

    Show_widget(panel);

    Integer doit = 1;

    while(doit)
    {
        Text cmd="", msg="";
        Integer id, ret = Wait_on_widgets(id, cmd, msg);

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
                Element drain;

                Integer rc = Validate(nsb, drain);

                if(rc != 1)
                {
                    Set_data(cmbMsg, "Select a drainage string");
                    break;
                }

                Text type="";
                Get_type(drain, type);

                if(type != "Drainage")
                {
                    Set_data(cmbMsg, "Selected element is not Drainage");
                    break;
                }

                Integer n_pits = 0;
                Get_drainage_pits(drain, n_pits);

                Print("Drainage string contains "
                      + To_text(n_pits) + " pits\n\n");

                for(Integer pit = 1; pit <= n_pits; pit++)
                {
                    Text pit_name="";
                    Get_drainage_pit_name(drain, pit, pit_name);

                    Text pit_type="";
                    Get_drainage_pit_type(drain, pit, pit_type);

                    Uid dm_uid;
                    Uid ds_uid;

                    Integer rc_dm =
                        Get_drainage_pit_attribute(
                            drain, pit,
                            "design model id",
                            dm_uid);

                    Integer rc_ds =
                        Get_drainage_pit_attribute(
                            drain, pit,
                            "design string id",
                            ds_uid);

                    Text dm_uid_txt="";
                    Text ds_uid_txt="";

                    if(rc_dm == 0)
                        Convert_uid(dm_uid, dm_uid_txt);

                    if(rc_ds == 0)
                        Convert_uid(ds_uid, ds_uid_txt);

                    Print("Pit #" + To_text(pit) + "\n");
                    Print("  Name = " + pit_name + "\n");
                    Print("  Type = " + pit_type + "\n");
                    Print("  design model uid  rc="
                          + To_text(rc_dm)
                          + " val=\"" + dm_uid_txt + "\"\n");
                    Print("  design string uid rc="
                          + To_text(rc_ds)
                          + " val=\"" + ds_uid_txt + "\"\n");

                    // ---- Verify model UID ----
                    if(rc_dm == 0)
                    {
                        Model design_model;
                        Integer rc_model =
                            Get_model(dm_uid, design_model);

                        Print("  Get_model rc = "
                              + To_text(rc_model) + "\n");

                        if(rc_model == 0)
                        {
                            Text model_name="";
                            Get_name(design_model, model_name);

                            Print("  Model name = "
                                  + model_name + "\n");

                            // ---- Resolve element using 5-parameter overload ----
                            if(rc_ds == 0)
                            {
                                Element setout;

                                Integer rc_elem =
                                    Get_element(
                                        model_name,
                                        dm_uid,
                                        "",
                                        ds_uid,
                                        setout);

                                Print("  Get_element rc = "
                                      + To_text(rc_elem) + "\n");

                                if(rc_elem == 0)
                                {
                                    Text so_name="";
                                    Get_name(setout, so_name);
                                    Print("  Resolved setout string name = " + so_name + "\n");

                                    Uid resolved_uid;
                                    Integer rc_uid = Get_id(setout, resolved_uid);     // ID = 1908

                                    Text resolved_uid_txt="";
                                    if(rc_uid == 0) Convert_uid(resolved_uid, resolved_uid_txt);

                                    Print("  Get_id rc = " + To_text(rc_uid) + "\n");
                                    Print("  Resolved element UID = " + resolved_uid_txt + "\n");
                                    Print("  Original design string UID = " + ds_uid_txt + "\n");


                                }
Uid actual_uid;
Integer rc_uid = Get_id(drain, actual_uid);

Text actual_uid_txt="";
Convert_uid(actual_uid, actual_uid_txt);

Print("Drainage string actual UID = " + actual_uid_txt + "\n");

                            }
                        }
                    }

                    Print("\n");
                }

                Set_data(cmbMsg,
                         "Done. Check Output Window.");
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

void main()
{
    mainPanel();
}
