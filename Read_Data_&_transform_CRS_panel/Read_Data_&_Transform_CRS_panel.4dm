/*---------------------------------------------------------------------
**   Programmer:           KLP
**   Date:                 2026-05-25
**   12D Model:            V15
**   Version:              002
**   Macro Name:           Read_Data_&_Transform_CRS_panel.4dm
**   Type:                 SOURCE
**
**   Brief description: Imports DWG/DXF or 12d data, reviews it, then approves, transforms, or rejects the import.
**
**
**---------------------------------------------------------------------
**   Description:
**       Opens the selected 12d read panel, imports data into the DATA IMPORT
**       view, and presents a review/approval workflow. Approved imports are
**       renamed with the selected model prefix, optionally vertically shifted,
**       optionally transformed to NZTM2000, added to the target data type view,
**       and cleaned of empty models. Rejected imports are deleted from DATA
**       IMPORT and empty models are removed automatically.
**
**---------------------------------------------------------------------
**   Update/Modification
**
**  This macro may be reproduced, modified and used without restriction.
**  The author grants all users Unlimited Use of the source code and any
**  associated files, for no fee. Unlimited Use includes compiling, running,
**  and modifying the code for individual or integrated purposes.
**  The author also grants 12d Solutions Pty Ltd and other users permission
**  to incorporate this macro, in whole or in part, into other macros or programs.
**---------------------------------------------------------------------
*/
#define DEBUG_FILE      0
#define ECHO_DEBUG_FILE 0
#define ECHO_LINE_NO    0

#define BUILD "version.15.0C1t"

// ----------------------------- INCLUDES -----------------------------
#include "standard_library.H"
#include "size_of.h"

/*global variables*/{

    Text gDataType = "";
    Text gDataFormat = "";

}

// helper: returns model prefix for selected as-built data type
Text Get_AsBuilt_Model_Prefix(Text dataType)
{
    Text modelPrefix = "";

    if(dataType == "EARTHWORKS") {
        modelPrefix = "EARTHWORKS/";
    }
    else if(dataType == "ROADING") {
        modelPrefix = "ROADING/";
    }
    else if(dataType == "STORMWATER") {
        modelPrefix = "STORMWATER/";
    }
    else if(dataType == "WASTEWATER") {
        modelPrefix = "WASTEWATER/";
    }
    else if(dataType == "WATERMAIN") {
        modelPrefix = "WATERMAIN/";
    }
    else if(dataType == "ELECTRICAL") {
        modelPrefix = "ELECTRICAL/";
    }
    else if(dataType == "TELECOM") {
        modelPrefix = "TELECOM/";
    }

    return modelPrefix;
}

// helper: returns as-built mapfile for selected data type
Text Get_AsBuilt_Map_File(Text dataType)
{
    Text mapFile = "";

    if(dataType == "EARTHWORKS") {
        mapFile = "AB EARTHWORKS.mapfile";
    }
    else if(dataType == "ROADING") {
        mapFile = "AB ROADING.mapfile";
    }
    else if(dataType == "STORMWATER") {
        mapFile = "AB STORMWATER.mapfile";
    }
    else if(dataType == "WASTEWATER") {
        mapFile = "AB WASTEWATER.mapfile";
    }
    else if(dataType == "WATERMAIN") {
        mapFile = "AB WATERMAIN.mapfile";
    }
    else if(dataType == "ELECTRICAL") {
        mapFile = "AB ELECTRICAL.mapfile";
    }
    else if(dataType == "TELECOM") {
        mapFile = "AB TELECOM.mapfile";
    }

    return mapFile;
}

// helper: ensures selected as-built mapfile exists in current working/project folder
Integer Ensure_AsBuilt_Map_File_Available(Text mapFile,Text &error)
{
    error = "";

    if(mapFile == "") {
        error = "Map file name is blank.";
        return -1;
    }

    // Signature: Integer File_exists(Text file_name)
    if(File_exists(mapFile)) {
        return 0;
    }

    Text sourceFolder = "F:\\DATA\\12d\\User_Lib (ASBUILT)\\"; 
    Text sourceFile = sourceFolder;
    sourceFile += mapFile;

    if(!File_exists(sourceFile)) {
        error = "Required mapfile is missing from source folder: ";
        error += sourceFile;
        return -2;
    }

    // Signature: Integer File_copy(Text new_name,Text old_name)
    Integer copyRet = File_copy(mapFile,sourceFile);

    if(copyRet != 0) {
        error = "Could not copy required mapfile from: ";
        error += sourceFile;
        error += " to current folder as: ";
        error += mapFile;
        return copyRet;
    }

    if(!File_exists(mapFile)) {
        error = "Mapfile copy completed but target file is still missing: ";
        error += mapFile;
        return -3;
    }

    return 0;
}

