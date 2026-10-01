# LC_creator_panel

## Purpose

Creates one 2D lot-connection Super string for each selected lot boundary by finding the nearest eligible drainage pipe segment.

The macro offsets each lot boundary inward, evaluates perpendicular projections from the offset polygon vertices to the selected drainage segments, and creates a two-vertex lot connection named from the source lot. Existing lot connections with the same name are skipped.

## Location

C:\12d\12dPL_Data\Code\LC_creator_panel

## Source

LC_creator_panel.4dm

## Compile Method

Open VS Code from:

C:\12d\12dPL_Data

Then open:

Code\LC_creator_panel\LC_creator_panel.4dm

Compile using:

Ctrl+Shift+P > 12dPL: Compile Current File

## Include Setup

```cpp
#include "standard_library.H"
#include "size_of.H"
#include "set_ups.H"
```

## Category

Drainage

## Type

Lot Connection Generation

## Author

Kleber Lessa do Prado

## 12d Version

V15

## Current Version

001

## Build

```text
15.0.001
```

## Inputs

### Drainage Strings

Select one or more drainage strings containing the pipes to which lot connections may attach.

Non-drainage elements are skipped.

### Lot Boundaries

Select the lot boundary polygons requiring lot connections.

Each lot is checked with `Check_polygon()` before processing.

### Offset from Boundary

Defines the inward offset applied to each lot boundary before searching for a connection point.

Default:

```text
1.0 m
```

### Search Distance

Maximum perpendicular distance between an offset-lot vertex and a drainage segment for the vertex to be considered a valid candidate.

Default:

```text
5.0 m
```

### Lot Connection Model

Select or create the output model for the lot-connection strings.

## Outputs

Creates two-vertex 2D Super strings in the selected output model.

Each connection:

- Starts at a vertex of the inward-offset lot polygon.
- Ends at the projected point on the selected drainage pipe segment.
- Uses an XY-only level of 0.0 at both vertices.
- Uses the colour of the associated drainage string.
- Is included in the grouped undo action.

## Naming Convention

The generated connection name is:

```text
<Lot Name>-PC
```

Example:

```text
Lot 125-PC
```

Before creating a connection, the macro searches the output model for an exact matching name. If a matching element exists, another connection is not created for that lot.

## Candidate Selection Logic

For each valid lot and drainage segment:

1. The lot boundary is offset inward.
2. Every vertex of the offset polygon is projected onto the drainage segment in XY.
3. Candidates beyond the search distance are rejected.
4. Remaining candidates are ranked using drainage flow direction and distance along the segment.
5. The candidate closest to the relevant downstream reference is preferred.
6. Perpendicular distance is used as a tie-breaker.
7. A two-point Super string is created from the selected lot point to the projected pipe point.

## Drainage Flow Handling

The macro reads the drainage string flow direction using:

```cpp
Get_drainage_flow()
```

The projection parameter is converted to a distance metric along the pipe so candidate selection can account for the drainage flow direction.

## Lot Offset Handling

The macro initially offsets each lot by the entered distance. It then tests a midpoint between the original and offset first vertices against the original polygon.

If the test indicates that the offset is outward, the macro rebuilds the offset using the opposite sign.

All temporary offset polygons are stored in:

```text
TEMP OFFSET MODEL TO BE DELETED
```

The temporary model is deleted after processing.

## Workflow

1. Select the drainage strings.
2. Select the lot boundaries.
3. Enter the inward boundary offset.
4. Enter the drainage search distance.
5. Select or create the output model.
6. Select **Process**.
7. The macro validates the inputs.
8. Valid lot polygons are offset inward and stored temporarily.
9. Each drainage segment is evaluated against each offset lot.
10. The best eligible perpendicular connection is selected.
11. Existing `<Lot Name>-PC` elements are skipped.
12. New 2D lot connections are created and coloured.
13. The temporary offset model is deleted.
14. All created connections are added to one grouped undo action.

## Main 12dPL Functions Demonstrated

### Lot and Polygon Functions

- `Check_polygon()`
- `Super_offset()`
- `XY_inside_polygon()`
- `Get_super_vertex_coord()`

### Drainage Functions

- `Get_drainage_flow()`
- `Get_drainage_pipe_attribute()`
- `Get_drainage_pipe_inverts()`
- `Get_segment()`

### Geometry Functions

- `Get_start()`
- `Get_end()`
- `Get_x()`
- `Get_y()`
- `Sqrt()`

### Super-String Functions

- `Create_super()`
- `Set_super_vertex_coord()`
- `Set_super_use_2d_level()`
- `Set_name()`
- `Set_model()`
- `Set_colour()`
- `Calc_extent()`

### Search and Model Functions

- `Find_element()`
- `Get_model_create()`
- `Model_delete()`
- `Get_elements()`

### Undo Functions

- `Add_undo_add()`
- `Add_undo_list()`

## Reporting

The 12d Output Window reports information including:

- Input validation outcome
- Number of selected lot boundaries
- Invalid lot polygons
- Non-drainage selections
- Total lot connections created
- No-connections-created result

## Undo Support

Created lot connections are grouped under:

```text
Create Lot Connections
```

## Notes

- Source lot boundaries and drainage strings are not modified.
- Drainage pipe invert levels are interpolated during candidate evaluation, but the calculated invert is not assigned to the 2D lot connection.
- Connections are added to the output model immediately so later checks can detect duplicate names.
- The source grants unrestricted reproduction, modification, compilation and reuse.

## Limitations

- Creates one lot connection per unique `<Lot Name>-PC` output name.
- Candidate points are taken from vertices of the inward-offset polygon rather than continuously along the offset boundary.
- The selected drainage segment must lie within the nominated search distance of an offset vertex.
- Output geometry is 2D with Z set to 0.0.
- Exact output-name matching is used for duplicate prevention.
- The source contains assignment-style flow-direction conditions (`if (flow_dir = 1)`) that should be reviewed before modifying the flow-direction logic.
- The temporary model uses a fixed project-wide name.

## Keywords

12d Model, 12dPL, lot connection, LC, property connection, drainage, stormwater, wastewater, lot boundary, cadastral polygon, inward offset, nearest pipe, perpendicular projection, drainage flow direction, subdivision design, two-point Super string

## Related Macros

- Create_Catchments_From_LC_panel
- Set_Direct_Lot_Connection_Count_To_Upstream_Pit_Area
- Drainage_Network_Framework

## Revision History

| Version | Date | Notes |
|---|---|---|
| 001 | 04/11/2025 | Initial version. Creates one named 2D lot connection per selected lot using inward offsets, drainage-segment projection, duplicate-name checks and grouped undo. |
