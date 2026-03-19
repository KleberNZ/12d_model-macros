/*---------------------------------------------------------------------
**   Programmer:Kleber lessa do Prado
**   Date:29/08/25
**   12D Model:            V15
**   Version:              001
**   Macro Name:           Drainage_Updater.4dm
**   Type:                 SOURCE
**
**   Brief description: Update a drainage model from as-built (LIDs, SUMPs, Pipe ILs)
**
**---------------------------------------------------------------------
**   Description:
**   • PITS first: LID (points only; set "cover rl mode"=2 then write RL),
**                 SUMP (lock then set level) – both optional
**   • PIPES second: 2-pt lines; respects flow dir; locks US/DS ILs – optional
**   • Strict 3D reads; each source truly optional
**---------------------------------------------------------------------
**   Update/Modification
**
**
**   (C) Copyright 2013-2025 by your_company Pty Ltd. All Rights
**       Reserved.
**---------------------------------------------------------------------*/
#define DEBUG_FILE      0
#define ECHO_DEBUG_FILE 0
#define ECHO_LINE_NO    0
#define BUILD "version.0.001"

// ----------------------------- INCLUDES -----------------------------
#include "..\\..\\include\\standard_library.H"
#include "..\\..\\include\\size_of.H"

/*global variables*/{
}

// ============================= HELPERS ==============================

// 3D read only; 0 = OK
Integer get_xyz_strict(Element e, Integer vi, Real &x, Real &y, Real &z)
{
  return Get_3d_data(e, vi, x, y, z);
}

// LID matching: **POINTS ONLY** (npts == 1). Returns 1 if found within tol; best_z out
Integer nearest_lid_point(Dynamic_Element ab_elts, Integer ab_count,
                          Real px, Real py, Real tol, Real &best_z)
{
  Real best_d2 = 1.0e30; Integer found = 0;
  Integer i;
  for(i=1; i<=ab_count; i++){
    Element e; Get_item(ab_elts, i, e);
    Integer npts=0; Get_points(e, npts);
    if(npts != 1) continue;                                // enforce point elements
    Real x,y,z; if(Get_3d_data(e, 1, x, y, z) != 0) continue;
    Real dx = x - px, dy = y - py; Real d2 = dx*dx + dy*dy;
    if(d2 < best_d2){ best_d2 = d2; best_z = z; found = 1; }
  }
  return (found && best_d2 <= tol*tol) ? 1 : 0;
}

// Generic nearest vertex (3D only) — used for SUMP if AB is points/strings
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
      Real x,y,z; if(get_xyz_strict(e,vi,x,y,z)!=0) continue;
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
  if(dir!=1) dir=0;                                        // 1=same, 0=opposite
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
  if(get_xyz_strict(e,1,x1,y1,z1)!=0) return 1;
  if(get_xyz_strict(e,2,x2,y2,z2)!=0) return 1;
  return 0;
}

Real dist_xy(Real ax, Real ay, Real bx, Real by)
{
  Real dx=ax-bx, dy=ay-by; return Sqrt(dx*dx+dy*dy);
}

// Find matching 2-pt line for US/DS; orient=0 (a→US,b→DS) or 1 (reversed)
Integer find_match_line(Dynamic_Element ab_elts, Integer ab_count,
                        Real usx,Real usy, Real dsx,Real dsy, Real tol,
                        Element &best_e, Text &best_name, Integer &orient)
{
  Real best_score=1.0e30; Integer found=0;
  Integer i;
  for(i=1;i<=ab_count;i++){
    Element a; Get_item(ab_elts,i,a);
    Integer npts=0; Get_points(a,npts); if(npts!=2) continue;
    Real ax,ay,az,bx,by,bz; if(get_line_endpoints(a,ax,ay,az,bx,by,bz)!=0) continue;

    Real dUS0=dist_xy(usx,usy,ax,ay), dDS0=dist_xy(dsx,dsy,bx,by);
    Real dUS1=dist_xy(usx,usy,bx,by), dDS1=dist_xy(dsx,dsy,ax,ay);

    if(dUS0<=tol && dDS0<=tol){ Real sc=dUS0+dDS0; if(sc<best_score){best_score=sc;found=1;orient=0;best_e=a;} }
    if(dUS1<=tol && dDS1<=tol){ Real sc=dUS1+dDS1; if(sc<best_score){best_score=sc;found=1;orient=1;best_e=a;} }
  }
  if(found){ Get_name(best_e,best_name); if(Text_length(best_name)==0) best_name="<no name>"; return 1; }
  return 0;
}