// helper: runs converted-chain DWG/DXF read panel with data-type settings
Integer Read_DWG_DXF_Data(Text dataType,Text &run_slf_error)
{
    Text mapFile = Get_AsBuilt_Map_File(dataType);
    Text modelPrefix = Get_AsBuilt_Model_Prefix(dataType);

    if(mapFile == "" || modelPrefix == "") {
        run_slf_error = "Unsupported data type.";
        return -99;
    }

    Integer mapCheck = Ensure_AsBuilt_Map_File_Available(mapFile,run_slf_error);

    if(mapCheck != 0) {
        return mapCheck;
    }

    Text buffer;

    buffer += "<screen_layout>\n";
    buffer += "  <version>1.0</version>\n";
    buffer += "  <panel>\n";
    buffer += "    <name>Read DWG/DXF Data</name>\n";
    buffer += "    <x>108</x>\n";
    buffer += "    <y>169</y>\n";

    buffer += "    <tick_box>\n";
    buffer += "      <name>Create anonymous function</name>\n";
    buffer += "      <value>true</value>\n";
    buffer += "    </tick_box>\n";

    buffer += "    <input_box>\n";
    buffer += "      <name>Import method</name>\n";
    buffer += "      <value>2020 64bit</value>\n";
    buffer += "    </input_box>\n";

    buffer += "    <file_box>\n";
    buffer += "      <name>File</name>\n";
    buffer += "      <value />\n";
    buffer += "    </file_box>\n";

    buffer += "    <file_box>\n";
    buffer += "      <name>Map file</name>\n";
    buffer += "      <value>";
    buffer += mapFile;
    buffer += "</value>\n";
    buffer += "    </file_box>\n";

    buffer += "    <input_box>\n";
    buffer += "      <name>Pre*postfix for models</name>\n";
    buffer += "      <value>";
    buffer += "";
    buffer += "</value>\n";
    buffer += "    </input_box>\n";

    buffer += "    <tick_box>\n";
    buffer += "      <name>Allow merge into existing models</name>\n";
    buffer += "      <value>true</value>\n";
    buffer += "    </tick_box>\n";

    buffer += "    <input_box>\n";
    buffer += "      <name>Target layer</name>\n";
    buffer += "      <value />\n";
    buffer += "    </input_box>\n";

    buffer += "    <input_box>\n";
    buffer += "      <name>Null level value</name>\n";
    buffer += "      <value>-999</value>\n";
    buffer += "    </input_box>\n";

    buffer += "    <input_box>\n";
    buffer += "      <name>Default lineweight</name>\n";
    buffer += "      <value>0.25</value>\n";
    buffer += "    </input_box>\n";

    buffer += "    <input_box>\n";
    buffer += "      <name>Spline approximation</name>\n";
    buffer += "      <value>12</value>\n";
    buffer += "    </input_box>\n";

    buffer += "    <input_box>\n";
    buffer += "      <name>Names</name>\n";
    buffer += "      <value>layer for name</value>\n";
    buffer += "    </input_box>\n";

    buffer += "    <input_box>\n";
    buffer += "      <name>Images</name>\n";
    buffer += "      <value>ignore</value>\n";
    buffer += "    </input_box>\n";

    buffer += "    <input_box>\n";
    buffer += "      <name>Blocks</name>\n";
    buffer += "      <value>to symbols</value>\n";
    buffer += "    </input_box>\n";

    buffer += "    <input_box>\n";
    buffer += "      <name>Block attributes</name>\n";
    buffer += "      <value>ignore</value>\n";
    buffer += "    </input_box>\n";

    buffer += "    <tick_box>\n";
    buffer += "      <name>Only create visible symbols</name>\n";
    buffer += "      <value>true</value>\n";
    buffer += "    </tick_box>\n";

    buffer += "    <tick_box>\n";
    buffer += "      <name>Translate 3DFaces to Faces</name>\n";
    buffer += "      <value>false</value>\n";
    buffer += "    </tick_box>\n";

    buffer += "    <tick_box>\n";
    buffer += "      <name>Use 12d Acad colour numbers</name>\n";
    buffer += "      <value>true</value>\n";
    buffer += "    </tick_box>\n";

    buffer += "    <tick_box>\n";
    buffer += "      <name>Create 2d/3d polys from ctrl points</name>\n";
    buffer += "      <value>true</value>\n";
    buffer += "    </tick_box>\n";

    buffer += "    <tick_box>\n";
    buffer += "      <name>Head to tail points/lines</name>\n";
    buffer += "      <value>true</value>\n";
    buffer += "    </tick_box>\n";

    buffer += "    <tick_box>\n";
    buffer += "      <name>Only load visible layers</name>\n";
    buffer += "      <value>true</value>\n";
    buffer += "    </tick_box>\n";

    buffer += "    <tick_box>\n";
    buffer += "      <name>Load paper space</name>\n";
    buffer += "      <value>false</value>\n";
    buffer += "    </tick_box>\n";

    buffer += "    <tick_box>\n";
    buffer += "      <name>Load xref files</name>\n";
    buffer += "      <value>true</value>\n";
    buffer += "    </tick_box>\n";

    buffer += "    <run_button>\n";
    buffer += "      <name>&amp;Read</name>\n";
    buffer += "    </run_button>\n";

    buffer += "  </panel>\n";
    buffer += "</screen_layout>\n";

    Integer pr_count = 0;
    Dynamic_Text pr_widget_path;
    Dynamic_Text pr_widget_name;
    Dynamic_Text pr_param_name;
    Dynamic_Integer pr_active;

    Integer bt_count = 0;
    Dynamic_Text bt_names;

    Text panel_name = "Read DWG/DXF Data";
    Text pvf_file = "";
    Integer clean_up = 1;
    Integer interactive = 1;


    // Signature: Integer Run_slf_data(Text slf_data,Integer pr_count,Dynamic_Text pr_widget_path,Dynamic_Text pr_widget_name,Dynamic_Text pr_param_name,Dynamic_Integer pr_active,Integer bt_count,Dynamic_Text bt_names,Text panel_name,Text pvf_file,Integer clean_up,Integer interactive,Text &error)
    Integer res = Run_slf_data(buffer,pr_count,pr_widget_path,pr_widget_name,pr_param_name,pr_active,bt_count,bt_names,panel_name,pvf_file,clean_up,interactive,run_slf_error);

    return res;
}

