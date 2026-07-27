/*---------------------------------------------------------------------
**   Programmer:Kleber Lessa do Prado
**   Company: The Neil Group
**   Date:17/09/25             
**   12D Model:            V15
**   Version:              006
**   Macro Name:           ACCoP_SW_Check.4dm
**   Type:                 Drainage QA
**
**   Brief description: Checks stormwater drainage strings against 
**            Auckland CoP for pit sizes, velocities, cover, grades, 
**            deflections, internal falls, and spacing requirements.
**
**---------------------------------------------------------------------
**   Description: 
**
** The ACCoP_SW_Check_v6.4dm macro evaluates stormwater drainage strings in 12d Model against the requirements of the Auckland Council 
** Code of Practice (CoP) for stormwater. After selecting a string, the macro extracts pit and pipe information and applies automated checks:
** Pit listing: Lists all pits with names, diameters, cover levels, inverts, and depths.
** Pipe spacing and attributes: Verifies maximum pit spacing by pipe size, minimum cover, pipe grade (0.1–25%), and flow velocities 
** (2% AEP ≥1.0 m/s, 10% AEP ≤4.0 m/s).
** Special provisions: Flags bedding and anchor block requirements for grades >10% and ≥20%.
** Deflections: Checks allowable joint deflections, warning if >75° or prohibiting >90°.
** Internal falls: Enforces CoP rules for manhole drops, including soffit-to-soffit, open cascades, minimum/maximum drop ranges, and
** absolute maximum drop ≤1.0 m.
** Steep grades: Applies extra conditions for pipes on grades >7%, including minimum pit depth, maximum deflection (≤45°), and prohibition
** of open cascades with large drops.
** Pit sizing rules (SW05/SW07): Ensures manhole diameters match required sizes based on outlet DN, upstream deflection, and pit depth, 
** and flags specific requirements such as in-situ concrete bases for SW07 cases.
** All results are printed to the Output window with clear CoP clause references,
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
**
**---------------------------------------------------------------------*/
#define BUILD "V15.0.002"
#define DEBUG_FILE                  0
#define ECHO_DEBUG_FILE             0
#define ECHO_LINE_NO                0
#define DEBUG_NETWORK_RELATIONSHIPS 0

#include "standard_library.h"
#include "size_of.h"

/*global variables*/{
  /* ============================ Limits ============================ */
  /* -------------------- Tolerances -------------------- */
  Real DROP_TOL = 0.005;   /* 5 mm drop tolerance */
  Real EPS_DEF  = 0.05;    /* 0.05 deg deflection tolerance */
  
  /* ===================== Canonical current-pit context ===================== */
  Integer QA_pit_count = 0;
  Integer QA_pit_depth_missing_count = 0;
  Integer QA_same_string_upstream_count = 0;
  Integer QA_cross_string_incoming_count = 0;
  Integer QA_same_string_check_failure_count = 0;
  Integer QA_cross_string_check_failure_count = 0;

  Integer QA_current_network_pit_id = 0;
  Integer QA_current_pit_index = 0;

  Text QA_current_string_name = "";
  Text QA_current_pit_name = "";

  Real QA_current_pit_x = 0.0;
  Real QA_current_pit_y = 0.0;
  Real QA_current_pit_z = 0.0;
  Real QA_current_pit_depth = 0.0;
  Real QA_current_pit_hgl = 0.0;
  Real QA_current_pit_sump_level = 0.0;
  Real QA_current_pit_nominal_diameter = 0.0;

  Integer QA_have_current_pit_coordinates = 0;
  Integer QA_have_current_pit_depth = 0;
  Integer QA_have_current_pit_hgl = 0;
  Integer QA_have_current_pit_sump_level = 0;
  Integer QA_have_current_pit_nominal_diameter = 0;

  /* ===================== Current downstream-pipe context ===================== */
  Integer QA_have_downstream_pipe = 0;
  Element QA_downstream_string;
  Integer QA_downstream_pipe_index = 0;
  Integer QA_downstream_network_pipe_id = 0;

  Real QA_downstream_nominal_diameter = 0.0;
  Real QA_downstream_internal_diameter = 0.0;
  Real QA_downstream_invert_us = 0.0;

  Integer QA_have_downstream_nominal_diameter = 0;
  Integer QA_have_downstream_internal_diameter = 0;
  Integer QA_have_downstream_invert_us = 0;

  /* ===================== Canonical report state ===================== */
  Log_Line QA_report_model_group;
  Log_Line QA_report_current_pit_group;

  Integer QA_report_active = 0;
  Integer QA_report_current_pit_has_error = 0;
  Integer QA_report_error_pit_count = 0;

}

