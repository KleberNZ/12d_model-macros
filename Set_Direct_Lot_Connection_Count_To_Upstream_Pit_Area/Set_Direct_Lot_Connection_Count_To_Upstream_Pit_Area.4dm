
/*---------------------------------------------------------------------
**   Programmer:           Kleber Lessa do Prado
**   Date:                 23/09/2026
**   12D Model:            V15
**   Version:              001
**   Macro Name:           Set_Direct_Lot_Connection_Count_To_Upstream_Pit_Area
**   Type:                 SOURCE
**
**   Brief description:
**   Counts direct lot connections attached to each drainage pipe and
**   stores the count in the upstream pit Real attribute "area".
**
**---------------------------------------------------------------------
**   Description:
**
**   Reads drainage strings from a Source_Box and lot connections from
**   a user-selected model.
**
**   A valid lot connection must be a Super string containing exactly
**   two vertices:
**
**      Vertex 1 = located within the allotment
**      Vertex 2 = drainage attachment point
**
**   During processing each drainage pipe is assessed independently.
**
**   A lot connection is counted when Vertex 2:
**
**      - intersects the upstream pit of the current pipe, or
**      - intersects the pipe itself.
**
**   A lot connection located at the downstream pit is ignored during
**   the current pipe loop to prevent double counting. The same node
**   will be counted when processing the downstream pipe where that
**   node becomes the upstream pit.
**
**   The count is reset for every pipe.
**
**      area = number of direct lot connections
**
**   The resulting count is written to the upstream pit Real attribute:
**
**      "area"
**
**   If no lot connections are found the area attribute is set to 0.
**
**   Typical use:
**
**      Watercare wastewater flow estimation where:
**
**      Q = Lots × 0.000041875 m³/s
**
**      and:
**
**      Lots = area attribute value
**
**------------------------------------------------------------**
**  This macro may be reproduced, modified and used without
**  restriction.
**
**  The author grants all users Unlimited Use of the source code
**  and any associated files, for no fee. Unlimited Use includes
**  compiling, running and modifying the code for individual or
**  integrated purposes.
**
**  The author also grants 12d Solutions Pty Ltd and other users
**  permission to incorporate this macro, in whole or in part,
**  into other macros or programs.
**
**---------------------------------------------------------------------
*/

#define DEBUG_FILE 0
#define ECHO_DEBUG_FILE 0
#define ECHO_LINE_NO 0
#define BUILD "15.0.002"

#include "standard_library.h"
#include "size_of.h"
#include "set_ups.h"

/*global variables*/{
}

Real Point_distance_2d(Real x1,Real y1,Real x2,Real y2)
{
    Real dx=x2-x1;
    Real dy=y2-y1;
    return Sqrt(dx*dx+dy*dy);
}

// Tests the pipe geometry but deliberately excludes the downstream pit.
Integer Point_near_pipe_excluding_ds_pit_2d(
    Real ax,Real ay,Real bx,Real by,
    Real dsx,Real dsy,
    Real px,Real py,Real tolerance)
{
    if(Point_distance_2d(px,py,dsx,dsy)<=tolerance) return 0;

    Real vx=bx-ax;
    Real vy=by-ay;
    Real wx=px-ax;
    Real wy=py-ay;
    Real vv=vx*vx+vy*vy;
    if(vv<=0.0) return 0;

    Real t=(wx*vx+wy*vy)/vv;
    if(t<0.0)t=0.0;
    if(t>1.0)t=1.0;

    Real cx=ax+t*vx;
    Real cy=ay+t*vy;
    return Point_distance_2d(cx,cy,px,py)<=tolerance;
}

Integer Get_lot_connection_endpoint(Element lc,Real &x,Real &y,Real &z)
{
    Text type="";
    if(Get_type(lc,type)!=0 || type!="Super") return 0;

    Integer points=0;
    if(Get_points(lc,points)!=0 || points!=2) return 0;
    if(Get_super_vertex_coord(lc,2,x,y,z)!=0) return 0;
    return 1;
}

