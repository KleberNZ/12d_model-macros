
/*
   MIT License

   Copyright (c) 2023 Core Spatial

   Permission is hereby granted, free of charge, to any person obtaining a copy
   of this software and associated documentation files (the "Software"), to deal
   in the Software without restriction, including without limitation the rights
   to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
   copies of the Software, and to permit persons to whom the Software is
   furnished to do so, subject to the following conditions:

   The above copyright notice and this permission notice shall be included in all
   copies or substantial portions of the Software.

   TO THE EXTENT PERMITTED BY LAW, THE SOFTWARE IS PROVIDED "AS IS", WITHOUT
   WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
   WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
   NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE
   FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
   TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR
   THE USE OR OTHER DEALINGS IN THE SOFTWARE.

*/

/*****************************************
 *
 *	FILE:		chain_custom_prompt_panel.4dm
 *
 *	DESCRIPTION:
 *
 *  refer chain_custom_prompt_panel.pdf
 *   and
 *        chain_custom_prompt_panel.txt
 *
 *
 *
 *
 *	AUTHOR:		Matthew Monk
 *	STARTED:	20-06-2014
 *
 *	REVISION HISTORY:
 *	1		20-06-2014	Initial macro
 *	2		24-06-2014	*ADD* More widgets supported
 *	3		08-08-2014	*FIX* Added checks for maximum arguments/widgets
 *	4		24-02-2020 	*MOD* Set Tin_Box for all tin types- supertin, grid tin, etc.
 *	5		11-04-2020	*MOD* Added Choice_Box support
 *   Matt's Legacy - Core Spatial - Tatras Consulting
 *	1.6		06/2023	 	code consolidated and issued for release
 *	1.7		06/2024	 	auto shutdown with 12d when closing the project, added by 12d
 *	1.8		04/2025	 	update the behaviour of the "OK" button, added by 12d
 *
 */

#define DEBUG 0

// Attribute Types
#define ATT_TYPE_INTEGER 1
#define ATT_TYPE_REAL 2
#define ATT_TYPE_TEXT 3
#define ATT_TYPE_BLOB 4
#define ATT_TYPE_BINARY ATT_TYPE_BLOB // Synonym
#define ATT_TYPE_ATTRIBUTES 5
#define ATT_TYPE_UID 6
#define ATT_TYPE_INT64 7 // 64-bit integer
#define ATT_TYPE_GUID 8
#define MAX_ARRAY_SIZE 500 // Maximum size for pre-declared fixed arrays

#define PARAMS_SEPARATOR "|"		   // Separates parameters
#define PARAMS_KEY_VALUE_SEPARATOR "=" // Separates key=value pairs

// Generic - All/Most Widgets
#define PARAM_NAME_DEFAULT_VALUE "d"
#define PARAM_NAME_WIDTH_IN_CHARS "wic"
#define PARAM_NAME_TOOLTIP "tt"
#define PARAM_NAME_OPTIONAL "opt"

// For those that have a create/validate mode
#define PARAM_NAME_GENERIC_CREATE_MODE "mode"

// Date_Time_Box
#define PARAM_NAME_DATE_TIME_IS_GMT "gmt"
#define PARAM_NAME_DATE_TIME_FORMAT "fmt"

// Directory_Box

// File_Box
#define PARAM_NAME_FILE_BOX_WILDCARD "wild"
#define PARAM_NAME_FILE_BOX_DIRECTORY "dir"
#define PARAM_NAME_FILE_BOX_MANY "many"
#define PARAM_NAME_FILE_BOX_ENCODING "enc"
#define PARAM_NAME_FILE_BOX_SHOW_ENCODING "shenc"
#define PARAM_NAME_FILE_BOX_LIBRARY "lib"
#define PARAM_NAME_FILE_BOX_SETUPS "sup"

// Function_BOx
#define PARAM_NAME_FUNC_BOX_TYPE_TEXT "typet"
#define PARAM_NAME_FUNC_BOX_TYPE_INT "typei"

// Input_Box
#define PARAM_NAME_INPUT_BOX_MULTILINES "lines"

// List_Box

// Model_Box

// New_Select_Box
#define PARAM_NAME_SELECT_MESSAGE "msg"
#define PARAM_NAME_SELECT_TYPE "type"
#define PARAM_NAME_SELECT_SNAP "snap"
#define PARAM_NAME_SELECT_DIR "dir"

// New_XYZ_Box
#define PARAM_NAME_XYZ_X "x"
#define PARAM_NAME_XYZ_Y "y"
#define PARAM_NAME_XYZ_Z "z"

// Polygon_Box
#define PARAM_NAME_POLYGON_HOLES "hole"

// Slider_Box
#define PARAM_NAME_SLIDER_HORIZONTAL "horz"
#define PARAM_NAME_SLIDER_WIDTH "w"
#define PARAM_NAME_SLIDER_HEIGHT "h"
#define PARAM_NAME_SLIDER_MIN "min"
#define PARAM_NAME_SLIDER_MAX "max"
#define PARAM_NAME_SLIDER_INTERVAL "int"
#define PARAM_NAME_SLIDER_POSITION "pos"

// Source_box & Target_Box
#define PARAM_NAME_SOURCE_BOX_FLAGS "flag"
#define PARAM_NAME_SOURCE_BOX_DEFAULT "def"

// Textstyle_Data_Box
#define PARAM_NAME_TEXTSTYLE_FLAG "flag"
#define PARAM_NAME_TEXTSTYLE_OPTIONAL "opts"

// Text_Edit_Box
#define PARAM_NAME_TEXT_EDIT_LINES "lines"
#define PARAM_NAME_TEXT_EDIT_WRAP "wrap"
#define PARAM_NAME_TEXT_EDIT_READONLY "ro"
#define PARAM_NAME_TEXT_EDIT_VSCROLL "vscr"
#define PARAM_NAME_TEXT_EDIT_HSCROLL "hscr"

// Tin_Box
#define PARAM_NAME_TIN_NORMAL "norm"
#define PARAM_NAME_TIN_SUPER "super"
#define PARAM_NAME_TIN_GRID "grid"
#define PARAM_NAME_TIN_EXACT "exact"
#define PARAM_NAME_TIN_ACCESS "acc"

// View_Box
#define PARAM_NAME_VIEW_TYPE_PLAN "plan"
#define PARAM_NAME_VIEW_TYPE_PERSPECTIVE "pers"
#define PARAM_NAME_VIEW_TYPE_SECTION "sect"
#define PARAM_NAME_VIEW_TYPE_HIDDEN "hidd"

#define PARAM_NAME_VIEW_ENGINE "eng"

// Prerequisites
// Matt Monk libraries
#include "..\\..\\include/Matt_set_ups.H"
#include "..\\..\\include/Matt_standard_library.H"

// Formwork
// #include "formwork/print/fw_print.h"
// #include "formwork/attributes/fw_attributes.h"




// #### GLOBAL VARIABLES ####
{
	// Appears in the panel title bar and about information printed to Output Window
	Text PROGRAM_NAME = "Chain Custom Prompt";
	Text PROGRAM_AUTHOR = "Matthew Monk - Core Spatial";
	Text PROGRAM_VERSION = "1.7";
	Text PROGRAM_DATE = "2024-06";
	Dynamic_Text Program_Info;

	Integer Shutdown_code = 424242;
}
Widget Cast(Widget w)
{
	return w;
}

Integer FW_Attributes_Get_value_real(Element elt, Integer att_no, Real &value);
Integer FW_Attributes_Get_value_real(Attributes atts, Integer att_no, Real &value);
Integer FW_Attributes_Get_value_real(Element elt, Text name, Real &value);
Integer FW_Attributes_Get_value_real(Attributes atts, Text name, Real &value);
void Null(Real &x, Real &y, Real &z);
Integer FW_Attributes_Get_value_integer(Attributes atts, Integer att_no, Integer &value);
Integer FW_Attributes_Get_value_integer(Attributes atts, Text name, Integer &value);
Integer FW_Attributes_Get_value_text(Attributes atts, Integer index, Text &value);
Integer FW_Attributes_Get_value_text(Attributes atts, Text name, Text &value);
Integer FW_Array_Fill(Integer &data[], Integer size, Integer value);
Integer FW_Attributes_Get_value_boolean(Attributes atts, Integer att_no, Integer &value);
Integer FW_Attributes_Get_value_boolean(Attributes atts, Text name, Integer &value);
Integer FW_Text_True_false(Text input);
Integer True_false(Text input);
Integer FW_Text_Split(Text string, Dynamic_Text &results, Text delimiter);
void PrintD(Text msg)
{
#if DEBUG
	Print(">DEBUG>" + msg + "\n");
#endif
	return;
}
// ### Function Prototypes ###
Integer manage_panel();
void Print_usage();

Text Get_default_widget_value(Attributes widget_params);
Integer Create_widget(Text widget_type, Text widget_title, Attributes &widget_params, Colour_Message_Box &message, Widget &widget);

/*! @ingroup macro
 *	@brief
 *	Main entry point for macro.
 */
void main()
{
#if DEBUG
	Clear_console();
#endif

	Print();
	Print("by " + PROGRAM_AUTHOR + "\n");
	Print(PROGRAM_NAME + " \nversion " + PROGRAM_VERSION + " " + PROGRAM_DATE + "\n");
	Print();

	// Arguments
	// Parse command line arguments
	Integer argc = Get_number_of_command_arguments();

	if (argc > 0)
	{
		Integer shutdown = manage_panel();
		if(shutdown == Shutdown_code) {
			// get out real fast
			return;
		}
	}
	else
	{
		Print("No command line arguments given. See Usage.");
		Print();
		Print_usage();
	}
	return;
}

/*! @ingroup macro
 *	@brief
 *	Prints the usage/help information to the Output Window.
 */
void Print_usage()
{
#if defined(__BASE_FILE_DATE__)
	Text date = __BASE_FILE_DATE__;
#else
	Text date = __DATE__;
#endif

	fix_date(date);

	// Make the first one flash the Output Window
	Print("\n");
	Print("=== " + PROGRAM_NAME + " ===");
	Print();
	Print("v." + PROGRAM_VERSION + ", Compiled: " + date + "\n\n");
	Print("Usage:\n");
	Print(Get_macro_name());
	Print("panel_title w1_type w1_title w2_type w2_title ... wN_type wN_title\n");
	Print("\n");
	Print("Where:\n");
	Print("    panel_title = Title of custom panel when displayed\n");
	Print("    wN_type     = A shortcode indicating the type for the Nth widget to create on the panel.\n");
	Print("                   e.g. VIEW, MODEL\n");
	Print("    wN_title    = The label for the corresponding Nth widget.\n");
	Print("                   e.g. \"Select a view\"\n");
	Print("\n");
	Print("The widget type, wN_type, and title, wN_title, should always be in pairs and in order.\n");
	Print("The widgets will be created on the panel in the order in which they are defined.\n");
	Print("Any type shortcode not known or defined will not produce a widget.\n");
	Print("\n");
	Print("Refer to the official documentation for more information.\n\n");

	return;
}

/*! @ingroup macro
 *	@brief
 *	Displays a GUI panel and handles user interaction with panel.
 */