// helper: runs converted-chain 12d Solutions Data read panel with data-type settings
Integer Read_12d_Solutions_Data(Text dataType,Text &run_slf_error)
{
    Text mapFile = Get_AsBuilt_Map_File(dataType);
    Text modelPrefix = Get_AsBuilt_Model_Prefix(dataType);

    if(mapFile == "" || modelPrefix == "") {
        run_slf_error = "Unsupported data type.";
        return -99;
    }

    Integer mapCheck = Ensure_AsBuilt_Map_File_Available(mapFile,run_slf_error);

    if(mapCheck != 0) {
        return mapCheck;
    }

    Text buffer;

    buffer += "<screen_layout>\n";
    buffer += "  <version>1.0</version>\n";
    buffer += "  <panel>\n";
    buffer += "    <name>Read 12d Solutions Data</name>\n";
    buffer += "    <x>116</x>\n";
    buffer += "    <y>139</y>\n";

    buffer += "    <tick_box>\n";
    buffer += "      <name>Create anonymous function</name>\n";
    buffer += "      <value>true</value>\n";
    buffer += "    </tick_box>\n";

    buffer += "    <files_box>\n";
    buffer += "      <name>Input file</name>\n";
    buffer += "      <tick_box>\n";
    buffer += "        <name>Advanced</name>\n";
    buffer += "        <value>false</value>\n";
    buffer += "      </tick_box>\n";
    buffer += "      <widget_pages>\n";
    buffer += "        <name>Pages</name>\n";
    buffer += "        <current_page>1</current_page>\n";
    buffer += "        <widget_page>\n";
    buffer += "          <name>1</name>\n";
    buffer += "          <file_box>\n";
    buffer += "            <name>File to read</name>\n";
    buffer += "            <value />\n";
    buffer += "          </file_box>\n";
    buffer += "        </widget_page>\n";
    buffer += "      </widget_pages>\n";
    buffer += "    </files_box>\n";

    buffer += "    <file_box>\n";
    buffer += "      <name>Map file</name>\n";
    buffer += "      <value>";
    buffer += mapFile;
    buffer += "</value>\n";
    buffer += "    </file_box>\n";

    buffer += "    <input_box>\n";
    buffer += "      <name>Pre*postfix for models</name>\n";
    buffer += "      <value>";
    buffer += "";
    buffer += "</value>\n";
    buffer += "    </input_box>\n";

    buffer += "    <tick_box>\n";
    buffer += "      <name>Use pre*postfix for tins</name>\n";
    buffer += "      <value>false</value>\n";
    buffer += "    </tick_box>\n";

    buffer += "    <tick_box>\n";
    buffer += "      <name>Use map file model when pt/line changes</name>\n";
    buffer += "      <value>false</value>\n";
    buffer += "    </tick_box>\n";

    buffer += "    <tick_box>\n";
    buffer += "      <name>Allow #include to be used</name>\n";
    buffer += "      <value>false</value>\n";
    buffer += "    </tick_box>\n";

    buffer += "    <tick_box>\n";
    buffer += "      <name>Convert 2d,3d,4d,poly,face,interface to super</name>\n";
    buffer += "      <value>true</value>\n";
    buffer += "    </tick_box>\n";

    buffer += "    <input_box>\n";
    buffer += "      <name>Model attributes</name>\n";
    buffer += "      <value>read and merge/duplicate</value>\n";
    buffer += "    </input_box>\n";

    buffer += "    <input_box>\n";
    buffer += "      <name>Merge with existing model attributes</name>\n";
    buffer += "      <value>delete old values</value>\n";
    buffer += "    </input_box>\n";

    buffer += "    <input_box>\n";
    buffer += "      <name>Project attributes</name>\n";
    buffer += "      <value>read and merge/duplicate</value>\n";
    buffer += "    </input_box>\n";

    buffer += "    <input_box>\n";
    buffer += "      <name>On existing project attributes</name>\n";
    buffer += "      <value>delete old values</value>\n";
    buffer += "    </input_box>\n";

    buffer += "    <input_box>\n";
    buffer += "      <name>On existing tins</name>\n";
    buffer += "      <value>error</value>\n";
    buffer += "    </input_box>\n";

    buffer += "    <tick_box>\n";
    buffer += "      <name>No error on missing raster image file</name>\n";
    buffer += "      <value>false</value>\n";
    buffer += "    </tick_box>\n";

    buffer += "    <polygon_box>\n";
    buffer += "      <name>Fence string</name>\n";
    buffer += "    </polygon_box>\n";

    buffer += "    <input_box>\n";
    buffer += "      <name>Fence mode</name>\n";
    buffer += "      <value />\n";
    buffer += "    </input_box>\n";

    buffer += "    <run_button>\n";
    buffer += "      <name>Read</name>\n";
    buffer += "    </run_button>\n";

    buffer += "  </panel>\n";
    buffer += "</screen_layout>\n";

    Integer pr_count = 0;
    Dynamic_Text pr_widget_path;
    Dynamic_Text pr_widget_name;
    Dynamic_Text pr_param_name;
    Dynamic_Integer pr_active;

    Integer bt_count = 0;
    Dynamic_Text bt_names;

    Text panel_name = "Read 12d Solutions Data";
    Text pvf_file = "";
    Integer clean_up = 1;
    Integer interactive = 1;

    // Signature: Integer Append(Text item,Dynamic_Text &array)
    Append("Read",bt_names);

    // Signature: Integer Run_slf_data(Text slf_data,Integer pr_count,Dynamic_Text pr_widget_path,Dynamic_Text pr_widget_name,Dynamic_Text pr_param_name,Dynamic_Integer pr_active,Integer bt_count,Dynamic_Text bt_names,Text panel_name,Text pvf_file,Integer clean_up,Integer interactive,Text &error)
    Integer res = Run_slf_data(buffer,pr_count,pr_widget_path,pr_widget_name,pr_param_name,pr_active,bt_count,bt_names,panel_name,pvf_file,clean_up,interactive,run_slf_error);

    return res;
}

// helper: ensures a named plan view exists
Integer Ensure_View_Exists(Text viewName,Text &error)
{
    error = "";

    if(viewName == "") {
        error = "View name is blank.";
        return -1;
    }

    // Signature: Integer View_exists(Text)
    if(View_exists(viewName)) {
        return 0;
    }

    // Signature: Integer View_create(Integer type,Text name,Integer left,Integer top,Integer width,Integer height,Integer engine_type)
    Integer createRet = View_create(0,viewName,100,100,900,700,1);

    if(createRet != 0) {
        error = "Could not create view: ";
        error += viewName;
        return createRet;
    }

    if(!View_exists(viewName)) {
        error = "View still missing after create: ";
        error += viewName;
        return -2;
    }

    return 0;
}