/* ============================ Helpers =========================== */
/* ---------------- SW05 required size (minimal table retained) ---------------- */
Integer _sw05_required_mm(Real outlet_dn, Real us_def_deg, Real pit_depth_m)
{
    // 12dPL implicit conversion
    Integer dn = outlet_dn + 0.5;
    // Round deflection to nearest whole degree
    Integer def = us_def_deg + 0.5;

    // DN > 1050 => Specific Design
    if(dn > 1050) return 0;

    // Small pipe shallow depth rule
    if(dn < 450 && pit_depth_m < 4.0) return 1050;

    // --------------------------------------------------
    // Deflection column index (1..6)
    // 1 = 0°
    // 2 = 30°
    // 3 = 45°
    // 4 = 60°
    // 5 = 75°
    // 6 = 90°
    //
    // Table uses LOWER-BOUND banding
    // --------------------------------------------------

    Integer col = 6; // default 90°

    if(def < 30.0)       col = 1;
    else if(def < 45.0)  col = 2;
    else if(def < 60.0)  col = 3;
    else if(def < 75.0)  col = 4;
    else if(def < 90.0)  col = 5;

    // DN row index (1..7)
    Integer row = 0;
    if(dn == 450)  row = 1;
    if(dn == 525)  row = 2;
    if(dn == 600)  row = 3;
    if(dn == 750)  row = 4;
    if(dn == 825)  row = 5;
    if(dn == 900)  row = 6;
    if(dn == 1050) row = 7;

    if(row == 0) return 0; // unknown DN => SD

    // --------------------------------------------------
    // 1D lookup table (7 rows × 6 cols = 42 values)
    // Row order:
    // 450,525,600,750,825,900,1050
    //
    // Col order:
    // 0°,30°,45°,60°,75°,90°
    //
    // SD = 0
    // --------------------------------------------------

    Integer table[42];

    // ---- 450 ----
    table[ 1]=1050; table[ 2]=1050; table[ 3]=1050;
    table[ 4]=1350; table[ 5]=1800; table[ 6]=2300;

    // ---- 525 ----
    table[ 7]=1050; table[ 8]=1050; table[ 9]=1200;
    table[10]=1500; table[11]=2050; table[12]=0;

    // ---- 600 ----
    table[13]=1050; table[14]=1050; table[15]=1350;
    table[16]=1800; table[17]=2300; table[18]=0;

    // ---- 750 ----
    table[19]=1050; table[20]=1050; table[21]=1800;
    table[22]=2300; table[23]=0;    table[24]=0;

    // ---- 825 ----
    table[25]=1200; table[26]=1200; table[27]=1800;
    table[28]=0;    table[29]=0;    table[30]=0;

    // ---- 900 ----
    table[31]=1200; table[32]=1200; table[33]=2050;
    table[34]=0;    table[35]=0;    table[36]=0;

    // ---- 1050 ----
    table[37]=1500; table[38]=1500; table[39]=2300;
    table[40]=0;    table[41]=0;    table[42]=0;

    Integer idx = (row - 1) * 6 + col;

    return table[idx];
}
void Output_line(Text text)
{
    Print(text);
    Print();
}


// helper: clear relationship-independent data before each canonical pit
void Reset_current_pit_context()
{
    QA_current_network_pit_id = 0;
    QA_current_pit_index = 0;

    QA_current_string_name = "";
    QA_current_pit_name = "";

    QA_current_pit_x = 0.0;
    QA_current_pit_y = 0.0;
    QA_current_pit_z = 0.0;
    QA_current_pit_depth = 0.0;
    QA_current_pit_hgl = 0.0;
    QA_current_pit_sump_level = 0.0;
    QA_current_pit_nominal_diameter = 0.0;

    QA_have_current_pit_coordinates = 0;
    QA_have_current_pit_depth = 0;
    QA_have_current_pit_hgl = 0;
    QA_have_current_pit_sump_level = 0;
    QA_have_current_pit_nominal_diameter = 0;

    Null(QA_downstream_string);

    QA_have_downstream_pipe = 0;
    QA_downstream_pipe_index = 0;
    QA_downstream_network_pipe_id = 0;
    QA_downstream_nominal_diameter = 0.0;
    QA_downstream_internal_diameter = 0.0;
    QA_downstream_invert_us = 0.0;
    QA_have_downstream_nominal_diameter = 0;
    QA_have_downstream_internal_diameter = 0;
    QA_have_downstream_invert_us = 0;
}


