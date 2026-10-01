# Set_CoverRL_to_Manual

## Purpose

Sets the drainage pit attribute `cover rl mode` to `2` for every pit within every drainage string in a selected model.

This is a bulk-update utility for drainage networks where pit cover RL control must be set to manual mode.

## Location

C:\12d\12dPL_Data\Code\Set_CoverRL_to_Manual

## Source

Set_CoverRL_Mode_Manual_ID1961.4dm

## Compile Method

Open VS Code from:

C:\12d\12dPL_Data

Then open:

Code\Set_CoverRL_to_Manual\Set_CoverRL_Mode_Manual_ID1961.4dm

Compile using:

Ctrl+Shift+P > 12dPL: Compile Current File

## Include Setup

```cpp
#include "standard_library.H"
#include "size_of.H"
#include "set_ups.h"
```

## Category

Drainage

## Type

Drainage Attribute Utility

## Author

ChatGPT

## 12d Version

V15

## Current Version

001

## Build

```text
version.0.001
```

## Inputs

### Model

Select an existing model containing drainage strings.

Requirements:

- The model must exist.
- The model must contain elements.
- Drainage strings must exist within the model for any pits to be updated.

## Outputs

Updates this attribute on every pit in each drainage string:

```text
cover rl mode = 2
```

No new geometry is created.

The macro reports:

- Models processed
- Drainage strings processed
- Pit attributes successfully set

## Workflow

1. Select an existing model.
2. Select **Run**.
3. The macro validates that the model exists and is not empty.
4. All model elements are retrieved.
5. Elements whose type is `Drainage` are processed.
6. The number of pits in each drainage string is retrieved.
7. `cover rl mode` is set to `2` for every pit index.
8. A model-level result is displayed and printed.
9. A cumulative summary is printed when the panel closes.

## Main 12dPL Functions Demonstrated

### Model Functions

- `Create_model_box()`
- `Model_exists()`
- `Get_elements()`
- `Get_number_of_items()`

### Element Functions

- `Get_item()`
- `Get_type()`

### Drainage Functions

- `Get_drainage_pits()`
- `Set_drainage_pit_attribute()`

### Panel Functions

- `Create_panel()`
- `Create_message_box()`
- `Create_button()`
- `Create_finish_button()`
- `Wait_on_widgets()`
- `Validate()`

## Reporting

After each run, the panel and Output Window report:

```text
Model processed. Drainage strings: <count>, Pit attributes set: <count>
```

When the macro closes, the Output Window reports cumulative totals for:

- Models processed
- Drainage strings
- Pit attributes set

## Notes

- All drainage strings in the selected model are processed.
- Existing cover RL values are not changed directly.
- Only the `cover rl mode` attribute is updated.
- Non-drainage elements are ignored.
- The source grants unrestricted reproduction, modification, compilation and reuse.

## Limitations

- No undo records are created.
- The assigned attribute value is fixed at `2`.
- There is no filtering by drainage network, pit type or pit attribute.
- Individual failed attribute updates are not reported separately.
- The build definition uses `version.0.001`, rather than a standard V15 build identifier.

## Keywords

12d Model, 12dPL, drainage, pit attribute, cover RL, manual cover level, cover rl mode, drainage strings, bulk update, drainage network, utility macro

## Related Macros

- Drainage_Set_Design_Grade_By_Self_Cleaning_Flow
- Drainage_Network_Framework
- ACCoP_SW_Check
- ACCoP_WW_Check

## Revision History

| Version | Date | Notes |
|---|---|---|
| 001 | 08/09/2025 | Initial version. Sets `cover rl mode` to `2` for all pits in every drainage string in the selected model. |
