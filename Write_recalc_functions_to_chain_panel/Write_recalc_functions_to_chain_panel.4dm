/*---------------------------------------------------------------------
**   Programmer:KLP
**   Date:23/03/26             
**   12D Model:            V15
**   Version:              001
**   Macro Name:           Write_recalc_functions_to_chain.4dm
**   Type:                 Chain
**
**   Brief description: Write recalc function commands to a chain
**
**---------------------------------------------------------------------
**   Description: Finds functions by wildcard pattern and writes recalc
**   function commands into a chain file.
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
#include "..\\..\\include/standard_library.H"
#include "..\\..\\include/size_of.H"
#include "..\\..\\include/QSort.H"

/*global variables*/{

}

//============================HELPER FUNCTIONS==========================
Text get_region_block(Text region_name)
{
    Text block = "";
    Text safe_region_name = Convert_legal_XML(region_name);

    block = block + "      <Region>\n";
    block = block + "        <Name>" + safe_region_name + "</Name>\n";
    block = block + "        <Active>true</Active>\n";
    block = block + "        <Continue_on_failure>false</Continue_on_failure>\n";
    block = block + "        <Uses_parameters>false</Uses_parameters>\n";
    block = block + "        <Interactive>false</Interactive>\n";
    block = block + "        <Comments>\n";
    block = block + "        </Comments>\n";
    block = block + "      </Region>\n";

    return block;
}

Text get_recalc_function_block(Text function_name)
{
    Text block = "";
    Text safe_function_name = Convert_legal_XML(function_name);
    Text safe_cmd_name      = Convert_legal_XML("Recalc " + function_name);

    block = block + "      <Function>\n";
    block = block + "        <Name>" + safe_cmd_name + "</Name>\n";
    block = block + "        <Active>true</Active>\n";
    block = block + "        <Continue_on_failure>false</Continue_on_failure>\n";
    block = block + "        <Uses_parameters>false</Uses_parameters>\n";
    block = block + "        <Interactive>false</Interactive>\n";
    block = block + "        <Comments>\n";
    block = block + "        </Comments>\n";
    block = block + "        <Function>" + safe_function_name + "</Function>\n";
    block = block + "      </Function>\n";

    return block;
}

Integer is_digit_char(Integer c)
{
    if(c >= 48 && c <= 57)
    {
        return 1;
    }

    return 0;
}

Text pad_integer_text(Text txt, Integer width)
{
    while(Text_length(txt) < width)
    {
        txt = "0" + txt;
    }

    return txt;
}

Text make_natural_sort_key(Text name)
{
    Text key = "";
    Text digit_text = "";
    Text ch = "";

    Integer len = 0;
    Integer i = 1;
    Integer j = 0;
    Integer c = 0;
    Integer number = 0;
    Integer rc_num = 0;
    Integer rc_char = 0;

    len = Text_length(name);

    while(i <= len)
    {
        c = 0;
        rc_char = Get_char(name, i, c);
        if(rc_char != 0)
        {
            i++;
            continue;
        }

        if(is_digit_char(c) != 0)
        {
            j = i;

            while(j <= len)
            {
                c = 0;
                rc_char = Get_char(name, j, c);
                if(rc_char != 0) break;
                if(is_digit_char(c) == 0) break;
                j++;
            }

            digit_text = Get_subtext(name, i, j - 1);

            number = 0;
            rc_num = From_text(digit_text, number);

            if(rc_num == 0)
            {
                key = key + pad_integer_text(To_text(number), 10);
            }
            else
            {
                key = key + digit_text;
            }

            i = j;
        }
        else
        {
            ch = Get_subtext(name, i, i);
            key = key + ch;
            i++;
        }
    }

    return key;
}

