/*---------------------------------------------------------------------
**   Programmer:KLP
**   Date:26/04/01             
**   12D Model:            V15
**   Version:              001
**   Macro Name:           Set_PC_DS_IL_from_main_panel.4dm
**   Type:                 SOURCE
**
**   Description: Panel macro with 2 model boxes. For each drainage string
**   in the selected SW/WW main model, loop through each pipe (pit-to-pit).
**   For each pipe, find property connection (PC) drainage strings whose
**   downstream point projects onto the main within a tolerance.
**
**   If a match is found, interpolate the main pipe IL at the projected
**   chainage, fetch the main diameter, and set the PC downstream invert to:
**
**      main_IL + 0.5 * main_diameter
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
/*global variables*/{
// USER SETTINGS
// Matching tolerance (m)
Real MATCH_TOL = 0.5;
}

Integer Get_element_model_and_string_ids(Element elt,Uid &model_id,Uid &string_id)
{
    Model m;

    if(Get_id(elt,string_id) != 0) return(1);
    if(Get_model(elt,m) != 0) return(1);
    if(Get_id(m,model_id) != 0) return(1);

    return(0);
}

Text Get_element_log_name(Element elt,Text prefix)
{
    Text name = "";
    Get_name(elt,name);

    if(name == "") return(prefix);
    return(prefix + name);
}

Integer Add_main_group_line(
    Log_Box lb_results,
    Element main_elt,
    Integer log_level,
    Text suffix,
    Log_Line &group_line
)
{
    Text msg = Get_element_log_name(main_elt,"Main: ");
    if(suffix != "") msg = msg + " " + suffix;

    group_line = Create_group_log_line(msg,log_level);
    return(Add_log_line(lb_results,group_line));
}

Integer Append_pc_highlight_line(
    Log_Line parent_line,
    Element pc_elt,
    Integer log_level,
    Text prefix
)
{
    Uid model_id,string_id;
    Text msg = Get_element_log_name(pc_elt,prefix);
    Log_Line line;

    if(Get_element_model_and_string_ids(pc_elt,model_id,string_id) != 0) return(1);

    line = Create_highlight_string_log_line(msg,log_level,model_id,string_id);
    return(Append_log_line(line,parent_line));
}

Integer Append_text_child_line(
    Log_Line parent_line,
    Text msg,
    Integer log_level
)
{
    Log_Line line = Create_text_log_line(msg,log_level);
    return(Append_log_line(line,parent_line));
}

// helper: cache pit chainages for one main string
Integer Get_main_pit_chainages(
    Element main_elt,
    Integer num_pits,
    Real pit_ch[]
)
{
    Integer p = 0;

    for(p = 1; p <= num_pits; p++)
    {
        pit_ch[p] = 0.0;
        if(Get_drainage_pit_attribute(main_elt,p,"pit chainage",pit_ch[p]) != 0)
        {
            return(1);
        }
    }

    return(0);
}
// helper: get PC downstream point and downstream pipe/end from flow
Integer Get_pc_downstream_end_data(
    Element pc_elt,
    Integer &target_pipe,
    Integer &use_rhs,
    Real &dsx,
    Real &dsy,
    Real &dsz
)
{
    Integer dir = 0;
    Integer num_verts = 0;
    Integer max_verts = 200;
    Real x[200], y[200], z[200], r[200];
    Integer f[200];

    if(Get_drainage_flow(pc_elt,dir) != 0) return(1);
    if(Get_drainage_data(pc_elt,x,y,z,r,f,max_verts,num_verts) != 0) return(1);
    if(num_verts < 2) return(1);

    if(dir == 1)
    {
        target_pipe = num_verts - 1;
        use_rhs = 1;
        dsx = x[num_verts];
        dsy = y[num_verts];
        dsz = z[num_verts];
    }
    else
    {
        target_pipe = 1;
        use_rhs = 0;
        dsx = x[1];
        dsy = y[1];
        dsz = z[1];
    }

    return(0);
}

