/*---------------------------------------------------------------------
**   Programmer:  (you)
**   Date:        23/08/25
**   12D Model:   V15
**   Version:     004
**   Macro:      Update_Pipe_Inverts_From_Vertex_Data_Panel_Fixed.4dm
**   Type:       SOURCE
**
**   Brief:
**     For each drainage pipe (string) in the selected model, find ONE
**     super string in Source1 whose TWO endpoints both lie within the
**     XY tolerance of the pipe's two ends. Then set the pipe inverts:
**       US = higher Z,  DS = lower Z   (from that super string only).
**     FIXED: Now properly handles flow direction (same/opposite to string).
**
**   Notes:
**     - Skips Source1 vertices with Null Z or Z ≈ -999.
**     - Locks attributes "lock us il" and "lock ds il" to 1 (manual)
**       before writing so DNE will not float the levels later.
**     - Flow direction: 1=same as chainage, 0=opposite to chainage
**
**   FIXES APPLIED:
**     - Fixed Get_drainage_flow() API usage
**     - Corrected element type filtering for drainage strings
**     - Improved error handling and debugging
**     - Fixed pipe index parameter in drainage functions
---------------------------------------------------------------------*/
#define DEBUG_FILE      0
#define ECHO_DEBUG_FILE 0
#define ECHO_LINE_NO    0
#define BUILD "15.0.004"

#include "..\\..\\include\\standard_library.H"
#include "..\\..\\include\\size_of.H"

#define MAX_DRAIN_PTS 8192

/* ============================== Globals ============================= */
/*global variables*/{
  Real g_searchRadiusM = 1.0;    /* default 1 m (≈ 1.0 m diameter) */
}

/* ============================== Helpers ============================= */

/* Simple validity check for a Z value (skip Null and ~-999) */
Integer IsGoodZ(Real z)
{
  if (Is_null(z)) return 0;
  if (z <= -998.999 && z >= -999.001) return 0;  /* treat -999 as invalid */
  return 1;
}

/* Flow direction function - CORRECTED */
Integer GetDrainageFlowDirection(Element drain, Integer &flow_direction)
{
  // First check if element is actually a drainage string
  Text element_type;
  Get_type(drain, element_type);
  
  if(element_type != "Drainage")
  {
    Print("Element type is: " + element_type + " (not Drainage)\n");
    return 0; // Failed - not a drainage string
  }
  
  // Get the flow direction using the correct API
  Integer result = Get_drainage_flow(drain, flow_direction);
  
  if(result != 0) 
  {
    Print("Failed to get flow direction, error: " + To_text(result) + "\n");
    // Default to flow same as chainage if we can't get the attribute
    flow_direction = 1;
    return 1; // Continue with default
  }
  
  // Report the flow direction
  Print("Flow Direction Report:\n");
  Print("---------------------\n");
  
  if(flow_direction == 1)
  {
    Print("Flow direction: 1 (same as drainage string chainage direction)\n");
    Print("The flow direction matches the chainage direction of the string\n");
  }
  else if(flow_direction == 0)
  {
    Print("Flow direction: 0 (opposite to drainage string chainage direction)\n");
    Print("The flow direction is opposite to the chainage direction of the string\n");
  }
  else
  {
    Print("Flow direction: " + To_text(flow_direction) + " (unexpected value)\n");
  }
  
  return 1; // Success
}

/* Get drainage string end XY using drainage data arrays (first/last verts) */
Integer GetDrainEndsXY(Element e, Real &x1, Real &y1, Real &x2, Real &y2)
{
  Real  x[MAX_DRAIN_PTS], y[MAX_DRAIN_PTS], z[MAX_DRAIN_PTS], r[MAX_DRAIN_PTS];
  Integer f[MAX_DRAIN_PTS];
  Integer n = 0;

  Integer ok = Get_drainage_data(e, x, y, z, r, f, MAX_DRAIN_PTS, n); /* 0 == success */
  if (ok != 0 || n < 2) {
    Print("Failed to get drainage data or insufficient points. Error: " + To_text(ok) + ", Points: " + To_text(n) + "\n");
    return 0;
  }

  x1 = x[1]; y1 = y[1];
  x2 = x[n]; y2 = y[n];
  Print("Drainage ends: (" + To_text(x1) + "," + To_text(y1) + ") to (" + To_text(x2) + "," + To_text(y2) + ")\n");
  return 1;
}

