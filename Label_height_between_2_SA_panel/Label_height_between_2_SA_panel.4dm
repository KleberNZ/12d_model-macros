/*---------------------------------------------------------------------
**   Programmer:KLP
**   Date:28/04/08             
**   12D Model:            V15
**   Version:              001
**   Macro Name:           Label_height_between_2_SA_panel.4dm
**   Type:                 LABEL
**
**   Brief description: 
**   Labels height differences between matched Super Alignment pairs
**   at user-defined chainage intervals, with optional maximum
**   difference detection.
**
**---------------------------------------------------------------------
**   Description: 
**   This macro selects multiple Super Alignments and matches them
**   into pairs based on naming suffixes (e.g. TOP/BOTTOM). It computes
**   vertical height differences (SA1 - SA2) along the alignment at
**   specified chainage intervals and places labels perpendicular to
**   the alignment using a chosen text style and output model.
**
**   An optional feature identifies the maximum height difference for
**   each pair using an internal resolution of 0.01m (variable step_size).
**   The maximum value is labelled once per pair (avoiding duplication
**   with regular interval labels) and reported in the Output Window
**   along with its chainage.
**
**   Additional features include optional endpoint labelling, grouped
**   undo support, and runtime reporting for performance comparison.
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
#define step_size 0.01

}
// ----------------------------- HELPERS -----------------------------
Integer create_label_text_at_chainage(
    Element sa1_horz,
    Real ch,
    Text label_text,
    Model output_model,
    Integer text_colour,
    Real text_size,
    Integer text_just,
    Integer text_type,
    Real text_offset,
    Real text_rise,
    Dynamic_Element &created_labels
)
{
    Integer rc = 0;
    Real x = 0.0, y = 0.0, z = 0.0, dir = 0.0;
    Real text_angle = 0.0;
    Element txt;

    rc = Get_position(sa1_horz,ch,x,y,z,dir);
    if(rc != 0) return(0);

    text_angle = dir + Pi()/2.0;

    if(text_angle > Pi()) text_angle -= Pi();

    if(text_angle > Pi()/2.0)
    {
        text_angle -= Pi();
    }
    else if(text_angle < -Pi()/2.0)
    {
        text_angle += Pi();
    }

    txt = Create_text(label_text,
                      x,y,text_size,text_colour,text_angle,
                      text_just,text_type,text_offset,text_rise);

    rc = Set_model(txt,output_model);
    if(rc != 0) return(0);

    rc = Append(txt,created_labels);
    if(rc != 0) return(0);

    return(1);
}

Integer create_label_at_chainage(
    Element sa1,
    Element sa2,
    Element sa1_horz,
    Real ch,
    Model output_model,
    Integer decimals,
    Integer text_colour,
    Real text_size,
    Integer text_just,
    Integer text_type,
    Real text_offset,
    Real text_rise,
    Dynamic_Element &created_labels
)
{
    Integer rc = 0;
    Real x = 0.0, y = 0.0, z = 0.0, dir = 0.0;
    Real level1 = 0.0, grade1 = 0.0, mvalue1 = 0.0;
    Real level2 = 0.0, grade2 = 0.0, mvalue2 = 0.0;
    Real diff = 0.0;
    Real text_angle = 0.0;
    Element txt;

    rc = Get_super_alignment_vertical_position(sa1,ch,level1,grade1,mvalue1);
    if(rc != 0) return(0);

    rc = Get_super_alignment_vertical_position(sa2,ch,level2,grade2,mvalue2);
    if(rc != 0) return(0);

    rc = Get_position(sa1_horz,ch,x,y,z,dir);
    if(rc != 0) return(0);

    text_angle = dir + Pi()/2.0;

    if(text_angle > Pi()) text_angle -= Pi();

    if(text_angle > Pi()/2.0)
    {
        text_angle -= Pi();
    }
    else if(text_angle < -Pi()/2.0)
    {
        text_angle += Pi();
    }

    diff = level1 - level2;

    txt = Create_text("HT=" + To_text(diff,decimals) + "m",
                      x,y,text_size,text_colour,text_angle,
                      text_just,text_type,text_offset,text_rise);

    rc = Set_model(txt,output_model);
    if(rc != 0) return(0);

    rc = Append(txt,created_labels);
    if(rc != 0) return(0);

    return(1);
}

Integer find_max_abs_height_diff(
    Element sa1,
    Element sa2,
    Real &max_ch,
    Real &max_diff
)
{
    Real len1 = 0.0, len2 = 0.0;
    Real end_ch = 0.0;
    Real ch = 0.0;
    Real h1 = 0.0, g1 = 0.0, m1 = 0.0;
    Real h2 = 0.0, g2 = 0.0, m2 = 0.0;
    Real diff = 0.0;

    if(Get_length(sa1,len1)) return 1;
    if(Get_length(sa2,len2)) return 1;

    end_ch = len1;
    if(len2 < end_ch) end_ch = len2;

    max_ch = 0.0;
    max_diff = -1.0;

    for(ch = 0.0; ch <= end_ch; ch += step_size)
    {
        if(Get_super_alignment_vertical_position(sa1,ch,h1,g1,m1)) continue;
        if(Get_super_alignment_vertical_position(sa2,ch,h2,g2,m2)) continue;

        diff = Absolute(h1 - h2);

        if(diff > max_diff)
        {
            max_diff = diff;
            max_ch = ch;
        }
    }

    return 0;
}

Integer is_chainage_on_regular_interval(
    Real test_ch,
    Real interval,
    Real tolerance
)
{
    Real n = 0.0;
    Real nearest_ch = 0.0;

    if(interval <= 0.0) return 0;

    n = Floor((test_ch / interval) + 0.5);
    nearest_ch = n * interval;

    if(Absolute(test_ch - nearest_ch) <= tolerance) return 1;

    return 0;
}

void mainPanel(){
 
    Text panelName="SA Height Difference Labels";
    Panel              panel  = Create_panel              (panelName,TRUE);
    Vertical_Group     vgroup = Create_vertical_group     (-1         );
    Colour_Message_Box cmbMsg = Create_colour_message_box (""         );

    ///////////////////CREATE INPUT WIDGETS////////////////
    Source_Box sb_source = Create_source_box("Super alignment source",cmbMsg,Source_Box_Standard);

    Input_Box ipb_top_suffix = Create_input_box("SA1 suffix",cmbMsg);
    Set_default_data(ipb_top_suffix,"TOP");

    Input_Box ipb_bottom_suffix = Create_input_box("SA2 suffix",cmbMsg);
    Set_default_data(ipb_bottom_suffix,"BOTTOM");

    Model_Box mb_output = Create_model_box("Output model",cmbMsg,CHECK_MODEL_CREATE);

    Integer_Box ib_precision = Create_integer_box("Precision",cmbMsg);
    Set_data(ib_precision,3);

    Real_Box rb_interval = Create_real_box("Chainage interval",cmbMsg);
    Set_default_data(rb_interval,10.0);

    Named_Tick_Box ntb_include_end = Create_named_tick_box("Regular intervals plus end point",1,"toggle include endpoint");
    Named_Tick_Box ntb_include_max = Create_named_tick_box("Include maximum height difference",1,"toggle include maximum height difference");

    Integer ts_flags = Show_all_boxes;

    Textstyle_Data_Box tsdb_text = Create_textstyle_data_box("Text parameters",cmbMsg,Show_std_boxes,0);
    
    ///////////////ADDING BUTTONS ALONG THE BOTTOM///////////////////////////
    Horizontal_Group bgroup = Create_button_group();
    Button process     = Create_button       ("&Process" ,"process");
    Button finish      = Create_finish_button("Finish"   ,"Finish" );
    Button help_button = Create_help_button  (panel      ,"Help"   );
    Append(process      ,bgroup);
    Append(finish       ,bgroup);
    Append(help_button  ,bgroup);
    ///////////////ADDING WIDGETS TO PANEL///////////////////////////
    Append(sb_source         ,vgroup);
    Append(ipb_top_suffix    ,vgroup);
    Append(ipb_bottom_suffix ,vgroup);
    Append(mb_output         ,vgroup);
    Append(ib_precision      ,vgroup);
    Append(tsdb_text         ,vgroup);
    Append(rb_interval      ,vgroup);
    Append(ntb_include_end   ,vgroup);
    Append(ntb_include_max,vgroup);

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
                // declare your widget variables
                Dynamic_Element sa_elements;
                Text top_suffix = "";
                Text bottom_suffix = "";
                Model output_model;
                Integer rc = 0;
                Integer ok = 1;
                Integer no_elts = 0;
                Textstyle_Data ts_data;
                Dynamic_Element created_labels;
                Undo_List undo_list;
                Integer created_label_count = 0;
                Real chainage_interval = 10.0;
                Integer include_end_point = 1;
                Integer do_max = 0;
                Integer decimals = 3;

                // declare your widget variables
                rc = Validate(sb_source,sa_elements);   // success = 1
                if(rc != 1)
                {
                    Set_data(cmbMsg,"Please select super alignments in the source box");
                    ok = 0;
                }

                if(ok)
                {
                    rc = Get_number_of_items(sa_elements,no_elts);   // success = 0
                    if(rc != 0 || no_elts < 2)
                    {
                        Set_data(cmbMsg,"Please select at least 2 super alignments");
                        ok = 0;
                    }
                }

                if(ok)
                {
                    rc = Validate(ipb_top_suffix,top_suffix);   // success = 1
                    if(rc == 0 || top_suffix == "")
                    {
                        Set_data(cmbMsg,"Top suffix is required");
                        ok = 0;
                    }
                }

                if(ok)
                {
                    rc = Validate(ipb_bottom_suffix,bottom_suffix);   // success = 1
                    if(rc == 0 || bottom_suffix == "")
                    {
                        Set_data(cmbMsg,"Bottom suffix is required");
                        ok = 0;
                    }
                }

                if(ok)
                {
                    if(top_suffix == bottom_suffix)
                    {
                        Set_data(cmbMsg,"Top and bottom suffixes must be different");
                        ok = 0;
                    }
                }

                if(ok)
                {
                    rc = Validate(mb_output,CHECK_MODEL_CREATE,output_model);

                    if(rc == 0)
                    {
                        Set_data(cmbMsg,"Drastic error validating output model");
                        ok = 0;
                    }
                    else if(rc == NO_NAME)
                    {
                        Set_data(cmbMsg,"Please enter an output model");
                        ok = 0;
                    }
                    else if(rc == MODEL_EXISTS)
                    {
                        // valid
                    }
                    else if(rc == NO_MODEL)
                    {
                        // valid: model will be created
                    }
                    else
                    {
                        Set_data(cmbMsg,"Invalid output model");
                        ok = 0;
                    }
                }


                if(ok)
                {
                    rc = Validate(ib_precision, decimals);

                    if(rc == 0)
                    {
                        Set_data(cmbMsg,"Precision validation failed");
                        ok = 0;
                    }

                    if(ok && decimals < 0)
                    {
                        Set_data(cmbMsg,"Precision must be 0 or greater");
                        ok = 0;
                    }
                }

                if(ok)
                {
                    Text chainage_interval_text = "";

                    rc = Get_data(rb_interval,chainage_interval_text);

                    if(rc != 0 || chainage_interval_text == "")
                    {
                        Set_data(cmbMsg,"Please enter a chainage interval");
                        ok = 0;
                    }
                    else
                    {
                        rc = From_text(chainage_interval_text,chainage_interval);

                        if(rc != 0)
                        {
                            Set_data(cmbMsg,"Invalid chainage interval");
                            ok = 0;
                        }
                        else if(chainage_interval <= 0.0)
                        {
                            Set_data(cmbMsg,"Chainage interval must be greater than zero");
                            ok = 0;
                        }
                    }

                }

                if(ok)
                {
                    rc = Validate(ntb_include_end,include_end_point);

                    if(rc == 0)
                    {
                        Set_data(cmbMsg,"Endpoint option validation failed");
                        ok = 0;
                    }
                }

                if(ok)
                {
                    rc = Validate(ntb_include_max,do_max);

                    if(rc == 0)
                    {
                        Set_data(cmbMsg,"Maximum height difference option validation failed");
                        ok = 0;
                    }
                }

                if(ok)
                {
                    rc = Validate(tsdb_text,ts_data);   // success = 1, error = 0
                    if(rc == 0)
                    {
                        Set_data(cmbMsg,"Please enter valid text parameters");
                        ok = 0;
                    }
                }
                if(!ok)
                {
                    continue;
                }

                // declare your calculation variables

                Print("===== SA Height Difference Labels Macro =====\n");
                Integer i,j;
                Integer matched_pairs = 0;
                Integer top_suffix_len = Text_length(top_suffix);
                Integer bottom_suffix_len = Text_length(bottom_suffix);

                for(i = 1; i <= no_elts; i++)
                {
                    Element sa1;
                    Text sa1_name = "";
                    Integer pos_top = 0;
                    Integer sa1_name_len = 0;
                    Text base_name = "";

                    rc = Get_item(sa_elements,i,sa1);
                    if(rc != 0) continue;

                    rc = Get_name(sa1,sa1_name);
                    if(rc != 0) continue;

                    sa1_name_len = Text_length(sa1_name);
                    pos_top = Find_text(sa1_name,top_suffix);

                    if(pos_top <= 0) continue;
                    if(pos_top != sa1_name_len - top_suffix_len + 1) continue;

                    base_name = Get_subtext(sa1_name,1,pos_top - 1);

                    for(j = 1; j <= no_elts; j++)
                    {
                        Element sa2;
                        Text sa2_name = "";
                        Text expected_bottom_name = base_name + bottom_suffix;

                        if(i == j) continue;

                        rc = Get_item(sa_elements,j,sa2);
                        if(rc != 0) continue;

                        rc = Get_name(sa2,sa2_name);
                        if(rc != 0) continue;

                         if(sa2_name == expected_bottom_name)
                        {
                            matched_pairs++;

                            Real sa1_len = 0.0;
                            Real sa2_len = 0.0;
                            Real shorter_len = 0.0;
                            Real ch = 0.0;

                            Element sa1_horz;
                            Real x = 0.0, y = 0.0, z = 0.0, dir = 0.0;
                            Real level1 = 0.0, grade1 = 0.0, mvalue1 = 0.0;
                            Real level2 = 0.0, grade2 = 0.0, mvalue2 = 0.0;
                            Real diff = 0.0;

                            Integer text_colour = 0;
                            Real text_size = 1.0;
                            Real text_angle = 0.0;
                            Integer text_just = 0;
                            Integer text_type = 0;
                            Real text_offset = 0.0;
                            Real text_rise = 0.0;

                            rc = Get_colour(ts_data,text_colour);
                            if(rc != 0)
                            {
                                break;
                            }

                            rc = Get_text_type(ts_data,text_type);
                            if(rc != 0)
                            {
                                break;
                            }

                            rc = Get_size(ts_data,text_size);
                            if(rc != 0)
                            {
                                break;
                            }

                            rc = Get_offset(ts_data,text_offset);
                            if(rc != 0)
                            {
                                break;
                            }

                            rc = Get_raise(ts_data,text_rise);
                            if(rc != 0)
                            {
                                break;
                            }

                            rc = Get_justify(ts_data,text_just);
                            if(rc != 0)
                            {
                                break;
                            }

                            Text output_model_name = "";
                            Integer labels_created = 0;
                            Element txt;

                            rc = Get_length(sa1,sa1_len);
                            if(rc != 0)
                            {
                                break;
                            }

                            rc = Get_length(sa2,sa2_len);
                            if(rc != 0)
                            {
                                break;
                            }

                            shorter_len = sa1_len;
                            if(sa2_len < shorter_len) shorter_len = sa2_len;

                            sa1_horz = Get_super_alignment_horizontal_string(sa1);

                            rc = Get_data(mb_output,output_model_name);
                            if(rc != 0 || output_model_name == "")
                            {
                                break;
                            }

                            if(Model_exists(output_model_name) == 0)
                            {
                                output_model = Create_model(output_model_name);
                            }
                            else
                            {
                                output_model = Get_model(output_model_name);
                            }

                            if(Model_exists(output_model) != 1)
                            {
                                Set_data(cmbMsg,"Could not create/get output model");
                                break;
                            }

                            Real last_regular_ch = -999999.0;

                            for(ch = 0.0; ch <= shorter_len; ch += chainage_interval)
                            {
                                last_regular_ch = ch;

                                if(create_label_at_chainage(sa1,sa2,sa1_horz,ch,
                                                           output_model,decimals,
                                                           text_colour,text_size,
                                                           text_just,text_type,
                                                           text_offset,text_rise,
                                                           created_labels))
                                {
                                    created_label_count++;
                                    labels_created++;
                                }
                            }

                            if(include_end_point && Absolute(last_regular_ch - shorter_len) > 0.001)
                            {
                                ch = shorter_len;

                                if(create_label_at_chainage(sa1,sa2,sa1_horz,ch,
                                                           output_model,decimals,
                                                           text_colour,text_size,
                                                           text_just,text_type,
                                                           text_offset,text_rise,
                                                           created_labels))
                                {
                                    created_label_count++;
                                    labels_created++;
                                }
                            }

                            if(do_max)
                            {
                                Real max_ch = 0.0;
                                Real max_diff = 0.0;

                                if(find_max_abs_height_diff(sa1,sa2,max_ch,max_diff) == 0)
                                {
                                    Integer max_is_duplicate = is_chainage_on_regular_interval(max_ch,chainage_interval,0.001);

                                    Print("Labelling SA " + base_name);
                                    Print("Max height difference = " + To_text(max_diff,decimals) + "m at chainage " + To_text(max_ch,decimals) + "m\n");

                                    if(max_is_duplicate == 0)
                                    {
                                        Text max_label = "HT=" + To_text(max_diff,decimals) + "m (MAX)";
                                        if(create_label_text_at_chainage(sa1_horz,max_ch,max_label,
                                                                        output_model,
                                                                        text_colour,text_size,
                                                                        text_just,text_type,
                                                                        text_offset,text_rise,
                                                                        created_labels))
                                        {
                                            created_label_count++;
                                            labels_created++;
                                        }
                                    }
                                }
                            }
                            break;
                        }
                    }
                }

                if(matched_pairs == 0)
                {
                    Set_data(cmbMsg,"No matching SA pairs found");
                    continue;
                }
                
                if(created_label_count > 0)
                {
                    Undo undo_added_labels;
                    undo_added_labels = Add_undo_add("created labels",created_labels);

                    rc = Append(undo_added_labels,undo_list);
                    if(rc != 0)
                    {
                        Set_data(cmbMsg,"Undo creation failed");
                        continue;
                    }

                    Add_undo_list("Label SA height differences",undo_list);
                }
                Set_data(cmbMsg,"Matched pairs: " + To_text(matched_pairs) + "  Labels created: " + To_text(created_label_count));
                
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