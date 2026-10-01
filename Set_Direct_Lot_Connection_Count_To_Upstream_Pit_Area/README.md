# Set_Direct_Lot_Connection_Count_To_Upstream_Pit_Area

## Purpose

Counts direct lot connections attached to each drainage pipe and writes the resulting count to the upstream pit Real attribute `area`.

The macro is intended for wastewater flow-estimation workflows where the number of directly connected lots is stored against the upstream pit and subsequently used in flow calculations.

## Location

C:
d
dPL_Data\Code\Set_Direct_Lot_Connection_Count_To_Upstream_Pit_Area

## Source

Set_Direct_Lot_Connection_Count_To_Upstream_Pit_Area.4dm

## Compile Method

Open VS Code from:

C:
d
dPL_Data

Then open:

Code\Set_Direct_Lot_Connection_Count_To_Upstream_Pit_Area\Set_Direct_Lot_Connection_Count_To_Upstream_Pit_Area.4dm

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

Wastewater Flow Estimation Utility

## Author

Kleber Lessa do Prado

## 12d Version

V15

## Current Version

001

## Build

```text
15.0.002
```

## Purpose

Stores:

```text
area = number of direct lot connections
```

on the upstream pit of every drainage pipe.

The resulting area value can be used in downstream wastewater flow calculations.

Example:

```text
Q = Lots × 0.000041875 m³/s
```

where:

```text
Lots = area attribute value
```

## Inputs

### Drainage Strings

Select one or more drainage strings.

### Lot Connection Model

Model containing lot connection strings.

Valid lot connections must be:

- Super strings
- Exactly two vertices
- Vertex 1 located inside a lot
- Vertex 2 located at the drainage attachment point

### Intersection Tolerance

Used when testing whether a lot connection endpoint intersects:

- An upstream pit
- A drainage pipe

Default:

```text
0.01 m
```

## Outputs

Updates the Real attribute:

```text
area
```

on upstream drainage pits.

The value written is:

```text
number of direct lot connections
```

If no lot connections are found:

```text
area = 0
```

## Counting Rules

A lot connection is counted when Vertex 2:

### Rule 1

Intersects the upstream pit of the current pipe.

### Rule 2

Intersects the pipe itself.

### Rule 3

Does not coincide with the downstream pit.

Connections located at the downstream pit are deliberately excluded to prevent double-counting.

They will instead be counted when that node becomes the upstream pit of the downstream pipe.

## Workflow

1. Select drainage strings.
2. Select the lot connection model.
3. Enter the intersection tolerance.
4. Select Process.
5. The lot connection model is read.
6. Each drainage string is processed.
7. Flow direction is determined.
8. Each pipe is evaluated independently.
9. Valid lot connections are counted.
10. The upstream pit area attribute is updated.
11. A completion summary is displayed.

## Drainage Flow Logic

For each pipe:

```text
Upstream Pit
↓
Pipe
↓
Downstream Pit
```

The upstream and downstream pit assignments are based on:

```cpp
Get_drainage_flow()
```

ensuring the count is always written to the hydraulic upstream node.

## Main 12dPL Functions Demonstrated

### Drainage Functions

- `Get_drainage_flow()`
- `Get_drainage_pits()`
- `Get_drainage_pit()`
- `Get_drainage_pit_name()`
- `Set_drainage_pit_attribute_by_type()`

### Geometry Functions

- `Get_segment()`
- `Get_start()`
- `Get_end()`
- `Get_x()`
- `Get_y()`
- `Sqrt()`

### Super String Functions

- `Get_points()`
- `Get_super_vertex_coord()`

### Model Functions

- `Create_model_box()`
- `Get_elements()`

### Panel Functions

- `Create_source_box()`
- `Create_real_box()`
- `Create_colour_message_box()`
- `Validate()`

## Reporting

The summary reports:

- Drainage strings processed
- Upstream pits updated
- Direct lot connections counted

Warnings are generated where pit attributes cannot be written.

## Notes

- The lot connection count is reset for every pipe.
- Upstream pits store the final count.
- Downstream-pit connections are excluded to prevent duplicate counts.
- Valid lot connections must contain exactly two vertices.
- Intended primarily for Watercare wastewater design workflows.

## Limitations

- Supports only two-vertex lot connections.
- Uses Vertex 2 as the drainage attachment point.
- Does not create or modify lot connections.
- Counts direct connections only.
- Does not calculate wastewater flow directly.
- No undo records are created.

## Keywords

lot connection, LC, wastewater, Watercare, drainage, upstream pit, area attribute, direct lot count, flow estimation, property connections, sewer design

## Related Macros

- Create_Catchments_From_LC_panel
- LC_creator_panel
- Drainage_Network_Framework
- Drainage_Set_Design_Grade_By_Self_Cleaning_Flow

## Revision History

| Version | Date | Notes |
|---|---|---|
| 001 | 23/09/2026 | Initial release. Counts direct lot connections and writes the count to the upstream pit area attribute. |
