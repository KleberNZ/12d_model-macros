

/*---------------------------------------------------------------------
** Programmer: Kleber Lessa do Prado / Microsoft 365 Copilot
** Date: 25/09/2026
** 12D Model: V15+
** Version: 028
** Macro Name: Polygon_Topology_Builder_panel_DEBUG.4dm
** Version 028 arc fix: final face Super Strings explicitly enable the
** segment-radius dimension before writing geometry, then explicitly write
** each segment radius and major flag and reject any readback mismatch.
** Version 027 fix: disconnected enclosed graph components now contribute one
** component-exterior hole to the containing atomic face, while the bounded
** faces inside that component remain standalone output polygons.
** Version 025 fix: Apply_line_undershoot_repair() aborted the whole repair
** (and therefore the whole macro) whenever the best-effort
** Set_model(original_copy, null_model) detach call returned nonzero. That
** call targets a Model handle from Null(), which is not a legal Set_model
** target and will reliably fail; it is now logged but treated as
** non-fatal, since original_copy only needs to be a valid Element for the
** Add_undo_change() call that follows.
** Type: SOURCE
**
** Stage 4A.1 degree-1 undershoot repair and Stage 4B iterative dangle pruning:
** - Uses documented Intersect(Segment,Segment,...) on native Segments
** - Does not promote arc-chord false positives to canonical nodes
** - Does not reject true arc crossings because of chord-only bounding boxes
** - Retains Stage 3F native noding and endpoint snap
** - Builds physical edges and paired directed edges
** - Repairs eligible degree-1 native LINE undershoots before dangle pruning
** - Rebuilds canonical topology after each source endpoint repair
** - Calculates active node degree and iteratively prunes remaining degree-1 chains
** - Deactivates each removed physical edge and both directed edges
** - Preserves native arc geometry and signed radius in output pieces
**---------------------------------------------------------------------*/
#define DEBUG_FILE 0
#define ECHO_DEBUG_FILE 0
#define ECHO_LINE_NO 0
#define BUILD "$2.0.035"
#include "standard_library.h"
#include "size_of.h"

/*global variables*/{
    Text MACRO_NAME="Polygon Topology Builder - DEBUG";
}

void Output_line(Text text){Print(text);Print();}

Integer Validate_positive(Text label,Real value)
{
    if(value<=0.0){Print("ERROR: ");Print(label);Print(" must be greater than zero.");Print();return(FALSE);}
    return(TRUE);
}

Integer Validate_non_negative(Text label,Real value)
{
    if(value<0.0){Print("ERROR: ");Print(label);Print(" must not be negative.");Print();return(FALSE);}
    return(TRUE);
}

Integer Read_super_summary(Element source,Text role,Integer &npts,Integer &line_count,Integer &arc_count)
{
    Integer status,i,major;
    Real x,y,z,radius;
    npts=0;line_count=0;arc_count=0;
    status=Get_points(source,npts);
    if(status!=0||npts<1)return(FALSE);
    for(i=1;i<=npts;i++)
    {
        status=Get_super_data(source,i,x,y,z,radius,major);
        if(status!=0)
        {
            Print("ERROR: Get_super_data failed. role=");Print(role);
            return(FALSE);
        }
        if(i<npts){if(radius==0.0)line_count++;else arc_count++;}
    }
    return(TRUE);
}

Integer Copy_super_arc_native(Element source,Model output_model,Real output_level,
                              Text output_name,Element &result)
{
    Integer status,npts=0,result_points=0,i,major;
    Real x,y,z,radius;
    Model actual_model;
    Text actual_name="";

    status=Get_points(source,npts);
    if(status!=0||npts<2)return(FALSE);
    result=Create_super(npts,source);
    if(Element_exists(result)==0)return(FALSE);
    status=Get_points(result,result_points);
    if(status!=0||result_points!=npts)return(FALSE);

    for(i=1;i<=npts;i++)
    {
        if(Get_super_data(source,i,x,y,z,radius,major)!=0)return(FALSE);
        if(Set_super_data(result,i,x,y,output_level,radius,major)!=0)return(FALSE);
    }

    status=Set_model(result,output_model);
    if(status!=0)return(FALSE);

    /* Example 12 renames strings already held by a model. */
    Set_name(result,output_name);
    status=Get_name(result,actual_name);
    

    status=Get_model(result,actual_model);
    if(status!=0)return(FALSE);

    /* Runtime testing confirms each created Element needs its own extent
       calculation before the Element is accessible/selectable in 12d. */
    status=Calc_extent(result);
    if(status!=0)return(FALSE);

    /* Register undo only after model assignment and successful extent update. */
    Undo created_undo=Add_undo_add("Create arc-native Stage 3B working output",result);
    return(TRUE);
}

Integer Get_input_element(Integer combined_index,Element site,
                          Dynamic_Element &internal_strings,Integer internal_count,
                          Element &element,Text &role)
{
    if(combined_index==1)
    {
        element=site;
        role="Site boundary";
        return(0);
    }
    Integer source_index=combined_index-1;
    if(source_index<1||source_index>internal_count)return(-1);
    if(Get_item(internal_strings,source_index,element)!=0)return(-2);
    Text name="";
    Get_name(element,name);
    role="Internal Element "+To_text(source_index)+" : "+name;
    return(0);
}

Real Cross_2d(Real ax,Real ay,Real bx,Real by)
{
    return(ax*by-ay*bx);
}

Integer Manual_segment_intersection(Real ax,Real ay,Real bx,Real by,
                                    Real cx,Real cy,Real dx,Real dy,
                                    Real tol,Real &ix,Real &iy)
{
    Real rx=bx-ax, ry=by-ay;
    Real sx=dx-cx, sy=dy-cy;
    Real qpx=cx-ax, qpy=cy-ay;
    Real rxs=Cross_2d(rx,ry,sx,sy);
    Real qpxr=Cross_2d(qpx,qpy,rx,ry);
    Real rr=rx*rx+ry*ry;
    Real ss=sx*sx+sy*sy;

    if(rr<=tol*tol||ss<=tol*tol)return(-1); /* degenerate */

    if(Absolute(rxs)>tol)
    {
        Real t=Cross_2d(qpx,qpy,sx,sy)/rxs;
        Real u=Cross_2d(qpx,qpy,rx,ry)/rxs;
        if(t>=-tol&&t<=1.0+tol&&u>=-tol&&u<=1.0+tol)
        {
            ix=ax+t*rx;
            iy=ay+t*ry;
            if(t<=tol||t>=1.0-tol||u<=tol||u>=1.0-tol)return(2); /* endpoint touch */
            return(1); /* proper crossing */
        }
        return(0);
    }

    if(Absolute(qpxr)>tol)return(0); /* parallel, non-collinear */

    /* Collinear classification on dominant axis. */
    Real a0,a1,c0,c1;
    if(Absolute(rx)>=Absolute(ry)){a0=ax;a1=bx;c0=cx;c1=dx;}
    else {a0=ay;a1=by;c0=cy;c1=dy;}
    if(a0>a1){Real tmp=a0;a0=a1;a1=tmp;}
    if(c0>c1){Real tmp2=c0;c0=c1;c1=tmp2;}
    Real lo=a0;if(c0>lo)lo=c0;
    Real hi=a1;if(c1<hi)hi=c1;
    if(hi<lo-tol)return(0);
    if(Absolute(hi-lo)<=tol)return(3); /* collinear point touch */
    return(4); /* finite overlap or duplicate */
}

Integer Find_or_add_node(Dynamic_Real &node_x,Dynamic_Real &node_y,
                         Real x,Real y,Real tol,Integer &created)
{
    Integer count=0,i;
    Get_number_of_items(node_x,count);
    Real best_d2=tol*tol;
    Integer best=0;
    for(i=1;i<=count;i++)
    {
        Real nx=0.0,ny=0.0;
        if(Get_item(node_x,i,nx)!=0||Get_item(node_y,i,ny)!=0)continue;
        Real dx=x-nx,dy=y-ny,d2=dx*dx+dy*dy;
        if(d2<=best_d2){best_d2=d2;best=i;}
    }
    if(best!=0){created=FALSE;return(best);}
    count++;
    Set_item(node_x,count,x);
    Set_item(node_y,count,y);
    created=TRUE;
    return(count);
}

Integer Point_on_segment_parameter(Real px,Real py,Real ax,Real ay,Real bx,Real by,
                                   Real tol,Real &parameter)
{
    Real rx=bx-ax,ry=by-ay;
    Real rr=rx*rx+ry*ry;
    if(rr<=tol*tol)return(FALSE);
    parameter=((px-ax)*rx+(py-ay)*ry)/rr;
    Real qx=ax+parameter*rx,qy=ay+parameter*ry;
    Real dx=px-qx,dy=py-qy;
    if(dx*dx+dy*dy>tol*tol)return(FALSE);
    if(parameter<-tol||parameter>1.0+tol)return(FALSE);
    return(TRUE);
}

Real Normalise_positive_angle(Real angle)
{
    Real two_pi=6.28318530717958647692;
    while(angle<0.0)angle+=two_pi;
    while(angle>=two_pi)angle-=two_pi;
    return(angle);
}

Integer Arc_node_parameter(Segment segment,Real px,Real py,Real tol,
                           Real &parameter,Real &signed_radius,Integer &reject_code,
                           Real &radial_error,Real &sweep,Real &travel)
{
    Arc arc;
    reject_code=0;radial_error=0.0;sweep=0.0;travel=0.0;parameter=0.0;signed_radius=0.0;
    if(Get_arc(segment,arc)!=0){reject_code=1;return(FALSE);}
    Point centre=Get_centre(arc);
    Point start=Get_start(arc);
    Point finish=Get_end(arc);
    signed_radius=Get_radius(arc);
    Real radius=Absolute(signed_radius);
    if(radius<=tol){reject_code=2;return(FALSE);}
    Real cx=Get_x(centre),cy=Get_y(centre);
    Real sx=Get_x(start),sy=Get_y(start);
    Real fx=Get_x(finish),fy=Get_y(finish);
    Real dsx=px-sx,dsy=py-sy;
    Real dfx=px-fx,dfy=py-fy;
    /* Endpoint snap must occur before angle normalisation.  A calculated
       start angle can differ by a tiny negative amount and normalise to
       almost 2*pi, incorrectly rejecting the true t=0 boundary. */
    if(dsx*dsx+dsy*dsy<=tol*tol)
    {
        parameter=0.0;radial_error=0.0;travel=0.0;
        Real a0s=Atan2(sy-cy,sx-cx);
        Real a1s=Atan2(fy-cy,fx-cx);
        if(signed_radius>0.0)sweep=Normalise_positive_angle(a0s-a1s);
        else sweep=Normalise_positive_angle(a1s-a0s);
        return(TRUE);
    }
    if(dfx*dfx+dfy*dfy<=tol*tol)
    {
        parameter=1.0;radial_error=0.0;
        Real a0f=Atan2(sy-cy,sx-cx);
        Real a1f=Atan2(fy-cy,fx-cx);
        if(signed_radius>0.0)sweep=Normalise_positive_angle(a0f-a1f);
        else sweep=Normalise_positive_angle(a1f-a0f);
        travel=sweep;
        return(TRUE);
    }
    Real vx=px-cx,vy=py-cy;
    Real radial=Sqrt(vx*vx+vy*vy);
    radial_error=Absolute(radial-radius);
    if(radial_error>tol){reject_code=3;return(FALSE);}
    Real a0=Atan2(sy-cy,sx-cx);
    Real a1=Atan2(fy-cy,fx-cx);
    Real ap=Atan2(py-cy,px-cx);
    if(signed_radius>0.0){sweep=Normalise_positive_angle(a0-a1);travel=Normalise_positive_angle(a0-ap);}
    else {sweep=Normalise_positive_angle(a1-a0);travel=Normalise_positive_angle(ap-a0);}
    if(sweep<=0.0){reject_code=4;return(FALSE);}
    if(travel>sweep+tol/radius){reject_code=5;return(FALSE);}
    parameter=travel/sweep;
    if(parameter<0.0)parameter=0.0;
    if(parameter>1.0)parameter=1.0;
    return(TRUE);
}

Integer Extract_overlap_endpoints(Real ax,Real ay,Real bx,Real by,
                                  Real cx,Real cy,Real dx,Real dy,
                                  Real tol,Real &ox0,Real &oy0,
                                  Real &ox1,Real &oy1,Integer &identical)
{
    Real rx=bx-ax,ry=by-ay;
    Real rr=rx*rx+ry*ry;
    if(rr<=tol*tol)return(FALSE);

    Real tc=((cx-ax)*rx+(cy-ay)*ry)/rr;
    Real td=((dx-ax)*rx+(dy-ay)*ry)/rr;
    Real b0=tc,b1=td;
    if(b0>b1){Real swap=b0;b0=b1;b1=swap;}

    Real lo=0.0;if(b0>lo)lo=b0;
    Real hi=1.0;if(b1<hi)hi=b1;
    if(hi<lo-tol)return(FALSE);
    if(Absolute(hi-lo)<=tol)return(FALSE);

    ox0=ax+lo*rx;oy0=ay+lo*ry;
    ox1=ax+hi*rx;oy1=ay+hi*ry;

    identical=FALSE;
    if(Absolute(lo)<=tol&&Absolute(hi-1.0)<=tol&&
       b0<=tol&&b1>=1.0-tol)identical=TRUE;
    return(TRUE);
}

/* ============================================================
   Stage 3F.1 — LINE NODE ATTACHMENT AUDIT
   Diagnostic-only audit. It does not alter topology.
   ============================================================ */