Integer manage_panel()
{
	Integer rv = -1;
	Integer argc = 0;

	argc = Get_number_of_command_arguments();
	if (argc == 0)
		return 1; // Shouldn't happen, but just in case

	Text args[argc];
	for (Integer i = 1; i <= argc; i++)
	{
		rv = Get_command_argument(i, args[i]);
		if (rv != 0)
		{
		}
	}

	Panel panel = Create_panel(args[1]);

	// ### V & H GROUPS ###
	Vertical_Group vg_panel = Create_vertical_group(BALANCE_WIDGETS_OVER_HEIGHT);
	Vertical_Group vg_main = Create_vertical_group(BALANCE_WIDGETS_OVER_HEIGHT);
	Horizontal_Group hg_buttons = Create_button_group();

	Colour_Message_Box message = Create_colour_message_box(" ");

	// ### WIDGETS ###
	Integer MAX_WIDGETS = 50;
	Widget widgets[MAX_WIDGETS];
	Integer widget_count = 0;
	Integer MAX_ARG_COUNT = (MAX_WIDGETS * 2) + 1;

	if (argc > MAX_ARG_COUNT)
	{
		Print("WARNING! Number of command-line arguments given (" + To_text(argc) + ") exceeds allowable limit (" +
			  To_text(MAX_ARG_COUNT) + "). Max. " + To_text(MAX_WIDGETS) + " widgets per panel are allowed.");
		Print();
	}

	for (i = 2; i <= MAX_ARG_COUNT; i += 2)
	{
		Text widget_type, widget_text, widget_title;
		Widget curr_widget;
		Attributes params;
		Dynamic_Text widget_params;
		widget_type = widget_text = widget_title = "";
		Null(widget_params);

		if (i > argc)
			break;

		widget_type = args[i];
		if ((i + 1) <= argc)
		{
			widget_text = args[i + 1];
		}
		else
		{
			widget_text = "";
		}

		++widget_count;
		PrintD("WIDGET(" + To_text(widget_count) + ") : " + widget_type + " => " + widget_text);

		if (Find_text(widget_text, PARAMS_SEPARATOR))
		{
			Integer num_params = 0;
			num_params = FW_Text_Split(widget_text, widget_params, PARAMS_SEPARATOR);

			if (num_params >= 1)
			{
				Get_item(widget_params, 1, widget_title);
			}
			for (Integer j = 2; j <= num_params; j++)
			{
				Text curr_param = "";
				Integer value_pos = 0;
				Text key = "", value = "";
				rv = Get_item(widget_params, j, curr_param);
				if (rv != 0)
				{
					Print("ERROR : Problem getting Parameter " + To_text(j) + " of " +
						  To_text(num_params) + " for Widget < " + To_text(widget_count) +
						  " , type = " + widget_type + " >. Skipping parameter.");
					Print();
					continue;
				}
				value_pos = Find_text(curr_param, PARAMS_KEY_VALUE_SEPARATOR);
				if (value_pos)
				{
					key = Get_subtext(curr_param, 1, value_pos - Text_length(PARAMS_KEY_VALUE_SEPARATOR));
					value = Get_subtext(curr_param, value_pos + Text_length(PARAMS_KEY_VALUE_SEPARATOR),
										Text_length(curr_param));
				}
				else
				{
					key = "key" + To_text(j - 1);
					value = curr_param;
				}
				Set_attribute(params, Text_lower(key), value);
			}
		}
		else // No parameters, so the first/only is the widget title
		{
			widget_title = widget_text;
		}
		rv = Create_widget(widget_type, widget_title, params, message, curr_widget);
		PrintD("Create_widget() : " + To_text(rv));
		if (rv == 0)
		{
			widgets[widget_count] = curr_widget;
		}
	}

	for (i = 1; i <= MAX_WIDGETS; i++)
	{
		Append(widgets[i], vg_main);
	}

	// ### BUTTONS ###
	Button but_process = Create_button("OK", "process");
	Button but_finish = Create_finish_button("Finish", "finish");
	// Button but_help = Create_help_button(panel, "Help");

	Append(but_process, hg_buttons);
	Append(but_finish, hg_buttons);
	// Append(but_help, hg_buttons);

	Append(vg_main, vg_panel);

	Append(message, vg_panel);
	Append(hg_buttons, vg_panel);

	Append(vg_panel, panel);

	Show_widget(panel);

	Integer doit = 1;
	Integer shutdown = 0;

	while (doit)
	{

		Integer64 id;
		Text cmd;
		Text msg;
		Integer ret = Wait_on_events(id, cmd, msg); // this processes standard messages first ?

		if(cmd == "CodeShutdown") {
			// we are done!
			Set_exit_code("CodeShutdown");
			shutdown = Shutdown_code;
			doit     = 0;
			break;
		}

		rv = -1;

		if (cmd == "keystroke")
			continue;

		switch (id)
		{

		case Get_id64(panel):
		{
			if (cmd == "Panel Quit")
			{
				doit = 0;
			}
			if (cmd == "Panel About")
			{
				// Standard 12d About dialog
				about_panel(panel);
			}
		}
		break; // End - Panel

		case Get_id64(but_finish):
		{
			if (cmd == "finish")
				doit = 0;
		}
		break; // End - finish

		case Get_id64(but_process): // version 1.8 update: "OK" button will behave the same as "Finish"
		{
			if (cmd == "process")
				doit = 0;
		}
		break; // End - process
		}

		if(shutdown != 0) {
			// only do what is absolutely critical - if anything at all
			return shutdown;
		}
	}
	return 0;
}

Text Get_default_widget_value(Attributes widget_params)
{
	Integer rv = -1;
	Text value = "";
	rv = Get_attribute(widget_params, PARAM_NAME_DEFAULT_VALUE, value);
	return (rv == 0) ? value : "";
}

Integer Get_width_in_chars_value(Attributes widget_params)
{
	Integer rv = -1;
	Text value = "";
	Integer int_value = 0;
	rv = Get_attribute(widget_params, PARAM_NAME_WIDTH_IN_CHARS, value);
	if (rv == 0)
	{
		rv = From_text(value, int_value);
		if ((rv == 0) && (To_text(int_value) == value))
		{
			return int_value;
		}
		else
		{
			Print("WARN : Problem extracting Integer from parameter value < " + value +
				  " > (err: " + To_text(rv) + ")");
			Print();
		}
	}
	return -1;
}

Text Get_widget_tooltip(Attributes widget_params)
{
	Integer rv = -1;
	Text value = "";
	rv = Get_attribute(widget_params, PARAM_NAME_TOOLTIP, value);
	return (rv == 0) ? value : "";
}

Integer Get_widget_optional(Attributes widget_params)
{
	Integer rv = -1;
	Text value = "";
	Integer int_value = 0;
	rv = Get_attribute(widget_params, PARAM_NAME_OPTIONAL, value);
	// Print("Get widget optional : rv = " + To_text(rv) + " , value = " + value + "\n");
	if (rv == 0)
	{
		return True_false(Text_lower(value));
	}
	return FALSE;
}

void Set_tin_types(Tin_Box &tin_box, Text title, Attributes widget_params)
{
	Integer rv = -1;
	Integer norm, super, grid;
	norm = super = grid = TRUE;

	// ===== Types ====
	Set_all_tin_types(tin_box);

	rv = FW_Attributes_Get_value_boolean(widget_params, PARAM_NAME_TIN_NORMAL, norm);
	if (rv != 0)
		norm = TRUE;
	rv = FW_Attributes_Get_value_boolean(widget_params, PARAM_NAME_TIN_SUPER, super);
	if (rv != 0)
		super = TRUE;
	rv = FW_Attributes_Get_value_boolean(widget_params, PARAM_NAME_TIN_GRID, grid);
	if (rv != 0)
		grid = TRUE;

	Integer types[3];
	Integer num_types = 0;
	FW_Array_Fill(types, 3, 0);

	if (norm)
		types[++num_types] = 1;
	if (super)
		types[++num_types] = 2;
	if (grid)
		types[++num_types] = 3;

	switch (num_types)
	{
	case (1):
	{
		Set_tin_type(tin_box, types[1]);
	}
	break;

	case (2):
	{
		Set_tin_type(tin_box, types[1], types[2]);
	}
	break;

	case (3):
	{
		Set_all_tin_types(tin_box);
	}
	break;

	default:
	{
		Print("WARN : All Tin Types disabled for widget < " + title +
			  " >. Re-enabling all. Check settings.");
		Print();
		Set_all_tin_types(tin_box);
	}
	break;
	}
	return;
}

Integer Set_tin_access(Tin_Box &tin_box, Text title, Attributes widget_params)
{
	Integer rv = -1;
	// ==== Access ====
	Text access = "";
	rv = FW_Attributes_Get_value_text(widget_params, PARAM_NAME_TIN_ACCESS, access);
	if (rv != 0)
		access = "rw";

	Integer accesses[2];
	Integer num_accs = 0;
	FW_Array_Fill(accesses, 2, 0);

	if (Find_text(Text_lower(access), "r"))
		accesses[++num_accs] = 1;
	if (Find_text(Text_lower(access), "w"))
		accesses[++num_accs] = 2;

	switch (num_accs)
	{
	case (1):
	{
		rv = Set_tin_access(tin_box, accesses[1]);
	}
	break;

	case (2):
	{
		rv = Set_tin_access(tin_box, accesses[1], accesses[2]);
	}
	break;

	default:
	{
		Print("WARN : All Tin Access modes disabled for widget < " + title +
			  " >. Re-enabling all. Check settings.");
		Print();
		rv = Set_tin_access(tin_box, 1, 2);
	}
	break;
	}
	return rv;
}

Integer Set_view_types(View_Box &view_box, Text title, Attributes widget_params)
{
	Integer rv = -1;
	Integer plan, pers, sect, hidd;
	plan = pers = sect = hidd = TRUE;

	// ===== Types ====
	Set_all_view_types(view_box);

	rv = FW_Attributes_Get_value_boolean(widget_params, PARAM_NAME_VIEW_TYPE_PLAN, plan);
	if (rv != 0)
		plan = TRUE;
	rv = FW_Attributes_Get_value_boolean(widget_params, PARAM_NAME_VIEW_TYPE_PERSPECTIVE, pers);
	if (rv != 0)
		pers = TRUE;
	rv = FW_Attributes_Get_value_boolean(widget_params, PARAM_NAME_VIEW_TYPE_SECTION, sect);
	if (rv != 0)
		sect = TRUE;
	rv = FW_Attributes_Get_value_boolean(widget_params, PARAM_NAME_VIEW_TYPE_HIDDEN, hidd);
	if (rv != 0)
		hidd = TRUE;

	Integer types[4];
	Integer num_types = 0;
	FW_Array_Fill(types, 4, 0);

	if (plan)
		types[++num_types] = 1;
	if (pers)
		types[++num_types] = 2;
	if (sect)
		types[++num_types] = 3;
	if (hidd)
		types[++num_types] = 4;

	switch (num_types)
	{
	case (1):
	{
		rv = Set_view_type(view_box, types[1]);
	}
	break;

	case (2):
	{
		rv = Set_view_type(view_box, types[1], types[2]);
	}
	break;

	case (3):
	{
		rv = Set_view_type(view_box, types[1], types[2], types[3]);
	}
	break;

	case (4):
	{
		rv = Set_all_view_types(view_box);
	}
	break;

	default:
	{
		Print("WARN : All View Types disabled for widget < " + title +
			  " >. Re-enabling all. Check settings.");
		Print();
		rv = Set_all_view_types(view_box);
	}
	break;
	}
	return rv;
}