// helper: sets named view state
Integer Set_View_State(Text viewName,Text viewState,Text &error)
{
    error = "";

    Integer ensureRet = Ensure_View_Exists(viewName,error);

    if(ensureRet != 0) {
        return ensureRet;
    }

    // Signature: View Get_view(Text vname)
    View view = Get_view(viewName);

    Integer ret = 0;

    if(viewState == "restore") {
        // Signature: Integer View_restore(View v)
        ret = View_restore(view);
    }
    else if(viewState == "minimize") {
        // Signature: Integer View_minimize(View v)
        ret = View_minimize(view);
    }
    else if(viewState == "maximize") {
        // Signature: Integer View_maximize(View v)
        ret = View_maximize(view);
    }
    else {
        error = "Unknown view state: ";
        error += viewState;
        return -3;
    }

    if(ret != 0) {
        error = "Could not set view state for: ";
        error += viewName;
        return ret;
    }

    return 0;
}

// Maximize DATA IMPORT view so users can review imported data
Integer Show_DATA_IMPORT_View(Text &error)
{
    return Set_View_State("DATA IMPORT","maximize",error);
}

// Minimize DATA IMPORT view after user approved or rejected data imported
Integer Minimize_DATA_IMPORT_View(Text &error)
{
    return Set_View_State("DATA IMPORT","minimize",error);
}

// helper: deletes all elements currently shown in DATA IMPORT view
Integer Delete_DATA_IMPORT_Elements(Integer &deletedCount,Text &error)
{
    deletedCount = 0;
    error = "";

    if(!View_exists("DATA IMPORT")) {
        error = "View does not exist: DATA IMPORT";
        return -1;
    }

    View dataImportView = Get_view("DATA IMPORT");

    Dynamic_Text modelNames;
    Integer retModels = View_get_models(dataImportView,modelNames);

    if(retModels != 0) {
        error = "Could not get DATA IMPORT view models.";
        return retModels;
    }

    Integer modelCount = 0;
    Get_number_of_items(modelNames,modelCount);

    for(Integer i = 1; i <= modelCount; i++) {
        Text modelName = "";
        Get_item(modelNames,i,modelName);

        Model model = Get_model(modelName);

        if(Model_exists(model)) {
            Dynamic_Element elements;
            Integer elementCount = 0;

            Get_elements(model,elements,elementCount);

            for(Integer j = elementCount; j >= 1; j--) {
                Element element;
                Get_item(elements,j,element);

                if(Element_delete(element) == 0) {
                    deletedCount++;
                }
            }
        }
    }

    return 0;
}

// helper: transforms DATA IMPORT from selected NZ2000 circuit to NZTM2000
Integer Transform_DATA_IMPORT_To_NZTM2000(Text fromCircuit,Text moveToModelPrefix,Text &run_slf_error)
{
    Text buffer;

    buffer += "<screen_layout>\n";
    buffer += "  <version>1.0</version>\n";
    buffer += "  <panel>\n";
    buffer += "    <name>New Zealand Conversions</name>\n";
    buffer += "    <x>439</x>\n";
    buffer += "    <y>272</y>\n";

    buffer += "    <input_box>\n";
    buffer += "      <name>Datum</name>\n";
    buffer += "      <value>NZ2000</value>\n";
    buffer += "    </input_box>\n";

    buffer += "    <input_box>\n";
    buffer += "      <name>Input data type</name>\n";
    buffer += "      <value>Circuit</value>\n";
    buffer += "    </input_box>\n";

    buffer += "    <input_box>\n";
    buffer += "      <name>Input Long/Lat unit</name>\n";
    buffer += "      <value>degrees (dms)</value>\n";
    buffer += "    </input_box>\n";

    buffer += "    <input_box>\n";
    buffer += "      <name>Out data type</name>\n";
    buffer += "      <value>NZMG/NZTM2000</value>\n";
    buffer += "    </input_box>\n";

    buffer += "    <input_box>\n";
    buffer += "      <name>Out Long/Lat unit</name>\n";
    buffer += "      <value>degrees (dms)</value>\n";
    buffer += "    </input_box>\n";

    buffer += "    <input_box>\n";
    buffer += "      <name>From circuit</name>\n";
    buffer += "      <value>";
    buffer += fromCircuit;
    buffer += "</value>\n";
    buffer += "    </input_box>\n";

    buffer += "    <input_box>\n";
    buffer += "      <name>To circuit.</name>\n";
    buffer += "      <value />\n";
    buffer += "    </input_box>\n";

    buffer += "    <tick_box>\n";
    buffer += "      <name>Use data source</name>\n";
    buffer += "      <value>true</value>\n";
    buffer += "    </tick_box>\n";

    buffer += "    <source_box>\n";
    buffer += "      <name>Data to transform</name>\n";
    buffer += "      <mode>Source_Box_View</mode>\n";
    buffer += "      <input_box>\n";
    buffer += "        <name>Data to transform - View</name>\n";
    buffer += "        <value>DATA IMPORT</value>\n";
    buffer += "      </input_box>\n";
    buffer += "    </source_box>\n";

    buffer += "    <target_box>\n";
    buffer += "      <name>Target</name>\n";
    buffer += "      <mode>Target_Box_Move_To_Original_Model</mode>\n";
    buffer += "      <tick_box>\n";
    buffer += "        <name>Target - Replace existing data</name>\n";
    buffer += "        <value>true</value>\n";
    buffer += "      </tick_box>\n";
    buffer += "    </target_box>\n";

    buffer += "    <input_box>\n";
    buffer += "      <name>Input coordinates</name>\n";
    buffer += "      <value />\n";
    buffer += "    </input_box>\n";

    buffer += "    <input_box>\n";
    buffer += "      <name>Output coordinates</name>\n";
    buffer += "      <value />\n";
    buffer += "    </input_box>\n";

    buffer += "    <run_button>\n";
    buffer += "      <name>Process</name>\n";
    buffer += "    </run_button>\n";

    buffer += "  </panel>\n";
    buffer += "</screen_layout>\n";

    Integer pr_count = 6;
    Dynamic_Text pr_widget_path;
    Dynamic_Text pr_widget_name;
    Dynamic_Text pr_param_name;
    Dynamic_Integer pr_active;

    Integer bt_count = 1;
    Dynamic_Text bt_names;

    Text panel_name = "New Zealand Conversions";
    Text pvf_file = "";
    Integer clean_up = 1;
    Integer interactive = 0;

    Append("NZ2000",pr_param_name);
    Append("Datum",pr_widget_name);
    Append("Datum",pr_widget_path);
    Append(1,pr_active);

    Append("Circuit",pr_param_name);
    Append("Input data type",pr_widget_name);
    Append("Input data type",pr_widget_path);
    Append(1,pr_active);

    Append("NZMG/NZTM2000",pr_param_name);
    Append("Out data type",pr_widget_name);
    Append("Out data type",pr_widget_path);
    Append(1,pr_active);

    Append(fromCircuit,pr_param_name);
    Append("From circuit",pr_widget_name);
    Append("From circuit",pr_widget_path);
    Append(1,pr_active);

    Append("DATA IMPORT",pr_param_name);
    Append("View",pr_widget_name);
    Append("Data to transform - View",pr_widget_path);
    Append(1,pr_active);

    Append("true",pr_param_name);
    Append("Replace existing data",pr_widget_name);
    Append("Target - Replace existing data",pr_widget_path);
    Append(1,pr_active);

    Append("Process",bt_names);

    Integer res = Run_slf_data(buffer,pr_count,pr_widget_path,pr_widget_name,pr_param_name,pr_active,bt_count,bt_names,panel_name,pvf_file,clean_up,interactive,run_slf_error);

    return res;
}

