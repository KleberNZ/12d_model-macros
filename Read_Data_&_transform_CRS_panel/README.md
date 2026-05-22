# Read_Data_&_transform_CRS_panel

## Purpose

Imports DWG/DXF or 12d data, reviews it, then approves, transforms, or rejects the import.

Opens the selected 12d read panel, imports data into the DATA IMPORT view, and presents a review/approval workflow. Approved imports are renamed with the selected model prefix, optionally vertically shifted, optionally transformed to NZTM2000, added to the target data type view, and cleaned of empty models. Rejected imports are deleted from DATA IMPORT and empty models are removed automatically.

## Location

C:\12d\12dPL_Data\Code\Read_Data_&_transform_CRS_panel

## Source

Read_Data_&_Transform_CRS_panel.4dm

## Compile Method

Open VS Code from:

C:\12d\12dPL_Data

Then open:

Code\Read_Data_&_transform_CRS_panel\Read_Data_&_Transform_CRS_panel.4dm

Compile using:

Ctrl+Shift+P > 12dPL: Compile Current File

Do not use F7 unless the old task system has been deliberately updated.

## Include Setup

This macro uses clean includes:

#include "standard_library.H"
#include "size_of.h"

These rely on the central workspace setting:

12dpl.compiler.includePaths = C:\12d\includes

## Inputs

- As-built data type: EARTHWORKS, ROADING, STORMWATER, WASTEWATER, WATERMAIN, ELECTRICAL, or TELECOM.
- Data format: DWG/DXF or 12d Solutions Data.
- Transform data to NZTM2000 toggle.
- From NZ2000 circuit, used when NZTM2000 transformation is enabled.
- Move to model prefix, defaulted from the selected as-built data type.
- Vertical translation Z.
- Approval decision after reviewing DATA IMPORT: Approve, Undo import, or Cancel.

## Outputs

- Imported data is loaded into the DATA IMPORT view for review.
- Approved imports are translated vertically, moved to the selected model prefix, and optionally transformed to NZTM2000.
- Non-empty approved models with the selected prefix are added to the target view named by the selected data type.
- Empty models are deleted after approval or reject cleanup.
- Rejected imports are deleted from the DATA IMPORT view/models automatically.

## Notes

- Target views are named by the selected as-built data type.
- DATA IMPORT is used as the temporary review view.
- Approval cleanup reports deleted empty models and models added to the target view.
- Reject cleanup reports imported elements deleted and empty models deleted.

## Revision History

| Version | Date | Notes |
|---|---|---|
| 001 | 2026-05-22 | Initial macro |
