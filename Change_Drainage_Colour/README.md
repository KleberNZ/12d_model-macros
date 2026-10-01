# Change_Drainage_Colour

## Purpose

Bulk updates the display colours of drainage pits and pipes within selected drainage strings.

The macro allows a user to apply a new colour to drainage nodes (pits), drainage links (pipes), or both, across multiple drainage strings in a single operation. All changes are grouped into a single undo operation.

## Location

C:\12d\12dPL_Data\Code\Change_Drainage_Colour

## Source

Change_Drainage_Colour.4dm

## Compile Method

Open VS Code from:

C:\12d\12dPL_Data

Then open:

Code\Change_Drainage_Colour\Change_Drainage_Colour.4dm

Compile using:

Ctrl+Shift+P > 12dPL: Compile Current File

## Include Setup

```cpp
#include "standard_library.h"
#include "size_of.h"
```

## Category

Utilities

## Type

Drainage Display / Visualisation

## Author

KLP

## 12d Version

V15

## Current Version

001

## Inputs

### Drainage Strings

Select one or more drainage strings.

### Node Colour (Optional)

Colour to be applied to:

- Drainage pits
- Drainage nodes

### Link Colour (Optional)

Colour to be applied to:

- Drainage pipes
- Drainage links

At least one colour must be specified.

## Outputs

Updates the selected drainage strings by changing:

- Pit colours
- Pipe colours

The macro reports:

- Number of pits changed
- Number of pipes changed
- Number of undo records created
- Number of skipped drainage elements

## Workflow

1. Select one or more drainage strings.
2. Enter a node colour, a link colour, or both.
3. Select Process.
4. The macro scans each drainage string.
5. Pit colours are updated.
6. Pipe colours are updated.
7. Undo records are created.
8. All undo records are grouped into a single undo action.
9. A summary message is displayed.

## Main 12dPL Functions Demonstrated

### Drainage Functions

- Get_drainage_pits()
- Set_drainage_pit_colour()
- Set_drainage_pipe_colour()

### Selection Functions

- Create_source_box()
- Validate()
- Get_number_of_items()

### Element Functions

- Element_duplicate()
- Get_item()
- Set_model()

### Undo Functions

- Add_undo_change()
- Add_undo_list()

### Panel Functions

- Create_panel()
- Create_colour_box()
- Create_button()
- Wait_on_widgets()

## Undo Support

The macro creates:

- Individual undo records for each modified drainage string.
- A grouped undo action named:

```text
Change drainage colours
```

allowing all colour changes to be rolled back in a single undo operation.

## Notes

- Node and link colours can be changed independently.
- A colour is only applied when the corresponding colour box contains a value.
- Drainage strings without valid drainage pit information are skipped.
- The macro modifies display properties only and does not alter hydraulic or drainage attributes.

## Limitations

- Works only on drainage strings.
- Requires at least one pit within the string.
- Colours are applied to all pits or all pipes within the selected drainage string.
- Does not support filtering by pit type, pipe size, network or attribute values.

## Keywords

Drainage, colour, display, visualisation, pit colour, pipe colour, node colour, link colour, drainage styling, bulk update, utilities

## Related Macros

- ACCoP_SW_Check
- ACCoP_WW_Check
- Drainage_Updater

## Revision History

| Version | Date | Notes |
|---|---|---|
| 001 | 22/07/2026 | Initial version. Bulk updates drainage pit and pipe colours with grouped undo support. |
