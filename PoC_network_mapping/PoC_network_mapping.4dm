/*---------------------------------------------------------------------
**   Macro:   PoC_network_mapping.4dm
**   Purpose: Map cross-string junctions in a selected model.
**            Report only connections between different strings.
**            Junction key = pit name.
---------------------------------------------------------------------*/
#define BUILD "PoC-Map-002"

#include "..\\..\\include\standard_library.H"
#include "..\\..\\include\size_of.H"

#define MAX_STRINGS  4000
#define MAX_OCC      60000

/*global variables*/{
/* per-string */
Element STR_s[MAX_STRINGS+1];
Integer STR_is_trunk[MAX_STRINGS+1];
Integer STR_dir[MAX_STRINGS+1];
Integer STR_npits[MAX_STRINGS+1];
Integer SCOUNT = 0;

/* pit occurrences (one row per pit on a string) */
Text    OCC_pit_name[MAX_OCC+1];
Integer OCC_str_idx[MAX_OCC+1];
Integer OCC_pit_idx[MAX_OCC+1];
Integer OCC_us_pipe_idx[MAX_OCC+1];
Integer OCC_ds_pipe_idx[MAX_OCC+1];
Integer OCC_COUNT = 0;
}

/* ------------------------------ helpers ----------------------------- */
Integer is_drainage(Element e){
  Integer n=0; if(Get_drainage_pits(e,n)!=0) return 0; return (n>0);
}

/* safe pipe-index check: 1..(npits-1) */
Integer valid_pipe_index(Integer str_idx, Integer k){
  if(k <= 0) return 0;
  Integer np = STR_npits[str_idx];
  if(np <= 1) return 0;
  if(k >= 1 && k <= (np - 1)) return 1;
  return 0;
}

/* add a pit occurrence to the OCC_ arrays */
void add_pit_occurrence(Text pit_name, Integer str_idx, Integer pit_idx, Integer us_idx, Integer ds_idx){
  if(OCC_COUNT >= MAX_OCC) return;
  OCC_COUNT += 1;
  OCC_pit_name[OCC_COUNT]    = pit_name;
  OCC_str_idx[OCC_COUNT]     = str_idx;
  OCC_pit_idx[OCC_COUNT]     = pit_idx;
  OCC_us_pipe_idx[OCC_COUNT] = us_idx;
  OCC_ds_pipe_idx[OCC_COUNT] = ds_idx;
}

/* find occurrence index by string and pit indices */
Integer find_occ(Integer str_idx, Integer pit_idx){
  for(Integer i=1; i<=OCC_COUNT; i++){
    if(OCC_str_idx[i]==str_idx && OCC_pit_idx[i]==pit_idx) return i;
  }
  return 0;
}

/* harvest all drainage strings and their pit US/DS indices from a model */
void harvest_from_model(Model mdl){
  SCOUNT = 0; OCC_COUNT = 0;

  Dynamic_Element de;
  Integer no_elts = 0;
  Get_elements(mdl, de, no_elts);   /* returns count in no_elts */

  for(Integer i=1; i<=no_elts; i++){
    Element elt; Get_item(de, i, elt); /* ID=128 */

    Integer npits=0;
    if(Get_drainage_pits(elt, npits)!=0 || npits<=0) continue; /* keep only drainage strings */

    Integer dir=1; Get_drainage_flow(elt, dir);
    Element trunk_el;
    Integer rc_tr = Get_drainage_trunk(elt, trunk_el);   // ID=1444
    // trunk flag per manual: 0=branch, 44=trunk with outlet, other!=0 undefined
    Integer is_trunk_flag = (rc_tr == 0) ? 0 : 1;        // treat 44 as trunk
    
    if(SCOUNT >= MAX_STRINGS) break;
    SCOUNT += 1;
    STR_s[SCOUNT]        = elt;
    STR_is_trunk[SCOUNT] = is_trunk_flag;
    STR_dir[SCOUNT]      = dir;
    STR_npits[SCOUNT]    = npits;

    /* per-pit US/DS pipe indices w.r.t. flow */
    for(Integer p=1; p<=npits; p++){
      Integer prev_idx = (p>1)     ? (p-1) : 0;  /* pipe just upstream if dir==1 */
      Integer next_idx = (p<npits) ?  p   : 0;  /* pipe just downstream if dir==1 */
      Integer us_idx   = (dir==1) ? prev_idx : next_idx;
      Integer ds_idx   = (dir==1) ? next_idx : prev_idx;

      Text pit_name=""; Get_drainage_pit_name(elt, p, pit_name);
      add_pit_occurrence(pit_name, SCOUNT, p, us_idx, ds_idx);
    }
  }
}

