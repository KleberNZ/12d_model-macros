/*---------------------------------------------------------------------
**   Programmer:           KLP
**   Date:                 2026-07-27
**   12D Model:            V15
**   Version:              001
**   Macro Name:           Drainage_Network_Framework.4dm
**   Type:                 SOURCE
**
**   Brief description:
**   Reusable drainage-network traversal framework.
**
**---------------------------------------------------------------------
**   Description:
**   Selects one existing drainage model, builds its Drainage_Network,
**   visits every canonical network pit, and classifies directly
**   connected pipes as:
**
**     - same-string upstream pipe;
**     - cross-string incoming pipe;
**     - downstream pipe.
**
**   Check-specific or edit-specific code belongs in the Process_*
**   hook functions. The framework itself is read-only.
**
**---------------------------------------------------------------------
**   Update/Modification
**
**   This macro may be reproduced, modified and used without restriction.
**---------------------------------------------------------------------
*/

#define DEBUG_FILE                  0
#define ECHO_DEBUG_FILE             0
#define ECHO_LINE_NO                0
#define DEBUG_NETWORK_RELATIONSHIPS 0

#define BUILD "15.0.001"

// ----------------------------- INCLUDES -----------------------------
#include "standard_library.H"
#include "size_of.H"

/*global variables*/{


}


// helper: write one complete Output Window line
void Output_line(Text text)
{
    Print(text);
    Print();
}


// ------------------------------------------------------------------
// PROCESSING HOOKS
//
// Replace the bodies of these functions in future QA/editing macros.
// The traversal and relationship classification should remain unchanged.
// ------------------------------------------------------------------

void Process_current_pit(
    Element current_string,
    Integer current_pit_index,
    Integer current_network_pit_id)
{
    // Future pit checks belong here.
}


void Process_same_string_upstream_pipe(
    Element current_string,
    Integer current_pit_index,
    Integer current_network_pit_id,
    Element pipe_string,
    Integer pipe_index,
    Integer network_pipe_id,
    Integer upstream_network_pit_id,
    Integer downstream_network_pit_id)
{
    // Future checks on the normal upstream pipe belong here.
}


void Process_cross_string_incoming_pipe(
    Element current_string,
    Integer current_pit_index,
    Integer current_network_pit_id,
    Element pipe_string,
    Integer pipe_index,
    Integer network_pipe_id,
    Integer upstream_network_pit_id,
    Integer downstream_network_pit_id)
{
    // Future checks on an incoming pipe from another string belong here.
}


void Process_downstream_pipe(
    Element current_string,
    Integer current_pit_index,
    Integer current_network_pit_id,
    Element pipe_string,
    Integer pipe_index,
    Integer network_pipe_id,
    Integer upstream_network_pit_id,
    Integer downstream_network_pit_id)
{
    // Future checks on the downstream pipe belong here.
}


// ------------------------------------------------------------------
// NETWORK TRAVERSAL
// ------------------------------------------------------------------