Integer Create_widget(Text widget_type, Text widget_title, Attributes &widget_params,
					  Colour_Message_Box &message, Widget &widget)
{
	Integer rv = -1;
	Text default_value = "";
	Integer width_in_chars = -1;
	Integer is_optional = -1;
	Text tooltip = "";
	widget_type = Text_upper(widget_type);

	// Common widget settings
	default_value = Get_default_widget_value(widget_params);
	width_in_chars = Get_width_in_chars_value(widget_params);
	is_optional = Get_widget_optional(widget_params);
	tooltip = Get_widget_tooltip(widget_params);

	switch (widget_type)
	{
	// ##### INPUT WIDGETS #####

	// Angle_Box
	case ("ANGLE"):
	case ("ANG"):
	case ("AN"):
	{
		Angle_Box curr_widget = Create_angle_box(widget_title, message);
		// Common settings
		if (default_value != "")
			Set_data(curr_widget, default_value);
		if (width_in_chars > 0)
			Set_width_in_chars(curr_widget, width_in_chars);
		if (tooltip != "")
			Set_tooltip(curr_widget, tooltip);
		if (is_optional > 0)
			Set_optional(curr_widget, is_optional);

		widget = Cast(curr_widget);
		return 0;
	}
	break;

	// Billboard_Box
	case ("BILLBOARD"):
	case ("BBOARD"):
	case ("BILL"):
	{
		Billboard_Box curr_widget = Create_billboard_box(widget_title, message);
		// Common settings
		if (default_value != "")
			Set_data(curr_widget, default_value);
		if (width_in_chars > 0)
			Set_width_in_chars(curr_widget, width_in_chars);
		if (tooltip != "")
			Set_tooltip(curr_widget, tooltip);
		if (is_optional > 0)
			Set_optional(curr_widget, is_optional);

		widget = Cast(curr_widget);
		return 0;
	}
	break;

	// bitmap_Fill_Box
	case ("BITMAP_FILL"):
	case ("BIT_FILL"):
	case ("BFILL"):
	case ("BF"):
	{
		Bitmap_Fill_Box curr_widget = Create_bitmap_fill_box(widget_title, message);
		// Common settings
		if (default_value != "")
			Set_data(curr_widget, default_value);
		if (width_in_chars > 0)
			Set_width_in_chars(curr_widget, width_in_chars);
		if (tooltip != "")
			Set_tooltip(curr_widget, tooltip);
		if (is_optional > 0)
			Set_optional(curr_widget, is_optional);

		widget = Cast(curr_widget);
		return 0;
	}
	break;

	// Bitmap_List_Box - NOT IMPLEMENTED - NO USER INPUT

	// Chainage_Box
	case ("CHAINAGE"):
	case ("CHAIN"):
	case ("CHNG"):
	case ("CHN"):
	case ("CHG"):
	{
		Chainage_Box curr_widget = Create_chainage_box(widget_title, message);
		// Common settings
		if (default_value != "")
			Set_data(curr_widget, default_value);
		if (width_in_chars > 0)
			Set_width_in_chars(curr_widget, width_in_chars);
		if (tooltip != "")
			Set_tooltip(curr_widget, tooltip);
		if (is_optional > 0)
			Set_optional(curr_widget, is_optional);

		widget = Cast(curr_widget);
		return 0;
	}
	break;

	// Choice_Box
	case ("CHOICE"):
	case ("CHC"):
	{
		Attributes choice_atts;
		Integer num_params = 0;

		Choice_Box curr_widget = Create_choice_box(widget_title, message);

		Get_number_of_attributes(widget_params, num_params);
		if (num_params <= 0)
		{
			Print("WARN : No parameters specified for Choice_Box widget < " + widget_title +
				  " >. No items to list. ");
			Print();
			return 1;
		}
		Text choices[num_params];
		for (Integer i = 1; i <= num_params; i++)
		{
			Text curr_value = "";
			rv = Get_attribute(widget_params, i, curr_value);
			if (rv != 0)
				continue;
			choices[i] = curr_value;
		}
		Set_data(curr_widget, num_params, choices);
		// Common settings
		if (default_value != "")
			Set_data(curr_widget, default_value);
		if (width_in_chars > 0)
			Set_width_in_chars(curr_widget, width_in_chars);
		if (tooltip != "")
			Set_tooltip(curr_widget, tooltip);
		if (is_optional > 0)
			Set_optional(curr_widget, is_optional);

		widget = Cast(curr_widget);
		return 0;
	}
	break;

	// Colour_Box
	case ("COLOUR"):
	case ("COLOR"):
	case ("COL"):
	case ("CLR"):
	case ("RGB"):
	{
		Colour_Box curr_widget = Create_colour_box(widget_title, message);
		// Common settings
		if (default_value != "")
			Set_data(curr_widget, default_value);
		if (width_in_chars > 0)
			Set_width_in_chars(curr_widget, width_in_chars);
		if (tooltip != "")
			Set_tooltip(curr_widget, tooltip);
		if (is_optional > 0)
			Set_optional(curr_widget, is_optional);

		widget = Cast(curr_widget);
		return 0;
	}
	break;

	// Date_Time_Box
	case ("DATE_TIME"):
	case ("DATETIME"):
	case ("DATE"):
	case ("TIME"):
	case ("DT"):
	{
		Text is_gmt, format;
		is_gmt = format = "";

		Date_Time_Box curr_widget = Create_date_time_box(widget_title, message);
		// Common settings
		if (default_value != "")
			Set_data(curr_widget, default_value);
		if (width_in_chars > 0)
			Set_width_in_chars(curr_widget, width_in_chars);
		if (tooltip != "")
			Set_tooltip(curr_widget, tooltip);
		if (is_optional > 0)
			Set_optional(curr_widget, is_optional);

		if (Get_attribute(widget_params, PARAM_NAME_DATE_TIME_IS_GMT, is_gmt) == 0)
		{
			rv = Set_gmt(curr_widget, True_false(is_gmt));
			if (rv != 0)
			{
				Print("WARN : Problem setting GMT for Date_Time_Box widget < " + widget_title +
					  " > using parameter value < " + is_gmt + " >. Widget may be incorrect.");
				Print();
			}
		}
		if (Get_attribute(widget_params, PARAM_NAME_DATE_TIME_FORMAT, format) == 0)
		{
			Integer format_int = 0;
			rv = From_text(format, format_int);
			if (rv == 0)
			{
				rv = Set_format(curr_widget, format_int);
			}
			if (rv != 0)
			{
				Print("WARN : Problem setting Format for Date_Time_Box widget < " + widget_title +
					  " > using parameter value < " + format + " >. Widget may be incorrect.");
				Print();
			}
		}
		widget = Cast(curr_widget);
		return 0;
	}
	break;

	// Directory_Box
	case ("DIRECTORY"):
	case ("FOLDER"):
	case ("FLDR"):
	case ("DIR"):
	{
		Integer mode = CHECK_DIRECTORY_EXISTS;
		rv = FW_Attributes_Get_value_integer(widget_params, PARAM_NAME_GENERIC_CREATE_MODE, mode);
		if (rv != 0)
			mode = CHECK_DIRECTORY_EXISTS;

		Directory_Box curr_widget = Create_directory_box(widget_title, message, mode);
		// Common settings
		if (default_value != "")
			Set_data(curr_widget, default_value);
		if (width_in_chars > 0)
			Set_width_in_chars(curr_widget, width_in_chars);
		if (tooltip != "")
			Set_tooltip(curr_widget, tooltip);
		if (is_optional > 0)
			Set_optional(curr_widget, is_optional);

		widget = Cast(curr_widget);
		return 0;
	}
	break;

	case ("DIR_NEW"):
	case ("DIR_N"):
	case ("DIRN"):
	{
		Integer mode = CHECK_DIRECTORY_NEW;
		Directory_Box curr_widget = Create_directory_box(widget_title, message, mode);
		// Common settings
		if (default_value != "")
			Set_data(curr_widget, default_value);
		if (width_in_chars > 0)
			Set_width_in_chars(curr_widget, width_in_chars);
		if (tooltip != "")
			Set_tooltip(curr_widget, tooltip);
		if (is_optional > 0)
			Set_optional(curr_widget, is_optional);

		widget = Cast(curr_widget);
		return 0;
	}
	break;

	case ("DIR_CREATE"):
	case ("DIR_C"):
	case ("DIRC"):
	{
		Integer mode = CHECK_DIRECTORY_CREATE;
		Directory_Box curr_widget = Create_directory_box(widget_title, message, mode);
		// Common settings
		if (default_value != "")
			Set_data(curr_widget, default_value);
		if (width_in_chars > 0)
			Set_width_in_chars(curr_widget, width_in_chars);
		if (tooltip != "")
			Set_tooltip(curr_widget, tooltip);
		if (is_optional > 0)
			Set_optional(curr_widget, is_optional);

		widget = Cast(curr_widget);
		return 0;
	}
	break;

	case ("DIR_EXIST"):
	case ("DIR_EX"):
	case ("DIR_E"):
	case ("DIRE"):
	{
		Integer mode = CHECK_DIRECTORY_EXISTS;
		Directory_Box curr_widget = Create_directory_box(widget_title, message, mode);
		// Common settings
		if (default_value != "")
			Set_data(curr_widget, default_value);
		if (width_in_chars > 0)
			Set_width_in_chars(curr_widget, width_in_chars);
		if (tooltip != "")
			Set_tooltip(curr_widget, tooltip);
		if (is_optional > 0)
			Set_optional(curr_widget, is_optional);

		widget = Cast(curr_widget);
		return 0;
	}
	break;

	// Draw_Box - NOT IMPLEMENTED - NO USER INPUT

	// File_Box
	case ("FILE"):
	case ("F"):
	{
		Integer mode = CHECK_FILE;
		Text wildcard = "*.*";

		rv = FW_Attributes_Get_value_integer(widget_params, PARAM_NAME_GENERIC_CREATE_MODE, mode);
		if (rv != 0)
			mode = CHECK_FILE;

		File_Box curr_widget = Create_file_box(widget_title, message, mode, wildcard);

		// Common settings
		if (default_value != "")
			Set_data(curr_widget, default_value);
		if (width_in_chars > 0)
			Set_width_in_chars(curr_widget, width_in_chars);
		if (tooltip != "")
			Set_tooltip(curr_widget, tooltip);
		if (is_optional > 0)
			Set_optional(curr_widget, is_optional);

		rv = FW_Attributes_Get_value_text(widget_params, PARAM_NAME_FILE_BOX_WILDCARD, wildcard);
		if (rv == 0)
			Set_wildcard(curr_widget, wildcard);

		Text dir = "";
		Integer many, enc, shenc, lib, sup;

		rv = FW_Attributes_Get_value_text(widget_params, PARAM_NAME_FILE_BOX_DIRECTORY, dir);
		if (rv == 0)
			Set_directory(curr_widget, dir);

		rv = FW_Attributes_Get_value_boolean(widget_params, PARAM_NAME_FILE_BOX_MANY, many);
		if (rv == 0)
			Set_many(curr_widget, many);

		rv = FW_Attributes_Get_value_integer(widget_params, PARAM_NAME_FILE_BOX_ENCODING, enc);
		if (rv == 0)
			Set_encoding(curr_widget, enc);

		rv = FW_Attributes_Get_value_boolean(widget_params, PARAM_NAME_FILE_BOX_SHOW_ENCODING, shenc);
		if (rv == 0)
			Set_show_encodings(curr_widget, shenc);

		rv = FW_Attributes_Get_value_boolean(widget_params, PARAM_NAME_FILE_BOX_LIBRARY, lib);
		if (rv == 0)
			Set_libraries(curr_widget, lib);

		rv = FW_Attributes_Get_value_boolean(widget_params, PARAM_NAME_FILE_BOX_SETUPS, sup);
		if (rv == 0)
			Set_setups(curr_widget, sup);

		widget = Cast(curr_widget);
		return 0;
	}
	break;

	// Function_Box
	case ("FUNCTION"):
	case ("FUNC"):
	case ("FUN"):
	case ("FN"):
	{
		Integer type_int = 0;
		Text type_text = "";
		Integer mode = CHECK_FUNCTION_EXISTS;
		rv = FW_Attributes_Get_value_integer(widget_params, PARAM_NAME_GENERIC_CREATE_MODE, mode);
		if (rv != 0)
			mode = CHECK_FUNCTION_EXISTS;

		rv = FW_Attributes_Get_value_integer(widget_params, PARAM_NAME_FUNC_BOX_TYPE_INT, type_int);
		if (rv != 0)
			type_int = 0;

		Function_Box curr_widget = Create_function_box(widget_title, message, mode, type_int);
		// Common settings
		if (default_value != "")
			Set_data(curr_widget, default_value);
		if (width_in_chars > 0)
			Set_width_in_chars(curr_widget, width_in_chars);
		if (tooltip != "")
			Set_tooltip(curr_widget, tooltip);
		if (is_optional > 0)
			Set_optional(curr_widget, is_optional);

		rv = FW_Attributes_Get_value_text(widget_params, PARAM_NAME_FUNC_BOX_TYPE_TEXT, type_text);
		if (rv == 0)
			Set_type(curr_widget, type_text);

		widget = Cast(curr_widget);
		return 0;
	}
	break;

	// HyperLink_Box - NOT IMPLEMENTED - NO USER INPUT

	// Input_Box
	case ("INPUT"):
	case ("INP"):
	{
		Input_Box curr_widget = Create_input_box(widget_title, message);
		// Common settings
		if (default_value != "")
			Set_data(curr_widget, default_value);
		if (width_in_chars > 0)
			Set_width_in_chars(curr_widget, width_in_chars);
		if (tooltip != "")
			Set_tooltip(curr_widget, tooltip);
		if (is_optional > 0)
			Set_optional(curr_widget, is_optional);
		// Specific settings
		Integer num_lines = 1;
		rv = FW_Attributes_Get_value_integer(widget_params, PARAM_NAME_INPUT_BOX_MULTILINES, num_lines);
		if (rv == 0)
			Set_multi_line(curr_widget, num_lines);

		widget = Cast(curr_widget);
		return 0;
	}
	break;

	// Integer_Box
	case ("INTEGER"):
	case ("INT"):
	{
		Integer_Box curr_widget = Create_integer_box(widget_title, message);
		// Common settings
		if (default_value != "")
			Set_data(curr_widget, default_value);
		if (width_in_chars > 0)
			Set_width_in_chars(curr_widget, width_in_chars);
		if (tooltip != "")
			Set_tooltip(curr_widget, tooltip);
		if (is_optional > 0)
			Set_optional(curr_widget, is_optional);

		widget = Cast(curr_widget);
		return 0;
	}
	break;

	// Justify_Box
	case ("JUSTIFY"):
	case ("JUST"):
	case ("J"):
	{
		Justify_Box curr_widget = Create_justify_box(widget_title, message);
		// Common settings
		if (default_value != "")
			Set_data(curr_widget, default_value);
		if (width_in_chars > 0)
			Set_width_in_chars(curr_widget, width_in_chars);
		if (tooltip != "")
			Set_tooltip(curr_widget, tooltip);
		if (is_optional > 0)
			Set_optional(curr_widget, is_optional);

		widget = Cast(curr_widget);
		return 0;
	}
	break;

	// Linestyle_Box
	case ("LINESTYLE"):
	case ("LSTYLE"):
	case ("L"):
	case ("LS"):
	{
		Integer mode = CHECK_LINESTYLE_MUST_EXIST;
		rv = FW_Attributes_Get_value_integer(widget_params, PARAM_NAME_GENERIC_CREATE_MODE, mode);
		if (rv != 0)
			mode = CHECK_LINESTYLE_MUST_EXIST;

		Linestyle_Box curr_widget = Create_linestyle_box(widget_title, message, mode);
		// Common settings
		if (default_value != "")
			Set_data(curr_widget, default_value);
		if (width_in_chars > 0)
			Set_width_in_chars(curr_widget, width_in_chars);
		if (tooltip != "")
			Set_tooltip(curr_widget, tooltip);
		if (is_optional > 0)
			Set_optional(curr_widget, is_optional);

		widget = Cast(curr_widget);
		return 0;
	}
	break;

	// List_Box - NOT IMPLEMENTED

	// Map_File_Box
	case ("MAP_FILE"):
	case ("MAPFILE"):
	case ("MAPPING"):
	case ("MAP"):
	{
		Integer mode;
		rv = FW_Attributes_Get_value_integer(widget_params, PARAM_NAME_GENERIC_CREATE_MODE, mode);
		if (rv != 0)
			mode = CHECK_FILE_MUST_EXIST;

		Map_File_Box curr_widget = Create_map_file_box(widget_title, message, mode);
		// Common settings
		if (default_value != "")
			Set_data(curr_widget, default_value);
		if (width_in_chars > 0)
			Set_width_in_chars(curr_widget, width_in_chars);
		if (tooltip != "")
			Set_tooltip(curr_widget, tooltip);
		if (is_optional > 0)
			Set_optional(curr_widget, is_optional);

		widget = Cast(curr_widget);
		return 0;
	}
	break;

	// Model_Box
	case ("MODEL"):
	case ("MOD"):
	{
		Integer mode;
		rv = FW_Attributes_Get_value_integer(widget_params, PARAM_NAME_GENERIC_CREATE_MODE, mode);
		if (rv != 0)
			mode = CHECK_MODEL_EXISTS;

		Model_Box curr_widget = Create_model_box(widget_title, message, mode);
		// Common settings
		if (default_value != "")
			Set_data(curr_widget, default_value);
		if (width_in_chars > 0)
			Set_width_in_chars(curr_widget, width_in_chars);
		if (tooltip != "")
			Set_tooltip(curr_widget, tooltip);
		if (is_optional > 0)
			Set_optional(curr_widget, is_optional);

		widget = Cast(curr_widget);
		return 0;
	}
	break;

	case ("MODEL_EX"):
	case ("MOD_EX"):
	case ("ME"):
	{
		Integer mode = CHECK_MODEL_MUST_EXIST;
		Model_Box curr_widget = Create_model_box(widget_title, message, mode);
		// Common settings
		if (default_value != "")
			Set_data(curr_widget, default_value);
		if (width_in_chars > 0)
			Set_width_in_chars(curr_widget, width_in_chars);
		if (tooltip != "")
			Set_tooltip(curr_widget, tooltip);
		if (is_optional > 0)
			Set_optional(curr_widget, is_optional);

		widget = Cast(curr_widget);
		return 0;
	}
	break;

	case ("MODEL_NEW"):
	case ("MOD_NEW"):
	case ("MN"):
	{
		Integer mode = CHECK_MODEL_MUST_NOT_EXIST;
		Model_Box curr_widget = Create_model_box(widget_title, message, mode);
		// Common settings
		if (default_value != "")
			Set_data(curr_widget, default_value);
		if (width_in_chars > 0)
			Set_width_in_chars(curr_widget, width_in_chars);
		if (tooltip != "")
			Set_tooltip(curr_widget, tooltip);
		if (is_optional > 0)
			Set_optional(curr_widget, is_optional);

		widget = Cast(curr_widget);
		return 0;
	}
	break;

	// Name_Box
	case ("NAME"):
	case ("NA"):
	{
		Name_Box curr_widget = Create_name_box(widget_title, message);
		// Common settings
		if (default_value != "")
			Set_data(curr_widget, default_value);
		if (width_in_chars > 0)
			Set_width_in_chars(curr_widget, width_in_chars);
		if (tooltip != "")
			Set_tooltip(curr_widget, tooltip);
		if (is_optional > 0)
			Set_optional(curr_widget, is_optional);

		widget = Cast(curr_widget);
		return 0;
	}
	break;

	// Named_Tick_Box
	case ("NAMED_TICK"):
	case ("NAMEDTICK"):
	case ("BOOLEAN"):
	case ("TICK"):
	case ("TRUE_FALSE"):
	case ("CHECK"):
	case ("CHK"):
	case ("T_F"):
	{
		Integer state = FALSE;
		Text response = "changed";
		rv = FW_Attributes_Get_value_boolean(widget_params, PARAM_NAME_DEFAULT_VALUE, state);
		if (rv != 0)
			state = FALSE;

		Named_Tick_Box curr_widget = Create_named_tick_box(widget_title, state, response);
		// Common settings
		if (width_in_chars > 0)
			Set_width_in_chars(curr_widget, width_in_chars);
		if (tooltip != "")
			Set_tooltip(curr_widget, tooltip);
		if (is_optional > 0)
			Set_optional(curr_widget, is_optional);

		widget = Cast(curr_widget);
		return 0;
	}
	break;

	// New_Select_Box
	case ("NEW_SELECT"):
	case ("STRING"):
	case ("SELECT"):
	case ("STR"):
	case ("PICK"):
	{
		Text msg, type;
		Integer snap, dir, mode;

		rv = FW_Attributes_Get_value_text(widget_params, PARAM_NAME_SELECT_MESSAGE, msg);
		if (rv != 0)
			msg = "Select a string";
		rv = FW_Attributes_Get_value_integer(widget_params, PARAM_NAME_GENERIC_CREATE_MODE, mode);
		if (rv != 0)
			mode = SELECT_STRING;

		New_Select_Box curr_widget = Create_new_select_box(widget_title, msg, mode, message);
		// Common settings
		if (default_value != "")
			Set_data(curr_widget, default_value);
		if (width_in_chars > 0)
			Set_width_in_chars(curr_widget, width_in_chars);
		if (tooltip != "")
			Set_tooltip(curr_widget, tooltip);
		if (is_optional > 0)
			Set_optional(curr_widget, is_optional);
		// Specific settings
		rv = FW_Attributes_Get_value_text(widget_params, PARAM_NAME_SELECT_TYPE, type);
		if (rv == 0)
			Set_select_type(curr_widget, type);
		rv = FW_Attributes_Get_value_integer(widget_params, PARAM_NAME_SELECT_SNAP, snap);
		if (rv == 0)
			Set_select_snap_mode(curr_widget, snap);
		rv = FW_Attributes_Get_value_integer(widget_params, PARAM_NAME_SELECT_DIR, dir);
		if (rv == 0)
			Set_select_direction(curr_widget, dir);

		widget = Cast(curr_widget);
		return 0;
	}
	break;

	// New_XYZ_Box
	case ("NEW_XYZ"):
	case ("NEWXYZ"):
	case ("XYZ_NEW"):
	{
		Real x, y, z;
		Null(x, y, z);
		New_XYZ_Box curr_widget = Create_new_xyz_box(widget_title, message);
		// Common settings
		if (default_value != "")
			Set_data(curr_widget, default_value);
		if (width_in_chars > 0)
			Set_width_in_chars(curr_widget, width_in_chars);
		if (tooltip != "")
			Set_tooltip(curr_widget, tooltip);
		if (is_optional > 0)
			Set_optional(curr_widget, is_optional);
		// Specific settings
		rv = FW_Attributes_Get_value_real(widget_params, PARAM_NAME_XYZ_Z, x);
		if (rv != 0)
			Null(x);
		rv = FW_Attributes_Get_value_real(widget_params, PARAM_NAME_XYZ_Z, y);
		if (rv != 0)
			Null(y);
		rv = FW_Attributes_Get_value_real(widget_params, PARAM_NAME_XYZ_Z, z);
		if (rv != 0)
			Null(z);
		if ((!Is_null(x)) && (!Is_null(y)) && (!Is_null(z)))
		{
			Set_data(curr_widget, x, y, z);
		}

		widget = Cast(curr_widget);
		return 0;
	}
	break;

	// Plotter_Box
	case ("PLOTTER"):
	case ("PLOTTERS"):
	case ("PRINTERS"):
	case ("PRINTER"):
	case ("PLOT"):
	case ("PRINT"):
	{
		Plotter_Box curr_widget = Create_plotter_box(widget_title, message);
		// Common settings
		if (default_value != "")
			Set_data(curr_widget, default_value);
		if (width_in_chars > 0)
			Set_width_in_chars(curr_widget, width_in_chars);
		if (tooltip != "")
			Set_tooltip(curr_widget, tooltip);
		if (is_optional > 0)
			Set_optional(curr_widget, is_optional);

		widget = Cast(curr_widget);
		return 0;
	}
	break;

	// Polygon_Box
	case ("POLYGON"):
	case ("POLY"):
	{
		Integer mode = 0;
		Text msg = "";
		rv = FW_Attributes_Get_value_text(widget_params, PARAM_NAME_SELECT_MESSAGE, msg);
		if (rv != 0)
			msg = "Select a string";

		rv = FW_Attributes_Get_value_integer(widget_params, PARAM_NAME_GENERIC_CREATE_MODE, mode);
		if (rv != 0)
			mode = 0;
		mode = 0;

		Polygon_Box curr_widget = Create_polygon_box(widget_title, msg, mode, message);
		// Common settings
		if (default_value != "")
			Set_data(curr_widget, default_value);
		if (width_in_chars > 0)
			Set_width_in_chars(curr_widget, width_in_chars);
		if (tooltip != "")
			Set_tooltip(curr_widget, tooltip);
		if (is_optional > 0)
			Set_optional(curr_widget, is_optional);

		widget = Cast(curr_widget);
		return 0;
	}
	break;

	// Real_Box
	case ("REAL"):
	case ("DECIMAL"):
	case ("DEC"):
	{
		Real_Box curr_widget = Create_real_box(widget_title, message);
		// Common settings
		if (default_value != "")
			Set_data(curr_widget, default_value);
		if (width_in_chars > 0)
			Set_width_in_chars(curr_widget, width_in_chars);
		if (tooltip != "")
			Set_tooltip(curr_widget, tooltip);
		if (is_optional > 0)
			Set_optional(curr_widget, is_optional);

		widget = Cast(curr_widget);
		return 0;
	}
	break;

	// Report_Box
	case ("REPORT"):
	case ("RPT"):
	case ("REP"):
	{
		Integer mode = CHECK_FILE;
		rv = FW_Attributes_Get_value_integer(widget_params, PARAM_NAME_GENERIC_CREATE_MODE, mode);
		if (rv != 0)
			mode = CHECK_FILE;

		Report_Box curr_widget = Create_report_box(widget_title, message, mode);
		// Common settings
		if (default_value != "")
			Set_data(curr_widget, default_value);
		if (width_in_chars > 0)
			Set_width_in_chars(curr_widget, width_in_chars);
		if (tooltip != "")
			Set_tooltip(curr_widget, tooltip);
		if (is_optional > 0)
			Set_optional(curr_widget, is_optional);

		widget = Cast(curr_widget);
		return 0;
	}
	break;

	// Screen_Text
	case ("SCREEN"):
	case ("LABEL"):
	case ("SCR"):
	{
		Screen_Text curr_widget = Create_screen_text(widget_title);
		// Common settings
		if (default_value != "")
			Set_data(curr_widget, default_value);
		if (width_in_chars > 0)
			Set_width_in_chars(curr_widget, width_in_chars);
		if (tooltip != "")
			Set_tooltip(curr_widget, tooltip);
		if (is_optional > 0)
			Set_optional(curr_widget, is_optional);

		widget = Cast(curr_widget);
		return 0;
	}
	break;

	// Select_Box - DEPRECATED
	// Select_Boxes - DEPRECATED

	// Sheet_Size_Box
	case ("SHEET_SIZE"):
	case ("SHEETSIZE"):
	case ("SHEETS"):
	case ("SHEET"):
	case ("SHT"):
	{
		Sheet_Size_Box curr_widget = Create_sheet_size_box(widget_title, message);
		// Common settings
		if (default_value != "")
			Set_data(curr_widget, default_value);
		if (width_in_chars > 0)
			Set_width_in_chars(curr_widget, width_in_chars);
		if (tooltip != "")
			Set_tooltip(curr_widget, tooltip);
		if (is_optional > 0)
			Set_optional(curr_widget, is_optional);

		widget = Cast(curr_widget);
		return 0;
	}
	break;

	// Slider_Box
	// Will this value actually be captured by a parameter/chain??
	case ("SLIDER"):
	case ("SLIDE"):
	case ("SLD"):
	{
		Integer width, height, min_value, max_value, tick_interval, horizontal;

		rv = FW_Attributes_Get_value_integer(widget_params, PARAM_NAME_SLIDER_WIDTH, width);
		if (rv != 0)
			width = 100;
		rv = FW_Attributes_Get_value_integer(widget_params, PARAM_NAME_SLIDER_HEIGHT, height);
		if (rv != 0)
			height = 30;
		rv = FW_Attributes_Get_value_integer(widget_params, PARAM_NAME_SLIDER_MIN, min_value);
		if (rv != 0)
			min_value = 0;
		rv = FW_Attributes_Get_value_integer(widget_params, PARAM_NAME_SLIDER_MAX, max_value);
		if (rv != 0)
			max_value = 100;
		rv = FW_Attributes_Get_value_integer(widget_params, PARAM_NAME_SLIDER_INTERVAL, tick_interval);
		if (rv != 0)
			tick_interval = 10;
		rv = FW_Attributes_Get_value_integer(widget_params, PARAM_NAME_SLIDER_HORIZONTAL, horizontal);
		if (rv != 0)
			horizontal = TRUE;

		Slider_Box curr_widget = Create_slider_box(widget_title, width, height,
												   min_value, max_value,
												   tick_interval, horizontal);
		// Common settings
		// N/A	if (default_value != "")		Set_data(curr_widget, default_value);
		if (width_in_chars > 0)
			Set_width_in_chars(curr_widget, width_in_chars);
		if (tooltip != "")
			Set_tooltip(curr_widget, tooltip);
		if (is_optional > 0)
			Set_optional(curr_widget, is_optional);

		widget = Cast(curr_widget);
		return 0;
	}
	break;

	// Source_Box
	case ("SOURCE"):
	case ("SRC"):
	{
		Integer flags, default_flag;
		rv = FW_Attributes_Get_value_integer(widget_params, PARAM_NAME_SOURCE_BOX_FLAGS, flags);
		// Print("Get source box flags : rv = " + To_text(rv) + " , flags = " + To_text(flags) + "\n");
		if (rv != 0)
			flags = Source_Box_All;
		rv = FW_Attributes_Get_value_integer(widget_params, PARAM_NAME_SOURCE_BOX_DEFAULT, default_flag);
		// Print("Get source box default : rv = " + To_text(rv) + " , default = " + To_text(default_flag) + "\n");
		if (rv != 0)
			default_flag = Source_Box_Model;

		Source_Box curr_widget = Create_source_box(widget_title, message, flags, default_flag);
		// Common settings
		if (default_value != "")
			Set_data(curr_widget, default_value);
		if (width_in_chars > 0)
			Set_width_in_chars(curr_widget, width_in_chars);
		if (tooltip != "")
			Set_tooltip(curr_widget, tooltip);
		if (is_optional > 0)
			Set_optional(curr_widget, is_optional);

		widget = Cast(curr_widget);
		return 0;
	}
	break;

	// Symbol_Box
	case ("SYMBOL"):
	case ("SYMB"):
	case ("SYM"):
	{
		Integer mode;
		rv = FW_Attributes_Get_value_integer(widget_params, PARAM_NAME_GENERIC_CREATE_MODE, mode);
		if (rv != 0)
			mode = CHECK_LINESTYLE_MUST_EXIST;

		Symbol_Box curr_widget = Create_symbol_box(widget_title, message, mode);
		// Common settings
		if (default_value != "")
			Set_data(curr_widget, default_value);
		if (width_in_chars > 0)
			Set_width_in_chars(curr_widget, width_in_chars);
		if (tooltip != "")
			Set_tooltip(curr_widget, tooltip);
		if (is_optional > 0)
			Set_optional(curr_widget, is_optional);

		widget = Cast(curr_widget);
		return 0;
	}
	break;

	// Target_Box
	case ("TARGET"):
	case ("TARG"):
	case ("TRG"):
	{
		Integer flags, default_flag;
		rv = FW_Attributes_Get_value_integer(widget_params, PARAM_NAME_SOURCE_BOX_FLAGS, flags);
		if (rv != 0)
			flags = Target_Box_Move_Copy_All;
		rv = FW_Attributes_Get_value_integer(widget_params, PARAM_NAME_SOURCE_BOX_DEFAULT, flags);
		if (rv != 0)
			default_flag = Target_Box_Move_To_Original_Model;

		Target_Box curr_widget = Create_target_box(widget_title, message, flags, default_flag);
		// Common settings
		// N/A	if (default_value != "")		Set_data(curr_widget, default_value);
		if (width_in_chars > 0)
			Set_width_in_chars(curr_widget, width_in_chars);
		if (tooltip != "")
			Set_tooltip(curr_widget, tooltip);
		if (is_optional > 0)
			Set_optional(curr_widget, is_optional);

		widget = Cast(curr_widget);
		return 0;
	}
	break;

	// Template_Box
	case ("TEMPLATE"):
	case ("TEMPLATES"):
	case ("TEMPL"):
	case ("TEMP"):
	case ("TPL"):
	{
		Integer mode;
		rv = FW_Attributes_Get_value_integer(widget_params, PARAM_NAME_GENERIC_CREATE_MODE, mode);
		if (rv != 0)
			mode = CHECK_TEMPLATE_MUST_EXIST;

		Template_Box curr_widget = Create_template_box(widget_title, message, mode);
		// Common settings
		if (default_value != "")
			Set_data(curr_widget, default_value);
		if (width_in_chars > 0)
			Set_width_in_chars(curr_widget, width_in_chars);
		if (tooltip != "")
			Set_tooltip(curr_widget, tooltip);
		if (is_optional > 0)
			Set_optional(curr_widget, is_optional);

		widget = Cast(curr_widget);
		return 0;
	}
	break;

	// Text_Style_Box
	case ("TEXTSTYLE"):
	case ("TSTYLE"):
	case ("TS"):
	{
		Text_Style_Box curr_widget = Create_text_style_box(widget_title, message);
		// Common settings
		if (default_value != "")
			Set_data(curr_widget, default_value);
		if (width_in_chars > 0)
			Set_width_in_chars(curr_widget, width_in_chars);
		if (tooltip != "")
			Set_tooltip(curr_widget, tooltip);
		if (is_optional > 0)
			Set_optional(curr_widget, is_optional);

		widget = Cast(curr_widget);
		return 0;
	}
	break;

	// Text_Units_Box
	case ("TEXT_UNITS"):
	case ("TEXTUNITS"):
	case ("UNITS"):
	case ("TU"):
	{
		Text_Units_Box curr_widget = Create_text_units_box(widget_title, message);
		// Common settings
		if (default_value != "")
			Set_data(curr_widget, default_value);
		if (width_in_chars > 0)
			Set_width_in_chars(curr_widget, width_in_chars);
		if (tooltip != "")
			Set_tooltip(curr_widget, tooltip);
		if (is_optional > 0)
			Set_optional(curr_widget, is_optional);

		widget = Cast(curr_widget);
		return 0;
	}
	break;

	// Textstyle_Data_Box
	case ("TEXTSTYLE_DATA"):
	case ("TSTYLE_DATA"):
	case ("TSD"):
	case ("TS_FAV"):
	{
		Integer flags, optional;

		rv = FW_Attributes_Get_value_integer(widget_params, PARAM_NAME_TEXTSTYLE_FLAG, flags);
		if (rv != 0)
			flags = V10_Show_all_boxes;

		rv = FW_Attributes_Get_value_integer(widget_params, PARAM_NAME_TEXTSTYLE_OPTIONAL, flags);
		if (rv != 0)
			optional = V10_Optional_std_boxes;

		Textstyle_Data_Box curr_widget = Create_textstyle_data_box(widget_title, message, flags, optional);
		// Common settings
		if (default_value != "")
			Set_data(curr_widget, default_value);
		if (width_in_chars > 0)
			Set_width_in_chars(curr_widget, width_in_chars);
		if (tooltip != "")
			Set_tooltip(curr_widget, tooltip);
		if (is_optional > 0)
			Set_optional(curr_widget, is_optional);

		widget = Cast(curr_widget);
		return 0;
	}
	break;

	// Text_Edit_Box - ??!!! WILL THIS CAPTURE !!!??
	case ("TEXT_EDIT"):
	{
		Integer num_lines = 3;
		Integer wrap, readonly, vscroll, hscroll;

		rv = FW_Attributes_Get_value_integer(widget_params, PARAM_NAME_TEXT_EDIT_LINES, num_lines);
		if (rv != 0)
			num_lines = 3;

		Text_Edit_Box curr_widget = Create_text_edit_box(widget_title, message, num_lines);
		// Common settings
		if (default_value != "")
			Set_data(curr_widget, default_value);
		if (width_in_chars > 0)
			Set_width_in_chars(curr_widget, width_in_chars);
		if (tooltip != "")
			Set_tooltip(curr_widget, tooltip);
		if (is_optional > 0)
			Set_optional(curr_widget, is_optional);
		// Specific settings
		rv = FW_Attributes_Get_value_boolean(widget_params, PARAM_NAME_TEXT_EDIT_WRAP, wrap);
		if (rv == 0)
			Set_word_wrap(curr_widget, wrap);
		rv = FW_Attributes_Get_value_boolean(widget_params, PARAM_NAME_TEXT_EDIT_READONLY, readonly);
		if (rv == 0)
			Set_read_only(curr_widget, readonly);
		rv = FW_Attributes_Get_value_boolean(widget_params, PARAM_NAME_TEXT_EDIT_HSCROLL, hscroll);
		if (rv == 0)
			Set_horizontal_scroll_bar(curr_widget, hscroll);
		rv = FW_Attributes_Get_value_boolean(widget_params, PARAM_NAME_TEXT_EDIT_WRAP, vscroll);
		if (rv == 0)
			Set_vertical_scroll_bar(curr_widget, vscroll);

		widget = Cast(curr_widget);
		return 0;
	}
	break;

	// Texture_Box
	case ("TEXTURE"):
	{
		Texture_Box curr_widget = Create_texture_box(widget_title, message);
		// Common settings
		if (default_value != "")
			Set_data(curr_widget, default_value);
		if (width_in_chars > 0)
			Set_width_in_chars(curr_widget, width_in_chars);
		if (tooltip != "")
			Set_tooltip(curr_widget, tooltip);
		if (is_optional > 0)
			Set_optional(curr_widget, is_optional);

		widget = Cast(curr_widget);
		return 0;
	}
	break;

	// Tick_Box - DEPRECATED - Use Named_Tick_Box

	// Tin_Box
	case ("TIN"):
	case ("TI"):
	{
		Integer mode;
		rv = FW_Attributes_Get_value_integer(widget_params, PARAM_NAME_GENERIC_CREATE_MODE, mode);
		if (rv != 0)
			mode = CHECK_TIN_EXISTS;

		Tin_Box curr_widget = Create_tin_box(widget_title, message, mode);
		// Common settings
		if (default_value != "")
			Set_data(curr_widget, default_value);
		if (width_in_chars > 0)
			Set_width_in_chars(curr_widget, width_in_chars);
		if (tooltip != "")
			Set_tooltip(curr_widget, tooltip);
		if (is_optional > 0)
			Set_optional(curr_widget, is_optional);
		// Specific Settings
		Set_tin_types(curr_widget, widget_title, widget_params);
		// Set_tin_access(curr_widget, widget_title, widget_params);
		Set_all_tin_modes(curr_widget);

		widget = Cast(curr_widget);
		return 0;
	}
	break;

	case ("TIN_EX"):
	case ("TX"):
	case ("TE"):
	{
		Integer mode = CHECK_TIN_MUST_EXIST;
		Tin_Box curr_widget = Create_tin_box(widget_title, message, mode);
		// Common settings
		if (default_value != "")
			Set_data(curr_widget, default_value);
		if (width_in_chars > 0)
			Set_width_in_chars(curr_widget, width_in_chars);
		if (tooltip != "")
			Set_tooltip(curr_widget, tooltip);
		if (is_optional > 0)
			Set_optional(curr_widget, is_optional);
		// Specific Settings
		Set_tin_types(curr_widget, widget_title, widget_params);
		// Set_tin_access(curr_widget, widget_title, widget_params);
		Set_all_tin_modes(curr_widget);

		widget = Cast(curr_widget);
		return 0;
	}

	case ("TIN_NEW"):
	case ("TN"):
	{
		Integer mode = CHECK_TIN_MUST_NOT_EXIST;
		Tin_Box curr_widget = Create_tin_box(widget_title, message, mode);
		Set_all_tin_types(curr_widget);
		// Common settings
		if (default_value != "")
			Set_data(curr_widget, default_value);
		if (width_in_chars > 0)
			Set_width_in_chars(curr_widget, width_in_chars);
		if (tooltip != "")
			Set_tooltip(curr_widget, tooltip);
		if (is_optional > 0)
			Set_optional(curr_widget, is_optional);
		// Specific Settings
		Set_tin_types(curr_widget, widget_title, widget_params);
		// Set_tin_access(curr_widget, widget_title, widget_params);
		Set_all_tin_modes(curr_widget);

		widget = Cast(curr_widget);
		return 0;
	}

	// View_Box
	case ("VIEW"):
	case ("V"):
	case ("VW"):
	{
		// Create a View widget
		Integer mode = CHECK_VIEW_MUST_EXIST;
		rv = FW_Attributes_Get_value_integer(widget_params, PARAM_NAME_GENERIC_CREATE_MODE, mode);
		if (rv != 0)
			mode = CHECK_VIEW_MUST_EXIST;

		View_Box curr_widget = Create_view_box(widget_title, message, mode);
		// Common settings
		if (default_value != "")
			Set_data(curr_widget, default_value);
		if (width_in_chars > 0)
			Set_width_in_chars(curr_widget, width_in_chars);
		if (tooltip != "")
			Set_tooltip(curr_widget, tooltip);
		if (is_optional > 0)
			Set_optional(curr_widget, is_optional);
		// Specific settings
		Integer engine = 0;
		rv = FW_Attributes_Get_value_integer(widget_params, PARAM_NAME_VIEW_ENGINE, engine);
		if (rv == 0)
			Set_view_engine(curr_widget, engine);
		Set_view_types(curr_widget, widget_title, widget_params);

		widget = Cast(curr_widget);
		return 0;
	}
	break;

	case ("VIEW_EX"):
	case ("VE"):
	case ("VX"):
	{
		View_Box curr_widget = Create_view_box(widget_title, message, CHECK_VIEW_MUST_EXIST);
		// Common settings
		if (default_value != "")
			Set_data(curr_widget, default_value);
		if (width_in_chars > 0)
			Set_width_in_chars(curr_widget, width_in_chars);
		if (tooltip != "")
			Set_tooltip(curr_widget, tooltip);
		if (is_optional > 0)
			Set_optional(curr_widget, is_optional);
		// Specific settings
		Integer engine = 0;
		rv = FW_Attributes_Get_value_integer(widget_params, PARAM_NAME_VIEW_ENGINE, engine);
		if (rv == 0)
			Set_view_engine(curr_widget, engine);
		Set_view_types(curr_widget, widget_title, widget_params);

		widget = Cast(curr_widget);
		return 0;
	}
	break;

	case ("VIEW_NEW"):
	case ("VN"):
	{
		View_Box curr_widget = Create_view_box(widget_title, message, CHECK_VIEW_MUST_NOT_EXIST);
		// Common settings
		if (default_value != "")
			Set_data(curr_widget, default_value);
		if (width_in_chars > 0)
			Set_width_in_chars(curr_widget, width_in_chars);
		if (tooltip != "")
			Set_tooltip(curr_widget, tooltip);
		if (is_optional > 0)
			Set_optional(curr_widget, is_optional);
		// Specific settings
		Integer engine = 0;
		rv = FW_Attributes_Get_value_integer(widget_params, PARAM_NAME_VIEW_ENGINE, engine);
		if (rv == 0)
			Set_view_engine(curr_widget, engine);
		Set_view_types(curr_widget, widget_title, widget_params);

		widget = Cast(curr_widget);
		return 0;
	}
	break;

	// XYZ_Box
	case ("XYZ"):
	{
		XYZ_Box curr_widget = Create_xyz_box(widget_title, message);
		// Common settings
		if (default_value != "")
			Set_data(curr_widget, default_value);
		if (width_in_chars > 0)
			Set_width_in_chars(curr_widget, width_in_chars);
		if (tooltip != "")
			Set_tooltip(curr_widget, tooltip);
		if (is_optional > 0)
			Set_optional(curr_widget, is_optional);
		// Specific settings
		Real x, y, z;
		Null(x, y, z);
		rv = FW_Attributes_Get_value_real(widget_params, PARAM_NAME_XYZ_Z, x);
		if (rv != 0)
			Null(x);
		rv = FW_Attributes_Get_value_real(widget_params, PARAM_NAME_XYZ_Z, y);
		if (rv != 0)
			Null(y);
		rv = FW_Attributes_Get_value_real(widget_params, PARAM_NAME_XYZ_Z, z);
		if (rv != 0)
			Null(z);
		if ((!Is_null(x)) && (!Is_null(y)) && (!Is_null(z)))
		{
			Set_data(curr_widget, x, y, z);
		}

		widget = Cast(curr_widget);
		return 0;
	}
	break;

	// #### LAYOUT WIDGETS ####
	case ("TAB<<"):
	{
		Tab_Box curr_widget = Create_tab_box();
		widget = Cast(curr_widget);
		return 0;
	}
	case (">>TAB"):
	{
		return -1; // Closing group
	}

	default:
	{
		return 1; // Unknown widget type
	}
	break;
	}
	return 99;
}

