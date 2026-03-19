/*---------------------------------------------------------------------
**   Programmer: KLP
**   Date: <Date>
**   12D Model:            V15
**   Version:              001
**   Macro Name:           Bulk_Add_mtfsnippet_to_MTF.4dm
**   Type:                 SOURCE
**
**   Brief description:
**   Bulk inserts SEMI_RECESSED_KERB.mtfsnippet entries into .mtf files
**   for selected semi-recessed drainage pits (CP and DCP).
**
**---------------------------------------------------------------------
**   Description:
**
**   This panel macro performs controlled bulk modification of .mtf files.
**
**   Workflow:
**
**   1. User selects:
**        • Drainage strings containing cesspit pits.
**
**   2. For each drainage string:
**        • Retrieves pit name, pit id and pit type.
**        • Processes only:
**              - "CP (SEMI-RECESSED)"
**              - "DCP (SEMI-RECESSED)"
**
**   3. Resolves associated design setout string via:
**        • "design model id"
**        • "design string id"
**
**   4. Determines modifier side from setout string name:
**        • "KIL" → Left side modifier
**        • "KIR" → Right side modifier
**
**   5. Determines snippet parameters:
**        • CP_TYPE:
**              CP  → "Single"
**              DCP → "Double"
**        • KINV  → Setout string name (e.g. KIL / KIR)
**        • ADJ   → FPL (Left) / FPR (Right)
**
**   6. Opens referenced .mtf file defined by:
**        • apply_mtf_details/mtf_file_name
**
**   7. Within the correct side modifier block:
**        • Tracks brace depth to determine true block extent.
**        • Creates region "CESSPITS" if not present.
**        • Inserts snippet inside CESSPITS region.
**        • Prevents duplicate insertion (drainage_ref match).
**
**   8. Writes updated file safely.
**
**   Reporting:
**        • Per-pit status printed:
**              UPDATED (mtf_file)
**              SKIPPED (reason)
**        • Bulk summary reports:
**              Total eligible pits
**              Updated
**              Duplicates skipped
**              No KI found
**---------------------------------------------------------------------
**
**  This macro may be reproduced, modified and used without restriction.
**  The author grants all users Unlimited Use of the source code and any 
**  associated files, for no fee. Unlimited Use includes compiling, running,
**  and modifying the code for individual or integrated purposes.
**  The author also grants 12d Solutions Pty Ltd and other users permission
**  to incorporate this macro, in whole or in part, into other macros or programs.
**
**---------------------------------------------------------------------*/

#define DEBUG_FILE      0
#define ECHO_DEBUG_FILE 0
#define ECHO_LINE_NO    0
#define BUILD "15.0.001"

#include "..\\..\\include/standard_library.H"
#include "..\\..\\include/size_of.H"

// ------------------------------------------------------------
// LOG HELPERS
// ------------------------------------------------------------

void log_ok(Log_Box lb, Text msg)
{
  Log_Line ln = Create_text_log_line(msg, 1);
  Add_log_line(lb, ln);
}

void log_warn(Log_Box lb, Text msg)
{
  Log_Line ln = Create_text_log_line(msg, 2);
  Add_log_line(lb, ln);
}

void log_err(Log_Box lb, Text msg)
{
  Log_Line ln = Create_text_log_line(msg, 3);
  Add_log_line(lb, ln);
  Print_log_line(ln, 1); // flash Output Window
}

void log_highlight(Log_Box lb, Text msg, Integer level, Element el)
{
    Uid mid, eid;
    Model mx;

    Get_model(el, mx);
    Get_id(mx, mid);
    Get_id(el, eid);
    Null(mx);

    Log_Line ln = Create_highlight_string_log_line(msg, level, mid, eid);
    Add_log_line(lb, ln);
}