void map_usds_to_lr(Integer dir, Real il_us, Real il_ds, Real &lhs, Real &rhs)
{
  if(dir==1){ lhs=il_us; rhs=il_ds; } else { lhs=il_ds; rhs=il_us; }
}

// ============================= PANEL ===============================
void mainPanel()
{
  Text panelName="Drainage Updater (Pits and Pipes)";
  Panel              panel  = Create_panel              (panelName,TRUE);
  Vertical_Group     vgroup = Create_vertical_group     (-1);
  Colour_Message_Box cmbMsg = Create_colour_message_box ("");

  // ---------- INPUT WIDGETS ----------
  Source_Box lid_src  = Create_source_box("As-built LID model (POINTS)",  cmbMsg, 0);
  Source_Box sump_src = Create_source_box("As-built SUMP model",         cmbMsg, 0);
  Source_Box pipe_src = Create_source_box("As-built PIPES (2-pt lines)", cmbMsg, 0);
  
  Model_Box  dmodel_box = Create_model_box("Drainage model", cmbMsg, CHECK_MODEL_MUST_EXIST); // require a real model to be chosen
  Real_Box   tol_box    = Create_real_box ("XY tolerance (m)", cmbMsg); Set_data(tol_box, 1.0);

  // ---------- BUTTONS ----------
  Horizontal_Group bgroup = Create_button_group();
  Button process     = Create_button       ("&Process","process");
  Button finish      = Create_finish_button("Finish"  ,"Finish");
  Button help_button = Create_help_button  (panel     ,"Help");
  Append(process    , bgroup);
  Append(finish     , bgroup);
  Append(help_button, bgroup);

  // ---------- LAYOUT ----------
  Append(lid_src   , vgroup);
  Append(sump_src  , vgroup);
  Append(pipe_src  , vgroup);
  Append(dmodel_box, vgroup);
  Append(tol_box   , vgroup);
  Append(cmbMsg    , vgroup);
  Append(bgroup    , vgroup);

  Append(vgroup,panel);
  Show_widget(panel);

  // ---------- EVENT LOOP ----------
  Integer doit = 1;
  while(doit)
  {
    Text cmd="", msg="";
    Integer id, ret = Wait_on_widgets(id,cmd,msg);

    switch(cmd)
    {
      case "keystroke":
      case "set_focus":
      case "kill_focus":
      { continue; } break;
      case "CodeShutdown":
      { Set_exit_code(cmd); } break;
    }

    switch(id)
    {
      case Get_id(panel):
      {
        if(cmd == "Panel Quit")  doit = 0;
        if(cmd == "Panel About") about_panel(panel);
      } break;

      case Get_id(process):
      {
        if(cmd == "process")
        {
          // =============== VALIDATE INPUTS =================
          Dynamic_Element lid_elts, sump_elts, pipe_elts;
          Integer lid_cnt=0, sump_cnt=0, pipe_cnt=0;

          Integer rcL = Validate(lid_src,  lid_elts);
          Integer rcS = Validate(sump_src, sump_elts);
          Integer rcP = Validate(pipe_src, pipe_elts);

          Integer lid_ok  = 0, sump_ok = 0, pipe_ok = 0;

          if(rcL == TRUE) { Get_number_of_items(lid_elts,  lid_cnt);  lid_ok  = (lid_cnt  > 0); }
          else if(rcL != NO_NAME) { Set_error_message(lid_src,  "LID source: invalid selection.");  break; }

          if(rcS == TRUE) { Get_number_of_items(sump_elts, sump_cnt); sump_ok = (sump_cnt > 0); }
          else if(rcS != NO_NAME) { Set_error_message(sump_src, "SUMP source: invalid selection."); break; }

          if(rcP == TRUE) { Get_number_of_items(pipe_elts, pipe_cnt); pipe_ok = (pipe_cnt > 0); }
          else if(rcP != NO_NAME) { Set_error_message(pipe_src, "PIPES source: invalid selection."); break; }

// optional: nothing chosen?
if(!lid_ok && !sump_ok && !pipe_ok){
  Set_data(cmbMsg, "Nothing to do (no as-built sources).");
  break;
}
          // ---- drainage model ----

          // Validate with the same CHECK mode; MODEL_EXISTS means OK
          Model dmodel;
          Integer rc = Validate(dmodel_box, CHECK_MODEL_MUST_EXIST, dmodel);
          if(rc != MODEL_EXISTS){                       // handles NO_MODEL / NO_NAME etc.
            Set_error_message(dmodel_box, "Pick a valid drainage model.");
            break;
          }

          Real tol=1.0; if(Validate(tol_box, tol) == 0 || tol<=0.0) tol = 1.0;

          Dynamic_Element d_elts; Integer d_count = 0;
          if(Get_elements(dmodel, d_elts, d_count) != 0 || d_count == 0){
            Set_data(cmbMsg, "Drainage model is empty.");
            break;
          }     
          // =============== PROCESSING =================

          Clear_console();
          Print("=== Drainage Updater ===  tol="+To_text(tol,3)+" m\n");

          // ---------- PITS (LID + SUMP) ----------
          Print("== PITS ==  LID="+(lid_ok?"yes":"no")+", SUMP="+(sump_ok?"yes":"no")+"\n");
          Integer lids_upd=0, lids_no=0, sumps_upd=0, sumps_no=0;
          Integer i, p;

          for(i=1;i<=d_count;i++){
            Element s; Get_item(d_elts,i,s);
            Integer dflow=0; if(Get_drainage_flow(s,dflow)!=0) continue;
            Integer npits=0; if(Get_drainage_pits(s,npits)!=0 || npits<=0) continue;

            Text nm; Get_name(s,nm); if(Text_length(nm)==0) nm="<no name>";
            Print("STRING | "+nm+" | pits="+To_text(npits)+"\n");

            for(p=1;p<=npits;p++){
              Real px,py,pz; if(Get_drainage_pit(s,p,px,py,pz)!=0){ Print("  pit "+To_text(p)+": <read error>\n"); continue; }

              // LID (points only)
              if(lid_ok){
                Real lid_z=0.0;
                if(nearest_lid_point(lid_elts, lid_cnt, px,py, tol, lid_z)!=0){
                  Attributes natt;
                  if(Get_drainage_pit_attributes(s,p,natt)==0){
                    Set_attribute(natt, "cover rl mode", 2);      // Manual
                    Set_drainage_pit_attributes(s,p,natt);        // commit
                  }
                  if(Set_drainage_pit(s,p,px,py,lid_z)==0){
                    lids_upd++; Print("  pit "+To_text(p)+": LID "+To_text(pz,3)+" -> "+To_text(lid_z,3)+"\n");
                  } else {
                    lids_no++;  Print("  pit "+To_text(p)+": LID set failed\n");
                  }
                } else { lids_no++; Print("  pit "+To_text(p)+": LID no match\n"); }
              }

              // SUMP
              if(sump_ok){
                Real sump_z=0.0, sump_old=0.0; Integer have_old=(Get_drainage_pit_sump_level(s,p,sump_old)==0);
                if(nearest_vertex_xy(sump_elts, sump_cnt, px,py, tol, sump_z)!=0){
                  if(Set_drainage_pit_float_sump(s,p,0)==0 && Set_drainage_pit_sump_level(s,p,sump_z)==0){
                    sumps_upd++;
                    if(have_old) Print("  pit "+To_text(p)+": SUMP "+To_text(sump_old,3)+" -> "+To_text(sump_z,3)+"\n");
                    else         Print("  pit "+To_text(p)+": SUMP ? -> "+To_text(sump_z,3)+"\n");
                  } else { sumps_no++; Print("  pit "+To_text(p)+": SUMP set failed\n"); }
                } else { sumps_no++; Print("  pit "+To_text(p)+": SUMP no match\n"); }
              }
            }
          }

          Print("PITS SUMMARY: lids_upd="+To_text(lids_upd)+", lids_no="+To_text(lids_no)+
                ", sump_upd="+To_text(sumps_upd)+", sump_no="+To_text(sumps_no)+"\n\n");

          // ---------- PIPES ----------
          Print("== PIPES ==  "+(pipe_ok?"running":"skipped")+"\n");
          if(pipe_ok){
            Integer updated=0, matched=0, nomatch=0, seg_total=0, drain_total=0;
            Integer sidx;

            for(i=1;i<=d_count;i++){
              Element e; Get_item(d_elts,i,e);
              Integer dir, nsegs, npits;
              if(!classify_drainage(e, dir, nsegs, npits)) continue;
              drain_total++;

              Text sname; Get_name(e,sname); if(Text_length(sname)==0) sname="<no name>";
              Print("DRAIN | "+sname+" | segs="+To_text(nsegs)+" | dir="+To_text(dir)+"\n");

              for(sidx=1; sidx<=nsegs; sidx++){
                seg_total++;

                Integer us_idx = (dir==1) ? sidx   : sidx+1;
                Integer ds_idx = (dir==1) ? sidx+1 : sidx;

                Real usx,usy,usz, dsx,dsy,dsz;
                if(safe_get_pit(e,us_idx,npits,usx,usy,usz)!=0 ||
                   safe_get_pit(e,ds_idx,npits,dsx,dsy,dsz)!=0){
                  Print("  seg "+To_text(sidx)+": <pit read error>\n"); continue;
                }

                Element best_e; Text best_name; Integer orient;
                if(!find_match_line(pipe_elts, pipe_cnt, usx,usy, dsx,dsy, tol, best_e, best_name, orient)){
                  nomatch++; Print("  seg "+To_text(sidx)+": NO MATCH within tol\n"); continue;
                }

                matched++;

                Real ax,ay,az,bx,by,bz; get_line_endpoints(best_e,ax,ay,az,bx,by,bz);
                Real new_us_il = (orient==0) ? az : bz;
                Real new_ds_il = (orient==0) ? bz : az;

                Real lhs, rhs; map_usds_to_lr(dir, new_us_il, new_ds_il, lhs, rhs);

                Real old_us=0, old_ds=0; Get_drainage_pipe_inverts(e, sidx, old_us, old_ds);
                Set_drainage_pipe_inverts(e, sidx, lhs, rhs);
                Set_drainage_pipe_attribute(e, sidx, "lock us il", 1);
                Set_drainage_pipe_attribute(e, sidx, "lock ds il", 1);

                updated++;
                Print("  seg "+To_text(sidx)+": ("+To_text(old_us,3)+","+To_text(old_ds,3)+") -> ("+
                      To_text(new_us_il,3)+","+To_text(new_ds_il,3)+")\n");
              }
            }

            Print("PIPES SUMMARY: updated="+To_text(updated)+", matched="+To_text(matched)+", no-match="+To_text(nomatch)+"\n");
          }

          Set_data(cmbMsg ,"Process finished");
        }
      } break;

      default:
      {
        if(cmd == "Finish") doit = 0;
      } break;
    }
  }
}

void main()
{
  // (pre-checks would go here)
  mainPanel();
}
// ============================= END OF FILE ===========================