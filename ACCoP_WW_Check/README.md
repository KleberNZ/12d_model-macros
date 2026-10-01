# ACCoP_WW_Check

## Purpose

Performs automated quality assurance checks on a wastewater drainage network against the Auckland Watercare Code of Practice requirements implemented in the source macro.

The macro traverses the selected 12d drainage network, resolves each canonical pit and its directly connected upstream and downstream pipes, and reports clause-specific compliance issues. Results are displayed in an interactive report panel with a pan-to-pit link for each resolved pit.

## Location

C:\12d\12dPL_Data\Code\ACCoP_WW_Check

## Source

ACCoP_WW_Check.4dm

## Compile Method

Open VS Code from:

C:\12d\12dPL_Data

Then open:

Code\ACCoP_WW_Check\ACCoP_WW_Check.4dm

Compile using:

Ctrl+Shift+P > 12dPL: Compile Current File

Do not use F7 unless the old task system has been deliberately updated.

## Include Setup

This macro uses clean includes:

```cpp
#include "standard_library.H"
#include "size_of.H"
```

These rely on the central workspace setting:

```text
12dpl.compiler.includePaths = C:\12d\includes
```

## Category

Drainage

## Type

Wastewater Drainage QA / Compliance Checking

## Author

Kleber Lessa do Prado

## Company

The Neil Group

## 12d Version

12d Model V15 build target `V15.0.001`.

Note: The source header contains the placeholder text `Vversion`, but the build definition targets V15.

## Current Version

002

## Inputs

- A selected 12d model containing a valid wastewater drainage network.
- Network pits and pipes accessible through the 12d drainage network API.
- Required pit information and attributes, where available:
  - Pit name
  - Pit coordinates
  - Pit depth
  - Hydraulic grade line
  - Sump level
  - `lplot Nominal Diameter`
- Required pipe information and attributes, where available:
  - Pipe name
  - Nominal diameter
  - Calculated pipe grade
  - Calculated downstream deflection
  - Upstream and downstream invert levels
  - Calculated pipe length

## Outputs

The macro does not modify drainage geometry or attributes. It produces:

- An `ACCoP Wastewater Report` in the panel log box.
- A grouped report for each canonical pit.
- A `Pan to Pit` highlight link when pit coordinates are available.
- Clause-specific errors and informational messages.
- `CoP Check = OK` for pits without a reported error.
- A completion summary showing:
  - Canonical pits processed
  - Same-string upstream pipes
  - Cross-string incoming pipes
  - Flagged upstream relationships
  - Downstream pipes
  - Downstream length failures
  - Flagged pits
  - Pits with missing depth data

## Compliance Checks Implemented

### Pipe Grade and Bedding

- Reports an error when pipe grade is from 10% to less than 20%, identifying the requirement for minimum 7 MPa scoria-concrete bedding under WW CoP 5.3.7.11.
- Reports an informational message when pipe grade is 20% or greater, identifying the requirement for anchor blocks at 6 m spacing under WW CoP 5.3.7.11.

### Maximum Pipe Length

- Reports an error when the calculated downstream pipe length exceeds 100 m under WW CoP 5.3.8.3.

### Minimum Manhole Diameter

The source applies these minimum nominal diameters under WW CoP 5.3.8.4:

- 1050 mm for pit depth below 3.0 m.
- 1200 mm for pit depth from 3.0 m to 6.0 m.
- 1500 mm for pit depth greater than 6.0 m.
- A minimum of 1200 mm where the calculated internal fall exceeds 0.15 m.

The terminal blank-cap case is skipped when there is no downstream pipe and the nominated pit diameter is zero or less.

### Minimum Internal Fall

The source calculates the minimum internal fall as follows:

- When the downstream pipe is larger than the upstream pipe, the minimum fall is the nominal diameter difference converted to metres.
- For equal-sized pipes or a smaller downstream pipe:
  - Up to 30 degrees deflection: 0.03 m.
  - Greater than 30 degrees and up to 60 degrees: 0.05 m.
  - Greater than 60 degrees: 0.08 m.

A 0.005 m tolerance is applied to drop comparisons.

### Steep-Grade Rules

