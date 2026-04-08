/*---------------------------------------------------------------------
**   Programmer:user_name
**   Date:26/04/08             
**   12D Model:            Vversion
**   Version:              001
**   Macro Name:           Label_height_between_2_SA_panel.4dm
**   Type:                 SOURCE
**
**   Brief description: BriefDescription
**
**
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
#include "..\\..\\include/standard_library.H"
#include "..\\..\\include/size_of.H"

/*global variables*/{


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

    Real_Box rb_precision = Create_real_box("Precision",cmbMsg);
    Set_default_data(rb_precision,3.0);

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
    Append(rb_precision      ,vgroup);
    Append(tsdb_text         ,vgroup);

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
                //TODO: declare your widget variables
                Dynamic_Element sa_elements;
                Text top_suffix = "";
                Text bottom_suffix = "";
                Model output_model;
                Real precision = 0.0;
                Integer rc = 0;
                Integer ok = 1;
                Integer no_elts = 0;
                Textstyle_Data ts_data;
                Dynamic_Element created_labels;
                Undo_List undo_list;
                Integer created_label_count = 0;


                //TODO: validate widgets
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
                    rc = Validate(rb_precision,precision);   // success = 0 on error
                    if(rc == 0)
                    {
                        Set_data(cmbMsg,"Please enter a valid precision");
                        ok = 0;
                    }
                    else
                    {
                        if(precision < 0.0) 
                        {
                            Set_data(cmbMsg,"Precision must be zero or greater");
                            ok = 0;
                        }
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

                //TODO: do calc
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

                            // Print("Matched pair found:");
                            // Print("  SA1 = " + sa1_name);
                            // Print("  SA2 = " + sa2_name);
                            // Print();

                            Real sa1_len = 0.0;
                            Real sa2_len = 0.0;
                            Real shorter_len = 0.0;
                            Real ch = 0.0;

                            Element sa1_horz;
                            Real x = 0.0, y = 0.0, z = 0.0, dir = 0.0;
                            Real level1 = 0.0, grade1 = 0.0, mvalue1 = 0.0;
                            Real level2 = 0.0, grade2 = 0.0, mvalue2 = 0.0;
                            Real diff = 0.0;

                            Integer decimals = precision;
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
                                // Print("Get_colour(ts_data) failed rc=" + To_text(rc));
                                break;
                            }

                            rc = Get_text_type(ts_data,text_type);
                            if(rc != 0)
                            {
                                // Print("Get_text_type(ts_data) failed rc=" + To_text(rc));
                                break;
                            }

                            rc = Get_size(ts_data,text_size);
                            if(rc != 0)
                            {
                                // Print("Get_size(ts_data) failed rc=" + To_text(rc));
                                break;
                            }

                            rc = Get_offset(ts_data,text_offset);
                            if(rc != 0)
                            {
                                // Print("Get_offset(ts_data) failed rc=" + To_text(rc));
                                break;
                            }

                            rc = Get_raise(ts_data,text_rise);
                            if(rc != 0)
                            {
                                // Print("Get_raise(ts_data) failed rc=" + To_text(rc));
                                break;
                            }

                            rc = Get_justify(ts_data,text_just);
                            if(rc != 0)
                            {
                                // Print("Get_justify(ts_data) failed rc=" + To_text(rc));
                                break;
                            }

                            Text output_model_name = "";
                            Integer labels_created = 0;
                            Element txt;

                            rc = Get_length(sa1,sa1_len);
                            if(rc != 0)
                            {
                                // Print("Get_length(sa1) failed rc=" + To_text(rc));
                                break;
                            }

                            rc = Get_length(sa2,sa2_len);
                            if(rc != 0)
                            {
                                // Print("Get_length(sa2) failed rc=" + To_text(rc));
                                break;
                            }

                            shorter_len = sa1_len;
                            if(sa2_len < shorter_len) shorter_len = sa2_len;

                            sa1_horz = Get_super_alignment_horizontal_string(sa1);

                            rc = Get_data(mb_output,output_model_name);
                            if(rc != 0 || output_model_name == "")
                            {
                                // Print("Get_data(mb_output) failedXXX rc=" + To_text(rc));
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

                            for(ch = 0.0; ch <= shorter_len; ch += 10.0)
                            {
                                rc = Get_super_alignment_vertical_position(sa1,ch,level1,grade1,mvalue1);
                                if(rc != 0)
                                {
                                    Print("Get_super_alignment_vertical_position(sa1) failed ch=" + To_text(ch,3) + " rc=" + To_text(rc));
                                    continue;
                                }

                                rc = Get_super_alignment_vertical_position(sa2,ch,level2,grade2,mvalue2);
                                if(rc != 0)
                                {
                                    Print("Get_super_alignment_vertical_position(sa2) failed ch=" + To_text(ch,3) + " rc=" + To_text(rc));
                                    continue;
                                }

                                rc = Get_position(sa1_horz,ch,x,y,z,dir);
                                if(rc != 0)
                                {
                                    Print("Get_position(sa1_horz) failed ch=" + To_text(ch,3) + " rc=" + To_text(rc));
                                    continue;
                                }

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
                                if(rc != 0)
                                {
                                    // Print("Set_model failed ch=" + To_text(ch,3) + " rc=" + To_text(rc));
                                    continue;
                                }
                                rc = Append(txt,created_labels);
                                if(rc != 0)
                                {
                                    // Print("Append(created label) failed ch=" + To_text(ch,3) + " rc=" + To_text(rc));
                                    continue;
                                }

                                created_label_count++;
                                labels_created++;
                            }

                            Print("Labels created = " + To_text(labels_created));
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