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
#define BUILD "V15.0.001"

#include "..\\..\\include/standard_library.H"
#include "..\\..\\include/size_of.H"

/*global variables*/{
  /* ============================ Limits ============================ */
  #define MAX_STRINGS  1500
  #define MAX_OCC      30000

  /* -------------------- Tolerances -------------------- */
  Real DROP_TOL = 0.005;   /* 5 mm drop tolerance */
  Real EPS_DEF  = 0.05;    /* 0.05 deg deflection tolerance */

  /* ============================ REPORT STORAGE ============================ */

  #define MAX_PIT_MSG   20
  #define MAX_PITS_ALL  MAX_OCC

  Integer PIT_has_error[MAX_PITS_ALL+1];
  Integer PIT_msg_count[MAX_PITS_ALL+1];

  Text    PIT_msg[MAX_PITS_ALL*MAX_PIT_MSG+1];
  Integer PIT_msg_level[MAX_PITS_ALL*MAX_PIT_MSG+1];

  Integer STRING_has_error[MAX_STRINGS+1];

  /* Per-string */
  Element STR_s[MAX_STRINGS+1];
  Integer STR_flows_to_trunk[MAX_STRINGS+1];
  Integer STR_dir[MAX_STRINGS+1];
  Integer STR_npits[MAX_STRINGS+1];
  Integer STR_is_trunk[MAX_STRINGS+1];
  Integer STR_occ_start[MAX_STRINGS+1];
  Integer SCOUNT = 0;

  /* Per-pit occurrence */
  Text    OCC_pit_name[MAX_OCC+1];
  Integer OCC_str_idx[MAX_OCC+1];
  Integer OCC_pit_idx[MAX_OCC+1];
  Integer OCC_us_pipe_idx[MAX_OCC+1];
  Integer OCC_ds_pipe_idx[MAX_OCC+1];
  Integer OCC_COUNT = 0;

}

/* ============================ Helpers =========================== */
void reset_run_state()
{

    /* ---- reset per-string storage ---- */
    Integer si = 1;
    while(si <= MAX_STRINGS){
        STR_occ_start[si]   = 0;
        STR_npits[si]       = 0;
        STR_is_trunk[si]    = 0;
        STR_dir[si]         = 0;
        STRING_has_error[si]= 0;
        si = si + 1;
    }

    /* ---- reset per-occurrence storage ---- */
    Integer i = 1;
    while(i <= MAX_OCC){
        OCC_pit_name[i]     = "";
        OCC_str_idx[i]      = 0;
        OCC_pit_idx[i]      = 0;
        OCC_us_pipe_idx[i]  = 0;
        OCC_ds_pipe_idx[i]  = 0;

        PIT_has_error[i]    = 0;
        PIT_msg_count[i]    = 0;

        i = i + 1;
    }

    /* ---- reset flat message buffers (optional but safe) ---- */
    Integer f = 1;
    while(f <= MAX_OCC * MAX_PIT_MSG){
        PIT_msg[f]       = "";
        PIT_msg_level[f] = 0;
        f = f + 1;
    }

    /* ---- reset counters last ---- */
    SCOUNT    = 0;
    OCC_COUNT = 0;
}

Integer is_drainage(Element e){
  Integer n=0; if(Get_drainage_pits(e,n)!=0) return 0; return (n>0);
}

void add_pit_occurrence(Text pit_name, Integer si, Integer p, Integer us_k, Integer ds_k){

    if(OCC_COUNT >= MAX_OCC) return;

    OCC_COUNT = OCC_COUNT + 1;

    OCC_pit_name[OCC_COUNT]      = pit_name;
    OCC_str_idx[OCC_COUNT]       = si;
    OCC_pit_idx[OCC_COUNT]       = p;
    OCC_us_pipe_idx[OCC_COUNT]   = us_k;
    OCC_ds_pipe_idx[OCC_COUNT]   = ds_k;

    /* store starting OCC index for this string */
    if(p == 1){
        STR_occ_start[si] = OCC_COUNT;
    }
}