// helper: get current main pipe data using pit-based logic p to p+1
Integer Get_main_pipe_range_data(
    Element main_elt,
    Integer pipe_no,
    Real &ch_us,
    Real &ch_ds,
    Real &ch_min,
    Real &ch_max,
    Real &il_us,
    Real &il_ds,
    Real &pipe_dia
)
{
    ch_us = 0.0;
    ch_ds = 0.0;
    ch_min = 0.0;
    ch_max = 0.0;
    il_us = 0.0;
    il_ds = 0.0;
    pipe_dia = 0.0;

    if(Get_drainage_pit_attribute(main_elt,pipe_no,"pit chainage",ch_us) != 0) return(1);
    if(Get_drainage_pit_attribute(main_elt,pipe_no + 1,"pit chainage",ch_ds) != 0) return(1);
    if(Get_drainage_pipe_inverts(main_elt,pipe_no,il_us,il_ds) != 0) return(1);
    if(Get_drainage_pipe_diameter(main_elt,pipe_no,pipe_dia) != 0) return(1);

    ch_min = ch_us;
    ch_max = ch_ds;
    if(ch_min > ch_max)
    {
        Real tmp = ch_min;
        ch_min = ch_max;
        ch_max = tmp;
    }

    return(0);
}

// helper: find main pipe at chainage using pit chainage attribute
Integer Get_main_pipe_data_at_chainage(
    Element drain,
    Real ch,
    Integer &pipe_no,
    Real &pipe_il,
    Real &pipe_dia
)
{
    Integer num_verts = 0;
    Integer max_verts = 200;
    Real x[200], y[200], z[200], r[200];
    Integer b[200];

    Integer pipe_count = 0;
    Integer p = 0;

    Real ch_us = 0.0;
    Real ch_ds = 0.0;
    Real ch_min = 0.0;
    Real ch_max = 0.0;

    Real ratio = 0.0;
    Real lhs = 0.0;
    Real rhs = 0.0;

    pipe_no = 0;
    pipe_il = 0.0;
    pipe_dia = 0.0;

    if(Get_drainage_data(drain,x,y,z,r,b,max_verts,num_verts) != 0) return(1);
    if(num_verts < 2) return(1);

    pipe_count = num_verts - 1;
    if(pipe_count < 1) return(1);

    for(p = 1; p <= pipe_count; p++)
    {
        if(Get_drainage_pit_attribute(drain,p,"pit chainage",ch_us) != 0)
        {
            continue;
        }

        if(Get_drainage_pit_attribute(drain,p + 1,"pit chainage",ch_ds) != 0)
        {
            continue;
        }

        ch_min = ch_us;
        ch_max = ch_ds;
        if(ch_min > ch_max)
        {
            Real tmp = ch_min;
            ch_min = ch_max;
            ch_max = tmp;
        }

        if((ch >= ch_min && ch <= ch_max) || p == pipe_count)
        {
            if(Get_drainage_pipe_inverts(drain,p,lhs,rhs) != 0)
            {
                continue;
            }

            if(Get_drainage_pipe_diameter(drain,p,pipe_dia) != 0)
            {
                continue;
            }

            if(Absolute(ch_ds - ch_us) > 0.0)
            {
                ratio = (ch - ch_us) / (ch_ds - ch_us);
            }
            else
            {
                ratio = 0.0;
            }

            if(ratio < 0.0) ratio = 0.0;
            if(ratio > 1.0) ratio = 1.0;

            pipe_il = lhs + ratio * (rhs - lhs);
            pipe_no = p;

            return(0);
        }
    }

    return(1);
}

