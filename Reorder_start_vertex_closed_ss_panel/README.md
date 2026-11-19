# Reorder_start_vertex_closed_ss_panel

## Purpose

Creates a reordered copy of a closed Super string so the vertex nearest the selected point becomes the start vertex. The existing vertex direction is retained.

## Location

C:\12d\12dPL_Data\Code\Reorder_start_vertex_closed_ss_panel

## Source

Reorder_start_vertex_closed_ss_panel.4dm

## Compile Method

Open VS Code from:

C:\12d\12dPL_Data

Then open:

Code\Reorder_start_vertex_closed_ss_panel\Reorder_start_vertex_closed_ss_panel.4dm

Compile using:

Ctrl+Shift+P > 12dPL: Compile Current File

Do not use F7 unless the old task system has been deliberately updated.

## Include Setup

The source includes:

#include "standard_library.h"
#include "size_of.h"
#include "set_ups.h"

These rely on the central workspace setting:

12dpl.compiler.includePaths = C:\12d\includes

## Inputs

Select a closed Super string near the vertex that should become its start. Use the Target box to choose copy or move and to select the original model, one destination model, or a destination model per source model. Enter a target model name or prefix when the selected target mode requires one.

## Outputs

Creates the reordered string in the model selected by the Target box. In move modes, the source string is removed after the reordered output is created successfully.

## Notes

The macro is intended for 12d Model V15. The selected point is matched to the nearest stored vertex in plan, and the string's vertex order is rotated without reversing its direction. The macro uses the central includes resolved through `12dpl.compiler.includePaths = C:\12d\includes`.

## Revision History

| Version | Date | Notes |
|---|---|---|
| 001 | 2026-10-07 | Initial macro |
| 002 | 2026-11-20 | Corrected macro name, paths, include list, and usage documentation |
