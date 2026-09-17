## Set_Drainage_Stage_By_Polygon_panel

### Purpose

Assign construction stage attributes to drainage pits and pipes using
named stage boundary polygons.

The macro spatially compares drainage elements against selected stage
polygons and automatically populates stage attributes used for
construction scheduling, reporting, and project staging.

---

### Location

C:\12d\12dPL_Data\Code\Set_Drainage_Stage_By_Polygon_panel

---

### Source

Set_Drainage_Stage_By_Polygon_panel.4dm

---

### Compile Method

Open VS Code from:

C:\12d\12dPL_Data

Then open:

Code\Set_Drainage_Stage_By_Polygon_panel\
Set_Drainage_Stage_By_Polygon_panel.4dm

Compile using:

Ctrl+Shift+P > 12dPL: Compile Current File

Do not use F7 unless the old task system has been deliberately updated.

---

### Include Setup

This macro uses:

```cpp
#include "standard_library.H"
#include "size_of.H"
#include "set_ups.H"
```

These rely on the central workspace setting:

```text
12dpl.compiler.includePaths = C:\12d\includes
```

---

### Inputs

#### Drainage Strings

Source Box containing one or more drainage strings.

Each selected element must be a valid Drainage element.

#### Stage Boundary Polygons

Source Box containing one or more closed polygons.

Requirements:

- Valid polygon geometry
- Polygon must have a name
- Polygon name becomes the stage value

Examples:

```text
Stage 1
Stage 2
Stage 3
Bulk Earthworks
Civil Works
Final Works
```

---

### Processing Logic

#### Pit Classification

For each drainage pit:

1. Read pit XY location.
2. Test location against selected stage polygons.
3. If inside a polygon:
   - Set attribute:

```text
pit stage
```

to:

```text
polygon name
```

Example:

```text
pit stage = Stage 2
```

---

#### Pipe Classification

For each drainage pipe:

1. Obtain actual drainage segment geometry.
2. Calculate segment midpoint.
3. Test midpoint against selected stage polygons.
4. If inside a polygon:
   - Set attribute:

```text
pipe stage
```

to:

```text
polygon name
```

Example:

```text
pipe stage = Stage 2
```

---

### Polygon Priority

Where polygons overlap:

- The first matching polygon found in the selected polygon dataset
  receives priority.

Future versions may provide configurable overlap handling.

---

### Outputs

Modified drainage strings.

Updated attributes:

```text
pit stage
pipe stage
```

No new geometry is created.

---

### Undo

The macro creates undo records for modified drainage strings.

All changes are grouped into a single undo operation:

```text
Set Drainage Stage Attributes
```

---

### Typical Workflow

1. Create stage boundary polygons.
2. Name each polygon.
3. Open the macro.
4. Select drainage strings.
5. Select stage polygons.
6. Click Process.
7. Review assigned attributes.

---

### Example

Polygon names:

```text
Stage 1
Stage 2
Stage 3
```

Results:

```text
Pit A
    pit stage = Stage 1

Pit B
    pit stage = Stage 2

Pipe 101
    pipe stage = Stage 1

Pipe 102
    pipe stage = Stage 2
```

---

### Known Limitations

Current Version (V002):

- Pipe classification uses segment midpoint.
- Items outside all polygons remain unchanged.
- Overlapping polygons are resolved by first-match priority.
- Polygon names must not be blank.

---

### Revision History

| Version | Date | Notes |
|----------|----------|----------|
| 001 | 2026-09-17 | Initial release |
| 002 | 2026-09-17 | Added Source Box validation, polygon validation, midpoint pipe