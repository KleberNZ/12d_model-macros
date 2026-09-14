/*---------------------------------------------------------------------
**   Programmer:           KLP
**   Date:                 2026-09-02
**   12D Model:            V15
**   Version:              001
**   Macro Name:           Retaining_Wall_Schedule_panel.4dm
**   Type:                 SOURCE
**
**   Brief description: BriefDescription
**       Pairs retaining-wall TOP and BOTTOM Super Alignments, samples
**       wall height at 0.1 m intervals and exports scheduled lengths
**       grouped into hard-coded 1 m height bands.
**---------------------------------------------------------------------
**   Description: Description
**
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
#include "standard_library.h"
#include "size_of.h"

/*global variables*/{


}
Integer Extract_prefix_from_name(Text name_in,Text suffix_in,Text &prefix)
{
    Text name   = name_in;
    Text suffix = suffix_in;

    Integer len_name = Text_length(name);
    while(len_name > 0)
    {
        Text c = Get_subtext(name,len_name,len_name);
        if(c != " ") break;
        name = Get_subtext(name,1,len_name-1);
        len_name = Text_length(name);
    }

    Integer len_suf = Text_length(suffix);
    while(len_suf > 0)
    {
        Text c2 = Get_subtext(suffix,len_suf,len_suf);
        if(c2 != " ") break;
        suffix = Get_subtext(suffix,1,len_suf-1);
        len_suf = Text_length(suffix);
    }

    prefix = "";
    if(len_suf <= 0) return 0;
    if(len_name <= len_suf) return 0;

    Text tail = Get_subtext(name,len_name-len_suf+1,len_name);
    if(tail != suffix) return 0;

    prefix = Get_subtext(name,1,len_name-len_suf);

    Integer lp = Text_length(prefix);
    if(lp > 0)
    {
        Text last_char = Get_subtext(prefix,lp,lp);
        if(last_char == " ") prefix = Get_subtext(prefix,1,lp-1);
    }
    return 1;
}

Integer Height_band_index(Real height)
{
    if(height <= 1.0)  return 1;
    if(height <= 2.0)  return 2;
    if(height <= 3.0)  return 3;
    if(height <= 4.0)  return 4;
    if(height <= 5.0)  return 5;
    if(height <= 6.0)  return 6;
    if(height <= 7.0)  return 7;
    if(height <= 8.0)  return 8;
    if(height <= 9.0)  return 9;
    if(height <= 10.0) return 10;
    return 11;
}