Integer find_occ(Integer si, Integer p){

    Integer i = 1;
    while(i <= OCC_COUNT){
        if(OCC_str_idx[i] == si && OCC_pit_idx[i] == p)
            return i;
        i = i + 1;
    }

    return 0;
}

Integer valid_pipe_index(Integer si, Integer k){
  /* guard invalid string index */
  if(si <= 0 || si > SCOUNT) return 0;
  if(k<=0) return 0;
  Integer np = STR_npits[si];
  if(np<=1) return 0;
  if(k>=1 && k<=np-1) return 1;
  return 0;
}

void harvest_from_selection(Dynamic_Element sel)
{
  Integer n=0; Get_number_of_items(sel, n);
  Integer i=1;
  while(i<=n){
    Element s; Get_item(sel, i, s);                 /* ID=128 */

    Integer npits=0;
    if(Get_drainage_pits(s,npits)!=0 || npits<=0){ i=i+1; continue; }  /* drainage only */

    Integer dir=1; Get_drainage_flow(s, dir);
    Element trunk_el; 
    Integer rc_tr = Get_drainage_trunk(s, trunk_el);

    /* Manual semantics:
      rc_tr == 0  → this string flows into a trunk (branch)
      rc_tr == 44 → downstream is outlet
      other nonzero → no trunk relationship determined
    */
    Integer flows_to_trunk = (rc_tr == 0); /* ID=1444 */

    Integer is_tr = (rc_tr==0) ? 0 : 1;  /* 0=branch, nonzero=trunk */

    if(SCOUNT < MAX_STRINGS){
      SCOUNT = SCOUNT + 1;
      STR_s[SCOUNT]        = s;
      STR_flows_to_trunk[SCOUNT] = flows_to_trunk;
      STR_dir[SCOUNT]      = dir;
      STR_npits[SCOUNT]    = npits;

      Integer p=1;
      while(p<=npits){
        Integer prev_k = (p>1)     ? (p-1) : 0;  /* pipe just upstream if dir==1 */
        Integer next_k = (p<npits) ?  p   : 0;  /* pipe just downstream if dir==1 */
        Integer us_k   = (dir==1) ? prev_k : next_k;
        Integer ds_k   = (dir==1) ? next_k : prev_k;

        Text pname=""; Get_drainage_pit_name(s, p, pname);
        add_pit_occurrence(pname, SCOUNT, p, us_k, ds_k);

        p = p + 1;
      }
    }
    i = i + 1;
  }
}

/* Resolve DS pipe for pit p on string si. Returns 1 if found. */
Integer resolve_ds_pipe(Integer si, Integer p, Integer &out_si, Integer &out_k, Text &out_name){
  out_si = si; out_k = 0; out_name="[none]";

  Integer occ = find_occ(si,p); if(occ==0) return 0;

  /* local DS first */
  Integer local_k = OCC_ds_pipe_idx[occ];
  if(valid_pipe_index(si,local_k)){
    out_k = local_k;
    Get_drainage_pipe_name(STR_s[si], out_k, out_name);
    return 1;
  }

  /* otherwise look at other strings sharing the same pit */
  Text key = OCC_pit_name[occ];

  /* prefer a trunk */
  Integer i=1;
  while(i<=OCC_COUNT){
    if(OCC_pit_name[i]==key && OCC_str_idx[i]!=si){
      Integer osi = OCC_str_idx[i];
      if(STR_flows_to_trunk[osi]==0){
        Integer ok = OCC_ds_pipe_idx[i];
        if(valid_pipe_index(osi,ok)){
          out_si=osi; out_k=ok; Get_drainage_pipe_name(STR_s[osi], out_k, out_name); return 1;
        }
      }
    }
    i=i+1;
  }
  /* then any other */
  Integer j=1;
  while(j<=OCC_COUNT){
    if(OCC_pit_name[j]==key && OCC_str_idx[j]!=si){
      Integer osi = OCC_str_idx[j];
      Integer ok = OCC_ds_pipe_idx[j];
      if(valid_pipe_index(osi,ok)){
        out_si=osi; out_k=ok; Get_drainage_pipe_name(STR_s[osi], out_k, out_name); return 1;
      }
    }
    j=j+1;
  }
  return 0;
}