Integer Traverse_drainage_network(
    Model selected_model)
{
    Drainage_Network drainage_network;

    Integer rc=
        Get_drainage_network(
            selected_model,
            drainage_network);

    if(rc!=0)
    {
        Output_line(
            "ERROR: Get_drainage_network failed. Return: "+
            To_text(rc));

        return rc;
    }

    Integer network_pit_count=0;
    Integer network_pipe_count=0;

    rc=
        Get_drainage_network_number_of_pits(
            drainage_network,
            network_pit_count);

    if(rc!=0)
    {
        Output_line(
            "ERROR: Unable to retrieve network pit count. Return: "+
            To_text(rc));

        return rc;
    }

    rc=
        Get_drainage_network_number_of_pipes(
            drainage_network,
            network_pipe_count);

    if(rc!=0)
    {
        Output_line(
            "ERROR: Unable to retrieve network pipe count. Return: "+
            To_text(rc));

        return rc;
    }

    if(network_pit_count<1)
    {
        Output_line("No network pits were found.");
        return 0;
    }

    Integer network_pit_ids[network_pit_count];
    Integer network_pit_types[network_pit_count];
    Integer returned_pits=0;

    rc=
        Get_drainage_network_pits(
            drainage_network,
            network_pit_ids,
            network_pit_types,
            network_pit_count,
            returned_pits);

    if(rc!=0)
    {
        Output_line(
            "ERROR: Unable to enumerate network pits. Return: "+
            To_text(rc));

        return rc;
    }

    Integer returned_pipes=0;

    if(network_pipe_count>0)
    {
        Integer network_pipe_ids[network_pipe_count];
        Integer network_pipe_types[network_pipe_count];

        rc=
            Get_drainage_network_pipes(
                drainage_network,
                network_pipe_ids,
                network_pipe_types,
                network_pipe_count,
                returned_pipes);

        if(rc!=0)
        {
            Output_line(
                "ERROR: Unable to enumerate network pipes. Return: "+
                To_text(rc));

            return rc;
        }

        Integer pit_number=0;

        for(
            pit_number=1;
            pit_number<=returned_pits;
            pit_number++)
        {
            Integer current_network_pit_id=
                network_pit_ids[pit_number];

            Element current_string;
            Integer current_pit_index=0;

            rc=
                Get_drainage_network_pit(
                    drainage_network,
                    current_network_pit_id,
                    current_string,
                    current_pit_index);

            if(rc!=0)
            {
                Output_line(
                    "WARNING: Unable to resolve network pit ID "+
                    To_text(current_network_pit_id));

                continue;
            }

            Uid current_string_uid;

            rc=
                Get_id(
                    current_string,
                    current_string_uid);

            if(rc!=0)
            {
                Output_line(
                    "WARNING: Unable to retrieve the owning string UID for network pit "+
                    To_text(current_network_pit_id));

                Null(current_string);
                continue;
            }

            Text current_string_name="";
            Text current_pit_name="";

            if(Get_name(current_string,current_string_name)!=0)
            {
                current_string_name="<name unavailable>";
            }

            if(
                Get_drainage_pit_name(
                    current_string,
                    current_pit_index,
                    current_pit_name)!=0)
            {
                current_pit_name="<pit name unavailable>";
            }

            Process_current_pit(
                current_string,
                current_pit_index,
                current_network_pit_id);

            Integer same_string_upstream_count=0;
            Integer cross_string_incoming_count=0;
            Integer downstream_pipe_count=0;
            Integer pipe_number=0;

            if(DEBUG_NETWORK_RELATIONSHIPS)
            {
                Output_line("");
                Output_line(
                    "PIT: "+
                    current_string_name+
                    " / index "+
                    To_text(current_pit_index)+
                    " / "+
                    current_pit_name+
                    " / network ID "+
                    To_text(current_network_pit_id));
            }

            for(
                pipe_number=1;
                pipe_number<=returned_pipes;
                pipe_number++)
            {
                Element pipe_string;

                Integer pipe_index=0;
                Integer upstream_network_pit_id=0;
                Integer downstream_network_pit_id=0;

                rc=
                    Get_drainage_network_pipe(
                        drainage_network,
                        network_pipe_ids[pipe_number],
                        pipe_string,
                        pipe_index,
                        upstream_network_pit_id,
                        downstream_network_pit_id);

                if(rc!=0)
                {
                    continue;
                }

                Uid pipe_string_uid;

                Integer pipe_uid_rc=
                    Get_id(
                        pipe_string,
                        pipe_string_uid);

                Text pipe_string_name="";

                if(Get_name(pipe_string,pipe_string_name)!=0)
                {
                    pipe_string_name="<name unavailable>";
                }

                // A pipe ending at the current pit is directly upstream.
                if(downstream_network_pit_id==current_network_pit_id)
                {
                    Integer same_string_upstream=0;

                    if(
                        pipe_uid_rc==0 &&
                        pipe_string_uid==current_string_uid &&
                        pipe_index==current_pit_index)
                    {
                        same_string_upstream=1;
                    }

                    if(same_string_upstream)
                    {
                        same_string_upstream_count++;

                        Process_same_string_upstream_pipe(
                            current_string,
                            current_pit_index,
                            current_network_pit_id,
                            pipe_string,
                            pipe_index,
                            network_pipe_ids[pipe_number],
                            upstream_network_pit_id,
                            downstream_network_pit_id);

                        if(DEBUG_NETWORK_RELATIONSHIPS)
                        {
                            Output_line(
                                "  UPSTREAM SAME STRING: "+
                                pipe_string_name+
                                " / pipe "+
                                To_text(pipe_index)+
                                " / network pipe "+
                                To_text(network_pipe_ids[pipe_number]));
                        }
                    }
                    else
                    {
                        cross_string_incoming_count++;

                        Process_cross_string_incoming_pipe(
                            current_string,
                            current_pit_index,
                            current_network_pit_id,
                            pipe_string,
                            pipe_index,
                            network_pipe_ids[pipe_number],
                            upstream_network_pit_id,
                            downstream_network_pit_id);

                        if(DEBUG_NETWORK_RELATIONSHIPS)
                        {
                            Output_line(
                                "  INCOMING OTHER STRING: "+
                                pipe_string_name+
                                " / pipe "+
                                To_text(pipe_index)+
                                " / network pipe "+
                                To_text(network_pipe_ids[pipe_number]));
                        }
                    }
                }

                // A pipe starting at the current pit is downstream.
                if(upstream_network_pit_id==current_network_pit_id)
                {
                    downstream_pipe_count++;

                    Process_downstream_pipe(
                        current_string,
                        current_pit_index,
                        current_network_pit_id,
                        pipe_string,
                        pipe_index,
                        network_pipe_ids[pipe_number],
                        upstream_network_pit_id,
                        downstream_network_pit_id);

                    if(DEBUG_NETWORK_RELATIONSHIPS)
                    {
                        Output_line(
                            "  DOWNSTREAM: "+
                            pipe_string_name+
                            " / pipe "+
                            To_text(pipe_index)+
                            " / network pipe "+
                            To_text(network_pipe_ids[pipe_number]));
                    }
                }

                if(pipe_uid_rc==0)
                {
                    Null(pipe_string_uid);
                }

                Null(pipe_string);
            }

            if(DEBUG_NETWORK_RELATIONSHIPS)
            {
                Output_line(
                    "  COUNTS: same-string upstream="+
                    To_text(same_string_upstream_count)+
                    ", cross-string incoming="+
                    To_text(cross_string_incoming_count)+
                    ", all direct upstream="+
                    To_text(
                        same_string_upstream_count+
                        cross_string_incoming_count)+
                    ", downstream="+
                    To_text(downstream_pipe_count));
            }

            Null(current_string_uid);
            Null(current_string);
        }
    }
    else
    {
        Output_line("The drainage network contains no pipes.");
    }

    if(DEBUG_NETWORK_RELATIONSHIPS)
    {
        Output_line("");
        Output_line(
            "NETWORK SUMMARY: pits="+
            To_text(returned_pits)+
            ", pipes="+
            To_text(returned_pipes));
    }

    return 0;
}


