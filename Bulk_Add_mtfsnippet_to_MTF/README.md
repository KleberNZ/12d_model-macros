# Bulk_Add_mtfsnippet_to_MTF

## Purpose

Performs bulk insertion of `SEMI_RECESSED_KERB.mtfsnippet` entries into MTF files for eligible semi-recessed cesspits.

The macro automates the process of finding qualifying drainage pits, locating the associated road setout strings and MTF files, and inserting the required mtfsnippet entries while preventing duplicates.

## Location

C:\12d\12dPL_Data\Code\Bulk_Add_mtfsnippet_to_MTF

## Source

Bulk_Add_mtfsnippet_to_MTF.4dm

## Compile Method

Open VS Code from:

C:\12d\12dPL_Data

Then open:

Code\Bulk_Add_mtfsnippet_to_MTF\Bulk_Add_mtfsnippet_to_MTF.4dm

Compile using:

Ctrl+Shift+P > 12dPL: Compile Current File

## Include Setup

```cpp
#include "standard_library.H"
#include "size_of.H"
```

## Category

Utilities

## Type

MTF File Automation

## Author

KLP

## 12d Version

V15

## Current Version

001

## Purpose

Bulk-modifies MTF files by inserting drainage-linked semi-recessed kerb snippets.

The macro is intended for large-scale updates where many semi-recessed cesspits must be added to MTF files without manually editing each file.

## Inputs

### Drainage Strings

User selects one or more drainage strings.

The macro processes only pits with type:

- `CP (SEMI-RECESSED)`
- `DCP (SEMI-RECESSED)`

### Drainage Attributes

The following drainage pit attributes are required:

- pit id
- design model id
- design string id

### Design Setout String

The associated setout string is resolved using:

- design model id
- design string id

### MTF Attributes

The setout string must contain:

```text
apply_mtf_details/mtf_file_name
```

## Outputs

Updates one or more MTF files.

For each valid pit the macro:

- Creates a drainage reference.
- Builds a snippet definition.
- Creates a CESSPITS region if required.
- Inserts the snippet.
- Prevents duplicates.
- Writes the modified MTF file.

## Supported Pit Types

### Single Cesspit

```text
CP (SEMI-RECESSED)
```

Produces:

```text
CP_TYPE = Single
```

### Double Cesspit

```text
DCP (SEMI-RECESSED)
```

Produces:

```text
CP_TYPE = Double
```

## Side Detection

The macro determines side automatically from the setout string name.

### Left Side

```text
KIL
```

Produces:

```text
ADJ = FPL
left_side_modifier
```

### Right Side

```text
KIR
```

Produces:

```text
ADJ = FPR
right_side_modifier
```

## Workflow

1. Select drainage strings.
2. Run Process.
3. Examine each pit.
4. Resolve associated setout string.
5. Read associated MTF filename.
6. Determine left or right side.
7. Build drainage reference.
8. Open the MTF file.
9. Locate the correct modifier block.
10. Locate or create the CESSPITS region.
11. Check for existing drainage_ref entries.
12. Insert snippet.
13. Save file.
14. Report results.

## Duplicate Protection

Before insertion the macro searches for:

```text
drainage_ref "<reference>"
```

If found, the pit is skipped.

This prevents duplicate mtfsnippet entries.

## Dependency Checks

The macro validates that the following file exists within the project folder:

```text
SEMI_RECESSED_KERB.mtfsnippet
```

A warning is reported if the file cannot be found.

## Reporting

The panel reports:

- UPDATED
- SKIPPED
- Duplicate skipped
- Missing KI link
- Missing MTF file
- Missing modifier block

A bulk summary is also provided.

## Summary Statistics

The macro reports:

- Total eligible pits
- Updated pits
- Duplicate entries skipped
- No KI link found

## Main 12dPL Functions Demonstrated

### Drainage Functions

- Get_drainage_pits()
- Get_drainage_pit_type()
- Get_drainage_pit_name()
- Get_drainage_pit_attribute()
- Get_drainage_pit_attribute_by_type()

### MTF File Processing

- File_exists()
- File_open()
- File_read_line()
- File_write_line()
- File_close()

### Object Resolution

- Get_model()
- Get_element()
- Get_attribute()
- Convert_uid()

### Reporting

- Create_log_box()
- Create_text_log_line()
- Create_highlight_string_log_line()
- Add_log_line()
- Print_log_line()

## Notes

- Designed specifically for semi-recessed cesspit workflows.
- Automatically creates a CESSPITS region when missing.
- Uses brace-depth tracking to identify the true extent of modifier blocks.
- Only inserts snippets on the appropriate road side.
- Highlights affected drainage strings in the report panel.

## Limitations

- No undo functionality is provided.
- Requires design model and design string links to exist.
- Requires MTF file references to be valid.
- Supports only semi-recessed CP and DCP pit types.
- Uses a fixed 20,000-line file buffer.

## Keywords

MTF, mtfsnippet, bulk update, semi recessed kerb, CP, DCP, cesspit, drainage reference, KI link, KIL, KIR, FPL, FPR, MTF automation, drainage design

## Related Macros

- Add_to_mtf_snippet_panel
- Drainage_Updater

## Revision History

| Version | Date | Notes |
|---|---|---|
| 001 | Initial release | Bulk insertion of SEMI_RECESSED_KERB mtfsnippets into MTF files with duplicate protection and automatic CESSPITS region creation. |