// helper: interpolate main IL and update matched PC downstream end
Integer Apply_pc_ds_il_update(
    Element main_elt,
    Integer main_pipe,
    Real ch_us,
    Real ch_ds,
    Real il_us,
    Real il_ds,
    Real main_dia,
    Real proj_ch,
    Element pc_elt,
    Integer pc_pipe,
    Integer use_rhs
)
{
    Real main_il = 0.0;
    Real new_il = 0.0;
    Real frac = 0.0;
    Real pc_lhs = 0.0;
    Real pc_rhs = 0.0;
    Real denom = 0.0;

    denom = ch_ds - ch_us;
    if(Absolute(denom) < 0.000001) return(1);

    frac = (proj_ch - ch_us) / denom;
    main_il = il_us + frac * (il_ds - il_us);
    new_il = main_il + 0.5 * main_dia;

    if(Get_drainage_pipe_inverts(pc_elt,pc_pipe,pc_lhs,pc_rhs) != 0) return(1);

    if(use_rhs != 0)
    {
        pc_rhs = new_il;
    }
    else
    {
        pc_lhs = new_il;
    }

    Integer rc1 = Set_drainage_pipe_inverts(pc_elt,pc_pipe,pc_lhs,pc_rhs);
    Integer rc2 = 0;

    if(rc1 != 0) return(1);

    rc2 = Set_drainage_pipe_attribute(pc_elt,pc_pipe,"lock ds il",1);

    if(rc2 != 0) return(1);

    return(0);
}