Integer Count_direct_connections(
    Dynamic_Element &connections,
    Integer connection_count,
    Segment pipe,
    Real usx,Real usy,
    Real dsx,Real dsy,
    Real tolerance)
{
    Point pipe_start;
    Point pipe_end;
    if(Get_start(pipe,pipe_start)!=0) return 0;
    if(Get_end(pipe,pipe_end)!=0) return 0;

    Real ax=Get_x(pipe_start);
    Real ay=Get_y(pipe_start);
    Real bx=Get_x(pipe_end);
    Real by=Get_y(pipe_end);

    Integer count=0;
    Integer i=0;
    for(i=1;i<=connection_count;i++)
    {
        Element lc;
        if(Get_item(connections,i,lc)!=0) continue;

        Real x=0.0,y=0.0,z=0.0;
        if(Get_lot_connection_endpoint(lc,x,y,z)==0) continue;

        // A connection at the upstream pit belongs to this pipe.
        if(Point_distance_2d(x,y,usx,usy)<=tolerance)
        {
            count++;
            continue;
        }

        // A connection at the downstream pit is excluded here. It will be
        // counted by the downstream pipe, where the node is its upstream pit.
        if(Point_near_pipe_excluding_ds_pit_2d(
            ax,ay,bx,by,dsx,dsy,x,y,tolerance))
        {
            count++;
        }
    }
    return count;
}

Integer Process_drainage_string(
    Element drainage,
    Dynamic_Element &connections,
    Integer connection_count,
    Real tolerance,
    Integer &pits_written,
    Integer &connections_counted)
{
    Text type="";
    if(Get_type(drainage,type)!=0 || type!="Drainage") return 0;

    Integer flow=0;
    Integer segment_count=0;
    Integer pit_count=0;
    if(Get_drainage_flow(drainage,flow)!=0) return 0;
    if(Get_segments(drainage,segment_count)!=0 || segment_count<1) return 0;
    if(Get_drainage_pits(drainage,pit_count)!=0 || pit_count<2) return 0;
    if(flow!=0 && flow!=1) return 0;

    Integer pipe_index=1;
    for(pipe_index=1;pipe_index<=segment_count;pipe_index++)
    {
        Integer us_pit=pipe_index;
        Integer ds_pit=pipe_index+1;
        if(flow==0)
        {
            us_pit=pipe_index+1;
            ds_pit=pipe_index;
        }

        Segment pipe;
        if(Get_segment(drainage,pipe_index,pipe)!=0) continue;

        Real usx=0.0,usy=0.0,usz=0.0;
        Real dsx=0.0,dsy=0.0,dsz=0.0;
        if(Get_drainage_pit(drainage,us_pit,usx,usy,usz)!=0) continue;
        if(Get_drainage_pit(drainage,ds_pit,dsx,dsy,dsz)!=0) continue;

        // This value resets for every pipe.
        Integer direct_count=Count_direct_connections(
            connections,connection_count,pipe,
            usx,usy,dsx,dsy,tolerance);

        connections_counted=connections_counted+direct_count;
        Real area_value=direct_count;

        Integer rc=Set_drainage_pit_attribute_by_type(
            drainage,us_pit,"area",area_value);

        if(rc==0)
        {
            pits_written++;
        }
        else
        {
            Text pit_name="<pit name unavailable>";
            Get_drainage_pit_name(drainage,us_pit,pit_name);
            Print("WARNING: Failed to set area on pit "+pit_name+
                  ". Return: "+To_text(rc)+"\n");
        }
    }
    return 1;
}

