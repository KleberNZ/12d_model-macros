/*---------------------------------------------------------------------
** Programmer: Kleber Lessa do Prado
** Date: 28/09/2026
** 12D Model: V15+
** Version: 0.3.000
** Macro Name: Dissolve_Adjacent_Polygons_Dynamic_Graph.4dm
** Type: SOURCE
**
** Brief Description:
** Dissolves adjacent closed Super-string polygons using canonical
** graph-based noding and shared-edge cancellation.
**
**---------------------------------------------------------------------
**
** Description:
**
** This macro:
**
** - Validates all selected closed Super strings.
** - Builds a canonical node registry from polygon boundaries.
** - Detects native line/arc intersections.
** - Virtually nodes and splits boundaries using dynamic containers.
** - Constructs a topology graph from the noded edge network.
** - Removes duplicated internal boundaries.
** - Traces the remaining exterior boundary.
** - Creates one dissolved Super string per connected component.
**
** Supported Geometry:
**
** - Closed Super strings
** - Straight segments
** - Circular arc segments
** - Multi-polygon connected coverages
**
** Limitations:
**
** - XY controls topology.
** - Holes are not supported.
** - Containment-only unions are not supported.
** - Arbitrary polygon overlap is not supported.
**
**---------------------------------------------------------------------
**
** This macro may be reproduced, modified and used without restriction.
**
** The author grants all users Unlimited Use of the source code and any
** associated files, for no fee.
**
** Unlimited Use includes compiling, running and modifying the code
** for individual or integrated purposes.
**
** The author also grants 12d Solutions Pty Ltd and other users
** permission to incorporate this macro, in whole or in part,
** into other macros or programs.
**
**---------------------------------------------------------------------*/

#define DEBUG_FILE 0
#define ECHO_DEBUG_FILE 0
#define ECHO_LINE_NO 0
#define BUILD "$2.0.003-PROTOTYPE"
#include "standard_library.h"
#include "size_of.h"

/*global variables*/
{
    Real XY_TOL=0.001;
    Real ARC_TOL=0.001;
    Real MIN_PIECE_LENGTH=0.000001;
}

