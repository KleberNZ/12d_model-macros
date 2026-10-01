# Polygon_Topology_Builder_panel

## Purpose

Builds production polygon topology from a closed site boundary and selected internal Super strings.

The macro nodes intersecting line and arc components, repairs eligible line undershoots, prunes dangling edges, removes graph bridges from polygon-forming topology, traces bounded faces, filters faces to the site boundary, and creates final closed Super-string polygons while preserving native circular arcs.

## Location

C:\12d\12dPL_Data\Code\Polygon_Topology_Builder_panel

## Source

polygon_topology_PRODUCTION.4dm

## Compile Method

Open VS Code from:

C:\12d\12dPL_Data

Then open:

Code\Polygon_Topology_Builder_panel\polygon_topology_PRODUCTION.4dm

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

Polygon Topology / Planar Graph Processing

## Author

Kleber Lessa do Prado / Microsoft 365 Copilot

## 12d Version

V15+

## Current Version

028

## Build

```text
$2.0.035
```

## Inputs

### Site Boundary

Select one closed site-boundary Super string.

The site boundary is included in the topology graph and is also linearised for point-in-polygon filtering of candidate faces.

### Topology Source

Select one or more internal Super strings.

The source geometry may contain:

- Open or closed Super strings
- Straight segments
- Native circular arcs
- Intersections
- Eligible short line undershoots
- Dangling branches
- Disconnected enclosed components

### Output Model

Select or create the model for the final topology polygons.

### Output Z Level

Level assigned to all vertices of the generated polygons.

Default:

```text
0.0 m
```

### Node Tolerance

XY tolerance used when canonicalising nodes and testing whether points lie on source components.

Default:

```text
0.001 m
```

### Arc Working Tolerance

Used when linearising the site boundary for point-in-polygon operations.

Default:

```text
0.001 m
```

### Minimum Segment Length

Noded line or arc pieces shorter than this value are excluded from the physical graph.

Default:

```text
0.001 m
```

### Minimum Face Area

Panel input intended to control the minimum accepted face area.

Default:

```text
0.001 m²
```

### Maximum Undershoot Extension

Maximum permitted extension distance for repairing an eligible degree-1 native line endpoint.

Default:

```text
0.050 m
```

Set this value to `0.0` to disable undershoot repair.

## Outputs

Creates closed Super-string polygons in the selected output model.

Output names use the face record and topology class:

```text
FACE_<ID>_ROOT_SHELL
FACE_<ID>_ISLAND_DEPTH_<DEPTH>
```

The completed output can include:

- Independent bounded-face polygons
- Polygons containing internal holes
- Island polygons at even containment depths
- Native line and circular-arc segments
- Inherited segment colours
- An inherited string weight, preferring an internal source edge where available

## Processing Architecture

### 1. Input Validation

The macro validates positive tolerances, non-negative thresholds, the selected site boundary, internal source collection and output model.

### 2. Canonical Node Registration

All original component endpoints are registered in a global XY canonical-node list using the node tolerance.

### 3. Native Intersection Noding

The macro calls:

```cpp
Intersect(Segment, Segment, ...)
```

on native line and arc segments.

Additional native-geometry checks confirm that each returned intersection lies on both finite components before the point is added to the canonical node registry.

### 4. Global Node Reattachment and Splitting

After the complete node registry is available, every canonical node is tested against every source component. Each line or arc is virtually split at its sorted component parameters.

The resulting physical graph pieces retain:

- Canonical endpoint nodes
- Source element and component references
- Line or arc classification
- Signed radius
- Arc major flag
- Segment colour
- Element weight
- Arc centre coordinates

### 5. Degree-1 Line Undershoot Repair

Before dangle pruning, the macro identifies eligible active graph edges having one degree-1 endpoint and one connected endpoint.

For native line sources, `Intersect_extended()` is used to find candidate intersections. Each candidate must:

- Lie beyond the free source endpoint in the correct extension direction
- Lie on the finite target line or arc
- Exceed the node tolerance
- Be within the maximum undershoot extension

The best candidate is selected deterministically. The original source endpoint is edited, an undo-change record is created and the complete topology is rebuilt. Up to 25 repair passes are allowed.

### 6. Iterative Dangle Pruning

Remaining degree-1 edge chains are removed iteratively until no active degree-1 node remains.

Both directed edges associated with each removed physical edge are deactivated. The corresponding temporary physical geometry is then deleted.

### 7. Bridge Detection

An iterative depth-first search calculates discovery and low-link values. Graph bridges are classified as cut edges and removed from polygon-forming topology.

### 8. Connected Components

Union-style graph traversal assigns component IDs to active nodes and edges. The component containing an active site-boundary edge is identified separately.

### 9. Directed-Edge Angular Ordering

Each physical edge creates two reverse directed edges. Active outgoing edges are sorted counter-clockwise at every node using `Atan2()`.

Deterministic tie-breakers are:

1. Direction angle
2. Destination distance
3. Destination node ID
4. Directed-edge ID

### 10. Next-Edge Assignment

For each directed edge, the macro finds its reverse edge at the destination node and assigns the next face-traversal edge from the angular ordering.

### 11. Ring Tracing and Face Classification

Directed-edge cycles are traced into candidate rings. Signed XY area is calculated using the shoelace formula.

Under the implemented traversal convention:

- Clockwise rings are treated as bounded-face candidates.
- Counter-clockwise rings are treated as component-exterior rings.
- Rings below the implemented minimum area are rejected.

### 12. Site Filtering