void mainPanel()
{
    Text panelName="Direct Lot Connections to Upstream Pit Area";
    Panel panel=Create_panel(panelName,TRUE);
    Vertical_Group vgroup=Create_vertical_group(-1);
    Colour_Message_Box cmbMsg=Create_colour_message_box("");

    Source_Box Source_box=Create_source_box(" of drainage strings",cmbMsg,0);
    Model_Box Model_box=Create_model_box("Lot connection model",cmbMsg,CHECK_MODEL_MUST_EXIST);
    Real_Box rb_tolerance=Create_real_box("Intersection tolerance",cmbMsg);
    Set_data(rb_tolerance,0.01);

    Horizontal_Group bgroup=Create_button_group();
    Button process=Create_button("&Process","process");
    Button finish=Create_finish_button("Finish","Finish");
    Button help_button=Create_help_button(panel,"Help");
    Append(process,bgroup);
    Append(finish,bgroup);
    Append(help_button,bgroup);

    Append(Source_box,vgroup);
    Append(Model_box,vgroup);
    Append(rb_tolerance,vgroup);
    Append(cmbMsg,vgroup);
    Append(bgroup,vgroup);
    Append(vgroup,panel);
    Show_widget(panel);

    Integer doit=1;
    while(doit)
    {
        Text cmd="",msg="";
        Integer id,ret=Wait_on_widgets(id,cmd,msg);
        switch(cmd)
        {
        case "keystroke":
        case "set_focus":
        case "kill_focus": {continue;} break;
        case "CodeShutdown": {Set_exit_code(cmd);} break;
        }

        switch(id)
        {
        case Get_id(panel):
        {
            if(cmd=="Panel Quit")doit=0;
            if(cmd=="Panel About")about_panel(panel);
        }
        break;

        case Get_id(process):
        {
            if(cmd=="process")
            {
                Dynamic_Element drainage_strings;
                if(Validate(Source_box,drainage_strings)!=1)
                {
                    Set_data(cmbMsg,"Select at least one drainage string.",2);
                    Null(drainage_strings);
                    continue;
                }

                Integer drainage_count=0;
                Get_number_of_items(drainage_strings,drainage_count);
                if(drainage_count<1)
                {
                    Set_data(cmbMsg,"Select at least one drainage string.",2);
                    Null(drainage_strings);
                    continue;
                }

                Model connection_model;
                if(Validate(Model_box,CHECK_MODEL_MUST_EXIST,connection_model)
                    !=MODEL_EXISTS)
                {
                    Set_data(cmbMsg,"Select an existing lot connection model.",2);
                    Null(drainage_strings);
                    Null(connection_model);
                    continue;
                }

                Real tolerance=0.0;
                if(Validate(rb_tolerance,tolerance)!=1 || tolerance<0.0)
                {
                    Set_data(cmbMsg,"Intersection tolerance must be zero or greater.",2);
                    Null(drainage_strings);
                    Null(connection_model);
                    continue;
                }

                Dynamic_Element connections;
                Integer connection_count=0;
                if(Get_elements(connection_model,connections,connection_count)!=0)
                {
                    Set_data(cmbMsg,"Unable to read the lot connection model.",2);
                    Null(drainage_strings);
                    Null(connection_model);
                    Null(connections);
                    continue;
                }

                Integer drainage_processed=0;
                Integer pits_written=0;
                Integer connections_counted=0;
                Integer i=0;
                for(i=1;i<=drainage_count;i++)
                {
                    Element drainage;
                    if(Get_item(drainage_strings,i,drainage)!=0)continue;
                    drainage_processed=drainage_processed+
                        Process_drainage_string(
                            drainage,connections,connection_count,tolerance,
                            pits_written,connections_counted);
                }

                Set_data(cmbMsg,
                    "Finished. Drainage strings: "+To_text(drainage_processed)+
                    ", upstream pits updated: "+To_text(pits_written)+
                    ", direct connections counted: "+To_text(connections_counted));

                Null(connections);
                Null(connection_model);
                Null(drainage_strings);
            }
        }
        break;

        default:
        {
            if(cmd=="Finish")doit=0;
        }
        break;
        }
    }
}

void main()
{
    mainPanel();
}
