## Create_mini_roundabout_SA_panel

### Purpose

Creates a mini-roundabout kerb return Super Alignment (SA) between two
selected centreline strings using computator parts.

The macro generates the horizontal and vertical geometry required for a
typical mini-roundabout kerb return by combining approach and departure
tangent lines, floating transition arcs and a central radius arc.

### Location

C:\12d\12dPL_Data\Code\Create_mini_roundabout_SA_panel

### Source

Create_mini_roundabout_SA_panel.4dm

### Compile Method

Open VS Code from:
C:\12d\12dPL_Data

Then open:
Code\Create_mini_roundabout_SA_panel\Create_mini_roundabout_SA_panel.4dm

Compile using:
Ctrl+Shift+P > 12dPL: Compile Current File

Do not use F7 unless the old task system has been deliberately updated.

### Include Setup

This macro uses clean includes:

#include "standard_library.H"
#include "size_of.h"

These rely on the central workspace setting:

12dpl.compiler.includePaths = C:\12d\includes

### Inputs

- Approach centreline string (selected with direction)
- Departure centreline string (selected with direction)
- Approach lane width
- Departure lane width
- Tangent point offset
- Radius
- Floating arc length
- Output model
- Output Super Alignment name

### Outputs

Creates a Super Alignment containing:

- Approach tangent section
- Floating entry arc
- Constant radius central arc
- Floating exit arc
- Departure tangent section
- Vertical geometry tied to the selected approach and departure strings

The completed Super Alignment is added to the nominated output model.

### Notes

- Tangent point offset controls the distance from the approach/departure
  string intersection to the kerb-return tangent points.

- Horizontal geometry is generated entirely from computator parts.

- Vertical geometry uses:
  - 3% tie-in from the approach string
  - Free parabola compound transition
  - 3% tie-in to the departure string

- String directions selected by the user are used to determine the
  correct offset and extension signs.

- The macro automatically increments the suggested output name when a
  trailing numerical counter is present.

### Revision History

<table>
<tr>
<th>
Version
</th>
<th>
Date
</th>
<th>
Notes
</th>
</tr>
<tr>
<td>
001
</td>
<td>
2026-08-17
</td>
<td>
Initial mini-roundabout kerb return SA macro
</td>
</tr>
</table>