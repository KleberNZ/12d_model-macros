/*---------------------------------------------------------------------
**   Programmer:Kleber Lessa do Prado
**   Company: The Neil Group
**   Date:17/09/25             
**   12D Model:            Vversion
**   Version:              002
**   Macro Name:           ACCoP_WW_Check.4dm
**   Type:                 Drainage QA
**
**   Brief description: Checks wastewater drainage strings against 
**               Auckland Watercare CoP (Chapter 5) for compliance
**               with pipe grade, pit spacing, pit size, internal
**                falls, and steep grade rules.
**
**---------------------------------------------------------------------
**   Description: 
**
** This macro, ACCoP_WW_Check.4dm, analyses wastewater drainage strings in 12d Model against the requirements of the Auckland Watercare Code of Practice (Chapter 5).
** After selecting one or more wastewater strings, the macro lists pits and pipe connections, then validates them against key CoP rules:
** Pipe grades: Flags steep grades ≥10% for 7 MPa scoria bedding and ≥20% for anchor blocks at 6 m spacing.
** Pit spacing: Checks maximum pipe length between pits ≤100 m .
** Minimum pit sizes: Enforces 1050 mm for depth <3 m, 1200 mm for depth 3–6 m, and 1500 mm for depth >6 m.
** Internal falls: Ensures correct minimum drop when DS pipe is larger than US pipe, or when deflection angle dictates minimum drop (0.03–0.08 m).
** Steep grade allowance (>7%): Verifies minimum pit depth, maximum deflection (<45°), and drop limits (min drop).
** All failures are reported in the Output window with explicit Watercare CoP clause references (e.g. WW_CoP 5.3.7.11, WW_CoP 5.3.8.3).
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

#define DEBUG_FILE      0
#define ECHO_DEBUG_FILE 0
#define ECHO_LINE_NO    0
#define DEBUG_NETWORK_RELATIONSHIPS 0
#define BUILD "V15.0.001"

#include "standard_library.H"
#include "size_of.H"

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
  Integer QA_downstream_pipe_count = 0;
  Integer QA_downstream_check_failure_count = 0;

  /* ===================== Current downstream-pipe context ===================== */
  Integer QA_have_downstream_pipe = 0;
  Element QA_downstream_string;
  Integer QA_downstream_pipe_index = 0;
  Integer QA_downstream_network_pipe_id = 0;

  Real QA_downstream_nominal_diameter = 0.0;
  Real QA_downstream_invert_us = 0.0;
  Real QA_downstream_pipe_length = 0.0;

  Integer QA_have_downstream_nominal_diameter = 0;
  Integer QA_have_downstream_invert_us = 0;
  Integer QA_have_downstream_pipe_length = 0;

  /* ===================== Canonical report state ===================== */
  Log_Line QA_report_model_group;
  Log_Line QA_report_current_pit_group;

  Integer QA_report_active = 0;
  Integer QA_report_current_pit_has_error = 0;
  Integer QA_report_error_pit_count = 0;

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


}

/* ============================ Helpers =========================== */
Real ww_min_drop_m(Real us_dn, Real ds_dn, Real us_def_deg)
{
  if(ds_dn > us_dn) {
    // soffit-to-soffit: minimum = size difference (m)
    return (ds_dn - us_dn) / 1000.0;
  }
  // same size or DS smaller: use angle bands
  if(us_def_deg <= 30.0) return 0.03; // 30 mm (for up to 30 deg)
  if(us_def_deg <= 60.0) return 0.05; // 50 mm (for >30 to 60)
  return 0.08; // 80 mm (for >60 to 120)
}

// Apply Watercare checks for a string, printing per-pit messages

void Output_line(Text text)
{
    Print(text);
    Print();
}


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
    QA_downstream_invert_us = 0.0;
    QA_downstream_pipe_length = 0.0;
    QA_have_downstream_nominal_diameter = 0;
    QA_have_downstream_invert_us = 0;
    QA_have_downstream_pipe_length = 0;
}


// ------------------------------------------------------------------
// CANONICAL REPORT HELPERS
// ------------------------------------------------------------------

