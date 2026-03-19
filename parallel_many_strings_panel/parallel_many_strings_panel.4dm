
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
 *	FILE:		parallel_strings_panel.4dm
 *
 *	DESCRIPTION:
 *	Parallel (offset) multiple elements at once.
 *
 *
 *	AUTHOR:		Matthew Monk
 *	STARTED:	09/05/2012
 *
 *	REVISION HISTORY:
 *	1		09/05/2012	Initial macro
 *  2		11/05/2012	*MOD* Changed macro name
 *						*ADD* Command-line arguments for chainable use in V9
 *						*ADD* Added support for Undo
 *	3		23/07/2012	*MOD* Updated for V10
 *						*ADD* Use Colour_Message_Box
 *						*ADD* Use Target_Box
 *	4		21/03/2012	*FIX* Inclued externally called functions from
 *								MM library in this file for easier submission.
 *	5		25/11/2013	*FIX* Validation of filter on load for source box
 *						*FIX* Externalised library functions again (see rev 4)
 *						*FIX* Minor rewording and tweaking of status reporting.
 *						*FIX* Added extra About info to Output window.
 *	6		16/01/2014	*ADD* Multiple offsets
 *						*ADD* Vertical offset
 *						*REL* Released to 12d Forum-
 *	7		18/03/2014	*ADD* Changed to newer Super_offset() call
 *						*FIX* Fixed undos
 *	8		28/05/2014	*FIX* Release objects preventing exit of macro
 *	9		22/07/2014	*MOD* Change panel name
 *						*MOD* Minor clean-up for V11 release
 *						*MOD* Changed build target for V11
 *	10		29/11/2015	*MOD* Copy source string basic properties to destination string/s
 *						*MOD* Target for v11C1i build inclusion
 *						*MOD* Version 2.0 of macro
 *   Matt's Legacy - Core Spatial - Tatras Consulting
 *	3.1		06/2023	 	code consolidated and issued for released
 *	3.2		03/2026	 	Added lost Z value code
 *	3.2		03/2026	 	Fixed error super offset modes 0 based index
 *	3.2		03/2026	 	Fixed undo add by range
 *
 */

#define DEBUG 0

// Prerequisites
// Matt Monk libraries
#include "..\\..\\include/Matt_standard_library.h"
#include "..\\..\\include/Matt_set_ups.h"
#include "..\\..\\include/parallel_many_strings-externals.h"

// Preset levels for Colour_Message_Box
#include "..\\..\\include/parallel_many_strings-externals.h"

// Preset levels for Colour_Message_Box
#define MESSAGE_LEVEL_GENERAL 1 // Default
#define MESSAGE_LEVEL_WARNING 2 // Yellow
#define MESSAGE_LEVEL_ERROR 3	// Red
#define MESSAGE_LEVEL_GOOD 4	// Green

#define PARALLEL_METHOD_PARALLEL 1	   // Use Parallel() call
#define PARALLEL_METHOD_SUPER_OFFSET 2 // Use Super_offset() call

#define SUPER_OFFSET_MODE_JOIN 0
#define SUPER_OFFSET_MODE_INTERSECT 1
#define SUPER_OFFSET_MODE_FILLET 2
#define SUPER_OFFSET_MODE_DUAL 3
#define SUPER_OFFSET_MODE_CLIP 4

#define SUPER_OFFSET_MODE_COUNT 5

#define DEFAULT_OFFSET_MODE SUPER_OFFSET_MODE_JOIN

#define COPY_ELEMENT_PROPERTY_NAME 0x0001
#define COPY_ELEMENT_PROPERTY_MODEL 0x0002
#define COPY_ELEMENT_PROPERTY_COLOUR 0x0010
#define COPY_ELEMENT_PROPERTY_STYLE 0x0020
#define COPY_ELEMENT_PROPERTY_BREAKLINE 0x0040
#define COPY_ELEMENT_PROPERTY_WEIGHT 0x0080
#define COPY_ELEMENT_PROPERTY_CHAINAGE 0x0100
#define COPY_ELEMENT_PROPERTY_ALL 0xFFFF

#define TARGET_PROPERTIES_MODE 1 // Where to get the target/new element properties from- 0 = Default/blank values, 1 = from Source String

// #### FUNCTION PROTOTYPES ####

void manage_panel();
void Print_usage();
Integer Process_elements(Dynamic_Element &data, Integer method, Integer offset_mode,
						 Real h_offset, Real v_offset, Integer iterations,
						 Integer target_mode, Text target_value, Colour_Message_Box &msg,
						 Integer &num_success, Integer &num_created, Integer &num_error);
Integer Process_item(Element &in, Integer method, Integer offset_mode, Real h_offset, Real v_offset,
					 Integer iterations, Log_Line &log, Dynamic_Element &out);
Integer Validate_offset_modes_box(Choice_Box &modes_box, Text &offset_modes[], Integer &offset_mode);

Text Get_target_mode_text(Integer target_mode);
Text Get_offset_mode_text(Integer offset_mode);

Integer Copy_basic_element_properties(Element &src_elt, Integer property_mode, Element &dest_elt);
Text Get_parallel_method_text(Integer method);
void Print_settings(Log_Line &log, Integer method, Integer offset_mode, Real h_offset, Real v_offset,
					Integer iterations, Integer target_mode, Text target_value);

// #### GLOBAL VARIABLES ####
{
	Text PROGRAM_NAME = "Parallel Many Strings";
	Text PROGRAM_AUTHOR = "Matthew Monk - Core Spatial";
	Text PROGRAM_VERSION = "3.2";
	Text PROGRAM_DATE = "2026-03";

	Dynamic_Text Program_Info;
}

