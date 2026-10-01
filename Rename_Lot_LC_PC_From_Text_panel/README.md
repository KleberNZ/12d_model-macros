# Rename_Lot_LC_PC_From_Text_panel

## Purpose

Renames allotment polygons and optional Lot Connection (LC) and Property Control (PC) Super strings using the lot-number Text element located inside each selected allotment polygon.

The macro provides consistent names across cadastral lots and related utility strings while supporting a configurable polygon naming template and grouped undo.

## Location

C:\12d\12dPL_Data\Code\Rename_Lot_LC_PC_From_Text_panel

## Source

Rename_Supers_From_Lot_Text.4dm

## Compile Method

Open VS Code from:

C:\12d\12dPL_Data

Then open:

Code\Rename_Lot_LC_PC_From_Text_panel\Rename_Supers_From_Lot_Text.4dm

Compile using:

Ctrl+Shift+P > 12dPL: Compile Current File

## Include Setup

```cpp
#include "standard_library.h"
#include "size_of.h"
```

## Category

Utilities

## Type

Lot, Lot Connection and Property Control Naming Utility

## Author

Kleber Lessa do Prado

## 12d Version

V15

## Current Version

003

## Build

```text
15.0.004
```

Note: The source header identifies Version 003, while the build definition is `15.0.004`.

## Inputs

### Allotment Polygons

Select the allotment polygons to rename.

Each processed allotment must be:

- A Super string
- Closed
- At least three vertices
- No more than 10,000 vertices

### Lot-Number Text Model

Required model containing the lot-number Text elements.

For a polygon to be processed, exactly one valid, non-empty Text element must be located inside the polygon.

### Lot Connection Model

Optional model containing LC Super strings.

Leave the model field blank to skip LC renaming.

### Property Control Model

Optional model containing PC Super strings.

Leave the model field blank to skip PC renaming.

### Polygon Prefix or Template

Defines how allotment polygons are named.

Default:

```text
Lot 
```

Use an asterisk to separate a prefix and suffix around the lot text.

Examples:

```text
Lot 
```

with lot text `125` produces:

```text
Lot 125
```

Template:

```text
Lot * DP12345
```

with lot text `125` produces:

```text
Lot 125 DP12345
```

If the template contains no asterisk, the complete template is treated as a prefix.

## Outputs

### Allotment Polygon Name

```text
<Template Prefix><Lot Text><Template Suffix>
```

### Lot Connection Name

```text
<Lot Text> LC
```

### Property Control Name

```text
<Lot Text> PC
```

## Matching Logic

### Lot Text Matching

The insertion point of each valid Text element is tested against each allotment polygon using an internal XY ray-crossing point-in-polygon routine.

A polygon is processed only when exactly one lot-number Text element is inside it.

### LC and PC Matching

LC and PC strings are matched using their first vertex only.

A candidate is renamed when:

- The candidate is a Super string.
- The candidate has at least one vertex.
- Its first vertex lies inside the allotment polygon.

The remaining portion of the LC or PC string may extend outside the polygon.

## Skip Conditions

The allotment and its related LC and PC strings are skipped when:

- No lot-number Text element is inside the polygon.
- More than one lot-number Text element is inside the polygon.
- The allotment is not a closed Super string.
- The allotment exceeds the supported point count.
- The polygon or related string geometry cannot be read.

## Workflow

1. Select the allotment polygons.
2. Select the required lot-number Text model.
3. Optionally select the LC model.
4. Optionally select the PC model.
5. Enter the polygon prefix or template.
6. Select **Process**.
7. The macro retrieves Text, LC and PC elements from the selected models.
8. Each allotment polygon is validated.
9. Text insertion points inside the polygon are counted.
10. Polygons with exactly one matching Text element are renamed.
11. LC and PC Super strings whose first vertex is inside the polygon are renamed.
12. All successful changes are grouped into one undo operation.
13. A processing summary is displayed.

## Main 12dPL Functions Demonstrated

### Text Processing

- `Get_text_data()`
- `Find_text()`
- `Text_length()`
- `Get_subtext()`

### Polygon and Super-String Processing

- `Get_type()`
- `String_closed()`
- `Get_points()`
- `Get_super_vertex_coord()`
- Internal XY point-in-polygon calculation

### Model and Selection Functions

- `Create_source_box()`
- `Create_model_box()`
- `Validate()`
- `Get_elements()`
- `Get_item()`
- `Get_number_of_items()`

### Naming and Undo Functions

- `Element_duplicate()`
- `Set_name()`
- `Add_undo_change()`
- `Add_undo_list()`

## Undo Support

All successful changes are grouped under:

```text
Rename allotments, lot connections and property controls
```

The macro creates changed-element undo records using copies of the original elements.

## Reporting

The completion message reports:

- Lots renamed
- LC strings renamed
- PC strings renamed
- Polygons with no matching Text
- Polygons with multiple matching Text elements
- Invalid or open allotments
- Invalid LC elements
- Invalid PC elements
- Rename errors

## Notes

- The lot-number Text model is mandatory.
- LC and PC models are independently optional.
- The Text contents are used exactly as stored, without numeric conversion or added zero-padding.
- Multiple LC or PC strings can be renamed for one allotment if their first vertices lie inside that polygon.
- Existing names are overwritten.

## Limitations

- Each processed allotment must contain exactly one valid Text insertion point.
- Text on a polygon boundary can be sensitive to the internal ray-crossing test.
- LC and PC association is based only on the first vertex.
- Maximum supported allotment size is 10,000 vertices.
- Duplicate output names are not checked.
- The script does not trim or normalise the lot Text contents.
- If allotment polygons overlap, an LC or PC first vertex may satisfy more than one selected polygon and be renamed more than once during the same run.

## Keywords

12d Model, 12dPL, rename lots, allotment polygons, lot-number text, cadastral naming, lot connection, LC, property control, PC, Super string, point in polygon, naming template, prefix, suffix, subdivision design, grouped undo

## Related Macros

- Rename_elements_panel
- LC_creator_panel
- Property_control_creator_panel
- Create_Catchments_From_LC_panel

## Revision History

| Version | Date | Notes |
|---|---|---|
| 003 | 21/09/2026 | Source-header version. Renames allotment polygons and optional LC/PC strings from the unique lot-number Text element inside each polygon. |
| Build 15.0.004 | Not stated | Current build identifier in the supplied source. |