Integer Same_real(Real a,Real b,Real tol){return(Absolute(a-b)<=tol);}
Integer Same_xy(Real ax,Real ay,Real bx,Real by)
{return(Same_real(ax,bx,XY_TOL)&&Same_real(ay,by,XY_TOL));}
Real Normalise_positive_angle(Real angle)
{
    Real two_pi=6.28318530717958647692;
    while(angle<0.0)angle+=two_pi;
    while(angle>=two_pi)angle-=two_pi;
    return(angle);
}
Text Element_label(Element elt,Integer fallback)
{
    Text name="";Get_name(elt,name);
    if(name=="")name="polygon "+To_text(fallback);
    return(name);
}
Integer Endpoint_before(Real ax,Real ay,Real bx,Real by)
{
    if(ax<bx-XY_TOL)return(TRUE);
    if(ax>bx+XY_TOL)return(FALSE);
    return(ay<by-XY_TOL);
}
Integer Find_or_add_node(Dynamic_Real &node_x,Dynamic_Real &node_y,
                         Real x,Real y,Integer &created)
{
    Integer count=0,i=0,best=0;
    Get_number_of_items(node_x,count);
    Real best_d2=XY_TOL*XY_TOL;
    for(i=1;i<=count;i++)
    {
        Real nx=0.0,ny=0.0;
        if(Get_item(node_x,i,nx)!=0||Get_item(node_y,i,ny)!=0)continue;
        Real dx=x-nx,dy=y-ny,d2=dx*dx+dy*dy;
        if(d2<=best_d2){best=i;best_d2=d2;}
    }
    if(best>0){created=FALSE;return(best);}
    count++;
    if(Set_item(node_x,count,x)!=0||Set_item(node_y,count,y)!=0)return(0);
    created=TRUE;
    return(count);
}
Integer Point_on_line_parameter(Real px,Real py,Real ax,Real ay,Real bx,Real by,
                                Real &parameter)
{
    Real vx=bx-ax,vy=by-ay,len2=vx*vx+vy*vy;
    if(len2<=XY_TOL*XY_TOL)return(FALSE);
    parameter=((px-ax)*vx+(py-ay)*vy)/len2;
    Real qx=ax+parameter*vx,qy=ay+parameter*vy;
    Real dx=px-qx,dy=py-qy;
    if(dx*dx+dy*dy>XY_TOL*XY_TOL)return(FALSE);
    Real length=Sqrt(len2),ptol=XY_TOL/length;
    if(parameter<-ptol||parameter>1.0+ptol)return(FALSE);
    if(parameter<0.0)parameter=0.0;
    if(parameter>1.0)parameter=1.0;
    return(TRUE);
}
Integer Arc_node_parameter(Segment segment,Real px,Real py,
                           Real &parameter,Real &signed_radius,Real &sweep)
{
    Arc arc;
    if(Get_arc(segment,arc)!=0)return(FALSE);
    Point centre=Get_centre(arc),start=Get_start(arc),finish=Get_end(arc);
    Real cx=Get_x(centre),cy=Get_y(centre);
    Real sx=Get_x(start),sy=Get_y(start),fx=Get_x(finish),fy=Get_y(finish);
    signed_radius=Get_radius(arc);
    Real radius=Absolute(signed_radius);
    if(radius<=ARC_TOL)return(FALSE);
    Real a0=Atan2(sy-cy,sx-cx),a1=Atan2(fy-cy,fx-cx);
    if(signed_radius>0.0)sweep=Normalise_positive_angle(a0-a1);
    else sweep=Normalise_positive_angle(a1-a0);
    Real dsx=px-sx,dsy=py-sy,dfx=px-fx,dfy=py-fy;
    if(dsx*dsx+dsy*dsy<=XY_TOL*XY_TOL){parameter=0.0;return(TRUE);}
    if(dfx*dfx+dfy*dfy<=XY_TOL*XY_TOL){parameter=1.0;return(TRUE);}
    Real vx=px-cx,vy=py-cy,radial=Sqrt(vx*vx+vy*vy);
    if(Absolute(radial-radius)>ARC_TOL)return(FALSE);
    Real ap=Atan2(py-cy,px-cx),travel=0.0;
    if(signed_radius>0.0)travel=Normalise_positive_angle(a0-ap);
    else travel=Normalise_positive_angle(ap-a0);
    if(sweep<=0.0||travel>sweep+ARC_TOL/radius)return(FALSE);
    parameter=travel/sweep;
    if(parameter<0.0)parameter=0.0;
    if(parameter>1.0)parameter=1.0;
    return(TRUE);
}
Integer UF_find(Integer p,Dynamic_Integer &parent)
{
    Integer root=p,q=p,next=0,value=0;
    Get_item(parent,root,value);
    while(value!=root){root=value;Get_item(parent,root,value);}
    Get_item(parent,q,value);
    while(value!=q)
    {
        next=value;Set_item(parent,q,root);q=next;Get_item(parent,q,value);
    }
    return(root);
}
void UF_union(Integer a,Integer b,Dynamic_Integer &parent)
{
    Integer ra=UF_find(a,parent),rb=UF_find(b,parent);
    if(ra!=rb)Set_item(parent,rb,ra);
}
Integer Same_piece_geometry(Integer kind_a,Real radius_a,Integer major_a,Real cx_a,Real cy_a,
                            Integer kind_b,Real radius_b,Integer major_b,Real cx_b,Real cy_b)
{
    if(kind_a!=kind_b)return(FALSE);
    if(kind_a==1)return(TRUE);
    if(Absolute(Absolute(radius_a)-Absolute(radius_b))>ARC_TOL)return(FALSE);
    if(major_a!=major_b)return(FALSE);
    if(!Same_xy(cx_a,cy_a,cx_b,cy_b))return(FALSE);
    return(TRUE);
}
Integer Find_physical_piece(Real x1,Real y1,Real x2,Real y2,
                            Integer kind,Real radius,Integer major,Real centre_x,Real centre_y,
                            Dynamic_Real &edge_x1,Dynamic_Real &edge_y1,
                            Dynamic_Real &edge_x2,Dynamic_Real &edge_y2,
                            Dynamic_Integer &edge_kind,Dynamic_Real &edge_radius,
                            Dynamic_Integer &edge_major,Dynamic_Real &edge_centre_x,
                            Dynamic_Real &edge_centre_y)
{
    Integer count=0,i=0;Get_number_of_items(edge_x1,count);
    for(i=1;i<=count;i++)
    {
        Real ax=0.0,ay=0.0,bx=0.0,by=0.0,ar=0.0,acx=0.0,acy=0.0;
        Integer ak=0,am=0;
        Get_item(edge_x1,i,ax);Get_item(edge_y1,i,ay);
        Get_item(edge_x2,i,bx);Get_item(edge_y2,i,by);
        if(!Same_xy(x1,y1,ax,ay)||!Same_xy(x2,y2,bx,by))continue;
        Get_item(edge_kind,i,ak);Get_item(edge_radius,i,ar);Get_item(edge_major,i,am);
        Get_item(edge_centre_x,i,acx);Get_item(edge_centre_y,i,acy);
        if(Same_piece_geometry(kind,radius,major,centre_x,centre_y,
                               ak,ar,am,acx,acy)==TRUE)return(i);
    }
    return(0);
}
void Cleanup_results(Dynamic_Element &results)
{
    Integer count=0,i=0;Get_number_of_items(results,count);
    for(i=1;i<=count;i++){Element e;if(Get_item(results,i,e)==0&&Element_exists(e)!=0)Element_delete(e);}
}
Integer Process_dissolve(Dynamic_Element &polygons,Model output_model,
                         Integer delete_originals,Text &status_message)
{
    Integer polygon_count=0;
    if(Get_number_of_items(polygons,polygon_count)!=0||polygon_count<1)
    {status_message="No source polygons were found.";return(FALSE);}

    Dynamic_Integer parent;
    Dynamic_Real node_x,node_y;
    Integer i=0,j=0,created=FALSE;

    /* Stage 1: validate polygons and register all original component endpoints. */
    for(i=1;i<=polygon_count;i++)
    {
        Element polygon;Text type="";Integer closed=FALSE,selfx=FALSE;
        Integer use_holes=FALSE,hole_count=0,segment_count=0;
        if(Get_item(polygons,i,polygon)!=0)
        {status_message="Could not retrieve a selected polygon.";return(FALSE);}
        Set_item(parent,i,i);
        if(Get_type(polygon,type)!=0||type!="Super")
        {status_message="Every selected element must be a Super string.";return(FALSE);}
        if(String_closed(polygon,closed)!=0||closed!=TRUE)
        {status_message="Every selected Super string must be closed.";return(FALSE);}
        if(String_self_intersects(polygon,selfx)!=0||selfx==TRUE)
        {status_message="A selected polygon self-intersects: "+Element_label(polygon,i);return(FALSE);}
        if(Get_super_use_hole(polygon,use_holes)!=0)
        {status_message="Could not read a Super string hole setting.";return(FALSE);}
        if(use_holes==TRUE)
        {
            if(Get_super_holes(polygon,hole_count)!=0||hole_count>0)
            {status_message="Holes are not supported: "+Element_label(polygon,i);return(FALSE);}
        }
        if(Get_segments(polygon,segment_count)!=0||segment_count<3)
        {status_message="A selected polygon has fewer than three segments.";return(FALSE);}
        for(j=1;j<=segment_count;j++)
        {
            Segment segment;Point start,finish;
            if(Get_segment(polygon,j,segment)!=0||Get_start(segment,start)!=0||Get_end(segment,finish)!=0)
            {status_message="Could not read a native polygon segment.";return(FALSE);}
            Real sx=Get_x(start),sy=Get_y(start),fx=Get_x(finish),fy=Get_y(finish);
            if(Same_xy(sx,sy,fx,fy))
            {status_message="Zero-length XY segment in "+Element_label(polygon,i);return(FALSE);}
            if(Find_or_add_node(node_x,node_y,sx,sy,created)==0||
               Find_or_add_node(node_x,node_y,fx,fy,created)==0)
            {status_message="Could not register a canonical endpoint node.";return(FALSE);}
        }
    }

    /* Stage 2: native intersection pass from the topology-builder approach. */
    Integer ea=0,eb=0,sa=0,sb=0,nsa=0,nsb=0;
    for(ea=1;ea<=polygon_count;ea++)
    {
        Element polygon_a;Get_item(polygons,ea,polygon_a);Get_segments(polygon_a,nsa);
        for(sa=1;sa<=nsa;sa++)
        {
            Segment segment_a;if(Get_segment(polygon_a,sa,segment_a)!=0)continue;
            for(eb=ea;eb<=polygon_count;eb++)
            {
                Element polygon_b;Get_item(polygons,eb,polygon_b);Get_segments(polygon_b,nsb);
                Integer first_sb=1;if(eb==ea)first_sb=sa+1;
                for(sb=first_sb;sb<=nsb;sb++)
                {
                    if(ea==eb&&(sb==sa+1||(sa==1&&sb==nsa)))continue;
                    Segment segment_b;if(Get_segment(polygon_b,sb,segment_b)!=0)continue;
                    Integer no_intersects=0;Point p1,p2;
                    if(Intersect(segment_a,segment_b,no_intersects,p1,p2)!=0||no_intersects<=0)continue;
                    if(no_intersects>2)no_intersects=2;
                    Integer k=0;for(k=1;k<=no_intersects;k++)
                    {
                        Point intersection=p1;if(k==2)intersection=p2;
                        if(Find_or_add_node(node_x,node_y,Get_x(intersection),Get_y(intersection),created)==0)
                        {status_message="Could not register a canonical intersection node.";return(FALSE);}
                    }
                }
            }
        }
    }

    /* Stage 3: global node re-attachment and dynamic physical-edge creation. */
    Dynamic_Real edge_x1,edge_y1,edge_z1,edge_x2,edge_y2,edge_z2;
    Dynamic_Real edge_radius,edge_centre_x,edge_centre_y;
    Dynamic_Integer edge_major,edge_kind,edge_owner1,edge_owner2;
    Dynamic_Integer edge_occurrence,edge_used;
    Integer node_count=0,edge_count=0,cancelled=0;
    Get_number_of_items(node_x,node_count);

    for(ea=1;ea<=polygon_count;ea++)
    {
        Element polygon;Get_item(polygons,ea,polygon);Get_segments(polygon,nsa);
        for(sa=1;sa<=nsa;sa++)
        {
            Segment segment;Point start,finish;
            if(Get_segment(polygon,sa,segment)!=0||Get_start(segment,start)!=0||Get_end(segment,finish)!=0)
            {status_message="Could not read a source segment during graph construction.";return(FALSE);}
            Real ax=Get_x(start),ay=Get_y(start),az=Get_z(start);
            Real bx=Get_x(finish),by=Get_y(finish),bz=Get_z(finish);
            Real vx=0.0,vy=0.0,vz=0.0,source_radius=0.0;Integer source_major=0;
            if(Get_super_data(polygon,sa,vx,vy,vz,source_radius,source_major)!=0)
            {status_message="Could not read source Super segment metadata.";return(FALSE);}
            Integer source_kind=1;Real native_radius=0.0,centre_x=0.0,centre_y=0.0,source_sweep=0.0;
            if(Absolute(source_radius)>ARC_TOL)
            {
                Arc native_arc;if(Get_arc(segment,native_arc)!=0)
                {status_message="Could not read native arc geometry.";return(FALSE);}
                Point centre=Get_centre(native_arc);centre_x=Get_x(centre);centre_y=Get_y(centre);
                native_radius=Get_radius(native_arc);source_kind=2;
                Real dummy_parameter=0.0,dummy_radius=0.0;
                Arc_node_parameter(segment,bx,by,dummy_parameter,dummy_radius,source_sweep);
            }

            Dynamic_Real parameters;Dynamic_Integer parameter_nodes;
            Integer ni=0,parameter_count=0;
            for(ni=1;ni<=node_count;ni++)
            {
                Real nx=0.0,ny=0.0,parameter=0.0,signed_radius=0.0,sweep=0.0;
                Get_item(node_x,ni,nx);Get_item(node_y,ni,ny);
                Integer on_component=FALSE;
                if(source_kind==1)on_component=Point_on_line_parameter(nx,ny,ax,ay,bx,by,parameter);
                else on_component=Arc_node_parameter(segment,nx,ny,parameter,signed_radius,sweep);
                if(on_component!=TRUE)continue;
                Real parameter_tolerance=XY_TOL;
                if(source_kind==1)
                {
                    Real length=Sqrt((bx-ax)*(bx-ax)+(by-ay)*(by-ay));
                    if(length>0.0)parameter_tolerance=XY_TOL/length;
                }
                else if(Absolute(native_radius)>ARC_TOL)parameter_tolerance=XY_TOL/Absolute(native_radius);
                Integer pi=0,exists=FALSE;
                for(pi=1;pi<=parameter_count;pi++)
                {
                    Real old_parameter=0.0;Get_item(parameters,pi,old_parameter);
                    if(Absolute(old_parameter-parameter)<=parameter_tolerance){exists=TRUE;break;}
                }
                if(exists==FALSE)
                {
                    parameter_count++;
                    Set_item(parameters,parameter_count,parameter);
                    Set_item(parameter_nodes,parameter_count,ni);
                }
            }
            if(parameter_count<2)
            {status_message="Noding failed to retain both endpoints of a source component.";return(FALSE);}

            /* Paired insertion sort preserves the parameter-to-node relationship. */
            Integer a=0,b=0;
            for(a=2;a<=parameter_count;a++)
            {
                Real key=0.0;Integer key_node=0;
                Get_item(parameters,a,key);Get_item(parameter_nodes,a,key_node);b=a-1;
                while(b>=1)
                {
                    Real previous=0.0;Get_item(parameters,b,previous);if(previous<=key)break;
                    Set_item(parameters,b+1,previous);
                    Integer previous_node=0;Get_item(parameter_nodes,b,previous_node);
                    Set_item(parameter_nodes,b+1,previous_node);b--;
                }
                Set_item(parameters,b+1,key);Set_item(parameter_nodes,b+1,key_node);
            }

            for(a=1;a<parameter_count;a++)
            {
                Real t0=0.0,t1=0.0;Integer node0=0,node1=0;
                Get_item(parameters,a,t0);Get_item(parameters,a+1,t1);
                Get_item(parameter_nodes,a,node0);Get_item(parameter_nodes,a+1,node1);
                if(t1<=t0)continue;
                Real x0=0.0,y0=0.0,x1=0.0,y1=0.0;
                Get_item(node_x,node0,x0);Get_item(node_y,node0,y0);
                Get_item(node_x,node1,x1);Get_item(node_y,node1,y1);
                Real dx=x1-x0,dy=y1-y0;
                if(dx*dx+dy*dy<MIN_PIECE_LENGTH*MIN_PIECE_LENGTH)continue;
                Real z0=az+(bz-az)*t0,z1=az+(bz-az)*t1;
                Real piece_radius=0.0,piece_centre_x=0.0,piece_centre_y=0.0;Integer piece_major=0;
                if(source_kind==2)
                {
                    piece_radius=native_radius;piece_centre_x=centre_x;piece_centre_y=centre_y;
                    if(source_sweep*(t1-t0)>3.14159265358979323846)piece_major=1;
                }
                Real ex0=x0,ey0=y0,ez0=z0,ex1=x1,ey1=y1,ez1=z1,canonical_radius=piece_radius;
                if(!Endpoint_before(ex0,ey0,ex1,ey1))
                {
                    Real tx=ex0,ty=ey0,tz=ez0;ex0=ex1;ey0=ey1;ez0=ez1;ex1=tx;ey1=ty;ez1=tz;
                    canonical_radius=-canonical_radius;
                }
                Integer physical=Find_physical_piece(ex0,ey0,ex1,ey1,source_kind,
                    canonical_radius,piece_major,piece_centre_x,piece_centre_y,
                    edge_x1,edge_y1,edge_x2,edge_y2,edge_kind,edge_radius,
                    edge_major,edge_centre_x,edge_centre_y);
                if(physical==0)
                {
                    edge_count++;
                    Set_item(edge_x1,edge_count,ex0);Set_item(edge_y1,edge_count,ey0);Set_item(edge_z1,edge_count,ez0);
                    Set_item(edge_x2,edge_count,ex1);Set_item(edge_y2,edge_count,ey1);Set_item(edge_z2,edge_count,ez1);
                    Set_item(edge_kind,edge_count,source_kind);Set_item(edge_radius,edge_count,canonical_radius);
                    Set_item(edge_major,edge_count,piece_major);Set_item(edge_centre_x,edge_count,piece_centre_x);
                    Set_item(edge_centre_y,edge_count,piece_centre_y);Set_item(edge_owner1,edge_count,ea);
                    Set_item(edge_owner2,edge_count,0);Set_item(edge_occurrence,edge_count,1);Set_item(edge_used,edge_count,FALSE);
                }
                else
                {
                    Integer occurrence=0;Get_item(edge_occurrence,physical,occurrence);occurrence++;
                    Set_item(edge_occurrence,physical,occurrence);
                    if(occurrence==2)
                    {
                        Set_item(edge_owner2,physical,ea);cancelled++;
                        Integer first_owner=0;Get_item(edge_owner1,physical,first_owner);
                        UF_union(first_owner,ea,parent);
                    }
                    else if(occurrence>2)
                    {status_message="Duplicate or overlapping coverage: a noded physical edge has more than two owners.";return(FALSE);}
                }
            }
        }
    }

    /* Stage 4: trace the active exterior graph for each union-find component. */
    Dynamic_Integer root_done;Dynamic_Element results;
    Integer result_count=0;
    for(i=1;i<=polygon_count;i++)Set_item(root_done,i,FALSE);
    for(i=1;i<=polygon_count;i++)
    {
        Integer root=UF_find(i,parent),done=FALSE;Get_item(root_done,root,done);
        if(done==TRUE)continue;Set_item(root_done,root,TRUE);
        Integer start_edge=0;
        for(j=1;j<=edge_count;j++)
        {
            Integer occurrence=0,owner=0;Get_item(edge_occurrence,j,occurrence);if(occurrence!=1)continue;
            Get_item(edge_owner1,j,owner);if(UF_find(owner,parent)==root){start_edge=j;break;}
        }
        if(start_edge==0){Cleanup_results(results);status_message="A graph component has no external boundary.";return(FALSE);}

        Dynamic_Real ring_x,ring_y,ring_z,ring_radius;Dynamic_Integer ring_major;
        Real sx=0.0,sy=0.0,sz=0.0,cx=0.0,cy=0.0,cz=0.0,start_radius=0.0;
        Integer start_major=0,ring_count=1;
        Get_item(edge_x1,start_edge,sx);Get_item(edge_y1,start_edge,sy);Get_item(edge_z1,start_edge,sz);
        Get_item(edge_x2,start_edge,cx);Get_item(edge_y2,start_edge,cy);Get_item(edge_z2,start_edge,cz);
        Get_item(edge_radius,start_edge,start_radius);Get_item(edge_major,start_edge,start_major);
        Set_item(ring_x,1,sx);Set_item(ring_y,1,sy);Set_item(ring_z,1,sz);
        Set_item(ring_radius,1,start_radius);Set_item(ring_major,1,start_major);Set_item(edge_used,start_edge,TRUE);

        while(!Same_xy(cx,cy,sx,sy))
        {
            Integer next=0,matches=0,reverse=FALSE;
            for(j=1;j<=edge_count;j++)
            {
                Integer occurrence=0,used=FALSE,owner=0;
                Get_item(edge_occurrence,j,occurrence);Get_item(edge_used,j,used);
                if(occurrence!=1||used==TRUE)continue;
                Get_item(edge_owner1,j,owner);if(UF_find(owner,parent)!=root)continue;
                Real ax=0.0,ay=0.0,bx=0.0,by=0.0;
                Get_item(edge_x1,j,ax);Get_item(edge_y1,j,ay);Get_item(edge_x2,j,bx);Get_item(edge_y2,j,by);
                if(Same_xy(ax,ay,cx,cy)){next=j;reverse=FALSE;matches++;}
                else if(Same_xy(bx,by,cx,cy)){next=j;reverse=TRUE;matches++;}
            }
            if(matches!=1)
            {Cleanup_results(results);status_message="The active exterior graph is open or branches after noding.";return(FALSE);}
            ring_count++;Set_item(ring_x,ring_count,cx);Set_item(ring_y,ring_count,cy);Set_item(ring_z,ring_count,cz);
            Real radius=0.0;Integer major=0;Get_item(edge_radius,next,radius);Get_item(edge_major,next,major);
            if(reverse==TRUE)
            {
                Set_item(ring_radius,ring_count,-radius);Set_item(ring_major,ring_count,major);
                Get_item(edge_x1,next,cx);Get_item(edge_y1,next,cy);Get_item(edge_z1,next,cz);
            }
            else
            {
                Set_item(ring_radius,ring_count,radius);Set_item(ring_major,ring_count,major);
                Get_item(edge_x2,next,cx);Get_item(edge_y2,next,cy);Get_item(edge_z2,next,cz);
            }
            Set_item(edge_used,next,TRUE);
        }

        for(j=1;j<=edge_count;j++)
        {
            Integer occurrence=0,used=FALSE,owner=0;
            Get_item(edge_occurrence,j,occurrence);Get_item(edge_used,j,used);
            if(occurrence!=1||used==TRUE)continue;
            Get_item(edge_owner1,j,owner);
            if(UF_find(owner,parent)==root)
            {Cleanup_results(results);status_message="A graph component produced more than one exterior ring. Holes or complex overlaps are unsupported.";return(FALSE);}
        }

        Element result=Create_super(0,ring_count);
        if(Element_exists(result)==0)
        {Cleanup_results(results);status_message="Create_super failed for a traced graph ring.";return(FALSE);}
        if(Set_super_use_3d_level(result,1)!=0||Set_super_use_segment_radius(result,1)!=0)
        {Element_delete(result);Cleanup_results(results);status_message="Could not enable result Super dimensions.";return(FALSE);}
        for(j=1;j<=ring_count;j++)
        {
            Real x=0.0,y=0.0,z=0.0,radius=0.0;Integer major=0;
            Get_item(ring_x,j,x);Get_item(ring_y,j,y);Get_item(ring_z,j,z);
            Get_item(ring_radius,j,radius);Get_item(ring_major,j,major);
            if(Set_super_data(result,j,x,y,z,radius,major)!=0)
            {Element_delete(result);Cleanup_results(results);status_message="Could not write a result Super vertex.";return(FALSE);}
        }
        if(String_close(result)!=0)
        {Element_delete(result);Cleanup_results(results);status_message="Could not close a result Super string.";return(FALSE);}
        Integer result_closed=FALSE,result_self=FALSE;
        if(String_closed(result,result_closed)!=0||result_closed!=TRUE||
           String_self_intersects(result,result_self)!=0||result_self==TRUE)
        {Element_delete(result);Cleanup_results(results);status_message="A traced result failed geometry validation.";return(FALSE);}
        Set_name(result,"Merged dynamic graph coverage "+To_text(result_count+1));Set_weight(result,0.25);
        if(Set_model(result,output_model)!=0||Calc_extent(result)!=0)
        {Element_delete(result);Cleanup_results(results);status_message="Could not add a result to the output model.";return(FALSE);}
        Element_draw(result);result_count++;Set_item(results,result_count,result);
    }

    /* Stage 5: register grouped undo only after all final outputs succeed. */
    Undo_List undo_list;Null(undo_list);
    for(i=1;i<=result_count;i++)
    {
        Element result;Get_item(results,i,result);
        Undo add_undo=Add_undo_add("Create merged dynamic graph coverage",result);
        Append(add_undo,undo_list);
    }
    if(delete_originals==TRUE)
    {
        for(i=1;i<=polygon_count;i++)
        {
            Element original;Get_item(polygons,i,original);
            Undo delete_undo=Add_undo_delete("Delete source polygon",original,1);
            Append(delete_undo,undo_list);
            if(Element_delete(original)!=0)
            {Add_undo_list("Dissolve Dynamic Graph Polygons",undo_list);status_message="Results were created, but an original could not be deleted.";return(FALSE);}
        }
    }
    Add_undo_list("Dissolve Dynamic Graph Adjacent Super Polygons",undo_list);
    Calc_extent(output_model);Model_draw(output_model);
    status_message="Created "+To_text(result_count)+" merged polygon(s). Canonical nodes="+
                   To_text(node_count)+", physical graph edges="+To_text(edge_count)+
                   ", cancelled shared edges="+To_text(cancelled)+".";
    return(TRUE);
}