// ------------------------------------------------------------------
// PANEL
// ------------------------------------------------------------------

void mainPanel(){

    Text panelName="Drainage Network Framework";
    Panel              panel  = Create_panel              (panelName,TRUE);
    Vertical_Group     vgroup = Create_vertical_group     (-1         );
    Colour_Message_Box cmbMsg = Create_colour_message_box (""         );

    ///////////////////CREATE INPUT WIDGETS////////////////

    Model_Box mb_drainage_model =
        Create_model_box(
            "Drainage model",
            cmbMsg,
            CHECK_MODEL_MUST_EXIST);

    ///////////////ADDING BUTTONS ALONG THE BOTTOM///////////////////////////
    Horizontal_Group bgroup = Create_button_group();
    Button process     = Create_button       ("&Process" ,"process");
    Button finish      = Create_finish_button("Finish"   ,"Finish" );
    Button help_button = Create_help_button  (panel      ,"Help"   );
    Append(process      ,bgroup);
    Append(finish       ,bgroup);
    Append(help_button  ,bgroup);

    ///////////////ADDING WIDGETS TO PANEL///////////////////////////

    Append(mb_drainage_model,vgroup);
    Append(cmbMsg           ,vgroup);
    Append(bgroup           ,vgroup);

    Append(vgroup,panel);
    Show_widget(panel);
    Integer doit = 1;

    while(doit)
    {
        Text cmd="",msg="";
        Integer id,ret=Wait_on_widgets(id,cmd,msg);

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
                //TODO: declare your widget variables

                Model selected_model;
                Text model_name="";
                Integer validate_rc=0;

                //TODO: validate widgets

                validate_rc=
                    Validate(
                        mb_drainage_model,
                        CHECK_MODEL_MUST_EXIST,
                        selected_model);

                if(validate_rc!=MODEL_EXISTS)
                {
                    if(validate_rc==NO_MODEL)
                    {
                        Set_data(
                            cmbMsg,
                            "The selected model does not exist.",
                            2);
                    }
                    else if(validate_rc==NO_NAME)
                    {
                        Set_data(
                            cmbMsg,
                            "Select a drainage model.",
                            2);
                    }
                    else if(validate_rc==0)
                    {
                        Set_data(
                            cmbMsg,
                            "Drastic error validating the model.",
                            2);
                    }
                    else
                    {
                        Set_data(
                            cmbMsg,
                            "Unexpected model validation result: "+
                            To_text(validate_rc),
                            2);
                    }

                    Null(selected_model);
                    continue;
                }

                //TODO: do calc

                if(Get_name(selected_model,model_name)!=0)
                {
                    model_name="<model name unavailable>";
                }

                if(DEBUG_NETWORK_RELATIONSHIPS)
                {
                    Output_line("");
                    Output_line("==================================================");
                    Output_line("MODEL: "+model_name);
                    Output_line("==================================================");
                }

                Integer traversal_rc=
                    Traverse_drainage_network(
                        selected_model);

                if(traversal_rc==0)
                {
                    Set_data(
                        cmbMsg,
                        "Network traversal completed: "+
                        model_name);
                }
                else
                {
                    Set_data(
                        cmbMsg,
                        "Network traversal failed. Return: "+
                        To_text(traversal_rc),
                        2);
                }

                Null(selected_model);
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

    // do some checks before you go to the main panel

    mainPanel();
}
