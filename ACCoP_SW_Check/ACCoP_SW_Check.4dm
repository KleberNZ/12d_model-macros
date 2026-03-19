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
  Integer STR_flows_to_trunk[MAX_STRINGS+1];   /* 1 = branch (flows into trunk), 0 = trunk */
  Integer STR_dir[MAX_STRINGS+1];        /* 1 with chainage, 0 opposite */
  Integer STR_npits[MAX_STRINGS+1];
  Integer STR_is_trunk[MAX_STRINGS+1];
  Integer STR_occ_start[MAX_STRINGS+1];
  Integer SCOUNT = 0;

  /* Per-pit occurrence: one row per pit on a string */
  Text    OCC_pit_name[MAX_OCC+1];
  Integer OCC_str_idx[MAX_OCC+1];        /* index into STR_* arrays */
  Integer OCC_pit_idx[MAX_OCC+1];        /* 1..npits */
  Integer OCC_us_pipe_idx[MAX_OCC+1];    /* immediate US pipe at pit */
  Integer OCC_ds_pipe_idx[MAX_OCC+1];    /* immediate DS pipe at pit */
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
/* ============================ Core Checks ============================ */
/* Place your existing pit and pipe checks here; this version focuses
   on integrating DS resolution into the per-pit loop. */

/* Per-string processing using resolver for DS */
/* Per-string processing using resolver for DS */
void process_string(Integer si)
{
  Element drain = STR_s[si];
  Integer npits = STR_npits[si];
  Integer dir   = STR_dir[si];
  STRING_has_error[si] = 0;

  Integer p=1;
  while(p<=npits){
    Integer pit_flags = 0;
    /* reset per pit */
    Text pit_name=""; Get_drainage_pit_name(drain, p, pit_name);
    Integer occ_idx = find_occ(si, p);
    Integer prev_idx = (p>1)     ? (p-1) : 0;
    /* US if dir==1 */
    Integer next_idx = (p<npits) ?  p   : 0;
    /* DS if dir==1 */
    Integer us_idx   = (dir==1) ? prev_idx : next_idx;
    Integer ds_idx   = (dir==1) ? next_idx : prev_idx;
    /* US print on same string only */
    // print_pipe_line(drain, "US ", us_idx);
    /* Resolve DS: same string if exists, else other string via junction */
    Integer o_si, o_k;
    Text o_name="";
    Integer have_outlet = get_outlet_pipe(si, p, ds_idx, o_si, o_k, o_name);
    Integer is_upstream   = ((dir==1 && p==1)    || (dir==0 && p==npits)) ? 1 : 0;
    Integer is_downstream = ((dir==1 && p==npits)|| (dir==0 && p==1))     ? 1 : 0;
    // Pipe sizes
    Real us_dn=0.0, outlet_dn = 0.0;
    if(us_idx>0) Get_drainage_pipe_nominal_diameter(drain, us_idx, us_dn);
    if(have_outlet) Get_drainage_pipe_nominal_diameter(STR_s[o_si], o_k, outlet_dn);
        // Upstream grade and DS deflection (abs)
    Real us_grade=0.0; if(us_idx>0) Get_drainage_pipe_grade(drain, us_idx, us_grade);
    Real us_grade_pct = (us_grade>0.0) ? 100.0/us_grade : 0.0;
        
    Real us_def=0.0; if(us_idx>0) Get_drainage_pipe_attribute(drain, us_idx, "calculated ds deflection", us_def);
    us_def = Absolute(us_def);
    // Pit depth
    Real pit_depth=0.0;
    if(Get_drainage_pit_attribute(drain, p, "pit depth", pit_depth)!=0){
      Real cover=0.0, ds_inv=0.0;
      Get_drainage_pit_attribute(drain, p, "cover rl",  cover);
      Get_drainage_pit_attribute(drain, p, "ds invert", ds_inv);
      pit_depth = cover - ds_inv;
    }
      
    // Manhole drop (actual_drop). Skip for most-upstream pit.
    Real actual_drop = 0.0;
    if(!is_upstream){
      if(is_downstream){
        if(us_idx>0){
          Real inv_us_ds=0.0, sump=0.0;
          Get_drainage_pipe_attribute(drain, us_idx, "invert ds", inv_us_ds);
          Get_drainage_pit_attribute(drain, p, "sump level", sump);
          actual_drop = inv_us_ds - sump;
        }
      } else {
        if(us_idx>0 && ds_idx>0){
          Real inv_us_ds=0.0, inv_ds_us=0.0;
          Get_drainage_pipe_attribute(drain, us_idx, "invert ds", inv_us_ds);
          Get_drainage_pipe_attribute(drain, ds_idx, "invert us", inv_ds_us);
          actual_drop = inv_us_ds - inv_ds_us;
        }
      }
    }

    /* Deflection flags (always checked if US pipe exists) */
    Integer pipe_flags = 0;

    if(us_idx > 0){

        Real abs_def = Absolute(us_def);

        if(Absolute(abs_def - 90.0) < EPS_DEF)
            abs_def = 90.0;

        if(abs_def > 90.0 + EPS_DEF){
            pipe_flags = 1;
            store_pit_msg(occ_idx,
                "CoP 4.3.10.3: Not permitted (deflection >90 deg - AC approval required).",
                3);
        }
        else{
            Integer mh_req = _sw05_required_mm(us_dn, abs_def, pit_depth);
            if(mh_req == 0){
                pipe_flags = 1;
                store_pit_msg(occ_idx,
                    "CoP 4.3.10.6: Specific design required for deflection "
                    + To_text(abs_def,2) + " deg",
                    3);
            }
        }
    }

    // ---- Internal falls through manhole ----
    if(!is_upstream){
    // Real EPS = 0.002;
    // 2 mm tolerance
    Real max_dn = (us_dn > outlet_dn) ? us_dn : outlet_dn;
    // DN >= 1000 → specific design
    if(max_dn >= 1000.0){
      if(actual_drop > 0.0){
        pipe_flags = 1;
        store_pit_msg(occ_idx, "CoP 4.3.10.6: Internal fall with DN>=1000 requires specific design", 3);
      }
      } else {
        // DN < 1000 → compute min/max drop by cases
        Real min_drop = 0.05;
        // default 50 mm
        Real max_drop = 0.30;
        // default 300 mm

        if(outlet_dn == us_dn){
          // equal sizes
          if(us_dn <= 300.0 && us_grade_pct <= 7.0){
            max_drop = 1.0;
          // open cascade allowed
          } else if(us_dn > 300.0){
            max_drop = 0.30;
          } else {
            // us_dn <=300 but grade >7% → no open cascade
            max_drop = 0.30;
          }
        } else if(outlet_dn > us_dn){
          /* Fetch internal diameters (metres) */
          Real us_diam = 0.0;
          Real ds_diam = 0.0;

          Get_drainage_pipe_attribute(drain, us_idx, "diameter", us_diam);
          Get_drainage_pipe_attribute(drain, ds_idx, "diameter", ds_diam);

          /* DS larger than US → soffit-to-soffit using internal diameters
          soffit-to-soffit minimum */
          min_drop = ds_diam - us_diam;

          if((min_drop - actual_drop) > DROP_TOL){
              pipe_flags = 1;
              store_pit_msg(occ_idx,
                  "Insufficient drop: required "
                  + To_text(min_drop,3)
                  + " m, found "
                  + To_text(actual_drop,3)
                  + " m",
                  3);
          }

          if(us_dn <= 300.0 && us_grade_pct <= 7.0){
            max_drop = 1.0;
            /* open cascade allowed */
          }
          else if(us_dn > 300.0){
            max_drop = 0.30;
          }
          else{
            /* us_dn <=300 but grade >7% → no open cascade */
            max_drop = 0.30;
          }
        } else {
          // outlet_dn < us_dn → not specified;
          // use general 50–300 mm
          min_drop = 0.05;
          max_drop = 0.30;
        }

        // flag out-of-range
        if(actual_drop > 0.0 && (min_drop - actual_drop) > DROP_TOL){
          pipe_flags = 1;
          // print_pipe_line(drain, "US ", us_idx);
                store_pit_msg(occ_idx, "CoP 4.3.10.6: Internal fall below minimum " + To_text(min_drop,3) + " m (found " + To_text(actual_drop,3) + " m)", 3);
        }
        if((actual_drop - max_drop) > DROP_TOL){
          pipe_flags = 1;
          // print_pipe_line(drain, "US ", us_idx);
                store_pit_msg(occ_idx, "CoP 4.3.10.6: Internal fall above maximum " + To_text(max_drop,3) + " m (found " + To_text(actual_drop,3) + " m)", 3);
        }
      }
    } 
    // ---- end internal-falls rules --------------------------------

    // Absolute upper bound on drop
    if(actual_drop > 1.0){
      store_pit_msg(occ_idx, "CoP 4.3.10.7: Drop >1.0 m not permitted (" + To_text(actual_drop,3) + " m)", 3);
    }

    // -------- Steep grades effects (threshold 7%) --------
    if(us_grade_pct > 7.0){
      // depth allowance by size
      if(us_dn <= 225.0 && !(pit_depth > 1.5)){
        pipe_flags = 1;
        store_pit_msg(occ_idx, "CoP 4.3.10: Steep grade>7% requires depth >1.5 m for DN<=225 (found "
              + To_text(pit_depth,2) + " m)", 3);
      }
      if(us_dn >= 300.0 && !(pit_depth > 2.0)){
        pipe_flags = 1;
        store_pit_msg(occ_idx, "CoP 4.3.10: Steep grade>7% requires depth >2.0 m for DN>=300 (found "
              + To_text(pit_depth,2) + " m)", 3);
      }
      if(us_def > 45.0){
        pipe_flags = 1;
        store_pit_msg(occ_idx, "CoP 4.3.10: Steep grade>7% requires deflection <=45 deg (found "
              + To_text(us_def,1) + " deg)", 3);
      }
      if(actual_drop > 0.30){
        pipe_flags = 1;
        store_pit_msg(occ_idx, "CoP 4.3.10: No open cascade allowed when upstream grade >7% (drop "
              + To_text(actual_drop,3) + " m)", 3);
      }
    }

    // -------- SW07 (depth 4–5 m with 500–1200 outlet) --------
    if(have_outlet && pit_depth > 4.0 && pit_depth < 5.0 && outlet_dn >= 500.0 && outlet_dn <= 1200.0){
      store_pit_msg(occ_idx, "SW07: MH with in-situ concrete base required [outlet DN=" 
            + To_text(outlet_dn,0)
            + ", depth=" + To_text(pit_depth,2) + " m]", 3);
    }

    // -------- SW05 check (pit DN vs matrix) --------
    // ---  skip SW05 on most-downstream pit (no DS pipe) ---
    if(ds_idx > 0){
      // SW05: pit DN from text only, fallback real.
      // No stripping. // BUGFIX: Commented out stray text.
      Real pit_dn = 0.0; Text pit_dn_txt="";
      if(Get_drainage_pit_attribute(drain, p, "lplot Nominal Diameter", pit_dn_txt)==0){
        From_text(pit_dn_txt, pit_dn);
      } else {
        Get_drainage_pit_attribute(drain, p, "lplot Nominal Diameter", pit_dn);
      }

      Integer req_mm = _sw05_required_mm(outlet_dn, us_def, pit_depth);
      if(req_mm == 0){
        pit_flags = 1;
        store_pit_msg(occ_idx, "SW05 check: Special Design required [outlet DN=" + To_text(outlet_dn,0)
              + " ; US def=" + To_text(us_def,0) + " deg ; depth=" + To_text(pit_depth,2) + " m]", 3);
      } else {
        if(Absolute(pit_dn - req_mm) > 1.0){
          pit_flags = 1;
          store_pit_msg(occ_idx, "SW05 check: Manhole DIA should be " + To_text(req_mm) + "mm (found "
                + To_text(pit_dn,0) + "mm)" 
                + " [outlet DN=" + To_text(outlet_dn,0)
                + " ; US def=" + To_text(us_def,0) + " deg"
                + " ; depth=" + 
To_text(pit_depth,2) + " m]", 3);
        }
    }
    if (pipe_flags == 1){
      print_pipe_line(drain, "US ", us_idx);
    }
    
   }// end SW05
    // Print( "Pit Flag = " + To_text(pit_flags) + "\n");
    if (pit_flags == 0 && pipe_flags == 0){
      store_pit_msg(occ_idx, "CoP Check = OK", 1);
    }
    p = p + 1;
    
    if(occ_idx > 0 && PIT_has_error[occ_idx] == 1)
    {
      STRING_has_error[si] = 1;
    }
  }
}