For incoming pipe grades greater than 7%, the source checks:

- DN 225 or smaller requires pit depth greater than 1.5 m.
- DN 300 or larger requires pit depth greater than 2.0 m.
- Pipe deflection must not exceed 45 degrees.
- The internal fall must not exceed the incoming nominal pipe diameter converted to metres; otherwise an internal dropper is reported as required.

### Network Relationships

The macro distinguishes and checks:

- Same-string upstream pipes.
- Cross-string incoming pipes.
- Downstream pipes.
- Terminal pits using the pit sump level when no downstream pipe invert is available.

## Workflow

1. Run the `ACCoP Wastewater QA Check` macro.
2. Select an existing wastewater drainage model.
3. Select **Process**.
4. The macro obtains and traverses the model's drainage network.
5. For each canonical pit, the downstream pipe is resolved first to establish outlet diameter, invert and length context.
6. All directly incoming pipes are then classified as same-string or cross-string connections.
7. The wastewater compliance checks are applied.
8. Review the grouped report and use `Pan to Pit` to inspect flagged locations.

## Main 12dPL Functions Demonstrated

### Drainage Network Functions

- `Get_drainage_network()`
- `Get_drainage_network_number_of_pits()`
- `Get_drainage_network_number_of_pipes()`
- `Get_drainage_network_pits()`
- `Get_drainage_network_pipes()`
- `Get_drainage_network_pit()`
- `Get_drainage_network_pipe()`

### Pit Functions

- `Get_drainage_pit()`
- `Get_drainage_pit_name()`
- `Get_drainage_pit_attribute()`
- `Get_drainage_pit_hgl()`

### Pipe Functions

- `Get_drainage_pipe_nominal_diameter()`
- `Get_drainage_pipe_attribute()`

### Reporting Functions

- `Create_log_box()`
- `Create_group_log_line()`
- `Create_text_log_line()`
- `Create_highlight_point_log_line()`
- `Add_log_line()`
- `Append_log_line()`

### Panel Functions

- `Create_panel()`
- `Create_model_box()`
- `Create_colour_message_box()`
- `Create_button()`
- `Wait_on_widgets()`
- `Validate()`

## Notes

- The macro analyses network relationships rather than relying only on drainage-string order.
- The downstream pipe is resolved before upstream checks so outlet diameter and invert data are available for internal-fall calculations.
- Both same-string and cross-string incoming pipes are assessed.
- Missing attributes do not automatically generate a dedicated compliance error in every case. Checks requiring unavailable data are not completed.
- Debug output can be enabled by changing `DEBUG_NETWORK_RELATIONSHIPS` from `0` to `1` in the source.
- The source grants unrestricted reproduction, modification, compilation and reuse, including incorporation into other macros or programs.

## Limitations

- Requires a valid 12d drainage network in the selected model.
- Depends on the required drainage attributes being present and correctly populated.
- Does not automatically correct non-compliant pits or pipes.
- It reports the 20% or greater anchor-block requirement as information rather than as a failed check.
- The minimum-drop helper returns 0.08 m for all deflections greater than 60 degrees; the source comment describes that band as greater than 60 degrees to 120 degrees, but no separate upper-angle rejection is implemented in this helper.
- For terminal pits, internal fall may be assessed against the pit sump level when no downstream pipe invert is available.

## Keywords

Wastewater, Watercare, Auckland, Code of Practice, drainage QA, compliance checking, pipe grade, scoria-concrete bedding, anchor blocks, manhole spacing, pipe length, manhole diameter, internal fall, steep grade, deflection, drainage network, same-string upstream, cross-string incoming, 12dPL, 12d Model

## Related Macros

- ACCoP_SW_Check
- Drainage_Updater
- Drainage_Network_Framework
- Drainage_Set_Design_Grade_By_Self_Cleaning_Flow

## Revision History

| Version | Date | Notes |
|---|---|---|
| 002 | 17/09/2025 | Current source version. Implements wastewater network traversal, connection classification, pipe-grade requirements, maximum 100 m pipe length, minimum manhole sizing, internal-fall checks, steep-grade checks and grouped pit reporting. |