// ------------------------------------------------------------------
// CANONICAL REPORT HELPERS
// ------------------------------------------------------------------

void QA_start_canonical_report(
    Log_Box lb_report,
    Text model_name)
{
    QA_report_active = 1;
    QA_report_current_pit_has_error = 0;
    QA_report_error_pit_count = 0;

    QA_report_model_group =
        Create_group_log_line(
            "=== Drainage Model: "+model_name+" ===",
            1);

    Add_log_line(
        lb_report,
        QA_report_model_group);
}

void QA_start_current_pit_report()
{
    QA_report_current_pit_has_error = 0;

    if(!QA_report_active) return;

    QA_report_current_pit_group =
        Create_group_log_line(
            "Pit = ["+QA_current_pit_name+
            "]  String = ["+QA_current_string_name+"]",
            1);

    Append_log_line(
        QA_report_current_pit_group,
        QA_report_model_group);

    if(QA_have_current_pit_coordinates)
    {
        Log_Line highlight =
            Create_highlight_point_log_line(
                "Pan to Pit",
                1,
                QA_current_pit_x,
                QA_current_pit_y,
                QA_current_pit_z);

        Append_log_line(
            highlight,
            QA_report_current_pit_group);
    }
}

void QA_report_error(Text message)
{
    QA_report_current_pit_has_error = 1;

    if(QA_report_active)
    {
        Log_Line clause =
            Create_text_log_line(
                message,
                3);

        Append_log_line(
            clause,
            QA_report_current_pit_group);
    }

    if(DEBUG_NETWORK_RELATIONSHIPS)
    {
        Output_line(
            "    QA ERROR: "+message);
    }
}

void QA_report_warning(Text message)
{
    QA_report_current_pit_has_error = 1;

    if(QA_report_active)
    {
        Log_Line clause =
            Create_text_log_line(
                message,
                2);

        Append_log_line(
            clause,
            QA_report_current_pit_group);
    }

    if(DEBUG_NETWORK_RELATIONSHIPS)
    {
        Output_line(
            "    QA WARNING: "+message);
    }
}

