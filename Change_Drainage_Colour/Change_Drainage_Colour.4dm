/*---------------------------------------------------------------------
**   Programmer:           KLP
**   Date:                 2026-07-22
**   12D Model:            V15
**   Version:              001
**   Macro Name:           Change_Drainage_Colour.4dm
**   Type:                 SOURCE
**
**   Brief description: Change the colour of drainage elements.
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

#include "standard_library.h"
#include "size_of.h"

/*global variables*/{
}

void mainPanel()
{
    Text panelName="Change Drainage Colours";
    Panel panel=Create_panel(panelName,TRUE);
    Vertical_Group vgroup=Create_vertical_group(-1);
    Colour_Message_Box cmbMsg=Create_colour_message_box("");

    Source_Box sb_source=Create_source_box("Drainage strings",cmbMsg,0);
    Colour_Box cb_node=Create_colour_box("Node colour (pits)",cmbMsg);
    Colour_Box cb_link=Create_colour_box("Link colour (pipes)",cmbMsg);

    Set_optional(cb_node,1);
    Set_optional(cb_link,1);

    Horizontal_Group bgroup=Create_button_group();
    Button process=Create_button("&Process","process");
    Button finish=Create_finish_button("Finish","Finish");
    Button help_button=Create_help_button(panel,"Help");

    Append(process,bgroup);
    Append(finish,bgroup);
    Append(help_button,bgroup);

    Append(sb_source,vgroup);
    Append(cb_node,vgroup);
    Append(cb_link,vgroup);
    Append(cmbMsg,vgroup);
    Append(bgroup,vgroup);
    Append(vgroup,panel);

    Show_widget(panel);

    Integer doit=1;
    while(doit)
    {
        Text cmd="",msg="";
        Integer id,ret=Wait_on_widgets(id,cmd,msg);

        switch(cmd)
        {
        case "keystroke":
        case "set_focus":
        case "kill_focus":
        {
            continue;
        }
        break;

        case "CodeShutdown":
        {
            Set_exit_code(cmd);
        }
        break;
        }

        switch(id)
        {
        case Get_id(panel):
        {
            if(cmd=="Panel Quit") doit=0;
            if(cmd=="Panel About") about_panel(panel);
        }
        break;

        case Get_id(process):
        {
            if(cmd=="process")
            {
                Dynamic_Element de_source;
                Integer source_count=0;
                Integer node_colour;
                Integer link_colour;
                Integer node_validation;
                Integer link_validation;
                Integer change_nodes;
                Integer change_links;

                if(Validate(sb_source,de_source)==FALSE)
                {
                    Set_error_message(sb_source,"");
                    break;
                }

                Get_number_of_items(de_source,source_count);

                if(source_count<=0)
                {
                    Set_error_message(sb_source,"No drainage strings selected");
                    break;
                }

                node_validation=Validate(cb_node,node_colour);
                if(node_validation==FALSE) break;

                link_validation=Validate(cb_link,link_colour);
                if(link_validation==FALSE) break;

                change_nodes=(node_validation!=NO_NAME);
                change_links=(link_validation!=NO_NAME);

                if(change_nodes==FALSE && change_links==FALSE)
                {
                    Set_data(cmbMsg,"Enter at least one node or link colour");
                    break;
                }

                Integer element_index;
                Integer pit_index;
                Integer pipe_index;
                Integer pit_count;
                Integer pipe_count;
                Integer changed_pits=0;
                Integer changed_pipes=0;
                Integer skipped_elements=0;
                Integer undo_count=0;
                Integer element_changed;
                Integer rc;

                Element drainage_element;
                Element original_element;
                Model null_model;
                Undo undo_item;
                Undo grouped_undo;
                Undo_List undo_list;

                Null(null_model);

                for(element_index=1;element_index<=source_count;element_index++)
                {
                    rc=Get_item(de_source,element_index,drainage_element);

                    if(rc!=0)
                    {
                        skipped_elements++;
                        continue;
                    }

                    rc=Get_drainage_pits(drainage_element,pit_count);

                    if(rc!=0 || pit_count<=0)
                    {
                        skipped_elements++;
                        Null(drainage_element);
                        continue;
                    }

                    pipe_count=pit_count-1;
                    element_changed=0;

                    rc=Element_duplicate(drainage_element,original_element);

                    if(rc!=0)
                    {
                        skipped_elements++;
                        Null(drainage_element);
                        continue;
                    }

                    Set_model(original_element,null_model);

                    if(change_nodes)
                    {
                        for(pit_index=1;pit_index<=pit_count;pit_index++)
                        {
                            rc=Set_drainage_pit_colour(
                                drainage_element,
                                pit_index,
                                node_colour
                            );

                            if(rc==0)
                            {
                                changed_pits++;
                                element_changed=1;
                            }
                        }
                    }

                    if(change_links)
                    {
                        for(pipe_index=1;pipe_index<=pipe_count;pipe_index++)
                        {
                            rc=Set_drainage_pipe_colour(
                                drainage_element,
                                pipe_index,
                                link_colour
                            );

                            if(rc==0)
                            {
                                changed_pipes++;
                                element_changed=1;
                            }
                        }
                    }

                    if(element_changed)
                    {
                        undo_item=Add_undo_change(
                            "Change drainage element colours",
                            original_element,
                            drainage_element
                        );

                        Append(undo_item,undo_list);
                        undo_count++;
                    }
                    else
                    {
                        Null(original_element);
                    }

                    Null(drainage_element);
                }

                if(undo_count>0)
                {
                    grouped_undo=Add_undo_list(
                        "Change drainage colours",
                        undo_list
                    );
                }

                Null(undo_list);

                Set_data(
                    cmbMsg,
                    "Changed "
                    +To_text(changed_pits)
                    +" nodes and "
                    +To_text(changed_pipes)
                    +" links. Undo items grouped: "
                    +To_text(undo_count)
                    +". Skipped "
                    +To_text(skipped_elements)
                    +" elements."
                );
            }
        }
        break;

        default:
        {
            if(cmd=="Finish") doit=0;
        }
        break;
        }
    }
}

void main()
{
    mainPanel();
}