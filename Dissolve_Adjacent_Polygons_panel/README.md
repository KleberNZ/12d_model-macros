# Dissolve_Adjacent_Polygons_panel

## Purpose

Dissolves adjacent closed Super-string polygons using canonical graph-based noding and shared-edge cancellation.

The macro validates the selected polygons, detects native line and arc intersections, virtually splits boundaries at canonical nodes, removes duplicated internal edges and traces the remaining external boundary. One dissolved Super string is created for each connected polygon component.

## Location

C:\12d\12dPL_Data\Code\Dissolve_Adjacent_Polygons_panel

## Source

Dissolve_Adjacent_Polygons_Dynamic_Graph.4dm

## Compile Method

Open VS Code from:

C:\12d\12dPL_Data

Then open:

Code\Dissolve_Adjacent_Polygons_panel\Dissolve_Adjacent_Polygons_Dynamic_Graph.4dm

Compile using:

Ctrl+Shift+P > 12dPL: Compile Current File

## Include Setup

```cpp
#include "standard_library.h"
#include "size_of.h"
```

## Category

Geometry

## Type

Polygon Dissolve / Topology Processing

## Author

Kleber Lessa do Prado

## 12d Version

V15+

## Current Version

0.3.000

## Build

```text
$2.0.003-PROTOTYPE
```

## Inputs

### Closed Super Polygons

Select one or more polygon elements.

Each selected element must be:

- A Super string
- Closed
- Free from self-intersections
- Composed of at least three segments
- Free from embedded Super-string holes

### Output Model

Select or create the model for the dissolved polygon outputs.

### XY Node Tolerance

Defines the tolerance used to create canonical XY nodes and compare arc geometry.

Default:

```text
0.001 m
```

### Delete Originals After Success

Optional setting that deletes the selected source polygons only after all dissolved outputs have been created successfully.

## Outputs

Creates one dissolved closed Super string for each connected polygon component.

Output names follow this convention:

```text
Merged dynamic graph coverage 1
Merged dynamic graph coverage 2
```

The completion message reports:

- Merged polygons created
- Canonical nodes registered
- Physical graph edges created
- Shared edges cancelled

## Supported Geometry

- Closed Super-string polygons
- Straight segments
- Circular arc segments
- Adjacent polygon coverages
- Multiple connected components
- Differently segmented shared boundaries where canonical noding resolves the coincident pieces

The macro preserves:

- Vertex Z values interpolated along split source segments
- Signed arc radius
- Arc major flags
- Native line and circular arc geometry

## Processing Workflow

1. Validate every selected polygon.
2. Register all original component endpoints in a canonical XY node registry.
3. Detect native line and arc intersections using `Intersect()`.
4. Reattach all canonical nodes to each source component.
5. Sort the node parameters along each source segment.
6. Virtually split source boundaries into physical graph edges.
7. Identify duplicate physical edges and cancel shared internal boundaries.
8. Use union-find logic to identify connected polygon components.
9. Trace the active exterior edge ring for each connected component.
10. Create and validate the dissolved Super strings.
11. Add the results to the output model.
12. Optionally delete the original polygons.
13. Register all changes as one grouped undo operation.

## Topology Method

### Canonical Nodes

Endpoints and detected intersections within the XY tolerance are assigned to a common node.

### Virtual Noding

Each source line or arc is split at all canonical nodes lying on the native component. Source polygons are not changed during this stage.

### Physical Edge Matching

Noded pieces are normalised into a canonical endpoint order. Line pieces are matched by endpoints. Arc pieces additionally require matching:

- Absolute radius
- Major flag
- Arc centre

### Shared-Edge Cancellation

A physical edge with two polygon owners is treated as an internal shared boundary and excluded from the final exterior ring.

A physical edge with more than two owners is rejected as duplicate or overlapping coverage.

### Exterior Ring Tracing

The remaining single-owner edges are traced into one closed ring for each union-find component. Open, branching or multi-ring components are rejected.

## Main 12dPL Functions Demonstrated

### Polygon Validation

- `Get_type()`
- `String_closed()`
- `String_self_intersects()`
- `Get_super_use_hole()`
- `Get_super_holes()`
- `Get_segments()`

### Native Geometry

- `Get_segment()`
- `Get_start()`
- `Get_end()`
- `Get_arc()`
- `Get_centre()`
- `Get_radius()`
- `Intersect()`

### Super-String Creation

- `Create_super()`
- `Set_super_use_3d_level()`
- `Set_super_use_segment_radius()`
- `Set_super_data()`
- `String_close()`
- `Calc_extent()`
- `Element_draw()`

### Dynamic Containers and Graph Processing

- `Dynamic_Real`
- `Dynamic_Integer`
- `Dynamic_Element`
- `Get_item()`
- `Set_item()`
- `Get_number_of_items()`

### Undo and Model Updates

- `Add_undo_add()`
- `Add_undo_delete()`
- `Add_undo_list()`
- `Set_model()`
- `Element_delete()`
- `Model_draw()`

## Error Conditions

Processing stops when the macro detects conditions including:

- A non-Super input element
- An open polygon
- A self-intersecting polygon
- A polygon containing holes
- A zero-length XY segment
- Failure to retain both endpoints during noding
- A physical edge owned by more than two polygons
- A graph component with no external boundary
- An exterior graph that is open or branches
- A component producing more than one exterior ring
- A traced result that is open or self-intersecting

## Undo Support

The macro creates a grouped undo action named:

```text
Dissolve Dynamic Graph Adjacent Super Polygons
```

The undo group includes:

- Addition of all dissolved output polygons
- Deletion of source polygons when the delete option is enabled

## Notes

- XY geometry controls the topology.
- The XY node tolerance is also applied as the arc tolerance.
- Each connected polygon group produces a separate output polygon.
- Source polygons remain unchanged unless deletion is explicitly selected.
- Original polygons are deleted only after all result polygons have been created successfully.
- The macro is identified in the panel and build definition as a dynamic graph prototype.

## Limitations

- Holes are not supported.
- Containment-only unions are not supported.
- Arbitrary polygon overlap is not supported.
- Components producing more than one exterior ring are rejected.
- Correct results depend on a suitable node tolerance for the source data accuracy.
- General polygon Boolean operations are outside the implemented scope.

## Keywords

12d Model, 12dPL, dissolve polygons, adjacent polygons, Super strings, polygon union, topology graph, canonical noding, shared-edge cancellation, line intersection, arc intersection, graph edges, union-find, exterior boundary, connected components, geometry processing

## Related Macros

- Polygon_Topology_Builder
- Create_Catchments_From_LC_panel

## Revision History

| Version | Date | Notes |
|---|---|---|
| 0.3.000 | 28/09/2026 | Dynamic graph prototype using canonical intersection noding, physical-edge matching, shared-edge cancellation and exterior-ring tracing for lines and circular arcs. |