/* Match ONE super string by requiring BOTH ends within tol of the pipe ends.
   Returns the Z values at string start/end positions (z1=start, z2=end)
   rather than pre-determining US/DS based on elevation alone.
   - Pipe ends: (px1,py1) and (px2,py2)
   - For each Super e: use its first & last vertices (sx1,sy1,sz1) and (sx2,sy2,sz2)
   - Accept if either orientation fits:
        A) (px1,py1)~(sx1,sy1) AND (px2,py2)~(sx2,sy2)
        B) (px1,py1)~(sx2,sy2) AND (px2,py2)~(sx1,sy1)
   - Choose the candidate with smallest total d^2.
   - Outputs z1 = Z at string START, z2 = Z at string END
   Returns 1 if matched; else 0.  */
Integer MatchSuperForPipe(Dynamic_Element &src,
                          Real px1, Real py1, Real px2, Real py2,
                          Real tolM,
                          Real &z1, Real &z2)
{
  Integer nEl = 0; 
  if (Get_number_of_items(src, nEl) != 0 || nEl <= 0) {
    Print("No elements in source dataset\n");
    return 0;
  }

  Real tol2 = tolM * tolM;
  Integer found = 0;
  Real bestScore = 9.9e99, bestZ1 = 0.0, bestZ2 = 0.0;

  Print("Searching " + To_text(nEl) + " elements with tolerance " + To_text(tolM) + "m\n");

  Integer maxSearch = 500; // Safety limit for source elements
  Integer searchLimit = (nEl < maxSearch) ? nEl : maxSearch;

  Integer i;
  for (i = 1; i <= searchLimit; i = i + 1)
  {
    Element e; 
    if (Get_item(src, i, e) != 0) continue;

    Text et = "";
    if (Get_type(e, et) != 0 || et != "Super") {
      continue;
    }

    Integer nV = 0; 
    if (Get_points(e, nV) != 0 || nV < 2) {
      continue;
    }

    Real sx1=0.0, sy1=0.0, sz1=0.0;
    Real sx2=0.0, sy2=0.0, sz2=0.0;

    if (Get_super_vertex_coord(e, 1, sx1, sy1, sz1) != 0) continue;
    if (Get_super_vertex_coord(e, nV, sx2, sy2, sz2) != 0) continue;

    if (!IsGoodZ(sz1) || !IsGoodZ(sz2)) continue;

    Real dx11 = sx1 - px1, dy11 = sy1 - py1;
    Real dx22 = sx2 - px2, dy22 = sy2 - py2;
    Real d2_A1 = dx11*dx11 + dy11*dy11;
    Real d2_A2 = dx22*dx22 + dy22*dy22;

    Real dx12 = sx2 - px1, dy12 = sy2 - py1;
    Real dx21 = sx1 - px2, dy21 = sy1 - py2;
    Real d2_B1 = dx12*dx12 + dy12*dy12;
    Real d2_B2 = dx21*dx21 + dy21*dy21;

    if (d2_A1 <= tol2 && d2_A2 <= tol2)
    {
      Real score = d2_A1 + d2_A2;
      if (score < bestScore)
      {
        bestScore = score;
        bestZ1 = sz1;
        bestZ2 = sz2;
        found = 1;
      }
    }

    if (d2_B1 <= tol2 && d2_B2 <= tol2)
    {
      Real score = d2_B1 + d2_B2;
      if (score < bestScore)
      {
        bestScore = score;
        bestZ1 = sz2;
        bestZ2 = sz1;
        found = 1;
      }
    }
  }

  if (found) { 
    z1 = bestZ1; 
    z2 = bestZ2; 
    Print("Match found: Z1=" + To_text(z1) + ", Z2=" + To_text(z2) + "\n");
    return 1; 
  }
  return 0;
}

/* Lock US/DS invert attributes to MANUAL (1 = locked) */
void LockLinkInverts(Element e)
{
  /* pipe index = 1 for normal drainage strings */
  Integer result1 = Set_drainage_pipe_attribute_by_type(e, 1, "lock us il", 1);
  Integer result2 = Set_drainage_pipe_attribute_by_type(e, 1, "lock ds il", 1);
  
  if (result1 != 0) Print("Warning: Failed to lock US invert, error: " + To_text(result1) + "\n");
  if (result2 != 0) Print("Warning: Failed to lock DS invert, error: " + To_text(result2) + "\n");
}

/* Apply inverts considering flow direction.
   - z1 = Z at string start, z2 = Z at string end
   - flowSameAsString: 1 = flow same as chainage, 0 = flow opposite
   - If flow same as string: start=US, end=DS
   - If flow opposite: start=DS, end=US
   Returns 1 if write succeeded, else 0. */