/* ============================ Printing ============================ */
void print_pipe_line(Element drain, Text prefix, Integer idx)
{
  Text name=""; Real pipe_dn=0.0, grade=0.0;
  Get_drainage_pipe_name(drain, idx, name);
  Get_drainage_pipe_nominal_diameter(drain, idx, pipe_dn);
  Get_drainage_pipe_grade(drain, idx, grade);

  Real inv_us=0.0, inv_ds=0.0; Integer got_us=0, got_ds=0;
  if(Get_drainage_pipe_attribute(drain, idx, "invert us", inv_us) == 0) got_us=1;
  if(Get_drainage_pipe_attribute(drain, idx, "invert ds", inv_ds) == 0) got_ds=1;
  if(!got_us || !got_ds){
    Real lhs=0.0, rhs=0.0;
    if(Get_drainage_pipe_inverts(drain, idx, lhs, rhs) == 0){
      if(!got_us) inv_us = lhs;
      if(!got_ds) inv_ds = rhs;
    }
  }

  Real drop_val = 0.0, ds_defl=0.0, pipe_length=0.0, min_cover=0.0, vel_10=0.0, vel_2=0.0;
  Get_drainage_pipe_attribute(drain, idx, "calculated pipe length", pipe_length);
  Get_drainage_pipe_attribute(drain, idx, "calculated drop",          drop_val);
  Get_drainage_pipe_attribute(drain, idx, "calculated ds deflection", ds_defl);
  ds_defl = Absolute(ds_defl);
  Get_drainage_pipe_attribute(drain, idx, "minimum cover", min_cover);
  Get_drainage_pipe_attribute(drain, idx, "10yr ARI/normal velocity", vel_10);
  Get_drainage_pipe_attribute(drain, idx, "2yr ARI/normal velocity",  vel_2);

  Real grade_pct = (grade>0.0) ? 100.0/grade : 0.0;

}

// helper: store pit message (12dPL-safe)
void store_pit_msg(Integer occ_idx, Text msg, Integer level)
{
    if(occ_idx <= 0) return;
    if(occ_idx > OCC_COUNT) return;   /* ADD THIS GUARD */
    
    if(PIT_msg_count[occ_idx] >= MAX_PIT_MSG) return;

    PIT_msg_count[occ_idx] = PIT_msg_count[occ_idx] + 1;
    Integer m = PIT_msg_count[occ_idx];

    Integer flat = (occ_idx-1)*MAX_PIT_MSG + m;

    if(flat <= 0) return;  /* defensive */
    if(flat > MAX_OCC*MAX_PIT_MSG) return;  /* defensive */

    PIT_msg[flat]       = msg;
    PIT_msg_level[flat] = level;

    if(level == 3)
        PIT_has_error[occ_idx] = 1;
}

/* Convenience: get outlet pipe using local ds_idx, else resolver */
Integer get_outlet_pipe(Integer si, Integer p, Integer ds_idx,
                        Integer &o_si, Integer &o_k, Text &o_name)
{
  o_si = si; o_k = 0; o_name = "[none]";
  if(valid_pipe_index(si, ds_idx)){
    o_k = ds_idx;
    Get_drainage_pipe_name(STR_s[o_si], o_k, o_name);
    return 1;
  }
  return resolve_ds_pipe(si, p, o_si, o_k, o_name);
}


// Get pit depth with fallback if attribute missing
Integer get_pit_depth(Element drain, Integer p_idx, Real &depth_m)
{
  Real d=0.0;
  if(Get_drainage_pit_attribute(drain, p_idx, "pit depth", d) == 0) { depth_m = d; return 0; }
  Real cover=0.0, ds_inv=0.0;
  if(Get_drainage_pit_attribute(drain, p_idx, "cover rl", cover) != 0) return 1;
  if(Get_drainage_pit_attribute(drain, p_idx, "ds invert", ds_inv) != 0) return 1;
  depth_m = cover - ds_inv;
  return 0;
}

