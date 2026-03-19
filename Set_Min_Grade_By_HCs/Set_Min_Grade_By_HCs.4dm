/*---------------------------------------------------------------------
**   Programmer:KLP
**   Date:11/02/26             
**   12D Model:            V15
**   Version:              002
**   Macro Name:           Drainage_Adjust_Grade_By_HCs.4dm
**   Type:                 SOURCE
**
**   Brief description: Adjust drainage pipe grades based on house connections
**
**---------------------------------------------------------------------
**   Description:
**   This macro sets the minimum design grade of drainage pipe
**   based on the cumulative number of upstream property/house
**   connections.
**
**   Cumulative connections are calculated using property control
**   chainage and pit chainage in the flow direction.
**
**   The calculated grade (1:X) is converted to grade (%) and
**   written to the pipe segment attribute "design grade".
**
**   Pipe inverts are not modified. Final grading should be applied
**   using WNE → Regrade Links.
**---------------------------------------------------------------------
*/
#define DEBUG_FILE      0
#define ECHO_DEBUG_FILE 0
#define ECHO_LINE_NO    0
 
#define BUILD "15.0.001"
 
// ----------------------------- INCLUDES -----------------------------
#include "..\\..\\include//standard_library.H"
#include "..\\..\\include//size_of.H"

/*global variables*/{
}

// helper: returns 1 if point (px,py) is within tol of segment A(ax,ay)-B(bx,by)
Integer point_near_seg_2d(Real ax, Real ay, Real bx, Real by, Real px, Real py, Real tol)
{
    Real dx = bx - ax;
    Real dy = by - ay;
    Real len2 = dx*dx + dy*dy;
    if(len2 <= 0.0) return 0;

    // projection parameter t in [0..1]
    Real t = ((px-ax)*dx + (py-ay)*dy) / len2;
    if(t < 0.0 || t > 1.0) return 0;

    Real len = Sqrt(len2);
    if(len <= 0.0) return 0;

    // perpendicular distance = |(P-A) x (B-A)| / |B-A|
    Real cross = (px-ax)*dy - (py-ay)*dx;
    Real dist = Absolute(cross) / len;

    if(dist <= tol) return 1;
    return 0;
}