Integer Point_on_xy_segment(Real px,Real py,Real ax,Real ay,Real bx,Real by,Real tol)
{
    Real vx=bx-ax,vy=by-ay,wx=px-ax,wy=py-ay;
    Real len2=vx*vx+vy*vy;
    if(len2<=tol*tol)return((wx*wx+wy*wy)<=tol*tol);
    Real length=Sqrt(len2);
    if(Absolute(vx*wy-vy*wx)>tol*length)return(FALSE);
    Real dot=wx*vx+wy*vy;
    if(dot<-tol*length||dot>len2+tol*length)return(FALSE);
    return(TRUE);
}
/* 1=INSIDE, 0=OUTSIDE, 2=BOUNDARY, -1=FAILURE */
Integer Manual_point_in_ring(Dynamic_Real &ring_x,Dynamic_Real &ring_y,Integer count,
                             Real px,Real py,Real tol)
{
    if(count<3)return(-1);
    Integer inside=FALSE,i=0,j=count;
    for(i=1;i<=count;i++)
    {
        Real ax=0.0,ay=0.0,bx=0.0,by=0.0;
        if(Get_item(ring_x,j,ax)!=0||Get_item(ring_y,j,ay)!=0||
           Get_item(ring_x,i,bx)!=0||Get_item(ring_y,i,by)!=0)return(-1);
        if(Point_on_xy_segment(px,py,ax,ay,bx,by,tol)==TRUE)return(2);
        if((ay>py&&by<=py)||(by>py&&ay<=py))
        {
            Real denominator=by-ay;
            if(denominator==0.0)return(-1);
            Real x_cross=ax+(py-ay)*(bx-ax)/denominator;
            if(x_cross>px){if(inside==TRUE)inside=FALSE;else inside=TRUE;}
        }
        j=i;
    }
    if(inside==TRUE)return(1);
    return(0);
}
Integer Append_pip_point(Dynamic_Real &xlist,Dynamic_Real &ylist,Integer &count,
                         Real x,Real y,Real tol)
{
    if(count>0)
    {
        Real lx=0.0,ly=0.0;
        if(Get_item(xlist,count,lx)!=0||Get_item(ylist,count,ly)!=0)return(FALSE);
        Real dx=x-lx,dy=y-ly;
        if(dx*dx+dy*dy<=tol*tol)return(TRUE);
    }
    count++;
    if(Set_item(xlist,count,x)!=0||Set_item(ylist,count,y)!=0)return(FALSE);
    return(TRUE);
}
Integer Build_site_pip_ring(Element site,Real arc_tolerance,Real node_tolerance,
                            Dynamic_Real &site_x,Dynamic_Real &site_y,Integer &site_count)
{
    site_count=0;
    Integer nseg=0,si=0;
    if(Get_segments(site,nseg)!=0||nseg<1)return(FALSE);
    for(si=1;si<=nseg;si++)
    {
        Segment seg; Point start,finish;
        if(Get_segment(site,si,seg)!=0||Get_start(seg,start)!=0||Get_end(seg,finish)!=0)return(FALSE);
        Real sx=Get_x(start),sy=Get_y(start),ex=Get_x(finish),ey=Get_y(finish);
        Arc arc;
        if(Get_arc(seg,arc)!=0)
        {
            if(Append_pip_point(site_x,site_y,site_count,sx,sy,node_tolerance)!=TRUE||
               Append_pip_point(site_x,site_y,site_count,ex,ey,node_tolerance)!=TRUE)return(FALSE);
            continue;
        }
        Point centre=Get_centre(arc);
        Real cx=Get_x(centre),cy=Get_y(centre),signed_radius=Get_radius(arc);
        Real radius=Absolute(signed_radius);
        if(radius<=node_tolerance)return(FALSE);
        Real a0=Atan2(sy-cy,sx-cx),a1=Atan2(ey-cy,ex-cx),sweep=0.0;
        if(signed_radius>0.0)sweep=Normalise_positive_angle(a0-a1);
        else sweep=Normalise_positive_angle(a1-a0);
        if(sweep<=0.0)return(FALSE);
        Real eps=arc_tolerance;if(eps<=0.0)eps=node_tolerance;
        Real theta_max=3.14159265358979323846/8.0;
        if(eps<radius){theta_max=2.0*Acos(1.0-eps/radius);if(theta_max<=0.0)theta_max=3.14159265358979323846/8.0;}
        Integer pieces=Ceil(sweep/theta_max);if(pieces<1)pieces=1;
        Integer k=0;
        for(k=0;k<=pieces;k++)
        {
            Real t=1.0*k/pieces,angle=a0;
            if(signed_radius>0.0)angle=a0-sweep*t;else angle=a0+sweep*t;
            Real x=cx+radius*Cos(angle),y=cy+radius*Sin(angle);
            if(k==0){x=sx;y=sy;}if(k==pieces){x=ex;y=ey;}
            if(Append_pip_point(site_x,site_y,site_count,x,y,node_tolerance)!=TRUE)return(FALSE);
        }
    }
    if(site_count<3)return(FALSE);
    Real fx=0.0,fy=0.0,lx=0.0,ly=0.0;
    Get_item(site_x,1,fx);Get_item(site_y,1,fy);Get_item(site_x,site_count,lx);Get_item(site_y,site_count,ly);
    Real dx=lx-fx,dy=ly-fy;if(dx*dx+dy*dy<=node_tolerance*node_tolerance)site_count--;
    return(site_count>=3);
}
Integer Find_face_representative_point(Dynamic_Real &face_x,Dynamic_Real &face_y,Integer count,
                                       Real signed_area,Real tol,Real &sample_x,Real &sample_y)
{
    if(count<3||Absolute(signed_area)<=0.0)return(FALSE);
    Real cross_sum=0.0,cx_sum=0.0,cy_sum=0.0;Integer i=0,j=0;
    for(i=1;i<=count;i++)
    {
        j=i+1;if(j>count)j=1;
        Real ax=0.0,ay=0.0,bx=0.0,by=0.0;
        Get_item(face_x,i,ax);Get_item(face_y,i,ay);Get_item(face_x,j,bx);Get_item(face_y,j,by);
        Real cross=ax*by-bx*ay;cross_sum+=cross;cx_sum+=(ax+bx)*cross;cy_sum+=(ay+by)*cross;
    }
    if(Absolute(cross_sum)>0.0)
    {
        sample_x=cx_sum/(3.0*cross_sum);sample_y=cy_sum/(3.0*cross_sum);
        if(Manual_point_in_ring(face_x,face_y,count,sample_x,sample_y,tol)==1)return(TRUE);
    }
    Real scales[6];scales[1]=2.0;scales[2]=5.0;scales[3]=10.0;scales[4]=25.0;scales[5]=50.0;scales[6]=100.0;
    for(i=1;i<=count;i++)
    {
        j=i+1;if(j>count)j=1;
        Real ax=0.0,ay=0.0,bx=0.0,by=0.0;
        Get_item(face_x,i,ax);Get_item(face_y,i,ay);Get_item(face_x,j,bx);Get_item(face_y,j,by);
        Real dx=bx-ax,dy=by-ay,length=Sqrt(dx*dx+dy*dy);if(length<=tol)continue;
        Real nx=-dy/length,ny=dx/length;if(signed_area<0.0){nx=-nx;ny=-ny;}
        Integer si=0;for(si=1;si<=6;si++)
        {
            sample_x=(ax+bx)/2.0+nx*tol*scales[si];sample_y=(ay+by)/2.0+ny*tol*scales[si];
            if(Manual_point_in_ring(face_x,face_y,count,sample_x,sample_y,tol)==1)return(TRUE);
        }
    }
    return(FALSE);
}
Integer Build_face_ring_from_start(Integer start_de,Dynamic_Integer &directed_next,
                                   Dynamic_Integer &directed_from,Dynamic_Real &node_x,Dynamic_Real &node_y,
                                   Integer max_steps,Dynamic_Real &ring_x,Dynamic_Real &ring_y,Integer &count)
{
    count=0;Integer current=start_de;
    while(count<=max_steps)
    {
        Integer node=0;Get_item(directed_from,current,node);
        Real x=0.0,y=0.0;Get_item(node_x,node,x);Get_item(node_y,node,y);
        count++;Set_item(ring_x,count,x);Set_item(ring_y,count,y);
        Integer next=0;Get_item(directed_next,current,next);
        if(next<1)return(FALSE);current=next;
        if(current==start_de)return(count>=3);
    }
    return(FALSE);
}

/* Stage 5N Super String metadata readback audit.
   A Super String stores its line/arc definition in Get_super_data().
   Get_arc(Segment,Arc) is not used here because its failure caused valid
   Super String polygons to be rejected before model output. */
Integer Verify_native_face_arcs(Element result,Integer expected_arcs,
                              Integer &actual_lines,Integer &actual_arcs)
{
    Integer nseg=0,i=0;
    actual_lines=0;actual_arcs=0;
    if(Get_segments(result,nseg)!=0)return(FALSE);
    for(i=1;i<=nseg;i++)
    {
        Real x=0.0,y=0.0,z=0.0,radius=0.0;
        Integer major=0;
        if(Get_super_data(result,i,x,y,z,radius,major)!=0)return(FALSE);
        if(radius!=0.0)
        {
            actual_arcs++;
        }
        else actual_lines++;
    }
    if(actual_arcs!=expected_arcs)
    {
        Print("STAGE5N ARC VERIFY FAILURE expected=");Print(expected_arcs);
        Print(" actual=");Print(actual_arcs);Print();
        return(FALSE);
    }
    return(TRUE);
}

/* Stage 5N: rebuild a traced ring using native line/arc segment metadata.
   edge_signed_radius is aligned with edge_from -> edge_to. Reversing a
   directed edge reverses the radius sign while retaining the major flag. */
Integer Build_native_face_super(Integer start_de,
                                Dynamic_Integer &directed_next,
                                Dynamic_Integer &directed_from,
                                Dynamic_Integer &directed_physical_edge,
                                Dynamic_Integer &edge_from,
                                Dynamic_Integer &edge_source_element,
                                Dynamic_Integer &edge_geometry_kind,
                                Dynamic_Real &edge_signed_radius,
                                Dynamic_Integer &edge_arc_major,
                                Dynamic_Integer &edge_segment_colour,
                                Dynamic_Real &edge_weight,
                                Dynamic_Real &edge_arc_centre_x,
                                Dynamic_Real &edge_arc_centre_y,
                                Dynamic_Real &node_x,Dynamic_Real &node_y,
                                Integer max_steps,Real output_level,
                                Element seed,
                                Element &result,Integer &vertex_count,
                                Integer &line_segments,Integer &arc_segments)
{
    vertex_count=0;line_segments=0;arc_segments=0;
    Integer current=start_de,closed=FALSE;
    Dynamic_Integer walk_edges;
    while(vertex_count<=max_steps)
    {
        vertex_count++;
        Set_item(walk_edges,vertex_count,current);
        Integer next=0;Get_item(directed_next,current,next);
        if(next<1)return(FALSE);
        current=next;
        if(current==start_de){closed=TRUE;break;}
    }
    if(closed!=TRUE||vertex_count<3)return(FALSE);
    /* BUGFIX: was Create_super(1,vertex_count) - this called the
       Create_super(Integer flag1,Integer num_pts) overload with a
       dimension flag of 1, which does not enable the radius/bulge
       dimension. Every Set_super_data() radius value below was then
       silently discarded, which is why Verify_native_face_arcs always
       read back actual_arcs=0. Create_super(Integer num_pts,Element seed)
       instead sizes the string correctly AND inherits seed's dimension
       set (including radius), matching the pattern already used
       successfully by Copy_super_arc_native() and the arc-piece writer. */
    result=Create_super(vertex_count,seed);
    if(Element_exists(result)==0)return(FALSE);
    /* The seed can be a line-only site boundary. Explicitly enable the
       segment-radius dimension so non-zero radii written below are retained. */
    if(Set_super_use_segment_radius(result,1)!=0)
    {
        Element_delete(result);
        return(FALSE);
    }
    if(Set_super_use_segment_colour(result,1)!=0)
    {
        Element_delete(result);
        return(FALSE);
    }
    Real inherited_weight=0.0;
    Integer inherited_weight_set=FALSE,inherited_weight_from_internal=FALSE;
    Integer i=0;
    for(i=1;i<=vertex_count;i++)
    {
        Integer de=0,node=0,physical=0,canonical_from=0,kind=1,major=0;
        Integer source_element=0,segment_colour=0;
        Real segment_weight=0.0;
        Real x=0.0,y=0.0,radius=0.0,centre_x=0.0,centre_y=0.0;
        Get_item(walk_edges,i,de);
        Get_item(directed_from,de,node);
        Get_item(directed_physical_edge,de,physical);
        Get_item(node_x,node,x);Get_item(node_y,node,y);
        Get_item(edge_from,physical,canonical_from);
        Get_item(edge_source_element,physical,source_element);
        Get_item(edge_geometry_kind,physical,kind);
        Get_item(edge_signed_radius,physical,radius);
        Get_item(edge_arc_major,physical,major);
        Get_item(edge_segment_colour,physical,segment_colour);
        Get_item(edge_weight,physical,segment_weight);
        Get_item(edge_arc_centre_x,physical,centre_x);
        Get_item(edge_arc_centre_y,physical,centre_y);
        if(node!=canonical_from)radius=-radius;
        if(kind!=2){radius=0.0;major=0;line_segments++;}
        else arc_segments++;
        if(Set_super_data(result,i,x,y,output_level,radius,major)!=0)
        {
            Element_delete(result);
            return(FALSE);
        }
        /* Write the documented per-segment arc fields explicitly as well. */
        if(Set_super_segment_radius(result,i,radius)!=0)
        {
            Element_delete(result);
            return(FALSE);
        }
        if(Set_super_segment_major(result,i,major)!=0)
        {
            Element_delete(result);
            return(FALSE);
        }
        if(Set_super_segment_colour(result,i,segment_colour)!=0)
        {
            Element_delete(result);
            return(FALSE);
        }
        /* Site boundary is source element 1. Prefer the first internal
           source edge because the site boundary can carry a display weight
           such as 5.0 while the subdivision lines/arcs carry 0.25. */
        if(source_element>1&&inherited_weight_from_internal!=TRUE)
        {
            inherited_weight=segment_weight;
            inherited_weight_set=TRUE;
            inherited_weight_from_internal=TRUE;
        }
        else if(inherited_weight_set!=TRUE)
        {
            inherited_weight=segment_weight;
            inherited_weight_set=TRUE;
        }
    }
    if(String_close(result)!=0)
    {
        Element_delete(result);
        return(FALSE);
    }
    if(inherited_weight_set==TRUE)
    {
        if(Set_weight(result,inherited_weight)!=0)
        {
            Element_delete(result);
            return(FALSE);
        }
    }
    Integer verified_lines=0,verified_arcs=0;
    if(Verify_native_face_arcs(result,arc_segments,verified_lines,verified_arcs)!=TRUE)
    {
        Print("STAGE5N ERROR: completed Super String did not retain expected arcs.");Print();
        Element_delete(result);
        return(FALSE);
    }
    line_segments=verified_lines;
    arc_segments=verified_arcs;
    return(TRUE);
}


/* ============================================================
   Stage 4A.1 - DEGREE-1 UNDERSHOOT REPAIR

   Intersect_extended(), manual ID 303, extends both native Segments.
   Therefore every returned candidate is independently checked against
   the finite target component and against the required source-line
   extension direction before it can be selected.
   ============================================================ */
Integer Edge_has_one_attachment(Integer edge_id,
                              Dynamic_Integer &edge_from,
                              Dynamic_Integer &edge_to,
                              Dynamic_Integer &edge_active,
                              Dynamic_Integer &node_degree,
                              Integer &free_node,Integer &attached_node)
{
    free_node=0;attached_node=0;
    Integer active=FALSE,from_node=0,to_node=0,from_degree=0,to_degree=0;
    if(Get_item(edge_active,edge_id,active)!=0||active!=TRUE)return(FALSE);
    if(Get_item(edge_from,edge_id,from_node)!=0||Get_item(edge_to,edge_id,to_node)!=0)return(FALSE);
    if(Get_item(node_degree,from_node,from_degree)!=0||Get_item(node_degree,to_node,to_degree)!=0)return(FALSE);
    if(from_degree==1&&to_degree>1){free_node=from_node;attached_node=to_node;return(TRUE);}
    if(to_degree==1&&from_degree>1){free_node=to_node;attached_node=from_node;return(TRUE);}
    return(FALSE);
}

Integer Delete_temporary_topology_output(Dynamic_Element &edge_geometry,
                                        Integer &deleted_count,Integer &failure_count)
{
    deleted_count=0;failure_count=0;
    Integer count=0,i=0;
    if(Get_number_of_items(edge_geometry,count)!=0)return(FALSE);
    for(i=1;i<=count;i++)
    {
        Element piece;
        if(Get_item(edge_geometry,i,piece)!=0)continue;
        if(Element_exists(piece)==0)continue;
        Integer status=Element_delete(piece);
        if(status==0)
        {
            deleted_count++;
        }
        else
        {
            failure_count++;
            Print("STAGE4A1 TEMPORARY OUTPUT CLEANUP FAILED edge=");Print(i);
        }
    }
    if(failure_count>0)return(FALSE);
    return(TRUE);
}

Integer Apply_line_undershoot_repair(Integer source_element_id,Integer source_component_id,
                                   Integer free_node,Element site,
                                   Dynamic_Element &internal_strings,Integer internal_count,
                                   Dynamic_Real &node_x,Dynamic_Real &node_y,
                                   Real repair_x,Real repair_y,Real node_tolerance)
{
    Element source;Text role="";
    Integer source_status=Get_input_element(source_element_id,site,internal_strings,internal_count,source,role);
    if(source_status!=0)
    {
        Print("STAGE4A1 APPLY FAILURE Get_input_element status=");Print(source_status);Print();
        return(FALSE);
    }
    Integer npts=0;
    Integer points_status=Get_points(source,npts);
    if(points_status!=0||source_component_id<1||source_component_id>=npts)
    {
        Print("STAGE4A1 APPLY FAILURE points status=");Print(points_status);Print(" npts=");Print(npts);Print();
        return(FALSE);
    }
    Real free_x=0.0,free_y=0.0;
    if(Get_item(node_x,free_node,free_x)!=0||Get_item(node_y,free_node,free_y)!=0)return(FALSE);
    Real sx=0.0,sy=0.0,sz=0.0,sradius=0.0;
    Real ex=0.0,ey=0.0,ez=0.0,eradius=0.0;
    Integer smajor=0,emajor=0;
    if(Get_super_data(source,source_component_id,sx,sy,sz,sradius,smajor)!=0)return(FALSE);
    if(Get_super_data(source,source_component_id+1,ex,ey,ez,eradius,emajor)!=0)return(FALSE);
    Real dsx=free_x-sx,dsy=free_y-sy,dex=free_x-ex,dey=free_y-ey;
    Integer vertex=0;
    if(dsx*dsx+dsy*dsy<=node_tolerance*node_tolerance)vertex=source_component_id;
    else if(dex*dex+dey*dey<=node_tolerance*node_tolerance)vertex=source_component_id+1;
    else return(FALSE);

    /* Preserve every metadata field stored on the updated Super vertex.
       At a component end this includes metadata belonging to the following
       adjacent component, so arbitrary radius/major values must not be used. */
    Real old_x=0.0,old_y=0.0,old_z=0.0,old_radius=0.0;Integer old_major=0;
    if(Get_super_data(source,vertex,old_x,old_y,old_z,old_radius,old_major)!=0)return(FALSE);

    Element original_copy;
    /* Element_duplicate is used here according to the approved changed-element
       undo pattern.  Do not interpret its return as generic zero-success.
       Validate the resulting Element handle instead. */
    Integer duplicate_status=Element_duplicate(source,original_copy);
    if(Element_exists(original_copy)==0)
    {
        Print("STAGE4A1 UNDERSHOOT REJECTED unable to duplicate original source for undo");Print();
        return(FALSE);
    }
    /* Best-effort only: Null() does not produce a Model handle that
       Set_model can legally target, so this call is expected to fail and
       must not be allowed to abort a correct repair. original_copy only
       needs to be a valid Element for Add_undo_change below; whether it is
       detached from a model first is cosmetic, not load-bearing. */
    Model null_model;Null(null_model);
    Integer detach_status=Set_model(original_copy,null_model);
    if(detach_status!=0)Print(" (non-fatal, continuing)");
    Integer set_status=Set_super_data(source,vertex,repair_x,repair_y,old_z,old_radius,old_major);
    if(set_status!=0)
    {
        Print("STAGE4A1 UNDERSHOOT REJECTED Set_super_data status=");Print(set_status);Print();
        return(FALSE);
    }
    Integer extent_status=Calc_extent(source);
    if(extent_status!=0)
    {
        /* Restore the original coordinate and metadata if the edited element
           cannot be made valid/selectable. */
        Set_super_data(source,vertex,old_x,old_y,old_z,old_radius,old_major);
        Calc_extent(source);
        Print("STAGE4A1 UNDERSHOOT REJECTED Calc_extent status=");Print(extent_status);Print();
        return(FALSE);
    }
    Undo repair_undo=Add_undo_change("Stage 4A.1 line undershoot repair",original_copy,source);
    return(TRUE);
}