/* print only cross-string connections:
   for each branch, take its DS-most pit and match same pit on other strings */
void report_cross_string_junctions(){
  Integer found=0;
  Print("Cross-string junctions (branch X trunk / branch X branch):\n");

  for(Integer si=1; si<=SCOUNT; si++){
    if(STR_is_trunk[si]==1) continue; /* only branches as sources */

    Integer np = STR_npits[si]; if(np<=0) continue;
    Integer p_ds = (STR_dir[si]==1) ? np : 1;

    Integer occ_i = find_occ(si, p_ds);
    if(occ_i==0) continue;

    Text jname = OCC_pit_name[occ_i];

    Integer branch_up_k = OCC_us_pipe_idx[occ_i];
    Text branch_up_name = "[none]";
    if(valid_pipe_index(si, branch_up_k)){
    Get_drainage_pipe_name(STR_s[si], branch_up_k, branch_up_name);
    }

    /* scan other strings that share this pit name */
    for(Integer j=1; j<=OCC_COUNT; j++){
      if(OCC_pit_name[j] != jname) continue;
      if(OCC_str_idx[j] == si)     continue; /* same string → skip */

        Integer other_ds_k = OCC_ds_pipe_idx[j];
        Integer other_si   = OCC_str_idx[j];

        // require a valid downstream pipe on the other string; otherwise skip
        if(other_ds_k <= 0 || other_ds_k > (STR_npits[other_si]-1)) continue;

        Text other_ds_name = "";
        Get_drainage_pipe_name(STR_s[other_si], other_ds_k, other_ds_name);

        Text line = "Junction " + jname + ": US=" + branch_up_name + "  DS=" + other_ds_name + "\n";
        Print(line);


      found += 1;
    }
  }

  if(found==0) Print("None found.\n");
}

/* ------------------------------ panel ------------------------------- */
void main(){
  Panel           panel = Create_panel("PoC Network Mapping", TRUE);
  Vertical_Group  vgrp  = Create_vertical_group(-1);
  Colour_Message_Box cmb = Create_colour_message_box("");

  Model_Box mbox = Create_model_box("Model:",cmb,CHECK_MODEL_MUST_EXIST);

  Horizontal_Group bgrp = Create_button_group();
  Button process = Create_button("&Process","process");
  Button finish  = Create_finish_button("Finish","Finish");

  Append(mbox, vgrp);
  Append(cmb,  vgrp);
  Append(process, bgrp);
  Append(finish,  bgrp);
  Append(bgrp, vgrp);
  Append(vgrp, panel);
  Show_widget(panel);

  Integer run=1;
  while(run){
    Integer id; Text cmd="", msg="";
    Wait_on_widgets(id, cmd, msg);

    if(cmd=="process"){
      Model mdl;
      Integer rc = Validate(mbox,7, mdl);
      if(rc==NO_NAME){ Set_data(cmb, "Select a model.", 2); continue; }
      if(rc==FALSE){  Set_data(cmb, "Invalid model.", 2);  continue; }

      harvest_from_model(mdl);
      if(SCOUNT==0){ Set_data(cmb, "No drainage strings in model.", 2); continue; }

      report_cross_string_junctions();
      Set_data(cmb, "Done. See Output.", 1);
    }
    else if(cmd=="Finish"){
      run=0;
    }
  }
}
