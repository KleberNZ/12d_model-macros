# 12d Model Macros

Personal 12d Model macro library for 12dPL development.

## Workflow
1. Generate or debug macro logic
2. Edit `.4dm` in VS Code
3. Compile using 12d / cc4d
4. Test in 12d Model
5. Commit only working versions
6. Push to GitHub

## Repository Rules
- Track `.4dm` source only
- Do NOT track compiled files (`.4do`, `.4dl`)
- Avoid committing test, backup, or temp files

## Folder Structure
Each macro lives in its own folder:
- `macro_name.4dm`
- optional `README.md`
- no backups or test clutter