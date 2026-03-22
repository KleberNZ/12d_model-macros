/*---------------------------------------------------------------------
**   Programmer:KlP
**   Date:20/03/26
**   12D Model:            V15
**   Version:              001
**   Macro Name:           Create_chain_resolve_sa_panel.4dm
**   Type:                 CHAIN
**
**   Brief description: This macro writes resolve Sa commands to a chain.
**
**
**---------------------------------------------------------------------
**   Description: Writes Resolve Super Alignment commands 
**               from selected elements to a chain file, with optional
**               region grouping and natural (numeric-aware) sorting.
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

#define BUILD "15.0.001"

// ----------------------------- INCLUDES -----------------------------
#include "..\\..\\include/standard_library.H"
#include "..\\..\\include/size_of.H"
#include "..\\..\\include/set_ups.h"
#include "..\\..\\include/element_ids.h"
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

Text get_resolve_sa_block(Element elt)
{
    Text block = "";
    Text model_name = "";
    Text elt_name   = "";
    Text model_id_txt = "";
    Text elt_id_txt   = "";
    Text safe_model_name = "";
    Text safe_elt_name   = "";
    Text safe_cmd_name   = "";
    Model model;

    Get_name(elt,elt_name);

    if(elt_name == "")
    {
        Get_text_value(elt,elt_name);
    }

    if(Get_model(elt,model) == 0)
    {
        Get_name(model,model_name);
    }
    
    Integer rc = 0;
    rc = get_element_ids(elt,model_id_txt,elt_id_txt);

    safe_model_name = Convert_legal_XML(model_name);
    safe_elt_name   = Convert_legal_XML(elt_name);
    safe_cmd_name   = Convert_legal_XML("Resolve " + model_name + "->" + elt_name);

    block = block + "      <Resolve_sa>\n";
    block = block + "        <Name>" + safe_cmd_name + "</Name>\n";
    block = block + "        <Active>true</Active>\n";
    block = block + "        <Continue_on_failure>false</Continue_on_failure>\n";
    block = block + "        <Uses_parameters>false</Uses_parameters>\n";
    block = block + "        <Interactive>false</Interactive>\n";
    block = block + "        <Comments>\n";
    block = block + "        </Comments>\n";
    block = block + "        <Model_Name>" + safe_model_name + "</Model_Name>\n";
    block = block + "        <Model_ID>" + model_id_txt + "</Model_ID>\n";
    block = block + "        <Element_Name>" + safe_elt_name + "</Element_Name>\n";
    block = block + "        <Element_ID>" + elt_id_txt + "</Element_ID>\n";
    block = block + "      </Resolve_sa>\n";

    return block;
}

// --- PATCH: helper functions ---
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

Text get_resolve_sa_sort_name(Element elt)
{
    Text model_name = "";
    Text elt_name = "";
    Model model;

    Get_name(elt, elt_name);

    if(elt_name == "")
    {
        Get_text_value(elt, elt_name);
    }

    if(Get_model(elt, model) == 0)
    {
        Get_name(model, model_name);
    }

    return model_name + "->" + elt_name;
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

Text get_new_chain_text(Integer use_region, Text region_name, Dynamic_Element &selected_elements, Integer sort_alpha)
{
    Text txt = "";
    Integer no_items = 0;
    Integer i = 0;
    Integer selected_ix = 0;
    Element elt;

    Get_number_of_items(selected_elements,no_items);

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
        Text sort_name = "";
        Integer index[10000];

        Null(sort_keys);

        for(i = 1; i <= no_items; i++)
        {
            Get_item(selected_elements, i, elt);
            sort_name = get_resolve_sa_sort_name(elt);
            sort_key = make_natural_sort_key(sort_name);
            Append(sort_key, sort_keys);
        }

        Qsort(sort_keys, index, no_items);

        for(i = 1; i <= no_items; i++)
        {
            Get_item(selected_elements, index[i], elt);
            txt = txt + get_resolve_sa_block(elt);
        }
    }
    else
    {
        for(i = 1; i <= no_items; i++)
        {
            Get_item(selected_elements, i, elt);
            txt = txt + get_resolve_sa_block(elt);
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

Integer append_to_existing_chain(Text &txt, Integer use_region, Text region_name, Dynamic_Element &selected_elements, Integer sort_alpha)
{
    Text region_tag = "";
    Text insert_text = "";
    Text search_text = "";
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
    Element elt;

    Get_number_of_items(selected_elements,no_items);
    if(no_items <= 0) return 1;

    if(sort_alpha == 1)
    {
        Dynamic_Text sort_keys;
        Text sort_key = "";
        Text sort_name = "";
        Integer index[10000];

        Null(sort_keys);

        if(no_items > 10000) return 1;

        for(i = 1; i <= no_items; i++)
        {
            Get_item(selected_elements,i,elt);
            sort_name = get_resolve_sa_sort_name(elt);
            sort_key = make_natural_sort_key(sort_name);
            Append(sort_key,sort_keys);
        }

        Qsort(sort_keys,index,no_items);

        for(i = 1; i <= no_items; i++)
        {
            Get_item(selected_elements,index[i],elt);
            insert_text = insert_text + get_resolve_sa_block(elt);
        }
    }
    else
    {
        for(i = 1; i <= no_items; i++)
        {
            Get_item(selected_elements,i,elt);
            insert_text = insert_text + get_resolve_sa_block(elt);
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

    Text panelName="Create Resolve SA Chain";
    Panel              panel  = Create_panel              (panelName,TRUE);
    Vertical_Group     vgroup = Create_vertical_group     (-1         );
    Colour_Message_Box cmbMsg = Create_colour_message_box (""         );

    ///////////////////CREATE INPUT WIDGETS////////////////
    Source_Box sb_sa = Create_source_box("of Super Alignments",cmbMsg,0);
    File_Box   fb_chain = Create_file_box("Chain File",cmbMsg,CHECK_FILE_CREATE,"*.chain");
    Input_Box ib_region = Create_input_box("Region Name",cmbMsg);
    Named_Tick_Box ntb_sort_alpha = Create_named_tick_box("Sort alphabetically", 0, "");
    Set_optional(ib_region,1);

    ///////////////ADDING BUTTONS ALONG THE BOTTOM///////////////////////////
    Horizontal_Group bgroup = Create_button_group();
    Button process     = Create_button       ("&Process" ,"process");
    Button finish      = Create_finish_button("Finish"   ,"Finish" );
    Button help_button = Create_help_button  (panel      ,"Help"   );
    Append(process      ,bgroup);
    Append(finish       ,bgroup);
    Append(help_button  ,bgroup);

    ///////////////ADDING WIDGETS TO PANEL///////////////////////////
    Append(sb_sa    ,vgroup);
    Append(fb_chain ,vgroup);
    Append(ib_region ,vgroup);
    Append(ntb_sort_alpha, vgroup);

    Append(cmbMsg   ,vgroup);
    Append(bgroup   ,vgroup);

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
                Dynamic_Element selected_elements;
                Element          elt;

                Integer source_ret = 0;
                Integer file_ret   = 0;
                Integer no_items   = 0;
                Integer i          = 0;
                Integer exists     = 0;
                Integer invalid_count = 0;

                Text region_name = "";
                Integer use_region = 0;
                Text chain_text  = "";
                Integer sort_alpha = 0;
                Integer region_ret = 0;
                Integer write_ret  = 0;
                Integer read_ret   = 0;
               
                Text chain_file = "";

                source_ret = Validate(sb_sa,selected_elements);
                if(source_ret == 0)
                {
                    Set_data(cmbMsg,"ERROR - invalid Source_Box");
                    break;
                }

                Get_number_of_items(selected_elements,no_items);
                if(no_items <= 0)
                {
                    Set_data(cmbMsg,"ERROR - no elements selected");
                    break;
                }

                file_ret = Validate(fb_chain,CHECK_FILE_CREATE,chain_file);
                if(file_ret == 0)
                {
                    Set_data(cmbMsg,"ERROR - invalid chain file");
                    break;
                }

                // Validate SA selected elements
                Text type = "";

                for(i = 1; i <= no_items; i++)
                {
                    Get_item(selected_elements,i,elt);
                    Get_type(elt,type);

                    if(type != "Super_Alignment")
                    {
                        invalid_count++;
                    }
                }

                if(invalid_count > 0)
                {
                    Set_data(cmbMsg,"ERROR - selection contains non-SA element(s)");
                    break;
                }
                // Validate region
                use_region = 0;
                region_name = "";
                region_ret = Validate(ib_region,region_name);

                if(region_ret == 0)
                {
                    Set_data(cmbMsg,"ERROR - invalid region name");
                    break;
                }

                if(region_ret == 1 && region_name != "")
                {
                    use_region = 1;
                }
                else
                {
                    use_region = 0;
                    region_name = "";
                }
                
                // Validate sorting tick box
                if(Validate(ntb_sort_alpha, sort_alpha) == 0)
                {
                    Set_data(cmbMsg, "ERROR - invalid Sort alphabetically");
                    break;
                }

                if(sort_alpha == 1 && no_items > 10000)
                {
                    Set_data(cmbMsg, "too many matching functions (>10000)");
                    break;
                }

                exists = File_exists(chain_file);   // non-zero = exists, zero = does not exist

                if(exists == 0)
                {
                    chain_text = get_new_chain_text(use_region, region_name, selected_elements, sort_alpha);

                    write_ret = write_unicode_text_file(chain_file,chain_text);
                    if(write_ret != 0)
                    {
                        Set_data(cmbMsg,"ERROR - failed to create chain file");
                        break;
                    }

                    Set_data(cmbMsg,"New chain created");
                }
                else
                {
                    read_ret = read_unicode_text_file(chain_file,chain_text);
                    if(read_ret != 0)
                    {
                        Set_data(cmbMsg,"ERROR - failed to read existing chain file");
                        break;
                    }
                    
                    if(append_to_existing_chain(chain_text, use_region, region_name, selected_elements, sort_alpha) != 0)
                    {
                        Set_data(cmbMsg,"ERROR - failed to append into existing chain");
                        break;
                    }

                    write_ret = write_unicode_text_file(chain_file,chain_text);
                    if(write_ret != 0)
                    {
                        Set_data(cmbMsg,"ERROR - failed to write updated chain file");
                        break;
                    }

                    Set_data(cmbMsg,"Existing chain appended");
                }

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