// Read pit DN (mm) from text first, then numeric fallback
Real get_pit_dn_mm(Element drain, Integer p_idx)
{
  Text pit_dn_txt=""; Real pit_dn=0.0;
  if(Get_drainage_pit_attribute(drain, p_idx, "lplot Nominal Diameter", pit_dn_txt) == 0) {
    From_text(pit_dn_txt, pit_dn);
  } else {
    Get_drainage_pit_attribute(drain, p_idx, "lplot Nominal Diameter", pit_dn);
  }
  return pit_dn;
}

// Compute panel-grade percent from pipe grade value returned by API
Real pipe_grade_percent(Real grade_val) {
  // Keep consistent with prior macro convention
  return (grade_val > 0.0) ? 100.0/grade_val : 0.0;
}

// Compute internal-fall min drop (m)
// Inputs: us_dn, ds_dn in mm, us_def_deg = |calculated ds deflection| from upstream pipe
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
void process_ww_string(Element drain, Integer si)
{
  Integer npits=0;
 if(Get_drainage_pits(drain, npits)!=0 || npits<=0)
  {
      STRING_has_error[si] = 1;
      return;
  }

  // Flow direction: 1 with chainage, 0 opposite
  Integer dir=1; Get_drainage_flow(drain, dir);

  // Walk pits in chainage order; immediate US/DS indices for the same string
  for(Integer p=1; p<=npits; p++)
  {
    Text pit_name=""; Get_drainage_pit_name(drain, p, pit_name);
    Integer occ_idx = find_occ(si, p);
    Integer pit_flags = 0;
    Integer pipe_flags = 0;

    Integer prev_idx = (p>1)     ? (p-1) : 0;
    Integer next_idx = (p<npits) ?  p    : 0;
    Integer us_idx = (dir==1) ? prev_idx : next_idx;
    Integer ds_idx = (dir==1) ? next_idx : prev_idx;

    // Pipe diameters, grade, deflection, length
    Real us_dn=0.0, ds_dn=0.0, us_grade=0.0, ds_grade=0.0, us_def=0.0, pipe_len=0.0;
    if(us_idx>0){
      Get_drainage_pipe_nominal_diameter(drain, us_idx, us_dn);
      Get_drainage_pipe_grade(drain, us_idx, us_grade);
      Get_drainage_pipe_attribute(drain, us_idx, "calculated ds deflection", us_def);
      us_def = Absolute(us_def);
    }
    if(ds_idx>0){
      Get_drainage_pipe_nominal_diameter(drain, ds_idx, ds_dn);
      Get_drainage_pipe_grade(drain, ds_idx, ds_grade);
      Get_drainage_pipe_attribute(drain, ds_idx, "calculated pipe length", pipe_len);
    }

    // Pit depth and DN
    Real pit_depth=0.0; get_pit_depth(drain, p, pit_depth);
    Real pit_dn = get_pit_dn_mm(drain, p);

    // If downstream pit, use pipe-to-pipe; at terminal, compare to sump if available
    Integer is_upstream   = ((dir==1 && p==1)    || (dir==0 && p==npits)) ? 1 : 0;
    Integer is_downstream = ((dir==1 && p==npits)|| (dir==0 && p==1))     ? 1 : 0;

    Integer is_blank_cap = (pit_dn <= 0.0);

    Integer is_terminal_end = (us_idx == 0);
    Real extension_len = pipe_len;
    Integer skip_min_dia = (is_terminal_end && extension_len <= 55.0 && is_blank_cap);

    // Inverts and measured MH drop across pit (positive means step down across pit)
    Real inv_us_ds=0.0, inv_ds_us=0.0, sump=0.0, mh_drop=0.0;
    if(us_idx>0) Get_drainage_pipe_attribute(drain, us_idx, "invert ds", inv_us_ds);
    if(ds_idx>0) Get_drainage_pipe_attribute(drain, ds_idx, "invert us", inv_ds_us);

    if(!is_upstream){
      if(is_downstream) {
        if(us_idx>0){
          Get_drainage_pit_attribute(drain, p, "sump level", sump);
          mh_drop = inv_us_ds - sump;
        }
      } else {
        if(us_idx>0 && ds_idx>0){
          mh_drop = inv_us_ds - inv_ds_us;
        }
      }
    }

    // -------- CHECK 1: pipe on steep grade ≥10% → bedding 7 MPa --------
    if(us_idx>0) {
      Real us_grade_pct = pipe_grade_percent(us_grade);
      if(us_grade_pct >= 10.0 && us_grade_pct <= 20.0) {
        pipe_flags = 1; // steep
        store_pit_msg(occ_idx, "WW_CoP 5.3.7.11: Pipe grade " + To_text(us_grade_pct,2) + "% requires pipe bedding min. 7MPa scoria concrete", 2);
        PIT_has_error[occ_idx] = 1;
        STRING_has_error[si] = 1;
      }
    }

    // -------- CHECK 2: pipe grade ≥20% → anchor blocks --------
    if(us_idx>0) {
      Real us_grade_pct = pipe_grade_percent(us_grade);
      if(us_grade_pct >= 20.0) {
        pipe_flags = 1; // very steep
        store_pit_msg(occ_idx, "WW_CoP 5.3.7.11: Pipe grade " + To_text(us_grade_pct,2) + "% requires anchor blocks (6 m spacings)", 1);
      }
    }

    // -------- CHECK 3: distance between pits (pipe length proxy) >100 m --------
    if(ds_idx>0) {
      if(pipe_len > 100.0) {
        pipe_flags = 1; // pits too far apart
        store_pit_msg(occ_idx, "WW_CoP 5.3.8.3: Pipe length " + To_text(pipe_len,1) + " m exceeds 100 m maximum between pits", 2);
        PIT_has_error[occ_idx] = 1;
        STRING_has_error[si] = 1;
      }
    }

    Integer is_branch = STR_flows_to_trunk[si]; // check if it is branch
    Integer is_branch_outlet = (is_branch && ds_idx == 0); // downstream end of branch

    if(!skip_min_dia && !is_branch_outlet)
    {
        // -------- CHECK 4: Minimum pit sizes by depth --------

        Integer req_dia = 0;

        if     (pit_depth < 3.0)      req_dia = 1050;
        else if(pit_depth <= 6.0)     req_dia = 1200;
        else                          req_dia = 1500;

        // --- Override: Internal dropper required ---
        // If drop across pit exceeds 150 mm (with tolerance),
        // minimum MH must be 1200 regardless of depth.

        Real dropper_limit = 0.15;   // 150 mm

        if((mh_drop - dropper_limit) > DROP_TOL)
        {
            if(req_dia < 1200)
                req_dia = 1200;
        }

        if(req_dia > 0 && Absolute(pit_dn - req_dia) > 1.0)
        {
            pit_flags = 1;

            store_pit_msg(occ_idx,
                "WW_CoP 5.3.8.4: Manhole DIA should be "
                + To_text(req_dia)
                + " mm (depth "
                + To_text(pit_depth,2)
                + " m; found "
                + To_text(pit_dn,0)
                + " mm)",
                2);

            PIT_has_error[occ_idx] = 1;
            STRING_has_error[si]   = 1;
        }
    }


    // -------- CHECK 5: Internal falls (minimum drop) --------
    if(us_idx > 0)
    {
      Real min_drop = ww_min_drop_m(us_dn, ds_dn, us_def);

      // Only flag if shortfall exceeds tolerance
      if((min_drop - mh_drop) > DROP_TOL)
      {
        pipe_flags = 1;
        store_pit_msg(occ_idx, "WW_CoP 5.3.8.4: Internal fall below minimum " + To_text(min_drop,3) + " m (found " + To_text(mh_drop,3) + " m)", 2);
        PIT_has_error[occ_idx] = 1;
        STRING_has_error[si]   = 1;
      }
    }

    // -------- CHECK 6: Allowance for steep pipe grade (>7%) --------
    if(us_idx>0) {

      Real us_grade_pct = pipe_grade_percent(us_grade);

      if(us_grade_pct > 7.0) {

        // 6.1 Depth by size (use upstream pipe size)

        if(us_dn <= 225.0 && !(pit_depth > 1.5)) {
          pipe_flags = 1;

          store_pit_msg(occ_idx,
            "WW_CoP 5.3.8.4.5: For DN<=225 and grade>7%, pit depth must be >1.5 m (found "
            + To_text(pit_depth,2) + " m)",
            2);

          PIT_has_error[occ_idx] = 1;
          STRING_has_error[si] = 1;
        }

        if(us_dn >= 300.0 && !(pit_depth > 2.0)) {
          pipe_flags = 1;

          store_pit_msg(occ_idx,
            "WW_CoP 5.3.8.4.5: For DN>=300 and grade>7%, pit depth must be >2.0 m (found "
            + To_text(pit_depth,2) + " m)",
            2);

          PIT_has_error[occ_idx] = 1;
          STRING_has_error[si] = 1;
        }

        // 6.2 Deflection <45°
        if((us_def - 45.0) > EPS_DEF) {
          pipe_flags = 1;

          store_pit_msg(occ_idx,
            "WW_CoP 5.3.8.4.5: For grade>7%, deflection must be <45deg (found "
            + To_text(us_def,1) + "°)",
            2);

          PIT_has_error[occ_idx] = 1;
          STRING_has_error[si] = 1;
        }

        // 6.3 Max drop = DN (m) or internal dropper required
        Real min_drop = ww_min_drop_m(us_dn, ds_dn, us_def);
        Real max_drop = us_dn / 1000.0;

        if((mh_drop - max_drop) > DROP_TOL) {
          pipe_flags = 1;
          store_pit_msg(occ_idx, "WW_CoP 5.3.8.4.5: Internal fall exceeds " + To_text(max_drop,3) + " m (found " + To_text(mh_drop,3) + " m). Internal dropper to be provided.", 2);
          PIT_has_error[occ_idx] = 1;
          STRING_has_error[si] = 1;
        }
      }
    }
    if (pipe_flags == 1){
        print_pipe_line(drain, "US ", us_idx);
    }

    if (pit_flags == 0 && pipe_flags == 0){
        store_pit_msg(occ_idx, "CoP Check = OK", 1);
    }
  }
}