Integer FW_Text_Split(Text string, Dynamic_Text &results, Text delimiter)
{
	Integer count = 0;
	Integer len_delim = Text_length(delimiter);
	Null(results);

	while (1)
	{
		Integer pos = Find_text(string, delimiter);

		if (pos <= 0)
		{
			// Delimiter not found
			// Entire string or last part
			Append(string, results);
			count++;
			break;
		}
		else if (pos == 1)
		{
			// 1st char is delimiter, therefore 1st field is blank
			Append("", results);
			count++;
		}
		else
		{
			// Delimiter found at pos
			Append(Get_subtext(string, 1, (pos - 1)), results);
			count++;
		}
		// Truncate the string to remove the last part
		string = Get_subtext(string, (pos + len_delim), Text_length(string));
	}
	return count;
}
Integer Get_attribute_type(Attributes attr, Text att_path)
{
	Integer rv = -1;
	Integer type = -1;
	rv = Get_attribute_type(attr, att_path, type);
	return (rv == 0) ? type : -1;
}
Integer Get_attribute_type(Attributes attr, Integer att_no)
{
	Integer rv = -1;
	Integer type = -1;
	rv = Get_attribute_type(attr, att_no, type);
	return (rv == 0) ? type : -1;
}

Text FW_Text_Integer_true_false(Integer input)
{
	return (input) ? "True" : "False";
}