void main()
{
#if DEBUG
	Clear_console();
#endif

	Print();
	Print("by " + PROGRAM_AUTHOR + "\n");
	Print(PROGRAM_NAME + " \nversion " + PROGRAM_VERSION + " " + PROGRAM_DATE + "\n");
	Print();
	// Parse command line arguments
	Integer argc = Get_number_of_command_arguments();
	Integer rv = -1;

	if (argc >= 3)
	{
		// Require 5 arguments - src_model h_offset target_model v_offset iterations
		Text src_model_arg, offset_arg, target_model_arg;
		Text v_offset_arg, iterations_arg, offset_mode_arg;
		Text target_model_name;
		Model src_model;
		Real offset = 0.0;
		Dynamic_Element src_data;
		Integer method = 0;
		Integer offset_mode = SUPER_OFFSET_MODE_JOIN;
		Real horiz_offset_distance = 0.00;
		Real vert_offset_distance = 0.00;
		Integer iterations = 1;
		Integer target_mode = 0; // Mode specified in the Target_Box - used to determine what to do with the data
		Text target_value = "";	 // Value specified in the Target_Box

		src_model_arg = offset_arg = target_model_arg = "";
		v_offset_arg = iterations_arg = offset_mode_arg = "";
		target_model_name = "";
		Null(src_model);
		Null(src_data);

		Get_command_argument(1, src_model_arg);
		Get_command_argument(2, offset_arg);
		Get_command_argument(3, target_model_arg);
		if (argc > 3)
			Get_command_argument(4, offset_mode_arg);
		if (argc > 4)
			Get_command_argument(5, v_offset_arg);
		if (argc > 5)
			Get_command_argument(6, iterations_arg);

		// Validate the source model argument
		if (!Model_exists(src_model_arg))
		{
			Print("Source model- " + src_model_arg + "- doesn't exist.\n");
			Print("Macro cancelled.\n");
			return;
		}
		src_model = Get_model(src_model_arg);

		// Validate the offset argument
		rv = From_text(offset_arg, offset);
		if (rv != 0)
		{
			Print("Invalid offset value- " + offset_arg + "- cannot be converted to a real number.\n");
			Print("Macro cancelled.\n");
			return;
		}
		else
		{
			horiz_offset_distance = offset;
		}
		// Validate the target model data
		Text valid_target_model_name = "";
		rv = Valid_model_name(target_value, valid_target_model_name);
		Print("Valid model name: " + valid_target_model_name + " rv=" + To_text(rv) + "\n");
		if (rv == 0)
		{
			if (valid_target_model_name != target_model_arg)
			{
				Print("Target model name specified is invalid. Using valid model name- " +
					  valid_target_model_name + "- instead.\n");
			}
		}
		else
		{
			Print("Error validating target model value- " + target_model_arg + ".\n");
			Print("Macro cancelled.\n");
			return;
		}
		// Validate the offset mode argument
		if (offset_mode_arg != "")
		{
			method = PARALLEL_METHOD_SUPER_OFFSET;
			rv = From_text(offset_mode_arg, offset_mode);
			if (rv != 0)
			{
				Print("Invalid offset mode- " + offset_mode_arg + "- cannot be converted to an integer.\n");
				Print("Using a default offset mode - " + Get_offset_mode_text(SUPER_OFFSET_MODE_JOIN) + "\n");
			}
		}
		else
		{
			method = PARALLEL_METHOD_PARALLEL;
			offset_mode = SUPER_OFFSET_MODE_JOIN;
		}
		// Validate the vertical offset argument
		if (v_offset_arg != "")
		{
			rv = From_text(v_offset_arg, vert_offset_distance);
			if (rv != 0)
			{
				Print("Invalid vertical offset value- " + v_offset_arg + "- cannot be converted to a real number.\n");
				Print("Using a default vertical offset = 0.0\n");
			}
		}
		else
		{
			vert_offset_distance = 0.0;
		}
		// Validate the iterations argument
		if (iterations_arg != "")
		{
			rv = From_text(iterations_arg, iterations);
			if (rv != 0)
			{
				Print("Invalid iterations value- " + iterations_arg + "- cannot be converted to an integer number.\n");
				Print("Using a default iteration = 1\n");
			}
			if (iterations < 1)
			{
				Print("Cannot have a negative or zero number of iterations. Using a default iteration = 1.\n");
				iterations = 1;
			}
		}
		else
		{
			iterations = 1;
		}
		// Get source data
		Model target_model;
		Integer num_src_elts, num_success, num_created, num_error;
		Colour_Message_Box msg = Create_colour_message_box("");
		num_src_elts = num_success = num_created = num_error = 0;

		target_model = Get_model_create(valid_target_model_name);
		if (!Model_exists(target_model))
		{
			Print("Error getting or creating model- " + valid_target_model_name + "\n");
			Print("Macro cancelled.\n");
			return;
		}
		target_mode = Target_Box_Copy_To_One_Model;

		rv = Get_elements(src_model, src_data, num_src_elts);
		if (rv != 0)
		{
			Print_log("ERROR : Unable to get elements from source model < " + src_model_arg +
						  " > (err: " + To_text(rv) + ")",
					  LOG_LINE_ERROR);
			return;
		}
		rv = Process_elements(src_data, method, offset_mode, horiz_offset_distance, vert_offset_distance,
							  iterations, target_mode, target_value, msg, num_success, num_created, num_error);

		Print("Finished. " + To_text(num_success) + " processed, " + To_text(num_error) + " errors,");
		Print(To_text(num_created) + " created.\n");
	}
	else if (argc > 0)
	{
		Text arg1 = "";
		Get_command_argument(1, arg1);
		if (arg1 == "about")
		{
			Print();
			Print("by " + PROGRAM_AUTHOR + "\n");
			Print(PROGRAM_NAME + " \nversion " + PROGRAM_VERSION + " " + PROGRAM_DATE + "\n");
			Print();
		}
		Print(Get_macro_name() + "- invalid usage.\n");
		Print_usage();
	}
	else
	{
		manage_panel();
	}

	return;
}

