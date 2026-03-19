//--------------------------------------------------------------
// Micro‑Macro 3: Spatial Matcher (editable XY tolerance)
// Panel: Source_Box (as‑built 2‑pt lines) + Model_Box (drainage) + Real_Box (XY tol, default 1.0m).
// For each drainage segment, determine US/DS from pits using flow dir (1=same, 0=opposite).
// Find a single as‑built 2‑pt line whose endpoints match US/DS within XY tolerance
// (either orientation). Print match/no‑match with distances (3 dp). No updates.
//--------------------------------------------------------------
// ----------------------------- INCLUDES -----------------------------
#include "..\\..\\include\\standard_library.H"
#include "..\\..\\include\\size_of.H"

// ----------------------------- HELPERS ------------------------------
Text fmt3(Real r) { return To_text(r,3); }

Real dist_xy(Real ax, Real ay, Real bx, Real by)
{
  Real dx = ax - bx;
  Real dy = ay - by;
  return Sqrt(dx*dx + dy*dy);
}

// Drainage classification
Integer classify_drainage(Element e, Integer &dir)
{
  Integer rc = Get_drainage_flow(e, dir);
  if(rc != 0) { dir=-1; return 0; }
  if(dir != 1) dir = 0; // 1=same, 0=opposite
  return 1;
}

// Safe get pit XYZ with bounds checking; returns 0 on success
Integer safe_get_pit(Element e, Integer idx, Integer npits, Real &x, Real &y, Real &z)
{
  if(idx < 1 || idx > npits) return 1;
  return Get_drainage_pit(e, idx, x, y, z);
}

// Get as‑built line endpoints; require exactly 2 points. Return 0 on success.
Integer get_line_endpoints(Element e, Real &x1,Real &y1,Real &z1, Real &x2,Real &y2,Real &z2)
{
  Integer npts=0; Get_points(e,npts);
  if(npts != 2) return 1;
  if(Get_super_vertex_coord(e,1,x1,y1,z1)==0 && Get_super_vertex_coord(e,2,x2,y2,z2)==0) return 0;
  if(Get_3d_data(e,1,x1,y1,z1)==0 && Get_3d_data(e,2,x2,y2,z2)==0) return 0;
  if(Get_2d_data(e,1,x1,y1)==0 && Get_2d_data(e,2,x2,y2)==0) { z1=0; z2=0; return 0; }
  return 1;
}

// Try to find a single 2‑pt as‑built line whose endpoints are within tol to US/DS (either orientation).
Integer find_match_line(Dynamic_Element ab_elts, Integer ab_count,
                        Real usx,Real usy, Real dsx,Real dsy, Real tol,
                        Element &best_e, Text &best_name, Real &best_dus, Real &best_dds, Integer &best_orient)
{
  Real best_score = 1.0e30;
  Integer found = 0;

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
    Get_name(best_e,best_name);
    if(Text_length(best_name)==0) best_name = "<no name>";
    return 1;
  }
  return 0;
}

// ------------------------------- MAIN -------------------------------

void main()
{
  // UI
  Panel          panel   = Create_panel("Spatial Matcher");
  Vertical_Group vgroup  = Create_vertical_group(0);
  Message_Box    mbox    = Create_message_box("");
  Source_Box     srcbox  = Create_source_box("As‑built 2‑pt lines", mbox, 0);
  Model_Box      modbox  = Create_model_box("Drainage model", mbox, 0);
  Real_Box       tolbox  = Create_real_box("XY tolerance (m)", mbox);
  Button         runbtn  = Create_run_button("Run", "run_reply");
  Button         finbtn  = Create_finish_button("Finish", "finish_reply");

  // default tol = 1.0 m
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

    switch(id) {
      case Get_id(panel): {
        if(cmd == "Panel Quit") loop = 0; break;
      }
      case Get_id(finbtn): {
        if(cmd == "finish_reply") loop = 0; break;
      }
      case Get_id(runbtn): {
        if(cmd == "run_reply") {
          // Validate inputs
          Dynamic_Element ab_elts; Integer v1 = Validate(srcbox, ab_elts);
          if(v1 == 0) { Set_error_message(srcbox,"Pick a valid as‑built dataset."); Set_data(mbox,"Invalid as‑built selection."); break; }
          Integer ab_count=0; Get_number_of_items(ab_elts,ab_count);
          if(ab_count <= 0) { Set_data(mbox,"As‑built dataset is empty."); Print("No as‑built elements.\n"); break; }

          Model dmodel; Integer v2 = Validate(modbox, 0, dmodel);
          if(v2 == 0) { Set_error_message(modbox,"Pick a valid drainage model."); Set_data(mbox,"Invalid drainage model."); break; }

          Real tol=1.0; Integer vt = Validate(tolbox, tol);
          if(vt == 0 || tol <= 0) { tol = 1.0; Set_data(mbox,"Invalid tol → using 1.0 m"); }

          Dynamic_Element d_elts; Integer d_count=0;
          Integer gerc = Get_elements(dmodel, d_elts, d_count);
          if(gerc != 0 || d_count <= 0) { Set_data(mbox,"Drainage model is empty."); Print("No drainage elements.\n"); break; }

          Print("=/= Spatial Matcher =/= tol="+fmt3(tol)+" m\n");
          Integer matches=0, nomatches=0, seg_total=0, drain_total=0;

          for(Integer i=1;i<=d_count;i++) {
            Element e; Get_item(d_elts,i,e);
            Integer dir;
            if(!classify_drainage(e, dir)) continue;
            drain_total++;

            Integer nsegs=0; Get_segments(e, nsegs);
            Integer npits=0; Get_drainage_pits(e, npits);
            if(nsegs <= 0 || npits <= 1) { Print("  skip: zero segments or pits\n"); continue; }

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
              if(ok) {
                matches++;
                Print("  seg "+To_text(s)+": MATCH line=\""+best_name+"\" | dUS="+fmt3(dus)+", dDS="+fmt3(dds)+" | orient="+To_text(orient)+"\n");
              } else {
                nomatches++;
                Print("  seg "+To_text(s)+": NO MATCH within tol\n");
              }
            }
          }

          Text summary = "Drainage strings="+To_text(drain_total)
            +", segments="+To_text(seg_total)
            +", matches="+To_text(matches)
            +", no‑matches="+To_text(nomatches);
          Print(summary+"\n");
          Set_data(mbox, summary);
        }
        break;
      }
    } // switch
  }   // while

  Set_finish_button(panel,1);
}
