/*---------------------------------------------------------------------
**   Programmer:Kleber Lessa do Prado
**   Company: The Neil group
**   Date:01/09/25
**   12D Model:            V15
**   Version:              001
**   Macro Name:           Drainage_UpdaterV2.4dm
**   Type:                 SOURCE
**
**   Brief description: Updates drainage model (Cover RL, Sump RL and Pipe Inverts) using points and 2-point data set.
**						Refer to READ ME.txt for mode comprehensive description.
**
**---------------------------------------------------------------------
**   Update/Modification
**
**  Minor changes, replaced Get_3d_data() functions with Get_super_vertex_coord().
**---------------------------------------------------------------------*/
#define DEBUG_FILE      0
#define ECHO_DEBUG_FILE 0
#define ECHO_LINE_NO    0
#define BUILD "version.0.002"

// ----------------------------- INCLUDES -----------------------------
#include "..\\..\\include/standard_library.H"
#include "..\\..\\include/size_of.H"
#include "..\\..\\include/set_ups.h"

//MACRO UPDATES LID LEVEL. not sump or pipes
/*global variables*/{
}

// ============================= HELPERS ==============================

// LID matching: points only (npts == 1). Returns 1 if found within tol; best_z out
Integer nearest_lid_point(Dynamic_Element ab_elts, Integer ab_count,
                          Real px, Real py, Real tol, Real &best_z)
{
  Real best_d2 = 1.0e30; Integer found = 0;
  Integer i;
  for(i=1; i<=ab_count; i++){
    Element e; Get_item(ab_elts, i, e);
    Integer npts=0; Get_points(e, npts);
    if(npts != 1) continue;
    Real x,y,z;if(Get_super_vertex_coord(e, 1, x, y, z) != 0) continue;
    Real dx = x - px, dy = y - py; Real d2 = dx*dx + dy*dy;
    if(d2 < best_d2){ best_d2 = d2; best_z = z; found = 1; }
  }
  return (found && best_d2 <= tol*tol) ? 1 : 0;
}

// Generic nearest vertex (3D only)
Integer nearest_vertex_xy(Dynamic_Element ab_elts, Integer ab_count,
                          Real px, Real py, Real tol, Real &best_z)
{
  Real best_d2 = 1.0e30; Integer found = 0;
  Integer i, vi;
  for(i=1;i<=ab_count;i++){
    Element e; Get_item(ab_elts,i,e);
    Integer npts=0; Get_points(e,npts);
    if(npts < 1) continue;
    for(vi=1; vi<=npts; vi++){
      Real x,y,z; if(Get_super_vertex_coord(e,vi,x,y,z)!=0) continue;
      Real dx=x-px, dy=y-py; Real d2=dx*dx+dy*dy;
      if(d2<best_d2){ best_d2=d2; best_z=z; found=1; }
    }
  }
  return (found && best_d2<=tol*tol) ? 1 : 0;
}

Integer classify_drainage(Element e, Integer &dir, Integer &nsegs, Integer &npits)
{
  Integer rc1 = Get_drainage_flow(e, dir);
  Integer rc2 = Get_segments(e, nsegs);
  Integer rc3 = Get_drainage_pits(e, npits);
  if(rc1!=0 || rc2!=0 || rc3!=0 || nsegs<=0 || npits<2) return 0;
  if(dir!=1) dir=0; // 1=same, 0=opposite
  return 1;
}

Integer safe_get_pit(Element e, Integer idx, Integer npits, Real &x, Real &y, Real &z)
{
  if(idx<1 || idx>npits) return 1;
  return Get_drainage_pit(e, idx, x, y, z);
}

Integer get_line_endpoints(Element e, Real &x1,Real &y1,Real &z1,
                                 Real &x2,Real &y2,Real &z2)
{
  Integer npts=0; Get_points(e,npts);
  if(npts!=2) return 1;
  if(Get_super_vertex_coord(e,1,x1,y1,z1)!=0) return 1;
  if(Get_super_vertex_coord(e,2,x2,y2,z2)!=0) return 1;
  return 0;
}

