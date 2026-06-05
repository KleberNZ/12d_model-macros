# Attribute_Value_Check

## Purpose

`Attribute_Value_Check.4dm` scans selected 12d elements and reports attribute values that match one or more user-defined tests.

The macro is intended for checking attribute values on:

- Drainage string node attributes
- Drainage string link attributes
- Super string vertex attributes
- Super string segment attributes
- Optional string / element attributes using `Get_attribute()`

Results are reported in a grouped `Log_Box`. Where a coordinate can be resolved, clicking a result line highlights / zooms to the matching node, vertex, or segment midpoint.

## Location

C:\12d\12dPL_Data\Code\Attribute_Value_Check

## Source

Attribute_Value_Check.4dm

## Compile Method

Open VS Code from:

C:\12d\12dPL_Data

Then open:

Code\Attribute_Value_Check\Attribute_Value_Check.4dm

Compile using:

Ctrl+Shift+P > 12dPL: Compile Current File

Do not use F7 unless the old task system has been deliberately updated.

## Include Setup

This macro uses clean includes:

```cpp
#include "standard_library.H"
#include "size_of.h"
```

These rely on the central workspace setting:

```text
12dpl.compiler.includePaths = C:\12d\includes
```

## Inputs

The macro uses a panel with:

### Data to test

A `Source_Box` used to select the 12d elements to scan.

### Attribute Tests grid

A `GridCtrl_Box` where each row defines one attribute test.

Columns:

| Column | Description |
|---|---|
| Target | Attribute location to test |
| Attribute Name | Exact 12d attribute name |
| Type | Attribute data type |
| Operation | Comparison operation |
| Test Value | Value to compare against |

Supported target choices:

| Target | Function family |
|---|---|
| Vertex / node attributes | `Get_drainage_pit_attribute()` for Drainage, `Get_super_vertex_attribute()` for Super strings |
| Segment / link attributes | `Get_drainage_pipe_attribute()` for Drainage, `Get_super_segment_attribute()` for Super strings |
| String / element attributes | `Get_attribute()` |

Supported data types:

- `real`
- `integer`
- `text`

Supported operations:

| Type | Operations |
|---|---|
| real | equal to, not equal to, less than, less than or equal to, greater than, greater than or equal to |
| integer | equal to, not equal to, less than, less than or equal to, greater than, greater than or equal to |
| text | equal to, not equal to, contains, does not contain |

Text `contains` / `does not contain` comparisons are case-insensitive.

## Outputs

The macro does not modify selected elements.

It writes matching results to the panel `Log_Box`.

Each flagged result reports:

- element name
- element type
- node / vertex, link / segment, or string / element target
- item index where applicable
- attribute value found
- comparison operation
- test value

For node / vertex and link / segment results, the log line attempts to provide highlight / zoom behaviour:

- Drainage node: highlights the drainage pit coordinate
- Drainage link: highlights the midpoint between adjacent pits
- Super vertex: highlights the super vertex coordinate
- Super segment: highlights the midpoint between adjacent super vertices
- String / element attribute: reports in the log; no specific coordinate highlight unless added later

## Notes

- Blank grid rows are skipped.
- Rows with blank attribute name or blank test value are rejected.
- Operations are validated against the selected attribute type.
- Drainage strings use drainage-specific pit and pipe attribute functions.
- Super strings use super string vertex and segment attribute functions.
- String / element attributes use `Get_attribute()`.
- For non-Drainage, non-Super elements, only string / element attribute tests are expected to be reliable.
- The macro reports flagged items only.
- No elements, models, or attributes are created, deleted, or modified.

## Revision History

| Version | Date | Notes |
|---|---|---|
| 001 | 2026-06-05 | Initial macro |
| 002 | 2026-06-05 | Documented GridCtrl_Box test workflow, Drainage/Super attribute handling, Log_Box output, and optional string / element attribute target |
