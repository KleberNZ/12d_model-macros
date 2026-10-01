# Create_GD05_SRP_DEB_trapezoidal_panel

## Purpose

Creates trapezoidal sediment control device strings for either a Sediment Retention Pond (SRP) or Decanting Earth Bund (DEB) using the geometric and validation rules implemented in the macro.

The macro builds the required 3D Super strings from user-defined dimensions, levels, origin and bearing, places them in the selected output model, calculates approximate storage volume and groups the created elements into one undo action.

## Location

C:\12d\12dPL_Data\Code\Create_GD05_SRP_DEB_trapezoidal_panel

## Source

Create_GD05_SRP_DEB_trapezoidal_panel.4dm

## Compile Method

Open VS Code from:

C:\12d\12dPL_Data

Then open:

Code\Create_GD05_SRP_DEB_trapezoidal_panel\Create_GD05_SRP_DEB_trapezoidal_panel.4dm

Compile using:

Ctrl+Shift+P > 12dPL: Compile Current File

## Include Setup

```cpp
#include "standard_library.H"
#include "size_of.h"
```

## Category

Earthworks and Sediment Control

## Type

Sediment Control Device Geometry Generator

## Author

KLP

## 12d Version

V15

## Current Version

001

## Device Types

### Sediment Retention Pond (SRP)

Creates:

- Top of embankment string with an outlet spillway notch
- Pond outer edge
- Water surface elevation polygon
- Pond base polygon
- Level spreader
- Forebay top
- Forebay base

### Decanting Earth Bund (DEB)

Creates:

- Top-of-bund string with entry-weir and outlet-spillway notches
- Crest outer polygon
- Top storage polygon
- Base/invert polygon
- Spillway base line
- Entry-weir base line

## Inputs

- Device type: `SRP` or `DEB`
- Output model
- Device name
- Origin XYZ
- Bearing
- Top of embankment RL
- Crest width
- Primary spillway/storage length
- Length-to-width ratio
- Storage depth
- Spillway base width
- Forebay width for SRP only

## Default Values

- Device type: SRP
- Origin: 0, 0, 0
- Bearing: 0
- Crest width: 1.0 m
- Length-to-width ratio: 3.0
- Storage depth: 1.0 m
- Spillway base width: 6.0 m
- Forebay width: 2.0 m

## Validation Rules Implemented

### Common Checks

- Primary storage length must be greater than 0.
- Length-to-width ratio must be between 3 and 5.
- Crest width must be greater than 0.
- Storage depth must be greater than 0.

### SRP Checks

- Storage depth must not exceed 2.0 m.
- Spillway base width must be at least 6.0 m.
- Forebay width must be at least 2.0 m.
- Spillway top width must fit within the storage and embankment widths.
- Calculated pond base width and length must be greater than 0.
- Calculated forebay base dimensions must remain valid.

### DEB Checks

- Total depth from top-of-bund RL to base RL must not exceed 1.0 m.
- Spillway base width must be at least 1.5 m.
- Calculated base width must be at least 2.0 m.
- Calculated base length must be greater than 0.
- Storage length must be sufficient for the selected ratio and depth.
- Spillway top width must fit within the crest outer width.
- Entry-weir top width must fit within the top storage width.

## Key Geometry Parameters

### SRP

- Side batters: 2H:1V
- Entry batter: 3H:1V
- Outlet batter: 2H:1V
- Spillway side batters: 2H:1V
- Spillway RL: 0.3 m below top of embankment
- Storage WSE RL: 0.3 m below spillway RL
- Level spreader RL: 0.15 m above storage WSE RL
- Forebay depth: 1.0 m
- Forebay batter: 1H:1V

### DEB

- Side batters: 2H:1V
- Entry batter: 3H:1V
- Outlet batter: 2H:1V
- Spillway batter: 2H:1V
- Primary spillway drop: 0.35 m below top-of-bund RL
- Spillway base RL: 0.10 m above storage RL
- Entry-weir RL: 0.10 m below top-of-bund RL

## Storage Volume

The macro reports an approximate storage volume using the frustum-style formula implemented in the source:

```text
V = D / 6 × [(Ltop × Wtop) + (Lbase × Wbase)
    + ((Ltop + Lbase) × (Wtop + Wbase))]
```

The resulting volume is displayed in cubic metres in the panel message box.

## Workflow

1. Select SRP or DEB.
2. Enter the origin and bearing.
3. Enter the top-of-embankment RL.
4. Enter the storage length, ratio, crest width, storage depth and spillway width.
5. For SRP, enter the forebay width.
6. Select or create the output model.
7. Enter the device name.
8. Select **Process**.
9. The macro validates the selected parameters.
10. Device strings are created in unrotated coordinates.
11. All created strings are rotated about the origin to the specified bearing.
12. A grouped undo record is created.
13. Calculated dimensions, levels and storage volume are reported.

## Main 12dPL Functions Demonstrated

### Panel and Validation

- `Create_panel()`
- `Create_choice_box()`
- `Create_model_box()`
- `Create_name_box()`
- `Create_xyz_box()`
- `Create_angle_box()`
- `Create_real_box()`
- `Validate()`
- `Set_enable()`

### Geometry Creation

- `Create_super()`
- `Set_super_use_3d_level()`
- `Set_super_data()`
- `String_close()`
- `Set_name()`
- `Set_model()`
- `Rotate()`
- `Bearing_to_angle()`

### Display and Undo

- `Set_colour()`
- `Set_super_use_segment_colour()`
- `Set_super_segment_colour()`
- `Add_undo_add()`
- `Add_undo_list()`

## Naming Convention

Output strings use the supplied device name with descriptive suffixes.

SRP examples:

```text
<Device Name> Top of Embankment
<Device Name> Pond Edge
<Device Name> WSE
<Device Name> Base
<Device Name> Level Spreader
<Device Name> Forebay Top
<Device Name> Forebay Base
```

DEB examples:

```text
<Device Name> TOB
<Device Name> Crest Outer
<Device Name> Top Storage
<Device Name> Base
<Device Name> Spillway
<Device Name> Entry Weir
```

## Notes

- Selecting DEB disables the forebay-width input because the DEB workflow does not create a forebay.
- Geometry is created relative to the specified origin, then rotated once at the end to the selected bearing.
- The macro assigns predefined colours to the output strings.
- The source grants unrestricted reproduction, modification, compilation and reuse.

## Limitations

- Creates idealised rectangular trapezoidal geometry rather than fitting the device to existing terrain.
- Does not calculate earthworks volumes or interact with a TIN.
- Does not automatically verify contributing catchment area, treatment volume or hydraulic capacity.
- Storage volume is based on the dimensions and formula implemented in the macro.
- Batter slopes and vertical offsets are fixed in the source.
- The source build definition is `version.0.001`, which appears to be a placeholder rather than a standard V15 build identifier.

## Keywords

GD05, sediment control, sediment retention pond, SRP, decanting earth bund, DEB, trapezoidal pond, forebay, level spreader, emergency spillway, entry weir, storage volume, earthworks, erosion and sediment control, 12d Model, 12dPL

## Related Macros

- Create_Catchments_From_LC_panel
- Polygon_Topology_Builder

## Revision History

| Version | Date | Notes |
|---|---|---|
| 001 | 16/06/2026 | Initial source version. Creates SRP and DEB trapezoidal device strings, applies device-specific checks, calculates storage volume and provides grouped undo. |