void Print_usage()
{
	Print();
	Print("### USAGE: ###\n");
	Print("Interactive panel:\n");
	Print(Get_macro_name() + " (with no arguments)\n");
	Print();
	Print("Command-line (non-interactive):\n");
	Print(Get_macro_name() + " \"source model\" horiz_offset \"target model\"");
	Print(" [ offset_mode [ vert_shift  [ iterations ] ] ]\n");
	Print();
	Print("source model = Model name containing elements to parallel.\n");
	Print("               All supported elements in model will be processed.\n");
	Print("               Enclose in quotes if model name contains spaces.\n");
	Print("horiz offset = Horizontal distance to parallel source elements at each iteration.\n");
	Print("                Must be a valid real value.\n");
	Print("target model = Model name in which to store the results.\n");
	Print("               Enclose in quotes if model name contains spaces.\n");
	Print("offset_mode  = Specify the integer representing the offset mode to use.\n");
	Print("               Valid offset modes are:\n");
	Print("               0. Join (default)\n");
	Print("               1. Intersect\n");
	Print("               2. Fillet\n");
	Print("               3. Dual\n");
	Print("               4. Clip\n");
	Print("               If non-blank, use the Super Offset method.\n");
	Print("               If blank (\"\"), use the Parallel method.\n");
	Print("vert_shift   = Specify the vertical distance to translate the resulting elements.\n");
	Print("               This only applies if the resulting elements have Z values.\n");
	Print("               Must be a valid real value, 0.0 = no shift, < 0.0 = shift down, > 0.0 = shift up\n");
	Print("               Must specify offset_mode if specifying vert_shift.\n");
	Print("iterations   = Specify the number of parallel iterations to run for each source element.\n");
	Print("               Must be a positive, non-zero integer. Default is one (1).\n");
	Print("               Must specify offset_mode and vert_shift if specifying iterations.\n");
	Print();
	Print("End.");
	Print();
	return;
}

