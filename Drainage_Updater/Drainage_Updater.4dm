//--------------------------------------------------------------
// Micro‑Macro 4: Drainage Updater (pipes only, no rounding fn)
// • As‑built: 2‑pt lines
// • Drainage: update pipe ILs from matched line endpoint Zs
// • Flow dir: 1 = same as string, 0 = opposite
// • After update: set pipe attributes "lock us il" and "lock ds il" to 1
//--------------------------------------------------------------
// ----------------------------- INCLUDES -----------------------------
#include "..\\..\\include\\standard_library.H"
#include "..\\..\\include\\size_of.H"

// ----------------------------- HELPERS ------------------------------

// prefer 3D read; return 0 on success
Integer get_xyz(Element e, Integer idx, Real &x, Real &y, Real &z) {
  if(Get_3d_data(e, idx, x, y, z) == 0) return 0;
  if(Get_super_vertex_coord(e, idx, x, y, z) == 0) return 0;
  if(Get_2d_data(e, idx, x, y) == 0) { z = 0.0; return 0; }
  return 1;
}

// Return 1 if drainage string; also fetch nsegs & pits
Integer classify_drainage(Element e, Integer &dir, Integer &nsegs, Integer &npits) {
  Integer rc1 = Get_drainage_flow(e, dir);            // 1=same, 0=opp
  Integer rc2 = Get_segments(e, nsegs);
  Integer rc3 = Get_drainage_pits(e, npits);
  if(rc1 != 0 || rc2 != 0 || rc3 != 0 || nsegs <= 0 || npits < 2) return 0;
  if(dir != 1) dir = 0;
  return 1;
}

// Get pit centre XYZ; safe with bounds check
Integer safe_get_pit(Element e, Integer idx, Integer npits, Real &x, Real &y, Real &z) {
  if(idx < 1 || idx > npits) return 1;
  return Get_drainage_pit(e, idx, x, y, z);
}

// Get line endpoints (2‑pt lines only). Return 0 on success.
Integer get_line_endpoints(Element e, Real &x1,Real &y1,Real &z1, Real &x2,Real &y2,Real &z2) {
  Integer npts=0; Get_points(e,npts);
  if(npts != 2) return 1;
  if(get_xyz(e,1,x1,y1,z1)==0 && get_xyz(e,2,x2,y2,z2)==0) return 0;
  return 1;
}

Real dist_xy(Real ax, Real ay, Real bx, Real by) {
  Real dx = ax - bx, dy = ay - by;
  return Sqrt(dx*dx + dy*dy);
}

// Find a single 2‑pt line whose endpoints are both within tol of US/DS (either orientation).
// Returns 1 if found with best score; sets orient (0: A->US,B->DS, 1: A->DS,B->US).
Integer find_match_line(Dynamic_Element ab_elts, Integer ab_count,
                        Real usx,Real usy, Real dsx,Real dsy, Real tol,
                        Element &best_e, Text &best_name, Real &best_dus, Real &best_dds, Integer &best_orient) {
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
      if(score < best_score) { best_score=score; found=1; best_orient=0; best_dus=dUS0; best_dds=dDS0; best_e=a; }
    }
    if(dUS1 <= tol && dDS1 <= tol) {
      Real score = dUS1 + dDS1;
      if(score < best_score) { best_score=score; found=1; best_orient=1; best_dus=dUS1; best_dds=dDS1; best_e=a; }
    }
  }
  if(found) {
    Get_name(best_e,best_name); if(Text_length(best_name)==0) best_name="<no name>";
    return 1;
  }
  return 0;
}

// Map US/DS to left/right (string order) for Set_drainage_pipe_inverts
inline void map_usds_to_lr(Integer dir, Real il_us, Real il_ds, Real &lhs, Real &rhs) {
  if(dir == 1) { lhs = il_us; rhs = il_ds; } else { lhs = il_ds; rhs = il_us; }
}