Integer Run_stage_4A1_undershoot_repair(Element site,Dynamic_Element &internal_strings,
                                      Integer internal_count,
                                      Dynamic_Integer &edge_from,Dynamic_Integer &edge_to,
                                      Dynamic_Integer &edge_source_element,
                                      Dynamic_Integer &edge_source_component,
                                      Dynamic_Integer &edge_geometry_kind,
                                      Dynamic_Integer &edge_active,
                                      Dynamic_Integer &node_degree,
                                      Dynamic_Real &node_x,Dynamic_Real &node_y,
                                      Real maximum_undershoot_extension,
                                      Real node_tolerance,Integer &repair_applied)
{
    repair_applied=FALSE;
    if(maximum_undershoot_extension<=0.0)
    {
        return(TRUE);
    }
    Integer edge_count=0,total_elements=internal_count+1,edge_id=0;
    if(Get_number_of_items(edge_from,edge_count)!=0)return(FALSE);
    Integer best_found=FALSE,best_source_element=0,best_source_component=0,best_free_node=0;
    Integer best_target_element=0,best_target_component=0;
    Real best_x=0.0,best_y=0.0,best_distance=0.0;
    Real tie_epsilon=node_tolerance*0.001;if(tie_epsilon<0.000000001)tie_epsilon=0.000000001;

    Integer eligible_edge_count=0;
    for(edge_id=1;edge_id<=edge_count;edge_id++)
    {
        Integer free_node=0,attached_node=0,active=FALSE;
        Integer ef=0,et=0,df=0,dt=0;
        Integer status_active=Get_item(edge_active,edge_id,active);
        Integer status_from=Get_item(edge_from,edge_id,ef);
        Integer status_to=Get_item(edge_to,edge_id,et);
        Integer status_df=-1,status_dt=-1;
        if(status_from==0)status_df=Get_item(node_degree,ef,df);
        if(status_to==0)status_dt=Get_item(node_degree,et,dt);
        if(status_active!=0||status_from!=0||status_to!=0||status_df!=0||status_dt!=0)
        {
            Print("STAGE4A1 UNDERSHOOT REJECTED graph read failure edge=");Print(edge_id);
            continue;
        }
        if(active!=TRUE)continue;
        if(df==1&&dt==1)
        {
            Print("STAGE4A1 UNDERSHOOT REJECTED isolated edge=");Print(edge_id);
            continue;
        }
        /* Resolve Scenario B directly from the already calculated graph degree.
           This avoids silently losing a valid edge if a secondary helper call
           encounters a container-read issue. */
        if(df==1&&dt>1){free_node=ef;attached_node=et;}
        else if(dt==1&&df>1){free_node=et;attached_node=ef;}
        else continue;
        eligible_edge_count++;
        Integer source_element_id=0,source_component_id=0,geometry_kind=0;
        Get_item(edge_source_element,edge_id,source_element_id);
        Get_item(edge_source_component,edge_id,source_component_id);
        Get_item(edge_geometry_kind,edge_id,geometry_kind);
        if(geometry_kind!=1)
        {
                    continue;
        }
        Element source;Text source_role="";
        if(Get_input_element(source_element_id,site,internal_strings,internal_count,source,source_role)!=0)continue;
        Segment source_segment;
        if(Get_segment(source,source_component_id,source_segment)!=0)continue;
        Point source_start,source_end;
        if(Get_start(source_segment,source_start)!=0||Get_end(source_segment,source_end)!=0)continue;
        Real sx=Get_x(source_start),sy=Get_y(source_start),ex=Get_x(source_end),ey=Get_y(source_end);
        Real vx=ex-sx,vy=ey-sy,len2=vx*vx+vy*vy;
        if(len2<=node_tolerance*node_tolerance)
        {
                    continue;
        }
        Real free_x=0.0,free_y=0.0;Get_item(node_x,free_node,free_x);Get_item(node_y,free_node,free_y);
        Real dstart2=(free_x-sx)*(free_x-sx)+(free_y-sy)*(free_y-sy);
        Real dend2=(free_x-ex)*(free_x-ex)+(free_y-ey)*(free_y-ey);
        Integer free_is_start=FALSE,free_is_end=FALSE;
        if(dstart2<=node_tolerance*node_tolerance)free_is_start=TRUE;
        else if(dend2<=node_tolerance*node_tolerance)free_is_end=TRUE;
        else
        {
            Print("STAGE4A1 UNDERSHOOT REJECTED free node not matching original source endpoint edge=");
            continue;
        }
        Integer target_element_id=0;
        for(target_element_id=1;target_element_id<=total_elements;target_element_id++)
        {
            Element target;Text target_role="";Integer target_segments=0,target_component_id=0;
            if(Get_input_element(target_element_id,site,internal_strings,internal_count,target,target_role)!=0)continue;
            if(Get_segments(target,target_segments)!=0)continue;
            for(target_component_id=1;target_component_id<=target_segments;target_component_id++)
            {
                if(target_element_id==source_element_id&&target_component_id==source_component_id)continue;
                Segment target_segment;
                if(Get_segment(target,target_component_id,target_segment)!=0)continue;
                Integer no_intersects=0;Point p1,p2;
                Integer istatus=Intersect_extended(source_segment,target_segment,no_intersects,p1,p2);
                if(istatus!=0||no_intersects<=0)continue;
                if(no_intersects>2)no_intersects=2;
                Real tx0=0.0,ty0=0.0,tz0=0.0,target_radius=0.0;Integer target_major=0;
                if(Get_super_data(target,target_component_id,tx0,ty0,tz0,target_radius,target_major)!=0)continue;
                Point target_start,target_end;
                if(Get_start(target_segment,target_start)!=0||Get_end(target_segment,target_end)!=0)continue;
                Real tax=Get_x(target_start),tay=Get_y(target_start),tbx=Get_x(target_end),tby=Get_y(target_end);
                Integer k=0;
                for(k=1;k<=no_intersects;k++)
                {
                    Point candidate=p1;if(k==2)candidate=p2;
                    Real ix=Get_x(candidate),iy=Get_y(candidate);
                    Real source_t=((ix-sx)*vx+(iy-sy)*vy)/len2;
                    Real source_length=Sqrt(len2);
                    /* source_t is dimensionless.  node_tolerance is an XY distance
                       and must never be used directly as a parameter tolerance.
                       Convert the XY tolerance to a source-line parameter tolerance. */
                    Real source_parameter_tolerance=node_tolerance/source_length;
                    Real projected_x=sx+source_t*vx,projected_y=sy+source_t*vy;
                    Real line_error2=(ix-projected_x)*(ix-projected_x)+(iy-projected_y)*(iy-projected_y);
                    if(line_error2>node_tolerance*node_tolerance)continue;
                    if(source_t>=-source_parameter_tolerance&&
                       source_t<=1.0+source_parameter_tolerance)
                    {
                        continue;
                    }
                    Integer correct_direction=FALSE;
                    if(free_is_start==TRUE&&source_t<0.0-source_parameter_tolerance)correct_direction=TRUE;
                    if(free_is_end==TRUE&&source_t>1.0+source_parameter_tolerance)correct_direction=TRUE;
                    if(correct_direction!=TRUE)
                    {
                                            continue;
                    }
                    Integer finite_target=FALSE;Real target_t=0.0;
                    if(target_radius==0.0)
                        finite_target=Point_on_segment_parameter(ix,iy,tax,tay,tbx,tby,node_tolerance,target_t);
                    else
                    {
                        Real signed_radius=0.0,radial_error=0.0,sweep=0.0,travel=0.0;Integer reject_code=0;
                        finite_target=Arc_node_parameter(target_segment,ix,iy,node_tolerance,target_t,
                                                         signed_radius,reject_code,radial_error,sweep,travel);
                    }
                    if(finite_target!=TRUE)
                    {
                                            continue;
                    }
                    Real dx=ix-free_x,dy=iy-free_y,distance=Sqrt(dx*dx+dy*dy);
                    if(distance<=node_tolerance)
                    {
                                            continue;
                    }
                    if(distance>maximum_undershoot_extension)
                    {
                        continue;
                    }
                    Integer select=FALSE;
                    if(best_found!=TRUE)select=TRUE;
                    else if(distance<best_distance-tie_epsilon)select=TRUE;
                    else if(Absolute(distance-best_distance)<=tie_epsilon)
                    {
                        if(target_element_id<best_target_element)select=TRUE;
                        else if(target_element_id==best_target_element&&target_component_id<best_target_component)select=TRUE;
                        else if(target_element_id==best_target_element&&target_component_id==best_target_component)
                        {
                            if(ix<best_x-tie_epsilon)select=TRUE;
                            else if(Absolute(ix-best_x)<=tie_epsilon&&iy<best_y-tie_epsilon)select=TRUE;
                        }
                    }
                    if(select==TRUE)
                    {
                        best_found=TRUE;best_distance=distance;best_x=ix;best_y=iy;
                        best_source_element=source_element_id;best_source_component=source_component_id;
                        best_free_node=free_node;best_target_element=target_element_id;
                        best_target_component=target_component_id;
                    }
                }
            }
        }
    }
    if(best_found==TRUE)
    {
        if(Apply_line_undershoot_repair(best_source_element,best_source_component,best_free_node,
                                        site,internal_strings,internal_count,node_x,node_y,
                                        best_x,best_y,node_tolerance)!=TRUE)return(FALSE);
        repair_applied=TRUE;
    }
    return(TRUE);
}

