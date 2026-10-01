# Create_Catchments_From_LC_panel

## Purpose

Creates drainage catchment polygons from lot connection topology.

The macro generates Rational Method style catchments by tracing lot connections to the upstream pit of each drainage pipe, identifying the contributing lot polygons, and creating catchment boundaries from the connected lots.

Unlike TIN-based catchment generation, this workflow derives catchments from cadastral lot layout and drainage lot connection relationships.

## Location

C:\12d\12dPL_Data\Code\Create_Catchments_From_LC_panel

## Source

Create_Catchments_From_LC_panel.4dm

## Compile Method

Open VS Code from:

C:\12d\12dPL_Data

Then open:

Code\Create_Catchments_From_LC_panel\Create_Catchments_From_LC_panel.4dm

Compile using:

Ctrl+Shift+P > 12dPL: Compile Current File

## Include Setup

```cpp
#include "standard_library.h"
#include "size_of.h"
#include "set_ups.h"
```

## Category

Drainage

## Type

Catchment Generation

## Author

Kleber Lessa do Prado

## 12d Version

V15

## Current Version

012

## Purpose

Automatically creates upstream-pit catchment polygons from:

- Drainage pipes
- Lot connection strings
- Lot boundary polygons

Catchments are named from the upstream pit and written to an output model.

## Inputs

### Drainage Strings

Selected drainage strings containing the stormwater network.

### Lot Connection Model

Model containing lot connection strings.

Requirements:

- Super strings
- Exactly two vertices
- Vertex 1 located inside a lot
- Vertex 2 connected to the pipe or upstream pit

### Lot Boundary Model

Model containing cadastral lot polygons.

Requirements:

- Closed Super strings
- Valid polygon geometry
- No self intersections
- No holes

### Hole Polygon Model (Optional)

Optional model containing explicit hole polygons.

Used only when disconnected catchment components need to be merged into a single shell.

### Output Model

Destination model for generated catchments.

### Pipe/Pit Connection Tolerance

Used when testing if a lot connection attaches to a pipe or pit.

Default:

```text
0.01 m
```

## Outputs

Creates:

- Catchment polygons
- Dissolved lot polygons
- Catchment hole geometry (when supplied)

Each catchment:

- Is named from the upstream pit.
- Is drawn into the output model.
- Has an undo record created.

Examples:

```text
MH01
MH01_2
MH01_3
```

## Workflow

For each drainage pipe:

1. Determine pipe flow direction.
2. Find upstream pit.
3. Identify connected lot connections.
4. Find containing lot polygons.
5. Remove duplicate lots.
6. Build contributing lot list.
7. Dissolve connected lots.
8. Optionally apply explicit hole polygons.
9. Reorder polygon vertices so vertex 1 is nearest the upstream pit.
10. Name the catchment.
11. Create the catchment in the output model.

## Dissolve Logic

When multiple lots contribute:

- Shared edges are detected.
- Duplicate boundaries are cancelled.
- Remaining exterior boundaries are reconstructed.
- Connected components are identified.
- Separate shells are created when required.

Version 1 supports:

- Shared line segments
- Shared arc segments
- Connected cadastral lots

## Explicit Hole Support

Optional hole polygons can be supplied.

The macro:

- Detects hole polygons sharing boundaries with multiple catchment components.
- Uses those polygons to bridge disconnected dissolved components.
- Creates a single shell with explicit holes.

Hole geometry is never inferred.

## Main 12dPL Functions Demonstrated

### Drainage Functions

- Get_drainage_flow()
- Get_drainage_pits()
- Get_drainage_pit()
- Get_drainage_pit_name()
- Get_drainage_pit_attribute()

### Polygon Functions

- XY_inside_polygon()
- String_closed()
- String_close()
- String_self_intersects()

### Super Functions

- Get_super_data()
- Set_super_data()
- Create_super()
- Super_add_hole()
- Super_get_hole()

### Geometry Functions

- Get_segment()
- Get_start()
- Get_end()
- Point_distance_2d()

### Undo Functions

- Add_undo_add()
- Add_undo_list()

## Naming Convention

Catchments are named from the upstream pit.

Examples:

```text
CP10
CP10_2
CP10_3
```

where suffixes indicate disconnected dissolved components.

## Notes

- Intended for land development and subdivision drainage design.
- Supports Rational Method workflows.
- Uses drainage topology rather than surface flow paths.
- Source lots are never modified.
- Drainage strings are never modified.
- Catchment polygons are rebuilt and reordered so the first vertex is nearest the upstream pit.

## Limitations

- Not a TIN catchment generation tool.
- Curved drainage pipes are not evaluated.
- Lot connections must contain exactly two vertices.
- Vertex 1 must be located inside one and only one lot.
- Hole geometry must be supplied explicitly.
- Polygon overlap and general Boolean operations are not supported.
- Adjacent or ambiguous hole polygons are not supported.
- Shared boundaries must match within tolerance.

## Keywords

Catchments, Rational Method, lot connections, LC, drainage, cadastral lots, stormwater, catchment generation, dissolved polygons, upstream pit, subdivision design, drainage topology

## Related Macros

- Set_Direct_Lot_Connection_Count_To_Upstream_Pit_Area
- Create_Catchments_From_Lot_Connections
- Polygon_Topology_Builder
- Drainage_Updater

## Revision History

| Version | Date | Notes |
|---|---|---|
| 012 | 23/09/2026 | Profiling build. Creates catchments from lot connections, supports multi-lot dissolve workflows, explicit hole polygons and upstream-pit based naming. |