void manage_panel()
{
	Panel panel = Create_panel(PROGRAM_NAME, TRUE);
	Vertical_Group vg1 = Create_vertical_group(BALANCE_WIDGETS_OVER_HEIGHT);
	Horizontal_Group hg_buttons = Create_button_group();

	Colour_Message_Box message = Create_colour_message_box("");

	// Source Box
	Vertical_Group vg_src = Create_vertical_group(BALANCE_WIDGETS_OVER_HEIGHT);
	Set_border(vg_src, " ");

	Integer src_flag, src_default;
	src_flag = Source_Box_Standard;
	src_default = Source_Box_Model;
	Source_Box src_box = Create_source_box(" to process", message, src_flag, src_default);

	Append(src_box, vg_src);

	// Main
	Vertical_Group vg_main = Create_vertical_group(BALANCE_WIDGETS_OVER_HEIGHT);
	Set_border(vg_main, "Settings");

	Named_Tick_Box use_super_offset_box = Create_named_tick_box("Use super offset", FALSE, "use_super");
	Set_tooltip(use_super_offset_box, "If ticked, use the Super Offset method. Otherwise, use the Parallel method.");
	Widget_Pages offset_mode_pages = Create_widget_pages();
	Vertical_Group vg_offset_page = Create_vertical_group(BALANCE_WIDGETS_OVER_HEIGHT);
	Vertical_Group vg_parallel_page = Create_vertical_group(BALANCE_WIDGETS_OVER_HEIGHT);

	Append(vg_parallel_page, offset_mode_pages);
	Append(vg_offset_page, offset_mode_pages);
	Set_page(offset_mode_pages, 1);

	Integer num_offset_modes = 5;
	Text offset_modes[10];
	offset_modes[SUPER_OFFSET_MODE_JOIN + 1] = "Join";
	offset_modes[SUPER_OFFSET_MODE_INTERSECT + 1] = "Intersect";
	offset_modes[SUPER_OFFSET_MODE_FILLET + 1] = "Fillet";
	offset_modes[SUPER_OFFSET_MODE_DUAL + 1] = "Dual";
	offset_modes[SUPER_OFFSET_MODE_CLIP + 1] = "Clip";
	Choice_Box offset_mode_box = Create_choice_box("Offset mode", message);
	Set_data(offset_mode_box, num_offset_modes, offset_modes);
	Set_data(offset_mode_box, offset_modes[DEFAULT_OFFSET_MODE + 1]);
	Set_tooltip(offset_mode_box, "Controls how offset segments are joined at corners. Uses the same modes as the Cad Offset command.");

	Real_Box horiz_offset_box = Create_real_box("Horizontal distance", message);
	Set_data(horiz_offset_box, 0.0);
	Set_tooltip(horiz_offset_box, "Horizontal parallel distance (-ve parallel to left, +ve parallel to right relative to direction of source string)");

	Real_Box vert_offset_box = Create_real_box("Translate Z", message);
	Set_optional(vert_offset_box, TRUE);
	Set_dump_name(vert_offset_box, "Vertical shift");
	Set_tooltip(vert_offset_box, "Translate resulting strings Z by this value (-ve offset down, +ve offset up)");

	Integer_Box iterations_box = Create_integer_box("Iterations", message);
	Set_data(iterations_box, 1);
	Set_optional(iterations_box, TRUE);
	Set_tooltip(iterations_box, "Number of times to perform the parallel operation. The parallel distance is multiplied by the iteration at each step.");

	Append(use_super_offset_box, vg_main);
	Append(offset_mode_box, vg_offset_page);
	Append(offset_mode_pages, vg_main);
	Append(horiz_offset_box, vg_main);
	Append(vert_offset_box, vg_main);
	Append(iterations_box, vg_main);

	// Target_Box
	Vertical_Group vg_target = Create_vertical_group(BALANCE_WIDGETS_OVER_HEIGHT);
	Set_border(vg_target, " ");
	Integer target_modes = Target_Box_Move_Copy_All;
	Integer target_default = Target_Box_Copy_To_Original_Model;
	Target_Box target_box = Create_target_box("", message, target_modes, target_default);
	Append(target_box, vg_target);

	Append(vg_src, vg1);
	Append(vg_main, vg1);
	Append(vg_target, vg1);

	Button but_process = Create_button("Process", "process");
	Button but_finish = Create_finish_button("Finish", "finish");
	Button but_help = Create_help_button(panel, "Help");

	Append(but_process, hg_buttons);
	Append(but_finish, hg_buttons);
	Append(but_help, hg_buttons);

	Append(message, vg1);
	Append(hg_buttons, vg1);
	Append(vg1, panel);

	Show_widget(panel);

	Integer doit = 1;
	Integer rv, proceed;

	proceed = 1;

	while (doit)
	{
		Integer id = -1;
		Text cmd = "";
		Text msg = "";
		Integer ret = Wait_on_widgets(id, cmd, msg); // this processes standard messages first ?

		rv = -1;
		proceed = 1;

		if (cmd == "keystroke")
			continue;

		switch (id)
		{
		case Get_id(panel):
		{
			if (cmd == "Panel Quit")
			{
				doit = 0;
			}
			if (cmd == "Panel About")
			{
				Print();
				Print("by " + PROGRAM_AUTHOR + "\n");
				Print(PROGRAM_NAME + " \nversion " + PROGRAM_VERSION + " " + PROGRAM_DATE + "\n");
				Print();
				about_panel(panel);
			}
		}
		break; // End - Panel

		case Get_id(but_finish):
		{
			if (cmd == "finish")
				doit = 0;
		}
		break; // End - finish

		case Get_id(use_super_offset_box):
		{
			Integer use_super_offset = FALSE;
			Validate(use_super_offset_box, use_super_offset);
			Set_page(offset_mode_pages, use_super_offset + 1);
			// Set_enable(vert_offset_box, !use_super_offset);
			if (use_super_offset)
			{
				Set_data(message, "Super Offset does not create Z on results.", MESSAGE_LEVEL_WARNING);
			}
		}
		break;

		case Get_id(src_box):
		{
			if (cmd == "source mode")
			{
				Set_level(message, MESSAGE_LEVEL_GENERAL);
			}
		}
		break;

		case Get_id(iterations_box):
		{
			if (cmd == "integer selected")
			{
				Integer iterations = 0;
				rv = Validate(iterations_box, iterations);
				PrintD("Iterations = " + To_text(iterations));
				if (rv == TRUE)
				{
					if (iterations < 1)
					{
						Set_data(message, "Iterations must be positive and non-zero.", MESSAGE_LEVEL_ERROR);
						break;
					}
					else
					{
						Set_data(message, To_text(iterations) + " is valid", MESSAGE_LEVEL_GENERAL);
					}
				}
				else if (rv == NO_NAME)
				{
					iterations = 0;
					Set_data(message, "ok - field is optional", MESSAGE_LEVEL_GENERAL);
					Set_level(message, MESSAGE_LEVEL_GENERAL);
				}
				else
				{
					break;
				}
			}
		}
		break;

		case Get_id(but_process):
		{
			Dynamic_Element src_data;
			Integer use_super_offset = FALSE;
			Integer method = 0;
			Integer offset_mode = SUPER_OFFSET_MODE_INTERSECT;
			Real horiz_offset_distance = 0.00;
			Real vert_offset_distance = 0.00;
			Integer iterations = 1;
			Integer target_mode = 0; // Mode specified in the Target_Box - used to determine what to do with the data
			Text target_value = "";	 // Value specified in the Target_Box
			Integer num_success, num_created, num_error;

			Null(src_data);
			num_success = num_created = num_error = 0;

			rv = Validate(src_box, src_data);
			if (rv != TRUE)
				break;

			rv = Validate(use_super_offset_box, use_super_offset);
			if (use_super_offset)
			{
				method = PARALLEL_METHOD_SUPER_OFFSET;
			}
			else
			{
				method = PARALLEL_METHOD_PARALLEL;
			}

			rv = Validate_offset_modes_box(offset_mode_box, offset_modes, offset_mode);
			if (rv != 0)
				break;

			rv = Validate(horiz_offset_box, horiz_offset_distance);
			if (rv != TRUE)
				break;

			rv = Validate(vert_offset_box, vert_offset_distance);
			if (rv == FALSE)
				break;
			if (rv == NO_NAME)
			{
				vert_offset_distance = 0.0;
			}

			rv = Validate(iterations_box, iterations);
			PrintD("Iterations = " + To_text(iterations));
			if (rv == TRUE)
			{
				if (iterations < 1)
				{
					Set_data(message, "Iterations must be positive and non-zero.", MESSAGE_LEVEL_ERROR);
					break;
				}
				else
				{
					Set_data(message, To_text(iterations) + " is valid", MESSAGE_LEVEL_GENERAL);
				}
			}
			else if (rv == NO_NAME)
			{
				iterations = 0;
				Set_data(message, "ok - field is optional", MESSAGE_LEVEL_GENERAL);
				Set_level(message, MESSAGE_LEVEL_GENERAL);
			}
			else
			{
				break;
			}

			rv = Validate(target_box, target_mode, target_value);

			if ((target_mode == Target_Box_Move_To_One_Model) || (target_mode == Target_Box_Copy_To_One_Model))
			{
				if ((Model_exists(target_value)) && (Is_model_shared_in(target_value)))
				{
					Set_data(message, "Target model is shared in and read only.", MESSAGE_LEVEL_ERROR);
					Print_log("ERROR : Target model < " + target_value + " > is shared in and read only. " +
								  "Cannot create result elements in this model. Please choose another model.",
							  LOG_LINE_ERROR);
					break;
				}
			}
			Set_data(message, "Processing...", MESSAGE_LEVEL_GENERAL);
			rv = Process_elements(src_data, method, offset_mode,
								  horiz_offset_distance, vert_offset_distance,
								  iterations, target_mode, target_value,
								  message, num_success, num_created, num_error);
			if (rv == 0)
			{
				Integer msg_level = 0;
				Text msg_text = "";
				msg_level = (num_error > 0) ? MESSAGE_LEVEL_WARNING : MESSAGE_LEVEL_GOOD;

				msg_text = "Finished. ";
				msg_text += To_text(num_success) + " processed, ";
				if (num_error > 0)
				{
					msg_text += To_text(num_error) + " with errors, ";
				}
				msg_text += To_text(num_created) + " created.";
				if (num_error > 0)
					msg_text += " See Output Window for errors.";

				Set_data(message, msg_text, msg_level);

				Integer move_cursor = (Getenv("MOVE_CURSOR_TO_FINISH_BUTTON_4D") == "1") ? TRUE : FALSE;
				Set_finish_button(but_finish, move_cursor);
			}
			else
			{
				Print_log("ERROR : Problem processing source elements (err: " + To_text(rv) +
							  "). Check messages above for details.",
						  LOG_LINE_ERROR);
				Set_data(message, "Error processing elements. Check Output Window for details.", MESSAGE_LEVEL_ERROR);
			}
			Null(src_data);
		}
		break; // End - process
		}
	}
	return;
}

