/*---------------------------------------------------------------------
**   Programmer:KLP
**   Date:26/05/08             
**   12D Model:            V15
**   Version:              001
**   Macro Name:           Colour_trimesh_by_TIN_triangles_panel.4dm
**   Type:                 SOURCE
**
**   Brief description: Colour existing Trimesh faces from TIN triangle colours
**
**
**---------------------------------------------------------------------
**   Description: Transfers per-triangle colours from a coloured TIN (Super TIN not supported)
**                to existing Trimesh face colours. The macro
**                assumes the Trimesh was created from the source TIN and
**                that exported TIN triangles are in Trimesh face order.
**
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

#define BUILD "15.0.001"

// ----------------------------- INCLUDES -----------------------------
#include "standard_library.H"
#include "size_of.H"
/*global variables*/{

}

void mainPanel(){

    Text panelName="Colour Trimesh By TIN Triangle Colours";
    Panel              panel  = Create_panel              (panelName,TRUE);
    Vertical_Group     vgroup = Create_vertical_group     (-1         );
    Colour_Message_Box cmbMsg = Create_colour_message_box (""         );

    ///////////////////CREATE INPUT WIDGETS////////////////
    Tin_Box tbSourceTin = Create_tin_box("Source coloured TIN",cmbMsg,CHECK_TIN_MUST_EXIST);
    Set_supertin(tbSourceTin,FALSE);
    Source_Box sbTargetTrimeshes = Create_source_box("Target Trimesh source",cmbMsg,Source_Box_All | Source_Box_Fence_Inside | Source_Box_Fence_Outside | Source_Box_Fence_Cross | Source_Box_Fence_String);
    Colour_Box cbFallbackColour = Create_colour_box("Fallback colour",cmbMsg);

    ///////////////ADDING BUTTONS ALONG THE BOTTOM///////////////////////////
    Horizontal_Group bgroup = Create_button_group();
    Button process     = Create_button       ("&Process" ,"process");
    Button finish      = Create_finish_button("Finish"   ,"Finish" );
    Button help_button = Create_help_button  (panel      ,"Help"   );
    Append(process      ,bgroup);
    Append(finish       ,bgroup);
    Append(help_button  ,bgroup);
    ///////////////ADDING WIDGETS TO PANEL///////////////////////////
    Append(tbSourceTin       ,vgroup);
    Append(sbTargetTrimeshes ,vgroup);
    Append(cbFallbackColour  ,vgroup);
    
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

                Tin             sourceTin;
                Dynamic_Element targetElements;
                Element         testElement;

                Integer tinRet;
                Integer targetCount;
                Integer targetIndex;

                Integer tinTriCount;
                Integer trimeshTriCount;
                Integer exportedTinTriangles;

                Integer tinTriangleIndex;
                Integer trimeshFaceIndex;
                Integer inside;

                Integer fallbackColour;
                Integer tinColour;
                Integer useColour;

                Integer infoListIndex;
                Integer bulkRet;
                Integer convertRet;

                Integer processedFaces;
                Integer processedMeshes;
                Integer fallbackUsed;
                Integer compatibleMeshes;
                Integer convertFailures;

                Text colourName;
                Text outMsg;

                //validate widgets
                tinRet = Validate(tbSourceTin,CHECK_TIN_MUST_EXIST,sourceTin);
                if(tinRet != TIN_EXISTS)
                {
                    Set_data(cmbMsg,"Source TIN is not valid.");
                    break;
                }

                if(Validate(sbTargetTrimeshes,targetElements) == FALSE)
                {
                    Set_data(cmbMsg,"Target Trimesh source is not valid.");
                    break;
                }

                if(Get_number_of_items(targetElements,targetCount) != 0)
                {
                    Set_data(cmbMsg,"Could not read target source element count.");
                    break;
                }

                if(targetCount < 1)
                {
                    Set_data(cmbMsg,"No target elements found in source selection.");
                    break;
                }

                  if(Validate(cbFallbackColour,fallbackColour) != TRUE)
                {
                    Set_data(cmbMsg,"Fallback colour is not valid.");
                    break;
                }

                if(Tin_number_of_triangles(sourceTin,tinTriCount) != 0)
                {
                    Set_data(cmbMsg,"Could not read TIN triangle count.");
                    break;
                }

                exportedTinTriangles = 0;

                for(tinTriangleIndex = 1; tinTriangleIndex <= tinTriCount; tinTriangleIndex++)
                {
                    if(Tin_get_triangle_inside(sourceTin,tinTriangleIndex,inside) != 0) continue;
                    
                    if(inside == 1) continue;

                    exportedTinTriangles++;
                }

                if(exportedTinTriangles < 1)
                {
                    Set_data(cmbMsg,"No exported TIN triangles found.");
                    break;
                }

                compatibleMeshes = 0;

                for(targetIndex = 1; targetIndex <= targetCount; targetIndex++)
                {
                    if(Get_item(targetElements,targetIndex,testElement) != 0) continue;

                    if(Is_trimesh(testElement) != 1) continue;

                    if(Trimesh_number_of_triangles(testElement,trimeshTriCount) != 0) continue;

                    if(trimeshTriCount == exportedTinTriangles)
                    {
                        compatibleMeshes++;
                    }
                }

                if(compatibleMeshes < 1)
                {
                    outMsg = "No compatible Trimesh found. Exported TIN triangles = ";
                    outMsg = outMsg + To_text(exportedTinTriangles);
                    Set_data(cmbMsg,outMsg);
                    break;
                }

                //do calc
                processedFaces  = 0;
                processedMeshes = 0;
                fallbackUsed    = 0;
                convertFailures = 0;

                for(targetIndex = 1; targetIndex <= targetCount; targetIndex++)
                {
                    if(Get_item(targetElements,targetIndex,testElement) != 0) continue;
                    if(Is_trimesh(testElement) != 1) continue;

                    if(Trimesh_number_of_triangles(testElement,trimeshTriCount) != 0) continue;
                    if(trimeshTriCount != exportedTinTriangles) continue;

                    Dynamic_Integer infoColours;
                    Dynamic_Text    infoNames;
                    Dynamic_Integer faceFlags;
                    Dynamic_Element convertList;

                    trimeshFaceIndex = 0;
                    infoListIndex    = 0;

                    for(tinTriangleIndex = 1; tinTriangleIndex <= tinTriCount; tinTriangleIndex++)
                    {
                        if(Tin_get_triangle_inside(sourceTin,tinTriangleIndex,inside) != 0) continue;

                        if(inside == 1) continue;

                        trimeshFaceIndex++;

                        if(trimeshFaceIndex > trimeshTriCount) break;

                        if(Tin_get_triangle_colour(sourceTin,tinTriangleIndex,tinColour) != 0)
                        {
                            tinColour = 0;
                        }

                        useColour = tinColour;

                        if(useColour == 0)
                        {
                            useColour = fallbackColour;
                            fallbackUsed++;
                        }

                        infoListIndex++;

                        colourName = "TIN triangle ";
                        colourName = colourName + To_text(tinTriangleIndex);

                        Append(useColour,infoColours);

                        Append(colourName,infoNames);

                        // faceFlags item number = Trimesh face number
                        // faceFlags value       = index into infoColours/infoNames
                        Append(infoListIndex,faceFlags);
                    }

                    if(trimeshFaceIndex != trimeshTriCount)
                    {
                        outMsg = "Face flag count mismatch. Flags = ";
                        outMsg = outMsg + To_text(trimeshFaceIndex);
                        outMsg = outMsg + ", Trimesh faces = ";
                        outMsg = outMsg + To_text(trimeshTriCount);
                        Set_data(cmbMsg,outMsg);
                        break;
                    }

                    bulkRet = Trimesh_set_face_infos_flags(testElement,infoColours,infoNames,faceFlags);

                    if(bulkRet != 0)
                    {
                        outMsg = "Trimesh_set_face_infos_flags failed. Return = ";
                        outMsg = outMsg + To_text(bulkRet);
                        Set_data(cmbMsg,outMsg);
                        break;
                    }

                    Append(testElement,convertList);

                    convertRet = Convert_named_faces_to_polymesh(convertList);

                    if(convertRet != 0)
                    {
                        convertFailures++;
                    }

                    Calc_extent(testElement);

                    Element_draw(testElement);

                    processedMeshes++;
                    processedFaces = processedFaces + trimeshFaceIndex;
                }

                outMsg = "Colour transfer finished. Trimeshes processed = ";
                outMsg = outMsg + To_text(processedMeshes);
                outMsg = outMsg + ", faces updated = ";
                outMsg = outMsg + To_text(processedFaces);
                outMsg = outMsg + ", fallback colour used = ";
                outMsg = outMsg + To_text(fallbackUsed);

                if(convertFailures > 0)
                {
                    outMsg = outMsg + ", polymesh convert failures = ";
                    outMsg = outMsg + To_text(convertFailures);
                }

                Set_data(cmbMsg,outMsg);
            }
        }
        break;
        default :
        {
            if(cmd == "Finish")doit = 0;
        }
        break; 
        }
    }
}
void main(){

    // do some checks before you go to the main panel


    mainPanel();
}
