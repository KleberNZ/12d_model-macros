# Add_to_mtf_snippet_panel

## Purpose

Adds an MTF snippet entry to an existing `.mtf` file at a selected drainage pit location.

The macro is intended to automate the insertion of predefined MTF snippets, such as semi-recessed kerb cesspits, into a road design MTF file by linking the snippet to a selected drainage pit and determining the correct road side from an associated super string.

## Location

C:\12d\12dPL_Data\Code\Add_to_mtf_snippet_panel

## Source

Add_to_mtf_snippet_panel.4dm

## Compile Method

Open VS Code from:

C:\12d\12dPL_Data

Then open:

Code\Add_to_mtf_snippet_panel\Add_to_mtf_snippet_panel.4dm

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

## Inputs

### Drainage String

The user selects a drainage string containing the cesspit.

Current implementation assumes:

- The cesspit is pit number 2 in the drainage string.
- The selected string type must be `Drainage`.

### Super String

The user selects a road super string.

The selected string must:

- Be of type `Super`.
- Contain attributes:
  - `apply_mtf_details/mtf_file_name`
  - `apply_mtf_details/link_side`

## Outputs

- Updates an existing `.mtf` file.
- Creates or updates a `CESSPITS` region.
- Inserts a new snippet definition.
- Links the snippet to the selected drainage pit.
- Preserves existing MTF content.

## Workflow

1. Select a drainage string.
2. Select a road super string.
3. Extract pit name and pit ID from drainage pit #2.
4. Build a drainage reference.
5. Read the MTF filename from the super string.
6. Determine whether the super string represents the left or right side of the road.
7. Build the snippet definition.
8. Open the target MTF file.
9. Locate the insertion location.
10. Create a `CESSPITS` region if it does not exist.
11. Insert the snippet.
12. Save the modified MTF file.

## Snippet Inserted

The macro inserts a snippet based on:

```text
SEMI_RECESSED_KERB.mtfsnippet
```

The generated entry includes:

- drainage_ref
- CP_TYPE
- KINV
- ADJ

Values are automatically populated from the selected drainage pit and road side.

## MTF Region Logic

The macro searches for:

```text
left_side_modifier
right_side_modifier
```

and inserts the snippet:

- inside an existing `CESSPITS` region, or
- creates a new `CESSPITS` region if one does not already exist.

The insertion occurs before pavement regions where appropriate.

## Main 12dPL Functions Demonstrated

### Drainage Functions

- `Get_drainage_pit_name()`
- `Get_drainage_pit_attribute()`

### Attribute Functions

- `Get_attribute()`
- `Get_type()`

### Model Functions

- `Get_model()`
- `Get_name()`

### File Functions

- `File_exists()`
- `File_open()`
- `File_read_line()`
- `File_write_line()`
- `File_close()`

### User Interface Functions

- `Create_panel()`
- `Create_new_select_box()`
- `Create_colour_message_box()`
- `Wait_on_widgets()`

## Notes

- Designed specifically for MTF workflows using drainage-linked kerb components.
- Automatically derives kerb inversion and adjacency variables from the road side.
- Uses project-relative paths via `Get_absolute_path("")`.
- Preserves existing MTF content and inserts only the required lines.

## Limitations

- Assumes the cesspit is always pit number 2.
- Currently inserts only `SEMI_RECESSED_KERB.mtfsnippet`.
- Requires specific super-string attributes to exist.
- Uses a fixed-size text buffer of 20,000 lines when loading the MTF file.
- Does not validate duplicate snippet entries.

## Keywords

MTF, mtfsnippet, semi recessed kerb, cesspit, drainage reference, road side, super string, file automation, kerb modelling, drainage integration

## Related Macros

- Bulk_Add_mtfsnippet_to_MTF
- Drainage_Updater

## Revision History

| Version | Date | Notes |
|---|---|---|
| 001 | 19/02/2026 | Initial version. Inserts drainage-linked mtf snippets into MTF files and automatically creates CESSPITS regions when required. |