// helper: translates DATA IMPORT with X=0, Y=0, Z=deltaZ, and applies model prefix
Integer Translate_DATA_IMPORT(Text moveToModelPrefix,Real deltaZ,Text &run_slf_error)
{
    Text deltaZText = To_text(deltaZ,6);

    Text buffer;

    buffer += "<screen_layout>\n";
    buffer += "  <version>1.0</version>\n";
    buffer += "  <panel>\n";
    buffer += "    <name>Translate</name>\n";
    buffer += "    <x>608</x>\n";
    buffer += "    <y>255</y>\n";

    buffer += "    <source_box>\n";
    buffer += "      <name>Data to translate</name>\n";
    buffer += "      <mode>Source_Box_View</mode>\n";
    buffer += "      <input_box>\n";
    buffer += "        <name>Data to translate - View</name>\n";
    buffer += "        <value>DATA IMPORT</value>\n";
    buffer += "      </input_box>\n";
    buffer += "    </source_box>\n";

    buffer += "    <xyz_box>\n";
    buffer += "      <name>Translate data</name>\n";
    buffer += "      <input_box>\n";
    buffer += "        <name>Delta X</name>\n";
    buffer += "        <value>0</value>\n";
    buffer += "      </input_box>\n";
    buffer += "      <input_box>\n";
    buffer += "        <name>Delta Y</name>\n";
    buffer += "        <value>0</value>\n";
    buffer += "      </input_box>\n";
    buffer += "      <input_box>\n";
    buffer += "        <name>Delta Z</name>\n";
    buffer += "        <value>";
    buffer += deltaZText;
    buffer += "</value>\n";
    buffer += "      </input_box>\n";
    buffer += "    </xyz_box>\n";

    buffer += "    <target_box>\n";
    buffer += "      <name>Target</name>\n";
    buffer += "      <mode>Target_Box_Move_To_Many_Models</mode>\n";
    buffer += "      <input_box>\n";
    buffer += "        <name>Target - Move to model prefix</name>\n";
    buffer += "        <value>";
    buffer += moveToModelPrefix;
    buffer += "</value>\n";
    buffer += "      </input_box>\n";
    buffer += "    </target_box>\n";

    buffer += "    <run_button>\n";
    buffer += "      <name>&amp;Translate</name>\n";
    buffer += "    </run_button>\n";

    buffer += "  </panel>\n";
    buffer += "</screen_layout>\n";

    Integer pr_count = 5;
    Dynamic_Text pr_widget_path;
    Dynamic_Text pr_widget_name;
    Dynamic_Text pr_param_name;
    Dynamic_Integer pr_active;

    Integer bt_count = 1;
    Dynamic_Text bt_names;

    Text panel_name = "Translate";
    Text pvf_file = "";
    Integer clean_up = 1;
    Integer interactive = 0;

    Append("DATA IMPORT",pr_param_name);
    Append("View",pr_widget_name);
    Append("Data to translate - View",pr_widget_path);
    Append(1,pr_active);

    Append("0",pr_param_name);
    Append("Delta X",pr_widget_name);
    Append("Translate data",pr_widget_path);
    Append(1,pr_active);

    Append("0",pr_param_name);
    Append("Delta Y",pr_widget_name);
    Append("Translate data",pr_widget_path);
    Append(1,pr_active);

    Append(deltaZText,pr_param_name);
    Append("Delta Z",pr_widget_name);
    Append("Translate data",pr_widget_path);
    Append(1,pr_active);

    Append(moveToModelPrefix,pr_param_name);
    Append("Move to model prefix",pr_widget_name);
    Append("Target - Move to model prefix",pr_widget_path);
    Append(1,pr_active);

    Append("&Translate",bt_names);

    Integer res = Run_slf_data(buffer,pr_count,pr_widget_path,pr_widget_name,pr_param_name,pr_active,bt_count,bt_names,panel_name,pvf_file,clean_up,interactive,run_slf_error);

    return res;
}

