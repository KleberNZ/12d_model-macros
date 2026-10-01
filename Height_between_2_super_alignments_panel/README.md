# Height_between_2_super_alignments_panel

## Purpose

Calculates vertical height differences between pairs of Super Alignments and exports the results to a CSV file.

The macro was primarily developed for retaining-wall scheduling workflows where a TOP alignment and a BOTTOM alignment define the wall extents. It automatically pairs alignments using naming conventions, samples elevations along the common chainage range, calculates height differences, and writes the results to a CSV report.

## Location

C:\12d\12dPL_Data\Code\Height_between_2_super_alignments_panel

## Source

Height_between_2_super_alignments_panel.4dm

## Compile Method

Open VS Code from:

C:\12d\12dPL_Data

Then open:

Code\Height_between_2_super_alignments_panel\Height_between_2_super_alignments_panel.4dm

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

Reporting / Retaining Wall Scheduling

## Author

Kleber Lessa do Prado

## 12d Version

V15

## Current Version

1.00

## Inputs

### Super Alignment Source

Select the Super Alignments to be analysed.

### Top Suffix

Default:

```text
TOP
```

### Bottom Suffix

Default:

```text
BOTTOM
```

### Chainage Interval

Sampling interval used when evaluating wall heights.

Default:

```text
5.0 m
```

### CSV Output File

Destination CSV file.

## Naming Convention

The macro pairs alignments using a common prefix and user-defined suffixes.

Example:

```text
RW001 TOP
RW001 BOTTOM
```

Produces pair:

```text
RW001
```

The prefix becomes the wall identifier written to the CSV file.

## Outputs

Creates a CSV file containing:

```text
WallName
Chainage
TopZ
BottomZ
DeltaZ
```

Each row represents a sampled chainage position.

Example:

```text
RW001,25.000,14.523,12.918,1.605
```

## Calculation Method

For each matched TOP/BOTTOM pair:

1. Read start and end chainages from both alignments.
2. Determine the overlapping chainage range.
3. Trim 0.1 m from both ends.
4. Sample elevations at the nominated chainage interval.
5. Retrieve vertical levels from both alignments.
6. Calculate:

```text
DeltaZ = |TopZ - BottomZ|
```

7. Write the results to the CSV file.

## Chainage Handling

The common chainage range is determined by:

```text
Start = maximum(StartTOP, StartBOTTOM)
End   = minimum(EndTOP, EndBOTTOM)
```

The macro then applies:

```text
Start += 0.1 m
End   -= 0.1 m
```

This avoids endpoint evaluation issues at alignment boundaries.

## Workflow

1. Select the source Super Alignments.
2. Enter TOP and BOTTOM suffixes.
3. Enter the chainage interval.
4. Select an output CSV file.
5. Select Process.
6. The alignments are classified as TOP or BOTTOM.
7. Pairs are matched using prefix names.
8. Common chainage limits are determined.
9. Heights are sampled.
10. CSV records are written.
11. A processing summary is displayed.

## Main 12dPL Functions Demonstrated

### Super Alignment Functions

- `Get_chainage()`
- `Get_end_chainage()`
- `Get_super_alignment_vertical_position()`

### String Functions

- `Get_name()`
- `Get_subtext()`
- `Text_length()`

### Dynamic Container Functions

- `Dynamic_Element`
- `Dynamic_Text`
- `Append()`
- `Get_item()`
- `Get_number_of_items()`

### File Functions

- `File_open()`
- `File_write_line()`
- `File_close()`

### Panel Functions

- `Create_panel()`
- `Create_source_box()`
- `Create_input_box()`
- `Create_real_box()`
- `Create_file_box()`
- `Validate()`

## Reporting

The completion message reports:

- Number of TOP alignments found
- Number of BOTTOM alignments found
- Number of matched pairs
- Number of unmatched alignments
- Number of CSV rows written

If no valid pairs are found, no CSV data is generated.

## Notes

- Designed for retaining wall scheduling workflows.
- Uses naming conventions instead of manual pairing.
- Absolute height differences are reported.
- Supports any number of matched wall pairs.
- Relative chainage starts at zero for each wall.

## Limitations

- Requires naming consistency between TOP and BOTTOM alignments.
- Uses only the overlapping chainage range.
- Reports vertical differences only.
- Does not create wall geometry.
- Does not calculate wall quantities or schedules.
- Unmatched alignments are ignored.

## Keywords

Retaining wall, Super Alignment, wall height, TOP, BOTTOM, chainage, elevation difference, CSV export, reporting, scheduling, road design

## Related Macros

- Label_height_between_2_SA_panel
- AT_GD0004_panel
- Print_SA_parts

## Revision History

| Version | Date | Notes |
|---|---|---|
| 1.00 | 27/11/2025 | Initial release. Pairs TOP/BOTTOM Super Alignments, samples elevations and exports wall heights to CSV. |
