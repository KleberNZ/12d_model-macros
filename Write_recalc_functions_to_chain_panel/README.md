# Write_recalc_functions_to_chain_panel

## Purpose

Creates or updates a 12d Chain file by automatically writing **Recalc Function** commands for functions that match a user-specified wildcard pattern.

The macro can:

- Create a new chain file.
- Append commands to an existing chain file.
- Optionally organise commands into a Chain Region.
- Optionally sort functions using natural alphanumeric ordering.

It is intended to automate the creation of batch recalculation chains for large numbers of 12d functions.

## Location

C:
d
dPL_Data\Code\Write_recalc_functions_to_chain_panel

## Source

Write_recalc_functions_to_chain.4dm

## Compile Method

Open VS Code from:

C:
d
dPL_Data

Then open:

Code\Write_recalc_functions_to_chain_panel\Write_recalc_functions_to_chain.4dm

Compile using:

Ctrl+Shift+P > 12dPL: Compile Current File

## Include Setup

```cpp
#include "standard_library.H"
#include "size_of.H"
#include "QSort.H"
```

## Category

Utilities

## Type

Chain Automation Utility

## Author

Kleber Lessa do Prado

## 12d Version

V15

## Current Version

001

## Build

```text
version.0.001
```

## Inputs

### Function Name Pattern

Wildcard pattern used to select functions.

Examples:

```text
WW_* 
```

```text
Stormwater* 
```

```text
*Catchment*
```

### Chain File

Target chain file.

Options:

- Create new chain.
- Append to existing chain.

### Region Name (Optional)

Optional Chain Region.

If supplied:

```text
Region Name = Watercare Recalcs
```

all generated recalc commands are placed inside that region.

### Sort Alphabetically

Default:

```text
Enabled
```

Uses a natural sort algorithm.

Examples:

```text
Pipe 2
Pipe 10
```

rather than:

```text
Pipe 10
Pipe 2
```

## Outputs

Creates or updates a Chain XML file.

Generated commands:

```xml
<Function>
    <Name>Recalc MyFunction</Name>
    <Function>MyFunction</Function>
</Function>
```

Each matched function becomes a Recalc command.

## Workflow

1. Enter a wildcard function pattern.
2. Select a chain file.
3. Optionally enter a region name.
4. Choose whether functions should be sorted.
5. Select Process.
6. All project functions are retrieved.
7. Functions matching the wildcard pattern are identified.
8. Matching functions are sorted if requested.
9. A new chain file is created or an existing chain is updated.
10. Recalc Function commands are written.

## Chain Creation Logic

When the chain file does not exist:

- A complete XML chain file is built.
- Region blocks are created if requested.
- Function commands are inserted.

When the chain file already exists:

- Existing XML is read.
- Matching commands are appended.
- Region insertion is supported.
- Updated XML is written back.

## Region Support

A region block is written as:

```xml
<Region>
    <Name>Region Name</Name>
</Region>
```

If the specified region already exists:

- Commands are inserted into that region.

If the specified region does not exist:

- A new region is created.

## Natural Sort Logic

The macro converts numeric portions of names into padded sort keys.

Example:

```text
Function 2
Function 10
Function 100
```

Sorts correctly using:

```text
Function 2
Function 10
Function 100
```

instead of lexical sorting.

## Main 12dPL Functions Demonstrated

### Function Management

- `Get_all_functions()`
- `Match_name()`

### Chain File Generation

- XML generation
- XML insertion
- XML escaping using:

```cpp
Convert_legal_XML()
```

### Dynamic Containers

- `Dynamic_Text`
- `Append()`
- `Get_item()`
- `Get_number_of_items()`

### File Functions

- `File_exists()`
- `File_open()`
- `File_read_line()`
- `File_write_unicode()`
- `File_close()`

### Sorting Functions

- `Qsort()`
- Natural alphanumeric sorting

### Panel Functions

- `Create_input_box()`
- `Create_file_box()`
- `Create_named_tick_box()`
- `Validate()`

## Reporting

The message box reports:

```text
new chain created
```

or:

```text
existing chain appended
```

Error reporting includes:

- Invalid pattern
- Invalid chain file
- Invalid region
- No matching functions
- Failed chain read
- Failed chain write
- Failed append operation

## Notes

- Existing chains are preserved and extended.
- Unicode chain files are supported.
- XML-safe conversion is applied.
- Regions are optional.
- Natural sorting is enabled by default.
- Supports wildcard-based function selection.

## Limitations

- Maximum of 10,000 functions when sorting.
- Requires valid chain XML structure.
- Existing commands are not deduplicated.
- Wildcard matching uses Match_name behaviour.
- Does not validate whether matched functions will successfully recalculate.

## Keywords

12d chain, chain file, recalc functions, automation, batch processing, function management, XML generation, natural sorting, utility macro, wildcard matching

## Related Macros

- Rename_elements_panel
- Drainage_Network_Framework
- Polygon_Topology_Builder_panel

## Revision History

| Version | Date | Notes |
|---|---|---|
| 001 | 23/03/2026 | Initial version. Creates or updates Chain files by writing Recalc Function commands from wildcard-selected functions. |