// helper: second macro panel for imported-data approval
Integer Approval_Panel(Text &decision)
{
    decision = "";

    Text panelName = "Approve Imported Data";
    Panel panel = Create_panel(panelName,TRUE);
    Vertical_Group vgroup = Create_vertical_group(-1);
    Colour_Message_Box cmbMsg = Create_colour_message_box("");

    Set_data(cmbMsg,"Review DATA IMPORT view. Approve or undo the import.");

    Horizontal_Group bgroup = Create_button_group();

    Button approveBtn = Create_button("&Approve","approve");
    Button undoBtn    = Create_button("&Undo import","undo_import");
    Button cancelBtn  = Create_finish_button("Cancel","cancel");

    Append(approveBtn,bgroup);
    Append(undoBtn,bgroup);
    Append(cancelBtn,bgroup);

    Append(cmbMsg,vgroup);
    Append(bgroup,vgroup);
    Append(vgroup,panel);

    Show_widget(panel);

    Integer doit = 1;

    while(doit) {
        Text cmd = "", msg = "";
        Integer id, ret = Wait_on_widgets(id,cmd,msg);

        switch(id) {
        case Get_id(approveBtn) :
        {
            if(cmd == "approve") {
                decision = "Approve";
                doit = 0;
            }
        }
        break;

        case Get_id(undoBtn) :
        {
            if(cmd == "undo_import") {
                decision = "Undo import";
                doit = 0;
            }
        }
        break;

        case Get_id(cancelBtn) :
        {
            decision = "Cancel";
            doit = 0;
        }
        break;

        case Get_id(panel) :
        {
            if(cmd == "Panel Quit") {
                decision = "Cancel";
                doit = 0;
            }
        }
        break;
        }
    }

    return 0;
}

// helper: restores target view matching selected data type
Integer Show_Target_DataType_View(Text dataType,Text &error)
{
    return Set_View_State(dataType,"restore",error);
}

// helper: add non-empty prefixed models to target data type view
Integer Add_Prefixed_Models_To_Target_View(Text dataType,Text modelPrefix,Integer &addedCount,Text &error)
{
    addedCount = 0;
    error = "";

    if(dataType == "") {
        error = "Target data type is blank.";
        return -1;
    }

    if(modelPrefix == "") {
        error = "Model prefix is blank.";
        return -2;
    }

    if(!View_exists(dataType)) {
        error = "Target view does not exist: ";
        error += dataType;
        return -3;
    }

    View targetView = Get_view(dataType);

    Dynamic_Text modelNames;
    Integer modelCount = 0;

    Integer retModels = Get_project_models(modelNames);

    if(retModels != 0) {
        error = "Could not get project model list.";
        return retModels;
    }

    Get_number_of_items(modelNames,modelCount);

    for(Integer i = 1; i <= modelCount; i++) {
        Text modelName = "";
        Get_item(modelNames,i,modelName);

        if(Find_text(modelName,modelPrefix) == 1) {
            Model model = Get_model(modelName);

            if(Model_exists(model)) {
                Integer itemCount = 0;
                Get_number_of_items(model,itemCount);

                if(itemCount > 0) {
                    Integer addRet = View_add_model(targetView,model);

                    if(addRet == 0) {
                        addedCount++;
                    }
                }
            }
        }
    }

    return 0;
}

Integer Finalise_Review_Views(Text dataType,Colour_Message_Box cmbMsg)
{
    Text minErr = "";
    Text targetErr = "";

    Integer minRet = Minimize_DATA_IMPORT_View(minErr);

    if(minRet != 0) {
        Text msg = "WARNING: DATA IMPORT minimise failed. ";
        msg += minErr;
        Set_data(cmbMsg,msg);
    }

    Integer targetRet = Show_Target_DataType_View(dataType,targetErr);

    if(targetRet != 0) {
        Text msg2 = "WARNING: target view restore failed. ";
        msg2 += targetErr;
        Set_data(cmbMsg,msg2);
        return targetRet;
    }

    return 0;
}

// helper: deletes all empty models in the project
Integer Delete_Empty_Models(Integer &deletedCount,Text &error)
{
    deletedCount = 0;
    error = "";

    Dynamic_Text modelNames;
    Integer modelCount = 0;

    Integer retModels = Get_project_models(modelNames);

    if(retModels != 0) {
        error = "Could not get project model list.";
        return retModels;
    }

    Get_number_of_items(modelNames,modelCount);

    for(Integer i = 1; i <= modelCount; i++) {
        Text modelName = "";
        Get_item(modelNames,i,modelName);

        Model model = Get_model(modelName);

        if(Model_exists(model)) {
            Integer itemCount = 0;
            Get_number_of_items(model,itemCount);

            if(itemCount == 0) {
                Integer delRet = Model_delete(model);

                if(delRet == 0) {
                    deletedCount++;
                }
            }
        }
    }

    return 0;
}