// ----------------------------- PANEL -----------------------------
void mainPanel(){

    Text panelName="Retaining Wall Schedule To CSV";
    Panel              panel  = Create_panel              (panelName,TRUE);
    Vertical_Group     vgroup = Create_vertical_group     (-1         );
    Colour_Message_Box cmbMsg = Create_colour_message_box (""         );

    ///////////////////CREATE INPUT WIDGETS////////////////
    //TODO: create some input fields
    Source_Box sb_source = Create_source_box("Retaining wall Super Alignments",cmbMsg,Source_Box_Standard);

    Input_Box ipb_top_suffix = Create_input_box("Top suffix",cmbMsg);
    Set_default_data(ipb_top_suffix,"TOP");

    Input_Box ipb_bottom_suffix = Create_input_box("Bottom suffix",cmbMsg);
    Set_default_data(ipb_bottom_suffix,"BOTTOM");

    File_Box fb_csv = Create_file_box("CSV output file",cmbMsg,CHECK_FILE,"*.csv");
    Choice_Box cb_delimiter =  Create_choice_box("Delimiter",cmbMsg);

    Text delimiter_choices[3];
    delimiter_choices[1] = "Comma (,)";
    delimiter_choices[2] = "Semicolon (;)";
    delimiter_choices[3] = "Tab";

    Set_data(cb_delimiter,3,delimiter_choices);
    Set_data(cb_delimiter,"Tab");

    ///////////////ADDING BUTTONS ALONG THE BOTTOM///////////////////////////
    Horizontal_Group bgroup = Create_button_group();
    Button process     = Create_button       ("&Process" ,"process");
    Button finish      = Create_finish_button("Finish"   ,"Finish" );
    Button help_button = Create_help_button  (panel      ,"Help"   );

    Append(process     ,bgroup);
    Append(finish      ,bgroup);
    Append(help_button ,bgroup);

    ///////////////ADDING WIDGETS TO PANEL///////////////////////////
    //TODO: add your widgets to vgroup

    Append(sb_source,vgroup);
    Append(ipb_top_suffix,vgroup);
    Append(ipb_bottom_suffix,vgroup);
    Append(fb_csv,vgroup);
    Append(cb_delimiter,vgroup);

    Append(cmbMsg      ,vgroup);
    Append(bgroup      ,vgroup);

    Append(vgroup,panel);
    Show_widget(panel);

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
                Dynamic_Element sa_elements;
                Text top_suffix = "";
                Text bottom_suffix = "";
                Text csv_path = "";
                Integer rc = 0;
                Integer ok = 1;
                Text delimiter_choice = "";
                Text delimiter = "\t";

                rc = Validate(sb_source,sa_elements);
                if(rc != 1)
                {
                    Set_data(cmbMsg,"Please select retaining wall Super Alignments");
                    ok = 0;
                }
                else
                {
                    Integer selected_count = 0;
                    rc = Get_number_of_items(sa_elements,selected_count);
                    if(rc != 0 || selected_count <= 0)
                    {
                        Set_data(cmbMsg,"No elements found in the source box");
                        ok = 0;
                    }
                }

                if(ok)
                {
                    rc = Validate(ipb_top_suffix,top_suffix);
                    if(rc != 1 || top_suffix == "")
                    {
                        Set_data(cmbMsg,"Top suffix is required");
                        ok = 0;
                    }
                }

                if(ok)
                {
                    rc = Validate(ipb_bottom_suffix,bottom_suffix);
                    if(rc != 1 || bottom_suffix == "")
                    {
                        Set_data(cmbMsg,"Bottom suffix is required");
                        ok = 0;
                    }
                }

                if(ok)
                {
                    rc = Validate(fb_csv,CHECK_FILE,csv_path);
                    if(rc == NO_NAME)
                    {
                        Set_data(cmbMsg,"Please specify a CSV output file");
                        ok = 0;
                    }
                }

                if(ok)
                {
                    rc = Validate(cb_delimiter,delimiter_choice);

                    if(rc != 1)
                    {
                        Set_data(cmbMsg,
                            "Please select a delimiter");
                        ok = 0;
                    }
                }

                if(ok == 0) break;

                Integer no_elts = 0;
                rc = Get_number_of_items(sa_elements,no_elts);
                if(rc != 0)
                {
                    Set_data(cmbMsg,"Error reading elements from source box");
                    break;
                }

                if(delimiter_choice == "Comma (,)")
                {
                    delimiter = ",";
                }
                else if(delimiter_choice == "Semicolon (;)")
                {
                    delimiter = ";";
                }
                else
                {
                    delimiter = "\t";
                }

                Dynamic_Element top_elements;
                Dynamic_Element bottom_elements;
                Dynamic_Text prefixes_top;
                Dynamic_Text prefixes_bottom;
                Dynamic_Text unmatched_names;

                Integer idx;
                for(idx=1;idx<=no_elts;idx++)
                {
                    Element elt;
                    rc = Get_item(sa_elements,idx,elt);
                    if(rc != 0) continue;

                    Text sa_name = "";
                    rc = Get_name(elt,sa_name);
                    if(rc != 0) continue;

                    Text prefix = "";
                    Integer matched = 0;

                    if(Extract_prefix_from_name(sa_name,top_suffix,prefix) == 1)
                    {
                        Append(elt,top_elements);
                        Append(prefix,prefixes_top);
                        matched = 1;
                    }
                    else if(Extract_prefix_from_name(sa_name,bottom_suffix,prefix) == 1)
                    {
                        Append(elt,bottom_elements);
                        Append(prefix,prefixes_bottom);
                        matched = 1;
                    }

                    if(matched == 0) Append(sa_name,unmatched_names);
                }

                Integer top_count = 0;
                Integer bottom_count = 0;
                Integer unmatched_src = 0;
                Get_number_of_items(top_elements,top_count);
                Get_number_of_items(bottom_elements,bottom_count);
                Get_number_of_items(unmatched_names,unmatched_src);

                Dynamic_Element pair_top_elements;
                Dynamic_Element pair_bottom_elements;
                Dynamic_Text pair_prefixes;

                Integer i,j;
                Integer pair_count = 0;

                for(i=1;i<=top_count;i++)
                {
                    Element top_elt;
                    Text top_prefix = "";
                    rc = Get_item(top_elements,i,top_elt);
                    if(rc != 0) continue;
                    rc = Get_item(prefixes_top,i,top_prefix);
                    if(rc != 0) continue;

                    for(j=1;j<=bottom_count;j++)
                    {
                        Element bottom_elt;
                        Text bottom_prefix = "";
                        rc = Get_item(bottom_elements,j,bottom_elt);
                        if(rc != 0) continue;
                        rc = Get_item(prefixes_bottom,j,bottom_prefix);
                        if(rc != 0) continue;

                        if(top_prefix == bottom_prefix)
                        {
                            Append(top_elt,pair_top_elements);
                            Append(bottom_elt,pair_bottom_elements);
                            Append(top_prefix,pair_prefixes);
                            pair_count++;
                            break;
                        }
                    }
                }

                if(pair_count <= 0)
                {
                    Set_data(cmbMsg,"No matching TOP/BOTTOM wall pairs were found");
                    break;
                }

                File csv_file;
                Integer f_rc = File_open(csv_path,"w",csv_file);
                if(f_rc != 0)
                {
                    Set_data(cmbMsg,"Failed to open CSV file for writing");
                    break;
                }

                Text header = "WallName" + delimiter + "TotalLength" + delimiter + "0-1m" + delimiter + "1-2m" + delimiter + "2-3m" + delimiter + "3-4m" + delimiter + "4-5m" + delimiter + "5-6m" + delimiter + "6-7m" + delimiter + "7-8m" + delimiter + "8-9m" + delimiter + "9-10m" + delimiter + "Over10m";
                File_write_line(csv_file,header);

                Real sample_interval = 0.1;
                Real crop = 0.1;
                Integer walls_written = 0;
                Integer failed_samples = 0;

                for(i=1;i<=pair_count;i++)
                {
                    Element top_elt;
                    Element bottom_elt;
                    Text prefix = "";

                    if(Get_item(pair_top_elements,i,top_elt) != 0) continue;
                    if(Get_item(pair_bottom_elements,i,bottom_elt) != 0) continue;
                    if(Get_item(pair_prefixes,i,prefix) != 0) continue;

                    Real start_top = 0.0, end_top = 0.0;
                    Real start_bot = 0.0, end_bot = 0.0;

                    if(Get_chainage(top_elt,start_top) != 0) continue;
                    if(Get_end_chainage(top_elt,end_top) != 0) continue;
                    if(Get_chainage(bottom_elt,start_bot) != 0) continue;
                    if(Get_end_chainage(bottom_elt,end_bot) != 0) continue;

                    if(end_top < start_top)
                    {
                        Real temp_top = start_top;
                        start_top = end_top;
                        end_top = temp_top;
                    }
                    if(end_bot < start_bot)
                    {
                        Real temp_bot = start_bot;
                        start_bot = end_bot;
                        end_bot = temp_bot;
                    }

                    Real start_common = start_top;
                    if(start_bot > start_common) start_common = start_bot;

                    Real end_common = end_top;
                    if(end_bot < end_common) end_common = end_bot;

                    start_common += crop;
                    end_common -= crop;
                    if(end_common <= start_common) continue;

                    Real band_length[11];
                    Integer b;
                    for(b=1;b<=11;b++) band_length[b] = 0.0;

                    Real wall_length = end_common-start_common;
                    Real segment_start = start_common;

                    while(segment_start < end_common)
                    {
                        Real segment_end = segment_start+sample_interval;
                        if(segment_end > end_common) segment_end = end_common;

                        Real segment_length = segment_end-segment_start;
                        Real sample_ch = segment_start+(segment_length/2.0);

                        Real lvl_top = 0.0, grd_top = 0.0, m_top = 0.0;
                        Real lvl_bot = 0.0, grd_bot = 0.0, m_bot = 0.0;

                        rc = Get_super_alignment_vertical_position(top_elt,sample_ch,lvl_top,grd_top,m_top);
                        if(rc != 0)
                        {
                            failed_samples++;
                            segment_start = segment_end;
                            continue;
                        }

                        rc = Get_super_alignment_vertical_position(bottom_elt,sample_ch,lvl_bot,grd_bot,m_bot);
                        if(rc != 0)
                        {
                            failed_samples++;
                            segment_start = segment_end;
                            continue;
                        }

                        Real height = Absolute(lvl_top-lvl_bot);
                        Integer band = Height_band_index(height);
                        band_length[band] += segment_length;

                        segment_start = segment_end;
                    }

                    Text line = prefix + delimiter + To_text(wall_length,3);
                    for(b=1;b<=11;b++) line += delimiter + To_text(band_length[b],3);

                    f_rc = File_write_line(csv_file,line);
                    if(f_rc != 0) break;
                    walls_written++;
                }

                File_close(csv_file);

                Text info = "Paired=" + To_text(pair_count) +
                            " / walls written=" + To_text(walls_written) +
                            " / sample interval=0.1 m";
                if(unmatched_src > 0) info += " / source names ignored=" + To_text(unmatched_src);
                if(failed_samples > 0) info += " / failed samples=" + To_text(failed_samples);
                Set_data(cmbMsg,info);
            }
        }
        break;

        default :
        {
            if(cmd == "Finish") doit = 0;
        }
        break;
        }
    }
}

// ----------------------------- MAIN -----------------------------
void main(){

    //TODO: do pre-panel checks here

    mainPanel();
}