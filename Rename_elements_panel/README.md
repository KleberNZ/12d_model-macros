# Rename_elements_panel

## Purpose

Renames selected Super strings using sequential numbering.

The macro applies a user-defined naming pattern consisting of an optional prefix, a sequential number, and an optional suffix. Numbers start from a nominated value and increment by a user-specified amount.

## Location

C:\12d\12dPL_Data\Code\Rename_elements_panel

## Source

rename_elements.4dm

## Compile Method

Open VS Code from:

C:\12d\12dPL_Data

Then open:

Code\Rename_elements_panel\rename_elements.4dm

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

Element Naming Utility

## Author

User

## 12d Version

V15

## Current Version

001

## Build

```text
15.0.001
```

## Inputs

### Super Strings

Select one or more Super strings.

Only elements with type:

```text
Super
```

are processed.

### Prefix

Optional text placed before the sequential number.

Example:

```text
LOT_
```

### Suffix

Optional text placed after the sequential number.

Example:

```text
_PC
```

### Starting Number

First number assigned.

Default:

```text
1
```

### Increment

Amount added after each successful rename.

Default:

```text
1
```

Must be greater than zero.

## Outputs

Renames selected Super strings.

Generated names follow:

```text
<Prefix><Number><Suffix>
```

Examples:

```text
LOT_1
LOT_2
LOT_3
```

or

```text
MH100_SW
MH110_SW
MH120_SW
```

## Workflow

1. Select Super strings.
2. Enter optional prefix.
3. Enter optional suffix.
4. Enter starting number.
5. Enter increment value.
6. Select Process.
7. Each Super string is renamed.
8. Sequential numbering is updated after each successful rename.
9. A completion message reports the total number renamed.

## Name Generation Logic

For each Super string:

```text
New Name = Prefix + Number + Suffix
```

The current number is then increased by:

```text
Increment
```

Example:

Starting Number:

```text
100
```

Increment:

```text
10
```

Result:

```text
100
110
120
130
```

## Main 12dPL Functions Demonstrated

### Selection Functions

- `Create_source_box()`
- `Validate()`
- `Get_number_of_items()`
- `Get_item()`

### Element Functions

- `Get_type()`
- `Set_name()`

### Text Functions

- `To_text()`

### Panel Functions

- `Create_panel()`
- `Create_input_box()`
- `Create_integer_box()`
- `Create_colour_message_box()`
- `Wait_on_widgets()`

### Project Functions

- `Get_project_name()`

## Validation

The macro validates:

- A project is open.
- At least one Super string is selected.
- The increment is greater than zero.
- The starting number is valid.

If no project is open the macro exits immediately.

## Reporting

The completion message reports:

```text
Process completed. Renamed X super strings.
```

The Output Window also reports:

```text
Super String Rename Macro - Build 15.0.001
```

and

```text
Macro finished
```

## Notes

- Prefix and suffix are optional.
- Numbering can start at any integer value.
- Increment can be any positive integer.
- Non-Super elements are ignored.
- Existing names are overwritten.

## Limitations

- No undo records are created.
- No duplicate-name checking is performed.
- Only Super strings are renamed.
- Name uniqueness is the responsibility of the user.

## Keywords

rename, super string, sequential numbering, prefix, suffix, naming convention, utilities, bulk rename, element management

## Related Macros

- Change_Drainage_Colour
- LC_creator_panel
- Property_control_creator_panel

## Revision History

| Version | Date | Notes |
|---|---|---|
| 001 | 18/08/2025 | Initial version. Bulk renames selected Super strings using prefix, suffix, starting number and increment values. |