void mainPanel(){
 
    Text panelName="As-Built Data Import";
    Panel              panel  = Create_panel              (panelName,TRUE);
    Vertical_Group     vgroup = Create_vertical_group     (-1         );
    Colour_Message_Box cmbMsg = Create_colour_message_box (""         );

    ///////////////////CREATE INPUT WIDGETS////////////////
    // create some input fields

    Choice_Box cbDataType = Create_choice_box("As-built data type",cmbMsg);

    Text dataTypes[7];
    dataTypes[1] = "EARTHWORKS";
    dataTypes[2] = "ROADING";
    dataTypes[3] = "STORMWATER";
    dataTypes[4] = "WASTEWATER";
    dataTypes[5] = "WATERMAIN";
    dataTypes[6] = "ELECTRICAL";
    dataTypes[7] = "TELECOM";

    Set_data(cbDataType,7,dataTypes);
    Set_data(cbDataType,"EARTHWORKS");

    Choice_Box cbDataFormat = Create_choice_box("Data format",cmbMsg);

    Text dataFormats[2];
    dataFormats[1] = "DWG/DXF";
    dataFormats[2] = "12d Solutions Data";

    Set_data(cbDataFormat,2,dataFormats);
    Set_data(cbDataFormat,"DWG/DXF");

    Named_Tick_Box ntbTransformToNZTM = Create_named_tick_box("Transform data to NZTM2000?",TRUE,"toggle_transform");
    Set_data(ntbTransformToNZTM,TRUE);

    Choice_Box cbFromCircuit = Create_choice_box("From NZ2000 circuit",cmbMsg);

    Text circuitNames[29];
    circuitNames[1]  = "Amuri";
    circuitNames[2]  = "Bay of Plenty";
    circuitNames[3]  = "Bluff";
    circuitNames[4]  = "Buller";
    circuitNames[5]  = "Chatham Islands";
    circuitNames[6]  = "Collingwood";
    circuitNames[7]  = "Gawler";
    circuitNames[8]  = "Grey";
    circuitNames[9]  = "Hawkes Bay";
    circuitNames[10] = "Hokitika";
    circuitNames[11] = "Jacksons Bay";
    circuitNames[12] = "Karamea";
    circuitNames[13] = "Lindis Peak";
    circuitNames[14] = "Marlborough";
    circuitNames[15] = "Mount Eden";
    circuitNames[16] = "Mount Nicholas";
    circuitNames[17] = "Mount Pleasant";
    circuitNames[18] = "Mount York";
    circuitNames[19] = "Nelson";
    circuitNames[20] = "North Taieri";
    circuitNames[21] = "Observation Pt";
    circuitNames[22] = "Okarito";
    circuitNames[23] = "Poverty Bay";
    circuitNames[24] = "Taranaki";
    circuitNames[25] = "Timaru";
    circuitNames[26] = "Tuhirangi";
    circuitNames[27] = "Wairarapa";
    circuitNames[28] = "Wanganui";
    circuitNames[29] = "Wellington";

    Set_data(cbFromCircuit,29,circuitNames);
    Set_data(cbFromCircuit,"Mount Eden");

    Input_Box ipbTransformPrefix = Create_input_box("Move to model prefix",cmbMsg);
    Set_data(ipbTransformPrefix,"EARTHWORKS/");
    
    Real_Box rbVerticalTranslation = Create_real_box("Vertical translation Z",cmbMsg);
    Set_data(rbVerticalTranslation,0.0);
        

    ///////////////ADDING BUTTONS ALONG THE BOTTOM///////////////////////////
    Horizontal_Group bgroup = Create_button_group();
    Button process     = Create_button       ("&Process" ,"process");
    Button review      = Create_button       ("&Review Import","review_import");
    Button finish      = Create_finish_button("Finish"   ,"Finish" );
    Button help_button = Create_help_button  (panel      ,"Help"   );
    Append(process      ,bgroup);
    Append(review       ,bgroup);
    Append(finish       ,bgroup);
    Append(help_button  ,bgroup);

    ///////////////ADDING WIDGETS TO PANEL///////////////////////////
    // add your widgets to vgroup

    Append(cbDataType,vgroup);
    Append(cbDataFormat,vgroup);
    Append(ntbTransformToNZTM,vgroup);
    Append(cbFromCircuit,vgroup);
    Append(ipbTransformPrefix,vgroup);
    Append(rbVerticalTranslation,vgroup);

    Append(cmbMsg    ,vgroup);
    Append(bgroup    ,vgroup);

    Append(vgroup,panel);
    Show_widget(panel);

    Integer doit = 1;
    while(doit)
    {
        Text cmd="",msg = "";
        Integer id,ret = Wait_on_widgets(id,cmd,msg);
 
        switch(cmd)
        {
        case "keystroke" :
        case "set_focus"  :
        case "kill_focus" :
        case "toggle tick" :
        {
            continue;
        }
        break;
        case "CodeShutdown" :
        {
            Set_exit_code(cmd);
        }
        break;
        }

        switch(id)
        {
        case Get_id(panel) :
        {
            if(cmd == "Panel Quit") doit = 0;
            if(cmd == "Panel About") about_panel(panel);
        }
        break; 

        case Get_id(process) :
        {
            if(cmd == "process")
            {
                // declare your widget variables

                Text run_slf_error = "";
                Integer ok = TRUE;

                gDataType = "";
                gDataFormat = "";

                // validate widgets

                Get_data(cbDataType,gDataType);
                if(gDataType == "") {
                    Set_data(cmbMsg,"ERROR: Select an as-built data type.");
                    ok = FALSE;
                }
                if(ok) {
                    Text defaultPrefix = Get_AsBuilt_Model_Prefix(gDataType);
                    if(defaultPrefix != "") {
                        Set_data(ipbTransformPrefix,defaultPrefix);
                    }
                }

                if(ok) {
                    Get_data(cbDataFormat,gDataFormat);
                    if(gDataFormat == "") {
                        Set_data(cmbMsg,"ERROR: Select a data format.");
                        ok = FALSE;
                    }
                }

                // do calc

                if(ok) {
                    if(gDataFormat == "DWG/DXF") {
                        Set_data(cmbMsg,"Running DWG/DXF read panel...");

                        Integer res = Read_DWG_DXF_Data(gDataType,run_slf_error);

                        if(res == 0) {
                            Set_data(cmbMsg,"DWG/DXF read panel launched. After reading data, click Review Import.");
                        }
                        else {
                            Text err = "ERROR: DWG/DXF import panel failed.";

                            if(run_slf_error != "") {
                                err += " ";
                                err += run_slf_error;
                            }

                            Set_data(cmbMsg,err);
                        }
                    }
                    else if(gDataFormat == "12d Solutions Data") {
                        Set_data(cmbMsg,"Running 12d Solutions Data read panel...");

                        Integer res12d = Read_12d_Solutions_Data(gDataType,run_slf_error);

                        if(res12d == 0) {
                            Set_data(cmbMsg,"12d Solutions Data read panel launched. After reading data, click Review Import.");
                        }
                        else {
                            Text err12d = "ERROR: 12d Solutions Data import panel failed.";

                            if(run_slf_error != "") {
                                err12d += " ";
                                err12d += run_slf_error;
                            }

                            Set_data(cmbMsg,err12d);
                        }
                    }
                    else {
                        Set_data(cmbMsg,"Unsupported data format.");
                    }
                }

                Print("--- AsBuilt import end ---\n");
            }
        }
        break;

        case Get_id(review) :
        {
            if(cmd == "review_import")
            {
                if(gDataType == "") {
                    Set_data(cmbMsg,"ERROR: Select data type and click Process before Review Import.");
                }
                else {
                    Text viewError = "";
                    Integer viewRet = Show_DATA_IMPORT_View(viewError);

                    if(viewRet == 0) {
                        Text decision = "";
                        Approval_Panel(decision);

                            if(decision == "Approve") {
                                Integer transformOn = FALSE;
                                Text fromCircuit = "";
                                Text movePrefix = "";
                                Text verticalZText = "";
                                Real verticalZ = 0.0;

                                Validate(ntbTransformToNZTM,transformOn);
                                Get_data(cbFromCircuit,fromCircuit);
                                Get_data(ipbTransformPrefix,movePrefix);
                                Get_data(rbVerticalTranslation,verticalZText);

                                From_text(verticalZText,verticalZ);

                                if(movePrefix == "") {
                                    Set_data(cmbMsg,"ERROR: Enter Move to model prefix.");
                                }
                                else {
                                    Text translateError = "";

                                    Set_data(cmbMsg,"Applying model prefix and vertical translation...");

                                    Integer translateRet = Translate_DATA_IMPORT(movePrefix,verticalZ,translateError);

                                    if(translateRet != 0) {
                                        Text terr = "ERROR: Translate/prefix failed. ";
                                        terr += translateError;
                                        Set_data(cmbMsg,terr);
                                    }
                                    else if(transformOn) {
                                        if(fromCircuit == "") {
                                            Set_data(cmbMsg,"ERROR: Select From NZ2000 circuit.");
                                        }
                                        else {
                                            Text transformError = "";

                                            Set_data(cmbMsg,"Transforming prefixed data to NZTM2000...");

                                            Integer transformRet = Transform_DATA_IMPORT_To_NZTM2000(fromCircuit,"",transformError);

                                            if(transformRet == 0) {
                                                Integer finalViewRet = Finalise_Review_Views(gDataType,cmbMsg);

                                                if(finalViewRet == 0) {
                                                    Integer addedModels = 0;
                                                    Text addModelsError = "";
                                                    Integer addModelsRet = Add_Prefixed_Models_To_Target_View(gDataType,movePrefix,addedModels,addModelsError);

                                                    Integer deletedModels = 0;
                                                    Text deleteError = "";

                                                    Delete_Empty_Models(deletedModels,deleteError);

                                                    Text doneMsg = "Vertical translation and NZTM2000 transformation completed. Empty models deleted: ";
                                                    doneMsg += To_text(deletedModels);
                                                    doneMsg += ". Models added to target view: ";
                                                    doneMsg += To_text(addedModels);

                                                    if(addModelsRet != 0) {
                                                        doneMsg += ". WARNING: add models to target view failed: ";
                                                        doneMsg += addModelsError;
                                                    }

                                                    Set_data(cmbMsg,doneMsg);
                                                }
                                                else {
                                                    Set_data(cmbMsg,"Transformation completed, but final view handling failed.");
                                                }
                                            }
                                            else {
                                                Text terr2 = "ERROR: Transformation failed. ";
                                                terr2 += transformError;
                                                Set_data(cmbMsg,terr2);
                                            }
                                        }
                                    }
                                    else {
                                        Integer finalViewRet2 = Finalise_Review_Views(gDataType,cmbMsg);

                                        if(finalViewRet2 == 0) {
                                            Integer addedModels2 = 0;
                                            Text addModelsError2 = "";
                                            Integer addModelsRet2 = Add_Prefixed_Models_To_Target_View(gDataType,movePrefix,addedModels2,addModelsError2);

                                            Integer deletedModels2 = 0;
                                            Text deleteError2 = "";

                                            Delete_Empty_Models(deletedModels2,deleteError2);

                                            Text doneMsg2 = "Prefix/vertical translation completed. NZTM2000 transformation skipped. Target view restored. Empty models deleted: ";
                                            doneMsg2 += ". Models added to target view: ";
                                            doneMsg2 += To_text(addedModels2);

                                            if(addModelsRet2 != 0) {
                                                doneMsg2 += ". WARNING: add models to target view failed: ";
                                                doneMsg2 += addModelsError2;
                                            }

                                            Set_data(cmbMsg,doneMsg2);
                                        }
                                        else {
                                            Set_data(cmbMsg,"Prefix/vertical translation completed, but final view handling failed.");
                                        }
                                    }
                                }
                            }
                        else if(decision == "Undo import") {
                            Integer deletedImportElements = 0;
                            Text deleteImportError = "";

                            Integer deleteImportRet = Delete_DATA_IMPORT_Elements(deletedImportElements,deleteImportError);

                            Text minErrUndo = "";
                            Minimize_DATA_IMPORT_View(minErrUndo);

                            if(deleteImportRet == 0) {
                                Integer deletedEmptyModels = 0;
                                Text deleteEmptyModelsError = "";

                                Integer deleteEmptyModelsRet = Delete_Empty_Models(deletedEmptyModels,deleteEmptyModelsError);

                                Text undoMsg = "Import rejected. Imported elements deleted: ";
                                undoMsg += To_text(deletedImportElements);
                                undoMsg += ". Empty models deleted: ";
                                undoMsg += To_text(deletedEmptyModels);

                                if(deleteEmptyModelsRet != 0) {
                                    undoMsg += ". WARNING: empty model cleanup failed: ";
                                    undoMsg += deleteEmptyModelsError;
                                }

                                Set_data(cmbMsg,undoMsg);
                            }
                            else {
                                Text undoErr = "ERROR: Import reject cleanup failed. ";
                                undoErr += deleteImportError;
                                Set_data(cmbMsg,undoErr);
                            }
                        }
                        else {
                            Text minErrCancel = "";
                            Minimize_DATA_IMPORT_View(minErrCancel);
                            Set_data(cmbMsg,"Approval cancelled.");
                        }
                    }
                    else {
                    Text err = "ERROR: ";
                    err += viewError;
                    Set_data(cmbMsg,err);
                }
            }
            }
        }
        break;

        default :
        {
            if(cmd == "Finish") doit = 0;
        }
        break;
        }
    }
}

// ----------------------------- MAIN -----------------------------
void main(){

    // do pre-panel checks here
    
    mainPanel();
}