/* ============================ PASS 2 : BUILD LOG ============================ */

void build_log(Log_Box lb_report)
{
  Integer si = 1;

  while(si <= SCOUNT)
  {
    Element drain = STR_s[si];
    Text sname="";
    Get_name(drain, sname);

    Integer string_level = (STRING_has_error[si] == 1) ? 3 : 1;

    // Create STRING group
    Log_Line string_group =
        Create_group_log_line("=== SW String: " + sname + " ===",
                              string_level);

    Add_log_line(lb_report, string_group);

    Integer p = 1;
    while(p <= STR_npits[si])
    {
      Integer occ_idx = find_occ(si, p);
      if(occ_idx == 0){
        p = p + 1;
        continue;
      }

      Text pit_name="";
      Get_drainage_pit_name(drain, p, pit_name);

      Integer pit_level = (PIT_has_error[occ_idx] == 1) ? 3 : 1;

      // Create PIT group
      Log_Line pit_group =
          Create_group_log_line("Pit = [" + pit_name + "]",
                                pit_level);

      Append_log_line(pit_group, string_group);

      {
        Real px=0.0, py=0.0, pz=0.0;
        Get_drainage_pit(drain, p, px, py, pz);   // ID 531

        Log_Line hl =
            Create_highlight_point_log_line("Pan to Pit", 1, px, py, pz);  // ID 2666

        Append_log_line(hl, pit_group);
      }

      // Append stored messages
      Integer m = 1;
      while(m <= PIT_msg_count[occ_idx])
      {
          Integer flat = (occ_idx-1)*MAX_PIT_MSG + m;

          /* MUST guard before indexing PIT_msg / PIT_msg_level */
          if(flat <= 0) break;
          if(flat > (MAX_OCC*MAX_PIT_MSG)) break;

          Text msg     = PIT_msg[flat];
          Integer level = PIT_msg_level[flat];

          Log_Line clause = Create_text_log_line(msg, level);
          Append_log_line(clause, pit_group);

          m = m + 1;
      }

      p = p + 1;
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
  Text panelName="ACCoP SW Check";
  Panel              panel      = Create_panel              (panelName, TRUE);
  Vertical_Group     vgroup     = Create_vertical_group     (-1             );
  Colour_Message_Box cmbMsg     = Create_colour_message_box (""             );
  Log_Box            lb_report  = Create_log_box            ("ACCoP Stormwater Report",90, 14);

  ///////////////////CREATE INPUT WIDGETS////////////////
  /* Scope selection (model/view/strings) */
  Source_Box scope = Create_source_box("Drainage data to be checked", cmbMsg, 0);

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

  Integer doit=1;
  while(doit)
  {
      Text cmd=""; Text msg="";
      Integer id, ret = Wait_on_widgets(id, cmd, msg);

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
          if(cmd=="process")
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
                process_string(si);

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
        default :
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
**   Macro:   ACCoP_SW_Check_v5.4dm*/