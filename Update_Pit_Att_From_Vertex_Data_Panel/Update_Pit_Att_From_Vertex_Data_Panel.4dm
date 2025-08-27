/*---------------------------------------------------------------------
**   Programmer: Kleber Lessa do Prado (revised)
**   Date:       22/08/25
**   12D Model:  V15
**   Version:    001
**   Macro:      Update_Pit_Att_From_Vertex_Data_Panel.4dm
**   Type:       SOURCE
**
**   Brief: Update Pit Sump Level from Nearest Vertex (locks to MANUAL first)
---------------------------------------------------------------------*/

/*---------------------------------------------------------------------
**   Description: Description
** Updates pit sump levels in a selected drainage model from the nearest
** input vertex Z (planar nearest within user radius). For each pit:
**   1) Lock sump to MANUAL (non-floating), then
**   2) Set sump level = nearest vertex Z, and verify (±1 mm),
**   3) Refresh views once after processing.
**
** Required setup / caveat (IMPORTANT)
** - In your drainage style file (drainage.4d), the "Sump RL mode" must be
**   BLANK/UNSET (not "Floating"/"Auto"). If it’s set to floating, the DNE
**   can re-float the sump after the macro runs. Leaving it blank allows
**   the macro’s Set_drainage_pit_float_sump(...,0) to persist the MANUAL lock.
**
** Usage
** - Source: select the vertex source (strings/points with XYZ).
** - Drainage model: select the model containing pits to update.
** - Radius (m): search radius in plan (default 0.5 m = 1.0 m diameter).
**
** Behaviour
** - Pits with no vertex found within radius are left unchanged.
** - Counts of updated/failed pits are reported; tolerance is 0.001 m.
** - Linear nearest search; for large datasets consider tighter radius.
**
** Notes
** - Macro changes pit attributes only; no topology edits.
** - Best practice: snapshot the model before batch updates.
---------------------------------------------------------------------*/

#define DEBUG_FILE      0
#define ECHO_DEBUG_FILE 0
#define ECHO_LINE_NO    0
#define BUILD "15.0.001"

// ----------------------------- INCLUDES -----------------------------
#include "..\\..\\include\\standard_library.H"
#include "..\\..\\include\\size_of.H"

/* ============================== Globals ============================= */
/*global variables*/{
  Real g_searchRadiusM = 0.5;  /* default 1.0 m diameter */
}

/* ============================== Helpers ============================= */
/* Lock (manual) then set pit sump level; return 1 on success (±1 mm) */
Integer ApplyManualSumpLevel(Element e, Integer pitIdx, Real zSump)
{
  Set_drainage_pit_float_sump(e, pitIdx, 0);           /* 0 = manual (non-floating) */
  Set_drainage_pit_sump_level(e, pitIdx, zSump);       /* set value */

  Real zBack = 0.0;
  Get_drainage_pit_sump_level(e, pitIdx, zBack);       /* read-back */
  if (Absolute(zBack - zSump) <= 0.001) return 1;
  return 0;
}

/* Redraw all views the model is on (call once after processing) */
void RefreshModelViews(Model mdl)
{
  Dynamic_Text vnames;
  Model_get_views(mdl, vnames);
  Integer nV = 0; Get_number_of_items(vnames, nV);
  Integer i;
  for (i = 1; i <= nV; i = i + 1) {
    Text vn = ""; Get_item(vnames, i, vn);
    View v = Get_view(vn);
    if (View_exists(v)) View_redraw(v);
  }
}

/* Build a cache of vertex XYZs from a Source_Box of vertex selections. */
Integer BuildVertexCache(Dynamic_Element &srcElems,
                         Dynamic_Real &vx, Dynamic_Real &vy, Dynamic_Real &vz)
{
  Integer i, nE = 0; Get_number_of_items(srcElems, nE);
  Integer nAdded = 0;

  for (i = 1; i <= nE; i = i + 1) {
    Element e; Get_item(srcElems, i, e);

    Integer npts = 0;
    Get_points(e, npts);
    if (npts <= 0) continue;

    Integer v;
    for (v = 1; v <= npts; v = v + 1) {
      Real x=0.0, y=0.0, z=0.0;
      Integer ok = Get_super_vertex_coord(e, v, x, y, z);
        /* 0 == success in 12dPL getters */
            if (ok == 0) {
                nAdded = nAdded + 1;
                Set_item(vx, nAdded, x);
                Set_item(vy, nAdded, y);
                Set_item(vz, nAdded, z);
        }

    }
  }
  return nAdded;
}

/* Find nearest vertex within radius; returns 1 if found, outputs bestZ */
Integer FindNearestZ(Dynamic_Real &vx, Dynamic_Real &vy, Dynamic_Real &vz,
                     Real px, Real py, Real radius_m, Real &bestZ)
{
  Integer nV = 0; Get_number_of_items(vx, nV);
  if (nV <= 0) return 0;

  Real r2 = radius_m * radius_m;
  Real bestD2 = 1.0E30;
  Integer i;
  for (i = 1; i <= nV; i = i + 1) {
    Real x=0.0, y=0.0, z=0.0;
    Get_item(vx, i, x);
    Get_item(vy, i, y);
    Get_item(vz, i, z);
    Real dx = x - px, dy = y - py;
    Real d2 = dx*dx + dy*dy;
    if (d2 <= r2 && d2 < bestD2) { bestD2 = d2; bestZ = z; }
  }
  if (bestD2 < 1.0E29) return 1;
  return 0;
}