Text True_false(Integer value)
{
	return FW_Text_Integer_true_false(value);
}
// Returns boolean integer based on text input
Integer FW_Text_True_false(Text input)
{
	return (Text_lower(input) == Text_lower(True_false(TRUE))) ? TRUE : FALSE;
}

Integer True_false(Text input)
{
	return FW_Text_True_false(input);
}
Integer FW_Attributes_Get_value_boolean(Attributes atts, Text name, Integer &value)
{
	Integer rv = -1;
	value = 0;
	Integer att_type = Get_attribute_type(atts, name);
	switch (att_type)
	{
	case (ATT_TYPE_INTEGER):
	case (ATT_TYPE_REAL):
	{
		Integer att_value = 0;
		rv = Get_attribute(atts, name, att_value);
		if (rv != 0)
			return 100 + att_type; // Problem retrieving attribute
		value = att_value;
	}
	break;

	case (ATT_TYPE_TEXT):
	{
		Text att_value = "";
		Integer int_value = 0;
		rv = Get_attribute(atts, name, att_value);
		if (rv != 0)
			return 100 + att_type; // Problem retrieving attribute
		att_value = Text_lower(att_value);
		if ((att_value == "y") || (att_value == "yes") || (att_value == "t") || (att_value == "true"))
		{
			value = TRUE;
		}
		else if ((att_value == "n") || (att_value == "no") || (att_value == "f") || (att_value == "false"))
		{
			value = FALSE;
		}
		else
		{
			rv = From_text(att_value, int_value);
			if ((rv == 0) && (To_text(int_value) == att_value))
			{
				value = int_value;
			}
			else
			{
				return 200 + att_type;
			}
		}
	}
	break;

	case (ATT_TYPE_UID):
	case (ATT_TYPE_BLOB):
	case (ATT_TYPE_ATTRIBUTES):
	case (ATT_TYPE_GUID):
	case (ATT_TYPE_INT64):
	default:
	{
		return 300 + att_type; // Unsupported type
	}
	break;
	}
	return 0;
}

