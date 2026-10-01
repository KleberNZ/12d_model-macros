# Set_PC_DS_IL_from_main_panel

## Purpose

Sets Property Connection (PC) downstream pipe invert levels from the connected main drainage pipe.

For each PC drainage string, the macro locates the intersecting main drainage pipe, interpolates the main pipe invert level (IL) at the projected connection chainage, and sets the PC downstream invert level to:

```text
Main Pipe IL + 0.5 × Main Pipe Diameter
```

The downstream invert is then locked.

## Location

C:\12d\12dPL_Data\Code\Set_PC_DS_IL_from_main_panel

## Source

Set_PC_DS_IL_from_main_panel.4dm

## Compile Method

Open VS Code from:

C:\12d\12dPL_Data

Then open:

Code\Set_PC_DS_IL_from_main_panel\Set_PC_DS_IL_from_main_panel.4dm

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

Property Connection Utility

## Author

KLP

## 12d Version

V15

## Current Version

001

## Build

```text
version.0.001
```

## Inputs

### Main Drainage Model

Model containing the primary SW or WW drainage strings.

### Property Connection Model

Model containing property connection drainage strings.

### Matching Tolerance

Internal setting:

```text
0.5 m
```

Used to determine whether the PC downstream point projects onto a main pipe.

## Outputs

Updates PC drainage strings by:

- Setting downstream invert level.
- Setting `lock ds il = 1`.

Produces a report showing:

- Main drainage strings.
- Updated PC strings.
- Mains without matching PCs.

## Calculation Method

For each matched PC:

```text
PC DS IL = Main IL + 0.5 × Main Pipe Diameter
```

Where:

```text
Main IL
```

is interpolated along the main pipe at the projected connection chainage.

## Workflow

1. Select the main drainage model.
2. Select the property connection drainage model.
3. Run Process.
4. Each main drainage string is analysed.
5. Each PC drainage string is analysed.
6. The PC downstream point is determined from drainage flow direction.
7. The downstream point is projected onto the main drainage string.
8. The matching main pipe is identified.
9. Main invert level is interpolated.
10. Downstream IL is updated.
11. The downstream invert lock is enabled.
12. Results are written to the log window.

## Flow Direction Handling

The macro automatically determines the downstream end of the PC string.

### Flow Direction = 1

```text
Last vertex = downstream end
```

### Flow Direction = 0

```text
First vertex = downstream end
```

The downstream pipe invert is updated on the downstream pipe segment.

## Matching Logic

A PC is considered connected when:

- Its downstream point can be projected onto a main drainage string.
- Offset from the main is less than the matching tolerance.
- The projected chainage falls within the chainage range of a main pipe.

Each PC is processed only once.

## Main 12dPL Functions Demonstrated

### Drainage Functions

- `Get_drainage_flow()`
- `Get_drainage_data()`
- `Get_drainage_pipe_inverts()`
- `Set_drainage_pipe_inverts()`
- `Get_drainage_pipe_diameter()`
- `Set_drainage_pipe_attribute()`
- `Get_drainage_pit_attribute()`

### Geometry Functions

- `Drop_point()`
- Chainage interpolation
- Pipe projection methods

### Model Functions

- `Create_model_box()`
- `Get_model()`
- `Get_elements()`

### Logging Functions

- `Create_log_box()`
- `Create_group_log_line()`
- `Create_highlight_string_log_line()`
- `Create_text_log_line()`

### Panel Functions

- `Create_panel()`
- `Create_colour_message_box()`
- `Wait_on_widgets()`

## Reporting

The results window shows:

- Each processed main drainage string.
- Property connections successfully updated.
- Mains with no intersecting PCs.

Updated PC strings are displayed as clickable highlighted elements.

## Notes

- Supports both stormwater and wastewater mains.
- Uses chainage-based invert interpolation.
- Locks the downstream invert after updating.
- Each PC can only be updated once per run.
- Intended for automated property connection design workflows.

## Limitations

- Uses a fixed matching tolerance of 0.5 m.
- Requires valid drainage flow direction.
- Requires valid pipe diameters.
- Does not create property connection strings.
- Does not modify upstream PC invert levels.
- No undo records are created.

## Keywords

property connection, PC, downstream invert, drainage design, sewer connection, stormwater connection, chainage interpolation, main pipe IL, invert level, utility automation

## Related Macros

- Property_control_creator_panel
- LC_creator_panel
- Drainage_Network_Framework
- Set_Direct_Lot_Connection_Count_To_Upstream_Pit_Area

## Revision History

| Version | Date | Notes |
|---|---|---|
| 001 | 26/04/2001 | Initial version. Sets PC downstream invert levels from interpolated main pipe invert levels and locks the downstream invert. |