void build_log(Log_Box lb_report)
{
    Integer string_level = 1;
    Integer pit_level    = 1;
    Integer clause_level = 1;

    Integer si = 1;

    while(si <= SCOUNT)
    {
        Element drain = STR_s[si];

        Text sname = "";
        Get_name(drain, sname);

        Text header = "=== WW String: " + sname;

        if(STRING_has_error[si] == 0)
            header = header + "  Complies with CoP ===";
        else
            header = header + "  Does NOT comply with CoP - See details below ===";

        Log_Line string_group =
            Create_group_log_line(header, string_level);

        Add_log_line(lb_report, string_group);

        Integer occ_start = STR_occ_start[si];
        Integer occ_end;

        if(si < SCOUNT)
            occ_end = STR_occ_start[si+1] - 1;
        else
            occ_end = OCC_COUNT;

        Integer occ_idx = occ_start;

        while(occ_idx <= occ_end)
        {
            Text pit_name = OCC_pit_name[occ_idx];

            Text pit_header = "Pit = [" + pit_name + "]";

            if(PIT_has_error[occ_idx] == 0)
                pit_header = pit_header;
            else
                pit_header = pit_header + "  Expand to see errors";

            Log_Line pit_group =
                Create_group_log_line(pit_header, pit_level);

            Append_log_line(pit_group, string_group);

            // --- Pan to pit ---
            Real px, py, pz;
            Get_drainage_pit(drain,
                             OCC_pit_idx[occ_idx],
                             px, py, pz);

            Log_Line hl =
                Create_highlight_point_log_line(
                    "Pan to Pit",
                    1,
                    px, py, pz);

            Append_log_line(hl, pit_group);

            // --- Add stored messages ---
            Integer base =
                (occ_idx - 1) * MAX_PIT_MSG;

            Integer m = 1;
            while(m <= PIT_msg_count[occ_idx])
            {
                Text msg =
                    PIT_msg[base + m];

                Integer level =
                    PIT_msg_level[base + m];

                Log_Line clause =
                    Create_text_log_line(msg, level);

                Append_log_line(clause, pit_group);

                m = m + 1;
            }

            occ_idx = occ_idx + 1;
        }

        si = si + 1;
    }
}