Integer Run_stage_3_noding(Element site,Dynamic_Element &internal_strings,
                           Integer internal_count,Model output_model,Real output_level,
                           Real node_tolerance,Real arc_working_tolerance,Real minimum_segment_length,
                           Real maximum_undershoot_extension,
                           Integer &physical_output_created,
                           Integer &summary_polygons_created,
                           Integer &summary_polygons_with_holes,
                           Integer &summary_islands,
                           Integer &summary_dangles_removed,
                           Integer &summary_temporary_removed)
{
    Dynamic_Real node_x,node_y;
    Integer total_elements=internal_count+1;
    Integer ea,eb,sa,sb,nsa,nsb;
    Integer original_endpoint_hits=0,intersection_hits=0;
    Integer overlap_pairs=0,overlap_resolved=0,overlap_unresolved=0;
    Integer overlap_endpoint_hits=0,identical_overlap_pairs=0,created=FALSE;
    physical_output_created=0;
    summary_polygons_created=0;
    summary_polygons_with_holes=0;
    summary_islands=0;
    summary_dangles_removed=0;
    summary_temporary_removed=0;


    /* Pass 1: canonicalise every original component endpoint. */
    for(ea=1;ea<=total_elements;ea++)
    {
        Element element_a;Text role_a="";
        if(Get_input_element(ea,site,internal_strings,internal_count,element_a,role_a)!=0)continue;
        if(Get_segments(element_a,nsa)!=0)continue;
        for(sa=1;sa<=nsa;sa++)
        {
            Segment seg_a;Point ap,bp;
            if(Get_segment(element_a,sa,seg_a)!=0)continue;
            if(Get_start(seg_a,ap)!=0||Get_end(seg_a,bp)!=0)continue;
            Find_or_add_node(node_x,node_y,Get_x(ap),Get_y(ap),node_tolerance,created);
            original_endpoint_hits++;
            Find_or_add_node(node_x,node_y,Get_x(bp),Get_y(bp),node_tolerance,created);
            original_endpoint_hits++;
        }
    }

    /* Pass 2: add intersections from the NATIVE Segment geometry.
       Patch:
       - Intersect() is used instead of endpoint-chord intersection.
       - Arc pairs bypass chord-only bbox rejection.
       - A node is canonicalised only after native intersection succeeds.
       This prevents false arc-chord nodes (e.g. node 31) from splitting
       unrelated line geometry and prevents true arc crossings from being
       missed because they lie outside the endpoint-chord bbox. */
    for(ea=1;ea<=total_elements;ea++)
    {
        Element element_a;Text role_a="";
        if(Get_input_element(ea,site,internal_strings,internal_count,element_a,role_a)!=0)continue;
        if(Get_segments(element_a,nsa)!=0)continue;

        for(sa=1;sa<=nsa;sa++)
        {
            Segment seg_a;Point ap,bp;
            if(Get_segment(element_a,sa,seg_a)!=0)continue;
            if(Get_start(seg_a,ap)!=0||Get_end(seg_a,bp)!=0)continue;

            Real ax=Get_x(ap),ay=Get_y(ap),bx=Get_x(bp),by=Get_y(bp);
            Real arv=0.0,axz=0.0,ayz=0.0,azz=0.0;
            Integer amajor=0;
            Get_super_data(element_a,sa,axz,ayz,azz,arv,amajor);

            for(eb=ea;eb<=total_elements;eb++)
            {
                Element element_b;Text role_b="";
                if(Get_input_element(eb,site,internal_strings,internal_count,element_b,role_b)!=0)continue;
                if(Get_segments(element_b,nsb)!=0)continue;

                Integer first_sb=1;
                if(eb==ea)first_sb=sa+1;

                for(sb=first_sb;sb<=nsb;sb++)
                {
                    if(ea==eb&&sb==sa+1)continue;

                    Segment seg_b;Point cp,dp;
                    if(Get_segment(element_b,sb,seg_b)!=0)continue;
                    if(Get_start(seg_b,cp)!=0||Get_end(seg_b,dp)!=0)continue;

                    Real cx=Get_x(cp),cy=Get_y(cp),dx=Get_x(dp),dy=Get_y(dp);
                    Real brv=0.0,bxz=0.0,byz=0.0,bzz=0.0;
                    Integer bmajor=0;
                    Get_super_data(element_b,sb,bxz,byz,bzz,brv,bmajor);

                    /* Signature: Integer Intersect(Segment seg_1,Segment seg_2,
                       Integer &no_intersects,Point &p1,Point &p2)
                       Manual: §5.27.4, ID 291. */
                    if(arv==0.0&&brv==0.0)
                    {
                        Real aminx=ax;if(bx<aminx)aminx=bx;
                        Real amaxx=ax;if(bx>amaxx)amaxx=bx;
                        Real aminy=ay;if(by<aminy)aminy=by;
                        Real amaxy=ay;if(by>amaxy)amaxy=by;
                        Real bminx=cx;if(dx<bminx)bminx=dx;
                        Real bmaxx=cx;if(dx>bmaxx)bmaxx=dx;
                        Real bminy=cy;if(dy<bminy)bminy=dy;
                        Real bmaxy=cy;if(dy>bmaxy)bmaxy=dy;

                        if(amaxx<bminx-node_tolerance||bmaxx<aminx-node_tolerance||
                           amaxy<bminy-node_tolerance||bmaxy<aminy-node_tolerance)
                            continue;
                    }

                    Integer no_intersects=0;
                    Point p1,p2;
                    Integer istatus=Intersect(seg_a,seg_b,no_intersects,p1,p2);
                    if(istatus!=0)continue;
                    if(no_intersects<=0)continue;
                    if(no_intersects>2)no_intersects=2;

                    Integer k;
                    for(k=1;k<=no_intersects;k++)
                    {
                        Point ip=p1;
                        if(k==2)ip=p2;

                        Real ix=Get_x(ip),iy=Get_y(ip);

                        /* Final native geometry guards.  These are intentionally
                           applied before Find_or_add_node(), so a candidate cannot
                           contaminate the global node set unless it belongs to
                           both native components. */
                        Real ta=0.0,tb=0.0;
                        Integer on_a=FALSE,on_b=FALSE;
                        if(arv==0.0)
                            on_a=Point_on_segment_parameter(ix,iy,ax,ay,bx,by,node_tolerance,ta);
                        else
                        {
                            Real sr=0.0,reject=0.0,sweep=0.0,travel=0.0;
                            Integer reject_code=0;
                            on_a=Arc_node_parameter(seg_a,ix,iy,node_tolerance,ta,sr,
                                                     reject_code,reject,sweep,travel);
                        }

                        if(brv==0.0)
                            on_b=Point_on_segment_parameter(ix,iy,cx,cy,dx,dy,node_tolerance,tb);
                        else
                        {
                            Real sr2=0.0,reject2=0.0,sweep2=0.0,travel2=0.0;
                            Integer reject_code2=0;
                            on_b=Arc_node_parameter(seg_b,ix,iy,node_tolerance,tb,sr2,
                                                     reject_code2,reject2,sweep2,travel2);
                        }

                        if(on_a!=TRUE||on_b!=TRUE)continue;

                        Integer node_id=Find_or_add_node(node_x,node_y,ix,iy,
                                                         node_tolerance,created);
                        intersection_hits++;

                    }
                }
            }
        }
    }

    Integer canonical_count=0;
    Get_number_of_items(node_x,canonical_count);

    /* Stage 3F.1: audit canonical-node attachment immediately before
       existing line/arc subsection generation. */
/* Stage 3G — GLOBAL NODE RE-ATTACHMENT + SPLIT PASS
   Every canonical node is tested against every source component only after
   the complete node registry exists.  The split list stores (t,nodeId)
   pairs so the physical piece endpoints are the canonical node coordinates.
*/
    Integer noded_edges=0,small_edges=0,duplicate_edges=0;
    Dynamic_Integer edge_from,edge_to;
    Dynamic_Integer edge_source_element,edge_source_component,edge_geometry_kind;
    Dynamic_Real edge_signed_radius;
    Dynamic_Integer edge_arc_major;
    Dynamic_Integer edge_segment_colour;
    Dynamic_Real edge_weight;
    Dynamic_Real edge_arc_centre_x,edge_arc_centre_y;
    Dynamic_Element edge_geometry;


    for(ea=1;ea<=total_elements;ea++)
    {
        Element element_a;Text role_a="";
        if(Get_input_element(ea,site,internal_strings,internal_count,element_a,role_a)!=0)continue;
        if(Get_segments(element_a,nsa)!=0)continue;

        for(sa=1;sa<=nsa;sa++)
        {
            Segment seg_a;Point ap,bp;
            if(Get_segment(element_a,sa,seg_a)!=0)continue;
            if(Get_start(seg_a,ap)!=0||Get_end(seg_a,bp)!=0)continue;

            Real ax=Get_x(ap),ay=Get_y(ap),bx=Get_x(bp),by=Get_y(bp);
            Real svx=0.0,svy=0.0,svz=0.0,source_radius=0.0;
            Integer source_major=0;
            Integer source_segment_colour=0;
            Integer source_uses_segment_colour=0;
            Real source_weight=0.0;
            Get_super_data(element_a,sa,svx,svy,svz,source_radius,source_major);
            Integer use_colour_status=Get_super_use_segment_colour(element_a,source_uses_segment_colour);
            Integer source_colour_status=-1;
            if(use_colour_status==0&&source_uses_segment_colour==1)
                source_colour_status=Get_super_segment_colour(element_a,sa,source_segment_colour);
            if(source_colour_status!=0)
                source_colour_status=Get_colour(element_a,source_segment_colour);
            if(source_colour_status!=0)source_segment_colour=0;
            if(Get_weight(element_a,source_weight)!=0)source_weight=0.0;

            Dynamic_Real parameters;
            Dynamic_Integer parameter_nodes;
            Integer ni;

            /* Global re-attachment: canonical registry is complete now. */
            for(ni=1;ni<=canonical_count;ni++)
            {
                Real nx=0.0,ny=0.0,t=0.0;
                Get_item(node_x,ni,nx);Get_item(node_y,ni,ny);

                Integer on_component=FALSE;
                Real arc_signed_radius=0.0;
                Integer arc_reject_code=0;
                Real radial_error=0.0,arc_sweep=0.0,arc_travel=0.0;

                if(source_radius==0.0)
                    on_component=Point_on_segment_parameter(
                        nx,ny,ax,ay,bx,by,node_tolerance,t);
                else
                    on_component=Arc_node_parameter(
                        seg_a,nx,ny,node_tolerance,t,arc_signed_radius,
                        arc_reject_code,radial_error,arc_sweep,arc_travel);

                if(on_component==TRUE)
                {
                    Integer pc=0,pj,exists=FALSE;
                    Get_number_of_items(parameters,pc);

                    Real parameter_tolerance=node_tolerance;
                    if(source_radius==0.0)
                    {
                        Real component_length=Sqrt((bx-ax)*(bx-ax)+(by-ay)*(by-ay));
                        if(component_length>0.0)
                            parameter_tolerance=node_tolerance/component_length;
                    }
                    else if(Absolute(source_radius)>node_tolerance)
                        parameter_tolerance=node_tolerance/Absolute(source_radius);

                    for(pj=1;pj<=pc;pj++)
                    {
                        Real oldt=0.0;
                        Get_item(parameters,pj,oldt);
                        if(Absolute(oldt-t)<=parameter_tolerance)
                        {
                            exists=TRUE;

                            /* Prefer an exact endpoint node over a near-end
                               intersection node when both occupy the same
                               parameter location. */
                            if((t<=parameter_tolerance&&
                                oldt>parameter_tolerance)||
                               (t>=1.0-parameter_tolerance&&
                                oldt<1.0-parameter_tolerance))
                            {
                                Set_item(parameters,pj,t);
                                Set_item(parameter_nodes,pj,ni);
                            }
                            break;
                        }
                    }

                    if(exists==FALSE)
                    {
                        Set_item(parameters,pc+1,t);
                        Set_item(parameter_nodes,pc+1,ni);
                    }

                }
            }

            Integer pc=0;
            Get_number_of_items(parameters,pc);

            
            

            /* Paired insertion sort: never separate node ID from its t. */
            Integer a,b;
            for(a=2;a<=pc;a++)
            {
                Real key=0.0;
                Integer key_node=0;
                Get_item(parameters,a,key);
                Get_item(parameter_nodes,a,key_node);
                b=a-1;
                while(b>=1)
                {
                    Real prev=0.0;
                    Get_item(parameters,b,prev);
                    if(prev<=key)break;
                    Set_item(parameters,b+1,prev);
                    Integer prev_node=0;
                    Get_item(parameter_nodes,b,prev_node);
                    Set_item(parameter_nodes,b+1,prev_node);
                    b--;
                }
                Set_item(parameters,b+1,key);
                Set_item(parameter_nodes,b+1,key_node);
            }

            /* Merge adjacent near-duplicate parameters while retaining the
               canonical node identity. */
            if(pc>1)
            {
                Integer write=1;
                for(a=2;a<=pc;a++)
                {
                    Real prev=0.0,current=0.0;
                    Integer prev_node=0,current_node=0;
                    Get_item(parameters,write,prev);
                    Get_item(parameters,a,current);
                    Get_item(parameter_nodes,write,prev_node);
                    Get_item(parameter_nodes,a,current_node);

                    Real merge_tol=node_tolerance;
                    if(source_radius==0.0)
                    {
                        Real component_length=Sqrt((bx-ax)*(bx-ax)+(by-ay)*(by-ay));
                        if(component_length>0.0)
                            merge_tol=node_tolerance/component_length;
                    }
                    else if(Absolute(source_radius)>node_tolerance)
                        merge_tol=node_tolerance/Absolute(source_radius);

                    if(Absolute(current-prev)<=merge_tol)
                    {
                        /* Prefer the node closer to the current canonical
                           endpoint when this is an endpoint duplicate. */
                        if(current<=merge_tol||current>=1.0-merge_tol)
                        {
                            Set_item(parameters,write,current);
                            Set_item(parameter_nodes,write,current_node);
                        }
                    }
                    else
                    {
                        write++;
                        Set_item(parameters,write,current);
                        Set_item(parameter_nodes,write,current_node);
                    }
                }

                /* Dynamic arrays cannot be explicitly truncated with an
                   unverified API; use 'write' as the authoritative count. */
                pc=write;
            }

            for(a=1;a<pc;a++)
            {
                Real t0=0.0,t1=0.0;
                Integer node0=0,node1=0;
                Get_item(parameters,a,t0);Get_item(parameters,a+1,t1);
                Get_item(parameter_nodes,a,node0);Get_item(parameter_nodes,a+1,node1);
                if(source_radius!=0.0)
                {
                }
                Real x0=0.0,y0=0.0,x1=0.0,y1=0.0;
                Get_item(node_x,node0,x0);Get_item(node_y,node0,y0);
                Get_item(node_x,node1,x1);Get_item(node_y,node1,y1);
                Real piece_radius=0.0;
                Real piece_centre_x=0.0,piece_centre_y=0.0;
                Integer piece_major=0;
                if(source_radius!=0.0)
                {
                    Arc native_arc;
                    if(Get_arc(seg_a,native_arc)==0)
                    {
                        Point centre=Get_centre(native_arc);
                        Point arc_start=Get_start(native_arc);
                        Point arc_end=Get_end(native_arc);
                        Real cx=Get_x(centre),cy=Get_y(centre);
                        piece_centre_x=cx;piece_centre_y=cy;
                        Real signed_r=Get_radius(native_arc);
                        Real radius=Absolute(signed_r);
                        Real a0=Atan2(Get_y(arc_start)-cy,Get_x(arc_start)-cx);
                        Real a1=Atan2(Get_y(arc_end)-cy,Get_x(arc_end)-cx);
                        Real sweep=0.0;
                        if(signed_r>0.0)sweep=Normalise_positive_angle(a0-a1);
                        else sweep=Normalise_positive_angle(a1-a0);
                        Real aa0=a0,aa1=a0;
                        /* Canonical node coordinates remain authoritative
                           for the physical split endpoints.  The native arc
                           is retained only for radius/major metadata. */
                        piece_radius=signed_r;
                        if(sweep*(t1-t0)>3.14159265358979323846)piece_major=1;
                    }
                }
                Real ddx=x1-x0,ddy=y1-y0;
                if(ddx*ddx+ddy*ddy<minimum_segment_length*minimum_segment_length){small_edges++;continue;}
                Integer c0=FALSE,c1=FALSE;
                Integer n0=Find_or_add_node(node_x,node_y,x0,y0,node_tolerance,c0);
                Integer n1=Find_or_add_node(node_x,node_y,x1,y1,node_tolerance,c1);
                Integer lo=n0,hi=n1;if(lo>hi){Integer swap=lo;lo=hi;hi=swap;}
                Integer ec=0,ei,isdup=FALSE;Get_number_of_items(edge_from,ec);
                for(ei=1;ei<=ec;ei++)
                {
                    Integer ef=0,et=0;Get_item(edge_from,ei,ef);Get_item(edge_to,ei,et);
                    if(ef==lo&&et==hi)isdup=TRUE;
                }
                if(isdup==TRUE)duplicate_edges++;
                else
                {
                    Set_item(edge_from,ec+1,lo);Set_item(edge_to,ec+1,hi);
                    Set_item(edge_source_element,ec+1,ea);
                    Set_item(edge_source_component,ec+1,sa);
                    Integer graph_kind=1;if(piece_radius!=0.0)graph_kind=2;
                    Set_item(edge_geometry_kind,ec+1,graph_kind);
                    Real canonical_radius=piece_radius;
                    if(n0>n1)canonical_radius=-canonical_radius;
                    Set_item(edge_signed_radius,ec+1,canonical_radius);
                    Set_item(edge_arc_major,ec+1,piece_major);
                    Set_item(edge_segment_colour,ec+1,source_segment_colour);
                    Set_item(edge_weight,ec+1,source_weight);
                    Set_item(edge_arc_centre_x,ec+1,piece_centre_x);
                    Set_item(edge_arc_centre_y,ec+1,piece_centre_y);
                    noded_edges++;
                    Element piece=Create_super(2,element_a);
                    Integer piece_status=-1;
                    if(Element_exists(piece)!=0)
                    {
                        piece_status=Set_super_data(piece,1,x0,y0,output_level,piece_radius,piece_major);
                        if(piece_status==0)piece_status=Set_super_data(piece,2,x1,y1,output_level,0.0,0);
                        if(piece_status==0)piece_status=Set_model(piece,output_model);
                        if(piece_status==0)
                        {
                            Text source_name="";Get_name(element_a,source_name);
                            Text kind="LINE";if(piece_radius!=0.0)kind="ARC";
                            Text piece_name=source_name+" - TOPOLOGY 2D "+To_text(ea-1)+
                                            " - "+kind+" PIECE "+To_text(physical_output_created+1);
                            if(ea==1)piece_name="SITE BOUNDARY - TOPOLOGY 2D - "+kind+
                                                " PIECE "+To_text(physical_output_created+1);
                            Set_name(piece,piece_name);
                            piece_status=Calc_extent(piece);
                            if(piece_status==0)
                            {
                                Set_item(edge_geometry,ec+1,piece);
                                Undo created_undo=Add_undo_add("Create Stage 4A graph geometry piece",piece);
                                physical_output_created++;
                            }
                        }
                    }
                }
            }
        }
    }

    /* Stage 4A manual planar graph construction.
       Each retained physical edge creates exactly two reverse directed edges.
       Stage 4A reports degree-1 nodes but does not remove them. */
    Integer graph_node_count=0,graph_edge_count=0;
    Get_number_of_items(node_x,graph_node_count);
    Get_number_of_items(edge_from,graph_edge_count);
    Output_line("DEBUG: Canonical topology graph");
    Print("  Original endpoint hits = ");Print(original_endpoint_hits);Print();
    Print("  Intersection hits = ");Print(intersection_hits);Print();
    Print("  Overlap pairs = ");Print(overlap_pairs);Print();
    Print("  Overlap resolved = ");Print(overlap_resolved);Print();
    Print("  Overlap unresolved = ");Print(overlap_unresolved);Print();
    Print("  Overlap endpoint hits = ");Print(overlap_endpoint_hits);Print();
    Print("  Identical overlap pairs = ");Print(identical_overlap_pairs);Print();
    Print("  Canonical nodes = ");Print(graph_node_count);Print();
    Print("  Noded physical edges = ");Print(graph_edge_count);Print();
    Print("  Noded edge pieces = ");Print(noded_edges);Print();
    Print("  Small edges skipped = ");Print(small_edges);Print();
    Print("  Duplicate edges detected = ");Print(duplicate_edges);Print();
    Dynamic_Integer node_degree,node_active,edge_active;
    Dynamic_Integer directed_from,directed_to,directed_reverse,directed_physical_edge,directed_active;
    Integer gi;
    for(gi=1;gi<=graph_node_count;gi++)
    { Set_item(node_degree,gi,0);Set_item(node_active,gi,TRUE); }
    for(gi=1;gi<=graph_edge_count;gi++)
    {
        Integer gf=0,gt=0,gd=0;
        Set_item(edge_active,gi,TRUE);
        Get_item(edge_from,gi,gf);Get_item(edge_to,gi,gt);
        Get_item(node_degree,gf,gd);Set_item(node_degree,gf,gd+1);
        Get_item(node_degree,gt,gd);Set_item(node_degree,gt,gd+1);
        Integer dab=2*gi-1,dba=2*gi;
        Set_item(directed_from,dab,gf);Set_item(directed_to,dab,gt);
        Set_item(directed_reverse,dab,dba);Set_item(directed_physical_edge,dab,gi);Set_item(directed_active,dab,TRUE);
        Set_item(directed_from,dba,gt);Set_item(directed_to,dba,gf);
        Set_item(directed_reverse,dba,dab);Set_item(directed_physical_edge,dba,gi);Set_item(directed_active,dba,TRUE);
        Integer se=0,sc=0,gk=0;Real gr=0.0;
        Get_item(edge_source_element,gi,se);Get_item(edge_source_component,gi,sc);
        Get_item(edge_geometry_kind,gi,gk);Get_item(edge_signed_radius,gi,gr);
    }
    Integer initial_dangle_count=0,isolated_node_count=0,max_degree=0,min_degree=-1;
    for(gi=1;gi<=graph_node_count;gi++)
    {
        Integer degree=0;Real gx=0.0,gy=0.0;
        Get_item(node_degree,gi,degree);Get_item(node_x,gi,gx);Get_item(node_y,gi,gy);
        if(min_degree<0||degree<min_degree)min_degree=degree;
        if(degree>max_degree)max_degree=degree;
        if(degree==0)isolated_node_count++;
        if(degree==1)
        {
            initial_dangle_count++;
        }
    }

    Output_line("DEBUG: Initial graph degree statistics");
    Print("  Initial degree-1 nodes = ");Print(initial_dangle_count);Print();
    Print("  Isolated nodes = ");Print(isolated_node_count);Print();
    Print("  Minimum degree = ");Print(min_degree);Print();
    Print("  Maximum degree = ");Print(max_degree);Print();
    Output_line("");

    /* Stage 4A.1 must run before any pruning or face construction.  A source
       endpoint edit invalidates canonical nodes, split pieces and every graph
       container, so this pass is deleted and the caller starts a fresh pass. */
    Integer stage4a1_repair_applied=FALSE;
    if(Run_stage_4A1_undershoot_repair(site,internal_strings,internal_count,
                                      edge_from,edge_to,edge_source_element,
                                      edge_source_component,edge_geometry_kind,
                                      edge_active,node_degree,node_x,node_y,
                                      maximum_undershoot_extension,node_tolerance,
                                      stage4a1_repair_applied)!=TRUE)
    {
        Print("STAGE4A1 UNDERSHOOT REJECTED repair stage failure");Print();
        return(FALSE);
    }
    if(stage4a1_repair_applied==TRUE)
    {
        Integer cleanup_deleted=0,cleanup_failures=0;
        if(Delete_temporary_topology_output(edge_geometry,
                                            cleanup_deleted,cleanup_failures)!=TRUE)
        {
            Print("STAGE4A1 UNDERSHOOT REJECTED topology pass cleanup failed");Print();
            return(FALSE);
        }
        summary_temporary_removed+=cleanup_deleted;
        physical_output_created=0;
        return(2); /* caller rebuilds canonical nodes in a fresh function scope */
    }

    /* Stage 4B iterative degree-1 pruning.  Physical geometry remains in the
       output model as diagnostic evidence; graph-active flags control all
       subsequent polygon-forming topology. */
    Integer dangle_iteration=0,total_dangle_edges_removed=0,removed_this_iteration=TRUE;
    while(removed_this_iteration==TRUE)
    {
        removed_this_iteration=FALSE;
        dangle_iteration++;
        for(gi=1;gi<=graph_node_count;gi++)Set_item(node_degree,gi,0);
        for(gi=1;gi<=graph_edge_count;gi++)
        {
            Integer active=FALSE,gf=0,gt=0,gd=0;
            Get_item(edge_active,gi,active);if(active!=TRUE)continue;
            Get_item(edge_from,gi,gf);Get_item(edge_to,gi,gt);
            Get_item(node_degree,gf,gd);Set_item(node_degree,gf,gd+1);
            Get_item(node_degree,gt,gd);Set_item(node_degree,gt,gd+1);
        }
        Integer iteration_removed=0;
        Integer gn;
        for(gn=1;gn<=graph_node_count;gn++)
        {
            Integer degree=0;Get_item(node_degree,gn,degree);if(degree!=1)continue;
            Integer ge;
            for(ge=1;ge<=graph_edge_count;ge++)
            {
                Integer active=FALSE,gf=0,gt=0;
                Get_item(edge_active,ge,active);if(active!=TRUE)continue;
                Get_item(edge_from,ge,gf);Get_item(edge_to,ge,gt);
                if(gf!=gn&&gt!=gn)continue;
                Set_item(edge_active,ge,FALSE);
                Set_item(directed_active,2*ge-1,FALSE);
                Set_item(directed_active,2*ge,FALSE);
                iteration_removed++;total_dangle_edges_removed++;removed_this_iteration=TRUE;
                Integer other=gf;if(other==gn)other=gt;
                Integer se=0,sc=0,gk=0;Real gr=0.0,gx=0.0,gy=0.0;
                Get_item(edge_source_element,ge,se);Get_item(edge_source_component,ge,sc);
                Get_item(edge_geometry_kind,ge,gk);Get_item(edge_signed_radius,ge,gr);
                Get_item(node_x,gn,gx);Get_item(node_y,gn,gy);
                break;
            }
        }
    }
    /* Final active degrees and counts after the stable empty iteration. */
    for(gi=1;gi<=graph_node_count;gi++)Set_item(node_degree,gi,0);
    Integer final_active_edge_count=0,final_active_directed_count=0,final_dangle_count=0,final_active_node_count=0;
    for(gi=1;gi<=graph_edge_count;gi++)
    {
        Integer active=FALSE,gf=0,gt=0,gd=0;
        Get_item(edge_active,gi,active);if(active!=TRUE)continue;
        final_active_edge_count++;
        Get_item(edge_from,gi,gf);Get_item(edge_to,gi,gt);
        Get_item(node_degree,gf,gd);Set_item(node_degree,gf,gd+1);
        Get_item(node_degree,gt,gd);Set_item(node_degree,gt,gd+1);
    }
    for(gi=1;gi<=graph_edge_count*2;gi++)
    { Integer active=FALSE;Get_item(directed_active,gi,active);if(active==TRUE)final_active_directed_count++; }
    for(gi=1;gi<=graph_node_count;gi++)
    {
        Integer degree=0;Get_item(node_degree,gi,degree);
        if(degree>0)final_active_node_count++;
        else Set_item(node_active,gi,FALSE);
        if(degree==1)final_dangle_count++;
    }

    Output_line("DEBUG: Stage 4B dangle pruning");
    Print("  Dangle iterations = ");Print(dangle_iteration);Print();
    Print("  Total physical edges removed from active graph = ");Print(total_dangle_edges_removed);Print();
    Print("  Final active edges = ");Print(final_active_edge_count);Print();
    Print("  Final active directed edges = ");Print(final_active_directed_count);Print();
    Print("  Final active nodes = ");Print(final_active_node_count);Print();
    Print("  Final degree-1 nodes = ");Print(final_dangle_count);Print();
    Output_line("");

    /* Stage 4C physical dangle deletion.
       Stage 4B has already marked every degree-1 edge inactive.  The
       corresponding physical element is stored in edge_geometry, so delete
       exactly those inactive physical pieces.  Cut edges are not present
       here because Stage 4C operates only on edges deactivated by Stage 4B. */
    Integer physical_dangles_deleted=0,physical_delete_failures=0;
    for(gi=1;gi<=graph_edge_count;gi++)
    {
        Integer active=FALSE;
        Get_item(edge_active,gi,active);
        if(active==TRUE)continue;

        Element dangling_piece;
        Get_item(edge_geometry,gi,dangling_piece);
        Integer delete_status=Element_delete(dangling_piece);
        if(delete_status==0)
        {
            physical_dangles_deleted++;
            Integer se=0,sc=0,gf=0,gt=0;
            Get_item(edge_source_element,gi,se);
            Get_item(edge_source_component,gi,sc);
            Get_item(edge_from,gi,gf);
            Get_item(edge_to,gi,gt);
        }
        else
        {
            physical_delete_failures++;
            Print("PHYSICAL DANGLE DELETE FAILED edge=");Print(gi);
        }
    }

    Output_line("DEBUG: Stage 4C physical cleanup");
    Print("  Physical dangles deleted = ");Print(physical_dangles_deleted);Print();
    Print("  Physical delete failures = ");Print(physical_delete_failures);Print();
    Output_line("");

    /* Stage 4D — bridge / cut-edge detection.
       Manual iterative DFS using discovery and low-link values.
       A tree edge (u,v) is a bridge when low[v] > disc[u].
       Bridge geometry remains available to the topology pass; only
       polygon-forming graph flags are deactivated. */

    Dynamic_Integer bridge_disc,bridge_low,bridge_parent_node,bridge_parent_edge;
    Dynamic_Integer bridge_scan,bridge_stack;
    Integer bridge_time=0,bridge_top=0,bridge_count=0;

    for(gi=1;gi<=graph_node_count;gi++)
    {
        Set_item(bridge_disc,gi,0);
        Set_item(bridge_low,gi,0);
        Set_item(bridge_parent_node,gi,0);
        Set_item(bridge_parent_edge,gi,0);
        Set_item(bridge_scan,gi,1);
    }

    Integer root;
    for(root=1;root<=graph_node_count;root++)
    {
        Integer root_degree=0;
        Get_item(node_degree,root,root_degree);
        if(root_degree==0)continue;

        Integer root_disc=0;
        Get_item(bridge_disc,root,root_disc);
        if(root_disc!=0)continue;

        bridge_time++;
        Set_item(bridge_disc,root,bridge_time);
        Set_item(bridge_low,root,bridge_time);
        Set_item(bridge_parent_node,root,0);
        Set_item(bridge_parent_edge,root,0);

        bridge_top++;
        Set_item(bridge_stack,bridge_top,root);

        while(bridge_top>0)
        {
            Integer u=0;
            Get_item(bridge_stack,bridge_top,u);

            Integer scan=0;
            Get_item(bridge_scan,u,scan);
            Integer found_edge=0;

            while(scan<=graph_edge_count)
            {
                Integer active_edge=FALSE;
                Get_item(edge_active,scan,active_edge);
                if(active_edge==TRUE)
                {
                    Integer ef=0,et=0;
                    Get_item(edge_from,scan,ef);
                    Get_item(edge_to,scan,et);
                    if(ef==u||et==u)
                    {
                        found_edge=scan;
                        scan++;
                        Set_item(bridge_scan,u,scan);
                        break;
                    }
                }
                scan++;
            }

            if(found_edge==0)
            {
                /* Finish u.  Propagate low-link information to its
                   DFS parent and classify the parent tree edge. */
                bridge_top--;

                Integer parent_node=0,parent_edge=0;
                Get_item(bridge_parent_node,u,parent_node);
                Get_item(bridge_parent_edge,u,parent_edge);

                if(parent_node!=0&&parent_edge!=0)
                {
                    Integer parent_low=0,child_low=0,parent_disc=0;
                    Get_item(bridge_low,parent_node,parent_low);
                    Get_item(bridge_low,u,child_low);
                    if(child_low<parent_low)
                        Set_item(bridge_low,parent_node,child_low);

                    Get_item(bridge_disc,parent_node,parent_disc);

                    if(child_low>parent_disc)
                    {
                        Integer already_active=FALSE;
                        Get_item(edge_active,parent_edge,already_active);
                        if(already_active==TRUE)
                        {
                            Set_item(edge_active,parent_edge,FALSE);

                            Integer de1=2*parent_edge-1;
                            Integer de2=2*parent_edge;
                            Set_item(directed_active,de1,FALSE);
                            Set_item(directed_active,de2,FALSE);

                            bridge_count++;

                            Integer bf=0,bt=0,bse=0,bsc=0,bkind=0;
                            Get_item(edge_from,parent_edge,bf);
                            Get_item(edge_to,parent_edge,bt);
                            Get_item(edge_source_element,parent_edge,bse);
                            Get_item(edge_source_component,parent_edge,bsc);
                            Get_item(edge_geometry_kind,parent_edge,bkind);

                        }
                    }
                }
                continue;
            }

            Integer ef=0,et=0,v=0;
            Get_item(edge_from,found_edge,ef);
            Get_item(edge_to,found_edge,et);
            if(ef==u)v=et;
            else v=ef;

            Integer v_disc=0;
            Get_item(bridge_disc,v,v_disc);

            if(v_disc==0)
            {
                Set_item(bridge_parent_node,v,u);
                Set_item(bridge_parent_edge,v,found_edge);
                bridge_time++;
                Set_item(bridge_disc,v,bridge_time);
                Set_item(bridge_low,v,bridge_time);
                Set_item(bridge_scan,v,1);

                bridge_top++;
                Set_item(bridge_stack,bridge_top,v);
            }
            else
            {
                Integer parent_edge_u=0;
                Get_item(bridge_parent_edge,u,parent_edge_u);
                if(found_edge!=parent_edge_u)
                {
                    Integer low_u=0;
                    Get_item(bridge_low,u,low_u);
                    if(v_disc<low_u)
                        Set_item(bridge_low,u,v_disc);
                }
            }
        }
    }

    Integer active_after_4d=0,active_directed_after_4d=0;
    for(gi=1;gi<=graph_edge_count;gi++)
    {
        Integer active=FALSE;
        Get_item(edge_active,gi,active);
        if(active==TRUE)active_after_4d++;
    }
    for(gi=1;gi<=graph_edge_count*2;gi++)
    {
        Integer active=FALSE;
        Get_item(directed_active,gi,active);
        if(active==TRUE)active_directed_after_4d++;
    }


    /* Stage 4E - identify active connected graph components. */
    Dynamic_Integer node_component,edge_component,component_stack;
    Integer component_count=0,component_top=0,component_node=0;
    for(gi=1;gi<=graph_node_count;gi++)Set_item(node_component,gi,0);
    for(gi=1;gi<=graph_edge_count;gi++)Set_item(edge_component,gi,0);
    for(component_node=1;component_node<=graph_node_count;component_node++)
    {
        Integer seed_degree=0,seed_component=0;
        Get_item(node_degree,component_node,seed_degree);
        Get_item(node_component,component_node,seed_component);
        if(seed_degree<=0||seed_component!=0)continue;
        component_count++;
        component_top=1;
        Set_item(component_stack,component_top,component_node);
        Set_item(node_component,component_node,component_count);
        while(component_top>0)
        {
            Integer u=0;Get_item(component_stack,component_top,u);component_top--;
            Integer ce=0;
            for(ce=1;ce<=graph_edge_count;ce++)
            {
                Integer active=FALSE,ef=0,et=0;
                Get_item(edge_active,ce,active);if(active!=TRUE)continue;
                Get_item(edge_from,ce,ef);Get_item(edge_to,ce,et);
                if(ef!=u&&et!=u)continue;
                Set_item(edge_component,ce,component_count);
                Integer v=ef;if(v==u)v=et;
                Integer vc=0;Get_item(node_component,v,vc);
                if(vc==0)
                {
                    Set_item(node_component,v,component_count);
                    component_top++;
                    Set_item(component_stack,component_top,v);
                }
            }
        }
    }
    Integer site_component_id=0;
    for(gi=1;gi<=graph_edge_count;gi++)
    {
        Integer active=FALSE,source_element_id=0,component_id_read=0;
        Get_item(edge_active,gi,active);if(active!=TRUE)continue;
        Get_item(edge_source_element,gi,source_element_id);if(source_element_id!=1)continue;
        Get_item(edge_component,gi,component_id_read);
        site_component_id=component_id_read;
        break;
    }
    /* Stage 5A — angular ordering of active outgoing directed edges.
       Atan2 is documented in the 12d Model Macro Manual (ID 7).
       Sort each node's active outgoing directed edges counter-clockwise.
       Tie-breakers: distance to destination, destination node ID,
       then directed-edge ID.  No next links are assigned in Stage 5A. */

    Dynamic_Real directed_angle;
    Dynamic_Real directed_distance2;
    Dynamic_Integer angular_rank;

    Integer directed_count=graph_edge_count*2;
    for(gi=1;gi<=directed_count;gi++)
    {
        Set_item(directed_angle,gi,0.0);
        Set_item(directed_distance2,gi,0.0);
        Set_item(angular_rank,gi,0);

        Integer de_active=FALSE;
        Get_item(directed_active,gi,de_active);
        if(de_active!=TRUE)continue;

        Integer df=0,dt=0;
        Real fx=0.0,fy=0.0,tx=0.0,ty=0.0;
        Get_item(directed_from,gi,df);
        Get_item(directed_to,gi,dt);
        Get_item(node_x,df,fx);
        Get_item(node_y,df,fy);
        Get_item(node_x,dt,tx);
        Get_item(node_y,dt,ty);

        Real dx=tx-fx,dy=ty-fy;
        Real d2=dx*dx+dy*dy;
        if(d2<=0.0)
        {
            continue;
        }

        Real angle=Atan2(dy,dx);
        if(angle<0.0)angle+=2.0*3.14159265358979323846;

        Set_item(directed_angle,gi,angle);
        Set_item(directed_distance2,gi,d2);
    }

    Dynamic_Integer sort_ids;
    Dynamic_Real sort_angles;
    Dynamic_Real sort_dist2;

    Integer stage5a_node_count=0;
    Integer stage5a_directed_count=0;

    for(gi=1;gi<=graph_node_count;gi++)
    {
        Integer node_degree_now=0;
        Get_item(node_degree,gi,node_degree_now);

        Integer local_count=0;
        Integer de;

        /* Build the local active outgoing list for this node. */
        for(de=1;de<=directed_count;de++)
        {
            Integer de_active=FALSE,df=0;
            Get_item(directed_active,de,de_active);
            if(de_active!=TRUE)continue;

            Get_item(directed_from,de,df);
            if(df!=gi)continue;

            local_count++;
            Set_item(sort_ids,local_count,de);

            Real a=0.0,d2=0.0;
            Get_item(directed_angle,de,a);
            Get_item(directed_distance2,de,d2);
            Set_item(sort_angles,local_count,a);
            Set_item(sort_dist2,local_count,d2);
        }

        if(local_count==0)continue;

        stage5a_node_count++;
        stage5a_directed_count+=local_count;

        /* Stable insertion sort.
           Primary key = CCW angle.
           Tie-breakers = destination distance, destination node ID,
           then directed-edge ID. */
        Integer pos;
        for(pos=2;pos<=local_count;pos++)
        {
            Integer key_id=0,key_dest=0;
            Real key_angle=0.0,key_dist2=0.0;
            Get_item(sort_ids,pos,key_id);
            Get_item(sort_angles,pos,key_angle);
            Get_item(sort_dist2,pos,key_dist2);
            Get_item(directed_to,key_id,key_dest);

            Integer j=pos-1;
            while(j>=1)
            {
                Integer cur_id=0,cur_dest=0;
                Real cur_angle=0.0,cur_dist2=0.0;
                Get_item(sort_ids,j,cur_id);
                Get_item(sort_angles,j,cur_angle);
                Get_item(sort_dist2,j,cur_dist2);
                Get_item(directed_to,cur_id,cur_dest);

                Integer move=FALSE;
                if(cur_angle>key_angle)
                    move=TRUE;
                else if(cur_angle==key_angle)
                {
                    if(cur_dist2>key_dist2)
                        move=TRUE;
                    else if(cur_dist2==key_dist2)
                    {
                        if(cur_dest>key_dest)
                            move=TRUE;
                        else if(cur_dest==key_dest&&cur_id>key_id)
                            move=TRUE;
                    }
                }

                if(move!=TRUE)break;

                Set_item(sort_ids,j+1,cur_id);
                Set_item(sort_angles,j+1,cur_angle);
                Set_item(sort_dist2,j+1,cur_dist2);
                j--;
            }

            Set_item(sort_ids,j+1,key_id);
            Set_item(sort_angles,j+1,key_angle);
            Set_item(sort_dist2,j+1,key_dist2);
        }

        for(pos=1;pos<=local_count;pos++)
        {
            Integer ordered_de=0,dest=0;
            Real ordered_angle=0.0;
            Get_item(sort_ids,pos,ordered_de);
            Get_item(sort_angles,pos,ordered_angle);
            Get_item(directed_to,ordered_de,dest);
            Set_item(angular_rank,ordered_de,pos);

        }
    }


    /* Stage 5B — assign planar face-traversal next links.
       For directed edge e = u -> v:
       1. reverse(e) is v -> u.
       2. At node v, find reverse(e)'s angular rank.
       3. Select the active outgoing edge immediately preceding
          reverse(e) in the CCW ordering, wrapping at rank 1.
       This stage only assigns graph next links; no geometry is changed. */

    Dynamic_Integer directed_next;
    for(gi=1;gi<=directed_count;gi++)Set_item(directed_next,gi,0);

    Integer stage5b_assigned=0;
    Integer stage5b_failed=0;

    for(gi=1;gi<=directed_count;gi++)
    {
        Integer de_active=FALSE;
        Get_item(directed_active,gi,de_active);
        if(de_active!=TRUE)continue;

        Integer destination=0;
        Integer reverse_de=0;
        Get_item(directed_to,gi,destination);
        Get_item(directed_reverse,gi,reverse_de);

        Integer reverse_rank=0;
        if(reverse_de>=1&&reverse_de<=directed_count)
            Get_item(angular_rank,reverse_de,reverse_rank);

        if(reverse_rank<=0)
        {
            Print("STAGE5B ERROR: reverse directed edge has no angular rank. edge=");
            stage5b_failed++;
            continue;
        }

        Integer destination_degree=0;
        Get_item(node_degree,destination,destination_degree);
        if(destination_degree<2)
        {
            Print("STAGE5B ERROR: active destination node has degree < 2. edge=");
            stage5b_failed++;
            continue;
        }

        Integer target_rank=reverse_rank+1;
        if(target_rank>destination_degree)target_rank=1;

        Integer next_de=0;
        Integer candidate_count=0;
        Integer de=0;

        /* Find the active outgoing directed edge at destination
           carrying the required angular rank. */
        for(de=1;de<=directed_count;de++)
        {
            Integer candidate_active=FALSE,candidate_from=0,candidate_rank=0;
            Get_item(directed_active,de,candidate_active);
            if(candidate_active!=TRUE)continue;

            Get_item(directed_from,de,candidate_from);
            if(candidate_from!=destination)continue;

            Get_item(angular_rank,de,candidate_rank);
            if(candidate_rank!=target_rank)continue;

            next_de=de;
            candidate_count++;
        }

        if(candidate_count!=1||next_de==0)
        {
            Print("STAGE5B ERROR: next-edge candidate count=");
            stage5b_failed++;
            continue;
        }

        Set_item(directed_next,gi,next_de);
        stage5b_assigned++;

    }


    /* Stage 5C — trace candidate rings using Stage 5B next links.
       Integer_Set stores directed-edge IDs already visited by a trace.
       A ring is accepted here only when traversal returns to its own
       starting directed edge. No geometry is changed in this stage. */

    Integer_Set stage5c_visited;
    Integer stage5c_candidate_rings=0;
    Integer stage5c_trace_failures=0;
    Integer stage5c_edges_traced=0;
    Integer stage5c_max_steps=directed_count+1;

    for(gi=1;gi<=directed_count;gi++)
    {
        Integer start_active=FALSE;
        Get_item(directed_active,gi,start_active);
        if(start_active!=TRUE)continue;

        Integer insert_result=Container_insert_key(stage5c_visited,gi);
        if(insert_result==1)continue;

        Integer start_de=gi;
        Integer current_de=gi;
        Integer steps=0;
        Integer closed=FALSE;
        Integer failed=FALSE;


        while(TRUE)
        {
            steps++;
            stage5c_edges_traced++;

            Integer physical_edge=0;
            Integer from_node=0;
            Integer to_node=0;
            Get_item(directed_physical_edge,current_de,physical_edge);
            Get_item(directed_from,current_de,from_node);
            Get_item(directed_to,current_de,to_node);


            if(steps>stage5c_max_steps)
            {
                Print("STAGE5C ERROR: traversal exceeded guard. start=");
                failed=TRUE;
                break;
            }

            Integer next_de=0;
            Get_item(directed_next,current_de,next_de);

            if(next_de<1||next_de>directed_count)
            {
                Print("STAGE5C ERROR: invalid next link. start=");
                failed=TRUE;
                break;
            }

            Integer next_active=FALSE;
            Get_item(directed_active,next_de,next_active);
            if(next_active!=TRUE)
            {
                Print("STAGE5C ERROR: next link targets inactive directed edge. start=");
                failed=TRUE;
                break;
            }

            current_de=next_de;

            if(current_de==start_de)
            {
                closed=TRUE;
                break;
            }

            Integer next_insert_result=Container_insert_key(stage5c_visited,current_de);
            if(next_insert_result==1)
            {
                Print("STAGE5C ERROR: premature revisit. start=");
                failed=TRUE;
                break;
            }
        }

        if(closed==TRUE&&failed==FALSE)
        {
            stage5c_candidate_rings++;
        }
        else
        {
            stage5c_trace_failures++;
            Print("STAGE5C TRACE FAILED start=");
        }
    }


    /* Stage 5D — calculate signed XY area/orientation for each traced
       candidate ring and filter bounded faces by orientation and minimum
       face area. This stage does not modify graph or physical geometry.
       Standard shoelace convention:
         positive area = counter-clockwise
         negative area = clockwise
       The Stage 5B face walk keeps the bounded face on the right, so
       bounded faces are expected to be clockwise and the unbounded
       exterior face counter-clockwise. */

    Integer_Set stage5d_visited;
    Integer stage5d_ring_count=0;
    Integer stage5d_valid_faces=0;
    Integer stage5d_rejected_small=0;
    Integer stage5d_rejected_exterior=0;
    Integer stage5d_trace_failures=0;
    Integer stage5d_max_steps=directed_count+1;
    Real minimum_face_area=0.001;
    Dynamic_Integer component_exterior_start,component_exterior_steps;
    Dynamic_Real component_exterior_sample_x,component_exterior_sample_y;

    for(gi=1;gi<=directed_count;gi++)
    {
        Integer start_active=FALSE;
        Get_item(directed_active,gi,start_active);
        if(start_active!=TRUE)continue;

        Integer insert_result=Container_insert_key(stage5d_visited,gi);
        if(insert_result==1)continue;

        Integer start_de=gi;
        Integer current_de=gi;
        Integer steps=0;
        Integer closed=FALSE;
        Integer failed=FALSE;
        Real twice_area=0.0;

        while(TRUE)
        {
            steps++;

            if(steps>stage5d_max_steps)
            {
                Print("STAGE5D ERROR: traversal exceeded guard. start=");
                failed=TRUE;
                break;
            }

            Integer from_node=0;
            Integer to_node=0;
            Get_item(directed_from,current_de,from_node);
            Get_item(directed_to,current_de,to_node);

            Real fx=0.0,fy=0.0,tx=0.0,ty=0.0;
            Get_item(node_x,from_node,fx);
            Get_item(node_y,from_node,fy);
            Get_item(node_x,to_node,tx);
            Get_item(node_y,to_node,ty);

            twice_area += (fx*ty)-(tx*fy);

            Integer next_de=0;
            Get_item(directed_next,current_de,next_de);

            if(next_de<1||next_de>directed_count)
            {
                Print("STAGE5D ERROR: invalid next link. start=");
                failed=TRUE;
                break;
            }

            Integer next_active=FALSE;
            Get_item(directed_active,next_de,next_active);
            if(next_active!=TRUE)
            {
                Print("STAGE5D ERROR: next link targets inactive edge. start=");
                failed=TRUE;
                break;
            }

            current_de=next_de;

            if(current_de==start_de)
            {
                closed=TRUE;
                break;
            }

            Integer next_insert_result=Container_insert_key(stage5d_visited,current_de);
            if(next_insert_result==1)
            {
                Print("STAGE5D ERROR: premature revisit. start=");
                failed=TRUE;
                break;
            }
        }

        if(closed!=TRUE||failed!=FALSE)
        {
            stage5d_trace_failures++;
            continue;
        }

        Real signed_area=twice_area/2.0;
        Real abs_area=Absolute(signed_area);
        Text orientation="DEGENERATE";

        if(signed_area>0.0)
            orientation="COUNTER-CLOCKWISE";
        else if(signed_area<0.0)
            orientation="CLOCKWISE";

        stage5d_ring_count++;

        Integer bounded_candidate=FALSE;
        Integer rejected_small=FALSE;

        if(abs_area<minimum_face_area)
        {
            rejected_small=TRUE;
            stage5d_rejected_small++;
        }
        else if(signed_area<0.0)
        {
            bounded_candidate=TRUE;
            stage5d_valid_faces++;
        }
        else
        {
            stage5d_rejected_exterior++;
            Integer first_physical=0,ring_component=0;
            Get_item(directed_physical_edge,start_de,first_physical);
            Get_item(edge_component,first_physical,ring_component);
            if(ring_component>0)
            {
                Dynamic_Real exterior_ring_x,exterior_ring_y;
                Integer exterior_ring_count=0;
                Integer exterior_ring_ok=Build_face_ring_from_start(
                    start_de,directed_next,directed_from,node_x,node_y,
                    stage5d_max_steps,exterior_ring_x,exterior_ring_y,exterior_ring_count);
                if(exterior_ring_ok==TRUE)
                {
                    Real exterior_sample_x=0.0,exterior_sample_y=0.0;
                    Integer exterior_sample_ok=Find_face_representative_point(
                        exterior_ring_x,exterior_ring_y,exterior_ring_count,
                        signed_area,node_tolerance,exterior_sample_x,exterior_sample_y);
                    if(exterior_sample_ok==TRUE)
                    {
                        Integer old_start=0;
                        Get_item(component_exterior_start,ring_component,old_start);
                        if(old_start==0)
                        {
                            Set_item(component_exterior_start,ring_component,start_de);
                            Set_item(component_exterior_steps,ring_component,steps);
                            Set_item(component_exterior_sample_x,ring_component,exterior_sample_x);
                            Set_item(component_exterior_sample_y,ring_component,exterior_sample_y);
                        }
                    }
                }
            }
        }


        if(rejected_small==TRUE)
        {
            /* Diagnostic classification output removed in production build. */
        }
        else if(bounded_candidate==TRUE)
        {
            /* Diagnostic classification output removed in production build. */
        }
        else
        {
            /* Diagnostic classification output removed in production build. */
        }

    }

    /* Stage 5F - site filtering; Stage 5G - containment hierarchy. */
    Integer stage5e_output_faces=0,stage5e_output_failures=0;
    Integer stage5f_faces_tested=0,stage5f_faces_inside_site=0;
    Integer stage5f_face_outside_site=0,stage5f_pip_failures=0;
    Dynamic_Real site_pip_x,site_pip_y;Integer site_pip_count=0;
    Integer site_ready=Build_site_pip_ring(site,arc_working_tolerance,node_tolerance,site_pip_x,site_pip_y,site_pip_count);
    
    
    Dynamic_Integer accepted_start,accepted_steps,accepted_component;
    Dynamic_Real accepted_area,accepted_sample_x,accepted_sample_y;
    Integer accepted_count=0;
    Integer_Set output_visited;
    for(gi=1;gi<=directed_count;gi++)
    {
        Integer active=FALSE;Get_item(directed_active,gi,active);if(active!=TRUE)continue;
        if(Container_insert_key(output_visited,gi)==1)continue;
        Integer start_de=gi,current_de=gi,steps=0,closed=FALSE,failed=FALSE;Real twice_area=0.0;
        Dynamic_Real face_x,face_y;
        while(steps<=stage5d_max_steps)
        {
            Integer fn=0,tn=0;Get_item(directed_from,current_de,fn);Get_item(directed_to,current_de,tn);
            Real fx=0.0,fy=0.0,tx=0.0,ty=0.0;
            Get_item(node_x,fn,fx);Get_item(node_y,fn,fy);Get_item(node_x,tn,tx);Get_item(node_y,tn,ty);
            steps++;Set_item(face_x,steps,fx);Set_item(face_y,steps,fy);twice_area+=fx*ty-tx*fy;
            Integer next_de=0;Get_item(directed_next,current_de,next_de);
            if(next_de<1||next_de>directed_count){failed=TRUE;break;}
            current_de=next_de;if(current_de==start_de){closed=TRUE;break;}
            if(Container_insert_key(output_visited,current_de)==1){failed=TRUE;break;}
        }
        if(closed!=TRUE||failed==TRUE||steps<3)continue;
        Real signed_area=twice_area/2.0;if(Absolute(signed_area)<minimum_face_area||signed_area>=0.0)continue;
        stage5f_faces_tested++;
        Real sample_x=0.0,sample_y=0.0;
        if(site_ready!=TRUE||Find_face_representative_point(face_x,face_y,steps,signed_area,node_tolerance,sample_x,sample_y)!=TRUE)
        
        Integer site_class=Manual_point_in_ring(site_pip_x,site_pip_y,site_pip_count,sample_x,sample_y,node_tolerance);
        if(site_class!=1)
        
        stage5f_faces_inside_site++;accepted_count++;
        Integer accepted_physical=0,accepted_component_id=0;
        Get_item(directed_physical_edge,start_de,accepted_physical);
        Get_item(edge_component,accepted_physical,accepted_component_id);
        Set_item(accepted_start,accepted_count,start_de);Set_item(accepted_steps,accepted_count,steps);
        Set_item(accepted_component,accepted_count,accepted_component_id);
        Set_item(accepted_area,accepted_count,Absolute(signed_area));Set_item(accepted_sample_x,accepted_count,sample_x);Set_item(accepted_sample_y,accepted_count,sample_y);
    }

    Integer stage5g_faces_processed=accepted_count,stage5g_containment_tests=0;
    Integer stage5g_containments_found=0,stage5g_root_faces=accepted_count;
    Integer stage5g_nested_faces=0,stage5g_failures=0;
    Dynamic_Integer stage5g_parent,stage5g_depth,component_container_face;
    Integer child=0;
    /* Atomic bounded faces remain output polygons. Only a disconnected
       component exterior ring can become a hole in another component. */
    for(child=1;child<=accepted_count;child++)
    {
        Set_item(stage5g_parent,child,0);
        Set_item(stage5g_depth,child,0);
    }
    Integer component_id=0;
    for(component_id=1;component_id<=component_count;component_id++)
    {
        if(component_id==site_component_id)continue;
        Integer exterior_start=0,exterior_steps=0;
        Real sample_x=0.0,sample_y=0.0;
        Get_item(component_exterior_start,component_id,exterior_start);
        Get_item(component_exterior_steps,component_id,exterior_steps);
        Get_item(component_exterior_sample_x,component_id,sample_x);
        Get_item(component_exterior_sample_y,component_id,sample_y);
        if(exterior_start<=0||exterior_steps<3)continue;
        Integer best_face=0;Real best_area=0.0;Integer candidate_face=0;
        for(candidate_face=1;candidate_face<=accepted_count;candidate_face++)
        {
            Integer face_component=0;
            Get_item(accepted_component,candidate_face,face_component);
            if(face_component==component_id)continue;
            Integer face_start=0;Real face_area=0.0;
            Get_item(accepted_start,candidate_face,face_start);
            Get_item(accepted_area,candidate_face,face_area);
            Dynamic_Real container_x,container_y;Integer rebuilt_count=0;
            Integer rebuild_ok=Build_face_ring_from_start(
                face_start,directed_next,directed_from,node_x,node_y,
                stage5d_max_steps,container_x,container_y,rebuilt_count);
            if(rebuild_ok!=TRUE){stage5g_failures++;continue;}
            stage5g_containment_tests++;
            Integer relation=Manual_point_in_ring(
                container_x,container_y,rebuilt_count,sample_x,sample_y,node_tolerance);
            if(relation==1)
            {
                if(best_face==0||face_area<best_area)
                {best_face=candidate_face;best_area=face_area;}
            }
            else if(relation<0)stage5g_failures++;
        }
        Set_item(component_container_face,component_id,best_face);
        if(best_face>0)stage5g_containments_found++;
    }
    /* Stage 5H classifies output eligibility. Stage 5M performs the only
       physical polygon creation so shell/island geometry is not duplicated. */
    Integer stage5h_shells_output=0,stage5h_holes_suppressed=0;
    Integer stage5h_invalid_depth=0,stage5h_output_failures=0;
    for(child=1;child<=accepted_count;child++)
    {
        Integer depth=0,start_id=0,steps=0;
        Real area=0.0;
        Get_item(stage5g_depth,child,depth);
        Get_item(accepted_start,child,start_id);
        Get_item(accepted_steps,child,steps);
        Get_item(accepted_area,child,area);
        if(depth<0)
        {
            stage5h_invalid_depth++;
            continue;
        }
        if(Mod(depth,2.0)!=0.0)
        {
            stage5h_holes_suppressed++;
            continue;
        }
        stage5h_shells_output++;
        
    }
    stage5e_output_faces=0;
    stage5e_output_failures=0;
    /* Stage 5I materialises the Stage 5G parent relationships as an explicit
       containment tree. This remains diagnostic and does not alter Stage 5H
       output decisions or source topology. */
    Dynamic_Integer stage5i_first_child,stage5i_next_sibling,stage5i_child_count;
    Integer stage5i_root_shells=0,stage5i_holes=0,stage5i_islands=0;
    Integer stage5i_max_depth=0,stage5i_tree_failures=0,stage5i_links=0;
    Integer face_id=0;
    for(face_id=1;face_id<=accepted_count;face_id++)
    {
        Set_item(stage5i_first_child,face_id,0);
        Set_item(stage5i_next_sibling,face_id,0);
        Set_item(stage5i_child_count,face_id,0);
    }
    /* Insert children in reverse face-ID order so sibling traversal is
       deterministic and reports children in ascending face-ID order. */
    for(face_id=accepted_count;face_id>=1;face_id--)
    {
        Integer parent_id=0,depth=0;
        Get_item(stage5g_parent,face_id,parent_id);
        Get_item(stage5g_depth,face_id,depth);
        if(depth<0)
        {
            stage5i_tree_failures++;
            Print("STAGE5I TREE FAILURE face=");Print(face_id);
            continue;
        }
        if(depth>stage5i_max_depth)stage5i_max_depth=depth;
        if(parent_id==0)
        {
            if(depth!=0)
            {
                stage5i_tree_failures++;
                Print("STAGE5I TREE FAILURE face=");Print(face_id);
            }
            else stage5i_root_shells++;
        }
        else
        {
            if(parent_id<1||parent_id>accepted_count||parent_id==face_id)
            {
                stage5i_tree_failures++;
                Print("STAGE5I TREE FAILURE face=");Print(face_id);
                continue;
            }
            Integer parent_depth=0;Get_item(stage5g_depth,parent_id,parent_depth);
            if(parent_depth+1!=depth)
            {
                stage5i_tree_failures++;
                Print("STAGE5I TREE FAILURE face=");Print(face_id);
            }
            Integer previous_first=0,parent_children=0;
            Get_item(stage5i_first_child,parent_id,previous_first);
            Get_item(stage5i_child_count,parent_id,parent_children);
            Set_item(stage5i_next_sibling,face_id,previous_first);
            Set_item(stage5i_first_child,parent_id,face_id);
            Set_item(stage5i_child_count,parent_id,parent_children+1);
            stage5i_links++;
        }
        if(Mod(depth,2.0)!=0.0)stage5i_holes++;
        else if(depth>0)stage5i_islands++;
    }
    for(face_id=1;face_id<=accepted_count;face_id++)
    {
        Integer parent_id=0,depth=0,first_child=0,child_count=0,start_id=0;
        Get_item(stage5g_parent,face_id,parent_id);
        Get_item(stage5g_depth,face_id,depth);
        Get_item(stage5i_first_child,face_id,first_child);
        Get_item(stage5i_child_count,face_id,child_count);
        Get_item(accepted_start,face_id,start_id);
        if(depth>=0)
        {
                    }
        Integer child_id=first_child,reported=0;
        while(child_id>0&&reported<=accepted_count)
        {
            Integer next_child=0;Get_item(stage5i_next_sibling,child_id,next_child);
            child_id=next_child;reported++;
        }
        if(reported>accepted_count)
        {
            stage5i_tree_failures++;
            Print("STAGE5I TREE FAILURE face=");Print(face_id);
        }
        else if(reported!=child_count)
        {
            stage5i_tree_failures++;
            Print("STAGE5I TREE FAILURE face=");Print(face_id);
        }
    }

    /* Stage 5K - materialise one stable topology record per accepted face.
       The record table uses verified Dynamic_Integer and Dynamic_Real lists.
       It does not write an external file and does not change geometry. */
    Dynamic_Integer record_face_id,record_start_edge,record_parent,record_depth;
    Dynamic_Integer record_class,record_first_child,record_child_count;
    Dynamic_Integer record_output_action,record_steps;
    Dynamic_Real record_area,record_sample_x,record_sample_y;
    Integer stage5k_records_created=0,stage5k_root_shell_records=0;
    Integer stage5k_hole_records=0,stage5k_island_records=0;
    Integer stage5k_output_records=0,stage5k_suppressed_records=0;
    Integer stage5k_export_failures=0,stage5k_max_depth=0;
    for(face_id=1;face_id<=accepted_count;face_id++)
    {
        Integer start_id=0,parent_id=0,depth=0,first_child=0,child_count=0,steps=0;
        Real area=0.0,sample_x=0.0,sample_y=0.0;
        Get_item(accepted_start,face_id,start_id);
        Get_item(accepted_steps,face_id,steps);
        Get_item(accepted_area,face_id,area);
        Get_item(accepted_sample_x,face_id,sample_x);
        Get_item(accepted_sample_y,face_id,sample_y);
        Get_item(stage5g_parent,face_id,parent_id);
        Get_item(stage5g_depth,face_id,depth);
        Get_item(stage5i_first_child,face_id,first_child);
        Get_item(stage5i_child_count,face_id,child_count);
        if(depth<0)
        {
            stage5k_export_failures++;
            Print("STAGE5K RECORD FAILURE face=");Print(face_id);
            continue;
        }
        Integer class_code=1; /* 1=ROOT_SHELL, 2=HOLE, 3=ISLAND */
        if(depth>0)
        {
            if(Mod(depth,2.0)!=0.0)class_code=2;
            else class_code=3;
        }
        Integer output_action=1; /* 1=OUTPUT, 0=SUPPRESS_HOLE */
        if(class_code==2)output_action=0;
        Integer record_index=stage5k_records_created+1;
        Integer write_failed=FALSE;
        if(Set_item(record_face_id,record_index,face_id)!=0)write_failed=TRUE;
        if(Set_item(record_start_edge,record_index,start_id)!=0)write_failed=TRUE;
        if(Set_item(record_parent,record_index,parent_id)!=0)write_failed=TRUE;
        if(Set_item(record_depth,record_index,depth)!=0)write_failed=TRUE;
        if(Set_item(record_class,record_index,class_code)!=0)write_failed=TRUE;
        if(Set_item(record_first_child,record_index,first_child)!=0)write_failed=TRUE;
        if(Set_item(record_child_count,record_index,child_count)!=0)write_failed=TRUE;
        if(Set_item(record_output_action,record_index,output_action)!=0)write_failed=TRUE;
        if(Set_item(record_steps,record_index,steps)!=0)write_failed=TRUE;
        if(Set_item(record_area,record_index,area)!=0)write_failed=TRUE;
        if(Set_item(record_sample_x,record_index,sample_x)!=0)write_failed=TRUE;
        if(Set_item(record_sample_y,record_index,sample_y)!=0)write_failed=TRUE;
        if(write_failed==TRUE)
        {
            stage5k_export_failures++;
            Print("STAGE5K RECORD FAILURE face=");Print(face_id);
            continue;
        }
        stage5k_records_created++;
        if(depth>stage5k_max_depth)stage5k_max_depth=depth;
        if(class_code==1)stage5k_root_shell_records++;
        else if(class_code==2)stage5k_hole_records++;
        else stage5k_island_records++;
        if(output_action==1)stage5k_output_records++;
        else stage5k_suppressed_records++;
    }
    /* Read every stored record back before reporting it. */
    Integer record_index=0;
    for(record_index=1;record_index<=stage5k_records_created;record_index++)
    {
        Integer rid=0,start_id=0,parent_id=0,depth=0,class_code=0;
        Integer first_child=0,child_count=0,output_action=0,steps=0;
        Real area=0.0,sample_x=0.0,sample_y=0.0;
        Integer read_failed=FALSE;
        if(Get_item(record_face_id,record_index,rid)!=0)read_failed=TRUE;
        if(Get_item(record_start_edge,record_index,start_id)!=0)read_failed=TRUE;
        if(Get_item(record_parent,record_index,parent_id)!=0)read_failed=TRUE;
        if(Get_item(record_depth,record_index,depth)!=0)read_failed=TRUE;
        if(Get_item(record_class,record_index,class_code)!=0)read_failed=TRUE;
        if(Get_item(record_first_child,record_index,first_child)!=0)read_failed=TRUE;
        if(Get_item(record_child_count,record_index,child_count)!=0)read_failed=TRUE;
        if(Get_item(record_output_action,record_index,output_action)!=0)read_failed=TRUE;
        if(Get_item(record_steps,record_index,steps)!=0)read_failed=TRUE;
        if(Get_item(record_area,record_index,area)!=0)read_failed=TRUE;
        if(Get_item(record_sample_x,record_index,sample_x)!=0)read_failed=TRUE;
        if(Get_item(record_sample_y,record_index,sample_y)!=0)read_failed=TRUE;
        if(read_failed==TRUE)
        {
            stage5k_export_failures++;
            Print("STAGE5K RECORD FAILURE index=");Print(record_index);
            continue;
        }
        
        
        
        
        
    }

    /* Stage 5L - build export-ready attribute rows from the verified Stage 5K
       topology records. This stage uses only Dynamic_Integer, Dynamic_Real,
       Dynamic_Text, Get_item, Set_item, To_text and Print. No external file,
       element-attribute or database API is assumed. */
    Dynamic_Text attribute_topology_id,attribute_classification;
    Dynamic_Text attribute_output_action,attribute_parent_topology_id;
    Dynamic_Text attribute_record_line;
    Integer stage5l_attribute_records=0,stage5l_root_attributes=0;
    Integer stage5l_hole_attributes=0,stage5l_island_attributes=0;
    Integer stage5l_output_attributes=0,stage5l_suppressed_attributes=0;
    Integer stage5l_max_depth=0,stage5l_export_failures=0;
    for(record_index=1;record_index<=stage5k_records_created;record_index++)
    {
        Integer rid=0,start_id=0,parent_id=0,depth=0,class_code=0;
        Integer first_child=0,child_count=0,output_action=0,steps=0;
        Real area=0.0,sample_x=0.0,sample_y=0.0;
        Integer read_failed=FALSE;
        if(Get_item(record_face_id,record_index,rid)!=0)read_failed=TRUE;
        if(Get_item(record_start_edge,record_index,start_id)!=0)read_failed=TRUE;
        if(Get_item(record_parent,record_index,parent_id)!=0)read_failed=TRUE;
        if(Get_item(record_depth,record_index,depth)!=0)read_failed=TRUE;
        if(Get_item(record_class,record_index,class_code)!=0)read_failed=TRUE;
        if(Get_item(record_first_child,record_index,first_child)!=0)read_failed=TRUE;
        if(Get_item(record_child_count,record_index,child_count)!=0)read_failed=TRUE;
        if(Get_item(record_output_action,record_index,output_action)!=0)read_failed=TRUE;
        if(Get_item(record_steps,record_index,steps)!=0)read_failed=TRUE;
        if(Get_item(record_area,record_index,area)!=0)read_failed=TRUE;
        if(Get_item(record_sample_x,record_index,sample_x)!=0)read_failed=TRUE;
        if(Get_item(record_sample_y,record_index,sample_y)!=0)read_failed=TRUE;
        if(read_failed==TRUE)
        {
            stage5l_export_failures++;
            Print("STAGE5L ATTRIBUTE FAILURE record=");Print(record_index);
            continue;
        }
        Text topology_id="FACE_"+To_text(rid);
        Text parent_topology_id="NONE";
        if(parent_id>0)parent_topology_id="FACE_"+To_text(parent_id);
        Text classification="UNKNOWN";
        if(class_code==1)classification="ROOT_SHELL";
        else if(class_code==2)classification="HOLE";
        else if(class_code==3)classification="ISLAND";
        Text action="SUPPRESS_HOLE";
        if(output_action==1)action="OUTPUT";
        Text row="topology_id="+topology_id+
                 "|face_id="+To_text(rid)+
                 "|start_edge="+To_text(start_id)+
                 "|parent_topology_id="+parent_topology_id+
                 "|parent_face_id="+To_text(parent_id)+
                 "|depth="+To_text(depth)+
                 "|classification="+classification+
                 "|area="+To_text(area,12)+
                 "|representative_x="+To_text(sample_x,12)+
                 "|representative_y="+To_text(sample_y,12)+
                 "|first_child_face_id="+To_text(first_child)+
                 "|child_count="+To_text(child_count)+
                 "|directed_edges="+To_text(steps)+
                 "|output_action="+action;
        Integer attribute_index=stage5l_attribute_records+1;
        Integer write_failed=FALSE;
        if(Set_item(attribute_topology_id,attribute_index,topology_id)!=0)write_failed=TRUE;
        if(Set_item(attribute_parent_topology_id,attribute_index,parent_topology_id)!=0)write_failed=TRUE;
        if(Set_item(attribute_classification,attribute_index,classification)!=0)write_failed=TRUE;
        if(Set_item(attribute_output_action,attribute_index,action)!=0)write_failed=TRUE;
        if(Set_item(attribute_record_line,attribute_index,row)!=0)write_failed=TRUE;
        if(write_failed==TRUE)
        {
            stage5l_export_failures++;
            Print("STAGE5L ATTRIBUTE FAILURE face=");Print(rid);
            continue;
        }
        stage5l_attribute_records++;
        if(depth>stage5l_max_depth)stage5l_max_depth=depth;
        if(class_code==1)stage5l_root_attributes++;
        else if(class_code==2)stage5l_hole_attributes++;
        else if(class_code==3)stage5l_island_attributes++;
        if(output_action==1)stage5l_output_attributes++;
        else stage5l_suppressed_attributes++;
    }
    Integer attribute_index=0;
    for(attribute_index=1;attribute_index<=stage5l_attribute_records;attribute_index++)
    {
        Text topology_id="",parent_topology_id="",classification="";
        Text action="",row="";
        Integer read_failed=FALSE;
        if(Get_item(attribute_topology_id,attribute_index,topology_id)!=0)read_failed=TRUE;
        if(Get_item(attribute_parent_topology_id,attribute_index,parent_topology_id)!=0)read_failed=TRUE;
        if(Get_item(attribute_classification,attribute_index,classification)!=0)read_failed=TRUE;
        if(Get_item(attribute_output_action,attribute_index,action)!=0)read_failed=TRUE;
        if(Get_item(attribute_record_line,attribute_index,row)!=0)read_failed=TRUE;
        if(read_failed==TRUE)
        {
            stage5l_export_failures++;
            Print("STAGE5L ATTRIBUTE FAILURE index=");Print(attribute_index);
            continue;
        }
    }

    /* Stage 5M - create real 12d Super String polygons with immediate odd-depth
       children attached as internal holes. The shell is not assigned to a
       model until Set_super_use_hole and every Super_add_hole call succeed. */
    Integer stage5m_polygons_created=0,stage5m_holes_attached=0;
    Integer stage5m_shell_failures=0,stage5m_hole_failures=0;
    Integer stage5m_model_failures=0,stage5m_extent_failures=0;
    Integer stage5m_verified_holes=0;
    Integer stage5n_native_line_segments=0,stage5n_native_arc_segments=0;
    for(face_id=1;face_id<=accepted_count;face_id++)
    {
        Integer depth=0,start_id=0,steps=0;
        Get_item(stage5g_depth,face_id,depth);
        Get_item(accepted_start,face_id,start_id);
        Get_item(accepted_steps,face_id,steps);
        if(depth<0||Mod(depth,2.0)!=0.0)continue;
        Integer shell_count=0,shell_lines=0,shell_arcs=0;
        Element polygon;
        if(Build_native_face_super(start_id,directed_next,directed_from,directed_physical_edge,
                                   edge_from,edge_source_element,edge_geometry_kind,edge_signed_radius,edge_arc_major,
                                   edge_segment_colour,edge_weight,edge_arc_centre_x,edge_arc_centre_y,
                                   node_x,node_y,stage5d_max_steps,output_level,site,
                                   polygon,shell_count,shell_lines,shell_arcs)!=TRUE)
        {
            stage5m_shell_failures++;
            Print("STAGE5N POLYGON FAILURE face=");Print(face_id);
            continue;
        }
        Integer immediate_holes=0,hole_attach_failed=FALSE;
        Integer candidate_hole=0;
        for(candidate_hole=1;candidate_hole<=accepted_count;candidate_hole++)
        {
            Integer hole_parent=0,hole_depth=0;
            Get_item(stage5g_parent,candidate_hole,hole_parent);
            Get_item(stage5g_depth,candidate_hole,hole_depth);
            if(hole_parent!=face_id||hole_depth!=depth+1||Mod(hole_depth,2.0)==0.0)continue;
            if(immediate_holes==0)
            {
                Integer use_status=Set_super_use_hole(polygon,1);
                if(use_status!=0)
                {
                    stage5m_hole_failures++;hole_attach_failed=TRUE;
                    Print("STAGE5M HOLE FAILURE shell=");Print(face_id);
                    break;
                }
            }
            Integer hole_start=0;Get_item(accepted_start,candidate_hole,hole_start);
            Integer hole_count=0,hole_lines=0,hole_arcs=0;
            Element hole_element;
            if(Build_native_face_super(hole_start,directed_next,directed_from,directed_physical_edge,
                                       edge_from,edge_source_element,edge_geometry_kind,edge_signed_radius,edge_arc_major,
                                       edge_segment_colour,edge_weight,edge_arc_centre_x,edge_arc_centre_y,
                                       node_x,node_y,stage5d_max_steps,output_level,site,
                                       hole_element,hole_count,hole_lines,hole_arcs)!=TRUE)
            {
                stage5m_hole_failures++;hole_attach_failed=TRUE;
                Print("STAGE5N HOLE FAILURE shell=");Print(face_id);
                break;
            }
            Integer add_status=Super_add_hole(polygon,hole_element);
            if(add_status!=0)
            {
                stage5m_hole_failures++;hole_attach_failed=TRUE;
                Print("STAGE5M HOLE FAILURE shell=");Print(face_id);
                Element_delete(hole_element);
                Element_delete(polygon);
                break;
            }
            immediate_holes++;stage5m_holes_attached++;
            stage5n_native_line_segments+=hole_lines;
            stage5n_native_arc_segments+=hole_arcs;
        }
        if(hole_attach_failed!=TRUE)
        {
            for(component_id=1;component_id<=component_count;component_id++)
            {
                Integer containing_face=0;
                Get_item(component_container_face,component_id,containing_face);
                if(containing_face!=face_id)continue;
                Integer hole_start=0;
                Get_item(component_exterior_start,component_id,hole_start);
                if(hole_start<=0)continue;
                if(immediate_holes==0)
                {
                    Integer use_status=Set_super_use_hole(polygon,1);
                    if(use_status!=0)
                    {stage5m_hole_failures++;hole_attach_failed=TRUE;break;}
                }
                Integer hole_count=0,hole_lines=0,hole_arcs=0;
                Element hole_element;
                Integer hole_build_ok=Build_native_face_super(
                    hole_start,directed_next,directed_from,directed_physical_edge,
                    edge_from,edge_source_element,edge_geometry_kind,edge_signed_radius,edge_arc_major,
                    edge_segment_colour,edge_weight,edge_arc_centre_x,edge_arc_centre_y,
                    node_x,node_y,stage5d_max_steps,output_level,site,
                    hole_element,hole_count,hole_lines,hole_arcs);
                if(hole_build_ok!=TRUE)
                {stage5m_hole_failures++;hole_attach_failed=TRUE;break;}
                Integer add_status=Super_add_hole(polygon,hole_element);
                if(add_status!=0)
                {
                    stage5m_hole_failures++;hole_attach_failed=TRUE;
                    Element_delete(hole_element);
                    break;
                }
                immediate_holes++;stage5m_holes_attached++;
                stage5n_native_line_segments+=hole_lines;
                stage5n_native_arc_segments+=hole_arcs;
            }
        }
        if(hole_attach_failed==TRUE)
        {
            Element_delete(polygon);
            continue;
        }
        Text polygon_name="FACE_"+To_text(face_id);
        if(depth==0)polygon_name=polygon_name+"_ROOT_SHELL";
        else polygon_name=polygon_name+"_ISLAND_DEPTH_"+To_text(depth);
        Set_name(polygon,polygon_name);
        Integer model_status=Set_model(polygon,output_model);
        if(model_status!=0)
        {
            stage5m_model_failures++;
            Print("STAGE5M POLYGON FAILURE face=");Print(face_id);
            Element_delete(polygon);
            continue;
        }
        Integer extent_status=Calc_extent(polygon);
        if(extent_status!=0)
        {
            stage5m_extent_failures++;
            Print("STAGE5M POLYGON FAILURE face=");Print(face_id);
            Element_delete(polygon);
            continue;
        }
        Integer verified_count=0;
        Integer verify_status=Get_super_holes(polygon,verified_count);
        if(immediate_holes==0)
        {
            if(verify_status==0)stage5m_verified_holes+=verified_count;
        }
        else if(verify_status==0&&verified_count==immediate_holes)
            stage5m_verified_holes+=verified_count;
        else
        {
            stage5m_hole_failures++;
            Print("STAGE5M HOLE VERIFY FAILURE face=");Print(face_id);
            Element_delete(polygon);
            continue;
        }
        Undo polygon_undo=Add_undo_add("Create Stage 5M hole-enabled polygon",polygon);
        stage5m_polygons_created++;
        if(immediate_holes>0)summary_polygons_with_holes++;
        stage5n_native_line_segments+=shell_lines;
        stage5n_native_arc_segments+=shell_arcs;
    }
    stage5e_output_faces=stage5m_polygons_created;
    stage5e_output_failures=stage5m_shell_failures+stage5m_hole_failures+
                            stage5m_model_failures+stage5m_extent_failures;

    Output_line("DEBUG: Stage 5 topology/face summary");
    Print("  Stage 5A nodes = ");Print(stage5a_node_count);Print();
    Print("  Stage 5A directed edges = ");Print(stage5a_directed_count);Print();
    Print("  Stage 5B next links assigned = ");Print(stage5b_assigned);Print();
    Print("  Stage 5B next-link failures = ");Print(stage5b_failed);Print();
    Print("  Stage 5C candidate rings = ");Print(stage5c_candidate_rings);Print();
    Print("  Stage 5C trace failures = ");Print(stage5c_trace_failures);Print();
    Print("  Stage 5C edges traced = ");Print(stage5c_edges_traced);Print();
    Print("  Stage 5D rings = ");Print(stage5d_ring_count);Print();
    Print("  Stage 5D valid faces = ");Print(stage5d_valid_faces);Print();
    Print("  Stage 5D small-face rejections = ");Print(stage5d_rejected_small);Print();
    Print("  Stage 5D exterior rejections = ");Print(stage5d_rejected_exterior);Print();
    Print("  Stage 5E output faces = ");Print(stage5e_output_faces);Print();
    Print("  Stage 5E output failures = ");Print(stage5e_output_failures);Print();
    Print("  Stage 5F faces tested = ");Print(stage5f_faces_tested);Print();
    Print("  Stage 5F faces inside site = ");Print(stage5f_faces_inside_site);Print();
    Print("  Stage 5F faces outside site = ");Print(stage5f_face_outside_site);Print();
    Print("  Stage 5F PIP failures = ");Print(stage5f_pip_failures);Print();
    Print("  Stage 5G containment tests = ");Print(stage5g_containment_tests);Print();
    Print("  Stage 5G containments found = ");Print(stage5g_containments_found);Print();
    Print("  Stage 5G root faces = ");Print(stage5g_root_faces);Print();
    Print("  Stage 5G nested faces = ");Print(stage5g_nested_faces);Print();
    Print("  Stage 5G failures = ");Print(stage5g_failures);Print();
    Print("  Stage 5H shells output = ");Print(stage5h_shells_output);Print();
    Print("  Stage 5H holes suppressed = ");Print(stage5h_holes_suppressed);Print();
    Print("  Stage 5H invalid depth = ");Print(stage5h_invalid_depth);Print();
    Print("  Stage 5H output failures = ");Print(stage5h_output_failures);Print();
    Print("  Stage 5I root shells = ");Print(stage5i_root_shells);Print();
    Print("  Stage 5I holes = ");Print(stage5i_holes);Print();
    Print("  Stage 5I islands = ");Print(stage5i_islands);Print();
    Print("  Stage 5I maximum depth = ");Print(stage5i_max_depth);Print();
    Print("  Stage 5I tree failures = ");Print(stage5i_tree_failures);Print();
    Print("  Stage 5K records created = ");Print(stage5k_records_created);Print();
    Print("  Stage 5K root shell records = ");Print(stage5k_root_shell_records);Print();
    Print("  Stage 5K hole records = ");Print(stage5k_hole_records);Print();
    Print("  Stage 5K island records = ");Print(stage5k_island_records);Print();
    Print("  Stage 5K export failures = ");Print(stage5k_export_failures);Print();
    Print("  Stage 5L attribute records = ");Print(stage5l_attribute_records);Print();
    Print("  Stage 5L output attributes = ");Print(stage5l_output_attributes);Print();
    Print("  Stage 5L export failures = ");Print(stage5l_export_failures);Print();
    Print("  Stage 5M polygons created = ");Print(stage5m_polygons_created);Print();
    Print("  Stage 5M holes attached = ");Print(stage5m_holes_attached);Print();
    Print("  Stage 5M verified holes = ");Print(stage5m_verified_holes);Print();
    Print("  Stage 5M shell failures = ");Print(stage5m_shell_failures);Print();
    Print("  Stage 5M hole failures = ");Print(stage5m_hole_failures);Print();
    Print("  Stage 5M model failures = ");Print(stage5m_model_failures);Print();
    Print("  Stage 5M extent failures = ");Print(stage5m_extent_failures);Print();
    Print("  Stage 5N native line segments = ");Print(stage5n_native_line_segments);Print();
    Print("  Stage 5N native arc segments = ");Print(stage5n_native_arc_segments);Print();
    Output_line("");

    /* Production cleanup: final polygons now exist, so remove every remaining
       physical topology line/arc piece from the output model. */
    Integer final_topology_deleted=0,final_topology_failures=0;
    if(Delete_temporary_topology_output(edge_geometry,
                                        final_topology_deleted,final_topology_failures)!=TRUE)
    {
        Print("ERROR: final temporary topology cleanup failed. Deleted=");
        Print(final_topology_deleted);Print(" failures=");Print(final_topology_failures);Print();
        return(FALSE);
    }
    summary_polygons_created=stage5m_polygons_created;
    summary_islands=0;
    summary_dangles_removed=total_dangle_edges_removed;
    summary_temporary_removed+=physical_dangles_deleted+final_topology_deleted;
    Null(edge_geometry);
    Calc_extent(output_model);
    Model_draw(output_model);

    return(TRUE);
}