void QA_finalise_current_pit_report()
{
    if(!QA_report_active) return;

    if(QA_report_current_pit_has_error)
    {
        QA_report_error_pit_count =
            QA_report_error_pit_count + 1;
    }
    else
    {
        Log_Line clause =
            Create_text_log_line(
                "CoP Check = OK",
                1);

        Append_log_line(
            clause,
            QA_report_current_pit_group);
    }
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
    Reset_current_pit_context();

    QA_pit_count = QA_pit_count + 1;

    QA_current_network_pit_id = current_network_pit_id;
    QA_current_pit_index = current_pit_index;

    if(Get_name(current_string,QA_current_string_name)!=0)
    {
        QA_current_string_name = "<name unavailable>";
    }

    if(
        Get_drainage_pit_name(
            current_string,
            current_pit_index,
            QA_current_pit_name)!=0)
    {
        QA_current_pit_name = "<pit name unavailable>";
    }

    if(
        Get_drainage_pit(
            current_string,
            current_pit_index,
            QA_current_pit_x,
            QA_current_pit_y,
            QA_current_pit_z)==0)
    {
        QA_have_current_pit_coordinates = 1;
    }

    // Top-level automatically calculated pit attribute.
    // Do not calculate depth and do not read /network attributes.
    if(
        Get_drainage_pit_attribute(
            current_string,
            current_pit_index,
            "pit depth",
            QA_current_pit_depth)==0)
    {
        QA_have_current_pit_depth = 1;
    }
    else
    {
        QA_pit_depth_missing_count =
            QA_pit_depth_missing_count + 1;

        if(DEBUG_NETWORK_RELATIONSHIPS)
        {
            Output_line(
                "  PIT DATA: top-level pit depth unavailable for "+
                QA_current_string_name+
                " / "+
                QA_current_pit_name);
        }
    }

    if(
        Get_drainage_pit_hgl(
            current_string,
            current_pit_index,
            QA_current_pit_hgl)==0)
    {
        QA_have_current_pit_hgl = 1;
    }

    if(
        Get_drainage_pit_attribute(
            current_string,
            current_pit_index,
            "sump level",
            QA_current_pit_sump_level)==0)
    {
        QA_have_current_pit_sump_level = 1;
    }

    Text pit_nominal_diameter_text="";

    if(
        Get_drainage_pit_attribute(
            current_string,
            current_pit_index,
            "lplot Nominal Diameter",
            pit_nominal_diameter_text)==0)
    {
        if(
            From_text(
                pit_nominal_diameter_text,
                QA_current_pit_nominal_diameter)==0)
        {
            QA_have_current_pit_nominal_diameter = 1;
        }
    }
    else if(
        Get_drainage_pit_attribute(
            current_string,
            current_pit_index,
            "lplot Nominal Diameter",
            QA_current_pit_nominal_diameter)==0)
    {
        QA_have_current_pit_nominal_diameter = 1;
    }

    QA_start_current_pit_report();

    if(DEBUG_NETWORK_RELATIONSHIPS)
    {
        Text depth_text="<unavailable>";
        Text pit_diameter_text="<unavailable>";

        if(QA_have_current_pit_depth)
        {
            depth_text=To_text(QA_current_pit_depth,3)+" m";
        }

        if(QA_have_current_pit_nominal_diameter)
        {
            pit_diameter_text=
                To_text(QA_current_pit_nominal_diameter,0)+" mm";
        }

        Output_line("  PIT DATA:");
        Output_line("    depth="+depth_text);
        Output_line("    pit diameter="+pit_diameter_text);
    }
}