// ------------------------------------------------------------
// MAIN PANEL
// ------------------------------------------------------------
void mainPanel()
{
    Text panelName="Bulk MTF Snippet at Pit Panel";
    Panel panel  = Create_panel(panelName,TRUE);
    Vertical_Group vgroup = Create_vertical_group(-1);
    Colour_Message_Box cmbMsg = Create_colour_message_box("");
    // Log box (name, width, height)
    Log_Box lb = Create_log_box("Report", 90, 14);
    
    Source_Box sb_drain = Create_source_box("Drainage strings (cesspits)",cmbMsg,0);

    Horizontal_Group bgroup = Create_button_group();
    Button process = Create_button("&Process","process");
    Button finish  = Create_finish_button("Finish","Finish");
    Button help_button = Create_help_button(panel,"Help");
    Button info_button = Create_button("Info","Info");

    Append(process,bgroup);
    Append(finish,bgroup);
    Append(help_button,bgroup);
    Append(info_button,bgroup);

    Append(sb_drain,vgroup);
    Append(lb, vgroup);
    Append(cmbMsg,vgroup);
    Append(bgroup,vgroup);

    Append(vgroup,panel);
    Show_widget(panel);
    Show_widget(panel);

    Clear(lb);

    // Reminder first
    Add_log_line(lb,
        Create_text_log_line(
            "Reminder: Run 'Set Pit Details' before executing this macro.",
            2
        )
    );

    // Check required snippet file exists
    Text project_path = Get_absolute_path("");
    Text snippet_path = project_path + "SEMI_RECESSED_KERB.mtfsnippet";

    if(File_exists(snippet_path) == 0)
    {
        Log_Line err = Create_text_log_line(
            "ERROR: Required file SEMI_RECESSED_KERB.mtfsnippet not found in project folder.",
            3
        );
        Add_log_line(lb, err);
        Print_log_line(err,1);   // flash Output Window
    }
    else
    {
        Add_log_line(lb,
            Create_text_log_line(
                "Dependency check OK: SEMI_RECESSED_KERB.mtfsnippet found.",
                1
            )
        );
    }

    Integer doit = 1;
    while(doit)
    {
        Text cmd="",msg = "";
        Integer id,ret = Wait_on_widgets(id,cmd,msg);

        if(id == Get_id(info_button) && cmd == "Info")
        {
            Clear(lb);

            Add_log_line(lb, Create_text_log_line("Bulk Add mtfsnippet to MTF", 1));
            Add_log_line(lb, Create_text_log_line(" ", 0));

            Add_log_line(lb, Create_text_log_line("Purpose:", 1));
            Add_log_line(lb, Create_text_log_line("  Insert SEMI_RECESSED_KERB.mtfsnippet into MTF file.", 1));

            Add_log_line(lb, Create_text_log_line("Required:", 1));
            Add_log_line(lb, Create_text_log_line("  Project folder must contain:", 1));
            Add_log_line(lb, Create_text_log_line("  SEMI_RECESSED_KERB.mtfsnippet", 1));

            Add_log_line(lb, Create_text_log_line("Supports:", 1));
            Add_log_line(lb, Create_text_log_line("  Single or Double cesspit types.", 1));

            // Highlight warning line
            Log_Line warn = Create_text_log_line("WARNING: No undo provided.", 2);
            Add_log_line(lb, warn);
        }
 
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
                Clear(lb);   // clear previous run
                log_ok(lb, "=== Bulk Add mtfsnippet to MTF file macro ===");
                

                Integer total_processed=0;
                Integer total_updated=0;
                Integer total_duplicate=0;
                Integer total_no_ki=0;

                Dynamic_Element drains;
                Integer rc_drain=Validate(sb_drain,drains);
                if(rc_drain<=0) 
                {
                    Add_log_line(lb,
                        Create_text_log_line("Invalid selection. Please select drainage strings.", 2) );
                    break;
                }

                Integer ndr=0;
                Get_number_of_items(drains,ndr);
                if(ndr==0)
                {
                    Add_log_line(lb, Create_text_log_line("No drainage strings selected.", 2));
                    break;
                }
                Integer found_drainage = 0;

                for(Integer i=1;i<=ndr;i++)
                {
                    Element drain;
                    if(Get_item(drains,i,drain)!=0) continue;

                    Text et="";
                    Get_type(drain,et);
                    if(et!="Drainage") continue;
                    found_drainage = 1;

                    Integer n_pits=0;
                    Get_drainage_pits(drain,n_pits);

                    for(Integer pit=1;pit<=n_pits;pit++)
                    {
                        Text pit_type="";
                        Get_drainage_pit_type(drain,pit,pit_type);

                        Text cp_type_value="";
                        if(pit_type=="CP (SEMI-RECESSED)") cp_type_value="Single";
                        else if(pit_type=="DCP (SEMI-RECESSED)") cp_type_value="Double";
                        else continue;

                        total_processed++;

                        Text pit_name="";
                        Get_drainage_pit_name(drain,pit,pit_name);
                        log_highlight(lb, "Pit: " + pit_name, 1, drain);

                        Integer pit_id=0;
                        Get_drainage_pit_attribute_by_type(drain,pit,"pit id",pit_id);

                        Uid dm_uid, ds_uid;

                        if(Get_drainage_pit_attribute(drain,pit,"design model id",dm_uid)!=0 ||
                        Get_drainage_pit_attribute(drain,pit,"design string id",ds_uid)!=0)
                        {
                            // highlight drainage string element
                            Uid model_uid, element_uid;
                            Model mx;

                            Get_model(drain, mx);
                            Get_id(mx, model_uid);
                            Get_id(drain, element_uid);
                            Null(mx);

                            Log_Line hl = Create_highlight_string_log_line(
                                "SKIPPED Pit <" + pit_name + "> (No setout link found)",
                                2,
                                model_uid,
                                element_uid
                            );

                            Add_log_line(lb, hl);
                            total_no_ki++;
                            continue;
                      }

                        // --- Get design setout string ---
                        Model design_model;
                        if(Get_model(dm_uid,design_model)!=0)
                        {
                            total_no_ki++;
                            continue;
                        }

                        Text design_model_name="";
                        Get_name(design_model,design_model_name);

                        Element setout;
                        if(Get_element(design_model_name,dm_uid,"",ds_uid,setout)!=0)
                        {
                            total_no_ki++;
                            continue;
                        }

                        // --- Get MTF file ---
                        Text mtf_file="";
                        Get_attribute(setout,
                                      "apply_mtf_details/mtf_file_name",
                                      mtf_file);

                        if(mtf_file=="") continue;

                        // --- Determine side from setout name ---
                        Text so_name="";
                        Get_name(setout,so_name);

                        Integer len=Text_length(so_name);
                        if(len<=0) continue;


                        // --- Determine side from setout string name (KIL/KIR) ---
                        Text adj = "";
                        Text side_modifier = "";
                        Text pavements_region = "";

                        if(Find_text(so_name, "KIL") == 1)
                        {
                            adj = "FPL";
                            side_modifier = "left_side_modifier = {";
                            pavements_region = "LHS PAVEMENTS";
                        }
                        else if(Find_text(so_name, "KIR") == 1)
                        {
                            adj = "FPR";
                            side_modifier = "right_side_modifier = {";
                            pavements_region = "RHS PAVEMENTS";
                        }
                        else
                        {
                            Set_data(cmbMsg, "Setout string not recognised (expect KIL/KIR) for pit " + pit_name);
                            continue;
                        }

                        // --- Build snippet ---
                        Text model_name="";
                        Model mdl;
                        Get_model(drain,mdl);
                        Get_name(mdl,model_name);

                        Text drainage_ref=
                            model_name+"->"+pit_name+";"+To_text(pit_id);

                        Text kinv_text="";
                        Convert_uid(ds_uid,kinv_text);

                        Text snippet_line=
                            "  snippet \"SEMI_RECESSED_KERB.mtfsnippet\" drainage_ref \""+
                            drainage_ref+
                            "\" 0 $null \"CP_TYPE\" \""+
                            cp_type_value+
                            "\" \"KINV\" \""+
                            so_name+
                            "\" \"ADJ\" \""+
                            adj+
                            "\" extra_start extra_end ";

                        // --- File handling ---
                        Text mtf_full_path=project_path+mtf_file;

                        if(File_exists(mtf_full_path)==0)
                        {
                            log_highlight(
                                lb,
                                "SKIPPED Pit <" + pit_name +
                                "> — MTF file not found (" + mtf_file + ")",
                                2,
                                drain
                            );
                            continue;
                        }

                        File f;
                        Text lines[20000];
                        Integer n=0;
                        Text line="";

                        if(File_open(mtf_full_path,"r",f)!=0) continue;
                        while(File_read_line(f,line)==0) lines[++n]=line;
                        File_close(f);

                        Integer already_exists=0;
                        for(Integer i_chk=1;i_chk<=n;i_chk++)
                        {
                            if(Find_text(lines[i_chk],
                                "drainage_ref \""+drainage_ref+"\"")>0)
                            {
                                already_exists=1;
                                break;
                            }
                        }

                        if(already_exists)
                        {
                            log_highlight(lb,"SKIPPED Pit <" + pit_name + "> (Duplicate)", 2, drain);
                            total_duplicate++;
                            continue;
                        }

                        // =============================================================
                        // DEBUG: MTF INSERTION LOGIC
                        // =============================================================

                        // Print("---- MTF DEBUG START ----\n");
                        // Print("MTF file: " + mtf_full_path + "\n");
                        // Print("Side modifier token: [" + side_modifier + "]\n");
                        // Print("Pavement region token: [" + pavements_region + "]\n");

                        Integer insert_index = 0;
                        Integer modifier_start = 0;
                        Integer modifier_end = 0;
                        Integer brace_depth = 0;

                        // -------------------------------------------------
                        // Find modifier start
                        // -------------------------------------------------

                        for(Integer line1=1; line1<=n; line1++)
                        {
                            if(Find_text(lines[line1], side_modifier) > 0)
                            {
                                modifier_start = line1;
                                // Print("Modifier start found at line " + To_text(line1) + "\n");
                                brace_depth = 1;
                                break;
                            }
                        }

                        if(modifier_start == 0)
                        {
                            log_highlight(lb,"SKIPPED Pit <" + pit_name +"> — Modifier block not found (" + mtf_file + ")", 2, drain);
                            continue;
                        }

                        // -------------------------------------------------
                        // Find modifier end using brace depth
                        // -------------------------------------------------

                        for(Integer line2=modifier_start+1; line2<=n; line2++)
                        {
                            if(Find_text(lines[line2], "{") > 0)
                                brace_depth++;

                            if(Find_text(lines[line2], "}") > 0)
                                brace_depth--;

                            if(brace_depth == 0)
                            {
                                modifier_end = line2;
                                // Print("Modifier end found at line " + To_text(line2) + "\n");
                                break;
                            }
                        }

                        if(modifier_end == 0)
                        {
                            // Print("Modifier end NOT found.\n");
                            continue;
                        }

                        // -------------------------------------------------
                        // Search for pavement region inside modifier block
                        // -------------------------------------------------

                        for(Integer line3=modifier_start; line3<=modifier_end; line3++)
                        {
                            if(Find_text(lines[line3], pavements_region) > 0)
                            {
                                insert_index = line3;
                                // Print("Pavement region found at line " + To_text(line3) + "\n");
                                break;
                            }
                        }

                        // -------------------------------------------------
                        // If not found, insert before closing brace
                        // -------------------------------------------------

                        if(insert_index == 0)
                        {
                            insert_index = modifier_end;

                            log_highlight(lb,"INFO Pit <" + pit_name + "> — Pavement region not found; inserting near end of modifier block (line " + To_text(insert_index) + ")", 2, drain);
                        }

                        // Print("Final insert index = " + To_text(insert_index) + "\n");

                        // -------------------------------------------------
                        // Ensure CESSPITS region exists
                        // -------------------------------------------------

                        Integer cesspits_found = 0;
                        Integer cesspits_line = 0;

                        for(Integer idx=modifier_start; idx<=modifier_end; idx++)
                        {
                            if(Find_text(lines[idx], "region \"CESSPITS\"") > 0)
                            {
                                cesspits_found = 1;
                                cesspits_line = idx;
                                break;
                            }
                        }

                        // -------------------------------------------------
                        // If CESSPITS exists → insert after it
                        // -------------------------------------------------

                        if(cesspits_found == 1)
                        {
                            insert_index = cesspits_line + 1;
                            // Print("CESSPITS region found at line " + To_text(cesspits_line) + "\n");
                        }
                        else
                        {
                            log_warn(lb, "INFO: CESSPITS region not found. Creating new region (" + mtf_file + ")");

                            // Make space for 2 lines (region + snippet)
                            for(Integer ins2=n; ins2>=insert_index; ins2--)
                            {
                                lines[ins2+2] = lines[ins2];
                            }

                            lines[insert_index]   = "  region \"CESSPITS\" \"CESSPITS\" 1";
                            lines[insert_index+1] = snippet_line;

                            n += 2;
                            insert_index = -1;   // prevent double insert
                        }

                        // -------------------------------------------------
                        // If region existed, insert snippet normally
                        // -------------------------------------------------

                        if(insert_index > 0)
                        {
                            for(Integer ins=n; ins>=insert_index; ins--)
                            {
                                lines[ins+1] = lines[ins];
                            }

                            lines[insert_index] = snippet_line;
                            n++;
                        }

                        // -------------------------------------------------
                        // Write file
                        // -------------------------------------------------

                        if(File_open(mtf_full_path,"w",f)!=0)
                        {
                            log_err(lb, "ERROR: Failed to open file for writing.\n");
                            continue;
                        }

                        for(Integer k=1;k<=n;k++)
                            File_write_line(f,lines[k]);

                        File_close(f);

                        // Print("File written successfully.\n");
                        // Print("---- MTF DEBUG END ----\n");

                        log_ok(lb, "UPDATED (" + mtf_file + ")");
                        total_updated++;
                    }
                }

                if(found_drainage == 0)
                {
                    Add_log_line(lb,
                        Create_text_log_line("No drainage strings found in selection.", 2)
                    );
                    break;
                }

                log_ok(lb,"\n===== BULK SUMMARY =====\n");
                log_ok(lb,"Total eligible pits : "+To_text(total_processed)+"\n");
                log_ok(lb,"Updated             : "+To_text(total_updated)+"\n");
                log_ok(lb,"Duplicates skipped  : "+To_text(total_duplicate)+"\n");
                log_ok(lb,"No KI found         : "+To_text(total_no_ki)+"\n");
                log_ok(lb,"========================\n");

                log_ok(lb, "Process finished");
                Set_data(cmbMsg,
                    "Updated: "+To_text(total_updated)+
                    " | Dup: "+To_text(total_duplicate)+
                    " | No KI: "+To_text(total_no_ki));
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
    mainPanel();
}