Integer FW_Attributes_Get_value_boolean(Attributes atts, Integer att_no, Integer &value)
{
	Integer rv = -1;
	value = 0;
	Integer att_type = Get_attribute_type(atts, att_no);
	switch (att_type)
	{
	case (ATT_TYPE_INTEGER):
	case (ATT_TYPE_REAL):
	{
		Integer att_value = 0;
		rv = Get_attribute(atts, att_no, att_value);
		if (rv != 0)
			return 100 + att_type; // Problem retrieving attribute
		value = att_value;
	}
	break;

	case (ATT_TYPE_TEXT):
	{
		Text att_value = "";
		Integer int_value = 0;
		rv = Get_attribute(atts, att_no, att_value);
		if (rv != 0)
			return 100 + att_type; // Problem retrieving attribute
		att_value = Text_lower(att_value);
		if ((att_value == "y") || (att_value == "yes") || (att_value == "t") || (att_value == "true"))
		{
			value = TRUE;
		}
		else if ((att_value == "n") || (att_value == "no") || (att_value == "f") || (att_value == "false"))
		{
			value = FALSE;
		}
		else
		{
			rv = From_text(att_value, int_value);
			if ((rv == 0) && (To_text(int_value) == att_value))
			{
				value = int_value;
			}
			else
			{
				return 200 + att_type;
			}
		}
	}
	break;

	case (ATT_TYPE_UID):
	case (ATT_TYPE_BLOB):
	case (ATT_TYPE_ATTRIBUTES):
	case (ATT_TYPE_GUID):
	case (ATT_TYPE_INT64):
	default:
	{
		return 300 + att_type; // Unsupported type
	}
	break;
	}
	return 0;
}
Integer FW_Array_Fill(Integer &data[], Integer size, Integer value)
{
	for (Integer i = 1; i <= size; i++)
	{
		data[i] = value;
	}
	return 0;
}
Integer FW_Attributes_Get_value_text(Attributes atts, Text name, Text &value)
{
	Integer rv = -1;
	value = "";
	Integer att_type = 0;

	if (!Attribute_exists(atts, name))
		return 1;
	rv = Get_attribute_type(atts, name, att_type);
	if (rv != 0)
		return 2;
	switch (att_type)
	{
	case (ATT_TYPE_INTEGER):
	{
		Integer att_value = 0;
		rv = Get_attribute(atts, name, att_value);
		if (rv != 0)
			return 100 + rv;
		value = To_text(att_value);
	}
	break;

	case (ATT_TYPE_REAL):
	{
		Real att_value;
		Null(att_value);
		rv = Get_attribute(atts, name, att_value);
		if (rv != 0)
			return 100 + rv;
		if (Is_null(att_value))
		{
			value = "";
		}
		else
		{
			value = To_text(att_value, "%.12f");
		}
	}
	break;

	case (ATT_TYPE_TEXT):
	{
		Text att_value = "";
		rv = Get_attribute(atts, name, att_value);
		if (rv != 0)
			return 100 + rv;
		value = att_value;
	}
	break;

	case (ATT_TYPE_UID):
	{
		Uid att_value;
		Null(att_value);
		rv = Get_attribute(atts, name, att_value);
		if (rv != 0)
			return 100 + rv;
		rv = Convert_uid(att_value, value);
		if (rv != 0)
			return 200 + rv;
	}
	break;

	default:
	{
		value = "";
		return 3;
	}
	}
	return 0;
}