Integer Process_elements(Dynamic_Element &data, Integer method, Integer offset_mode,
						 Real h_offset, Real v_offset, Integer iterations,
						 Integer target_mode, Text target_value, Colour_Message_Box &msg,
						 Integer &num_success, Integer &num_created, Integer &num_error)
{
	Integer rv = -1;
	Integer num_src_elts = 0;
	Undo_List undo_list;
	Uid first_uid = Get_next_uid();
	num_success = num_created = num_error = 0;

	rv = Get_number_of_items(data, num_src_elts);

    Text ts = "";
    Integer now;
    Get_time(now);
    Convert_time(now, "%H:%M:%S %d/%m/%Y", ts);
	// Top-level Log line for this whole processing run
	Log_Line proc_log = Create_group_log_line(ts + " - Parallel Many Strings - " + To_text(num_src_elts) + " elements",
											  LOG_LINE_GENERAL);
	Print_settings(proc_log, method, offset_mode, h_offset, v_offset, iterations, target_mode, target_value);

	if (num_src_elts <= 0)
	{
		Print_log(proc_log, "No elements in source data. Nothing to process.", LOG_LINE_ERROR);
		Print_log_line(proc_log, TRUE);
		return 1;
	}
	if (rv != 0)
	{
		Print_log(proc_log, "Unable to get number of elements in source data (err: " + To_text(rv) + ")", LOG_LINE_ERROR);
		Print_log_line(proc_log, TRUE);
		return 2;
	}

	for (Integer i = 1; i <= num_src_elts; i++)
	{
		Element curr_elt, orig_elt, new_elt;
		Dynamic_Element new_elts;
		Model curr_model, new_model, null_model;
		Text curr_model_name, new_model_name;
		Text elt_text, elt_type;
		Undo add_new, del_orig, chg_orig;
		Integer num_new_elts = 0;
		Integer smrv = -1; // Set model return value - need to keep separate to generic rv variable

		curr_model_name = new_model_name = elt_text = elt_type = "";
		Null(curr_elt);
		Null(orig_elt);
		Null(new_elt);
		Null(new_elts);
		Null(curr_model);
		Null(new_model);
		Null(null_model);

		Log_Line elt_log;		 // For current element
		Integer add_log = FALSE; // Whether to add the elt_log to the proc_log - generally only add errors/warnings
		Text elt_ctr = To_text(i) + " / " + To_text(num_src_elts) + " : ";

		rv = Get_item(data, i, curr_elt);
		if (rv != 0)
		{
			elt_log = Create_group_log_line(elt_ctr + "Unable to get element from source data " +
												"(err: " + To_text(rv) + "). Skipping...",
											LOG_LINE_ERROR);
			Append_log_line(elt_log, proc_log);
			continue;
		}
		else
		{
			elt_text = Get_element_text(curr_elt);
			elt_log = Create_group_log_line(elt_ctr + elt_text, LOG_LINE_NONE);
		}

		/// --- Get element information ---
		Get_type(curr_elt, elt_type);
		Get_model(curr_elt, curr_model);
		Get_name(curr_model, curr_model_name);

		Set_data(msg, "Processing " + To_text(i) + " of " + To_text(num_src_elts) + " elements...", MESSAGE_LEVEL_GENERAL);

		/// --- Restrict by Element type ---
		// Current types:
		// Super, Super_Alignment, Drainage, Text, Tin, SuperTin
		// Arc, Circle, Feature, Interface, Plot Frame, Pipeline
		// 2d, 3d, 4d, Pipe, Polyline, Alignment
		if ((elt_type == "Tin") || (elt_type == "Text") || (elt_type == "3d Primitive") ||
			(elt_type == "Super_Alignment"))
		{
			Print_log(elt_log, "Unsupported element type (type = " + elt_type + "). Skipping...",
					  LOG_LINE_ERROR, curr_elt);
			add_log = TRUE;
			++num_error;
			Append_log_line(elt_log, proc_log);
			continue;
		}
		else if ((elt_type != "Super") && (method == PARALLEL_METHOD_SUPER_OFFSET))
		{
			Print_log(elt_log, "Cannot use non-Super element (type = " + elt_type + ") with Super Offset method. " + "Trying old parallel method. Results may not be as expected.", LOG_LINE_WARNING, curr_elt);
			add_log = TRUE;
		}
		/// --- Check Shared Data vs Target Mode ---
		// Move/Copy to Single Model modes already done in Manage_panel() function
		if ((target_mode == Target_Box_Move_To_Original_Model) || (target_mode == Target_Box_Copy_To_Original_Model))
		{
			if (Is_model_shared_in(curr_model_name))
			{
				Print_log(elt_log, "ERROR : Target model < " + curr_model_name + " > is shared in and read only. " + "Cannot create result strings in this model. Skipping element...",
						  LOG_LINE_ERROR, curr_elt);
				Append_log_line(elt_log, proc_log);
				++num_error;
				continue;
			}
		}
		else if ((target_mode == Target_Box_Move_To_Many_Models) || (target_mode == Target_Box_Copy_To_Many_Models))
		{
			rv = Get_wildcard_model(target_value, curr_model_name, new_model_name);
			if (rv != 0)
			{
				Print_log(elt_log, "ERROR : Problem getting Target Model from pattern (err: " + To_text(rv) + ")",
						  LOG_LINE_ERROR, curr_elt);
				Print_log(elt_log, "    Current model : " + curr_model_name, LOG_LINE_NONE);
				Print_log(elt_log, "    Input value : " + target_value, LOG_LINE_NONE);
				Print_log(elt_log, "    Target model : " + new_model_name, LOG_LINE_NONE);
				Append_log_line(elt_log, proc_log);
				++num_error;
				continue;
			}
			if (Is_model_shared_in(new_model_name))
			{
				Print_log(elt_log, "ERROR : Target model < " + new_model_name + " > is shared in and read only. " + "Cannot create result strings in this model. Please choose another model.",
						  LOG_LINE_ERROR, curr_elt);
				Append_log_line(elt_log, proc_log);
				++num_error;
				continue;
			}
		}

		switch (target_mode)
		{
		case (Target_Box_Move_To_Original_Model):
		{
			// Process element using curr_elt
			rv = Process_item(curr_elt, method, offset_mode, h_offset, v_offset, iterations, elt_log, new_elts);
			if (rv == 0)
			{
				// Need to do separate delete and add steps because there could be
				// more elements in results than in original element.
				Append(Add_undo_delete("deleted", curr_elt, 1), undo_list);
				Element_delete(curr_elt);
				smrv = Set_model(new_elts, curr_model);
				if (smrv != 0)
				{
					Print_log(elt_log, "ERROR : Problem moving result elements to original model < " + curr_model_name + " > (err: " + To_text(smrv) + ")", LOG_LINE_ERROR, curr_elt);
					add_log = TRUE;
					++num_error;
				}
				Append(Add_undo_add("created", new_elts), undo_list);
			}
		}
		break;
		case Target_Box_Move_To_One_Model:
		{
			// Process element using curr_elt
			rv = Process_item(curr_elt, method, offset_mode, h_offset, v_offset, iterations, elt_log, new_elts);
			if (rv == 0)
			{
				new_model = Get_model_create(target_value);
				// Moving to a new model
				// 1. Delete original element
				Append(Add_undo_delete("deleted", curr_elt, 1), undo_list);
				Element_delete(curr_elt);
				// 2. Add new elements to model
				smrv = Set_model(new_elts, new_model);
				if (smrv != 0)
				{
					Print_log(elt_log, "ERROR : Problem moving result elements to new model < " + new_model_name + " > (err: " + To_text(smrv) + ")", LOG_LINE_ERROR, curr_elt);
					add_log = TRUE;
					++num_error;
				}
				Append(Add_undo_add("created", new_elts), undo_list);
			}
		}
		break;
		case Target_Box_Move_To_Many_Models:
		{
			// Process element using curr_elt
			rv = Process_item(curr_elt, method, offset_mode, h_offset, v_offset, iterations, elt_log, new_elts);
			if (rv == 0)
			{
				new_model = Get_model_create(new_model_name);
				// Move to Many Models
				// 1. Delete original element
				Append(Add_undo_delete("delete", curr_elt, 1), undo_list);
				Element_delete(curr_elt);
				// 2. Add new elements
				smrv = Set_model(new_elts, new_model);
				if (smrv != 0)
				{
					Print_log(elt_log, "ERROR : Problem moving result elements to new model < " + new_model_name + " > (err: " + To_text(smrv) + ")", LOG_LINE_ERROR, curr_elt);
					add_log = TRUE;
					++num_error;
				}
				Append(Add_undo_add("created", new_elts), undo_list);
			}
		}
		break;
		case Target_Box_Copy_To_Original_Model:
		{
			// This only creates new elements, not modify original element, so don't need to duplicate
			rv = Process_item(curr_elt, method, offset_mode, h_offset, v_offset, iterations, elt_log, new_elts);
			if (rv == 0)
			{
				// Copy to new model
				// 1. Add new elements
				smrv = Set_model(new_elts, curr_model);
				if (smrv != 0)
				{
					Print_log(elt_log, "ERROR : Problem moving result elements to original model < " + curr_model_name + " > (err: " + To_text(smrv) + ")", LOG_LINE_ERROR, curr_elt);
					add_log = TRUE;
					++num_error;
				}
				Append(Add_undo_add("created", new_elts), undo_list);
			}
		}
		break;
		case Target_Box_Copy_To_One_Model:
		{
			// This only creates new elements, not modify original element, so don't need to duplicate
			rv = Process_item(curr_elt, method, offset_mode, h_offset, v_offset, iterations, elt_log, new_elts);
			if (rv == 0)
			{
				new_model = Get_model_create(target_value);
				smrv = Set_model(new_elts, new_model);
				if (smrv != 0)
				{
					Print_log(elt_log, "ERROR : Problem moving result elements to new model < " + new_model_name + " > (err: " + To_text(smrv) + ")", LOG_LINE_ERROR, curr_elt);
					add_log = TRUE;
					++num_error;
				}
				Append(Add_undo_add("created", new_elts), undo_list);
			}
		}
		break;
		case Target_Box_Copy_To_Many_Models:
		{
			// This only creates new elements, not modify original element, so don't need to duplicate
			rv = Process_item(curr_elt, method, offset_mode, h_offset, v_offset, iterations, elt_log, new_elts);
			if (rv == 0)
			{
				new_model = Get_model_create(target_value);
				smrv = Set_model(new_elts, new_model);
				if (smrv != 0)
				{
					Print_log(elt_log, "ERROR : Problem moving result elements to new model < " + new_model_name + " > (err: " + To_text(smrv) + ")", LOG_LINE_ERROR, curr_elt);
					add_log = TRUE;
					++num_error;
				}
				Append(Add_undo_add("created", new_elts), undo_list);
			}
		}
		break;
		}
		PrintD(To_text(rv) + " : Process item < " + To_text(i) + " >");
		if (rv == 0)
		{
			Get_number_of_items(new_elts, num_new_elts);
			if (num_new_elts > 0)
			{
				num_created += num_new_elts;
			}
			++num_success;
		}
		else
		{
			Print_log(elt_log, "ERROR : Problem processing element (err: " + To_text(rv) + ")", LOG_LINE_ERROR, curr_elt);
			add_log = TRUE;
			++num_error;
		}
		if (add_log)
		{
			Append_log_line(elt_log, proc_log);
		}
	}
	Uid last_uid = Get_last_uid();
	Append(Add_undo_range("create parallel strings", first_uid, last_uid), undo_list);
	Add_undo_list(PROGRAM_NAME, undo_list);

	Print_log_line(proc_log, num_error);
	View_redraw(data);
	Null(data); // Clean-up and release objects

	PrintD("Success = " + To_text(num_success) + " , Created = " + To_text(num_created) + ", Error = " + To_text(num_error));

	return rv;
}

