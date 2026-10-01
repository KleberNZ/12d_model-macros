# Property_control_creator_panel

## Purpose

Creates property-control strings from lot boundaries and associated Point of Connection (PC) strings.

For each selected lot, the macro identifies the corresponding PC string, offsets the lot boundary inward, determines a split location, and generates two property-control strings that can be used by downstream utility workflows such as Create/Update Property Control and House Connections.

## Location

C:\12d\12dPL_Data\Code\Property_control_creator_panel

## Source

Lot_Connection_Creator.4dm

## Compile Method

Open VS Code from:

C:\12d\12dPL_Data

Then open:

Code\Property_control_creator_panel\Lot_Connection_Creator.4dm

Compile using:

Ctrl+Shift+P > 12dPL: Compile Current File

## Include Setup

```cpp
#include "standard_library.H"
#include "size_of.H"
```

## Category

Drainage

## Type

Property Control Generation

## Author

Kleber Lessa do Prado

## 12d Version

V15

## Current Version

006

## Build

```text
15.0.006
```

## Inputs

### 2D Lot Boundaries

Selected lot polygons must:

- Be closed polygons.
- Pass `Check_polygon()` validation.
- Represent individual lots.

### Point of Connection Strings

Selected PC strings must:

- Start inside the lot.
- Extend outside the lot.
- Be offset from the lot boundary by the nominated offset distance.

### Offset Distance from Boundary

Distance used to offset the lot boundary prior to creating property-control strings.

### Output Model

Model where the property-control strings will be created.

### Drape Polygon Option

Options:

```text
No
Highest TIN z
Lowest TIN z
```

When enabled, an offset polygon is draped to a TIN surface and the split location is determined using the selected elevation criterion.

### TIN for Draping

Required only when a draping option is selected.

## Outputs

Creates:

- Property Control 1
- Property Control 2

Each output:

- Inherits the lot name.
- Is coloured automatically.
- Is placed in the nominated output model.
- Is added to a grouped undo operation.

## Colour Assignment

Property Control 1:

```text
Orange (Colour 8)
```

Property Control 2:

```text
Brown (Colour 15)
```

## Processing Workflow

1. Select lot boundary polygons.
2. Select PC strings.
3. Specify boundary offset distance.
4. Select draping option.
5. Select an output model.
6. Run Process.
7. Validate lot polygons.
8. Create an inward offset polygon.
9. Locate the PC string associated with the lot.
10. Determine the split position.
11. Split the offset polygon.
12. Join each split segment to duplicated PC strings.
13. Reverse final geometry for correct direction.
14. Write property-control strings to the output model.
15. Create a grouped undo record.

## Drape Polygon Behaviour

### No

The split location is based directly on the PC position projected onto the offset polygon.

### Highest TIN Z

The offset polygon is draped to a TIN and the highest vertex is used to locate the split position.

Recommended where:

- Lots drain toward the Point of Connection.

### Lowest TIN Z

The offset polygon is draped to a TIN and the lowest vertex is used to locate the split position.

Recommended where:

- Lots drain away from the Point of Connection.

Version 005 corrected the chainage mapping used by the Lowest TIN Z workflow.

## PC Detection Logic

The macro searches the nominated PC strings and accepts the first candidate that:

- Has at least two vertices.
- Starts inside the lot.
- Contains a vertex outside the lot.

The inside and outside positions are then used to drive polygon splitting.

## Main 12dPL Functions Demonstrated

### Polygon Functions

- `Check_polygon()`
- `XY_inside_polygon()`
- `Plan_area_signed()`
- `Super_offset()`
- `Split_string()`

### Surface Functions

- `Drape()`
- `Tin_Box`

### Super String Functions

- `Get_super_vertex_coord()`
- `Get_points()`
- `String_reverse()`
- `Join_strings()`

### Model Functions

- `Get_model_create()`
- `Model_delete()`
- `Set_model()`

### Logging Functions

- `Create_log_box()`
- `Create_text_log_line()`
- `Create_highlight_string_log_line()`
- `Add_log_line()`

### Undo Functions

- `Add_undo_add()`
- `Add_undo_list()`

## Logging

The log window reports:

- Created Property Control 1 strings.
- Created Property Control 2 strings.
- Missing or invalid PC strings.
- Polygon validation failures.
- Split failures.
- Drape failures.

Created outputs are provided as clickable highlighted strings.

## Undo Support

All created strings are grouped under:

```text
Create Property Controls
```

allowing all generated property controls to be removed with a single Undo operation.

## Notes

- Property-control strings inherit the source lot name.
- Temporary draped geometry is stored in a temporary model and deleted at the end of processing.
- The macro duplicates the source PC string before constructing the final geometry.
- Help and runtime logging were cleaned up in Version 006.

## Limitations

- Requires valid closed lot polygons.
- Requires at least one valid PC string inside each lot.
- Assumes PC strings extend from inside the lot toward the network.
- Uses a single matching PC string per lot.
- Drape logic depends on a valid TIN surface.
- Split behaviour depends on offset polygon quality.

## Keywords

Property control, house connection, lot connection, PC string, lot boundary, subdivision, drainage, drape polygon, TIN, highest elevation, lowest elevation, utility connection, civil design

## Related Macros

- LC_creator_panel
- Create_Catchments_From_LC_panel
- Drainage_Network_Framework

## Revision History

| Version | Date | Notes |
|---|---|---|
| 002 | Added Highest/Lowest TIN Z option. |
| 003 | Added draped-polygon workflow documentation. |
| 004 | Added LC validation after search and duplication. |
| 005 | Corrected Lowest TIN Z split chainage mapping. |
| 006 | Production cleanup, corrected Help-event handling and removed obsolete debug comments. |
