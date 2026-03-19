/*---------------------------------------------------------------------
**   Programmer:Kleber Lessa do Prado
**   Date:29/08/25
**   12D Model:            V15
**   Version:              001
**   Macro Name:           AverageXYZ_to_Points.4dm
**   Type:                 SOURCE
**
**   Brief description: For each selected element, compute average XYZ and
**                      create a point string in the target model.
**
**---------------------------------------------------------------------
**   Description:
**   - Source_Box lets user pick a dataset of elements.
**   - Model_Box (CHECK_MODEL_CREATE) sets/creates output model.
**   - For each element: read vertices, average XYZ, create pt<i>.
**   - Prints element count, per-point Z, and summary.
**---------------------------------------------------------------------*/
#define DEBUG_FILE      0
#define ECHO_DEBUG_FILE 0
#define ECHO_LINE_NO    0
#define BUILD "version.0.001"

// ----------------------------- INCLUDES -----------------------------
#include "..\\..\\include\\standard_library.H"
#include "..\\..\\include\\size_of.H"
#include "..\\..\\include\\set_ups.h"


// ----------------------------- HELPERS ------------------------------
void print_err(Colour_Message_Box cmb, Text msg)
{
  Set_data(cmb, msg, 2);
  Print("ERROR: " + msg);
  Print();
}

// ----------------------------- PANEL --------------------------------
void mainPanel()
{
  Text panelName="Average XYZ to Points";
  Panel              panel  = Create_panel(panelName, TRUE);
  Vertical_Group     vgroup = Create_vertical_group(-1);
  Message_Box        mbox   = Create_message_box("Inputs");
  Colour_Message_Box cmbMsg = Create_colour_message_box("");

  // Inputs
  Source_Box srcBox = Create_source_box("&Source dataset", mbox, 0);
  Model_Box  mdlBox = Create_model_box("&Output model",   mbox, CHECK_MODEL_CREATE);

  // Buttons
  Horizontal_Group bgroup = Create_button_group();
  Button process     = Create_button("&Process", "process");
  Button finish      = Create_finish_button("Finish", "Finish");
  Button help_button = Create_help_button(panel, "Help");
  Append(process    , bgroup);
  Append(finish     , bgroup);
  Append(help_button, bgroup);

  // Layout
  Append(srcBox, vgroup);
  Append(mdlBox, vgroup);
  Append(cmbMsg, vgroup);
  Append(bgroup, vgroup);
  Append(vgroup, panel);
  Show_widget(panel);

  Integer doit = 1;
  while(doit)
  {
    Text cmd="", msg="";
    Integer id, ret = Wait_on_widgets(id, cmd, msg);

    switch(cmd)
    {
      case "keystroke":
      case "set_focus":
      case "kill_focus": 
      {
        continue;
      } 
      break;
      case "CodeShutdown":
      {
        Set_exit_code(cmd);
      }
       break;
    }
    switch(id)
    {
      case Get_id(panel):
      {
        if(cmd=="Panel Quit") doit=0;
        if(cmd=="Panel About") about_panel(panel);
      } break;

      case Get_id(process):
      {
        if(cmd=="process")
        {
          // ---- read widgets ----
          Dynamic_Element de;  Null(de);
          Integer vret = Validate(srcBox, de);   // ok even if zero items
          Integer nEl = 0; Get_number_of_items(de, nEl);

          Text modelName=""; Get_data(mdlBox, modelName);

          // ---- validate ----
          if(modelName=="")
          {
            print_err(cmbMsg, "Output model not set.");
            Null(de);
            break;
          }
          Model outModel = Get_model_create(modelName);
          if(Model_exists(outModel)==0)
          {
            print_err(cmbMsg, "Failed to create/open output model.");
            Null(de);
            break;
          }
          if(nEl<=0)
          {
            print_err(cmbMsg, "Selection contains no elements.");
            Null(de);
            break;
          }

          // ---- report element count ----
          Print("Selected elements: " + To_text(nEl));
          Integer made=0;

          // ---- main loop ----
          Integer i;
          for(i=1;i<=nEl;i++)
          {
            Element e; Get_item(de, i, e);
            if(Element_exists(e)!=1) { Print("Skip " + To_text(i) + ": invalid element"); continue; }

            Integer npt=0;
            if(Get_points(e, npt)!=0)
            { Print("Skip " + To_text(i) + ": cannot read vertex count"); continue; }

            Print("Element " + To_text(i) + ": vertices = " + To_text(npt));

            if(npt<1)
            { Print("Skip " + To_text(i) + ": no vertices"); continue; }

            // read XYZ
            Real x[npt], y[npt], z[npt];
            Integer got=0;
            Integer gret = Get_3d_data(e, x, y, z, npt, got);   // returns 0 on success
            if(gret!=0 || got<1)
            { Print("Skip " + To_text(i) + ": no 3D data"); continue; }

            // average
            Integer k;
            Real sx=0.0, sy=0.0, sz=0.0;
            for(k=1;k<=got;k++){ sx+=x[k]; sy+=y[k]; sz+=z[k]; }
                Real inv = 1.0 / got;          // got is Integer; promoted to Real
                Real ax = sx * inv;
                Real ay = sy * inv;
                Real az = sz * inv;


            // create 1-vertex 3D element
            Real px[1], py[1], pz[1];
            px[1]=ax; py[1]=ay; pz[1]=az;
            Element pt = Create_3d(px,py,pz,1);
            Text pname = "pt" + To_text(i);
            Set_name(pt, pname);
            if(Set_model(pt, outModel)!=0)
            { Print("Skip " + To_text(i) + ": failed to place point"); continue; }

            // per-point report
            Print(pname + " -> aveZ = " + To_text(az,3) + "m");
            made++;
          }

          // ---- summary ----
          Print("Created points: " + To_text(made) + " into model \"" + modelName + "\"");
          Print();
          Set_data(cmbMsg, "Done", 0);

          Null(de);
        }
      } break;

      default:
      {
        if(cmd=="Finish") doit=0;
      } break;
    }
  }
}

void main()
{
  mainPanel();
}