Integer apply_vertical_offset(Element &original_item, Real vt_drop, Element &out)
{
	Integer rv = -1;

	if (Is_null2(vt_drop) || xeqy(0.0, vt_drop))
	{
		// not needed
		return (0);
	}
	Integer points = 0;
	Get_points(out, points);
	Set_super_use_2d_level(out, 0);
	Set_super_use_3d_level(out, 1);
	for (Integer vrt = 1; vrt <= points; vrt++)
	{
		Real x, y, z = 0., xf, yf, zf, chf, dirf, off;
		Get_data(out, vrt, x, y, z);
		Drop_point(original_item, x, y, z, xf, yf, zf, chf, dirf, off);
		Set_super_vertex_coord(out, vrt, x, y, zf + vt_drop);
	}
	Calc_extent(out);
	return (rv);
}

Integer Process_item(Element &in, Integer method, Integer offset_mode, Real h_offset, Real v_offset,
					 Integer iterations, Log_Line &log, Dynamic_Element &out)
{
	Integer rv = -1;
	Text elt, in_type;
	elt = in_type = "";
	Integer num_err = 0;

	elt = Get_element_text(in);

	for (Integer i = 1; i <= iterations; i++)
	{
		Element new_elt;
		Dynamic_Element tmp;
		Real h, v;
		Null(tmp);
		//

		h = h_offset * i; // Multiply for each iteration
		v = v_offset * i; //

		PrintD(To_text(i) + ": H Off = " + To_text(h, 4) + ", V Off = " + To_text(v, 4));

		// Old parallel option
		if (method == PARALLEL_METHOD_SUPER_OFFSET)
		{
			rv = Super_offset(in, h, offset_mode, new_elt);
		}
		else
		{
			rv = Parallel(in, h, new_elt);
		}
		if (rv == 0)
		{
#if TARGET_PROPERTIES_MODE
			// Get element properties from source element
			Integer copy_mode = COPY_ELEMENT_PROPERTY_ALL;
			rv = Copy_basic_element_properties(in, copy_mode, new_elt);
			if (rv != 0)
			{
				Print_log(log, "ERROR : Problem copying string properties to new element <" + Get_element_text(new_elt) + "> (err: " + To_text(rv) + ").", LOG_LINE_ERROR, new_elt);
				++num_err;
			}
#endif // TARGET_PROPERTIES_MODE
	   // Otherwise, element properties are default/blank

			// Append(new_elt, tmp);
			// rv = Translate(new_elt, 0.0, 0.0, v);
			rv = apply_vertical_offset(in, v, new_elt);

			if (rv == 0)
			{
				Append(new_elt, out);
			}
			else
			{
				Print_log(log, "ERROR : Translating element <" + elt + "> by DZ = " + To_text(v, 3) + " (err:" + To_text(rv) + "). Skipping.", LOG_LINE_ERROR, in);
			}
		}
		else
		{
			Print_log(log, "ERROR : Problem creating parallel string " + To_text(i) + " of element <" + elt + "> (err: " + To_text(rv) + ").", LOG_LINE_ERROR, in);
			++num_err;
			continue;
		}
	}
	return num_err;
}