void QA_start_canonical_report(
    Log_Box lb_report,
    Text model_name)
{
    QA_report_active=1;
    QA_report_current_pit_has_error=0;
    QA_report_error_pit_count=0;

    QA_report_model_group=
        Create_group_log_line(
            "=== Drainage Model: "+model_name+" ===",
            1);

    Add_log_line(
        lb_report,
        QA_report_model_group);
}

void QA_start_current_pit_report()
{
    QA_report_current_pit_has_error=0;

    if(!QA_report_active) return;

    QA_report_current_pit_group=
        Create_group_log_line(
            "Pit = ["+QA_current_pit_name+
            "]  String = ["+QA_current_string_name+"]",
            1);

    Append_log_line(
        QA_report_current_pit_group,
        QA_report_model_group);

    if(QA_have_current_pit_coordinates)
    {
        Log_Line highlight=
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
    QA_report_current_pit_has_error=1;

    if(QA_report_active)
    {
        Log_Line clause=
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

void QA_report_info(Text message)
{
    if(QA_report_active)
    {
        Log_Line clause=
            Create_text_log_line(
                message,
                1);

        Append_log_line(
            clause,
            QA_report_current_pit_group);
    }

    if(DEBUG_NETWORK_RELATIONSHIPS)
    {
        Output_line(
            "    QA INFO: "+message);
    }
}

void QA_finalise_current_pit_report()
{
    if(!QA_report_active) return;

    if(QA_report_current_pit_has_error)
    {
        QA_report_error_pit_count=
            QA_report_error_pit_count+1;
    }
    else
    {
        Log_Line clause=
            Create_text_log_line(
                "CoP Check = OK",
                1);

        Append_log_line(
            clause,
            QA_report_current_pit_group);
    }
}


// helper: checks that apply to one resolved direct-upstream wastewater pipe
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

    Text pipe_string_name="<name unavailable>";
    Get_name(pipe_string,pipe_string_name);

    Text pipe_attribute_name="<pipe name unavailable>";
    if(Get_drainage_pipe_attribute(
        pipe_string,
        pipe_index,
        "pipe name",
        pipe_attribute_name)!=0)
    {
        pipe_attribute_name="<pipe name unavailable>";
    }

    Real pipe_dn=0.0;
    Integer pipe_dn_rc=
        Get_drainage_pipe_nominal_diameter(
            pipe_string,
            pipe_index,
            pipe_dn);

    Real pipe_grade=0.0;
    Integer pipe_grade_rc=
        Get_drainage_pipe_attribute(
            pipe_string,
            pipe_index,
            "calculated pipe grade",
            pipe_grade);

    Real pipe_deflection=0.0;
    Integer pipe_deflection_rc=
        Get_drainage_pipe_attribute(
            pipe_string,
            pipe_index,
            "calculated ds deflection",
            pipe_deflection);

    if(pipe_grade_rc==0)
    {
        if(pipe_grade>=10.0 && pipe_grade<20.0)
        {
            check_failed=1;

            QA_report_error(
                "WW CoP 5.3.7.11 grade 10%-20% requires "+
                "minimum 7 MPa scoria-concrete bedding"+
                " [pipe name="+pipe_attribute_name+
                "; grade="+To_text(pipe_grade,3)+"%]"
            );
        }

        // Existing behaviour retained as informational only.
        if(pipe_grade>=20.0)
        {
            QA_report_info(
                "WW CoP 5.3.7.11 grade >=20% requires "+
                "anchor blocks at 6 m spacing"+
                " [pipe name="+pipe_attribute_name+
                "; grade="+To_text(pipe_grade,3)+"%]"
            );
        }
    }

    if(pipe_grade_rc==0 && pipe_dn_rc==0 && pipe_grade>7.0)
    {
        if(QA_have_current_pit_depth)
        {
            if(pipe_dn<=225.0 && QA_current_pit_depth<=1.5)
            {
                check_failed=1;

                QA_report_error(
                    "WW CoP 5.3.8.4.5 grade >7% with DN <=225 "+
                    "requires pit depth >1.5 m"+
                    " [pipe name="+pipe_attribute_name+
                    "; pit depth="+To_text(QA_current_pit_depth,3)+" m]"
                );
            }

            if(pipe_dn>=300.0 && QA_current_pit_depth<=2.0)
            {
                check_failed=1;

                QA_report_error(
                    "WW CoP 5.3.8.4.5 grade >7% with DN >=300 "+
                    "requires pit depth >2.0 m"+
                    " [pipe name="+pipe_attribute_name+
                    "; pit depth="+To_text(QA_current_pit_depth,3)+" m]"
                );
            }
        }

        if(pipe_deflection_rc==0 &&
           Absolute(pipe_deflection)>45.0)
        {
            check_failed=1;

            QA_report_error(
                "WW CoP 5.3.8.4.5 grade >7% requires "+
                "deflection <=45 deg"+
                " [pipe name="+pipe_attribute_name+
                "; found="+To_text(Absolute(pipe_deflection),1)+" deg]"
            );
        }
    }

    // Resolve the incoming pipe downstream invert for pit-drop checks.
    Real incoming_invert_ds=0.0;
    Integer incoming_invert_ds_rc=
        Get_drainage_pipe_attribute(
            pipe_string,
            pipe_index,
            "invert ds",
            incoming_invert_ds);

    Integer have_actual_drop=0;
    Real actual_drop=0.0;

    if(incoming_invert_ds_rc==0)
    {
        if(QA_have_downstream_invert_us)
        {
            actual_drop=
                incoming_invert_ds-
                QA_downstream_invert_us;

            have_actual_drop=1;
        }
        else if(QA_have_current_pit_sump_level)
        {
            // Network outlet: preserve the existing terminal-pit comparison.
            actual_drop=
                incoming_invert_ds-
                QA_current_pit_sump_level;

            have_actual_drop=1;
        }
    }

    // WW CoP 5.3.8.4 - minimum internal fall.
    if(
        have_actual_drop &&
        pipe_dn_rc==0 &&
        pipe_deflection_rc==0)
    {
        Real minimum_drop=
            ww_min_drop_m(
                pipe_dn,
                QA_downstream_nominal_diameter,
                Absolute(pipe_deflection));

        if((minimum_drop-actual_drop)>DROP_TOL)
        {
            check_failed=1;

            QA_report_error(
                "WW CoP 5.3.8.4 internal fall below minimum"+
                " [pipe name="+pipe_attribute_name+
                "; minimum="+To_text(minimum_drop,3)+" m"+
                "; found="+To_text(actual_drop,3)+" m]"
            );
        }
    }

    // WW CoP 5.3.8.4.5 - maximum fall for incoming grade >7%.
    if(
        have_actual_drop &&
        pipe_grade_rc==0 &&
        pipe_dn_rc==0 &&
        pipe_grade>7.0)
    {
        Real maximum_drop=
            pipe_dn/1000.0;

        if((actual_drop-maximum_drop)>DROP_TOL)
        {
            check_failed=1;

            QA_report_error(
                "WW CoP 5.3.8.4.5 internal fall exceeds "+
                To_text(maximum_drop,3)+" m; internal dropper required"+
                " [pipe name="+pipe_attribute_name+
                "; found="+To_text(actual_drop,3)+" m]"
            );
        }
    }

    // WW CoP 5.3.8.4 - minimum manhole diameter.
    // Canonical branch-end duplicate pits are not traversed. A network outlet
    // with no nominated pit diameter is retained as the terminal blank-cap case.
    Integer skip_minimum_diameter=0;

    if(
        !QA_have_downstream_pipe &&
        QA_have_current_pit_nominal_diameter &&
        QA_current_pit_nominal_diameter<=0.0)
    {
        skip_minimum_diameter=1;
    }

    if(
        !skip_minimum_diameter &&
        QA_have_current_pit_depth &&
        QA_have_current_pit_nominal_diameter)
    {
        Integer required_diameter=1050;

        if(QA_current_pit_depth>=3.0)
        {
            required_diameter=1200;
        }

        if(QA_current_pit_depth>6.0)
        {
            required_diameter=1500;
        }

        if(
            have_actual_drop &&
            (actual_drop-0.15)>DROP_TOL &&
            required_diameter<1200)
        {
            required_diameter=1200;
        }

        if(
            Absolute(
                QA_current_pit_nominal_diameter-
                required_diameter)>1.0)
        {
            check_failed=1;

            QA_report_error(
                "WW CoP 5.3.8.4 manhole diameter should be "+
                To_text(required_diameter)+" mm"+
                " [pipe name="+pipe_attribute_name+
                "; pit depth="+To_text(QA_current_pit_depth,3)+" m"+
                "; found="+To_text(QA_current_pit_nominal_diameter,0)+" mm]"
            );
        }
    }

    if(check_failed)
    {
        if(relationship_type==1)
        {
            QA_same_string_check_failure_count=
                QA_same_string_check_failure_count+1;
        }
        else
        {
            QA_cross_string_check_failure_count=
                QA_cross_string_check_failure_count+1;
        }
    }

    if(DEBUG_NETWORK_RELATIONSHIPS)
    {
        Text result_text="NO FLAG";
        Text relationship_text="SAME-STRING UPSTREAM";

        if(check_failed) result_text="FAIL";
        if(relationship_type==2)
        {
            relationship_text="CROSS-STRING INCOMING";
        }

        Output_line(
            "    QA CHECKED: "+
            relationship_text+
            " / "+
            pipe_string_name+
            " / pipe "+To_text(pipe_index)+
            " / result="+result_text);
    }
}


// ------------------------------------------------------------------
// PROCESSING HOOKS
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

    QA_downstream_pipe_count=
        QA_downstream_pipe_count+1;

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
            "invert us",
            QA_downstream_invert_us)==0)
    {
        QA_have_downstream_invert_us=1;
    }

    if(
        Get_drainage_pipe_attribute(
            pipe_string,
            pipe_index,
            "calculated pipe length",
            QA_downstream_pipe_length)==0)
    {
        QA_have_downstream_pipe_length=1;
    }

    // WW CoP 5.3.8.3 - maximum spacing/pipe length between pits.
    if(
        QA_have_downstream_pipe_length &&
        QA_downstream_pipe_length>100.0)
    {
        QA_downstream_check_failure_count=
            QA_downstream_check_failure_count+1;

        Text downstream_pipe_name="<pipe name unavailable>";

        if(
            Get_drainage_pipe_attribute(
                pipe_string,
                pipe_index,
                "pipe name",
                downstream_pipe_name)!=0)
        {
            downstream_pipe_name="<pipe name unavailable>";
        }

        QA_report_error(
            "WW CoP 5.3.8.3 pipe length exceeds 100 m"+
            " [pipe name="+downstream_pipe_name+
            "; found="+To_text(QA_downstream_pipe_length,1)+" m]"
        );
    }
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

            Integer same_string_upstream_count=0;
            Integer cross_string_incoming_count=0;
            Integer downstream_pipe_count=0;
            Integer pipe_number=0;

            // Resolve the downstream pipe first so every incoming-pipe check
            // has the correct outlet diameter and invert context.
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

            // Process every direct incoming pipe after the downstream context.
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
  Text panelName="ACCoP Wastewater QA Check";
  Panel              panel      = Create_panel              (panelName, TRUE);
  Vertical_Group     vgroup     = Create_vertical_group     (-1             );
  Colour_Message_Box cmbMsg     = Create_colour_message_box (""             );
  Log_Box            lb_report  = Create_log_box            ("ACCoP Wastewater Report",90, 14);

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

              QA_pit_count=0;
              QA_pit_depth_missing_count=0;
              QA_same_string_upstream_count=0;
              QA_cross_string_incoming_count=0;
              QA_same_string_check_failure_count=0;
              QA_cross_string_check_failure_count=0;
              QA_downstream_pipe_count=0;
              QA_downstream_check_failure_count=0;
              QA_report_current_pit_has_error=0;
              QA_report_error_pit_count=0;

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
                      "Wastewater QA completed: "+
                      model_name+
                      " [canonical pits="+To_text(QA_pit_count)+
                      "; same-string upstream="+To_text(QA_same_string_upstream_count)+
                      "; cross-string incoming="+To_text(QA_cross_string_incoming_count)+
                      "; same-string flagged="+To_text(QA_same_string_check_failure_count)+
                      "; cross-string flagged="+To_text(QA_cross_string_check_failure_count)+
                      "; downstream pipes="+To_text(QA_downstream_pipe_count)+
                      "; downstream length flagged="+To_text(QA_downstream_check_failure_count)+
                      "; pits flagged="+To_text(QA_report_error_pit_count)+
                      "; missing pit depth="+To_text(QA_pit_depth_missing_count)+"]",
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
