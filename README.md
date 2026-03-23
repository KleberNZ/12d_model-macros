# 12d Model Macros

Personal 12d Model macro library for 12dPL development.

------------------------------------------------------------------------

## Overview

This repository contains a collection of 12dPL macros used for design
automation, validation, and productivity workflows within 12d Model.

Each macro is self-contained in its own folder and follows a consistent
structure.

------------------------------------------------------------------------

## Workflow

1.  Create new macro using `new_macro.ps1`
2.  Edit `.4dm` in VS Code (12dPL profile)
3.  Compile using 12d / `cc4d.exe`
4.  Test inside 12d Model
5.  Commit changes (auto for new macros)
6.  Push to GitHub when ready

------------------------------------------------------------------------

## Repository Rules

-   ✔ Track source files only:
    -   `.4dm`
-   ❌ Do NOT track:
    -   `.4do`, `.4dl` (compiled outputs)
    -   temp/log files
    -   backup/test files
-   ✔ One macro per folder

------------------------------------------------------------------------

## Folder Structure

``` text
Macro_Name/
  Macro_Name.4dm
  Macro_Name.code-workspace
  README.md (optional)
```

------------------------------------------------------------------------

## Naming Convention

Use:

``` text
Verb_Object[_Qualifier][_panel]
```

Examples:

-   `Update_Pit_Attributes_Panel`
-   `Write_Resolve_SA_to_Chain_Panel`
-   `Delete_Duplicate_Points`

Rules:

-   Use action-first naming\
-   Use `_panel` only if UI exists\
-   Avoid `test`, `backup`, `final`, `v2`

------------------------------------------------------------------------

## Development Principles

-   Build macros incrementally\
-   Validate after each step\
-   Keep logic simple and modular\
-   Prefer clarity over cleverness

------------------------------------------------------------------------

## Notes

-   All macros are intended for **12d Model V15**
-   Uses standard include libraries from:

``` text
../../include
```

------------------------------------------------------------------------

## Future Improvements

-   Standardised macro templates\
-   Reusable snippet library integration\
-   Automated testing workflows (where applicable)