Integer Process_stage_3(Element site,Dynamic_Element &internal_strings,Model output_model,
                        Real output_level,Real node_tolerance,Real arc_working_tolerance,
                        Real minimum_segment_length,Real minimum_face_area,
                        Real maximum_undershoot_extension)
{
    Integer internal_count=0,status,i;
    Integer summary_polygons_created=0,summary_polygons_with_holes=0,summary_islands=0;
    Integer summary_dangles_removed=0,summary_temporary_removed=0;
    Real elapsed_start=0.0,elapsed_end=0.0;
    Get_time(elapsed_start);
    Output_line("============================");
    Output_line("== Polygon Topology Builder ==");
    Output_line("============================");
    Output_line("Please wait... this process might take several seconds..");
    Output_line("");
    Output_line("******** POLYGON TOPOLOGY BUILDER DEBUG ********");
    Output_line("Diagnostic output enabled. Production topology logic unchanged.");
    Output_line("************************************************");
    Output_line("");
    Integer site_points,site_lines,site_arcs;

    if(Validate_positive("Node tolerance",node_tolerance)!=TRUE)return(FALSE);
    if(Validate_positive("Arc working tolerance",arc_working_tolerance)!=TRUE)return(FALSE);
    if(Validate_non_negative("Minimum segment length",minimum_segment_length)!=TRUE)return(FALSE);
    if(Validate_non_negative("Minimum face area",minimum_face_area)!=TRUE)return(FALSE);
    if(Validate_non_negative("Maximum undershoot extension",maximum_undershoot_extension)!=TRUE)return(FALSE);

    Output_line("DEBUG: Processing parameters");
    Print("  Node tolerance = ");Print(node_tolerance);Print();
    Print("  Arc working tolerance = ");Print(arc_working_tolerance);Print();
    Print("  Minimum segment length = ");Print(minimum_segment_length);Print();
    Print("  Minimum face area = ");Print(minimum_face_area);Print();
    Print("  Maximum undershoot extension = ");Print(maximum_undershoot_extension);Print();
    Print("  Output level = ");Print(output_level);Print();
    Output_line("");

    status=Get_number_of_items(internal_strings,internal_count);
    if(status!=0||internal_count==0)return(FALSE);

    if(Read_super_summary(site,"Site boundary",site_points,site_lines,site_arcs)!=TRUE)return(FALSE);
    Output_line("DEBUG: Site boundary summary");
    Print("  Points = ");Print(site_points);Print();
    Print("  Line segments = ");Print(site_lines);Print();
    Print("  Arc segments = ");Print(site_arcs);Print();
    Output_line("");

    Output_line("DEBUG: Internal source summary");
    Print("  Source elements = ");Print(internal_count);Print();

    for(i=1;i<=internal_count;i++)
    {
        Element source,result;
        Text source_name="",role="";
        Integer npts=0,lines=0,arcs=0;
        if(Get_item(internal_strings,i,source)!=0){continue;}
        Get_name(source,source_name);
        if(source_name=="")source_name="SUPER";
        role="Internal Element "+To_text(i)+" : "+source_name;
        if(Read_super_summary(source,role,npts,lines,arcs)!=TRUE)
        {
            Print("  Source ");Print(i);Print(" summary read FAILED");Print();
            continue;
        }
        Print("  Source ");Print(i);Print(": ");Print(source_name);
        Print(" | points=");Print(npts);
        Print(" | lines=");Print(lines);
        Print(" | arcs=");Print(arcs);Print();
/* Physical noded pieces are created after canonicalisation. */
    }
Integer physical_output_created=0;
    Integer repair_pass=0,total_repairs_applied=0,noding_status=FALSE;
    Integer maximum_repair_passes=25;
    while(repair_pass<maximum_repair_passes)
    {
        repair_pass++;
        physical_output_created=0;
        Output_line("DEBUG: Topology rebuild pass");
        Print("  Repair/noding pass = ");Print(repair_pass);
        Print("  Maximum repair passes = ");Print(maximum_repair_passes);Print();
        Real pass_start=0.0,pass_end=0.0;
        Get_time(pass_start);
        noding_status=Run_stage_3_noding(site,internal_strings,internal_count,output_model,output_level,
                       node_tolerance,arc_working_tolerance,minimum_segment_length,
                       maximum_undershoot_extension,physical_output_created,
                       summary_polygons_created,summary_polygons_with_holes,summary_islands,
                       summary_dangles_removed,summary_temporary_removed);
        Get_time(pass_end);
        Print("  Pass elapsed seconds = ");Print(pass_end-pass_start);Print();
        Print("  Physical output pieces created = ");Print(physical_output_created);Print();
        Print("  Noding status = ");Print(noding_status);Print();
        if(noding_status==2)
        {
            total_repairs_applied++;
            Print("  Stage 4A.1 repair triggered rebuild. Total rebuild repairs = ");
            Print(total_repairs_applied);Print();
            continue;
        }
        if(noding_status!=TRUE)
        {
            Print("STAGE4A1 processing failed during topology build");Print();
            return(FALSE);
        }
        break;
    }
    if(noding_status==2)
    {
        return(FALSE);
    }
    status=Calc_extent(output_model);
    status=Model_draw(output_model);
    Get_time(elapsed_end);
    Real processing_time=elapsed_end-elapsed_start;
    Output_line("DEBUG: Final result");
    Print("  Final polygons = ");Print(summary_polygons_created);Print();
    Print("  Polygons with holes = ");Print(summary_polygons_with_holes);Print();
    Print("  Islands = ");Print(summary_islands);Print();
    Print("  Undershoot rebuild repairs = ");Print(total_repairs_applied);Print();
    Print("  Dangling edges removed = ");Print(summary_dangles_removed);Print();
    Print("  Temporary topology elements removed = ");Print(summary_temporary_removed);Print();
    Print("  Output model redraw status = ");Print(status);Print();
    Output_line("");
    Output_line("=== Polygon Topology Builder DEBUG complete ===");
    Print("Total polygons created = ");Print(summary_polygons_created);Print();
    Print("Polygons containing holes = ");Print(summary_polygons_with_holes);Print();
    Print("Islands detected = ");Print(summary_islands);Print();
    Print("Undershoot repairs applied = ");Print(total_repairs_applied);Print();
    Print("Dangling edge repairs applied = ");Print(summary_dangles_removed);Print();
    Print("Processing time (seconds) = ");Print(processing_time);Print();
    return(TRUE);
}