Real dist_xy(Real ax, Real ay, Real bx, Real by)
{
  Real dx=ax-bx, dy=ay-by; return Sqrt(dx*dx+dy*dy);
}

// Find matching 2-pt line for US/DS; flow_dir=0 (a→US,b→DS) or 1 (reversed)
// Extended version from pipe updater that returns distances
Integer find_match_line(Dynamic_Element ab_elts, Integer ab_count,
                        Real usx,Real usy, Real dsx,Real dsy, Real tol,
                        Element &best_e, Text &best_name, Integer &best_flow_dir)
{
  Real best_score = 1.0e30; Integer found = 0;

  for(Integer i=1;i<=ab_count;i++) {
    Element a; Get_item(ab_elts,i,a);
    Integer npts=0; Get_points(a,npts);
    if(npts != 2) continue;

    Real ax,ay,az,bx,by,bz;
    if(get_line_endpoints(a,ax,ay,az,bx,by,bz) != 0) continue;

    Real dUS0 = dist_xy(usx,usy,ax,ay);
    Real dDS0 = dist_xy(dsx,dsy,bx,by);
    Real dUS1 = dist_xy(usx,usy,bx,by);
    Real dDS1 = dist_xy(dsx,dsy,ax,ay);

    if(dUS0 <= tol && dDS0 <= tol) {
      Real score = dUS0 + dDS0;
      if(score < best_score) { best_score=score; found=1; best_flow_dir=0; best_e=a; }
    }
    if(dUS1 <= tol && dDS1 <= tol) {
      Real score = dUS1 + dDS1;
      if(score < best_score) { best_score=score; found=1; best_flow_dir=1; best_e=a; }
    }
  }

  if(found) {
    Get_name(best_e,best_name); if(Text_length(best_name)==0) best_name="<no name>";
    return 1;
  }
  return 0;
}

void map_usds_to_lr(Integer dir, Real il_us, Real il_ds, Real &lhs, Real &rhs)
{
  if(dir==1){ lhs=il_us; rhs=il_ds; } else { lhs=il_ds; rhs=il_us; }
}

// validate optional Model_Box and announce selection
Integer Validate_optional_model(Model_Box box, Model &mdl, Text label, Text &model_name)
{
  Text typed = "";
  Get_data(box, typed);                       // text in widget

  Integer rc = Validate(box, GET_MODEL, mdl); // Validate(Model_Box,Integer,Model&)

  if (rc == MODEL_EXISTS || rc == NEW_MODEL || rc == DISK_MODEL_EXISTS) {
    if (Numchr(typed) > 0) model_name = typed;
    else Get_name(mdl, model_name);
    Print("Model \"" + model_name + "\" will be processed\n");
    return rc;
  }

  if (rc == NO_NAME) {                        // optional + blank
    model_name = "";
    return rc;
  }

  Print("Error validating " + label + " (code " + To_text(rc) + ")\n");
  model_name = "";
  return rc;
}

// Count elements in a model with ID=132 Get_elements()
// Returns 0 on success; non-zero on failure. 'count' is set by the API.
Integer Count_model_elements(Model mdl, Integer &count)
{
  Dynamic_Element model_elts;
  count = 0;
  return Get_elements(mdl, model_elts, count); // 0 == success
}


// ============================= UI / MAIN ============================