void release_drainage_handles()
{
    Integer i = 1;
    while(i <= SCOUNT){
        Null(STR_s[i]);
        i = i + 1;
    }
}

/* ============================ Panel ============================ */
void mainPanel()
{
    Text panelName="ACCoP WW Check";
    Panel              panel      = Create_panel              (panelName, TRUE);
    Vertical_Group     vgroup     = Create_vertical_group     (-1             );
    Colour_Message_Box cmbMsg     = Create_colour_message_box (""             );
    Log_Box            lb_report  = Create_log_box            ("WSL Wastewater Report",90, 14);

    ///////////////////CREATE INPUT WIDGETS////////////////
    /* Scope selection (model/view/strings) */
    Source_Box scope = Create_source_box("Scope (model/view/strings)", cmbMsg, 0);

    ///////////////ADDING BUTTONS ALONG THE BOTTOM///////////////////////////
    Horizontal_Group bgroup = Create_button_group();
    Button process     = Create_button       ("&Process" ,"process");
    Button finish      = Create_finish_button("Finish"   ,"Finish" );
    Button help_button = Create_help_button  (panel      ,"Help"   );
    Append(process      ,bgroup);
    Append(finish       ,bgroup);
    Append(help_button  ,bgroup);

    ///////////////ADDING WIDGETS TO PANEL///////////////////////////
    Append(scope, vgroup);
    Append(cmbMsg,   vgroup);
    Append(lb_report, vgroup);
    Append(bgroup,  vgroup);
    Append(vgroup,  panel);
    Show_widget(panel);

    Integer doit = 1;
    while(doit)
    {
        Text cmd=""; Text msg = "";
        Integer id, ret = Wait_on_widgets(id,cmd,msg);

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

        case Get_id(process):
        {
          if(cmd == "process")
          {
            // Clear log box
            Clear(lb_report);
            
            Dynamic_Element sel;
            Integer rc = Validate(scope, sel);
            Integer n=0; Get_number_of_items(sel, n);
            if(n<=0){ Set_data(cmbMsg, "Select a model/view/strings in data set.", 2); continue; }
            
            reset_run_state();

            harvest_from_selection(sel);

            if(SCOUNT==0){
                Set_data(cmbMsg, "No drainage strings in data set.", 2);
                continue;
            }

            Integer si=1;
            while(si<=SCOUNT){

                Element drain = STR_s[si];

                Text sname="";
                Get_name(drain, sname);

                /* per-string checks */
                process_ww_string(drain, si);
                si = si + 1;
            }

            build_log(lb_report);

            Set_data(cmbMsg, "Done. Check report below.", 1);
            // release per-run handles
            release_drainage_handles();
            Null(sel);
            
          }
        }
        break;
        default:
        {
            if(cmd == "Finish") doit = 0;
        }
        break;
        }
    }
}
void main(){

    // do some checks before you go to the main panel


    mainPanel();
}
/*---------------------------------------------------------------------
**   Macro:   ACCoP_WW_Check.4dm*/