Text get_new_chain_text(Integer use_region, Text region_name, Dynamic_Text &matched_functions, Integer sort_alpha)
{
    Text txt = "";
    Integer no_items = 0;
    Integer i = 0;
    Integer selected_ix = 0;
    Text function_name = "";

    Get_number_of_items(matched_functions,no_items);

    if(use_region == 1)
    {
        selected_ix = no_items;
    }
    else
    {
        selected_ix = no_items - 1;
        if(selected_ix < 0) selected_ix = 0;
    }

    txt = txt + "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n";
    txt = txt + "<xml12d xmlns=\"http://www.12d.com/schema/xml12d-10.0\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" language=\"English\" version=\"1.0\">\n";
    txt = txt + "  <meta_data>\n";
    txt = txt + "    <author></author>\n";
    txt = txt + "    <company></company>\n";
    txt = txt + "    <date></date>\n";
    txt = txt + "    <time></time>\n";
    txt = txt + "  </meta_data>\n";
    txt = txt + "  <Chain>\n";
    txt = txt + "    <version>1</version>\n";
    txt = txt + "    <Settings>\n";
    txt = txt + "      <Parameter_File/>\n";
    txt = txt + "      <Prompt_for_parameters>false</Prompt_for_parameters>\n";
    txt = txt + "      <Always_record_for_parameters>false</Always_record_for_parameters>\n";
    txt = txt + "      <Interactive>false</Interactive>\n";
    txt = txt + "    </Settings>\n";
    txt = txt + "    <Commands>\n";

    if(use_region == 1)
    {
        txt = txt + get_region_block(region_name);
    }

    if(sort_alpha == 1)
    {
        Dynamic_Text sort_keys;
        Text sort_key = "";

        Null(sort_keys);

        if(no_items > 10000)
        {
            return "";
        }

        for(i = 1; i <= no_items; i++)
        {
            Get_item(matched_functions, i, function_name);
            sort_key = make_natural_sort_key(function_name);
            Append(sort_key, sort_keys);
        }

        Integer index[10000];

        Qsort(sort_keys, index, no_items);

        for(i = 1; i <= no_items; i++)
        {
            Get_item(matched_functions, index[i], function_name);
            txt = txt + get_recalc_function_block(function_name);
        }
    }
    else
    {
        for(i = 1; i <= no_items; i++)
        {
            Get_item(matched_functions, i, function_name);
            txt = txt + get_recalc_function_block(function_name);
        }
    }

    txt = txt + "    </Commands>\n";
    txt = txt + "    <selected_command>\n";
    txt = txt + "      <ix>" + To_text(selected_ix) + "</ix>\n";
    txt = txt + "    </selected_command>\n";
    txt = txt + "  </Chain>\n";
    txt = txt + "</xml12d>\n";

    return txt;
}

Integer read_unicode_text_file(Text file_name, Text &txt)
{
    File file;
    Text line = "";
    Integer ret = 0;

    txt = "";

    ret = File_open(file_name,"r","ccs=UNICODE",file);
    if(ret != 0) return 1;

    while(1)
    {
        ret = File_read_line(file,line);

        if(ret == -1) break;
        if(ret != 0)
        {
            File_close(file);
            return 1;
        }

        txt = txt + line + "\n";
    }

    File_close(file);
    return 0;
}

Integer write_unicode_text_file(Text file_name, Text txt)
{
    File file;
    Integer ret = 0;

    ret = File_open(file_name,"w","ccs=UNICODE",file);
    if(ret != 0) return 1;

    ret = File_write_unicode(file,Text_length(txt),txt);

    File_close(file);

    if(ret != 0) return 1;

    return 0;
}

Integer insert_before_tag(Text &txt, Text tag, Text insert_text)
{
    Integer pos = 0;

    pos = Find_text(txt,tag);
    if(pos == 0) return 1;

    Insert_text(txt,pos,insert_text);
    return 0;
}

