# Drainage_Network_Framework

## Purpose

Provides a reusable, read-only framework for traversing a 12d Model drainage network and classifying every pipe directly connected to each canonical network pit.

The framework separates network traversal from check-specific or edit-specific logic. Developers can retain the established traversal and relationship-classification code while adding project-specific processing within dedicated hook functions.

## Location

C:\12d\12dPL_Data\Code\Drainage_Network_Framework

## Source

Drainage_Network_Framework.4dm

## Compile Method

Open VS Code from:

C:\12d\12dPL_Data

Then open:

Code\Drainage_Network_Framework\Drainage_Network_Framework.4dm

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

Reusable Drainage-Network Traversal Framework

## Author

KLP

## 12d Version

V15

## Current Version

001

## Build

```text
15.0.001
```

## Inputs

### Drainage Model

Select one existing 12d model containing a drainage network.

The macro validates that the selected model exists before attempting traversal.

## Outputs

The base framework does not edit drainage elements or create new geometry.

It:

- Builds the selected model's `Drainage_Network`.
- Enumerates canonical network pits and pipes.
- Resolves each canonical pit to its owning drainage string and pit index.
- Identifies directly connected pipes.
- Classifies each connected pipe by relationship.
- Calls the appropriate processing hook.
- Reports completion or failure in the panel message box.

When relationship debugging is enabled, the macro also writes detailed pit, pipe, relationship and network-summary information to the 12d Output Window.

## Pipe Relationship Classification

For each canonical network pit, connected pipes are classified as follows.

### Same-String Upstream Pipe

A pipe is classified as the normal same-string upstream pipe when:

- The pipe's downstream network pit ID matches the current network pit ID.
- The pipe belongs to the same drainage string as the current pit.
- The pipe index matches the current pit index.

### Cross-String Incoming Pipe

A pipe is classified as a cross-string incoming pipe when:

- The pipe's downstream network pit ID matches the current network pit ID.
- It does not meet the same-string upstream criteria.

This captures incoming branches from other drainage strings.

### Downstream Pipe

A pipe is classified as downstream when its upstream network pit ID matches the current network pit ID.

## Processing Hooks

Project-specific logic belongs in these functions:

```cpp
Process_current_pit()
Process_same_string_upstream_pipe()
Process_cross_string_incoming_pipe()
Process_downstream_pipe()
```

The supplied version leaves each hook body empty so the framework can be adapted for:

- Drainage QA checks
- Attribute reporting
- Network auditing
- Hydraulic relationship checks
- Controlled drainage edits

The traversal and classification logic should remain unchanged unless the network relationship model itself needs revision.

## Workflow

1. Run the `Drainage Network Framework` macro.
2. Select an existing drainage model.
3. Select **Process**.
4. The macro creates the model's drainage-network representation.
5. Network pit and pipe counts are retrieved.
6. Every canonical network pit is resolved to an owning drainage string and pit index.
7. Every network pipe is tested against the current pit.
8. Directly connected pipes are classified as same-string upstream, cross-string incoming or downstream.
9. The corresponding processing hooks are called.
10. The panel reports whether traversal completed successfully.

## Debugging

Relationship debugging is controlled by:

```cpp
#define DEBUG_NETWORK_RELATIONSHIPS 0
```

Set the value to `1` to print:

- Model name
- Current pit string, index, name and network ID
- Same-string upstream pipes
- Cross-string incoming pipes
- Downstream pipes
- Relationship counts for each pit
- Total network pit and pipe counts

## Main 12dPL Functions Demonstrated

### Drainage-Network Functions

- `Get_drainage_network()`
- `Get_drainage_network_number_of_pits()`
- `Get_drainage_network_number_of_pipes()`
- `Get_drainage_network_pits()`
- `Get_drainage_network_pipes()`
- `Get_drainage_network_pit()`
- `Get_drainage_network_pipe()`

### Drainage-Element Functions

- `Get_drainage_pit_name()`
- `Get_id()`
- `Get_name()`

### Panel and Validation Functions

- `Create_panel()`
- `Create_model_box()`
- `Create_colour_message_box()`
- `Create_button()`
- `Validate()`
- `Wait_on_widgets()`

### Output and Resource Handling

- `Print()`
- `To_text()`
- `Null()`

## Error Handling

The framework reports or handles conditions including:

- Failure to create the drainage network
- Failure to retrieve network pit or pipe counts
- Failure to enumerate network pits or pipes
- Network containing no pits
- Network containing no pipes
- Failure to resolve an individual network pit
- Failure to retrieve a pit's owning string UID
- Invalid or missing drainage model selection

An individual unresolved pit is reported as a warning and skipped. Core network-enumeration failures stop traversal and return the relevant error code.

## Notes

- The base framework is read-only.
- Canonical network relationships are determined using network pit IDs rather than relying only on drainage-string sequence.
- Multiple incoming pipes are supported.
- A pit may have a same-string upstream pipe and one or more cross-string incoming pipes.
- Pipe and pit objects are released with `Null()` after processing.
- The source grants unrestricted reproduction, modification and use.

## Limitations

- The selected model must produce a valid 12d drainage network.
- The base hook functions perform no checks or edits until customised.
- The implementation scans the complete pipe list for each pit.
- Relationship debug output is disabled by default.
- Any edit logic added to the hooks must independently implement validation, undo support and failure handling.

## Keywords

12d Model, 12dPL, drainage network, network traversal, canonical pit, network pit ID, network pipe ID, same-string upstream pipe, cross-string incoming pipe, downstream pipe, drainage relationships, QA framework, reusable macro, stormwater, wastewater

## Related Macros

- ACCoP_SW_Check
- ACCoP_WW_Check
- Drainage_Updater
- Change_Drainage_Colour

## Revision History

| Version | Date | Notes |
|---|---|---|
| 001 | 27/07/2026 | Initial reusable framework for canonical network-pit traversal and classification of same-string upstream, cross-string incoming and downstream pipes. |
