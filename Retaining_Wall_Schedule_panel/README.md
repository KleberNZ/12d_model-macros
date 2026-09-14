### Retaining_Wall_Schedule_panel

#### Purpose

Creates a retaining-wall length schedule from paired TOP and BOTTOM Super Alignments.

The macro identifies wall pairs using a common name prefix and the configured suffixes. For example:

- `WALL A1 TOP`
- `WALL A1 BOTTOM`

For each successfully matched pair, the macro samples the vertical difference between the TOP and BOTTOM alignments at a hard-coded interval of 0.1 m. Each sampled wall segment is assigned to a 1 m height band, and the accumulated length in each band is written to the selected output file.

#### Location

`C:\12d\12dPL_Data\Code\Retaining_Wall_Schedule_panel`

#### Source

`Retaining_Wall_Schedule_panel.4dm`

#### Compile Method

Open VS Code from:

`C:\12d\12dPL_Data`

Then open:

`Code\Retaining_Wall_Schedule_panel\Retaining_Wall_Schedule_panel.4dm`

Compile using:

`Ctrl+Shift+P > 12dPL: Compile Current File`

Do not use F7 unless the old task system has been deliberately updated.

#### Include Setup

This macro uses clean includes:

```c
#include "standard_library.H"
#include "size_of.h"
```

These rely on the central workspace setting:

`12dpl.compiler.includePaths = C:\12d\includes`

#### Naming Convention

The default suffixes are:

- TOP alignment suffix: `TOP`
- BOTTOM alignment suffix: `BOTTOM`

The text before the suffix is treated as the wall name and pairing key.

Example:

```text
WALL A1 TOP
WALL A1 BOTTOM
```

Both alignments are paired under the output wall name `WALL A1`.

Trailing spaces in alignment names and suffix entries are removed before matching. Matching is otherwise exact and case-sensitive.

#### Inputs

The panel contains the following inputs:

- **Retaining wall Super Alignments**
  - Source box containing the candidate TOP and BOTTOM Super Alignments.
  - Select both alignments for every wall that is to be scheduled.

- **Top suffix**
  - Default value: `TOP`.
  - Identifies the top-of-wall Super Alignments.

- **Bottom suffix**
  - Default value: `BOTTOM`.
  - Identifies the bottom-of-wall Super Alignments.

- **Delimiter**
  - Choice box used to select the separator written between output fields.
  - Available choices:
    - `,` for comma-delimited output
    - `;` for semicolon-delimited output
    - `tab` for tab-delimited output
  - The selected display value is converted to the corresponding output character before the header and data rows are written.
  - For the `tab` choice, the macro writes a tab character rather than the word `tab`.

- **Output file**
  - Destination path and filename for the wall schedule.
  - The selected delimiter controls the file contents. The filename extension does not change the separator used inside the file.

The chainage sampling interval is not shown on the panel. It is hard-coded to 0.1 m.

#### Processing Method

For each selected Super Alignment, the macro:

1. Reads the alignment name.
2. Checks whether the name ends with the TOP or BOTTOM suffix.
3. Removes the suffix to create the wall pairing key.
4. Matches TOP and BOTTOM alignments that have the same key.
5. Determines the common chainage range shared by both alignments.
6. Crops 0.1 m from each end of the common range.
7. Divides the remaining range into segments of up to 0.1 m.
8. Samples the TOP and BOTTOM levels at the midpoint of each segment.
9. Calculates wall height as the absolute vertical level difference.
10. Adds the segment length to the applicable height band.
11. Builds the header and data rows using the delimiter selected in the panel.
12. Writes one output row for each successfully processed wall pair.

#### Height Bands

The height bands are currently hard-coded as:

- 0 to 1 m
- Greater than 1 m to 2 m
- Greater than 2 m to 3 m
- Greater than 3 m to 4 m
- Greater than 4 m to 5 m
- Greater than 5 m to 6 m
- Greater than 6 m to 7 m
- Greater than 7 m to 8 m
- Greater than 8 m to 9 m
- Greater than 9 m to 10 m
- Greater than 10 m

A height exactly equal to a band upper limit is included in that band. For example, 1.000 m is placed in `0-1m`, while a height greater than 1.000 m and up to 2.000 m is placed in `1-2m`.

#### Outputs

The output contains the following fields:

```text
WallName | TotalLength | 0-1m | 1-2m | 2-3m | 3-4m | 4-5m | 5-6m | 6-7m | 7-8m | 8-9m | 9-10m | Over10m
```

The vertical bars above illustrate field boundaries only. The actual separator is the delimiter selected in the panel.

Examples:

Comma-delimited:

```text
WallName,TotalLength,0-1m,1-2m,...
```

Semicolon-delimited:

```text
WallName;TotalLength;0-1m;1-2m;...
```

Tab-delimited:

```text
WallName<TAB>TotalLength<TAB>0-1m<TAB>1-2m<TAB>...
```

`<TAB>` represents an actual tab character in the generated file.

- **WallName**: Common prefix used to match the TOP and BOTTOM alignments.
- **TotalLength**: Common sampled chainage length after the 0.1 m crop at each end.
- **Height-band fields**: Accumulated wall length classified into each height range.

Lengths are written in metres to three decimal places.

The panel status message reports the matched pairs, walls written, sampling interval, ignored source names, failed samples and selected delimiter where implemented in the revised status text.

#### Delimiter and Spreadsheet Compatibility

The delimiter choice is provided because spreadsheet applications can use different regional list-separator settings.

- Try **comma** when the spreadsheet installation recognises comma-separated CSV files.
- Try **semicolon** when the spreadsheet installation uses semicolon as its configured list separator.
- Try **tab** when comma and semicolon files open with each complete row in a single spreadsheet cell.

If a file still opens into one cell, import the file through the spreadsheet application's text or CSV import command and select the same delimiter used by the macro.

#### Notes

- Only successfully matched TOP and BOTTOM pairs are included in the output.
- The TOP and BOTTOM alignments must overlap in chainage.
- Paired alignments are assumed to use a compatible chainage reference.
- Wall height is calculated using the absolute level difference.
- Sampling is performed at the midpoint of each 0.1 m segment.
- The final segment may be shorter than 0.1 m.
- A 0.1 m crop is applied at both ends of the shared chainage range.
- Failed vertical samples are skipped and reported in the panel status message.
- If samples fail, the sum of the height-band lengths can be less than `TotalLength`.
- If multiple BOTTOM alignments have the same pairing key, the first matching alignment in the selected source is used.
- The height bands and sampling interval are currently hard-coded.
- The delimiter affects both the header and every data row.
- The macro creates a schedule file only. It does not modify the selected Super Alignments or create 12d model elements.

#### Suggested Checks Before Use

- Confirm every wall has one TOP and one BOTTOM Super Alignment.
- Confirm paired names use the same spelling, spacing and letter case.
- Confirm paired alignments overlap and share the same chainage reference.
- Confirm the output location is writable.
- Select a delimiter appropriate for the application that will open the output.
- Review the completion message for ignored names and failed samples.
- Open the output and confirm the header is separated into individual columns.
- When no samples fail, check that the height-band lengths add up to the reported total length.

#### Revision History

| Version | Date | Notes |
|---|---|---|
| 001 | 2026-09-02 | Initial macro and README documentation. |
| 002 | 2026-09-15 | Added panel Choice_Box for comma, semicolon or tab output delimiters and updated output documentation. |