Integer Validate_offset_modes_box(Choice_Box &modes_box, Text &offset_modes[], Integer &offset_mode)
{
	Integer rv;
	Text mode_value;

	rv = Validate(modes_box, mode_value);
	if (rv != TRUE)
	{
		return rv;
	}

	switch (mode_value)
	{
	case (offset_modes[SUPER_OFFSET_MODE_JOIN + 1]):
	{
		offset_mode = SUPER_OFFSET_MODE_JOIN;
	}
	break;

	case (offset_modes[SUPER_OFFSET_MODE_INTERSECT + 1]):
	{
		offset_mode = SUPER_OFFSET_MODE_INTERSECT;
	}
	break;

	case (offset_modes[SUPER_OFFSET_MODE_FILLET + 1]):
	{
		offset_mode = SUPER_OFFSET_MODE_FILLET;
	}
	break;

	case (offset_modes[SUPER_OFFSET_MODE_DUAL + 1]):
	{
		offset_mode = SUPER_OFFSET_MODE_DUAL;
	}
	break;

	case (offset_modes[SUPER_OFFSET_MODE_CLIP + 1]):
	{
		offset_mode = SUPER_OFFSET_MODE_CLIP;
	}
	break;

	default:
	{
		offset_mode = -1;
		return 1;
	}
	break;
	}
	return 0;
}

