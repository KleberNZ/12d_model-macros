# AT_GD0004_panel

## Purpose

Creates a Super Alignment (SA) kerb return between two selected centreline strings using Auckland Transport TDM GD0004 compound curve geometry.

The macro automates the creation of kerb return Super Alignments by generating both horizontal and vertical geometry from two selected road centrelines. It applies GD0004 compound curve parameters for residential and commercial intersections and builds the required computator parts automatically.

## Location

C:\12d\12dPL_Data\Code\AT_GD0004_panel

## Source

AT_GD0004_panel.4dm

## Compile Method

Open VS Code from:

C:\12d\12dPL_Data

Then open:

Code\AT_GD0004_panel\AT_GD0004_panel.4dm

Compile using:

Ctrl+Shift+P > 12dPL: Compile Current File

## Include Setup

```cpp
#include "standard_library.H"
#include "size_of.H"
```

## Category

Roading

## Type

Super Alignment Generation

## Author

KLP

## 12d Version

V15

## Current Version

001

## Purpose of the Geometry

Creates a kerb return SA between two road centrelines.

The resulting SA includes:

- Horizontal geometry.
- Vertical geometry.
- GD0004 compound curve geometry.
- Optional transition parts.
- Super Alignment computators.

## Inputs

### Approach Centreline

User selects:

- Approach centreline string.
- Direction of travel.

### Departure Centreline

User selects:

- Departure centreline string.
- Direction of travel.

### Carriageway Widths

- Approach lane width.
- Departure lane width.

### Curve Type

Options:

- Residential Compound Curve
- Commercial Compound Curve

### Curve Offset

Defaults:

- Residential = 6.4 m
- Commercial = 13.5 m

### Output Model

Destination model for the new Super Alignment.

### Optional Settings

- Include 1 m transition end parts.

## Outputs

Creates:

- A new Super Alignment.
- Horizontal SA geometry.
- Vertical SA geometry.
- Computator parts.
- Undo record.

The SA is automatically placed into the selected output model.

## GD0004 Geometry Parameters

### Residential Curve

Uses:

- Curve offset = 6.4 m
- Approaching radius = 4 m
- Departing radius = 15 m

### Commercial Curve

Uses:

- Curve offset = 13.5 m
- Approaching radius = 7 m
- Departing radius = 30 m

### Compound Curve Ratio

Default:

```text
0.5
```

## Workflow

1. Select the approach centreline.
2. Select the departure centreline.
3. Specify the lane widths.
4. Select Residential or Commercial curve type.
5. Confirm the generated kerb return name.
6. Select an output model.
7. Press Process.
8. Horizontal computators are created.
9. GD0004 compound curve geometry is generated.
10. Vertical geometry is generated.
11. The Super Alignment is calculated.
12. The SA is added to the output model.

## Horizontal Parts Created

Depending on the settings, the macro creates:

- Fixed horizontal line parts.
- Free arc length parts.
- KerbReturnApp transition.
- Two centred compound curve.
- KerbReturnDep transition.

## Vertical Parts Created

The macro automatically creates:

### Entry Grade

- 3% vertical offset.

### Compound Vertical Curve

- Free parabola compound.

### Exit Grade

- 3% vertical offset.

## Main 12dPL Functions Demonstrated

### Super Alignment Functions

- Create_super_alignment()
- Super_alignment_horz_part_append()
- Super_alignment_vert_part_append()
- Calc_super_alignment_horz()
- Calc_super_alignment_vert()

### Computator Generation

- computator_horz_line_2_points
- two_centred_curve
- free_arc_length
- computator_vertical_offset
- free_parabola_compound

### Selection Functions

- Create_new_select_box()
- Get_select_direction()
- Validate()

### Model Functions

- Get_model_create()
- Set_model()
- Set_name()
- Calc_extent()

### Undo Functions

- Add_undo_add()

## Naming Convention

The macro automatically suggests:

```text
<Approach String> to <Departure String> <Counter>
```

Example:

```text
Totara Road CL to Access Road CL 1
```

The counter increments automatically after successful creation.

## Notes

- Designed around Auckland Transport GD0004 geometry.
- Generates complete horizontal and vertical SA geometry.
- Supports centreline selection with direction.
- Creates reusable computator-based geometry.
- Generates an undo record for the created SA.
- Automatically updates default offsets when curve type changes.

## Limitations

- Expects two valid centreline strings.
- Uses fixed GD0004 radii and geometry assumptions.
- Vertical grades are fixed at 3%.
- Compound curve ratio is fixed at 0.5.
- Intended primarily for standard urban kerb returns.

## Keywords

GD0004, Auckland Transport, kerb return, intersection design, compound curve, two centred curve, super alignment, SA, computator, road geometry, vertical geometry, horizontal geometry

## Related Macros

- Create_mini_roundabout_SA_panel
- Height_between_2_super_alignments_panel
- Label_height_between_2_SA_panel
- Print_SA_parts

## Revision History

| Version | Date | Notes |
|---|---|---|
| 001 | 10/03/2026 | Initial version. Creates GD0004 kerb return Super Alignments with automated horizontal and vertical geometry generation. |