void mainPanel(){

    Text panelName="Set Property Connection DS Invert From Main";
    Panel              panel  = Create_panel              (panelName,TRUE);
    Vertical_Group     vgroup = Create_vertical_group     (-1         );
    Colour_Message_Box cmbMsg = Create_colour_message_box (""         );

    ///////////////////CREATE INPUT WIDGETS////////////////
    Model_Box mb_prop = Create_model_box("PC Drainage Model",cmbMsg,7);
    Model_Box mb_main = Create_model_box("Main Drainage Model"        ,cmbMsg,7);
    Log_Box lb_results = Create_log_box("Results",400,100);

    ///////////////ADDING BUTTONS ALONG THE BOTTOM///////////////////////////
    Horizontal_Group bgroup = Create_button_group();
    Button process     = Create_button       ("&Process" ,"process");
    Button finish      = Create_finish_button("Finish"   ,"Finish" );
    Button help_button = Create_help_button  (panel      ,"Help"   );
    Append(process      ,bgroup);
    Append(finish       ,bgroup);
    Append(help_button  ,bgroup);

    ///////////////ADDING WIDGETS TO PANEL///////////////////////////
    Append(mb_main   ,vgroup);
    Append(mb_prop   ,vgroup);
    Append(lb_results,vgroup);
    Append(cmbMsg    ,vgroup);
    Append(bgroup    ,vgroup);

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
                // TODO: do calc
                Clear(lb_results);
                Text prop_model_name = "";
                Text main_model_name = "";

                Get_data(mb_prop,prop_model_name);
                Get_data(mb_main,main_model_name);

                Model prop_model = Get_model(prop_model_name);
                Model main_model = Get_model(main_model_name);

                Dynamic_Element prop_list;
                Dynamic_Element main_list;

                Integer prop_count = 0;
                Integer main_count = 0;

                if(Get_elements(prop_model,prop_list,prop_count) != 0)
                {
                    Set_data(cmbMsg,"Failed to get property connection elements");
                    continue;
                }

                if(Get_elements(main_model,main_list,main_count) != 0)
                {
                    Set_data(cmbMsg,"Failed to get main elements");
                    continue;
                }

                if(prop_count < 1)
                {
                    Set_data(cmbMsg,"No property connection elements found");
                    continue;
                }

                if(main_count < 1)
                {
                    Set_data(cmbMsg,"No main elements found");
                    continue;
                }

                Real tol = MATCH_TOL;

                // 1-based flags aligned to prop_list
                Integer pc_done[10000];
                Integer i = 0;
                for(i = 1; i <= 10000; i++) pc_done[i] = 0;

                Integer main_i = 0;
                for(main_i = 1; main_i <= main_count; main_i++)
                {
                    Element main_elt;
                    Text main_type = "";
                    Integer main_dir = 0;
                    Integer pipe_count = 0;
                    Integer main_match_count = 0;
                    Dynamic_Element matched_pcs;
                    Integer matched_pc_count = 0;

                    Integer num_pts = 0;
                    Integer max_pts = 500;
                    Real mx[500], my[500], mz[500], mr[500];
                    Integer mf[500];

                    Real pit_ch[500];

                    if(Get_item(main_list,main_i,main_elt) != 0) continue;
                    if(Get_type(main_elt,main_type) != 0) continue;
                    
                    if(main_type != "Drainage")
                    {
                        Log_Line err_group;
                        Add_main_group_line(lb_results,main_elt,3,"[ERROR: not Drainage]",err_group);
                        continue;
                    }

                    if(Get_drainage_flow(main_elt,main_dir) != 0) continue;

                    if(Get_drainage_data(main_elt,mx,my,mz,mr,mf,max_pts,num_pts) != 0) continue;
                    if(num_pts < 2) continue;

                    if(Get_main_pit_chainages(main_elt,num_pts,pit_ch) != 0) continue;

                    pipe_count = num_pts - 1;

                    Integer p = 0;
                    for(p = 1; p <= pipe_count; p++)
                    {
                        Real ch_us = 0.0;
                        Real ch_ds = 0.0;
                        Real ch_min = 0.0;
                        Real ch_max = 0.0;
                        Real il_us = 0.0;
                        Real il_ds = 0.0;
                        Real main_dia = 0.0;

                        ch_us = pit_ch[p];
                        ch_ds = pit_ch[p + 1];

                        if(Get_drainage_pipe_inverts(main_elt,p,il_us,il_ds) != 0) continue;
                        if(Get_drainage_pipe_diameter(main_elt,p,main_dia) != 0) continue;

                        ch_min = ch_us;
                        ch_max = ch_ds;
                        if(ch_min > ch_max)
                        {
                            Real tmp = ch_min;
                            ch_min = ch_max;
                            ch_max = tmp;
                        }

                        Integer pc_i = 0;
                        for(pc_i = 1; pc_i <= prop_count; pc_i++)
                        {
                            Element pc_elt;
                            Text pc_type = "";

                            Integer target_pipe = 0;
                            Integer use_rhs = 0;

                            Real dsx = 0.0;
                            Real dsy = 0.0;
                            Real dsz = 0.0;

                            Real xf = 0.0;
                            Real yf = 0.0;
                            Real zf = 0.0;
                            Real proj_ch = 0.0;
                            Real proj_dir = 0.0;
                            Real off = 0.0;

                            if(pc_done[pc_i] != 0) continue;

                            if(Get_item(prop_list,pc_i,pc_elt) != 0) continue;
                            if(Get_type(pc_elt,pc_type) != 0) continue;
                            if(pc_type != "Drainage") continue;

                            if(Get_pc_downstream_end_data(pc_elt,target_pipe,use_rhs,dsx,dsy,dsz) != 0)
                            {
                                continue;
                            }

                            if(Drop_point(main_elt,dsx,dsy,dsz,xf,yf,zf,proj_ch,proj_dir,off) != 0)
                            {
                                continue;
                            }

                            if(Absolute(off) > tol)
                            {
                                continue;
                            }

                            if(proj_ch < ch_min || proj_ch > ch_max)
                            {
                                continue;
                            }

                            if(Apply_pc_ds_il_update(main_elt,p,ch_us,ch_ds,il_us,il_ds,main_dia,proj_ch,pc_elt,target_pipe,use_rhs) == 0)
                            {
                                pc_done[pc_i] = 1;
                                main_match_count++;

                                Append(pc_elt,matched_pcs);
                                matched_pc_count++;
                            }
                            
                        }
                    }
                    {
                    Log_Line main_group;

                        if(main_match_count > 0)
                        {
                            Integer k = 0;

                            Add_main_group_line(lb_results,main_elt,1,"",main_group);

                            for(k = 1; k <= matched_pc_count; k++)
                            {
                                Element matched_pc;
                                if(Get_item(matched_pcs,k,matched_pc) != 0) continue;

                                Append_pc_highlight_line(main_group,matched_pc,1,"Updated: ");
                            }
                        }
                        else
                        {
                            Add_main_group_line(lb_results,main_elt,2,"",main_group);
                            Append_text_child_line(main_group,"No PC strings intersected this main",2);
                        }
                    }
                }

                Set_data(cmbMsg,"Process finished");
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