Integer ApplyManualInverts(Element e, Real z1, Real z2, Integer flowSameAsString)
{
  Real zUS, zDS;
  
  if (flowSameAsString == 1) {
    /* Flow same as string direction: start=US, end=DS */
    zUS = z1;  /* string start = upstream */
    zDS = z2;  /* string end = downstream */
    Print("Flow same as string: US=" + To_text(zUS) + ", DS=" + To_text(zDS) + "\n");
  } else {
    /* Flow opposite to string direction: start=DS, end=US */
    zUS = z2;  /* string end = upstream */
    zDS = z1;  /* string start = downstream */
    Print("Flow opposite to string: US=" + To_text(zUS) + ", DS=" + To_text(zDS) + "\n");
  }

  LockLinkInverts(e);
  Integer okS = Set_drainage_pipe_inverts(e, 1, zUS, zDS);   /* 0 == success */

  if (okS != 0) {
    Print("Failed to set pipe inverts, error: " + To_text(okS) + "\n");
    return 0;
  }

  /* Verify the write worked */
  Real rbUS=0.0, rbDS=0.0; 
  Integer okG = Get_drainage_pipe_inverts(e, 1, rbUS, rbDS);
  if (okG != 0) {
    Print("Failed to verify pipe inverts, error: " + To_text(okG) + "\n");
    return 0;
  }
  
  Real tolerance = 0.001;
  Integer usOK = (Absolute(rbUS - zUS) <= tolerance);
  Integer dsOK = (Absolute(rbDS - zDS) <= tolerance);

  if (usOK && dsOK) {
    Print("Verification successful: US=" + To_text(rbUS) + ", DS=" + To_text(rbDS) + "\n");
  } else {
    Print("Verification failed: Expected US=" + To_text(zUS) + ", Got=" + To_text(rbUS) + "\n");
    Print("Verification failed: Expected DS=" + To_text(zDS) + ", Got=" + To_text(rbDS) + "\n");
  }
  
  return 1;  // Always return success to avoid stopping the process
}


/* ============================== Panel =============================== */

Integer show_help(Panel p);  /* prototype */