Integer FW_Attributes_Get_value_text(Attributes atts, Integer index, Text &value)
{
	Integer rv = -1;
	value = "";
	Integer att_type = 0;

	rv = Get_attribute_type(atts, index, att_type);
	if (rv != 0)
		return 2;
	switch (att_type)
	{
	case (ATT_TYPE_INTEGER):
	{
		Integer att_value = 0;
		rv = Get_attribute(atts, index, att_value);
		if (rv != 0)
			return 100 + rv;
		value = To_text(att_value);
	}
	break;

	case (ATT_TYPE_REAL):
	{
		Real att_value;
		Null(att_value);
		rv = Get_attribute(atts, index, att_value);
		if (rv != 0)
			return 100 + rv;
		if (Is_null(att_value))
		{
			value = "";
		}
		else
		{
			value = To_text(att_value, "%.12f");
		}
	}
	break;

	case (ATT_TYPE_TEXT):
	{
		Text att_value = "";
		rv = Get_attribute(atts, index, att_value);
		if (rv != 0)
			return 100 + rv;
		value = att_value;
	}
	break;

	case (ATT_TYPE_UID):
	{
		Uid att_value;
		Null(att_value);
		rv = Get_attribute(atts, index, att_value);
		if (rv != 0)
			return 100 + rv;
		rv = Convert_uid(att_value, value);
		if (rv != 0)
			return 200 + rv;
	}
	break;

	default:
	{
		value = "";
		return 3;
	}
	}
	return 0;
}
Integer FW_Attributes_Get_value_integer(Attributes atts, Text name, Integer &value)
{
	Integer rv = -1;
	value = 0;
	Integer att_type = Get_attribute_type(atts, name);
	switch (att_type)
	{
	case (ATT_TYPE_INTEGER):
	{
		Integer att_value = 0;
		rv = Get_attribute(atts, name, att_value);
		if (rv != 0)
			return 100 + att_type; // Problem retrieving attribute
		value = att_value;
	}
	break;

	case (ATT_TYPE_REAL):
	{
		rv = Get_attribute(atts, name, value);
		if (rv != 0)
			return 100 + att_type; // Problem retrieving attribute
	}
	break;

	case (ATT_TYPE_TEXT):
	{
		Text att_value = "";
		Integer int_value = 0;
		rv = Get_attribute(atts, name, att_value);
		if (rv != 0)
			return 100 + att_type; // Problem retrieving attribute
		rv = From_text(att_value, int_value);
		if ((rv == 0) && (To_text(int_value) == att_value))
		{
			value = int_value;
		}
		else
		{
			return 200 + att_type; // Problem converting/casting value
		}
	}
	break;

	case (ATT_TYPE_UID):
	{
		Uid att_value;
		Null(att_value);
		Integer int_value = 0;
		rv = Get_attribute(atts, name, att_value);
		if (rv != 0)
			return 100 + att_type; // Problem retrieving attribute
		rv = Convert_uid(att_value, int_value);
		if (rv != 0)
			return 200 + att_type; // Problem converting/casting value
		value = int_value;
	}
	break;

	case (ATT_TYPE_BLOB):
	case (ATT_TYPE_ATTRIBUTES):
	case (ATT_TYPE_GUID):
	case (ATT_TYPE_INT64):
	default:
	{
		return 300 + att_type; // Unsupported type
	}
	break;
	}
	return 0;
}

Integer FW_Attributes_Get_value_integer(Attributes atts, Integer att_no, Integer &value)
{
	Integer rv = -1;
	value = 0;
	Integer att_type = Get_attribute_type(atts, att_no);
	switch (att_type)
	{
	case (ATT_TYPE_INTEGER):
	{
		Integer att_value = 0;
		rv = Get_attribute(atts, att_no, att_value);
		if (rv != 0)
			return 100 + att_type; // Problem retrieving attribute
		value = att_value;
	}
	break;

	case (ATT_TYPE_REAL):
	{
		rv = Get_attribute(atts, att_no, value);
		if (rv != 0)
			return 100 + att_type; // Problem retrieving attribute
	}
	break;

	case (ATT_TYPE_TEXT):
	{
		Text att_value = "";
		Integer int_value = 0;
		rv = Get_attribute(atts, att_no, att_value);
		if (rv != 0)
			return 100 + att_type; // Problem retrieving attribute
		rv = From_text(att_value, int_value);
		if ((rv == 0) && (To_text(int_value) == att_value))
		{
			value = int_value;
		}
		else
		{
			return 200 + att_type; // Problem converting/casting value
		}
	}
	break;

	case (ATT_TYPE_UID):
	{
		Uid att_value;
		Null(att_value);
		Integer int_value = 0;
		rv = Get_attribute(atts, att_no, att_value);
		if (rv != 0)
			return 100 + att_type; // Problem retrieving attribute
		rv = Convert_uid(att_value, int_value);
		if (rv != 0)
			return 200 + att_type; // Problem converting/casting value
		value = int_value;
	}
	break;

	case (ATT_TYPE_BLOB):
	case (ATT_TYPE_ATTRIBUTES):
	case (ATT_TYPE_GUID):
	case (ATT_TYPE_INT64):
	default:
	{
		return 300 + att_type; // Unsupported type
	}
	break;
	}
	return 0;
}
void Null(Dynamic_Element &x[], Integer num_index)
{
	for (Integer i = 1; i <= num_index; i++)
	{
		Null(x[i]);
	}
}
void Null(Dynamic_Text &x[], Integer num_index)
{
	for (Integer i = 1; i <= num_index; i++)
	{
		Null(x[i]);
	}
}
void Null(Dynamic_Real &x[], Integer num_index)
{
	for (Integer i = 1; i <= num_index; i++)
	{
		Null(x[i]);
	}
}
void Null(Dynamic_Integer &x[], Integer num_index)
{
	for (Integer i = 1; i <= num_index; i++)
	{
		Null(x[i]);
	}
}

void Null(Element &x[], Integer num_index)
{
	for (Integer i = 1; i <= num_index; i++)
	{
		Null(x[i]);
	}
}
void Null(Real &x[], Integer num_index)
{
	for (Integer i = 1; i <= num_index; i++)
	{
		Null(x[i]);
	}
}

void Null(Element &x, Element &y)
{
	Null(x);
	Null(y);
}
void Null(Element &x, Element &y, Element &z)
{
	Null(x);
	Null(y);
	Null(z);
}
void Null(Element &x, Element &y, Element &z, Element &w)
{
	Null(x);
	Null(y);
	Null(z);
	Null(w);
}
void Null(Element &x, Element &y, Element &z, Element &w, Element &r)
{
	Null(x);
	Null(y);
	Null(z);
	Null(w);
	Null(r);
}
void Null(Element &x, Element &y, Element &z, Element &w, Element &r, Element &t)
{
	Null(x);
	Null(y);
	Null(z);
	Null(w);
	Null(r);
	Null(t);
}

void Null(Dynamic_Element &x, Dynamic_Element &y)
{
	Null(x);
	Null(y);
}
void Null(Dynamic_Element &x, Dynamic_Element &y, Dynamic_Element &z)
{
	Null(x);
	Null(y);
	Null(z);
}
void Null(Dynamic_Element &x, Dynamic_Element &y, Dynamic_Element &z, Dynamic_Element &w)
{
	Null(x);
	Null(y);
	Null(z);
	Null(w);
}
void Null(Dynamic_Element &x, Dynamic_Element &y, Dynamic_Element &z, Dynamic_Element &w, Dynamic_Element &r)
{
	Null(x);
	Null(y);
	Null(z);
	Null(w);
	Null(r);
}
void Null(Dynamic_Element &x, Dynamic_Element &y, Dynamic_Element &z, Dynamic_Element &w, Dynamic_Element &r, Dynamic_Element &t)
{
	Null(x);
	Null(y);
	Null(z);
	Null(w);
	Null(r);
	Null(t);
}