// helper: apply checks that use the current pit and one direct upstream pipe.
// Called for both same-string and cross-string incoming relationships.
void Check_direct_upstream_pipe(
    Element current_string,
    Integer current_pit_index,
    Integer current_network_pit_id,
    Element pipe_string,
    Integer pipe_index,
    Integer network_pipe_id,
    Integer relationship_type)
{
    Integer check_failed=0;

    Text pipe_name="<name unavailable>";
    Get_name(
        pipe_string,
        pipe_name);

    Text pipe_attribute_name="<pipe name unavailable>";
    Integer pipe_attribute_name_rc=
        Get_drainage_pipe_attribute(
            pipe_string,
            pipe_index,
            "pipe name",
            pipe_attribute_name);

    if(pipe_attribute_name_rc!=0)
    {
        pipe_attribute_name="<pipe name unavailable>";
    }

    Real pipe_dn=0.0;
    Real pipe_grade=0.0;
    Real pipe_grade_pct=0.0;
    Real pipe_deflection=0.0;
    Real pipe_ds_invert=0.0;

    Integer have_pipe_dn=0;
    Integer have_pipe_grade=0;
    Integer have_pipe_deflection=0;
    Integer have_pipe_ds_invert=0;

    if(
        Get_drainage_pipe_nominal_diameter(
            pipe_string,
            pipe_index,
            pipe_dn)==0)
    {
        have_pipe_dn=1;
    }

    if(
        Get_drainage_pipe_grade(
            pipe_string,
            pipe_index,
            pipe_grade)==0)
    {
        have_pipe_grade=1;

        if(pipe_grade>0.0)
        {
            pipe_grade_pct=100.0/pipe_grade;
        }
    }

    if(
        Get_drainage_pipe_attribute(
            pipe_string,
            pipe_index,
            "calculated ds deflection",
            pipe_deflection)==0)
    {
        have_pipe_deflection=1;
        pipe_deflection=Absolute(pipe_deflection);

        if(Absolute(pipe_deflection-90.0)<EPS_DEF)
        {
            pipe_deflection=90.0;
        }
    }

    if(
        Get_drainage_pipe_attribute(
            pipe_string,
            pipe_index,
            "invert ds",
            pipe_ds_invert)==0)
    {
        have_pipe_ds_invert=1;
    }

    // Existing deflection rule.
    if(have_pipe_deflection)
    {
        if(pipe_deflection>90.0+EPS_DEF)
        {
            check_failed=1;

            QA_report_error(
                "CoP 4.3.10.3 deflection >90 deg"+
                " [found="+To_text(pipe_deflection,2)+" deg]"
            );
        }
        else if(
            have_pipe_dn &&
            QA_have_current_pit_depth)
        {
            Integer mh_req=
                _sw05_required_mm(
                    pipe_dn,
                    pipe_deflection,
                    QA_current_pit_depth);

            if(mh_req==0)
            {
                check_failed=1;

                QA_report_error(
                    "CoP 4.3.10.6 specific design required"+
                    " [deflection="+To_text(pipe_deflection,2)+" deg]"
                );
            }
        }
    }

    // Existing primary-pipe surcharge rule.
    if(
        QA_have_current_pit_hgl &&
        have_pipe_ds_invert &&
        have_pipe_dn)
    {
        Real EPS_HGL=0.010;
        Real pipe_soffit=
            pipe_ds_invert+
            pipe_dn/1000.0;

        Real surcharge=
            QA_current_pit_hgl-
            pipe_soffit;

        if(surcharge>EPS_HGL)
        {
            check_failed=1;

            QA_report_warning(
                "CoP 4.3.5.3 incoming pipe surcharging"+
                " [pipe name="+pipe_attribute_name+
                "; HGL="+To_text(QA_current_pit_hgl,3)+" m"+
                "; soffit="+To_text(pipe_soffit,3)+" m"+
                "; exceedance="+To_text(surcharge,3)+" m]"
            );
        }
    }

    // Existing steep-grade checks that do not require the downstream pipe.
    if(
        have_pipe_grade &&
        pipe_grade_pct>7.0)
    {
        if(
            have_pipe_dn &&
            QA_have_current_pit_depth)
        {
            if(
                pipe_dn<=225.0 &&
                !(QA_current_pit_depth>1.5))
            {
                check_failed=1;

                QA_report_error(
                    "CoP 4.3.10 grade >7% requires pit depth >1.5 m for DN<=225"+
                    " [found="+To_text(QA_current_pit_depth,2)+" m]"
                );
            }

            if(
                pipe_dn>=300.0 &&
                !(QA_current_pit_depth>2.0))
            {
                check_failed=1;

                QA_report_error(
                    "CoP 4.3.10 grade >7% requires pit depth >2.0 m for DN>=300"+
                    " [found="+To_text(QA_current_pit_depth,2)+" m]"
                );
            }
        }

        if(
            have_pipe_deflection &&
            pipe_deflection>45.0)
        {
            check_failed=1;

            QA_report_error(
                "CoP 4.3.10 grade >7% requires deflection <=45 deg"+
                " [pipe name="+pipe_attribute_name+
                "; found="+To_text(pipe_deflection,1)+" deg]"
            );
        }
    }

    // Existing checks that compare this direct upstream pipe
    // with the resolved downstream pipe, or with the terminal-pit sump.
    Real actual_drop=0.0;
    Integer have_actual_drop=0;

    if(have_pipe_ds_invert)
    {
        if(
            QA_have_downstream_pipe &&
            QA_have_downstream_invert_us)
        {
            actual_drop=
                pipe_ds_invert-
                QA_downstream_invert_us;
            have_actual_drop=1;
        }
        else if(QA_have_current_pit_sump_level)
        {
            // Preserve the existing terminal-pit calculation.
            actual_drop=
                pipe_ds_invert-
                QA_current_pit_sump_level;
            have_actual_drop=1;
        }
    }

    if(have_actual_drop)
    {
        Real outlet_dn=0.0;
        Integer have_outlet_dn=0;

        if(QA_have_downstream_nominal_diameter)
        {
            outlet_dn=QA_downstream_nominal_diameter;
            have_outlet_dn=1;
        }

        if(QA_have_downstream_pipe && have_pipe_dn && have_outlet_dn)
        {
            Real max_dn=
                (pipe_dn>outlet_dn) ? pipe_dn : outlet_dn;

            if(max_dn>=1000.0)
            {
                if(actual_drop>0.0)
                {
                    check_failed=1;

                    QA_report_error(
                        "CoP 4.3.10.6 internal fall with DN>=1000 requires specific design"+
                        " [drop="+To_text(actual_drop,3)+" m]"
                    );
                }
            }
            else
            {
                Real min_drop=0.05;
                Real max_drop=0.30;

                if(outlet_dn==pipe_dn)
                {
                    if(
                        pipe_dn<=300.0 &&
                        pipe_grade_pct<=7.0)
                    {
                        max_drop=1.0;
                    }
                }
                else if(outlet_dn>pipe_dn)
                {
                    if(
                        QA_have_downstream_internal_diameter)
                    {
                        Real upstream_internal_diameter=0.0;

                        if(
                            Get_drainage_pipe_attribute(
                                pipe_string,
                                pipe_index,
                                "diameter",
                                upstream_internal_diameter)==0)
                        {
                            min_drop=
                                QA_downstream_internal_diameter-
                                upstream_internal_diameter;
                        }
                    }

                    if(
                        pipe_dn<=300.0 &&
                        pipe_grade_pct<=7.0)
                    {
                        max_drop=1.0;
                    }
                }

                if(
                    actual_drop>0.0 &&
                    (min_drop-actual_drop)>DROP_TOL)
                {
                    check_failed=1;

                    QA_report_error(
                        "CoP 4.3.10.6 internal fall below minimum "+
                        To_text(min_drop,3)+" m"+
                        " [found="+To_text(actual_drop,3)+" m]"
                    );
                }

                if((actual_drop-max_drop)>DROP_TOL)
                {
                    check_failed=1;

                    QA_report_error(
                        "CoP 4.3.10.6 internal fall above maximum "+
                        To_text(max_drop,3)+" m"+
                        " [pipe name="+pipe_attribute_name+
                        "; found="+To_text(actual_drop,3)+" m]"
                    );
                }
            }

            // Existing SW05 pit sizing check.
            if(
                QA_have_current_pit_depth &&
                QA_have_current_pit_nominal_diameter &&
                have_pipe_deflection)
            {
                Integer required_pit_diameter=
                    _sw05_required_mm(
                        outlet_dn,
                        pipe_deflection,
                        QA_current_pit_depth);

                if(required_pit_diameter==0)
                {
                    check_failed=1;

                    QA_report_error(
                        "SW05 specific design required"+
                        " [outlet DN="+To_text(outlet_dn,0)+
                        "; incoming deflection="+To_text(pipe_deflection,1)+" deg"+
                        "; depth="+To_text(QA_current_pit_depth,2)+" m]"
                    );
                }
                else if(
                    Absolute(
                        QA_current_pit_nominal_diameter-
                        required_pit_diameter)>1.0)
                {
                    check_failed=1;

                    QA_report_error(
                        "SW05 manhole diameter should be "+
                        To_text(required_pit_diameter)+" mm"+
                        " [found="+To_text(QA_current_pit_nominal_diameter,0)+" mm]"
                    );
                }
            }
        }

        if(actual_drop>1.0)
        {
            check_failed=1;

            QA_report_error(
                "CoP 4.3.10.7 drop >1.0 m not permitted"+
                " [found="+To_text(actual_drop,3)+" m]"
            );
        }

        if(
            have_pipe_grade &&
            pipe_grade_pct>7.0 &&
            actual_drop>0.30)
        {
            check_failed=1;

            QA_report_error(
                "CoP 4.3.10 no open cascade allowed when incoming grade >7%"+
                " [pipe name="+pipe_attribute_name+
                "; drop="+To_text(actual_drop,3)+" m]"
            );
        }
    }

    if(check_failed)
    {
        if(relationship_type==2)
        {
            QA_cross_string_check_failure_count=
                QA_cross_string_check_failure_count+1;
        }
        else
        {
            QA_same_string_check_failure_count=
                QA_same_string_check_failure_count+1;
        }
    }

    if(DEBUG_NETWORK_RELATIONSHIPS)
    {
        Text relationship_text="SAME-STRING UPSTREAM";

        if(relationship_type==2)
        {
            relationship_text="CROSS-STRING INCOMING";
        }

        Text result_text="NO FLAG";

        if(check_failed)
        {
            result_text="FAIL";
        }

        Output_line(
            "    QA CHECKED: "+
            relationship_text+
            " / "+
            pipe_name+
            " / pipe "+
            To_text(pipe_index)+
            " / result="+
            result_text);
    }
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
    QA_same_string_upstream_count=
        QA_same_string_upstream_count+1;

    Check_direct_upstream_pipe(
        current_string,
        current_pit_index,
        current_network_pit_id,
        pipe_string,
        pipe_index,
        network_pipe_id,
        1);
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
    QA_cross_string_incoming_count=
        QA_cross_string_incoming_count+1;

    Check_direct_upstream_pipe(
        current_string,
        current_pit_index,
        current_network_pit_id,
        pipe_string,
        pipe_index,
        network_pipe_id,
        2);
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
    QA_have_downstream_pipe=1;
    QA_downstream_string=pipe_string;
    QA_downstream_pipe_index=pipe_index;
    QA_downstream_network_pipe_id=network_pipe_id;

    if(
        Get_drainage_pipe_nominal_diameter(
            pipe_string,
            pipe_index,
            QA_downstream_nominal_diameter)==0)
    {
        QA_have_downstream_nominal_diameter=1;
    }

    if(
        Get_drainage_pipe_attribute(
            pipe_string,
            pipe_index,
            "diameter",
            QA_downstream_internal_diameter)==0)
    {
        QA_have_downstream_internal_diameter=1;
    }

    if(
        Get_drainage_pipe_attribute(
            pipe_string,
            pipe_index,
            "invert us",
            QA_downstream_invert_us)==0)
    {
        QA_have_downstream_invert_us=1;
    }

    // Existing SW07 rule depends only on the current pit and outlet pipe.
    if(
        QA_have_current_pit_depth &&
        QA_have_downstream_nominal_diameter &&
        QA_current_pit_depth>4.0 &&
        QA_current_pit_depth<5.0 &&
        QA_downstream_nominal_diameter>=500.0 &&
        QA_downstream_nominal_diameter<=1200.0)
    {
        QA_report_error(
            "SW07 manhole with in-situ concrete base required"+
            " [outlet DN="+To_text(QA_downstream_nominal_diameter,0)+
            "; depth="+To_text(QA_current_pit_depth,2)+" m]"
        );
    }
}


