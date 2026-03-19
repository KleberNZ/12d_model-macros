//--------------------------------------------------------------
// Micro-Macro 1: As-Built Data Inspector (Validate fixed)
// - Correct handling of Validate(Source_Box,...): zero means ERROR
// - Removed nonexistent Get_value(...) fallback
//--------------------------------------------------------------
// ----------------------------- INCLUDES -----------------------------
#include "..\\..\\include\\standard_library.H"
#include "..\\..\\include\\size_of.H"

// ---- helpers --------------------------------------------------------
Integer get_xyz(Element elt,Integer i,Real &x,Real &y,Real &z)
{
  if(Get_super_vertex_coord(elt,i,x,y,z) == 0) return 0;
  if(Get_3d_data(elt,i,x,y,z) == 0) return 0;
  if(Get_2d_data(elt,i,x,y)  == 0) { z = 0.0; return 0; }
  return 1;
}

Text fmt3(Real r) { return To_text(r,3); }

void print_point(Element e, Text name, Integer &count_points)
{
  Real x1,y1,z1;
  if(get_xyz(e,1,x1,y1,z1) != 0) { Print("POINT | name="+name+" | <coord read error>\n"); return; }
  Print("POINT | name="+name+" | x="+fmt3(x1)+", y="+fmt3(y1)+", z="+fmt3(z1)+"\n");
  count_points++;
}

void print_line(Element e, Text name, Integer &count_lines)
{
  Real x1,y1,z1,x2,y2,z2;
  if(get_xyz(e,1,x1,y1,z1) != 0 || get_xyz(e,2,x2,y2,z2) != 0) {
    Print("LINE  | name="+name+" | <coord read error>\n"); return;
  }
  Print("LINE  | name="+name+" | (US) x1="+fmt3(x1)+", y1="+fmt3(y1)+", z1="+fmt3(z1)
        +" | (DS) x2="+fmt3(x2)+", y2="+fmt3(y2)+", z2="+fmt3(z2)+"\n");
  count_lines++;
}

// ---- main with panel ------------------------------------------------

void main()
{
  Panel         panel      = Create_panel("As-Built Data Inspector");
  Vertical_Group vgroup    = Create_vertical_group(0);
  Message_Box   msg_box    = Create_message_box("");
  Source_Box    src_box    = Create_source_box("As-built data (points or 2-pt lines)", msg_box, 0);
  Button        run_btn    = Create_run_button("Run", "run_reply");
  Button        finish_btn = Create_finish_button("Finish", "finish_reply");

  Append(src_box,  vgroup);
  Append(msg_box,  vgroup);
  Horizontal_Group hgrp = Create_button_group();
  Append(run_btn,    hgrp);
  Append(finish_btn, hgrp);
  Append(hgrp,     vgroup);
  Append(vgroup,   panel);
  Show_widget(panel);
  Clear_console();

  Integer doit = 1;
  while(doit) {
    Integer id; Text cmd,msg;
    Integer ret = Wait_on_widgets(id,cmd,msg);
    if(cmd == "CodeShutdown") { Set_exit_code("CodeShutdown"); return; }
    if(cmd == "keystroke") continue;

    switch(id) {
      case Get_id(panel): {
        if(cmd == "Panel Quit") doit = 0;
        break;
      }
      case Get_id(finish_btn): {
        if(cmd == "finish_reply") doit = 0;
        break;
      }
      case Get_id(run_btn): {
        if(cmd == "run_reply") {
          Dynamic_Element elts; Integer vret = Validate(src_box, elts);
          // Per manual: 0 = drastic error; -2 = blank/choice issue; 1 (TRUE) = ok; NO_NAME when optional
          if(vret == 0) {
            Set_error_message(src_box, "Please pick a valid model or selection.");
            Set_data(msg_box,"Invalid selection.");
            break;
          }

          Integer n=0; Get_number_of_items(elts,n);
          if(n <= 0) { Set_data(msg_box,"No elements to process."); Print("No elements found.\n"); break; }

          Integer count_total=0, count_points=0, count_lines=0, count_skipped=0;
          Print("---- As-Built Data Inspector ----\n");
          for(Integer i=1;i<=n;i++) {
            Element e; Get_item(elts,i,e);
            Text name; Get_name(e,name);
            if(Text_length(name)==0) name = "<no name>";

            Integer numpts=0; Get_points(e,numpts);

            if(numpts == 1) {
              print_point(e,name,count_points);
              count_total++;
            } else if(numpts == 2) {
              print_line(e,name,count_lines);
              count_total++;
            } else {
              Print("SKIP  | name="+name+" | numpts="+To_text(numpts)+"\n");
              count_skipped++;
            }
          }
          Text summary = "Summary: total="+To_text(count_total)
                         +", points="+To_text(count_points)
                         +", lines="+To_text(count_lines)
                         +", skipped="+To_text(count_skipped);
          Print(summary + "\n");
          Set_data(msg_box, summary);
        }
        break;
      }
    }
  }

  Set_finish_button(panel,1);
}
