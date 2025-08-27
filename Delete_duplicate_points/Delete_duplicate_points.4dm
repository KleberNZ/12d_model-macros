/*---------------------------------------------------------------------
**   Programmer:Kleber Lessa
**   Date:22/08/25             
**   12D Model:            V15
**   Version:              001
**   Macro Name:           Delete_duplicate_points.4dm
**   Type:                 SOURCE
**
**   Brief description: BriefDescription
**
**
**---------------------------------------------------------------------
**   Description: Finds and moves duplicate single-vertex points to a target model.
**                 Includes two modes: (A) only points that duplicate vertices on lines,
**                 and (B) a broader check against all points and all line vertices (supports chaining).
**
**
**---------------------------------------------------------------------
**   Update/Modification
**
**
**   (C) Copyright 2013-2025 by your_company Pty Ltd. All Rights
**       Reserved.
**   This macro, or parts thereof, may not be reproduced in any form
**   without permission of your_company.
**---------------------------------------------------------------------
*/
#define DEBUG_FILE      0
#define ECHO_DEBUG_FILE 0
#define ECHO_LINE_NO    0
 
#define BUILD "1.0.001"
 
// ----------------------------- INCLUDES -----------------------------
#include "..\\..\\include\standard_library.H"
#include "..\\..\\include\size_of.H"
/*global variables*/{


}