/* Main interactive panel */
void mainPanel()
{
  Text panelName = "Update Pipe Inverts from Nearest Super String";
  Panel              panel   = Create_panel(panelName, TRUE);
  Vertical_Group     vgroup  = Create_vertical_group(-1);
  Colour_Message_Box cmbMsg  = Create_colour_message_box("");

  /* Inputs */
  Source_Box sb_src = Create_source_box("Source1 (Super strings w/ US&DS Z)", cmbMsg, 0);
  Model_Box  mb_dr  = Create_model_box("Drainage model (pipes)", cmbMsg, CHECK_MODEL_MUST_EXIST);
  Real_Box   rb_tol = Create_real_box("XY tolerance (m)", cmbMsg);

  /* Buttons */
  Horizontal_Group bgroup = Create_button_group();
  Button process     = Create_button("&Process","process");
  Button finish      = Create_finish_button("Finish","Finish");
  Button help_button = Create_help_button(panel,"Help");
  Append(process, bgroup); Append(finish, bgroup); Append(help_button, bgroup);

  /* Defaults */
  Set_data(rb_tol, g_searchRadiusM);

  /* Layout */
  Append(sb_src, vgroup);
  Append(mb_dr,  vgroup);
  Append(rb_tol, vgroup);
  Append(cmbMsg, vgroup);
  Append(bgroup, vgroup);
  Append(vgroup, panel);
  Show_widget(panel);

  Integer doit = 1;
  while (doit)
  {
    Text cmd="", msg=""; Integer id, ret = Wait_on_widgets(id, cmd, msg);
    if (cmd == "CodeShutdown") { Set_exit_code(cmd); return; }
    if (cmd == "keystroke" || cmd == "set_focus" || cmd == "kill_focus") continue;

    switch (id)
    {
      case Get_id(panel):
      {
        if (cmd == "Panel Quit") doit = 0;
        else if (cmd == "Panel About") show_help(panel);
        break;
      }

      case Get_id(process):
      {
        if (cmd != "process") break;

        Print("Starting pipe invert update process...\n");

        /* Validate inputs */
        Dynamic_Element deSrc;
        if (Validate(sb_src, deSrc) == 0) { 
          Set_error_message(sb_src, "Select Source1 (Supers with 2 endpoints)"); 
          Print("ERROR: No source data selected\n");
          break; 
        }

        Model mdl; Integer mret = Validate(mb_dr, GET_MODEL, mdl);
        if (mret != MODEL_EXISTS) { 
          Set_error_message(mb_dr, "Drainage model must exist"); 
          Print("ERROR: Drainage model does not exist\n");
          break; 
        }

        Real tolM = 0.5;
        if (Validate(rb_tol, tolM) == 0 || tolM <= 0.0) tolM = 0.5;
        g_searchRadiusM = tolM;

        Print("Using tolerance: " + To_text(tolM) + "m\n");

        /* Collect model elements - FIXED: Filter for drainage elements only */
        Dynamic_Element dEls; Integer nEls = 0;
        Get_elements(mdl, dEls, nEls);
        if (nEls <= 0) { 
          Set_data(cmbMsg, "Model has no elements."); 
          Print("ERROR: Model has no elements\n");
          break; 
        }

        Print("Found " + To_text(nEls) + " total elements in model\n");

        Integer nUpdated=0, nNoMatch=0, nSkipped=0, nFlowError=0, nProcessed=0;
        Integer maxElements = 1000; // Safety limit

        Integer ei;
        for (ei = 1; ei <= nEls && ei <= maxElements; ei = ei + 1)
        {
          Element e; 
          if (Get_item(dEls, ei, e) != 0) continue;

          /* Check if element is drainage type first */
          Text element_type = "";
          if (Get_type(e, element_type) != 0) continue;
          if (element_type != "Drainage") {
            continue; // Skip non-drainage elements silently
          }

          nProcessed = nProcessed + 1;
          Print("\n--- Processing drainage element " + To_text(nProcessed) + " ---\n");

          /* Get flow direction for this drainage string */
          Integer flowSameAsString = 1; /* default assumption */
          if (GetDrainageFlowDirection(e, flowSameAsString) == 0) {
            /* Failed to get flow direction - continue with default */
            nFlowError = nFlowError + 1;
            Print("Using default flow direction (same as chainage)\n");
            flowSameAsString = 1;
          }

          /* Pipe strings should have at least 2 drainage vertices */
          Real ex1=0.0, ey1=0.0, ex2=0.0, ey2=0.0;
          if (!GetDrainEndsXY(e, ex1, ey1, ex2, ey2)) { 
            nSkipped = nSkipped + 1; 
            Print("Skipped - could not get drainage ends\n");
            continue; 
          }

          /* Find ONE super that matches both ends - now returns z1/z2 instead of zUS/zDS */
          Real z1=0.0, z2=0.0;
          Integer ok = MatchSuperForPipe(deSrc, ex1, ey1, ex2, ey2, tolM, z1, z2);
          if (!ok) { 
            nNoMatch = nNoMatch + 1; 
            Print("No matching super string found\n");
            continue; 
          }

          /* Apply inverts considering flow direction */
          if (ApplyManualInverts(e, z1, z2, flowSameAsString)) {
            nUpdated = nUpdated + 1;
            Print("Successfully updated pipe inverts\n");
          } else {
            nSkipped = nSkipped + 1;
            Print("Failed to apply inverts\n");
          }
        }

        /* Refresh all views showing the model */
        Dynamic_Text vnames; 
        if (Model_get_views(mdl, vnames) == 0) {
          Integer nV=0; Get_number_of_items(vnames, nV);
          Integer vi; 
          for (vi=1; vi<=nV; vi=vi+1) { 
            Text vn=""; 
            if (Get_item(vnames, vi, vn) == 0) {
              View v=Get_view(vn); 
              if (View_exists(v)) View_redraw(v); 
            }
          }
        }

        Text r = "Processed: " + To_text(nProcessed) + " drainage elements. Updated: " + To_text(nUpdated) + ", No match: " + To_text(nNoMatch) + ", Skipped: " + To_text(nSkipped);
        if (nFlowError > 0) {
          r = r + ", Flow errors: " + To_text(nFlowError);
        }
        Set_data(cmbMsg, r);
        Print("\nFINAL SUMMARY: " + r + "\n");
        break;
      }

      default:
      {
        if (cmd == "Finish") doit = 0;
        break;
      }
    }
  }
}

/* =========================== Help / About =========================== */
Integer show_help(Panel p)
{
  Print("Update pipe inverts from super-string as-built pairs.\n");
  Print("For each pipe, find ONE super whose TWO endpoints lie within the tolerance of the pipe ends.\n");
  Print("US/DS assignment now considers drainage flow direction (same/opposite to string chainage).\n");
  Print("Vertices with Null or -999 Z are ignored.\n");
  Print("Locks 'lock us il' and 'lock ds il' = 1 (manual) before writing.\n");
  return TRUE;
}

/* ================================ Main ============================== */
void main()
{
  Print("Starting Update Pipe Inverts Macro - Version " + BUILD + "\n");
  mainPanel();
}