// ------------------------------- MAIN -------------------------------
void main() {
  // UI
  Panel          panel  = Create_panel("Drainage Updater (pipes only)");
  Vertical_Group vgroup = Create_vertical_group(0);
  Message_Box    mbox   = Create_message_box("Status");
  Source_Box     srcbox = Create_source_box("As-built (2-pt lines)", mbox, 0);
  Model_Box      modbox = Create_model_box("Drainage model", mbox, 0);
  Real_Box       tolbox = Create_real_box("XY tolerance (m)", mbox);
  Button         runbtn = Create_run_button("Update", "run_reply");
  Button         finbtn = Create_finish_button("Close", "finish_reply");

  Set_data(tolbox, 1.0);

  Append(srcbox, vgroup);
  Append(modbox, vgroup);
  Append(tolbox, vgroup);
  Append(mbox,   vgroup);
  Horizontal_Group hgrp = Create_button_group();
  Append(runbtn, hgrp);
  Append(finbtn, hgrp);
  Append(hgrp,  vgroup);
  Append(vgroup, panel);
  Show_widget(panel);
  Clear_console();

  Integer loop = 1;
  while(loop) {
    Integer id; Text cmd, msg;
    Integer ret = Wait_on_widgets(id, cmd, msg);
    if(cmd == "CodeShutdown") { Set_exit_code("CodeShutdown"); return; }
    if(cmd == "keystroke") continue;

    if(id == Get_id(panel) && cmd == "Panel Quit") { loop = 0; continue; }
    if(id == Get_id(finbtn) && cmd == "finish_reply") { loop = 0; continue; }

    if(id == Get_id(runbtn) && cmd == "run_reply") {
      // Validate inputs
      Dynamic_Element ab_elts; Integer v1 = Validate(srcbox, ab_elts);
      if(v1 == 0) { Set_error_message(srcbox,"Pick a valid as‑built dataset."); Set_data(mbox,"Invalid as‑built selection."); continue; }
      Integer ab_count=0; Get_number_of_items(ab_elts,ab_count);
      if(ab_count <= 0) { Set_data(mbox,"As‑built dataset is empty."); Print("No as‑built elements.\n"); continue; }

      Model dmodel; Integer v2 = Validate(modbox, 0, dmodel);
      if(v2 == 0) { Set_error_message(modbox,"Pick a valid drainage model."); Set_data(mbox,"Invalid drainage model."); continue; }

      Real tol=1.0; Integer vt = Validate(tolbox, tol);
      if(vt == 0 || tol <= 0.0) { tol = 1.0; Set_data(mbox,"Invalid tol → using 1.0 m"); }

      // Iterate drainage strings
      Dynamic_Element d_elts; Integer d_count=0;
      Integer gerc = Get_elements(dmodel, d_elts, d_count);
      if(gerc != 0 || d_count <= 0) { Set_data(mbox,"Drainage model is empty."); Print("No drainage elements.\n"); continue; }

      Integer updated=0, matched=0, nomatch=0, seg_total=0, drain_total=0;

      Print("— Drainage Updater (pipes only) — tol="+To_text(tol,3)+" m\n");

      for(Integer i=1;i<=d_count;i++) {
        Element e; Get_item(d_elts,i,e);
        Integer dir, nsegs, npits;
        if(!classify_drainage(e, dir, nsegs, npits)) continue;
        drain_total++;

        Text sname; Get_name(e,sname); if(Text_length(sname)==0) sname="<no name>";
        Print("DRAIN | "+sname+" | segs="+To_text(nsegs)+" | dir="+To_text(dir)+"\n");

        for(Integer s=1; s<=nsegs; s++) {
          seg_total++;

          Integer us_idx = (dir==1) ? s   : s+1;
          Integer ds_idx = (dir==1) ? s+1 : s;

          Real usx,usy,usz, dsx,dsy,dsz;
          Integer rc1 = safe_get_pit(e, us_idx, npits, usx, usy, usz);
          Integer rc2 = safe_get_pit(e, ds_idx, npits, dsx, dsy, dsz);
          if(rc1!=0 || rc2!=0) { Print("  seg "+To_text(s)+": <pit read error>\n"); continue; }

          Element best_e; Text best_name; Real dus, dds; Integer orient;
          Integer ok = find_match_line(ab_elts, ab_count, usx,usy, dsx,dsy, tol, best_e, best_name, dus, dds, orient);
          if(!ok) { nomatch++; Print("  seg "+To_text(s)+": NO MATCH within tol\n"); continue; }

          matched++;

          // As‑built line Zs -> US/DS by orientation
          Real ax,ay,az,bx,by,bz; get_line_endpoints(best_e,ax,ay,az,bx,by,bz);
          Real new_us_il = (orient==0) ? az : bz;
          Real new_ds_il = (orient==0) ? bz : az;

          // Map to L/R for setter
          Real lhs, rhs; map_usds_to_lr(dir, new_us_il, new_ds_il, lhs, rhs);

          // Update & lock
          Real old_us=0, old_ds=0; Get_drainage_pipe_inverts(e, s, old_us, old_ds);
          Integer src = Set_drainage_pipe_inverts(e, s, lhs, rhs);
          Set_drainage_pipe_attribute(e, s, "lock us il", 1);
          Set_drainage_pipe_attribute(e, s, "lock ds il", 1);

          updated++;
          Print("  seg "+To_text(s)+": UPDATE line=\""+best_name+"\" | dUS="+To_text(dus,3)+", dDS="+To_text(dds,3)+
                " | old("+To_text(old_us,3)+","+To_text(old_ds,3)+") -> new("+To_text(new_us_il,3)+","+To_text(new_ds_il,3)+")\n");
        }
      }

      Text summary = "strings="+To_text(drain_total)+", segs="+To_text(seg_total)+", matched="+To_text(matched)+", updated="+To_text(updated)+", no‑match="+To_text(nomatch);
      Print(summary+"\n");
      Set_data(mbox, summary);
    }
  }

  Set_finish_button(panel,1);
}