void Null(Real &x, Real &y)
{
	Null(x);
	Null(y);
}
void Null(Real &x, Real &y, Real &z)
{
	Null(x);
	Null(y);
	Null(z);
}
void Null(Real &x, Real &y, Real &z, Real &w)
{
	Null(x);
	Null(y);
	Null(z);
	Null(w);
}
void Null(Real &x, Real &y, Real &z, Real &w, Real &r)
{
	Null(x);
	Null(y);
	Null(z);
	Null(w);
	Null(r);
}
void Null(Real &x, Real &y, Real &z, Real &w, Real &r, Real &t)
{
	Null(x);
	Null(y);
	Null(z);
	Null(w);
	Null(r);
	Null(t);
}
void Null(Dynamic_Real &x, Dynamic_Real &y)
{
	Null(x);
	Null(y);
}
void Null(Dynamic_Real &x, Dynamic_Real &y, Dynamic_Real &z)
{
	Null(x);
	Null(y);
	Null(z);
}
void Null(Dynamic_Real &x, Dynamic_Real &y, Dynamic_Real &z, Dynamic_Real &w)
{
	Null(x);
	Null(y);
	Null(z);
	Null(w);
}
void Null(Dynamic_Real &x, Dynamic_Real &y, Dynamic_Real &z, Dynamic_Real &w, Dynamic_Real &r)
{
	Null(x);
	Null(y);
	Null(z);
	Null(w);
	Null(r);
}
void Null(Dynamic_Real &x, Dynamic_Real &y, Dynamic_Real &z, Dynamic_Real &w, Dynamic_Real &r, Dynamic_Real &t)
{
	Null(x);
	Null(y);
	Null(z);
	Null(w);
	Null(r);
	Null(t);
}

void Null(Dynamic_Text &x, Dynamic_Text &y)
{
	Null(x);
	Null(y);
}
void Null(Dynamic_Text &x, Dynamic_Text &y, Dynamic_Text &z)
{
	Null(x);
	Null(y);
	Null(z);
}
void Null(Dynamic_Text &x, Dynamic_Text &y, Dynamic_Text &z, Dynamic_Text &w)
{
	Null(x);
	Null(y);
	Null(z);
	Null(w);
}
void Null(Dynamic_Text &x, Dynamic_Text &y, Dynamic_Text &z, Dynamic_Text &w, Dynamic_Text &r)
{
	Null(x);
	Null(y);
	Null(z);
	Null(w);
	Null(r);
}
void Null(Dynamic_Text &x, Dynamic_Text &y, Dynamic_Text &z, Dynamic_Text &w, Dynamic_Text &r, Dynamic_Text &t)
{
	Null(x);
	Null(y);
	Null(z);
	Null(w);
	Null(r);
	Null(t);
}

void Null(Dynamic_Integer &x, Dynamic_Integer &y)
{
	Null(x);
	Null(y);
}
void Null(Dynamic_Integer &x, Dynamic_Integer &y, Dynamic_Integer &z)
{
	Null(x);
	Null(y);
	Null(z);
}
void Null(Dynamic_Integer &x, Dynamic_Integer &y, Dynamic_Integer &z, Dynamic_Integer &w)
{
	Null(x);
	Null(y);
	Null(z);
	Null(w);
}
void Null(Dynamic_Integer &x, Dynamic_Integer &y, Dynamic_Integer &z, Dynamic_Integer &w, Dynamic_Integer &r)
{
	Null(x);
	Null(y);
	Null(z);
	Null(w);
	Null(r);
}
void Null(Dynamic_Integer &x, Dynamic_Integer &y, Dynamic_Integer &z, Dynamic_Integer &w, Dynamic_Integer &r, Dynamic_Integer &t)
{
	Null(x);
	Null(y);
	Null(z);
	Null(w);
	Null(r);
	Null(t);
}

// Casts an attribute value to a Real, if possible, even if it is an Integer or Text type
// does not work on GUID, BLOB, ATTRIBUTES, INT64 types
Integer FW_Attributes_Get_value_real(Attributes atts, Text name, Real &value)
{
	Integer rv = -1;
	Null(value);
	Integer att_type = Get_attribute_type(atts, name);
	switch (att_type)
	{
	case (ATT_TYPE_INTEGER):
	{
		Integer att_value = 0;
		rv = Get_attribute(atts, name, att_value);
		if (rv != 0)
			return 100 + att_type; // Problem retrieving attribute
		value = att_value;
	}
	break;

	case (ATT_TYPE_REAL):
	{
		rv = Get_attribute(atts, name, value);
		if (rv != 0)
			return 100 + att_type; // Problem retrieving attribute
	}
	break;

	case (ATT_TYPE_TEXT):
	{
		Text att_value = "";
		rv = Get_attribute(atts, name, att_value);
		if (rv != 0)
			return 100 + att_type; // Problem retrieving attribute
		rv = From_text(att_value, value, "%lf");
		if (rv != 0)
			return 200 + att_type; // Problem converting/casting value
	}
	break;

	case (ATT_TYPE_UID):
	{
		Uid att_value;
		Null(att_value);
		Integer int_value = 0;
		rv = Get_attribute(atts, name, att_value);
		if (rv != 0)
			return 100 + att_type; // Problem retrieving attribute
		rv = Convert_uid(att_value, int_value);
		if (rv != 0)
			return 200 + att_type; // Problem converting/casting value
		value = int_value;
	}
	break;

	case (ATT_TYPE_BLOB):
	case (ATT_TYPE_ATTRIBUTES):
	case (ATT_TYPE_GUID):
	case (ATT_TYPE_INT64):
	default:
	{
		return 300 + att_type; // Unsupported type
	}
	break;
	}
	return 0;
}
Integer Get_attribute_type(Element elt, Integer att_no)
{
	Integer rv = -1;
	Integer type = -1;
	rv = Get_attribute_type(elt, att_no, type);
	return (rv == 0) ? type : -1;
}
Integer Get_attribute_type(Element elt, Text att_path)
{
	Integer rv = -1;
	Integer type = -1;
	rv = Get_attribute_type(elt, att_path, type);
	return (rv == 0) ? type : -1;
}

Integer FW_Attributes_Get_value_real(Element elt, Text name, Real &value)
{
	Integer rv = -1;
	Null(value);
	Integer att_type = Get_attribute_type(elt, name);
	switch (att_type)
	{
	case (ATT_TYPE_INTEGER):
	{
		Integer att_value = 0;
		rv = Get_attribute(elt, name, att_value);
		if (rv != 0)
			return 100 + att_type; // Problem retrieving attribute
		value = att_value;
	}
	break;

	case (ATT_TYPE_REAL):
	{
		rv = Get_attribute(elt, name, value);
		if (rv != 0)
			return 100 + att_type; // Problem retrieving attribute
	}
	break;

	case (ATT_TYPE_TEXT):
	{
		Text att_value = "";
		rv = Get_attribute(elt, name, att_value);
		if (rv != 0)
			return 100 + att_type; // Problem retrieving attribute
		rv = From_text(att_value, value, "%lf");
		if (rv != 0)
			return 200 + att_type; // Problem converting/casting value
	}
	break;

	case (ATT_TYPE_UID):
	{
		Uid att_value;
		Null(att_value);
		Integer int_value = 0;
		rv = Get_attribute(elt, name, att_value);
		if (rv != 0)
			return 100 + att_type; // Problem retrieving attribute
		rv = Convert_uid(att_value, int_value);
		if (rv != 0)
			return 200 + att_type; // Problem converting/casting value
		value = int_value;
	}
	break;

	case (ATT_TYPE_BLOB):
	case (ATT_TYPE_ATTRIBUTES):
	case (ATT_TYPE_GUID):
	case (ATT_TYPE_INT64):
	default:
	{
		return 300 + att_type; // Unsupported type
	}
	break;
	}
	return 0;
}

// Casts an attribute value to a Real, if possible, even if it is an Integer or Text type
// does not work on GUID, BLOB, ATTRIBUTES, INT64 types
Integer FW_Attributes_Get_value_real(Attributes atts, Integer att_no, Real &value)
{
	Integer rv = -1;
	Null(value);
	Integer att_type = Get_attribute_type(atts, att_no);
	switch (att_type)
	{
	case (ATT_TYPE_INTEGER):
	{
		Integer att_value = 0;
		rv = Get_attribute(atts, att_no, att_value);
		if (rv != 0)
			return 100 + att_type; // Problem retrieving attribute
		value = att_value;
	}
	break;

	case (ATT_TYPE_REAL):
	{
		rv = Get_attribute(atts, att_no, value);
		if (rv != 0)
			return 100 + att_type; // Problem retrieving attribute
	}
	break;

	case (ATT_TYPE_TEXT):
	{
		Text att_value = "";
		rv = Get_attribute(atts, att_no, att_value);
		if (rv != 0)
			return 100 + att_type; // Problem retrieving attribute
		rv = From_text(att_value, value, "%lf");
		if (rv != 0)
			return 200 + att_type; // Problem converting/casting value
	}
	break;

	case (ATT_TYPE_UID):
	{
		Uid att_value;
		Null(att_value);
		Integer int_value = 0;
		rv = Get_attribute(atts, att_no, att_value);
		if (rv != 0)
			return 100 + att_type; // Problem retrieving attribute
		rv = Convert_uid(att_value, int_value);
		if (rv != 0)
			return 200 + att_type; // Problem converting/casting value
		value = int_value;
	}
	break;

	case (ATT_TYPE_BLOB):
	case (ATT_TYPE_ATTRIBUTES):
	case (ATT_TYPE_GUID):
	case (ATT_TYPE_INT64):
	default:
	{
		return 300 + att_type; // Unsupported type
	}
	break;
	}
	return 0;
}

Integer FW_Attributes_Get_value_real(Element elt, Integer att_no, Real &value)
{
	Integer rv = -1;
	Null(value);
	Integer att_type = Get_attribute_type(elt, att_no);
	switch (att_type)
	{
	case (ATT_TYPE_INTEGER):
	{
		Integer att_value = 0;
		rv = Get_attribute(elt, att_no, att_value);
		if (rv != 0)
			return 100 + att_type; // Problem retrieving attribute
		value = att_value;
	}
	break;

	case (ATT_TYPE_REAL):
	{
		rv = Get_attribute(elt, att_no, value);
		if (rv != 0)
			return 100 + att_type; // Problem retrieving attribute
	}
	break;

	case (ATT_TYPE_TEXT):
	{
		Text att_value = "";
		rv = Get_attribute(elt, att_no, att_value);
		if (rv != 0)
			return 100 + att_type; // Problem retrieving attribute
		rv = From_text(att_value, value, "%lf");
		if (rv != 0)
			return 200 + att_type; // Problem converting/casting value
	}
	break;

	case (ATT_TYPE_UID):
	{
		Uid att_value;
		Null(att_value);
		Integer int_value = 0;
		rv = Get_attribute(elt, att_no, att_value);
		if (rv != 0)
			return 100 + att_type; // Problem retrieving attribute
		rv = Convert_uid(att_value, int_value);
		if (rv != 0)
			return 200 + att_type; // Problem converting/casting value
		value = int_value;
	}
	break;

	case (ATT_TYPE_BLOB):
	case (ATT_TYPE_ATTRIBUTES):
	case (ATT_TYPE_GUID):
	case (ATT_TYPE_INT64):
	default:
	{
		return 300 + att_type; // Unsupported type
	}
	break;
	}
	return 0;
}