void mainPanel(){
 
    Text panelName="PanelName";
    Panel              panel  = Create_panel              (panelName,TRUE);
    Vertical_Group     vgroup = Create_vertical_group     (-1         );
    Colour_Message_Box cmbMsg = Create_colour_message_box (""         );

    ///////////////////CREATE INPUT WIDGETS////////////////
    //TODO: create some input fields
    
    ///////////////ADDING BUTTONS ALONG THE BOTTOM///////////////////////////
    Horizontal_Group bgroup = Create_button_group();
    Button process     = Create_button       ("&Process" ,"process");
    Button finish      = Create_finish_button("Finish"   ,"Finish" );
    Button help_button = Create_help_button  (panel      ,"Help"   );
    Append(process      ,bgroup);
    Append(finish       ,bgroup);
    Append(help_button  ,bgroup);
    ///////////////ADDING WIDGETS TO PANEL///////////////////////////
    //TODO: add your widgets to vgroup

    //Append(widget1    ,vgroup);
    //Append(widget2    ,vgroup);


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
                //TODO: declare your widget variables



                //TODO: validate widgets




                //TODO: do calc




                Set_data(cmbMsg ,"Process finished");
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
#define DEBUG_FILE      0
#define ECHO_DEBUG_FILE 0 
#define ECHO_LINE_NO    0

// ----------------------------- INCLUDES -----------------------------
#include "..\\..\\include\\standard_library.H"
#include "..\\..\\include\\size_of.H"
#include "..\\..\\include\\QSort.h"

/*global variables*/
Real get_length( Real x1 , Real x2, Real y1, Real y2 )
{
    Real distance;
    Real a = y2-y1;
    Real b = x2-x1;
    Real Sa = a * a;
    Real Sb = b * b;
    distance = Sqrt( Sa + Sb  );
    return (distance);
}

Element create_super_circle(Real xd,Real yd, Real rad )
// --------------------------------------------------------------------
// --------------------------------------------------------------------
{
    Real half = rad;
    Integer size = 4;
    Integer flags = String_Super_Bit(ZCoord_Array) | String_Super_Bit(Colour_Array) | String_Super_Bit(Radius_Array);
    Element super = Create_super(flags,size);

    Set_colour   (super,7);
    Set_style    (super,"1");
    Set_breakline(super,1);

    Set_super_vertex_coord (  super,1,xd        ,yd + half  ,0);
    Set_super_vertex_coord (  super,2,xd + half ,yd         ,0);
    Set_super_vertex_coord (  super,3,xd        ,yd - half  ,0);
    Set_super_vertex_coord (  super,4,xd - half ,yd         ,0);

    Set_super_segment_radius( super, 1,half);
    Set_super_segment_radius( super, 2,half);
    Set_super_segment_radius( super, 3,half);
    String_close ( super );
    Set_super_segment_radius( super, 4,half);

    Calc_extent   (  super);
    return(super);
}

Element create_super_point(Real x,Real y, Real z, Attributes atts,Text name, Real chain, Integer colour, Text point_number,
                           Text symbol_name,Integer sym_col, Real sym_rot,Real sym_size ,Text style   )
// --------------------------------------------------------------------
// --------------------------------------------------------------------
{
    Integer size = 1;
    Integer flags = String_Super_Bit(ZCoord_Array) | String_Super_Bit(Colour_Array) | String_Super_Bit(Vertex_Attribute_Array) | String_Super_Bit(Symbol_Array);
    Element super = Create_super(flags,size);

    Set_colour   (super,colour);
    Set_style    (super,style);

    Set_super_vertex_coord (  super,1,x,y,z);
    Set_super_vertex_attributes(super,1,atts  );
    Set_name(super,name  );
    Set_chainage(super,chain);

    Set_super_vertex_point_number( super,1,point_number);
    Set_super_vertex_symbol_style( super,1,symbol_name);
    Set_super_vertex_symbol_rotation( super,1,sym_rot);
    Set_super_vertex_symbol_size(     super,1,sym_size);
    Set_super_vertex_symbol_colour(   super,1,sym_col);

    Calc_extent   (  super);
    return(super);
}

Integer move_vertex_to_model(Element &elemnt,Integer i,  Model &extr_model  )
{
    Integer no_points=0;
    Get_points(elemnt , no_points);
    if ( no_points == 1 )
    {
        Set_model(elemnt,extr_model);
    }
    else
    {
        Attributes atts;
        Get_super_vertex_attributes(elemnt,i,atts  );
        Real x,y,z;
        Get_data(elemnt,i,x,y,z);
        Text name;
        Get_name(elemnt,name  );
        Real xf,yf,zf,chain,dir,off;
        Drop_point( elemnt,x,y,z,xf,yf,zf,chain,dir,off   );
        Integer colour;
        Get_colour(elemnt,colour);

        Text style;
        Get_style(elemnt,style);

        Text point_number="",symbol_name="";

        Get_super_vertex_point_number(elemnt,i,point_number);
        Get_super_vertex_symbol_style(elemnt,i,symbol_name);

        Real sym_rot,sym_size;
        Integer sym_col;
        Get_super_vertex_symbol_rotation( elemnt,i,sym_rot);
        Get_super_vertex_symbol_size(     elemnt,i,sym_size);
        Get_super_vertex_symbol_colour(   elemnt,i,sym_col);

        Element super =  create_super_point(  x,  y,   z,   atts,  name,   chain,   colour,   point_number,
                                              symbol_name,  sym_col,   sym_rot,  sym_size ,  style   );
        Set_model(super,extr_model);
        Calc_extent(super);
        Calc_extent(extr_model);

        Super_remove_vertex( elemnt,i,1);
        Calc_extent(elemnt);
    }
    return(0);
}

Integer has_duplicate(Dynamic_Element elements , Real x1, Real y1, Real tol  )
{
    Integer  counting=0;

    Element fence_list = create_super_circle(  x1,  y1, 0.15 );

    Dynamic_Element  ret_inside,   ret_outside;
    Fence(elements,0, fence_list, ret_inside,  ret_outside)  ;
    Integer num_of_strings;
    Get_number_of_items(ret_inside,num_of_strings);

    for (Integer s=1; s<=num_of_strings; s++)
    {
        Element string;
        Get_item(ret_inside,s,string);
        Integer no_vertx;
        Get_points(string, no_vertx);

        for( Integer v=1; v<=no_vertx; v++)
        {
            Real  x2,y2,z2;
            Get_data(string,v,  x2,y2,z2);
            Real dist = get_length(   x1 ,   x2,   y1,   y2 );
            if ( Xley(dist,tol ) == 1 )
            {
                counting += 1;
            }
        }
    }
    return(counting);
}

Integer get_sorted_elements (Dynamic_Integer  &countpoints,  Dynamic_Element orelts, Integer index[]    )
{
    Integer         no_items;
    Get_number_of_items(orelts,no_items);

    for(Integer i=1; i<=no_items; i++)
    {
        Element  eitem;
        Get_item(orelts,i,eitem);
        Integer no_points=0;
        Get_points(eitem,no_points);
        Append( no_points, countpoints);
    }

    Qsort(countpoints,index,no_items);

    return(0);
}

void manage_a_panel()
// ----------------------------------------------------------
// ----------------------------------------------------------
{
    // create the panel
    Integer no_arg = Get_number_of_command_arguments();

    Integer mode=0;
    Text modename="panel";
    Text types="eek";
    Text view_name="";
    Text model_name="";
    Text do_2d3d="2d";
    Text output_name="";

    for (Integer r=1; r<=no_arg; r++)
    {
        Text argument;
        Get_command_argument(r, argument);
        if ( Match_name(Text_lower(argument),"mode_*") != 0 )
        {
            modename = Get_subtext(argument,6,Text_length(argument));
        }
        else if ( Match_name(Text_lower(argument),"name_*") != 0 )
        {
            types = Get_subtext(argument,6,Text_length(argument));
        }
        else if ( Match_name(Text_lower(argument),"type_*") != 0 )
        {
            do_2d3d = Get_subtext(argument,6,Text_length(argument));
        }
        else if ( Match_name(Text_lower(argument),"save_*") != 0 )
        {
            output_name = Get_subtext(argument,6,Text_length(argument));
        }
    }
    
    if ( Text_lower(modename) == "view" )
    {
        mode=1;
        view_name=types;
    }
    else if ( Text_lower(modename) == "model" )
    {
        mode=2;
        model_name=types;
    }

    Panel          panel   = Create_panel("Delete Duplicate Points",TRUE);
    Vertical_Group VGROUP  = Create_vertical_group(-1);
    Colour_Message_Box    message = Create_colour_message_box("    ");

    Source_Box  source_box = Create_source_box(" Source",message,0);
    Append(source_box ,VGROUP);

    // -------------------------------------------------------------------------

    Vertical_Group vgr  = Create_vertical_group(-1);
    Set_border(vgr,"Options");

    Named_Tick_Box idntext_box = Create_named_tick_box("do 3d XYZ comparison",1,"identical xy");
    Append(idntext_box,vgr);

    Named_Tick_Box idncoords_box = Create_named_tick_box("do 2D comparison",0,"identical z");
    Append(idncoords_box,vgr);

    Model_Box Mod_boxpts1 = Create_model_box("Model for duplicates",message,CHECK_MODEL_CREATE);
    Append(Mod_boxpts1,vgr);

    Append(vgr,VGROUP);

    // buttons along the bottom
    Horizontal_Group bgroup = Create_button_group();
    Button process = Create_button("&Move","count");
    Button finish  = Create_button("&Finish" ,"finish");

    Append(process,bgroup);
    Append(finish ,bgroup);

    Append(message ,VGROUP);
    Append(bgroup,VGROUP );
    Append(VGROUP ,panel);

    Set_data(message, "There is NO UNDO for this macro !!!!!" );

    // validate and process data
    if ( mode != 0 )
    {
        Print( "There is NO UNDO for this macro !!!!!" );
        Print();
        Dynamic_Element      orelts ;
        Integer         no_items;
        Integer no_models;

        Text timen;
        //Get_time_text(timen);
        Print("start time:\n");
        //Print(timen);
        Print("\n");
        
        if ( mode == 2 )
        {
            no_models = 1;
            Model modin = Get_model_create(  model_name);
            Dynamic_Element copy_elts;
            Null(copy_elts);

            Get_elements(  modin,copy_elts,  no_items);
            Append(   copy_elts, orelts);
        }
        else if ( mode == 1 )
        {
            Dynamic_Element copy_elts;
            Null(copy_elts);

            View view = Get_view(  view_name);
            Dynamic_Text  model_names;
            View_get_models(  view,  model_names);
            Get_number_of_items(model_names,no_models);

            for(Integer m=1; m<=no_models; m++)
            {
                Null(copy_elts);
                Text  em;
                Get_item(model_names,m,em);

                Model modin = Get_model_create(  em);
                Get_elements(  modin,copy_elts,  no_items);
                Append(   copy_elts, orelts);
            }
        }

        Get_number_of_items(orelts,no_items);
        Model model = Get_model_create(  output_name);

        Integer tickcoor ,tickz;
        if (   Text_lower(do_2d3d) == "2d" )
        {
            tickcoor =0;
            tickz = 1;
        }
        else
        {
            tickcoor =1;
            tickz = 0;
        }

        // --------------------------------------------------------
        // --------------------------------------------------------

        Integer counttxt = 0;

        Dynamic_Integer  countpoints;

        Integer index[no_items+10];
        get_sorted_elements (   countpoints,    orelts,   index    );

        for(Integer k=1; k<=no_items; k++)
        {
            Integer i = index[k];

            Element  eitem;
            Get_item(orelts,i,eitem);

            Text type;
            Get_type(eitem,type);
            if ( Text_lower(type) != "super")
            {
                continue;
            }
            Integer no_points;
            Get_points(eitem,no_points);

            for ( Integer p=no_points; p>=1; p--)
            {
                Real  orgx,orgy,orgz;
                Get_data(eitem,p,orgx,orgy,orgz);

                Integer has_dups = has_duplicate(  orelts , orgx, orgy,   0.0001  );

                if (has_dups < 2 )
                {
                    continue;
                }
                Integer moveme = 0;

                for(Integer h=k+1; h<=no_items; h++)
                {
                    Integer j = index[h];

                    if ( moveme > 0 )
                    {
                        break;
                    }
                    Element  compitem;
                    Get_item(orelts,j,compitem);
                    Integer cheh=0;
                    Get_points(compitem,cheh);

                    for( Integer v=1; v<=cheh; v++)
                    {
                        if ( moveme > 0 )
                        {
                            break;
                        }
                        Real  comx,comy,comz;
                        Get_data(compitem,v,comx,comy,comz);

                        if( tickcoor == 1 )
                        {
                            if ( Xeqy(orgx,comx,1.0e-4) == 1 && Xeqy(orgy,comy,1.0e-4) == 1 && Xeqy(orgz,comz,1.0e-4) == 1  )
                            {
                                moveme = 1;
                                ++counttxt;
                                move_vertex_to_model(eitem,p,  model  );
                                break;
                            }
                        }
                        else if( tickz == 1 )
                        {
                            if ( Xeqy(orgx,comx,1.0e-4) == 1 && Xeqy(orgy,comy,1.0e-4) == 1 )
                            {
                                moveme = 1;
                                ++counttxt;
                                move_vertex_to_model(eitem,p,  model  );
                                break;
                            }
                        }
                    }
                }
            }
        }  //for integer i

        Null(orelts);

        Print( "Done . . . Moved: " + To_text(counttxt) + " Strings from " + To_text(no_models) + " models." );

        Print();
        //Get_time_text(timen);
        Print("finish time:\n");
        //Print(timen);
        Print("\n");
    }
    else
    {
        Show_widget(panel);

        Integer doit = 1;

        while(doit)
        {
            Integer id;
            Text    cmd;
            Text    msg;
            Integer ret = Wait_on_widgets(id,cmd,msg);

            if(cmd == "keystroke") continue;

            switch(id)
            {
                case Get_id(panel) :
                {
                    if(cmd == "Panel Quit") doit = 0;
                }
                break;

                case Get_id(finish) :
                {
                    if(cmd == "finish") doit = 0;
                }
                break;

                case Get_id(idncoords_box) :
                {
                    Set_data(idncoords_box,"1");
                    Set_data(idntext_box,"0");
                }
                break;
                
                case Get_id(idntext_box) :
                {
                    Set_data(idncoords_box,"0");
                    Set_data(idntext_box,"1");
                }
                break;

                case Get_id(process) :
                {
                    Text timen;
                    //Get_time_text(timen);
                    Print("start time:\n");
                    //Print(timen);
                    Print("\n");

                    Integer tickcoor ,tickz;

                    Validate(idncoords_box,tickcoor);
                    Validate(idntext_box,tickz);

                    // --------------------------------------------------------
                    // --------------------------------------------------------

                    Dynamic_Element      orelts;

                    Integer ierr = Validate(source_box,orelts);
                    if(ierr != TRUE)
                    {
                        Set_data(message,"Invalid Source points");
                        break;
                    }
                    Model model;

                    ierr = Validate(Mod_boxpts1,GET_MODEL_CREATE,model);
                    if(ierr != MODEL_EXISTS) break;

                    Integer         no_items;
                    Get_number_of_items(orelts,no_items);

                    Integer counttxt = 0;

                    Dynamic_Integer  countpoints;

                    Integer index[no_items+10];
                    get_sorted_elements (   countpoints,    orelts,   index    );

                    for(Integer k=1; k<=no_items; k++)
                    {
                        Integer i = index[k];

                        Element  eitem;
                        Get_item(orelts,i,eitem);

                        Text type;
                        Get_type(eitem,type);
                        if ( Text_lower(type) != "super")
                        {
                            continue;
                        }
                        Integer no_points;
                        Get_points(eitem,no_points);

                        for ( Integer p=no_points; p>=1; p--)
                        {
                            Real  orgx,orgy,orgz;
                            Get_data(eitem,p,orgx,orgy,orgz);

                            Integer has_dups = has_duplicate(  orelts , orgx, orgy,   0.0001  );

                            if (has_dups < 2 )
                            {
                                continue;
                            }
                            Integer moveme = 0;

                            for(Integer h=k+1; h<=no_items; h++)
                            {
                                Integer j = index[h];

                                if ( moveme > 0 )
                                {
                                    break;
                                }
                                Element  compitem;
                                Get_item(orelts,j,compitem);
                                Integer cheh=0;
                                Get_points(compitem,cheh);

                                for( Integer v=1; v<=cheh; v++)
                                {
                                    if ( moveme > 0 )
                                    {
                                        break;
                                    }
                                    Real  comx,comy,comz;
                                    Get_data(compitem,v,comx,comy,comz);

                                    if( tickcoor == 1 )
                                    {
                                        if ( Xeqy(orgx,comx,1.0e-4) == 1 && Xeqy(orgy,comy,1.0e-4) == 1 && Xeqy(orgz,comz,1.0e-4) == 1  )
                                        {
                                            moveme = 1;
                                            ++counttxt;
                                            move_vertex_to_model(eitem,p,  model  );
                                            break;
                                        }
                                    }
                                    else if( tickz == 1 )
                                    {
                                        if ( Xeqy(orgx,comx,1.0e-4) == 1 && Xeqy(orgy,comy,1.0e-4) == 1 )
                                        {
                                            moveme = 1;
                                            ++counttxt;
                                            move_vertex_to_model(eitem,p,  model  );
                                            break;
                                        }
                                    }
                                }
                            }
                        }
                    }  //for integer i

                    Null(orelts);

                    Print( "Done . . . Moved: " + To_text(counttxt) + " Strings.");

                    Print();
                    //Get_time_text(timen);
                    Print("finish time:\n");
                    //Print(timen);
                    Print("\n");
                }
                break;
            }
        }
    }
}
