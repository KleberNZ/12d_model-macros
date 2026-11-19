# parallel_many_strings_panel

## Purpose

Creates parallel or Super Offset results for multiple selected elements. Super Offset provides Join, Intersect, Fillet, Dual, and Clip corner modes. Results can be copied or moved to models selected with the Target box.

## Location

C:\12d\12dPL_Data\Code\parallel_many_strings_panel

## Source

parallel_many_strings_panel.4dm

## Compile Method

Open VS Code from:

C:\12d\12dPL_Data

Then open:

Code\parallel_many_strings_panel\parallel_many_strings_panel.4dm

Compile using:

Ctrl+Shift+P > 12dPL: Compile Current File

Do not use F7 unless the old task system has been deliberately updated.

## Include Setup

The source includes:

#include "set_ups.h"
#include "standard_library.h"
#include "parallel_many_strings-externals.h"

These rely on the central workspace setting:

12dpl.compiler.includePaths = C:\12d\includes

## Inputs

Choose source elements with the Source box. Set the method (Parallel or Super Offset), horizontal distance, optional Z translation, and optional number of iterations. Super Offset also uses the selected corner mode: Join, Intersect, Fillet, Dual, or Clip. Use the Target box to choose copy or move and the destination model or models. A command-line entry point is also provided for a source model, horizontal offset, target model, and optional offset mode, vertical shift, and iteration count.

## Outputs

Creates offset result elements in the target model or models. Move modes remove source elements as part of the move workflow; copy modes retain the sources. The panel reports processing messages and logs per-element results.

## Notes

The macro is intended for 12d Model V15. The horizontal distance is multiplied by each iteration number. A positive Z translation moves results upward and a negative value moves them downward. Super Offset is intended for Super strings; the Parallel method remains available for other supported element types. The macro depends on `parallel_many_strings-externals.h` in the central include directory, alongside the headers listed above. These headers are resolved through `12dpl.compiler.includePaths = C:\12d\includes`.

## Revision History

| Version | Date | Notes |
|---|---|---|
| 001 | 2026-10-08 | Initial macro |
| 002 | 2026-11-20 | Removed TODOs and aligned usage and include documentation with the source |