void mainPanel()
{
    Text panelName=MACRO_NAME;
    Panel panel=Create_panel(panelName,TRUE);
    Vertical_Group vgroup=Create_vertical_group(-1);
    Colour_Message_Box cmbMsg=Create_colour_message_box("");

    New_Select_Box nsb_site=Create_new_select_box("Site boundary selection",
        "Select closed site boundary Super String",SELECT_STRING,cmbMsg);
    Source_Box sb_internal=Create_source_box("Topology Source",cmbMsg,0);
    Model_Box mb_output=Create_model_box("Output model",cmbMsg,CHECK_MODEL_CREATE);
    Real_Box rb_output_z=Create_real_box("Output Z level",cmbMsg);
    Real_Box rb_node_tol=Create_real_box("Node tolerance",cmbMsg);
    Real_Box rb_arc_tol=Create_real_box("Arc working tolerance",cmbMsg);
    Real_Box rb_min_seg=Create_real_box("Minimum segment length",cmbMsg);
    Real_Box rb_min_area=Create_real_box("Minimum face area",cmbMsg);
    Real_Box rb_max_undershoot=Create_real_box("Maximum undershoot extension",cmbMsg);

    Set_data(rb_output_z,0.0);Set_data(rb_node_tol,0.001);Set_data(rb_arc_tol,0.001);
    Set_data(rb_min_seg,0.001);Set_data(rb_min_area,0.001);Set_data(rb_max_undershoot,0.050);

    Horizontal_Group bgroup=Create_button_group();
    Button process=Create_button("&Process","process");
    Button finish=Create_finish_button("Finish","Finish");
    Button help_button=Create_help_button(panel,"Help");
    Append(process,bgroup);Append(finish,bgroup);Append(help_button,bgroup);

    Append(nsb_site,vgroup);Append(sb_internal,vgroup);Append(mb_output,vgroup);
    Append(rb_output_z,vgroup);Append(rb_node_tol,vgroup);Append(rb_arc_tol,vgroup);
    Append(rb_min_seg,vgroup);Append(rb_min_area,vgroup);Append(rb_max_undershoot,vgroup);
    Append(cmbMsg,vgroup);Append(bgroup,vgroup);Append(vgroup,panel);Show_widget(panel);

    Integer doit=1;
    while(doit)
    {
        Text cmd="",msg="";
        Integer id,ret=Wait_on_widgets(id,cmd,msg);
        switch(cmd)
        {
        case "keystroke":
        case "set_focus":
        case "kill_focus":{continue;}break;
        case "CodeShutdown":{Set_exit_code(cmd);}break;
        }
        switch(id)
        {
        case Get_id(panel):
        {
            if(cmd=="Panel Quit")doit=0;
            if(cmd=="Panel About")about_panel(panel);
        }break;
        case Get_id(process):
        {
            if(cmd=="process")
            {
                Element site;
                Dynamic_Element de_internal;
                Model output_model;
                Real output_level,node_tolerance,arc_working_tolerance;
                Real minimum_segment_length,minimum_face_area,maximum_undershoot_extension;
                Integer source_ret,internal_count=0;

                if(Validate(nsb_site,site)!=TRUE)break;
                source_ret=Validate(sb_internal,de_internal);
                if(source_ret==FALSE){Set_data(cmbMsg,"Source_Box drastic validation error.");break;}
                if(source_ret==NO_NAME){Set_data(cmbMsg,"No Source_Box source selected.");break;}
                if(source_ret==-2){Set_data(cmbMsg,"Invalid Source_Box choice or blank field.");break;}
                if(Get_number_of_items(de_internal,internal_count)!=0)
                {Set_data(cmbMsg,"Unable to read Source_Box contents.");break;}
                if(internal_count==0)
                {Set_data(cmbMsg,"Source_Box is valid but returned no elements.");break;}

                if(Validate(mb_output,GET_MODEL_CREATE,output_model)!=MODEL_EXISTS)break;
                if(Validate(rb_output_z,output_level)==FALSE)break;
                if(Validate(rb_node_tol,node_tolerance)==FALSE)break;
                if(Validate(rb_arc_tol,arc_working_tolerance)==FALSE)break;
                if(Validate(rb_min_seg,minimum_segment_length)==FALSE)break;
                if(Validate(rb_min_area,minimum_face_area)==FALSE)break;
                if(Validate(rb_max_undershoot,maximum_undershoot_extension)==FALSE)break;
                if(Validate_non_negative("Maximum undershoot extension",maximum_undershoot_extension)!=TRUE)
                {Set_data(cmbMsg,"Maximum undershoot extension must not be negative.");break;}

                Set_data(cmbMsg,"Please wait... this may take several seconds..");

                if(Process_stage_3(site,de_internal,output_model,output_level,
                    node_tolerance,arc_working_tolerance,minimum_segment_length,
                    minimum_face_area,maximum_undershoot_extension)==TRUE)
                    Set_data(cmbMsg,"DEBUG polygon topology processing finished");
                else Set_data(cmbMsg,"Topology processing failed. Review the Output Window.");
            }
        }break;
        default:{if(cmd=="Finish")doit=0;}break;
        }
    }
}

void main(){mainPanel();}