Integer append_to_existing_chain(Text &txt, Integer use_region, Text region_name, Dynamic_Text &matched_functions, Integer sort_alpha)
{
    Text region_tag = "";
    Text insert_text = "";
    Text search_text = "";
    Text function_name = "";

    Integer region_pos = 0;
    Integer first_region_pos = 0;
    Integer next_region_pos = 0;
    Integer commands_end_pos = 0;
    Integer insert_pos = 0;
    Integer no_items = 0;
    Integer i = 0;
    Integer txt_len = 0;
    Integer sub_start = 0;
    Integer sub_end = 0;

    Get_number_of_items(matched_functions,no_items);
    if(no_items <= 0) return 1;

        if(sort_alpha == 1)
    {
        Dynamic_Text sort_keys;
        Text sort_key = "";

        Null(sort_keys);

        if(no_items > 10000)
        {
            return 1;
        }

        for(i = 1; i <= no_items; i++)
        {
            Get_item(matched_functions, i, function_name);
            sort_key = make_natural_sort_key(function_name);
            Append(sort_key, sort_keys);
        }

        Integer index[10000];

        Qsort(sort_keys, index, no_items);

        for(i = 1; i <= no_items; i++)
        {
            Get_item(matched_functions, index[i], function_name);
            insert_text = insert_text + get_recalc_function_block(function_name);
        }
    }
    else
    {
        for(i = 1; i <= no_items; i++)
        {
            Get_item(matched_functions, i, function_name);
            insert_text = insert_text + get_recalc_function_block(function_name);
        }
    }

    if(use_region == 0)
    {
        first_region_pos = Find_text(txt,"      <Region>");
        if(first_region_pos != 0)
        {
            Insert_text(txt,first_region_pos,insert_text);
            return 0;
        }

        return insert_before_tag(txt,"    </Commands>",insert_text);
    }

    region_tag = "<Name>" + Convert_legal_XML(region_name) + "</Name>";
    region_pos = Find_text(txt,region_tag);

    if(region_pos == 0)
    {
        insert_text = get_region_block(region_name) + insert_text;
        return insert_before_tag(txt,"    </Commands>",insert_text);
    }

    txt_len = Text_length(txt);
    sub_start = region_pos + 1;
    sub_end = txt_len;

    search_text = Get_subtext(txt,sub_start,sub_end);

    next_region_pos = Find_text(search_text,"      <Region>");
    commands_end_pos = Find_text(search_text,"    </Commands>");

    if(next_region_pos != 0 && commands_end_pos != 0)
    {
        if(next_region_pos < commands_end_pos)
        {
            insert_pos = region_pos + next_region_pos - 1;
        }
        else
        {
            insert_pos = region_pos + commands_end_pos - 1;
        }
    }
    else if(next_region_pos != 0)
    {
        insert_pos = region_pos + next_region_pos - 1;
    }
    else if(commands_end_pos != 0)
    {
        insert_pos = region_pos + commands_end_pos - 1;
    }
    else
    {
        return 1;
    }

    Insert_text(txt,insert_pos,insert_text);
    return 0;
}