Text Get_target_mode_text(Integer target_mode)
{
	switch (target_mode)
	{
	case (Target_Box_Move_To_Original_Model):
	{
		return "Move to original model(s)/replace";
	}
	break;

	case (Target_Box_Move_To_One_Model):
	{
		return "Move to one model";
	}
	break;

	case (Target_Box_Move_To_Many_Models):
	{
		return "Move to many models";
	}
	break;

	case (Target_Box_Copy_To_Original_Model):
	{
		return "Copy to original model(s)";
	}
	break;

	case (Target_Box_Copy_To_One_Model):
	{
		return "Copy to one model";
	}
	break;

	case (Target_Box_Copy_To_Many_Models):
	{
		return "Copy to many models";
	}
	break;

	default:
	{
		return "";
	}
	break;
	}
	return "";
}

Text Get_offset_mode_text(Integer offset_mode)
{
	switch (offset_mode)
	{
	case (SUPER_OFFSET_MODE_JOIN):
	{
		return "Join";
	}
	break;

	case (SUPER_OFFSET_MODE_INTERSECT):
	{
		return "Intersect";
	}
	break;

	case (SUPER_OFFSET_MODE_FILLET):
	{
		return "Fillet";
	}
	break;

	case (SUPER_OFFSET_MODE_DUAL):
	{
		return "Dual";
	}
	break;

	case (SUPER_OFFSET_MODE_CLIP):
	{
		return "Clip";
	}
	break;

	default:
	{
		return "";
	}
	}
	return "";
}

Integer Copy_basic_element_properties(Element &src_elt, Integer property_mode, Element &dest_elt)
{
	Integer rv = 0;
	Integer src_colour, src_breakline;
	Text src_name, src_style;
	Real src_weight, src_chg;
	Model src_model;

	if (property_mode & COPY_ELEMENT_PROPERTY_NAME)
	{
		rv = Get_name(src_elt, src_name);
		if (rv != 0)
			return 1;
		rv = Set_name(dest_elt, src_name);
		if (rv != 0)
			return 2;
	}
	if (property_mode & COPY_ELEMENT_PROPERTY_MODEL)
	{
		rv = Get_model(src_elt, src_model);
		if (rv != 0)
			return 3;
		rv = Set_model(dest_elt, src_model);
		if (rv != 0)
			return 4;
	}
	if (property_mode & COPY_ELEMENT_PROPERTY_COLOUR)
	{
		rv = Get_colour(src_elt, src_colour);
		if (rv != 0)
			return 5;
		rv = Set_colour(dest_elt, src_colour);
		if (rv != 0)
			return 6;
	}
	if (property_mode & COPY_ELEMENT_PROPERTY_BREAKLINE)
	{
		rv = Get_breakline(src_elt, src_breakline);
		if (rv != 0)
			return 7;
		rv = Set_breakline(dest_elt, src_breakline);
		if (rv != 0)
			return 8;
	}
	if (property_mode & COPY_ELEMENT_PROPERTY_STYLE)
	{
		rv = Get_style(src_elt, src_style);
		if (rv != 0)
			return 9;
		rv = Set_style(dest_elt, src_style);
		if (rv != 0)
			return 10;
	}
	if (property_mode & COPY_ELEMENT_PROPERTY_WEIGHT)
	{
		rv = Get_weight(src_elt, src_weight);
		if (rv != 0)
			return 11;
		rv = Set_weight(dest_elt, src_weight);
		if (rv != 0)
			return 12;
	}
	if (property_mode & COPY_ELEMENT_PROPERTY_CHAINAGE)
	{
		rv = Get_chainage(src_elt, src_chg);
		if (rv != 0)
			return 13;
		rv = Set_chainage(dest_elt, src_chg);
		if (rv != 0)
			return 14;
	}
	return rv;
}

Text Get_parallel_method_text(Integer method)
{
	Text result = "";
	if (method == PARALLEL_METHOD_SUPER_OFFSET)
	{
		result = "Super Offset";
	}
	else
	{
		result = "Parallel";
	}
	return result;
}

void Print_settings(Log_Line &log, Integer method, Integer offset_mode, Real h_offset, Real v_offset,
					Integer iterations, Integer target_mode, Text target_value)
{
	Text msg = "";
	msg = "Parallel method = " + Get_parallel_method_text(method);
	msg += " , Offset mode = ";
	if (method == PARALLEL_METHOD_SUPER_OFFSET)
	{
		msg += Get_offset_mode_text(offset_mode) + " (" + To_text(offset_mode) + ")";
	}
	else
	{
		msg += "N/A";
	}
	Print_log(log, msg, LOG_LINE_NONE);
	msg = "Horiz. offset = " + To_text(h_offset, 4);
	msg += ", Vert. shift = " + To_text(v_offset, 4);
	msg += ", Iterations = " + To_text(iterations);
	Print_log(log, msg, LOG_LINE_NONE);
	msg = "Target mode = " + Get_target_mode_text(target_mode) + ", Target value = " + target_value;
	Print_log(log, msg, LOG_LINE_NONE);

	return;
}