void mainPanel()
{
    Text panelName="Dissolve Adjacent Super Polygons - Dynamic Graph Prototype";
    Panel panel=Create_panel(panelName,TRUE);
    Vertical_Group vgroup=Create_vertical_group(-1);
    Colour_Message_Box cmbMsg=Create_colour_message_box("");
    Source_Box sb_source=Create_source_box("Closed Super polygons",cmbMsg,0);
    Model_Box mb_output=Create_model_box("Output model",cmbMsg,CHECK_MODEL_CREATE);
    Real_Box rb_node_tolerance=Create_real_box("XY node tolerance",cmbMsg);
    Named_Tick_Box ntb_delete=Create_named_tick_box("Delete originals after success",FALSE,"");
    Set_data(rb_node_tolerance,0.001);
    Horizontal_Group bgroup=Create_button_group();
    Button process=Create_button("&Process","process");
    Button finish=Create_finish_button("Finish","Finish");
    Button help_button=Create_help_button(panel,"Help");
    Append(process,bgroup);Append(finish,bgroup);Append(help_button,bgroup);
    Append(sb_source,vgroup);Append(mb_output,vgroup);Append(rb_node_tolerance,vgroup);
    Append(ntb_delete,vgroup);Append(cmbMsg,vgroup);Append(bgroup,vgroup);
    Append(vgroup,panel);Show_widget(panel);
    Integer doit=1;
    while(doit)
    {
        Text cmd="",msg="";Integer id,ret=Wait_on_widgets(id,cmd,msg);
        switch(cmd)
        {
        case "keystroke":case "set_focus":case "kill_focus":{continue;}break;
        case "CodeShutdown":{Set_exit_code(cmd);}break;
        }
        switch(id)
        {
        case Get_id(panel):
        {if(cmd=="Panel Quit")doit=0;if(cmd=="Panel About")about_panel(panel);}break;
        case Get_id(process):
        {
            if(cmd=="process")
            {
                Dynamic_Element selected;Null(selected);Model output_model;
                Real node_tolerance=0.001;Integer delete_originals=FALSE;
                if(Validate(sb_source,selected)!=TRUE)
                {Set_data(cmbMsg,"Invalid or incomplete source selection.");break;}
                if(Validate(mb_output,GET_MODEL_CREATE,output_model)!=MODEL_EXISTS)break;
                if(Validate(rb_node_tolerance,node_tolerance)==FALSE)break;
                if(node_tolerance<=0.0)
                {Set_data(cmbMsg,"XY node tolerance must be greater than zero.");break;}
                if(Validate(ntb_delete,delete_originals)==FALSE)break;
                XY_TOL=node_tolerance;ARC_TOL=node_tolerance;
                Set_data(cmbMsg,"Processing dynamic noded graph...");
                Text process_message="";
                Process_dissolve(selected,output_model,delete_originals,process_message);
                Set_data(cmbMsg,process_message);
            }
        }break;
        default:{if(cmd=="Finish")doit=0;}break;
        }
    }
}
void main(){mainPanel();}