// ------------------------------------------------------------------
// NETWORK TRAVERSAL
// ------------------------------------------------------------------

Integer Traverse_drainage_network(
    Model selected_model)
{
    QA_pit_count = 0;
    QA_pit_depth_missing_count = 0;
    QA_same_string_upstream_count = 0;
    QA_cross_string_incoming_count = 0;
    QA_same_string_check_failure_count = 0;
    QA_cross_string_check_failure_count = 0;
    QA_report_current_pit_has_error = 0;
    QA_report_error_pit_count = 0;
    Reset_current_pit_context();

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

        Null(drainage_network);
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

        Null(drainage_network);
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

        Null(drainage_network);
        return rc;
    }

    if(network_pit_count<1)
    {
        Output_line("No network pits were found.");
        Null(drainage_network);
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

        Null(drainage_network);
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

            Null(drainage_network);
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

            Process_current_pit(
                current_string,
                current_pit_index,
                current_network_pit_id);

            // Resolve and process the downstream pipe first so every
            // direct-upstream hook has the correct outlet context.
            for(
                pipe_number=1;
                pipe_number<=returned_pipes;
                pipe_number++)
            {
                Element downstream_string;
                Integer downstream_pipe_index=0;
                Integer downstream_us_pit_id=0;
                Integer downstream_ds_pit_id=0;

                rc=
                    Get_drainage_network_pipe(
                        drainage_network,
                        network_pipe_ids[pipe_number],
                        downstream_string,
                        downstream_pipe_index,
                        downstream_us_pit_id,
                        downstream_ds_pit_id);

                if(rc!=0)
                {
                    continue;
                }

                if(downstream_us_pit_id==current_network_pit_id)
                {
                    Text downstream_string_name="";

                    if(
                        Get_name(
                            downstream_string,
                            downstream_string_name)!=0)
                    {
                        downstream_string_name="<name unavailable>";
                    }

                    downstream_pipe_count++;

                    if(DEBUG_NETWORK_RELATIONSHIPS)
                    {
                        Output_line(
                            "  DOWNSTREAM: "+
                            downstream_string_name+
                            " / pipe "+
                            To_text(downstream_pipe_index)+
                            " / network pipe "+
                            To_text(network_pipe_ids[pipe_number]));
                    }

                    Process_downstream_pipe(
                        current_string,
                        current_pit_index,
                        current_network_pit_id,
                        downstream_string,
                        downstream_pipe_index,
                        network_pipe_ids[pipe_number],
                        downstream_us_pit_id,
                        downstream_ds_pit_id);
                }

                Null(downstream_string);
            }

            // Process all direct upstream relationships after the outlet.
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

                        Process_same_string_upstream_pipe(
                            current_string,
                            current_pit_index,
                            current_network_pit_id,
                            pipe_string,
                            pipe_index,
                            network_pipe_ids[pipe_number],
                            upstream_network_pit_id,
                            downstream_network_pit_id);
                    }
                    else
                    {
                        cross_string_incoming_count++;

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

                        Process_cross_string_incoming_pipe(
                            current_string,
                            current_pit_index,
                            current_network_pit_id,
                            pipe_string,
                            pipe_index,
                            network_pipe_ids[pipe_number],
                            upstream_network_pit_id,
                            downstream_network_pit_id);
                    }
                }

                if(pipe_uid_rc==0)
                {
                    Null(pipe_string_uid);
                }

                Null(pipe_string);
            }

            QA_finalise_current_pit_report();

            Null(QA_downstream_string);

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

    Null(drainage_network);
    return 0;
}