/* ============================ Prototypes ============================ */
void about_panel(Panel p);

/* ============================ Main Panel ============================ */
void mainPanel(){
  Text panelName = "Update Pit Sump level from Nearest Vertex";
  Panel              panel  = Create_panel(panelName, TRUE);
  Vertical_Group     vgroup = Create_vertical_group(-1);
  Colour_Message_Box cmbMsg = Create_colour_message_box("");

  /* INPUTS */
  Source_Box sb_pts = Create_source_box("of vertex", cmbMsg, 0);
  Model_Box  mb_drainage = Create_model_box("Drainage Model to be Updated", cmbMsg, CHECK_MODEL_MUST_EXIST);
  Real_Box   rb_radius   = Create_real_box("Search radius (m)", cmbMsg);

  /* BUTTONS */
  Horizontal_Group bgroup = Create_button_group();
  Button process     = Create_button("&Process","process");
  Button finish      = Create_finish_button("Finish","Finish");
  Button help_button = Create_help_button(panel,"Help");
  Append(process, bgroup); Append(finish, bgroup); Append(help_button, bgroup);

  /* DEFAULTS */
  Set_data(rb_radius, g_searchRadiusM);

  /* LAYOUT */
  Append(sb_pts, vgroup);
  Append(mb_drainage, vgroup);
  Append(rb_radius, vgroup);
  Append(cmbMsg, vgroup);
  Append(bgroup, vgroup);
  Append(vgroup, panel);
  Show_widget(panel);

  Integer doit = 1;
  while(doit){
    Text cmd="", msg=""; Integer id, ret = Wait_on_widgets(id,cmd,msg);
    if(cmd=="CodeShutdown"){ Set_exit_code(cmd); return; }
    if(cmd=="keystroke" || cmd=="set_focus" || cmd=="kill_focus") continue;

switch (id)
{
  /* ---------------------------------------------------------- */
  case Get_id(panel) :
  {
    if (cmd == "Panel Quit") { doit = 0; }
    else if (cmd == "Panel About") { about_panel(panel); }
    break;
  }

  /* ---------------------------------------------------------- */
  case Get_id(process) :
  {
    if (cmd == "process")
    {
      /* -------- READ + VALIDATE -------- */
      Dynamic_Element dePts;
      if (Validate(sb_pts, dePts) == 0)
      {
        Set_error_message(sb_pts, "Pick a source with vertices");
        break;
      }

      Model mdlDrain; Integer mret = Validate(mb_drainage, GET_MODEL, mdlDrain);
      if (mret != MODEL_EXISTS)
      {
        Set_error_message(mb_drainage, "Drainage model must exist");
        break;
      }

      Real radM = 0.5;
      if (Validate(rb_radius, radM) == 0 || radM <= 0.0) radM = 0.5;
      g_searchRadiusM = radM;

      /* -------- GET DRAINAGE ELEMENTS -------- */
      Dynamic_Element dEls; Integer nEls = 0;
      Get_elements(mdlDrain, dEls, nEls);
      if (nEls <= 0) { Set_data(cmbMsg, "No elements in drainage model"); break; }

      /* -------- BUILD VERTEX CACHE -------- */
      Dynamic_Real vx, vy, vz;
      Integer nVert = BuildVertexCache(dePts, vx, vy, vz);
      if (nVert <= 0) { Set_data(cmbMsg, "Source has no vertices"); break; }

      /* -------- PROCESS: LOOP PITS -------- */
      Integer nUpdated = 0, nFailed = 0;
      Integer eix;
      for (eix = 1; eix <= nEls; eix = eix + 1)
      {
        Element curEl; Get_item(dEls, eix, curEl);

        Integer nPits = 0; Get_drainage_pits(curEl, nPits);
        if (nPits <= 0) continue;

        Integer pitIdx;
        for (pitIdx = 1; pitIdx <= nPits; pitIdx = pitIdx + 1)
        {
          Real px = 0.0, py = 0.0, pz = 0.0;
          Get_drainage_pit(curEl, pitIdx, px, py, pz);

          Real bestZ = 0.0;
          if (!FindNearestZ(vx, vy, vz, px, py, radM, bestZ)) continue;

          if (ApplyManualSumpLevel(curEl, pitIdx, bestZ)) nUpdated = nUpdated + 1;
          else nFailed = nFailed + 1;
        }
      }

      /* -------- REFRESH + REPORT -------- */
      RefreshModelViews(mdlDrain);
      Text r = "SUCCESS: Updated " + To_text(nUpdated) + " pit sump levels";
      if (nFailed > 0) r = r + " (" + To_text(nFailed) + " failed)";
      Set_data(cmbMsg, r);
    }
    break;
  }

  /* ---------------------------------------------------------- */
  default :
  {
    if (cmd == "Finish") { doit = 0; }
    break;
  }
}            /* end switch */
}            /* end while(doit) */
}           /* end mainPanel() */
/* =========================== Main ========================== */
void main()
{
  mainPanel();
}