// ----------------------------- INCLUDES -----------------------------
#include "..\\..\\include\\standard_library.H"
#include "..\\..\\include\\size_of.H"

// ----------------------------- HELPERS ------------------------------

// Prefer 3D read; return 0 on success
Integer get_xyz(Element e, Integer idx, Real &x, Real &y, Real &z)
{
  if(Get_3d_data(e, idx, x, y, z) == 0) return 0;
  if(Get_super_vertex_coord(e, idx, x, y, z) == 0) return 0;
  if(Get_2d_data(e, idx, x, y) == 0) { z = 0.0; return 0; }
  return 1;
}

// Drainage check + counts (return 1 if drainage string)
Integer classify_drainage(Element e, Integer &dir, Integer &nsegs, Integer &npits)
{
  Integer rc1 = Get_drainage_flow(e, dir);     // 1 = same, 0 = opposite
  Integer rc2 = Get_segments(e, nsegs);
  Integer rc3 = Get_drainage_pits(e, npits);
  if(rc1 != 0 || rc2 != 0 || rc3 != 0) return 0;
  if(nsegs <= 0 || npits < 2) return 0;
  if(dir != 1) dir = 0;                        // normalise
  return 1;
}

// Safe pit centre read (bounds checked); 0 = ok
Integer safe_get_pit(Element e, Integer idx, Integer npits, Real &x, Real &y, Real &z)
{
  if(idx < 1 || idx > npits) return 1;
  return Get_drainage_pit(e, idx, x, y, z);
}

// Get endpoints of a 2-pt line; 0 = ok
Integer get_line_endpoints(Element e,
                           Real &x1,Real &y1,Real &z1,
                           Real &x2,Real &y2,Real &z2)
{
  Integer npts=0; Get_points(e,npts);
  if(npts != 2) return 1;
  if(get_xyz(e,1,x1,y1,z1)==0 && get_xyz(e,2,x2,y2,z2)==0) return 0;
  return 1;
}

Real dist_xy(Real ax, Real ay, Real bx, Real by)
{
  Real dx = ax - bx, dy = ay - by;
  return Sqrt(dx*dx + dy*dy);
}

// Find the best 2-pt line whose endpoints fall within tol of US/DS (either orientation).
// Returns 1 if found. orient = 0 => A->US,B->DS ; orient = 1 => A->DS,B->US.
Integer find_match_line(Dynamic_Element ab_elts, Integer ab_count,
                        Real usx,Real usy, Real dsx,Real dsy, Real tol,
                        Element &best_e, Text &best_name,
                        Real &best_dus, Real &best_dds, Integer &best_orient)
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

// Map US/DS to LHS/RHS for Set_drainage_pipe_inverts
void map_usds_to_lr(Integer dir, Real il_us, Real il_ds, Real &lhs, Real &rhs)
{
  if(dir == 1) { lhs = il_us; rhs = il_ds; }
  else         { lhs = il_ds; rhs = il_us; }
}

// ------------------------------- MAIN -------------------------------
void main()
{
  // Panel
  Panel          panel  = Create_panel("Drainage Updater (pipes only)");
  Vertical_Group vgroup = Create_vertical_group(0);   // <-- needs (0) in your build
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
  Append(runbtn, vgroup);
  Append(finbtn, vgroup);
  Append(vgroup, panel);
  Show_widget(panel);
  Clear_console();

  Integer loop = 1;
  while(loop) {
    Integer id; Text cmd, info;
    Wait_on_widgets(id, cmd, info);

    if(id == Get_id(panel) && cmd == "Panel Quit") break;
    if(id == Get_id(finbtn) && cmd == "finish_reply") break;

    if(id == Get_id(runbtn) && cmd == "run_reply") {
      // Validate inputs
      Dynamic_Element ab_elts; Integer ok_ab = Validate(srcbox, ab_elts);      // ok for Source_Box
      if(ok_ab == 0) { Set_error_message(srcbox,"Pick a valid as-built dataset."); Set_data(mbox,"Invalid as-built selection."); continue; }
      Integer ab_count=0; Get_number_of_items(ab_elts,ab_count);
      if(ab_count <= 0) { Set_data(mbox,"As-built dataset is empty."); Print("No as-built elements.\n"); continue; }

      Model dmodel; Integer ok_dm = Validate(modbox, 0, dmodel);               // <-- needs 3 args
      if(ok_dm == 0) { Set_error_message(modbox,"Pick a valid drainage model."); Set_data(mbox,"Invalid drainage model."); continue; }

      Real tol=1.0; if(Validate(tolbox, tol) == 0 || tol <= 0.0) { tol = 1.0; Set_data(mbox,"Invalid tol → using 1.0 m"); }

      // Drainage strings
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

          Element best_e; Text best_name; Real dUS, dDS; Integer orient;
          Integer ok = find_match_line(ab_elts, ab_count, usx,usy, dsx,dsy, tol,
                                       best_e, best_name, dUS, dDS, orient);
          if(!ok) { nomatch++; Print("  seg "+To_text(s)+": NO MATCH within tol\n"); continue; }
          matched++;

          Real ax,ay,az,bx,by,bz; get_line_endpoints(best_e,ax,ay,az,bx,by,bz);
          Real new_us_il = (orient==0) ? az : bz;
          Real new_ds_il = (orient==0) ? bz : az;

          Real lhs, rhs; map_usds_to_lr(dir, new_us_il, new_ds_il, lhs, rhs);

          Real old_us=0, old_ds=0; Get_drainage_pipe_inverts(e, s, old_us, old_ds);
          Integer setrc = Set_drainage_pipe_inverts(e, s, lhs, rhs);
          Set_drainage_pipe_attribute(e, s, "lock us il", 1);
          Set_drainage_pipe_attribute(e, s, "lock ds il", 1);

          updated++;
          Print("  seg "+To_text(s)+": UPDATE line=\""+best_name+"\" | dUS="+To_text(dUS,3)+", dDS="+To_text(dDS,3)+
                " | old("+To_text(old_us,3)+","+To_text(old_ds,3)+") -> new("+To_text(new_us_il,3)+","+To_text(new_ds_il,3)+")\n");
        }
      }

      Text summary = "strings="+To_text(drain_total)+", segs="+To_text(seg_total)+
                     ", matched="+To_text(matched)+", updated="+To_text(updated)+
                     ", no-match="+To_text(nomatch);
      Print(summary+"\n");
      Set_data(mbox, summary);
    }
  }
}