/* ============================ Panel ============================ */void mainPanel()
{
  Text panelName="ACCoP Stormwater QA Check";
  Panel              panel      = Create_panel              (panelName, TRUE);
  Vertical_Group     vgroup     = Create_vertical_group     (-1             );
  Colour_Message_Box cmbMsg     = Create_colour_message_box (""             );
  Log_Box            lb_report  = Create_log_box            ("ACCoP Stormwater Report",90, 14);

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
  Append(mb_drainage_model, vgroup);
  Append(cmbMsg,            vgroup);
  Append(lb_report,         vgroup);
  Append(bgroup,            vgroup);
  Append(vgroup,            panel);
  Show_widget(panel);

  Integer doit=1;
  while(doit)
  {
      Text cmd="";
      Text msg="";
      Integer id;
      Integer ret=Wait_on_widgets(id,cmd,msg);

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
          if(cmd=="Panel Quit") doit=0;
          if(cmd=="Panel About") about_panel(panel);
      }
      break;

      case Get_id(process) :
      {
          if(cmd=="process")
          {
              Clear(lb_report);

              Model selected_model;
              Text model_name="";
              Integer validate_rc=
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

                  Null(QA_downstream_string);
              Null(selected_model);
                  continue;
              }

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

              QA_start_canonical_report(
                  lb_report,
                  model_name);

              Integer traversal_rc=
                  Traverse_drainage_network(
                      selected_model);

              if(traversal_rc==0)
              {
                  Set_data(
                      cmbMsg,
                       "Stormwater QA completed: "+
                      model_name+
                      " [canonical pits="+To_text(QA_pit_count)+
                      "; same-string upstream="+To_text(QA_same_string_upstream_count)+
                      "; cross-string incoming="+To_text(QA_cross_string_incoming_count)+
                      "; same-string flagged="+To_text(QA_same_string_check_failure_count)+
                      "; cross-string flagged="+To_text(QA_cross_string_check_failure_count)+
                      "; pits flagged="+To_text(QA_report_error_pit_count)+"; missing pit depth="+To_text(QA_pit_depth_missing_count)+"]",
                      1);
              }
              else
              {
                  Set_data(
                      cmbMsg,
                      "Network traversal failed. Return: "+
                      To_text(traversal_rc),
                      2);
              }

              Null(QA_downstream_string);
              Null(selected_model);
          }
      }
      break;

      default :
      {
          if(cmd=="Finish") doit=0;
      }
      break;
      }
  }

  Null(QA_downstream_string);
}

void main()
{
    mainPanel();
}
