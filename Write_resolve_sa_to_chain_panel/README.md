# Write_resolve_sa_to_chain_panel

## Purpose

Creates or updates a 12d Chain file with **Resolve Super Alignment** commands for selected Super Alignments.

The macro can create a new Unicode Chain XML file or append commands to an existing Chain. Commands can optionally be grouped under a named region and sorted using natural, numeric-aware ordering.

## Location

C:\12d\12dPL_Data\Code\Write_resolve_sa_to_chain_panel

## Source

Create_chain_resolve_sa_panel.4dm

## Compile Method

Open VS Code from:

C:\12d\12dPL_Data

Then open:

Code\Write_resolve_sa_to_chain_panel\Create_chain_resolve_sa_panel.4dm

Compile using:

Ctrl+Shift+P > 12dPL: Compile Current File

## Include Setup

```cpp
#include "standard_library.H"
#include "size_of.H"
#include "set_ups.h"
#include "element_ids.h"
#include "QSort.H"
```

## Category

Utilities

## Type

Chain Automation Utility

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

### Super Alignments

Select one or more Super Alignments.

All selected elements must have the type:

```text
Super_Alignment
```

If any other element type is selected, processing stops.

### Chain File

Select the target `.chain` file.

The macro will:

- Create a new Chain if the file does not exist.
- Append Resolve SA commands if the file already exists.

### Region Name

Optional Chain region name.

If provided, generated commands are placed under that region. If the region does not exist in an existing Chain, the region is created.

### Sort Alphabetically

Optional natural alphanumeric sorting based on:

```text
<Model Name>-><Element Name>
```

Numeric groups are zero-padded internally so names containing numbers sort naturally.

## Outputs

Creates or updates a Unicode 12d Chain XML file containing one `Resolve_sa` command for each selected Super Alignment.

Each command stores:

- Command name
- Model name
- Model ID
- Element name
- Element ID
- Active status
- Continue-on-failure status
- Parameter and interactive settings

Example command structure:

```xml
<Resolve_sa>
  <Name>Resolve Road Design->Main Alignment</Name>
  <Active>true</Active>
  <Continue_on_failure>false</Continue_on_failure>
  <Uses_parameters>false</Uses_parameters>
  <Interactive>false</Interactive>
  <Comments>
  </Comments>
  <Model_Name>Road Design</Model_Name>
  <Model_ID>...</Model_ID>
  <Element_Name>Main Alignment</Element_Name>
  <Element_ID>...</Element_ID>
</Resolve_sa>
```

## Workflow

1. Select the Super Alignments.
2. Select or enter the target Chain file.
3. Optionally enter a region name.
4. Choose whether to sort the commands alphabetically.
5. Select **Process**.
6. The macro validates that every selected element is a Super Alignment.
7. Model and element names and IDs are retrieved.
8. XML-safe Resolve SA command blocks are generated.
9. A new Chain is created or the existing Chain is read.
10. Commands are inserted at the applicable location.
11. The Chain is written as Unicode text.
12. The panel reports whether a new Chain was created or an existing Chain was appended.

## New Chain Behaviour

When the target file does not exist, the macro creates a complete Chain document containing:

- XML declaration
- `xml12d` root element
- Metadata block
- Chain version
- Non-interactive Chain settings
- Commands block
- Optional region
- Resolve SA commands
- Selected-command index

## Existing Chain Behaviour

### Without a Region Name

Generated commands are inserted:

- Before the first existing region, when a region exists.
- Otherwise before the closing `Commands` tag.

### With a Region Name

- If the named region exists, commands are inserted before the next region or the closing `Commands` tag.
- If the named region does not exist, a new region and its commands are inserted before the closing `Commands` tag.

## Natural Sorting

When sorting is enabled, the sort name combines the model and element names:

```text
<Model Name>-><Element Name>
```

Numeric character groups are converted to ten-character padded keys before `Qsort()` is applied.

This allows names such as:

```text
Alignment 2
Alignment 10
Alignment 100
```

to sort in numeric order rather than basic lexical order.

## XML Safety

The following names are passed through `Convert_legal_XML()` before being written:

- Region name
- Command name
- Model name
- Element name

## Main 12dPL Functions Demonstrated

### Element and ID Functions

- `Get_type()`
- `Get_name()`
- `Get_text_value()`
- `Get_model()`
- `get_element_ids()`

### XML and Text Functions

- `Convert_legal_XML()`
- `Get_char()`
- `Get_subtext()`
- `From_text()`
- `Find_text()`
- `Insert_text()`

### Dynamic Containers and Sorting

- `Dynamic_Element`
- `Dynamic_Text`
- `Append()`
- `Get_item()`
- `Get_number_of_items()`
- `Qsort()`

### File Functions

- `File_exists()`
- `File_open()`
- `File_read_line()`
- `File_write_unicode()`
- `File_close()`

### Panel Functions

- `Create_source_box()`
- `Create_file_box()`
- `Create_input_box()`
- `Create_named_tick_box()`
- `Create_colour_message_box()`
- `Validate()`
- `Wait_on_widgets()`

## Reporting

Successful processing reports either:

```text
New chain created
```

or:

```text
Existing chain appended
```

Error messages cover:

- Invalid Source Box
- No elements selected
- Invalid Chain file
- Selection containing non-SA elements
- Invalid region name
- Invalid sort option
- More than 10,000 selected elements when sorting
- Failure to create, read, append or write the Chain file

## Notes

- The command references each Super Alignment by both name and ID.
- Unicode Chain files are read and written using `ccs=UNICODE`.
- Region grouping is optional.
- Sorting is optional and uses model name plus element name.
- The source grants unrestricted reproduction, modification, compilation and reuse.

## Limitations

- Sorting supports a maximum of 10,000 selected elements.
- Existing Resolve SA commands are not checked for duplicates.
- Existing Chain content must contain the expected XML tags for insertion.
- The macro validates the selected element type but does not test whether each Super Alignment will resolve successfully when the Chain runs.
- Element ID retrieval return status is assigned but not used to reject command creation.

## Keywords

12d Model, 12dPL, Chain file, Resolve Super Alignment, Resolve SA, Super Alignment, batch processing, Chain automation, XML, Unicode, model ID, element ID, region grouping, natural sorting, QSort

## Related Macros

- Write_recalc_functions_to_chain_panel
- AT_GD0004_panel
- Height_between_2_super_alignments_panel
- Label_height_between_2_SA_panel

## Revision History

| Version | Date | Notes |
|---|---|---|
| 001 | 20/03/2026 | Initial version. Creates or appends Resolve Super Alignment commands with optional region grouping and natural sorting. |
