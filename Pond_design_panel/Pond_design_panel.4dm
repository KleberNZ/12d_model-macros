/*---------------------------------------------------------------------
**   Programmer:ChatGPT
**   Date:_date
**   12D Model:            Vversion
**   Version:              15
**   Macro Name:           Pond_Parametric_Footprint_Prismoidal
**   Type:                 SOURCE
**
**   Brief description: Parametric rectangular trapezoidal pond (SUPER ALIGNMENTS) with prismoidal volume
**
**---------------------------------------------------------------------
**   Description: Creates CREST_OUTER/CREST_INNER/POND_BASE/MWL as SUPER ALIGNMENTS
**                from fixed TOB footprint and reports analytic prismoidal water volume.
**
**---------------------------------------------------------------------
**   Update/Modification
**
**
**   (C) Copyright 2013-2025 by your_company Pty Ltd. All Rights
**       Reserved.
**   This macro, or parts thereof, may not be reproduced in any form
**   without permission of your_company.
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

Integer delete_named_element(Text model_name, Text element_name)
{
    Element found;
    Integer count = 0;
    if(Find_element(model_name, element_name, found, count) && count > 0)
    {
        Element_delete(found);
        return TRUE;
    }
    return FALSE;
}

Integer build_rect_super_alignment(
    Model model,
    Text model_name,
    Text sa_name,
    Real x0, Real y0,
    Real L, Real W,
    Real bearing_rad,
    Real z_const
)
{
    // delete any existing element with same name (best effort)
    delete_named_element(model_name, sa_name);

    // build points (SW corner at x0,y0)
    Real ux = Cos(bearing_rad);
    Real uy = Sin(bearing_rad);
    Real vx = Cos(bearing_rad + 1.5707963267948966); // +90deg
    Real vy = Sin(bearing_rad + 1.5707963267948966);

    Real x1 = x0 + L*ux;
    Real y1 = y0 + L*uy;

    Real x2 = x1 + W*vx;
    Real y2 = y1 + W*vy;

    Real x3 = x0 + W*vx;
    Real y3 = y0 + W*vy;

    Element sa = Create_super_alignment();
    Set_model(sa, model);
    Set_name(sa, sa_name);

    Append_hip(sa, x0, y0);
    Append_hip(sa, x1, y1);
    Append_hip(sa, x2, y2);
    Append_hip(sa, x3, y3);
    Append_hip(sa, x0, y0); // close

    if(Calc_super_alignment_horz(sa) == FALSE)
        return FALSE;

    // constant vertical (v1: no crest grade applied)
    Real perim = 2.0*(L + W);
    Append_vip(sa, 0.0,    z_const);
    Append_vip(sa, perim,  z_const);

    if(Calc_super_alignment_vert(sa) == FALSE)
        return FALSE;

    return TRUE;
}

void mainPanel(){

    Text panelName="Parametric Pond (Footprint Driven)";
    Panel              panel  = Create_panel              (panelName,TRUE);
    Vertical_Group     vgroup = Create_vertical_group     (-1         );
    Colour_Message_Box cmbMsg = Create_colour_message_box (""         );

    ///////////////////CREATE INPUT WIDGETS////////////////
    Text_Edit_Box teb_prefix   = Create_text_edit_box("Model name prefix", cmbMsg, 1);
    Model_Box     mb_target    = Create_model_box("Target model", cmbMsg, 0);

    Real_Box rb_xref      = Create_real_box("X_ref (SW corner of CREST_OUTER)", cmbMsg);
    Real_Box rb_yref      = Create_real_box("Y_ref (SW corner of CREST_OUTER)", cmbMsg);

    Real_Box rb_Lout      = Create_real_box("Outer crest length L_out (m)", cmbMsg);
    Real_Box rb_Wout      = Create_real_box("Outer crest width  W_out (m)", cmbMsg);
    Real_Box rb_B         = Create_real_box("Crest width B (m)", cmbMsg);

    Real_Box rb_Ztob      = Create_real_box("Z_TOB_ref (m)", cmbMsg);

    Real_Box rb_g         = Create_real_box("Crest grade g (%) [v1 not applied]", cmbMsg);
    Angle_Box ab_bearing  = Create_angle_box("Initial bearing (radians)", cmbMsg);

    Real_Box rb_Dmax      = Create_real_box("Max water depth D_max (m)", cmbMsg);
    Real_Box rb_F         = Create_real_box("Freeboard F (m)", cmbMsg);

    Real_Box rb_sin       = Create_real_box("Uniform inside batter s_in (1V:sH)", cmbMsg);

    ///////////////ADDING BUTTONS ALONG THE BOTTOM///////////////////////////
    Horizontal_Group bgroup = Create_button_group();
    Button process     = Create_button       ("&Process" ,"process");
    Button finish      = Create_finish_button("Finish"   ,"Finish" );
    Button help_button = Create_help_button  (panel      ,"Help"   );
    Append(process      ,bgroup);
    Append(finish       ,bgroup);
    Append(help_button  ,bgroup);

    ///////////////ADDING WIDGETS TO PANEL///////////////////////////
    Append(teb_prefix ,vgroup);
    Append(mb_target  ,vgroup);

    Append(rb_xref ,vgroup);
    Append(rb_yref ,vgroup);

    Append(rb_Lout ,vgroup);
    Append(rb_Wout ,vgroup);
    Append(rb_B    ,vgroup);

    Append(rb_Ztob ,vgroup);
    Append(rb_g    ,vgroup);
    Append(ab_bearing ,vgroup);

    Append(rb_Dmax ,vgroup);
    Append(rb_F    ,vgroup);
    Append(rb_sin  ,vgroup);

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
                // ---- declare widget variables
                Text prefix = "";
                Get_data(teb_prefix, prefix);

                Model target_model;
                if(Validate(mb_target, 0, target_model) == FALSE)
                {
                    Set_data(cmbMsg, "Select a target model.");
                    break;
                }

                Real xref=0.0,yref=0.0;
                Real Lout=0.0,Wout=0.0,B=0.0;
                Real Ztob=0.0;
                Real g_pct=0.0;
                Real bearing=0.0;
                Real Dmax=0.0,F=0.0;
                Real s_in=0.0;

                // ---- validate widgets
                if(Validate(rb_xref, xref) == FALSE) break;
                if(Validate(rb_yref, yref) == FALSE) break;

                if(Validate(rb_Lout, Lout) == FALSE) break;
                if(Validate(rb_Wout, Wout) == FALSE) break;
                if(Validate(rb_B,    B   ) == FALSE) break;

                if(Validate(rb_Ztob, Ztob) == FALSE) break;

                // grade is accepted but not applied in v1
                Validate(rb_g, g_pct);
                if(Validate(ab_bearing, bearing) == FALSE) break;

                if(Validate(rb_Dmax, Dmax) == FALSE) break;
                if(Validate(rb_F,    F   ) == FALSE) break;

                if(Validate(rb_sin,  s_in) == FALSE) break;

                // ---- fail-fast / sanity
                if(Lout <= 0.0 || Wout <= 0.0 || B <= 0.0 || Dmax <= 0.0 || F < 0.0 || s_in <= 0.0)
                {
                    Set_data(cmbMsg, "Invalid inputs (must be positive; freeboard >= 0).");
                    break;
                }

                // ---- derived values
                Real D_TOB  = Dmax + F;
                Real Z_base = Ztob - D_TOB;
                Real Z_MWL  = Ztob - F;

                // ---- crest inner (fit check)
                Real Lin = Lout - 2.0*B;
                Real Win = Wout - 2.0*B;
                if(Lin <= 0.0 || Win <= 0.0)
                {
                    Set_data(cmbMsg, "Footprint too small for requested depth/slopes/freeboard/bench.");
                    break;
                }

                // ---- base dims (uniform batter)
                Real Lb = Lout - 2.0*B - 2.0*s_in*D_TOB;
                Real Wb = Wout - 2.0*B - 2.0*s_in*D_TOB;
                if(Lb <= 0.0 || Wb <= 0.0)
                {
                    Set_data(cmbMsg, "Footprint too small for requested depth/slopes/freeboard/bench.");
                    break;
                }

                // ---- MWL dims
                Real Lmwl = Lb + 2.0*s_in*Dmax;
                Real Wmwl = Wb + 2.0*s_in*Dmax;

                // ---- areas
                Real A_b    = Lb*Wb;
                Real A_MWL  = Lmwl*Wmwl;
                Real A_foot = Lout*Wout;

                // ---- prismoidal volume (uniform)
                Real Amid = (Lb + s_in*Dmax) * (Wb + s_in*Dmax);
                Real Vwater = (Dmax/6.0) * (A_b + 4.0*Amid + A_MWL);

                // ---- naming
                if(prefix == "")
                    prefix = "POND";

                Text model_name = Get_name(target_model);

                Text name_crest_outer = prefix + "_CREST_OUTER";
                Text name_crest_inner = prefix + "_CREST_INNER";
                Text name_base        = prefix + "_POND_BASE";
                Text name_mwl         = prefix + "_MWL";

                // ---- geometry (SUPER ALIGNMENTS only)
                // CREST_OUTER
                if(build_rect_super_alignment(target_model, model_name, name_crest_outer,
                                              xref, yref, Lout, Wout, bearing, Ztob) == FALSE)
                {
                    Set_data(cmbMsg, "Failed creating CREST_OUTER.");
                    break;
                }

                // CREST_INNER: offset inward by B on all sides in rectangle local axes
                Real ux = Cos(bearing);
                Real uy = Sin(bearing);
                Real vx = Cos(bearing + 1.5707963267948966);
                Real vy = Sin(bearing + 1.5707963267948966);

                Real x_in = xref + B*ux + B*vx;
                Real y_in = yref + B*uy + B*vy;

                if(build_rect_super_alignment(target_model, model_name, name_crest_inner,
                                              x_in, y_in, Lin, Win, bearing, Ztob) == FALSE)
                {
                    Set_data(cmbMsg, "Failed creating CREST_INNER.");
                    break;
                }

                // POND_BASE: offset inward from CREST_OUTER by (B + s_in*D_TOB)
                Real off_base = B + s_in*D_TOB;
                Real x_base = xref + off_base*ux + off_base*vx;
                Real y_base = yref + off_base*uy + off_base*vy;

                if(build_rect_super_alignment(target_model, model_name, name_base,
                                              x_base, y_base, Lb, Wb, bearing, Z_base) == FALSE)
                {
                    Set_data(cmbMsg, "Failed creating POND_BASE.");
                    break;
                }

                // MWL: offset inward from CREST_OUTER by (B + s_in*F)
                Real off_mwl = B + s_in*F;
                Real x_mwl = xref + off_mwl*ux + off_mwl*vx;
                Real y_mwl = yref + off_mwl*uy + off_mwl*vy;

                if(build_rect_super_alignment(target_model, model_name, name_mwl,
                                              x_mwl, y_mwl, Lmwl, Wmwl, bearing, Z_MWL) == FALSE)
                {
                    Set_data(cmbMsg, "Failed creating MWL.");
                    break;
                }

                // ---- reporting
                Text rep = "";
                rep = rep + "Z_TOB_ref = " + To_text(Ztob, 3) + " m\n";
                rep = rep + "Z_MWL     = " + To_text(Z_MWL, 3) + " m\n";
                rep = rep + "Z_base    = " + To_text(Z_base, 3) + " m\n\n";

                rep = rep + "A_base    = " + To_text(A_b, 3) + " m^2\n";
                rep = rep + "A_MWL     = " + To_text(A_MWL, 3) + " m^2\n";
                rep = rep + "A_foot    = " + To_text(A_foot, 3) + " m^2\n\n";

                rep = rep + "V_water (prismoidal) = " + To_text(Vwater, 3) + " m^3\n";
                rep = rep + "\nNOTE: v1 uses constant crest elevation; grade input accepted but not applied.\n";

                Print(rep);
                Set_data(cmbMsg, rep);
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
