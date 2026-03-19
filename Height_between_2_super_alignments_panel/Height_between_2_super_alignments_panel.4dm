/*--------------------------------------------------------------------
**   Programmer: Kleber Lessa do Prado
**   Date:       27/11/2025
**   12d Model:  V15
**   Version:    1.00
**   Macro Name: Height_between_2_super_alignments_panel
**   Type:       SOURCE
**
**   Brief:
**       Computes height differences between pairs of super alignments
**       and writes results to a CSV file.
**
**   Full Description:
**       This macro allows the user to select a set of super alignments
**       and automatically pairs them based on matching name prefixes
**       and user-defined suffixes (eg:TOP/BOTTOM). After pairing, it
**       samples elevations along the common chainage range of each
**       pair, computes the absolute vertical height difference at
**       regular chainage intervals, and writes the data to a CSV file.
**
**       Chainage sampling is trimmed by 0.1 m at both ends to avoid
**       endpoint evaluation issues, and level values are read using
**       the super alignment vertical position functions. The CSV file
**       contains one row per sampled chainage, including prefix name,
**       relative chainage, TOP elevation, BOTTOM elevation, and height
**       difference.
**
**       This panel-based macro was intended for retaining wall
**       scheduling.
**
**---------------------------------------------------------------------
**   Update/Modification
**
**  This macro may be reproduced, modified and used without restriction.
**  The author grants all users Unlimited Use of the source code and any 
**  associated files, for no fee. Unlimited Use includes compiling, running,
**  and modifying the code for individual or integrated purposes.
**  The author also grants 12d Solutions Pty Ltd and other users permission
**  to incorporate this macro, in whole or in part, into other macros or programs..
*--------------------------------------------------------------------
*/

#define DEBUG_FILE      0
#define ECHO_DEBUG_FILE 0
#define ECHO_LINE_NO    0
 
#define BUILD "version.0.001"
 
#include "..\\..\\include/standard_library.H"
#include "..\\..\\include/size_of.H"

/*--------------------------------------------------------------------
** Helper: extract prefix if name ends with suffix (trim spaces)
*--------------------------------------------------------------------*/
Integer Extract_prefix_from_name(Text name_in,Text suffix_in,Text &prefix)
{
    Text name   = name_in;
    Text suffix = suffix_in;

    // Trim trailing spaces from name
    Integer len_name = Text_length(name);
    while(len_name > 0)
    {
        Text c = Get_subtext(name,len_name,len_name);
        if(c != " ") break;
        name     = Get_subtext(name,1,len_name-1);
        len_name = Text_length(name);
    }

    // Trim trailing spaces from suffix
    Integer len_suf = Text_length(suffix);
    while(len_suf > 0)
    {
        Text c2 = Get_subtext(suffix,len_suf,len_suf);
        if(c2 != " ") break;
        suffix  = Get_subtext(suffix,1,len_suf-1);
        len_suf = Text_length(suffix);
    }

    prefix = "";

    if(len_suf <= 0) return 0;
    if(len_name <= len_suf) return 0;

    // Get last len_suf chars
    Text tail = Get_subtext(name,len_name - len_suf + 1,len_name);
    if(tail != suffix) return 0;

    // Base prefix: everything before suffix
    prefix = Get_subtext(name,1,len_name - len_suf);

    // Trim a single trailing space if present
    Integer lp = Text_length(prefix);
    if(lp > 0)
    {
        Text last_char = Get_subtext(prefix,lp,lp);
        if(last_char == " ")
        {
            prefix = Get_subtext(prefix,1,lp-1);
        }
    }

    return 1;
}

/*global variables*/{


}

