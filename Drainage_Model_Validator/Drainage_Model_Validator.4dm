//--------------------------------------------------------------
// Micro‑Macro : Drainage Model Validator
// - Drainage-only via Get_drainage_flow + Get_drainage_sewer
// - IL mapping honors dir (1 same, 0 opposite)
// - Endpoints from pits with full bounds checks (avoid out-of-range indices)
// - Warn when pits != segments+1
//--------------------------------------------------------------
// ----------------------------- INCLUDES -----------------------------
#include "..\\..\\include\\standard_library.H"
#include "..\\..\\include\\size_of.H"

Text fmt3(Real r) { return To_text(r,3); }

// Return 1 if drainage; sets dir (0/1) and sewer_type (0 stormwater, 1 sewer)
Integer classify_drainage(Element e, Integer &dir, Integer &sewer_type, Text &flow_txt, Text &stype_txt)
{
  Integer rc = Get_drainage_flow(e, dir);
  if(rc != 0) { dir=-1; sewer_type=-1; flow_txt="not drainage"; stype_txt="n/a"; return 0; }

  Integer sret = Get_drainage_sewer(e, sewer_type); // 0 on success
  if(sret != 0) sewer_type = 0;
  stype_txt = (sewer_type==1) ? "sewer" : "stormwater";
  flow_txt  = (dir==1) ? "same as string" : "opposite to string";
  return 1;
}

// Safe get pit XYZ with bounds checking; returns 0 on success
Integer safe_get_pit(Element e, Integer idx, Integer npits, Real &x, Real &y, Real &z)
{
  if(idx < 1 || idx > npits) return 1;
  return Get_drainage_pit(e, idx, x, y, z);
}

// Print one drainage string: per‑segment endpoints from pits and ILs.
Integer report_drain(Element e, Text name, Integer dir, Integer sewer_type)
{
  Integer nsegs = 0; Get_segments(e, nsegs);
  Integer npits = 0; Get_drainage_pits(e, npits);

  Print("DRAIN | name="+name+" | type="+((sewer_type==1)?"sewer":"storm")+" | segments="+To_text(nsegs)+", pits="+To_text(npits)+"\n");

  if(nsegs <= 0) return 0;
  if(npits <= 1) { Print("  warning: insufficient pits for endpoints\n"); }

  Integer expected = nsegs + 1;
  if(npits != expected) {
    Print("  warning: pits ("+To_text(npits)+") != segments+1 ("+To_text(expected)+")\n");
  }

  for(Integer i=1; i<=nsegs; i++) {
    Integer us_idx = (dir==1) ? i   : i+1;
    Integer ds_idx = (dir==1) ? i+1 : i;

    Real usx=0,usy=0,usz=0, dsx=0,dsy=0,dsz=0;
    Integer rc1 = safe_get_pit(e, us_idx, npits, usx, usy, usz);
    Integer rc2 = safe_get_pit(e, ds_idx, npits, dsx, dsy, dsz);

    // Inverts returned along string; swap based on dir
    Real inv_a=0, inv_b=0;
    Integer irc = Get_drainage_pipe_inverts(e, i, inv_a, inv_b);
    Real us_il = (dir==1) ? inv_a : inv_b;
    Real ds_il = (dir==1) ? inv_b : inv_a;

    Text geo_part;
    if(rc1==0 && rc2==0) {
      geo_part = "x1,y1("+fmt3(usx)+","+fmt3(usy)+","+fmt3(usz)+")"
                 +" x2,y2("+fmt3(dsx)+","+fmt3(dsy)+","+fmt3(dsz)+")";
    } else {
      geo_part = "US/DS <pit read error>";
    }

    if(irc == 0) {
      Print("  seg "+To_text(i)+": " + geo_part
            +" | IL_US="+fmt3(us_il)+", IL_DS="+fmt3(ds_il)+"\n");
    } else {
      Print("  seg "+To_text(i)+": " + geo_part + " | <invert read error>\n");
    }
  }
  return nsegs;
}

// ------------------------------- MAIN -------------------------------

void main()
{
  Panel          panel   = Create_panel("Drainage Model Validator");
  Vertical_Group vgroup  = Create_vertical_group(0);
  Message_Box    mbox    = Create_message_box("");
  Model_Box      modbox  = Create_model_box("Drainage model", mbox, 0);
  Button         runbtn  = Create_run_button("Run", "run_reply");
  Button         finbtn  = Create_finish_button("Finish", "finish_reply");

  Append(modbox, vgroup);
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
        if(cmd == "Panel Quit") loop = 0;
        break;
      }
      case Get_id(finbtn): {
        if(cmd == "finish_reply") loop = 0;
        break;
      }
      case Get_id(runbtn): {
        if(cmd == "run_reply") {
          // Validate model selection
          Model dmodel;
          Integer ok = Validate(modbox, 0, dmodel);
          if(ok == 0) { Set_error_message(modbox, "Please select a valid model."); Set_data(mbox, "Invalid model."); break; }

          // Get elements
          Dynamic_Element elts; Integer count=0;
          Integer gerc = Get_elements(dmodel, elts, count);
          if(gerc != 0 || count <= 0) { Set_data(mbox, "Model is empty."); Print("No elements in model.\n"); break; }

          Integer n_drain=0, n_nondrain=0, n_segs_total=0;
          Print(" ==/== Drainage Model Validator ==/== \n");
          for(Integer i=1; i<=count; i++) {
            Element e; Get_item(elts, i, e);
            Text name; Get_name(e, name); if(Text_length(name)==0) name = "<no name>";

            Integer dir, stype; Text flow_txt, stype_txt;
            if(classify_drainage(e, dir, stype, flow_txt, stype_txt)) {
              n_drain++;
              Print("Flow: "+flow_txt+" (dir="+To_text(dir)+") | type="+stype_txt+"\n");
              n_segs_total += report_drain(e, name, dir, stype);
            } else {
              n_nondrain++;
              Print("NON   | name="+name+"\n");
            }
          }

          Text summary = "Processed="+To_text(count)+
            ", drainage="+To_text(n_drain)+
            ", non-drainage="+To_text(n_nondrain)+
            ", segments="+To_text(n_segs_total);
          Print(summary+"\n");
          Set_data(mbox, summary);
        }
        break;
      }
    } // switch
  }   // while

  Set_finish_button(panel,1);
}