void mainPanel()
{
  Text panelName="Drainage_Updater_NEW";
  Panel              panel  = Create_panel              (panelName,TRUE);
  Vertical_Group     vgroup = Create_vertical_group     (-1);
  Colour_Message_Box cmbMsg = Create_colour_message_box ("");

  // inputs
  Model_Box mb_Lid   = Create_model_box("As-built MH lid level (POINTS)",  cmbMsg, CHECK_MODEL_MUST_EXIST);
  Set_optional(mb_Lid,TRUE);
  Model_Box mb_Sump  = Create_model_box("As-built Sump level (POINTS)",    cmbMsg, CHECK_MODEL_MUST_EXIST);
  Set_optional(mb_Sump,TRUE);
  Model_Box mb_Pipe  = Create_model_box("As-built pipe IL (2-pt lines)",   cmbMsg, CHECK_MODEL_MUST_EXIST);
  Set_optional(mb_Pipe,TRUE);
  Model_Box mb_drain = Create_model_box("Drainage model to be updated",    cmbMsg, CHECK_MODEL_MUST_EXIST);
  Set_optional(mb_drain,FALSE);

  Real_Box  tol_box  = Create_real_box ("XY tolerance (m)", cmbMsg);
  Set_data(tol_box, 1.0);

  // buttons
  Horizontal_Group bgroup = Create_button_group();
  Button process     = Create_button       ("&Process","process");
  Button finish      = Create_finish_button("Finish"  ,"Finish");
  Button help_button = Create_help_button  (panel     ,"Help");
  Append(process    ,bgroup);
  Append(finish     ,bgroup);
  Append(help_button,bgroup);

  // layout
  Append(mb_Lid  ,vgroup);
  Append(mb_Sump ,vgroup);
  Append(mb_Pipe ,vgroup);
  Append(mb_drain,vgroup);
  Append(tol_box ,vgroup);
  Append(cmbMsg  ,vgroup);
  Append(bgroup  ,vgroup);
  Append(vgroup  ,panel);
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
          // no Clear_output_window() in 12dPL; print a separator
          Print("\n---------------- Process ----------------\n");

          Set_data(cmbMsg ,"Processing...");

          // Get tolerance value
          Real tol;
          if(Validate(tol_box, tol) == 0 || tol <= 0.0) { 
            tol = 1.0; 
            Print("Invalid tolerance → using 1.0 m\n"); 
          }

          // validate optional sources
          Model mL, mS, mP;
          Text  nL="", nS="", nP="";
          Integer rL = Validate_optional_model(mb_Lid,  mL, "Model Lid Level",   nL);
          Integer rS = Validate_optional_model(mb_Sump, mS, "Model Sump Level",  nS);
          Integer rP = Validate_optional_model(mb_Pipe, mP, "Model Pipes IL",    nP);

          if (rL == NO_NAME && rS == NO_NAME && rP == NO_NAME) {
            Print("At least one input model is required\n");
            Set_data(cmbMsg ,"Process aborted");
            break;
          }

          // element counts for provided models
          Integer n;
          if (rL==2) {
            if (Count_model_elements(mL, n) == 0)
              Print("Model \"" + nL + "\" has " + To_text(n) + " elements\n");
            else
              Print("Error: could not get elements for \"" + nL + "\"\n");
          }
          if (rS==2) {
            if (Count_model_elements(mS, n) == 0)
              Print("Model \"" + nS + "\" has " + To_text(n) + " elements\n");
            else
              Print("Error: could not get elements for \"" + nS + "\"\n");
          }
          if (rP==2) {
            if (Count_model_elements(mP, n) == 0)
              Print("Model \"" + nP + "\" has " + To_text(n) + " elements\n");
            else
              Print("Error: could not get elements for \"" + nP + "\"\n");
          }
          // validate required drainage model
          Model dmodel; Text dname="";
          Integer rd = Validate_optional_model(mb_drain, dmodel, "Drainage Model", dname);
          if (rd != MODEL_EXISTS && rd != DISK_MODEL_EXISTS) {
            Print("Error validating Drainage Model\n");
            Set_data(cmbMsg ,"Process aborted");
            break;
          }
          Print("Model \"" + dname + "\" will be processed\n");
          if (Count_model_elements(dmodel, n) != 0) {
            Print("Error: could not get elements for \"" + dname + "\"\n");
            Set_data(cmbMsg ,"Process aborted");
            break;
          } else {
            Print("Model \"" + dname + "\" has " + To_text(n) + " elements\n");
          }
         // --- validate required drainage model and enumerate elements
Model mD; Text nD="";
Integer rD = Validate(mb_drain, GET_MODEL, mD);
if (rD != MODEL_EXISTS && rD != DISK_MODEL_EXISTS) {
  Print("Error: drainage model is required and must exist\n");
  Set_data(cmbMsg,"Process aborted");
  break;
}
Get_name(mD, nD);
Print("Drainage model \"" + nD + "\" will be processed\n");

Dynamic_Element d_elts;
Integer d_count = 0;
if (Get_elements(mD, d_elts, d_count) != 0 || d_count <= 0) {
  Print("Drainage model has no elements\n");
  Set_data(cmbMsg,"Process aborted");
  break;
}

// --- update pit LIDs from LID points (if LID model supplied)
Integer lids_upd = 0, lids_no = 0;
Integer sumps_upd = 0, sumps_no = 0;  // Add sump counters
Integer pipes_upd = 0, pipes_no = 0;  // Add pipe counters
Integer i, p;

// prepare LID model elements
Dynamic_Element lid_elts;
Integer nLid = 0;

if (rL == 2) {
  if (Get_elements(mL, lid_elts, nLid) != 0 || nLid <= 0) {
    Print("Warning: could not get elements for LID model \"" + nL + "\"; LID updates disabled\n");
    rL = NO_NAME; // treat as not provided
  } else {
    Print("LID model \"" + nL + "\" has " + To_text(nLid) + " elements\n");
  }
}

// prepare Sump model elements
Dynamic_Element sump_elts;
Integer sump_cnt = 0;
Integer sump_ok = 0;

if (rS == 2) {
  if (Get_elements(mS, sump_elts, sump_cnt) != 0 || sump_cnt <= 0) {
    Print("Warning: could not get elements for Sump model \"" + nS + "\"; Sump updates disabled\n");
    sump_ok = 0;
  } else {
    Print("Sump model \"" + nS + "\" has " + To_text(sump_cnt) + " elements\n");
    sump_ok = 1;
  }
}

// prepare Pipe model elements
Dynamic_Element pipe_elts;
Integer pipe_cnt = 0;
Integer pipe_ok = 0;

if (rP == 2) {
  if (Get_elements(mP, pipe_elts, pipe_cnt) != 0 || pipe_cnt <= 0) {
    Print("Warning: could not get elements for Pipe model \"" + nP + "\"; Pipe updates disabled\n");
    pipe_ok = 0;
  } else {
    Print("Pipe model \"" + nP + "\" has " + To_text(pipe_cnt) + " elements\n");
    pipe_ok = 1;
  }
}

for (i = 1; i <= d_count; i++) {
  Element s; Get_item(d_elts, i, s);

  Integer dflow = 0;                   // ensure drainage string
  if (Get_drainage_flow(s, dflow) != 0) continue;

  Integer npits = 0;
  if (Get_drainage_pits(s, npits) != 0 || npits <= 0) continue;

  Text nm; Get_name(s, nm); if (Numchr(nm) == 0) nm = "<no name>";
  Print("STRING | " + nm + " | pits=" + To_text(npits) + "\n");

  for (p = 1; p <= npits; p++) {
    Real px, py, pz;
    if (Get_drainage_pit(s, p, px, py, pz) != 0) {
      Print("  pit " + To_text(p) + ": <read error>\n");
      continue;
    }

    // LID update only if a LID model was provided and loaded successfully
    if (rL == 2) {
      Real lid_z = 0.0;
      if (nearest_lid_point(lid_elts, nLid, px, py, tol, lid_z) != 0) {
        Attributes natt;
        if (Get_drainage_pit_attributes(s, p, natt) == 0) {
          Set_attribute(natt, "cover rl mode", 2);     // cover RL = explicit
          Set_drainage_pit_attributes(s, p, natt);     // commit attributes
        }
        if (Set_drainage_pit(s, p, px, py, lid_z) == 0) {
          lids_upd++;
          Print("  pit " + To_text(p) + ": LID "
                + To_text(pz, 3) + " -> " + To_text(lid_z, 3) + "\n");
        } else {
          lids_no++;
          Print("  pit " + To_text(p) + ": LID set failed\n");
        }
      } else {
        lids_no++;
        Print("  pit " + To_text(p) + ": LID no match\n");
      }
    }

    // SUMP update only if a Sump model was provided and loaded successfully
    if(sump_ok){
      Real sump_z=0.0, sump_old=0.0; 
      Integer have_old=(Get_drainage_pit_sump_level(s,p,sump_old)==0);
      if(nearest_vertex_xy(sump_elts, sump_cnt, px,py, tol, sump_z)!=0){
        if(Set_drainage_pit_float_sump(s,p,0)==0 && Set_drainage_pit_sump_level(s,p,sump_z)==0){
          sumps_upd++;
          if(have_old) Print("  pit "+To_text(p)+": SUMP "+To_text(sump_old,3)+" -> "+To_text(sump_z,3)+"\n");
          else         Print("  pit "+To_text(p)+": SUMP ? -> "+To_text(sump_z,3)+"\n");
        } else { 
          sumps_no++; 
          Print("  pit "+To_text(p)+": SUMP set failed\n"); 
        }
      } else { 
        sumps_no++; 
        Print("  pit "+To_text(p)+": SUMP no match\n"); 
      }
    }
  }
}

// ============================= PIPE UPDATE BLOCK ==============================
// Added from Drainage_Pipe_Updater.4dm

// Process pipe segments if pipe model is available
if (pipe_ok) {
  Print("\n--- PIPE UPDATES ---\n");
  
  for (i = 1; i <= d_count; i++) {
    Element e; Get_item(d_elts, i, e);
    Integer dir, nsegs, npits;
    if(!classify_drainage(e, dir, nsegs, npits)) continue;

    Text sname; Get_name(e,sname); if(Text_length(sname)==0) sname="<no name>";
    Print("DRAIN | "+sname+" | segs="+To_text(nsegs)+" | dir="+To_text(dir)+"\n");

    for(Integer s=1; s<=nsegs; s++) {
      Integer us_idx = (dir==1) ? s   : s+1;
      Integer ds_idx = (dir==1) ? s+1 : s;

      Real usx,usy,usz, dsx,dsy,dsz;
      Integer rc1 = safe_get_pit(e, us_idx, npits, usx, usy, usz);
      Integer rc2 = safe_get_pit(e, ds_idx, npits, dsx, dsy, dsz);
      if(rc1!=0 || rc2!=0) { Print("  seg "+To_text(s)+": <pit read error>\n"); continue; }

      Element best_e; Text best_name; Integer flow_dir;
      Integer ok = find_match_line(pipe_elts, pipe_cnt, usx,usy, dsx,dsy, tol,
                                   best_e, best_name, flow_dir);
      if(!ok) { 
        pipes_no++; 
        Print("  seg "+To_text(s)+": NO MATCH within tol\n"); 
        continue; 
      }

      Real ax,ay,az,bx,by,bz; get_line_endpoints(best_e,ax,ay,az,bx,by,bz);
      Real new_us_il = (flow_dir==0) ? az : bz;
      Real new_ds_il = (flow_dir==0) ? bz : az;

      Real lhs, rhs; map_usds_to_lr(dir, new_us_il, new_ds_il, lhs, rhs);

      Real old_us=0, old_ds=0; Get_drainage_pipe_inverts(e, s, old_us, old_ds);
      Integer setrc = Set_drainage_pipe_inverts(e, s, lhs, rhs);
      Set_drainage_pipe_attribute(e, s, "lock us il", 1);
      Set_drainage_pipe_attribute(e, s, "lock ds il", 1);

      pipes_upd++;
      Print("  seg "+To_text(s)+": UPDATE line=\""+best_name+"\" | flow_dir="+To_text(flow_dir)+
            " | old("+To_text(old_us,3)+","+To_text(old_ds,3)+") -> new("+To_text(new_us_il,3)+","+To_text(new_ds_il,3)+")\n");
    }
  }
}

Print("PITS SUMMARY: lids_upd="+To_text(lids_upd)+", lids_no="+To_text(lids_no)+
      ", sump_upd="+To_text(sumps_upd)+", sump_no="+To_text(sumps_no)+"\n");

Print("PIPES SUMMARY: pipes_upd="+To_text(pipes_upd)+", pipes_no="+To_text(pipes_no)+"\n");

          Set_data(cmbMsg ,"Process finished");
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

void main()
{
  mainPanel();
}