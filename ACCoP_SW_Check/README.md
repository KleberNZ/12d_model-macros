# ACCoP_SW_Check

## Purpose

Performs automated quality assurance checks on a stormwater drainage network against the Auckland Council Code of Practice (ACCoP).

The macro traverses a 12d drainage network and evaluates pits, pipes and network relationships for compliance with stormwater design requirements. Results are presented in an interactive report panel with highlighted pits and clause-specific error messages.

The macro is intended as a drainage design review tool to identify non-compliant network elements before design issue.

## Location

C:\12d\12dPL_Data\Code\ACCoP_SW_Check

## Source

ACCoP_SW_Check.4dm

## Compile Method

Open VS Code from:

C:\12d\12dPL_Data

Then open:

Code\ACCoP_SW_Check\ACCoP_SW_Check.4dm

Compile using:

Ctrl+Shift+P > 12dPL: Compile Current File

Do not use F7 unless the old task system has been deliberately updated.

## Include Setup

This macro uses clean includes:

```cpp
#include "standard_library.h"
#include "size_of.h"
```

These rely on the central workspace setting:

```text
12dpl.compiler.includePaths = C:\12d\includes
```

## Category

Drainage

## Type

Drainage QA / Compliance Checking

## Author

Kleber Lessa do Prado

## Company

The Neil Group

## 12d Version

12d Model V15

## Current Version

007

## Inputs

- A 12d drainage model containing a valid drainage network.
- Stormwater pipe strings.
- Pits and drainage attributes created using standard 12d drainage functionality.
- Pipe and pit attributes including:
  - Pipe diameters
  - Pipe grades
  - Invert levels
  - Pit depths
  - Pit HGLs
  - Pit diameters
  - Deflection values

## Outputs

Produces a detailed compliance report in the panel log window.

Outputs include:

- Highlight links to non-compliant pits.
- CoP clause references.
- Error messages.
- Warning messages.
- Network statistics summary.

Checks include:

### Pit Checks

- Pit depth
- Pit diameter
- Pit sizing requirements
- SW05 manhole sizing
- SW07 manhole requirements
- Specific design requirements

### Pipe Checks

- Nominal diameter
- Internal diameter
- Grade
- Deflection
- Invert levels
- Internal falls

### Hydraulic Checks

- Pipe surcharging
- Internal fall requirements
- Open cascade limitations
- Grade restrictions
- Drop limits

### Network Relationship Checks

- Same-string upstream pipes
- Cross-string incoming pipes
- Downstream pipes
- Pit-to-pipe relationships

## Auckland Council CoP Rules Checked

The macro includes automated checks associated with:

- CoP 4.3.5.3
- CoP 4.3.10
- CoP 4.3.10.3
- CoP 4.3.10.6
- CoP 4.3.10.7
- SW05 Manhole Sizing
- SW07 Manhole Requirements

Checks include:

- Maximum allowable deflection
- Maximum pit drop
- Minimum internal falls
- Maximum internal falls
- Pit sizing requirements
- Steep grade restrictions
- Surcharging conditions
- Special design triggers

## Workflow

1. Open the ACCoP Stormwater QA Check panel.
2. Select the drainage model.
3. Select **Process**.
4. The drainage network is traversed.
5. Each pit becomes the current analysis location.
6. Upstream and downstream relationships are identified.
7. Compliance checks are executed.
8. Results are written to the report window.
9. Review highlighted pits and reported CoP issues.

## Main 12dPL Functions Demonstrated

### Drainage Network Functions

- `Get_drainage_network()`
- `Get_drainage_network_pits()`
- `Get_drainage_network_pipes()`
- `Get_drainage_network_pipe()`
- `Get_drainage_network_pit()`

### Pit Functions

- `Get_drainage_pit()`
- `Get_drainage_pit_name()`
- `Get_drainage_pit_attribute()`
- `Get_drainage_pit_hgl()`

### Pipe Functions

- `Get_drainage_pipe_nominal_diameter()`
- `Get_drainage_pipe_grade()`
- `Get_drainage_pipe_attribute()`

### Reporting Functions

- `Create_log_box()`
- `Create_group_log_line()`
- `Create_text_log_line()`
- `Create_highlight_point_log_line()`

### Panel Functions

- `Create_panel()`
- `Create_model_box()`
- `Create_button()`
- `Wait_on_widgets()`

## Notes

- Designed for stormwater networks.
- Assumes drainage data has been processed and the required attributes are available.
- Uses drainage network relationships rather than relying only on string ordering.
- Checks both same-string and cross-string pipe connections.
- Includes tolerance handling for drops and deflections.
- Generates an interactive report with pan-to-pit functionality.
- Intended as a QA review tool and does not modify the model.

## Limitations

- Relies on drainage attributes existing and being correctly populated.
- Requires a valid drainage network object.
- SW05 sizes for DN 225, DN 300, DN 375 and DN 675 are identified in the source as preliminary guidance and require confirmation through geometry, structural, access and constructability checks.
- Does not automatically correct non-compliant items.
- Reports warnings and errors only.

## Keywords

Drainage QA, ACCoP, Auckland Council, stormwater, SW05, SW07, manhole sizing, internal fall, deflection, surcharge, pit checks, pipe checks, compliance review, drainage network, quality assurance

## Related Macros

- Drainage_Updater
- Drainage_Network_Framework
- Drainage_Set_Design_Grade_By_Self_Cleaning_Flow
- Create_Catchments_From_LC_panel

## Revision History

| Version | Date | Notes |
|---|---|---|
| 007 | 17/09/2025 | Current source version. Includes drainage-network traversal, SW05 sizing checks, SW07 checks, internal-fall validation, surcharge checks, relationship-based QA reporting and canonical pit analysis. |
