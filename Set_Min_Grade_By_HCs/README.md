# Set_Min_Grade_By_HCs

## Purpose

Calculates and assigns minimum drainage pipe design grades based on the cumulative number of upstream house/property connections.

The macro applies Watercare minimum grade criteria using cumulative house connections and writes the resulting grade (%) to the pipe attribute `design grade`.

Pipe geometry and invert levels are not modified.

## Location

C:\12d\12dPL_Data\Code\Set_Min_Grade_By_HCs

## Source

Drainage_Adjust_Grade_By_HCs.4dm

## Compile Method

Open VS Code from:

C:\12d\12dPL_Data

Then open:

Code\Set_Min_Grade_By_HCs\Drainage_Adjust_Grade_By_HCs.4dm

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

Wastewater Design Automation

## Author

KLP

## 12d Version

V15

## Current Version

002

## Build

```text
15.0.001
```

## Inputs

### Drainage Strings

Select one or more drainage strings.

All selected elements must be of type:

```text
Drainage
```

### Required Drainage Data

The drainage string must contain:

- Pipe chainages
- Pit chainages
- Property connection chainages
- Pipe diameters
- Existing drainage attributes

## Outputs

Updates the pipe Real attribute:

```text
design grade
```

The calculated grade is stored as a percentage.

Examples:

```text
1.00
0.75
0.45
0.30
```

The Output Window reports:

- Pipe name
- Pipe diameter
- Cumulative upstream property connections
- Assigned minimum grade

## Design Method

The macro determines the number of cumulative upstream property connections.

Property connection chainages are compared against the downstream end of each pipe in the direction of flow.

A cumulative count is then calculated:

```text
Connections upstream of the pipe outlet
```

The minimum grade is assigned according to Watercare criteria.

## Watercare Grade Rules Implemented

### DN150

| Cumulative Property Connections | Design Grade |
|---|---|
| < 20 | 1.00% |
| 20 to < 200 | 0.75% |
| ≥ 200 | 0.75% |

### DN225

| Design Grade |
|---|
| 0.45% |

### DN300

| Design Grade |
|---|
| 0.30% |

### Other Pipe Sizes

Skipped.

No design-grade modification is made.

## Flow Direction Processing

The downstream chainage used for cumulative counting depends on:

```cpp
Get_drainage_flow()
```

### Flow Following String Direction

Downstream chainage:

```text
Pit s+1
```

### Flow Opposite String Direction

Downstream chainage:

```text
Pit s
```

This ensures cumulative property connections are counted in the hydraulic flow direction.

## Workflow

1. Select drainage strings.
2. Run Process.
3. Validate all selected elements are drainage strings.
4. Read drainage flow direction.
5. Read property connection chainages.
6. Read pit chainages.
7. Determine downstream chainage.
8. Calculate cumulative property connections.
9. Determine Watercare minimum design grade.
10. Update the design grade attribute.
11. Verify the written value.
12. Report results to the Output Window.

## Main 12dPL Functions Demonstrated

### Drainage Functions

- `Get_drainage_flow()`
- `Get_drainage_pcs_count()`
- `Get_drainage_pc_chainage()`
- `Get_drainage_pit_chainage()`
- `Get_drainage_pipe_attribute()`
- `Get_drainage_pipe_attributes()`
- `Set_drainage_pipe_attributes()`

### Attribute Functions

- `Get_attribute()`
- `Set_attribute()`

### Dynamic Containers

- `Dynamic_Element`
- `Dynamic_Real`
- `Append()`
- `Get_item()`

### Panel Functions

- `Create_source_box()`
- `Create_colour_message_box()`
- `Validate()`
- `Wait_on_widgets()`

## Notes

- Intended for wastewater design workflows.
- Uses cumulative property connections rather than direct property connections.
- Updates only the design-grade attribute.
- Pipe geometry is not modified.
- After assignment, the drainage network should be regraded using WNE → Regrade Links.

## Limitations

- Supports DN150, DN225 and DN300 only.
- Requires valid property connection chainages.
- Does not calculate wastewater flows.
- Does not modify pipe invert levels.
- Unsupported pipe sizes are skipped.
- No undo records are created.

## Keywords

house connections, property connections, wastewater, Watercare, minimum grade, design grade, cumulative connections, sewer design, drainage automation, DN150, DN225, DN300

## Related Macros

- Set_Direct_Lot_Connection_Count_To_Upstream_Pit_Area
- Drainage_Set_Design_Grade_By_Self_Cleaning_Flow
- Drainage_Network_Framework
- ACCoP_WW_Check

## Revision History

| Version | Date | Notes |
|---|---|---|
| 002 | 11/02/2026 | Calculates minimum design grades from cumulative upstream property connections and writes values to the design grade pipe attribute. |
