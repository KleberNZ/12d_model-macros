# Drainage_Set_Design_Grade_By_Self_Cleaning_Flow

## Purpose

Sets the drainage pipe attribute **design grade** based on pipe diameter and the calculated self-cleaning flow stored in each pipe.

The macro applies Watercare minimum grade requirements using the pipe attribute:

```text
Self-cleaning/pipe flow
```

and writes the calculated minimum grade (%) into:

```text
design grade
```

The macro does not modify pipe inverts or pipe geometry.

## Location

C:\12d\12dPL_Data\Code\Drainage_Set_Design_Grade_By_Self_Cleaning_Flow

## Source

Drainage_Set_Design_Grade_By_Self_Cleaning_Flow.4dm

## Compile Method

Open VS Code from:

C:\12d\12dPL_Data

Then open:

Code\Drainage_Set_Design_Grade_By_Self_Cleaning_Flow\Drainage_Set_Design_Grade_By_Self_Cleaning_Flow.4dm

Compile using:

Ctrl+Shift+P > 12dPL: Compile Current File

## Include Setup

```cpp
#include "standard_library.H"
#include "size_of.H"
```

## Category

Drainage

## Type

Drainage Design Automation

## Author

KLP

## 12d Version

V15

## Current Version

002

## Inputs

### Drainage Model

Select a drainage model containing drainage strings.

### Required Pipe Attributes

Each pipe must contain:

```text
nominal diameter
Self-cleaning/pipe flow
```

The calculated grade is written to:

```text
design grade
```

## Outputs

Updates the pipe attribute:

```text
design grade
```

for all supported drainage pipes.

The Output Window reports:

- Pipe name
- Nominal diameter
- Self-cleaning flow
- Assigned design grade

The panel summary reports:

- Pipes updated
- Non-drainage elements skipped

## Watercare Grade Rules Implemented

### DN150

| Self-Cleaning Flow | Design Grade |
|---|---|
| < 0.375 L/s | 1.00% |
| 0.375 to < 3.75 L/s | 0.75% |
| ≥ 3.75 L/s | 0.75% |

### DN225

| Design Grade |
|---|
| 0.45% |

### DN300

| Design Grade |
|---|
| 0.30% |

### Other Pipe Sizes

Unsupported diameters are skipped.

## Workflow

1. Select a drainage model.
2. Select Process.
3. The model is scanned for drainage strings.
4. Each drainage pipe is evaluated.
5. The nominal diameter is read.
6. The self-cleaning flow is read.
7. The required design grade is calculated.
8. The design grade attribute is updated.
9. Results are written to the Output Window.
10. A summary message is displayed.

## Main 12dPL Functions Demonstrated

### Drainage Functions

- `Get_drainage_pipe_attribute()`
- `Get_drainage_pipe_attributes()`
- `Set_drainage_pipe_attributes()`

### Attribute Functions

- `Set_attribute()`

### Model Functions

- `Get_elements()`
- `Get_type()`

### Panel Functions

- `Create_panel()`
- `Create_model_box()`
- `Validate()`
- `Wait_on_widgets()`

## Notes

- Designed to support Watercare wastewater design workflows.
- Updates only the design-grade attribute.
- Pipe geometry and invert levels are not modified.
- Intended to be used before pipe regrading.

## Recommended Follow-Up

After updating design grades, regrade the network using:

```text
WNE → Regrade Links
```

so pipe inverts are adjusted to match the calculated design grades.

## Limitations

- Supports DN150, DN225 and DN300 only.
- Requires valid self-cleaning flow values.
- Does not calculate self-cleaning flows.
- Does not modify pipe levels.
- Unsupported diameters are ignored.

## Keywords

Drainage, Watercare, wastewater, self-cleaning flow, design grade, minimum grade, regrade links, DN150, DN225, DN300, pipe design, drainage automation

## Related Macros

- Drainage_Network_Framework
- ACCoP_WW_Check
- Drainage_Updater

## Revision History

| Version | Date | Notes |
|---|---|---|
| 002 | 12/02/2026 | Applies Watercare self-cleaning flow rules and populates drainage pipe design-grade attributes. |