The site boundary is converted to a densified XY ring for point-in-polygon testing. A representative point is calculated for each bounded face, and only faces classified inside the site ring are retained.

### 13. Containment and Hole Handling

Accepted atomic bounded faces remain output polygons.

For disconnected enclosed graph components, the component-exterior ring can be attached as a hole to the smallest containing accepted face. Bounded faces within the disconnected component remain standalone output polygons.

### 14. Native Polygon Creation

Final faces are rebuilt as native Super strings. The macro explicitly enables and writes:

- Segment-radius data
- Arc major flags
- Segment colours

Arc metadata is read back and verified before the polygon is accepted.

### 15. Production Cleanup

Final polygon outputs are retained. Temporary topology line and arc pieces are deleted, the output model extent is recalculated and the model is redrawn.

## Arc Preservation

Version 028 explicitly enables the segment-radius dimension on each final Super string before writing geometry.

For every final segment, the macro writes and verifies:

```cpp
Set_super_data()
Set_super_segment_radius()
Set_super_segment_major()
```

A final face is rejected if the number of arc segments read back from the Super string differs from the expected arc count.

## Undershoot Repair Behaviour

Only native line endpoints are repaired.

Arc endpoints are not extended by the repair stage. Extension candidates are checked against finite native target geometry, including arc sweep and radial checks.

The source element is modified only after a duplicate has been created for undo support. If the updated element cannot pass `Calc_extent()`, the original coordinate and metadata are restored.

## Hole and Island Behaviour

- Immediate odd-depth children are attached to even-depth shell polygons as holes.
- Even-depth contained faces remain output polygons.
- A disconnected enclosed component may contribute its counter-clockwise component-exterior ring as a hole to a containing face.
- Bounded faces within that component remain separate polygons.

## Main 12dPL Functions Demonstrated

### Super-String Geometry

- `Create_super()`
- `Get_super_data()`
- `Set_super_data()`
- `Set_super_use_segment_radius()`
- `Set_super_segment_radius()`
- `Set_super_segment_major()`
- `Set_super_use_segment_colour()`
- `Set_super_segment_colour()`
- `String_close()`
- `Super_add_hole()`
- `Get_super_holes()`

### Native Segments and Arcs

- `Get_segment()`
- `Get_start()`
- `Get_end()`
- `Get_arc()`
- `Get_centre()`
- `Get_radius()`
- `Intersect()`
- `Intersect_extended()`

### Polygon and Point Tests

- Manual XY point-on-segment testing
- Manual ray-crossing point-in-ring testing
- Shoelace signed-area calculation
- Representative-point calculation

### Graph and Container Operations

- `Dynamic_Integer`
- `Dynamic_Real`
- `Dynamic_Element`
- `Dynamic_Text`
- `Integer_Set`
- `Container_insert_key()`
- `Get_item()`
- `Set_item()`
- `Get_number_of_items()`

### Element, Model and Undo Functions

- `Element_duplicate()`
- `Element_delete()`
- `Set_model()`
- `Calc_extent()`
- `Model_draw()`
- `Add_undo_add()`
- `Add_undo_change()`

## Reporting

The Output Window reports completion information including:

- Total polygons created
- Polygons containing holes
- Islands detected
- Undershoot repairs applied
- Dangling edge repairs applied
- Processing time in seconds

Detailed failure messages are also printed for noding, graph traversal, arc verification, hole creation, model assignment and cleanup failures.

## Notes

- Topology is evaluated in XY.
- Final polygons are flattened to the selected output Z level.
- Native circular-arc metadata is preserved in final polygon edges.
- The site boundary participates in the planar graph and is also used for final spatial filtering.
- Source geometry can be changed when line undershoot repair succeeds.
- Temporary physical topology pieces are removed after successful polygon creation.

## Limitations and Implementation Notes

- The panel validates a **Minimum face area** value, but the current `Run_stage_3_noding()` implementation uses a fixed internal value of `0.001` and does not receive the panel value. Changing the panel field therefore does not currently alter face filtering.
- Topology is two-dimensional. Source Z values are not retained in final faces.
- Undershoot repair applies only to eligible native line endpoints.
- A maximum of 25 topology rebuild passes is allowed for sequential undershoot repairs.
- Arbitrary overlapping or duplicate source geometry can produce rejected multi-owner edges or topology failures.
- Correct results depend on tolerances appropriate to the source-data precision and geometry scale.
- The summary variable for islands is initialised to zero in the current implementation and is not updated from the internal containment counters.
- Temporary topology creation and source repairs create undo records individually rather than one final grouped undo list.

## Keywords

12d Model, 12dPL, polygon topology, planar graph, polygonisation, site boundary, Super string, native arcs, canonical nodes, noding, segment intersection, arc intersection, undershoot repair, dangling edges, dangle pruning, bridge detection, cut edges, directed edges, face tracing, signed area, point in polygon, holes, islands, topology cleanup

## Related Macros

- Dissolve_Adjacent_Polygons_panel
- Create_Catchments_From_LC_panel
- LC_creator_panel

## Revision History

| Version | Date | Notes |
|---|---|---|
| 025 | 25/09/2026 | Treated failure of the best-effort null-model detach during undershoot-repair undo preparation as non-fatal. |
| 027 | 25/09/2026 | Added component-exterior holes for disconnected enclosed graph components while retaining their bounded faces as standalone polygons. |
| 028 | 25/09/2026 | Explicitly enabled segment-radius storage on final face Super strings, wrote radius and major metadata, and rejected arc readback mismatches. |