void mainPanel(){
 
    Text panelName="SA Wall Heights To CSV";
    Panel              panel  = Create_panel              (panelName,TRUE);
    Vertical_Group     vgroup = Create_vertical_group     (-1         );
    Colour_Message_Box cmbMsg = Create_colour_message_box (""         );

    Source_Box sb_source = Create_source_box("Super alignment source",cmbMsg,Source_Box_Standard);

    Input_Box ipb_top_suffix = Create_input_box("Top suffix"   ,cmbMsg);
    Set_default_data(ipb_top_suffix,"TOP");

    Input_Box ipb_bottom_suffix = Create_input_box("Bottom suffix",cmbMsg);
    Set_default_data(ipb_bottom_suffix,"BOTTOM");

    Real_Box rb_chain_interval = Create_real_box("Chainage interval (m)",cmbMsg);
    Set_default_data(rb_chain_interval,5.0);

    File_Box fb_csv = Create_file_box("CSV output file",cmbMsg,CHECK_FILE,"*.csv");
    
    Horizontal_Group bgroup = Create_button_group();
    Button process     = Create_button       ("&Process" ,"process");
    Button finish      = Create_finish_button("Finish"   ,"Finish" );
    Button help_button = Create_help_button  (panel      ,"Help"   );
    Append(process      ,bgroup);
    Append(finish       ,bgroup);
    Append(help_button  ,bgroup);

    Append(sb_source         ,vgroup);
    Append(ipb_top_suffix    ,vgroup);
    Append(ipb_bottom_suffix ,vgroup);
    Append(rb_chain_interval ,vgroup);
    Append(fb_csv            ,vgroup);
    Append(cmbMsg            ,vgroup);
    Append(bgroup            ,vgroup);

    Append(vgroup,panel);
    Show_widget(panel);

    Integer doit = 1;
    while(doit)
    {
        Text cmd="",msg = "";
        Integer id,ret = Wait_on_widgets(id,cmd,msg);
 
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
                Dynamic_Element sa_elements;
                Text top_suffix     = "";
                Text bottom_suffix  = "";
                Text csv_path       = "";
                Real chain_interval = 0.0;
                Integer rc          = 0;
                Integer ok          = 1;

                // 1) Validate Source_Box selection
                rc = Validate(sb_source,sa_elements);     // success = 1
                if(rc != 1)
                {
                    Set_data(cmbMsg,"Please select super alignments in the source box");
                    ok = 0;
                }
                else
                {
                    Integer no_elts_chk = 0;
                    rc = Get_number_of_items(sa_elements,no_elts_chk);   // success = 0
                    if(rc != 0 || no_elts_chk <= 0)
                    {
                        Set_data(cmbMsg,"No elements found in the source box");
                        ok = 0;
                    }
                }

                // 2) Validate TOP suffix
                if(ok)
                {
                    rc = Validate(ipb_top_suffix,top_suffix);   // success = 1
                    if(rc == 0 || top_suffix == "")
                    {
                        Set_data(cmbMsg,"Top suffix is required");
                        ok = 0;
                    }
                }

                // 3) Validate BOTTOM suffix
                if(ok)
                {
                    rc = Validate(ipb_bottom_suffix,bottom_suffix);  // success = 1
                    if(rc == 0 || bottom_suffix == "")
                    {
                        Set_data(cmbMsg,"Bottom suffix is required");
                        ok = 0;
                    }
                }

                // 4) Validate chainage interval > 0
                if(ok)
                {
                    rc = Validate(rb_chain_interval,chain_interval); // success = 1
                    if(rc != 1 || chain_interval <= 0.0)
                    {
                        Set_data(cmbMsg,"Chainage interval must be greater than 0.0 m");
                        ok = 0;
                    }
                }

                // 5) Validate CSV file path
                if(ok)
                {
                    rc = Validate(fb_csv, CHECK_FILE, csv_path);     // FILE_EXISTS / NO_FILE / NO_NAME
                    if(rc == NO_NAME)
                    {
                        Set_data(cmbMsg,"Please specify a CSV output file");
                        ok = 0;
                    }
                }

                if(ok == 0) break;

                // -------- classify SAs into TOP/BOTTOM ----------
                Integer no_elts = 0;
                rc = Get_number_of_items(sa_elements,no_elts);   // success = 0
                if(rc != 0)
                {
                    Set_data(cmbMsg,"Error reading elements from source box");
                    break;
                }

                Dynamic_Element top_elements;
                Dynamic_Element bottom_elements;
                Dynamic_Text    prefixes_top;
                Dynamic_Text    prefixes_bottom;
                Dynamic_Text    unmatched_names;

                Integer idx;
                for(idx = 1 ; idx <= no_elts ; idx++)
                {
                    Element elt;
                    rc = Get_item(sa_elements,idx,elt);          // success = 0
                    if(rc != 0) continue;

                    Text sa_name = "";
                    rc = Get_name(elt,sa_name);                  // success = 0
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

                    if(matched == 0)
                        Append(sa_name,unmatched_names);
                }

                Integer top_count     = 0;
                Integer bottom_count  = 0;
                Integer unmatched_src = 0;
                Get_number_of_items(top_elements   ,top_count);
                Get_number_of_items(bottom_elements,bottom_count);
                Get_number_of_items(unmatched_names,unmatched_src);

                // -------- pair TOP/BOTTOM by prefix -------------
                Dynamic_Element pair_top_elements;
                Dynamic_Element pair_bottom_elements;
                Dynamic_Text    pair_prefixes;

                Integer i,j;
                Integer pair_count = 0;

                for(i = 1 ; i <= top_count ; i++)
                {
                    Element top_elt;
                    Text    top_prefix = "";

                    rc = Get_item(top_elements ,i,top_elt);
                    if(rc != 0) continue;
                    rc = Get_item(prefixes_top,i,top_prefix);
                    if(rc != 0) continue;

                    for(j = 1 ; j <= bottom_count ; j++)
                    {
                        Element bottom_elt;
                        Text    bottom_prefix = "";

                        rc = Get_item(bottom_elements ,j,bottom_elt);
                        if(rc != 0) continue;
                        rc = Get_item(prefixes_bottom,j,bottom_prefix);
                        if(rc != 0) continue;

                        if(top_prefix == bottom_prefix)
                        {
                            Append(top_elt   ,pair_top_elements);
                            Append(bottom_elt,pair_bottom_elements);
                            Append(top_prefix,pair_prefixes);
                            pair_count++;
                            break;
                        }
                    }
                }

                Integer unmatched_top    = top_count    - pair_count;
                Integer unmatched_bottom = bottom_count - pair_count;

                if(pair_count <= 0)
                {
                    Text info0 = "TOP=" + To_text(top_count) +
                                 " BOTTOM=" + To_text(bottom_count) +
                                 " PAIRED=0";

                    if(unmatched_src > 0)
                    {
                        Text extra = " Unmatched source=" + To_text(unmatched_src) + " e.g.: ";
                        Integer show_n = unmatched_src;
                        if(show_n > 3) show_n = 3;

                        Integer k;
                        for(k = 1 ; k <= show_n ; k++)
                        {
                            Text nm = "";
                            Get_item(unmatched_names,k,nm);
                            if(k > 1) extra += " | ";
                            extra += "'" + nm + "'";
                        }
                        info0 += extra;
                    }

                    info0 += " - no pairs found, nothing written";
                    Set_data(cmbMsg,info0);
                    break;
                }

                // -------- open CSV & header ----------------------
                File csv_file;
                Integer f_rc = 0;
                f_rc = File_open(csv_path,"w",csv_file);   // success = 0
                if(f_rc != 0)
                {
                    Set_data(cmbMsg,"Failed to open CSV file for writing");
                    break;
                }

                Text header = "WallName,Chainage,TopZ,BottomZ,DeltaZ";
                File_write_line(csv_file,header);

                // -------- sample heights & write rows -----------
                Integer total_rows = 0;

                for(i = 1 ; i <= pair_count ; i++)
                {
                    Element top_elt;
                    Element bottom_elt;
                    Text    prefix = "";

                    rc = Get_item(pair_top_elements   ,i,top_elt);
                    if(rc != 0) continue;
                    rc = Get_item(pair_bottom_elements,i,bottom_elt);
                    if(rc != 0) continue;
                    rc = Get_item(pair_prefixes       ,i,prefix);
                    if(rc != 0) continue;

                    Real start_top = 0.0, end_top = 0.0;
                    Real start_bot = 0.0, end_bot = 0.0;

                    rc = Get_chainage(top_elt,start_top);     
                    if(rc != 0) continue;
                    rc = Get_end_chainage(top_elt,end_top);   
                    if(rc != 0) continue;

                    rc = Get_chainage(bottom_elt,start_bot);  
                    if(rc != 0) continue;
                    rc = Get_end_chainage(bottom_elt,end_bot);
                    if(rc != 0) continue;

                    if(end_top < start_top)
                    {
                        Real tmp = start_top; start_top = end_top; end_top = tmp;
                    }
                    if(end_bot < start_bot)
                    {
                        Real tmp2 = start_bot; start_bot = end_bot; end_bot = tmp2;
                    }

                    Real start_common = start_top;
                    if(start_bot > start_common) start_common = start_bot;

                    Real end_common = end_top;
                    if(end_bot < end_common) end_common = end_bot;

                    Real crop = 0.1;
                    start_common = start_common + crop;
                    end_common   = end_common   - crop;

                    if(end_common <= start_common) continue;

                    Real ch;
                    Real eps = 1.0e-6;
                    for(ch = start_common ; ch <= end_common + eps ; ch = ch + chain_interval)
                    {
                        Real lvl_top = 0.0, grd_top = 0.0, m_top = 0.0;
                        Real lvl_bot = 0.0, grd_bot = 0.0, m_bot = 0.0;

                        rc = Get_super_alignment_vertical_position(top_elt   ,ch,lvl_top,grd_top,m_top);
                        if(rc != 0) continue;

                        rc = Get_super_alignment_vertical_position(bottom_elt,ch,lvl_bot,grd_bot,m_bot);
                        if(rc != 0) continue;

                        Real delta = Absolute(lvl_top - lvl_bot);
                        Real rel_ch = ch - start_common;

                        Text line = "";
                        line  = prefix + ",";
                        line += To_text(rel_ch ,3) + ",";
                        line += To_text(lvl_top,3) + ",";
                        line += To_text(lvl_bot,3) + ",";
                        line += To_text(delta  ,3);

                        f_rc = File_write_line(csv_file,line);
                        if(f_rc != 0) break;

                        total_rows++;
                    }
                }

                File_close(csv_file);

                Text info = "TOP=" + To_text(top_count) +
                            " / BOTTOM=" + To_text(bottom_count) +
                            " / PAIRED=" + To_text(pair_count);

                if(unmatched_top > 0 || unmatched_bottom > 0)
                {
                    info += " (unmatched TOP=" + To_text(unmatched_top) +
                            ", unmatched BOTTOM=" + To_text(unmatched_bottom) + ")";
                }
                if(unmatched_src > 0)
                {
                    info += " | source unmatched=" + To_text(unmatched_src);
                }

                info += " - CSV rows written=" + To_text(total_rows);
                Set_data(cmbMsg,info);
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
    mainPanel();
}
