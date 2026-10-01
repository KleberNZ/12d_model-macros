# Label_height_between_2_SA_panel

## Purpose

Creates height-difference labels between matched Super Alignment pairs.

The macro matches Super Alignments using naming suffixes (typically TOP and BOTTOM), calculates vertical height differences along the overlapping alignment length, and places labels perpendicular to the alignment at user-defined chainage intervals.

An optional maximum-height search identifies and labels the maximum vertical difference for each matched pair.

## Location

C:\12d\12dPL_Data\Code\Label_height_between_2_SA_panel

## Source

Label_height_between_2_SA_panel.4dm

## Compile Method

Open VS Code from:

C:\12d\12dPL_Data

Then open:

Code\Label_height_between_2_SA_panel\Label_height_between_2_SA_panel.4dm

Compile using:

Ctrl+Shift+P > 12dPL: Compile Current File

## Include Setup

```cpp
#include "standard_library.h"
#include "size_of.h"
```

## Category

Roading

## Type

Retention Wall / Height Difference Labelling

## Author

KLP

## 12d Version

V15

## Current Version

001

## Inputs

### Super Alignment Source

Select multiple Super Alignments.

### SA1 Suffix

Default:

```text
TOP
```

### SA2 Suffix

Default:

```text
BOTTOM
```

### Output Model

Model where labels will be created.

### Precision

Number of decimal places displayed.

Default:

```text
3
```

### Chainage Interval

Default:

```text
10.0 m
```

### Regular Intervals Plus End Point

Optional endpoint label.

### Include Maximum Height Difference

Optional maximum-height label.

### Text Style Parameters

Uses a standard 12d text style configuration.

## Outputs

Creates text labels such as:

```text
HT=1.235m
```

or:

```text
HT=1.235m (MAX)
```

Labels are written to the selected output model.

## Pair Matching Logic

Pairs are identified using a common name prefix.

Example:

```text
RW01 TOP
RW01 BOTTOM
```

produces pair:

```text
RW01
```

Only exact suffix matches are accepted.

## Height Calculation

At each chainage:

```text
Height Difference = SA1 Level - SA2 Level
```

Label text:

```text
HT=<difference>m
```

The height value is calculated from:

```cpp
Get_super_alignment_vertical_position()
```

for both Super Alignments.

## Label Orientation

Labels are created:

- At the alignment position.
- Rotated perpendicular to alignment direction.
- Automatically normalised for readability.

The macro uses:

```cpp
Get_position()
```

from the SA horizontal string to determine insertion angle.

## Maximum Height Difference Option

When enabled:

- Heights are evaluated every 0.01 m.
- The maximum absolute difference is identified.
- The result is reported to the Output Window.
- One MAX label is created.
- Duplicate labels are avoided when the maximum occurs on a regular interval.

Internal resolution:

```text
0.01 m
```

## Workflow

1. Select Super Alignments.
2. Define TOP and BOTTOM suffixes.
3. Select an output model.
4. Define precision.
5. Define chainage interval.
6. Configure text style.
7. Enable optional endpoint and maximum-height labelling if required.
8. Select Process.
9. Matching pairs are identified.
10. Heights are sampled.
11. Labels are created.
12. Undo records are grouped.

## Main 12dPL Functions Demonstrated

### Super Alignment Functions

- `Get_super_alignment_vertical_position()`
- `Get_super_alignment_horizontal_string()`
- `Get_length()`
- `Get_position()`

### Text Functions

- `Create_text()`
- `Set_model()`

### Model Functions

- `Create_model()`
- `Get_model()`
- `Model_exists()`

### Panel Functions

- `Create_source_box()`
- `Create_model_box()`
- `Create_textstyle_data_box()`
- `Create_real_box()`
- `Create_integer_box()`
- `Create_named_tick_box()`

### Undo Functions

- `Add_undo_add()`
- `Add_undo_list()`

## Undo Support

All labels are grouped under:

```text
Label SA height differences
```

allowing a single undo operation.

## Notes

- Intended primarily for retaining wall design and scheduling.
- Automatically pairs alignments by name.
- Labels are positioned perpendicular to the alignment.
- Supports endpoint labelling.
- Supports maximum-height detection.

## Limitations

- Requires consistent naming conventions.
- Uses only matched SA pairs.
- Reports vertical differences only.
- Does not create schedules or CSV files.
- Maximum-height search uses a fixed 0.01 m resolution.

## Keywords

retaining wall, height difference, super alignment, TOP, BOTTOM, label, chainage, maximum height, wall schedule, road design, civil design

## Related Macros

- Height_between_2_super_alignments_panel
- AT_GD0004_panel
- Print_SA_parts

## Revision History

| Version | Date | Notes |
|---|---|---|
| 001 | 28/04/2008 | Initial version. Labels height differences between matched Super Alignment pairs with optional maximum-height labelling. |
