# 12d Model Macros

Personal 12d Model macro library for 12dPL development.

This repository contains 12dPL macro source code used for civil design automation, validation, drainage tools, geometry helpers, panel-based utilities, and productivity workflows within 12d Model.

---

## Repository Layout

The wider local workspace is:

```text
C:\12d\12dPL_Data
````

The Git repository is:

```text
C:\12d\12dPL_Data\Code
```

The shared include library is:

```text
C:\12d\includes
```

Important distinction:

```text
C:\12d\12dPL_Data                                = central VS Code workspace
C:\12d\12dPL_Data\Code                           = Git repo for macro source files
C:\12d\12dPL_Data\12d Model Programmer Custom GPT = reference / Custom GPT knowledge workspace
C:\12d\includes                                  = shared include files
```

---

## Reference Knowledge Workspace

The macro source repository is:

```text
C:\12d\12dPL_Data\Code
````

The separate 12dPL reference / Custom GPT workspace is:

```text
C:\12d\12dPL_Data\12d Model Programmer Custom GPT
```

This reference workspace contains supporting material for 12dPL macro generation, debugging, and validation, including:

* manuals and extracted manual text;
* prototype/function signature databases;
* symbol/reference databases;
* approved scaffolds;
* approved snippets;
* lookup indexes;
* macro assistant instructions and policy files.

Important files in the reference workspace include:

```text
AGENTS.md
README.md
WORKSPACE_INVENTORY.md
12dPL MACRO ASSISTANT SPECIFICATION.md
macro_structure.md
Instructions.md
INTERNET LOOKUP POLICY - FALLBACK ONLY.md
```

Use the reference workspace as read-only guidance by default.

Do not copy the full reference workspace into this macro source repo.

Do not commit manuals, indexes, databases, archived files, or generated reference assets into this repo unless deliberately reviewed.


## Overview

Each macro is stored in its own folder under the `Code` repository.

Typical macro folder:

```text
Macro_Name/
  Macro_Name.4dm
  README.md
```

Compiled outputs may be created locally after compiling:

```text
Macro_Name/
  Macro_Name.4do
```

Compiled outputs are build artifacts and must not be committed.

---

## Workflow

1. Create a new macro using:

   ```powershell
   .\new_macro.ps1
   ```

2. The script creates:

   ```text
   Code\Macro_Name\Macro_Name.4dm
   Code\Macro_Name\README.md
   ```

3. The script opens the central VS Code workspace:

   ```text
   C:\12d\12dPL_Data
   ```
   > **Important:** Always open `C:\12d\12dPL_Data` as the VS Code workspace root when editing and compiling 12dPL macros. The workspace-level `.vscode/settings.json` provides the 12dPL compiler path, include path, file association, and default compiler flags. Opening an individual macro folder directly may cause include files such as `standard_library.h` and `size_of.h` to fail during compile.

4. Edit the `.4dm` file in VS Code.

5. Compile using:

   ```text
   Ctrl+Shift+P > 12dPL: Compile Current File
   ```

6. Test the macro inside 12d Model.

7. Review Git changes:

   ```powershell
   git status --short
   git diff
   ```

8. Commit and push when ready.

The `new_macro.ps1` script stages new macro folders for review. It does not commit automatically.

---

## VS Code Setup

Workspace settings are stored at:

```text
C:\12d\12dPL_Data\.vscode\settings.json
```

These settings only apply reliably when `C:\12d\12dPL_Data` is opened as the VS Code workspace root.

Expected settings:

```json
{
    "files.associations": {
        "*.4dm": "12dpl"
    },
    "12dpl.compiler.path": "C:\\Program Files\\12d\\12dmodel\\15.00\\nt.x64\\",
    "12dpl.compiler.includePaths": [
        "C:\\12d\\includes"
    ],
    "12dpl.compiler.defaultFlags": [
        "-allow_id_calls",
        "-allow_old_calls"
    ]
}
```

The 12dPL VS Code extension must be installed in the VS Code profile being used.

Current workflow uses the normal/default VS Code profile, not a dedicated `12dPL` profile.

---

## Repository Rules

Track source and documentation files such as:

```text
*.4dm
README.md
AGENTS.md
new_macro.ps1
sync.ps1
```

Do not track generated, temporary, or local-only files such as:

```text
*.4do
*.4dl
*.log
*.tmp
*.pdf
*.txt
*.json
*.go
test/
test*/
*backup*
*BACKUP*
```

Use:

```powershell
git status --short
```

before committing.

Use:

```powershell
git ls-files *.4do *.4dl *.tmp *.pdf *.json *.txt
```

to check whether unwanted generated/local files are tracked.

---

## Folder Structure

Preferred structure:

```text
Macro_Name/
  Macro_Name.4dm
  README.md
```

Do not create individual `.code-workspace` files for each macro unless there is a specific reason.

The current workflow uses the central workspace:

```text
C:\12d\12dPL_Data
```

---

## Naming Convention

Use action-first naming.

Preferred pattern:

```text
Verb_Object[_Qualifier][_panel]
```

Examples:

```text
Delete_duplicate_points
Drainage_Updater
Set_CoverRL_to_Manual
Write_resolve_sa_to_chain_panel
```

Rules:

* Use clear action-first names.
* Use `_panel` only if the macro has a user interface panel.
* Avoid names such as `test`, `backup`, `final`, `v2`, `new`, or `copy`.

---

## Include Setup

Shared include files are stored in:

```text
C:\12d\includes
```

Common includes used by new macro templates:

```c
#include "standard_library.H"
#include "size_of.h"
```

The include path is configured through the VS Code workspace setting:

```json
"12dpl.compiler.includePaths": [
    "C:\\12d\\includes"
]
```

Do not duplicate shared include files into individual macro folders unless there is a specific reason.

---

## Helper Scripts

### `new_macro.ps1`

Creates a new macro folder and starter files.

Expected behaviour:

* Creates the macro folder under `C:\12d\12dPL_Data\Code`
* Creates the `.4dm` file
* Creates the macro `README.md`
* Opens the central VS Code workspace
* Stages the new macro folder for review
* Does not commit automatically

### `sync.ps1`

Safer Git sync helper.

Expected behaviour:

* Shows current Git status
* Checks for tracked generated/local file types
* Asks before staging
* Shows staged changes
* Asks before committing
* Asks before pushing

Use this script only after reviewing the changes.

---

## Development Principles

* Build macros incrementally.
* Validate after each step.
* Keep logic simple and modular.
* Prefer clarity over cleverness.
* Preserve working macro behaviour unless the requested change requires modifying it.
* Avoid broad rewrites.
* Keep changes small and reviewable.

---

## Macro README Files

Each macro folder may include a `README.md`.

Recommended sections:

```text
Purpose
Location
Source
Compile Method
Include Setup
Inputs
Outputs
Notes
Revision History
```

Keep macro README files practical and focused on how to use, compile, and maintain the macro.

---

## 12d Model Version

Macros are intended for:

```text
12d Model V15
```

Compiler path:

```text
C:\Program Files\12d\12dmodel\15.00\nt.x64\
```

---

## Agent Instructions

This repo includes:

```text
AGENTS.md
```

That file contains rules for Codex / coding agents working on this repository.

Agents should follow `AGENTS.md` before editing macros, scripts, ignore rules, or documentation.

---

## Future Improvements

Possible future improvements:

* Standardised macro templates
* Reusable snippet library integration
* Better macro README coverage
* Safer macro validation checklist
* Optional automated checks for unwanted tracked file types
* Documentation for common 12dPL patterns used across macros

````