void mainPanel(){
 
    Text panelName="Write Recalc Functions To Chain";
    Panel              panel  = Create_panel              (panelName,TRUE);
    Vertical_Group     vgroup = Create_vertical_group     (-1         );
    Colour_Message_Box cmbMsg = Create_colour_message_box (""         );

    ///////////////////CREATE INPUT WIDGETS////////////////
    Input_Box pattern_box = Create_input_box("Function name pattern", cmbMsg);
    File_Box  chain_box   = Create_file_box ("Chain file",            cmbMsg, 0, "*.chain");
    Input_Box region_box  = Create_input_box("Region name (optional)",cmbMsg);
    Named_Tick_Box sort_box = Create_named_tick_box("Sort alphabetically",TRUE,"");

    Set_data(sort_box, 1);

    Set_optional(region_box, TRUE);

    // optional starter values
    Set_data(pattern_box, "");
    Set_data(chain_box,   "");
    Set_data(region_box,  "");
    
    ///////////////ADDING BUTTONS ALONG THE BOTTOM///////////////////////////
    Horizontal_Group bgroup = Create_button_group();
    Button process     = Create_button       ("&Process" ,"process");
    Button finish      = Create_finish_button("Finish"   ,"Finish" );
    Button help_button = Create_help_button  (panel      ,"Help"   );
    Append(process      ,bgroup);
    Append(finish       ,bgroup);
    Append(help_button  ,bgroup);

    ///////////////ADDING WIDGETS TO PANEL///////////////////////////
    Append(pattern_box ,vgroup);
    Append(chain_box   ,vgroup);
    Append(region_box  ,vgroup);
    Append(sort_box    ,vgroup);
    
    Append(cmbMsg      ,vgroup);
    Append(bgroup      ,vgroup);

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
                Text pattern_text = "";
                Text chain_file   = "";
                Text region_text  = "";
                Text chain_text   = "";
                Text new_chain_text = "";

                Integer rc_pattern = 0;
                Integer rc_chain   = 0;
                Integer rc_region  = 0;
                Integer rc_all     = 0;
                Integer rc_count   = 0;
                Integer rc_item    = 0;
                Integer rc_match   = 0;
                Integer rc_file    = 0;
                Integer rc_read    = 0;
                Integer rc_append  = 0;
                Integer rc_write   = 0;

                Integer use_region    = 0;
                Integer chain_exists  = 0;
                Integer no_items      = 0;
                Integer i             = 0;
                Integer matched_count = 0;
                Integer sort_alpha    = 1;
                Integer rc_sortbox    = 0;

                Text function_name = "";

                Dynamic_Text all_functions;
                Dynamic_Text matched_functions;

                Null(all_functions);
                Null(matched_functions);

                Set_data(cmbMsg, "");

                //Validate wild Card function name
                rc_pattern = Validate(pattern_box, pattern_text);
                if(rc_pattern == 0)
                {
                    Set_data(cmbMsg, "invalid function pattern");
                    continue;
                }

                //validate Chain name
                rc_chain = Validate(chain_box, CHECK_FILE_APPEND, chain_file);
                if(rc_chain == 0)
                {
                    Set_data(cmbMsg, "invalid chain file");
                    continue;
                }

                //Validate region name
                rc_region = Validate(region_box, region_text);
                if(rc_region == 0)
                {
                    Set_data(cmbMsg, "invalid region name");
                    continue;
                }
                else if(rc_region == NO_NAME)
                {
                    use_region = 0;
                    region_text = "";
                }
                else
                {
                    use_region = 1;
                }

                //Validate sort alphabetically
                rc_sortbox = Validate(sort_box, sort_alpha);
                if(rc_sortbox == 0)
                {
                    Set_data(cmbMsg, "invalid sort option");
                    continue;
                }

                rc_all = Get_all_functions(all_functions);
                if(rc_all != 0)
                {
                    Set_data(cmbMsg, "could not read functions");
                    continue;
                }

                rc_count = Get_number_of_items(all_functions, no_items);
                if(rc_count != 0)
                {
                    Set_data(cmbMsg, "could not count functions");
                    continue;
                }

                for(i = 1; i <= no_items; i++)
                {
                    function_name = "";
                    rc_item = Get_item(all_functions, i, function_name);
                    if(rc_item != 0)
                    {
                        continue;
                    }

                    rc_match = Match_name(function_name, pattern_text);
                    if(rc_match != 0)
                    {
                        Append(function_name, matched_functions);
                        matched_count++;
                    }
                }

                if(matched_count == 0)
                {
                    Set_data(cmbMsg, "no matching functions");
                    continue;
                }

                if(sort_alpha == 1 && matched_count > 10000)
                {
                    Set_data(cmbMsg, "too many matching functions (>10000)");
                    continue;
                }

                chain_exists = File_exists(chain_file);

                if(chain_exists == 0)
                {
                    new_chain_text = get_new_chain_text(use_region, region_text, matched_functions, sort_alpha);

                    rc_write = write_unicode_text_file(chain_file, new_chain_text);
                    if(rc_write != 0)
                    {
                        Set_data(cmbMsg, "could not write chain");
                        continue;
                    }

                    Set_data(cmbMsg, "new chain created");
                    continue;
                }

                rc_read = read_unicode_text_file(chain_file, chain_text);
                if(rc_read != 0)
                {
                    Set_data(cmbMsg, "could not read chain");
                    continue;
                }

                rc_append = append_to_existing_chain(chain_text, use_region, region_text, matched_functions, sort_alpha);
                if(rc_append != 0)
                {
                    Set_data(cmbMsg, "could not append chain");
                    continue;
                }

                rc_write = write_unicode_text_file(chain_file, chain_text);
                if(rc_write != 0)
                {
                    Set_data(cmbMsg, "could not write chain");
                    continue;
                }

                Set_data(cmbMsg, "existing chain appended");
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