void mainPanel(){
 
    Text panelName="Drainage Grade Adjust";
    Panel              panel  = Create_panel              (panelName,TRUE);
    Vertical_Group     vgroup = Create_vertical_group     (-1         );
    Colour_Message_Box cmbMsg = Create_colour_message_box (""         );

    ///////////////////CREATE INPUT WIDGETS////////////////
    Source_Box sb_drains = Create_source_box("Drainage Strings", cmbMsg, 0);

    ///////////////ADDING BUTTONS ALONG THE BOTTOM///////////////////////////
    Horizontal_Group bgroup = Create_button_group();
    Button process     = Create_button       ("&Process" ,"process");
    Button finish      = Create_finish_button("Finish"   ,"Finish" );
    Button help_button = Create_help_button  (panel      ,"Help"   );
    Append(process      ,bgroup);
    Append(finish       ,bgroup);
    Append(help_button  ,bgroup);

    ///////////////ADDING WIDGETS TO PANEL///////////////////////////
    Append(sb_drains ,vgroup);
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
                // --- declare variables ---
                Integer ierr;
                Integer src_count;
                Integer has_error = 0;
                Dynamic_Element de_src;

                // ---------------- Source_Box validation ----------------
                ierr = Validate(sb_drains, de_src);
                if(ierr == FALSE)
                {
                    Set_error_message(sb_drains,"");
                    continue;
                }

                ierr = Get_number_of_items(de_src, src_count);
                if(ierr != 0)
                {
                    Set_error_message(sb_drains,"Source error");
                    continue;
                }

                if(src_count <= 0)
                {
                    Set_error_message(sb_drains,"No elements selected");
                    continue;
                }

                // ---------------- Drainage type check (hard fail) ----------------
                for(Integer i=1; i<=src_count; i++)
                {
                    Element e;
                    Text type;

                    Get_item(de_src, i, e);
                    Get_type(e, type);

                    if(type != "Drainage")
                    {
                        Set_error_message(
                            sb_drains,
                            "Selection contains non-drainage elements"
                        );
                        has_error = 1;
                        break;
                    }
                }

                if(has_error)
                    continue;
                // ================= CUMULATIVE DESIGN GRADE UPDATE =================

                for(Integer d=1; d<=src_count; d++)
                {
                    Element drain;
                    Get_item(de_src, d, drain);

                    Integer nsegs = 0;
                    Integer no_pcs = 0;
                    Integer flow_dir = -1;

                    Get_segments(drain, nsegs);
                    Get_drainage_pcs_count(drain, no_pcs);
                    Get_drainage_flow(drain, flow_dir);

                    // ---- Store PC chainages using Dynamic_Real ----
                    Dynamic_Real pc_ch;
                    for(Integer pc=1; pc<=no_pcs; pc++)
                    {
                        Real ch;
                        Get_drainage_pc_chainage(drain, pc, ch);
                        Append(ch, pc_ch);
                    }

                    Integer npc_total = no_pcs;

                    // ---- Loop segments ----
                    for(Integer s=1; s<=nsegs; s++)
                    {
                        Real pit_ch_s, pit_ch_s1;

                        if(Get_drainage_pit_chainage(drain, s, pit_ch_s) != 0)
                            continue;
                        if(Get_drainage_pit_chainage(drain, s+1, pit_ch_s1) != 0)
                            continue;
                        
                        Text pipe_name = "";
                        if(Get_drainage_pipe_attribute(drain, s, "pipe name", pipe_name) != 0)
                            pipe_name = "pipe_" + To_text(s);


                        // Determine downstream chainage based on flow direction
                        Real downstream_ch;

                        if(flow_dir == 0)
                        {
                            // Flow opposite to string direction
                            // Downstream is lower chainage (pit s)
                            downstream_ch = pit_ch_s;
                        }
                        else
                        {
                            // Flow follows string direction
                            // Downstream is pit s+1
                            downstream_ch = pit_ch_s1;
                        }

                        // ---- cumulative count in FLOW direction ----
                        Integer cumulative_pc = 0;

                        for(Integer k=1; k<=npc_total; k++)
                        {
                            Real pc_val;
                            Get_item(pc_ch, k, pc_val);

                            // Count all PCs upstream of this downstream point
                            if(pc_val >= downstream_ch)
                                cumulative_pc++;
                        }

                        // ---- determine grade (Watercare minimums - percentage) ----

                        // Get pipe diameter (DN)
                        Real dn = 0.0;
                        Get_drainage_pipe_attribute(drain, s, "nominal diameter", dn);  // adjust name if needed

                        Real grade_percent = 0.0;

                        // DN150 rules
                        if(dn == 150)
                        {
                            if(cumulative_pc < 20)
                                grade_percent = 1.0;      // 1.0 %
                            else if(cumulative_pc < 200)
                                grade_percent = 0.75;     // 0.75 %
                            else
                                grade_percent = 0.75;     // minimum per table
                        }

                        // DN225
                        else if(dn == 225)
                        {
                            grade_percent = 0.45;
                        }

                        // DN300
                        else if(dn == 300)
                        {
                            grade_percent = 0.30;
                        }
                        else
                        {
                            continue;   // skip unsupported sizes
                        }

                        // ---- get attributes ----
                        Attributes att;
                        if(Get_drainage_pipe_attributes(drain, s, att) != 0)
                            continue;

                        // ---- set REAL attribute ----
                        Integer rc_set = Set_attribute(att, "design grade", grade_percent);
                        Integer rc_write = Set_drainage_pipe_attributes(drain, s, att);

                        // ---- read back REAL ----
                        Attributes att_check;
                        Get_drainage_pipe_attributes(drain, s, att_check);

                        Real dg_read = -1.0;
                        Get_attribute(att_check, "design grade", dg_read);

                        Text out = "[" + pipe_name + "] DN=" +
                                To_text(dn,0) +
                                " cumulative PCs=" + To_text(cumulative_pc) +
                                " min grade=" + To_text(grade_percent,2) + "%";

                        Print(out);
                        Print();
                    }
                }
                Set_data(cmbMsg,"Design grade update complete");

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
