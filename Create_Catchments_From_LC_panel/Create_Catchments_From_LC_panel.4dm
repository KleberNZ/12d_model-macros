/*---------------------------------------------------------------------
**   Programmer:           Kleber Lessa do Prado
**   Date:                 23/09/2026
**   12D Model:            V15
**   Version:              012
**   Profiling build:       Timing only; processing logic unchanged
**   Macro Name:           Create_Catchments_From_LC_panel4dm
**   Type:                 SOURCE
**
**   Brief description:
**   Creates upstream-pit catchment polygons from lots associated with
**   direct lot connections on each drainage pipe.
**
**---------------------------------------------------------------------
**   Description:
**
**   For each selected drainage pipe, this macro:
**   - Determines the direct upstream pit from drainage flow direction.
**   - Finds two-vertex Super lot connections whose vertex 2 is attached
**     to the upstream pit or to the straight pipe, excluding the
**     downstream pit.
**   - Uses lot-connection vertex 1 with XY_inside_polygon() to find the
**     containing closed Super lot polygon.
**   - Adds each source lot only once.
**   - Copies a single lot directly, or dissolves multiple edge-connected
**     lots by cancelling shared line/arc segments and reconstructing the
**     external boundary of each connected component.
**   - Names the outputs from the upstream pit. Disconnected components
**     are named PIT, PIT_2, PIT_3, and so on.
**
**   Version 1 assumptions and limitations:
**   - Rational Method network convention: each pit has one downstream
**     outlet pipe; multiple inlet pipes are permitted.
**   - Drainage pipe attachment testing assumes straight pipe geometry.
**     Curved pipe geometry is not evaluated.
**   - Lot connections must be Super strings with exactly two vertices.
**   - Vertex 1 must lie inside one and only one selected lot polygon.
**   - Vertex 2 must connect to the upstream pit or the current pipe.
**   - Lot boundaries must be closed Super polygons.
**   - Shared lot boundaries must have matching endpoints and matching
**     segmentation within XY_TOL and ARC_TOL.
**   - Optional hole polygons must be supplied in the Hole polygons model.
**   - Hole geometry is never inferred or reconstructed.
**   - A hole polygon must bridge at least two disconnected catchment
**     components using complete, identically segmented shared boundaries.
**   - Adding the selected hole polygon(s) to the contributing lots must
**     dissolve to exactly one external catchment shell.
**   - Hole polygons must be closed Supers without holes.
**   - Adjacent, overlapping, contained, partially matched or ambiguous
**     hole polygons are unsupported.
**   - Polygon containment, overlaps, partial-edge noding, coverage
**     validation and general Boolean operations are unsupported.
**   - Source lot polygons and drainage attributes are not modified.
**
**   Intended use:
**   Generates drainage catchments from cadastral lot layout and
**   lot-connection topology rather than surface-derived flow paths.
**
**   This is not a TIN-based catchment delineation tool and is intended
**   for Rational Method style subdivision drainage design workflows.
**
**---------------------------------------------------------------------
**  This macro may be reproduced, modified and used without restriction.
**  The author grants all users Unlimited Use of the source code and any
**  associated files, for no fee. Unlimited Use includes compiling,
**  running and modifying the code for individual or integrated purposes.
**  The author also grants 12d Solutions Pty Ltd and other users permission
**  to incorporate this macro, in whole or in part, into other macros or
**  programs.
**---------------------------------------------------------------------
*/
#define DEBUG_FILE 0
#define ECHO_DEBUG_FILE 0
#define ECHO_LINE_NO 0
#define BUILD "15.008"

#include "standard_library.h"
#include "size_of.h"
#include "set_ups.h"

/*global variables*/
{
    Integer MAX_POLYGONS=500;
    Integer MAX_SEGMENTS=50000;
    Integer MAX_RING_POINTS=50000;
    Real XY_TOL=0.000001;
    Real ARC_TOL=0.000001;
}
/*--------------------------- HELPERS ----------------------------*/
// Converts a text string to a valid 12d name by replacing invalid characters with hyphens.
Text Make_valid_12d_name(Text name)
{
    Integer i=0;

    while((i=Find_text(name,"/"))>0)
        name=Get_subtext(name,1,i-1)+"-"+Get_subtext(name,i+1,999999);

    while((i=Find_text(name,"\\"))>0)
        name=Get_subtext(name,1,i-1)+"-"+Get_subtext(name,i+1,999999);

    while((i=Find_text(name,"&"))>0)
        name=Get_subtext(name,1,i-1)+"-"+Get_subtext(name,i+1,999999);

    while((i=Find_text(name,"?"))>0)
        name=Get_subtext(name,1,i-1)+"-"+Get_subtext(name,i+1,999999);

    while((i=Find_text(name,"*"))>0)
        name=Get_subtext(name,1,i-1)+"-"+Get_subtext(name,i+1,999999);

    while((i=Find_text(name,":"))>0)
        name=Get_subtext(name,1,i-1)+"-"+Get_subtext(name,i+1,999999);

    while((i=Find_text(name,"|"))>0)
        name=Get_subtext(name,1,i-1)+"-"+Get_subtext(name,i+1,999999);

    while((i=Find_text(name,"<"))>0)
        name=Get_subtext(name,1,i-1)+"-"+Get_subtext(name,i+1,999999);

    while((i=Find_text(name,">"))>0)
        name=Get_subtext(name,1,i-1)+"-"+Get_subtext(name,i+1,999999);

    return(name);
}
/*--------------------------- LOG HELPERS ----------------------------*/
void log_ok(Log_Box lb,Text msg)
{
    Add_log_line(lb,Create_text_log_line(msg,1));
}
void log_warn(Log_Box lb,Text msg)
{
    Add_log_line(lb,Create_text_log_line(msg,2));
}
void log_err(Log_Box lb,Text msg)
{
    Log_Line ln=Create_text_log_line(msg,3);
    Add_log_line(lb,ln);
    Print_log_line(ln,1);
}
void add_highlight_log(Log_Box lb,Element e,Text msg)
{
    Model m;
    Uid mid,eid;
    Get_model(e,m);
    Get_id(m,mid);
    Get_id(e,eid);
    Add_log_line(lb,Create_highlight_string_log_line(msg,1,mid,eid));
}

/*----------------------- CONNECTION HELPERS -------------------------*/
Real Point_distance_2d(Real x1,Real y1,Real x2,Real y2)
{
    Real dx=x2-x1;
    Real dy=y2-y1;
    return Sqrt(dx*dx+dy*dy);
}

// Tests the straight pipe geometry but deliberately excludes the
// downstream pit. Curved pipes are outside Version 1 scope.
Integer Point_near_pipe_excluding_ds_pit_2d(
    Real ax,Real ay,Real bx,Real by,
    Real dsx,Real dsy,
    Real px,Real py,Real tolerance)
{
    if(Point_distance_2d(px,py,dsx,dsy)<=tolerance)return(FALSE);
    Real vx=bx-ax;
    Real vy=by-ay;
    Real wx=px-ax;
    Real wy=py-ay;
    Real vv=vx*vx+vy*vy;
    if(vv<=0.0)return(FALSE);
    Real t=(wx*vx+wy*vy)/vv;
    if(t<0.0)t=0.0;
    if(t>1.0)t=1.0;
    Real cx=ax+t*vx;
    Real cy=ay+t*vy;
    return(Point_distance_2d(cx,cy,px,py)<=tolerance);
}

Integer Get_lot_connection_vertices(
    Element lc,
    Real &x1,Real &y1,Real &z1,
    Real &x2,Real &y2,Real &z2)
{
    Text type="";
    if(Get_type(lc,type)!=0 || type!="Super")return(FALSE);
    Integer points=0;
    if(Get_points(lc,points)!=0 || points!=2)return(FALSE);
    if(Get_super_vertex_coord(lc,1,x1,y1,z1)!=0)return(FALSE);
    if(Get_super_vertex_coord(lc,2,x2,y2,z2)!=0)return(FALSE);
    return(TRUE);
}

Integer Connection_belongs_to_pipe(
    Element lc,Segment pipe,
    Real usx,Real usy,Real dsx,Real dsy,
    Real tolerance,
    Real &lot_x,Real &lot_y,Real &lot_z)
{
    Real x2=0.0,y2=0.0,z2=0.0;
    if(!Get_lot_connection_vertices(
        lc,lot_x,lot_y,lot_z,x2,y2,z2))return(FALSE);

    if(Point_distance_2d(x2,y2,usx,usy)<=tolerance)return(TRUE);

    Point pipe_start;
    Point pipe_end;
    if(Get_start(pipe,pipe_start)!=0)return(FALSE);
    if(Get_end(pipe,pipe_end)!=0)return(FALSE);
    Real ax=Get_x(pipe_start);
    Real ay=Get_y(pipe_start);
    Real bx=Get_x(pipe_end);
    Real by=Get_y(pipe_end);

    return Point_near_pipe_excluding_ds_pit_2d(
        ax,ay,bx,by,dsx,dsy,x2,y2,tolerance);
}

/*-------------------------- LOT HELPERS -----------------------------*/
Integer Validate_lot_polygon(Element lot,Text &error)
{
    Text type="";
    Integer closed=FALSE,selfx=FALSE,use_holes=FALSE,holes=0,npts=0;
    if(Get_type(lot,type)!=0 || type!="Super")
    {
        error="Lot boundary is not a Super string.";
        return(FALSE);
    }
    if(String_closed(lot,closed)!=0 || !closed)
    {
        error="Lot boundary is not closed.";
        return(FALSE);
    }
    if(Get_points(lot,npts)!=0 || npts<3)
    {
        error="Lot boundary has fewer than three vertices.";
        return(FALSE);
    }
    if(String_self_intersects(lot,selfx)!=0 || selfx)
    {
        error="Lot boundary self-intersects.";
        return(FALSE);
    }
    if(Get_super_use_hole(lot,use_holes)!=0)
    {
        error="Could not read lot boundary hole setting.";
        return(FALSE);
    }
    if(use_holes)
    {
        if(Get_super_holes(lot,holes)!=0)
        {
            error="Could not read lot boundary hole count.";
            return(FALSE);
        }
        if(holes>0)
        {
            error="Lot boundaries with holes are not supported.";
            return(FALSE);
        }
    }
    return(TRUE);
}

// Returns 0 for exactly one match, 1 for no match, and 2 for ambiguity.
Integer Find_containing_lot(
    Element &lots[],Integer lot_count,
    Real x,Real y,
    Integer &lot_index)
{
    Integer i=0,matches=0;
    lot_index=0;
    for(i=1;i<=lot_count;i++)
    {
        Integer inside=0;
        if(XY_inside_polygon(lots[i],x,y,inside)!=0)continue;
        if(inside==1)
        {
            matches++;
            lot_index=i;
        }
    }
    if(matches==1)return(0);
    if(matches==0)return(1);
    lot_index=0;
    return(2);
}

Integer Lot_index_already_collected(
    Integer lot_index,Integer &indices[],Integer count)
{
    Integer i=0;
    for(i=1;i<=count;i++)if(indices[i]==lot_index)return(TRUE);
    return(FALSE);
}

/*------------------------ DISSOLVE HELPERS --------------------------*/
Integer same_real(Real a,Real b,Real tol)
{
    return(Absolute(a-b)<=tol);
}
Integer same_xy(Real x1,Real y1,Real x2,Real y2)
{
    return(same_real(x1,x2,XY_TOL)&&same_real(y1,y2,XY_TOL));
}
Integer endpoint_before(Real ax,Real ay,Real bx,Real by)
{
    if(ax<bx-XY_TOL)return(TRUE);
    if(ax>bx+XY_TOL)return(FALSE);
    return(ay<by-XY_TOL);
}
Integer same_geometry(Real ar,Integer af,Real br,Integer bf)
{
    if(!same_real(ar,br,ARC_TOL))return(FALSE);
    if(Absolute(ar)<=ARC_TOL && Absolute(br)<=ARC_TOL)return(TRUE);
    return(af==bf);
}
Integer find_segment(
    Real x1,Real y1,Real x2,Real y2,Real radius,Integer major,Integer count,
    Dynamic_Real &sx1,Dynamic_Real &sy1,Dynamic_Real &sx2,Dynamic_Real &sy2,
    Dynamic_Real &sr,Dynamic_Integer &sf)
{
    Integer i=0;
    for(i=1;i<=count;i++)
    {
        Real ax=0.0,ay=0.0,bx=0.0,by=0.0,ar=0.0;
        Integer af=0;
        Get_item(sx1,i,ax);
        Get_item(sy1,i,ay);
        Get_item(sx2,i,bx);
        Get_item(sy2,i,by);
        Get_item(sr,i,ar);
        Get_item(sf,i,af);
        if(same_xy(x1,y1,ax,ay) &&
           same_xy(x2,y2,bx,by) &&
           same_geometry(radius,major,ar,af))return(i);
    }
    return(0);
}
Integer uf_find(Integer p,Integer &parent[])
{
    Integer root=p,q=0,next=0;
    while(parent[root]!=root)root=parent[root];
    q=p;
    while(parent[q]!=q)
    {
        next=parent[q];
        parent[q]=root;
        q=next;
    }
    return(root);
}
void uf_union(Integer a,Integer b,Integer &parent[])
{
    Integer ra=uf_find(a,parent);
    Integer rb=uf_find(b,parent);
    if(ra!=rb)parent[rb]=ra;
}
void cleanup_results(Element &results[],Integer count)
{
    Integer i=0;
    for(i=1;i<=count;i++)Element_delete(results[i]);
}
Text element_label(Element elt,Integer fallback_index)
{
    Text name="";
    Get_name(elt,name);
    if(name=="")name="polygon "+To_text(fallback_index);
    return(name);
}

// UI-independent extraction of the tested dissolve geometry engine.
// Results are staged outside a model and returned to the caller.
Integer Dissolve_lot_polygons(
    Element &polys[],Integer poly_count,
    Element &results[],Integer &result_count,
    Text &error)
{
    result_count=0;
    error="";
    if(poly_count<2)
    {
        error="Dissolve requires at least two polygons.";
        return(FALSE);
    }
    if(poly_count>MAX_POLYGONS)
    {
        error="Too many lot polygons. Increase MAX_POLYGONS.";
        return(FALSE);
    }

    Integer parent[MAX_POLYGONS+1];
    Dynamic_Real sx1,sy1,sz1;
    Dynamic_Real sx2,sy2,sz2;
    Dynamic_Real sr;
    Dynamic_Integer sf,owner1,owner2;
    Dynamic_Integer occurrence,used;
    Integer seg_count=0,failed=FALSE;
    Integer i=0,j=0;

    for(i=1;i<=poly_count;i++)parent[i]=i;

    for(i=1;i<=poly_count && !failed;i++)
    {
        Text validation_error="";
        if(!Validate_lot_polygon(polys[i],validation_error))
        {
            failed=TRUE;
            error=validation_error+" Source: "+element_label(polys[i],i);
            break;
        }

        Integer npts=0;
        Get_points(polys[i],npts);
        Real fx=0.0,fy=0.0,fz=0.0,fr=0.0;
        Integer ff=0;
        Real px=0.0,py=0.0,pz=0.0,pr=0.0;
        Integer pf=0;
        if(Get_super_data(polys[i],1,fx,fy,fz,fr,ff)!=0)
        {
            failed=TRUE;
            error="Could not read first Super vertex data.";
            break;
        }
        px=fx;py=fy;pz=fz;pr=fr;pf=ff;

        for(j=2;j<=npts+1 && !failed;j++)
        {
            Real cx=0.0,cy=0.0,cz=0.0,cr=0.0;
            Integer cf=0;
            if(j==npts+1)
            {
                cx=fx;cy=fy;cz=fz;cr=fr;cf=ff;
            }
            else if(Get_super_data(polys[i],j,cx,cy,cz,cr,cf)!=0)
            {
                failed=TRUE;
                error="Could not read Super vertex data.";
                break;
            }
            if(same_xy(px,py,cx,cy))
            {
                failed=TRUE;
                error="Zero-length XY segment in "+element_label(polys[i],i);
                break;
            }

            Real ax=px,ay=py,az=pz,bx=cx,by=cy,bz=cz,r=pr;
            Integer f=pf;
            if(!endpoint_before(ax,ay,bx,by))
            {
                Real tx=ax,ty=ay,tz=az;
                ax=bx;ay=by;az=bz;
                bx=tx;by=ty;bz=tz;
                r=-r;
            }
            if(Absolute(r)<=ARC_TOL)
            {
                r=0.0;
                f=0;
            }

            Integer k=find_segment(
                ax,ay,bx,by,r,f,seg_count,
                sx1,sy1,sx2,sy2,sr,sf);
            if(k==0)
            {
                seg_count++;
                if(seg_count>MAX_SEGMENTS)
                {
                    failed=TRUE;
                    error="Too many segments. Increase MAX_SEGMENTS.";
                    break;
                }
                Set_item(sx1,seg_count,ax);Set_item(sy1,seg_count,ay);Set_item(sz1,seg_count,az);
                Set_item(sx2,seg_count,bx);Set_item(sy2,seg_count,by);Set_item(sz2,seg_count,bz);
                Set_item(sr,seg_count,r);Set_item(sf,seg_count,f);
                Set_item(owner1,seg_count,i);Set_item(owner2,seg_count,0);
                Set_item(occurrence,seg_count,1);Set_item(used,seg_count,FALSE);
            }
            else
            {
                Integer occ=0,own1=0,own2=0;
                Real seg_radius=0.0;
                Get_item(occurrence,k,occ);
                Get_item(owner1,k,own1);
                Get_item(owner2,k,own2);
                Get_item(sr,k,seg_radius);
                occ++;
                Set_item(occurrence,k,occ);
                if(occ==2)
                {
                    Set_item(owner2,k,i);
                    uf_union(own1,i,parent);
                }
                else if(occ>2)
                {
                    Text kind="line";
                    if(Absolute(seg_radius)>ARC_TOL)kind="arc";
                    failed=TRUE;
                    error="Duplicate or overlapping coverage detected. The same "+
                        kind+" is owned by more than two polygons: "+
                        element_label(polys[own1],own1)+", "+
                        element_label(polys[own2],own2)+", "+
                        element_label(polys[i],i)+".";
                    break;
                }
            }
            px=cx;py=cy;pz=cz;pr=cr;pf=cf;
        }
    }
    if(failed)return(FALSE);

    Integer root_done[MAX_POLYGONS+1];
    for(i=1;i<=poly_count;i++)root_done[i]=FALSE;

    for(i=1;i<=poly_count && !failed;i++)
    {
        Integer root=uf_find(i,parent);
        if(root_done[root])continue;
        root_done[root]=TRUE;

        Integer start_edge=0;
        for(j=1;j<=seg_count;j++)
        {
            Integer occ=0,own1=0;
            Get_item(occurrence,j,occ);
            Get_item(owner1,j,own1);
            if(occ==1 && uf_find(own1,parent)==root)
            {
                start_edge=j;
                break;
            }
        }
        if(start_edge==0)
        {
            failed=TRUE;
            error="A component has no external boundary.";
            break;
        }

        Real rx[MAX_RING_POINTS+1],ry[MAX_RING_POINTS+1];
        Real rz[MAX_RING_POINTS+1],rr[MAX_RING_POINTS+1];
        Integer rf[MAX_RING_POINTS+1];
        Integer rn=1;
        Real sx1v=0.0,sy1v=0.0,sz1v=0.0,sx2v=0.0,sy2v=0.0,sz2v=0.0,srv=0.0;
        Integer sfv=0;
        Get_item(sx1,start_edge,sx1v);Get_item(sy1,start_edge,sy1v);Get_item(sz1,start_edge,sz1v);
        Get_item(sx2,start_edge,sx2v);Get_item(sy2,start_edge,sy2v);Get_item(sz2,start_edge,sz2v);
        Get_item(sr,start_edge,srv);Get_item(sf,start_edge,sfv);
        rx[1]=sx1v;ry[1]=sy1v;rz[1]=sz1v;
        rr[1]=srv;rf[1]=sfv;
        Real startx=rx[1],starty=ry[1];
        Real cx=sx2v,cy=sy2v,cz=sz2v;
        Set_item(used,start_edge,TRUE);

        while(!same_xy(cx,cy,startx,starty) && !failed)
        {
            Integer next=0,nmatch=0,reverse=FALSE;
            for(j=1;j<=seg_count;j++)
            {
                Integer occ=0,is_used=FALSE,own1=0;
                Real x1v=0.0,y1v=0.0,x2v=0.0,y2v=0.0;
                Get_item(occurrence,j,occ);
                Get_item(used,j,is_used);
                Get_item(owner1,j,own1);
                if(occ!=1 || is_used ||
                   uf_find(own1,parent)!=root)continue;
                Get_item(sx1,j,x1v);Get_item(sy1,j,y1v);
                Get_item(sx2,j,x2v);Get_item(sy2,j,y2v);
                if(same_xy(x1v,y1v,cx,cy))
                {
                    next=j;reverse=FALSE;nmatch++;
                }
                else if(same_xy(x2v,y2v,cx,cy))
                {
                    next=j;reverse=TRUE;nmatch++;
                }
            }
            if(nmatch!=1)
            {
                failed=TRUE;
                error="External boundary is open or branches. Check shared boundary segmentation.";
                break;
            }
            if(rn>=MAX_RING_POINTS)
            {
                failed=TRUE;
                error="A result ring exceeds MAX_RING_POINTS.";
                break;
            }

            rn++;
            rx[rn]=cx;ry[rn]=cy;rz[rn]=cz;
            Real next_r=0.0,next_x1=0.0,next_y1=0.0,next_z1=0.0;
            Real next_x2=0.0,next_y2=0.0,next_z2=0.0;
            Integer next_f=0;
            Get_item(sr,next,next_r);Get_item(sf,next,next_f);
            Get_item(sx1,next,next_x1);Get_item(sy1,next,next_y1);Get_item(sz1,next,next_z1);
            Get_item(sx2,next,next_x2);Get_item(sy2,next,next_y2);Get_item(sz2,next,next_z2);
            if(reverse)
            {
                rr[rn]=-next_r;rf[rn]=next_f;
                cx=next_x1;cy=next_y1;cz=next_z1;
            }
            else
            {
                rr[rn]=next_r;rf[rn]=next_f;
                cx=next_x2;cy=next_y2;cz=next_z2;
            }
            Set_item(used,next,TRUE);
        }
        if(failed)break;

        for(j=1;j<=seg_count;j++)
        {
            Integer occ=0,is_used=FALSE,own1=0;
            Get_item(occurrence,j,occ);
            Get_item(used,j,is_used);
            Get_item(owner1,j,own1);
            if(occ==1 && !is_used &&
               uf_find(own1,parent)==root)
            {
                failed=TRUE;
                error="A component produced more than one ring. Holes, duplicates or complex overlap are unsupported.";
                break;
            }
        }
        if(failed)break;

        Element result=Create_super(0,rn);
        Text result_type="";
        if(Get_type(result,result_type)!=0 || result_type!="Super")
        {
            failed=TRUE;
            error="Create_super did not return a valid Super string.";
            break;
        }
        if(Set_super_use_3d_level(result,1)!=0)
        {
            Element_delete(result);
            failed=TRUE;
            error="Could not enable result 3D levels.";
            break;
        }
        if(Set_super_use_segment_radius(result,1)!=0)
        {
            Element_delete(result);
            failed=TRUE;
            error="Could not enable result segment radii.";
            break;
        }
        for(j=1;j<=rn;j++)
        {
            if(Set_super_data(result,j,rx[j],ry[j],rz[j],rr[j],rf[j])!=0)
            {
                Element_delete(result);
                failed=TRUE;
                error="Could not write result Super vertex data.";
                break;
            }
        }
        if(failed)break;
        if(String_close(result)!=0)
        {
            Element_delete(result);
            failed=TRUE;
            error="Could not close a result Super string.";
            break;
        }
        Integer result_closed=FALSE,result_self=FALSE;
        if(String_closed(result,result_closed)!=0 || !result_closed)
        {
            Element_delete(result);
            failed=TRUE;
            error="The created result is not closed.";
            break;
        }
        if(String_self_intersects(result,result_self)!=0 || result_self)
        {
            Element_delete(result);
            failed=TRUE;
            error="The created result self-intersects.";
            break;
        }
        result_count++;
        results[result_count]=result;
    }

    if(failed)
    {
        cleanup_results(results,result_count);
        result_count=0;
        return(FALSE);
    }
    return(TRUE);
}

/*-------------------- OPTIONAL HOLE HELPERS ------------------------*/

Integer Polygon_has_shared_segment(Element a,Element b)
{
    Integer na=0,nb=0;
    if(Get_points(a,na)!=0 || na<3)return(FALSE);
    if(Get_points(b,nb)!=0 || nb<3)return(FALSE);

    Real afx=0.0,afy=0.0,afz=0.0,afr=0.0;
    Integer aff=0;
    if(Get_super_data(a,1,afx,afy,afz,afr,aff)!=0)return(FALSE);
    Real apx=afx,apy=afy,apz=afz,apr=afr;
    Integer apf=aff;
    Integer ia=0,ib=0;

    for(ia=2;ia<=na+1;ia++)
    {
        Real acx=0.0,acy=0.0,acz=0.0,acr=0.0;
        Integer acf=0;
        if(ia==na+1)
        {
            acx=afx;acy=afy;acz=afz;acr=afr;acf=aff;
        }
        else if(Get_super_data(a,ia,acx,acy,acz,acr,acf)!=0)
            return(FALSE);

        Real a1x=apx,a1y=apy,a1z=apz;
        Real a2x=acx,a2y=acy,a2z=acz;
        Real ar=apr;
        Integer amajor=apf;
        if(!endpoint_before(a1x,a1y,a2x,a2y))
        {
            Real tx=a1x,ty=a1y,tz=a1z;
            a1x=a2x;a1y=a2y;a1z=a2z;
            a2x=tx;a2y=ty;a2z=tz;
            ar=-ar;
        }
        if(Absolute(ar)<=ARC_TOL)
        {
            ar=0.0;
            amajor=0;
        }

        Real bfx=0.0,bfy=0.0,bfz=0.0,bfr=0.0;
        Integer bff=0;
        if(Get_super_data(b,1,bfx,bfy,bfz,bfr,bff)!=0)return(FALSE);
        Real bpx=bfx,bpy=bfy,bpz=bfz,bpr=bfr;
        Integer bpf=bff;

        for(ib=2;ib<=nb+1;ib++)
        {
            Real bcx=0.0,bcy=0.0,bcz=0.0,bcr=0.0;
            Integer bcf=0;
            if(ib==nb+1)
            {
                bcx=bfx;bcy=bfy;bcz=bfz;bcr=bfr;bcf=bff;
            }
            else if(Get_super_data(b,ib,bcx,bcy,bcz,bcr,bcf)!=0)
                return(FALSE);

            Real b1x=bpx,b1y=bpy,b1z=bpz;
            Real b2x=bcx,b2y=bcy,b2z=bcz;
            Real br=bpr;
            Integer bmajor=bpf;
            if(!endpoint_before(b1x,b1y,b2x,b2y))
            {
                Real tx=b1x,ty=b1y,tz=b1z;
                b1x=b2x;b1y=b2y;b1z=b2z;
                b2x=tx;b2y=ty;b2z=tz;
                br=-br;
            }
            if(Absolute(br)<=ARC_TOL)
            {
                br=0.0;
                bmajor=0;
            }

            if(same_xy(a1x,a1y,b1x,b1y) &&
               same_xy(a2x,a2y,b2x,b2y) &&
               same_geometry(ar,amajor,br,bmajor))
                return(TRUE);

            bpx=bcx;bpy=bcy;bpz=bcz;bpr=bcr;bpf=bcf;
        }
        apx=acx;apy=acy;apz=acz;apr=acr;apf=acf;
    }
    return(FALSE);
}

// A candidate hole must share a complete segment with at least two
// disconnected catchment components. No hole geometry is inferred.
Integer Collect_candidate_holes(
    Element &holes[],Integer hole_count,
    Element &components[],Integer component_count,
    Element &candidate_holes[],Integer &candidate_count)
{
    candidate_count=0;
    Integer i=0,j=0;
    for(i=1;i<=hole_count;i++)
    {
        Integer touched_components=0;
        for(j=1;j<=component_count;j++)
            if(Polygon_has_shared_segment(holes[i],components[j]))
                touched_components++;

        if(touched_components>=2)
        {
            candidate_count++;
            candidate_holes[candidate_count]=holes[i];
        }
    }
    return(candidate_count>0);
}

// Creates one shell only when explicit hole polygons bridge the disconnected
// components. Each supplied hole is copied and stored as a Super hole before
// the shell is assigned to the output model.
Integer Create_catchment_from_explicit_holes(
    Element &selected_lots[],Integer selected_count,
    Element &components[],Integer component_count,
    Element &holes[],Integer hole_count,
    Element &result,Integer &holes_added,Text &error)
{
    Null(result);
    holes_added=0;
    error="";

    Element candidate_holes[MAX_POLYGONS+1];
    Integer candidate_count=0;
    if(!Collect_candidate_holes(
        holes,hole_count,components,component_count,
        candidate_holes,candidate_count))
    {
        error="No explicit hole polygon bridges at least two disconnected catchment components.";
        return(FALSE);
    }

    if(selected_count+candidate_count>MAX_POLYGONS)
    {
        error="The combined lot and hole input exceeds MAX_POLYGONS.";
        return(FALSE);
    }

    Element shell_inputs[MAX_POLYGONS+1];
    Integer i=0;
    for(i=1;i<=selected_count;i++)shell_inputs[i]=selected_lots[i];
    for(i=1;i<=candidate_count;i++)
        shell_inputs[selected_count+i]=candidate_holes[i];

    Element shell_results[MAX_POLYGONS+1];
    Integer shell_count=0;
    if(!Dissolve_lot_polygons(
        shell_inputs,selected_count+candidate_count,
        shell_results,shell_count,error))return(FALSE);

    if(shell_count!=1)
    {
        cleanup_results(shell_results,shell_count);
        error="Adding the explicit hole polygon(s) did not produce exactly one external shell.";
        return(FALSE);
    }

    if(Set_super_use_hole(shell_results[1],1)!=0)
    {
        Element_delete(shell_results[1]);
        error="Could not enable holes on the catchment Super string.";
        return(FALSE);
    }

    for(i=1;i<=candidate_count;i++)
    {
        Element hole_copy;
        if(Element_duplicate(candidate_holes[i],hole_copy)!=0)
        {
            Element_delete(shell_results[1]);
            error="Could not duplicate an explicit hole polygon.";
            return(FALSE);
        }
        if(Super_add_hole(shell_results[1],hole_copy)!=0)
        {
            Element_delete(hole_copy);
            Element_delete(shell_results[1]);
            error="Could not add an explicit hole polygon to the catchment.";
            return(FALSE);
        }
        holes_added++;
    }

    result=shell_results[1];
    return(TRUE);
}


/*------------------ CATCHMENT VERTEX ORDER HELPER ------------------*/
// Rebuilds a closed Super so vertex 1 is the boundary point nearest
// the upstream pit. Straight segments may receive an interpolated XYZ
// vertex. For arc segments, the nearer existing arc endpoint is used.
Integer Reorder_catchment_first_vertex_near_pit(
    Element &catchment,Real pit_x,Real pit_y,Real pit_z,Text &error)
{
    error="";
    Text type="";
    Integer closed=FALSE,npts=0;
    if(Get_type(catchment,type)!=0 || type!="Super")
    {
        error="Catchment is not a Super string.";
        return(FALSE);
    }
    if(String_closed(catchment,closed)!=0 || !closed)
    {
        error="Catchment is not closed.";
        return(FALSE);
    }
    if(Get_points(catchment,npts)!=0 || npts<3)
    {
        error="Catchment has fewer than three vertices.";
        return(FALSE);
    }

    Dynamic_Real vx,vy,vz,vr;
    Dynamic_Integer vf;
    Integer i=0;
    for(i=1;i<=npts;i++)
    {
        Real x=0.0,y=0.0,z=0.0,r=0.0;
        Integer f=0;
        if(Get_super_data(catchment,i,x,y,z,r,f)!=0)
        {
            error="Could not read catchment Super vertex data.";
            return(FALSE);
        }
        Set_item(vx,i,x);Set_item(vy,i,y);Set_item(vz,i,z);
        Set_item(vr,i,r);Set_item(vf,i,f);
    }

    Real best_dist=-1.0,best_x=0.0,best_y=0.0,best_z=0.0;
    Integer best_seg=0,best_vertex=0,insert_point=FALSE;
    for(i=1;i<=npts;i++)
    {
        Integer j=i+1;
        if(j>npts)j=1;
        Real ax=0.0,ay=0.0,az=0.0,bx=0.0,by=0.0,bz=0.0,r=0.0;
        Integer f=0;
        Get_item(vx,i,ax);Get_item(vy,i,ay);Get_item(vz,i,az);
        Get_item(vx,j,bx);Get_item(vy,j,by);Get_item(vz,j,bz);
        Get_item(vr,i,r);Get_item(vf,i,f);

        Real qx=0.0,qy=0.0,qz=0.0;
        Integer candidate_vertex=0,candidate_insert=FALSE;
        if(Absolute(r)>ARC_TOL)
        {
            Real da=Point_distance_2d(pit_x,pit_y,ax,ay);
            Real db=Point_distance_2d(pit_x,pit_y,bx,by);
            if(da<=db){qx=ax;qy=ay;qz=az;candidate_vertex=i;}
            else      {qx=bx;qy=by;qz=bz;candidate_vertex=j;}
        }
        else
        {
            Real dx=bx-ax,dy=by-ay;
            Real len2=dx*dx+dy*dy;
            Real t=0.0;
            if(len2>0.0)t=((pit_x-ax)*dx+(pit_y-ay)*dy)/len2;
            if(t<0.0)t=0.0;
            if(t>1.0)t=1.0;
            qx=ax+t*dx;qy=ay+t*dy;qz=az+t*(bz-az);
            if(t<=XY_TOL)candidate_vertex=i;
            else if(t>=1.0-XY_TOL)candidate_vertex=j;
            else candidate_insert=TRUE;
        }
        Real d=Point_distance_2d(pit_x,pit_y,qx,qy);
        if(best_dist<0.0 || d<best_dist)
        {
            best_dist=d;best_x=qx;best_y=qy;best_z=qz;
            best_seg=i;best_vertex=candidate_vertex;
            insert_point=candidate_insert;
        }
    }

    Integer new_count=npts;
    if(insert_point)new_count++;
    Element reordered=Create_super(0,new_count);
    Text reordered_type="";
    if(Get_type(reordered,reordered_type)!=0 || reordered_type!="Super")
    {
        error="Could not create reordered catchment Super string.";
        return(FALSE);
    }
    if(Set_super_use_3d_level(reordered,1)!=0 ||
       Set_super_use_segment_radius(reordered,1)!=0)
    {
        Element_delete(reordered);
        error="Could not enable reordered catchment Super data.";
        return(FALSE);
    }

    Integer out_index=0,source_index=0,step=0;
    if(insert_point)
    {
        out_index=1;
        if(Set_super_data(reordered,out_index,best_x,best_y,best_z,0.0,0)!=0)
        {
            Element_delete(reordered);error="Could not write inserted nearest vertex.";return(FALSE);
        }
        source_index=best_seg+1;if(source_index>npts)source_index=1;
        for(step=0;step<npts;step++)
        {
            Real x=0.0,y=0.0,z=0.0,r=0.0;Integer f=0;
            Get_item(vx,source_index,x);Get_item(vy,source_index,y);
            Get_item(vz,source_index,z);Get_item(vr,source_index,r);Get_item(vf,source_index,f);
            // The original segment containing the insertion point is split
            // into two straight segments, both with zero radius.
            if(source_index==best_seg){r=0.0;f=0;}
            out_index++;
            if(Set_super_data(reordered,out_index,x,y,z,r,f)!=0)
            {Element_delete(reordered);error="Could not write reordered catchment vertex.";return(FALSE);}
            source_index++;if(source_index>npts)source_index=1;
        }
    }
    else
    {
        source_index=best_vertex;
        for(step=0;step<npts;step++)
        {
            Real x=0.0,y=0.0,z=0.0,r=0.0;Integer f=0;
            Get_item(vx,source_index,x);Get_item(vy,source_index,y);
            Get_item(vz,source_index,z);Get_item(vr,source_index,r);Get_item(vf,source_index,f);
            out_index++;
            if(Set_super_data(reordered,out_index,x,y,z,r,f)!=0)
            {Element_delete(reordered);error="Could not write reordered catchment vertex.";return(FALSE);}
            source_index++;if(source_index>npts)source_index=1;
        }
    }
    if(String_close(reordered)!=0)
    {Element_delete(reordered);error="Could not close reordered catchment.";return(FALSE);}

    Integer hole_count=0;
    if(Get_super_holes(catchment,hole_count)==0 && hole_count>0)
    {
        if(Set_super_use_hole(reordered,1)!=0)
        {Element_delete(reordered);error="Could not enable holes on reordered catchment.";return(FALSE);}
        for(i=1;i<=hole_count;i++)
        {
            Element hole,hole_copy;
            if(Super_get_hole(catchment,i,hole)!=0 || Element_duplicate(hole,hole_copy)!=0 ||
               Super_add_hole(reordered,hole_copy)!=0)
            {Element_delete(reordered);error="Could not preserve catchment hole geometry.";return(FALSE);}
        }
    }
    Element_delete(catchment);
    catchment=reordered;
    return(TRUE);
}

/*--------------------------- PIPE PROCESS ---------------------------*/
Integer Process_pipe_catchment(
    Element drainage,Integer pipe_index,Integer flow,
    Dynamic_Element &connections,Integer connection_count,
    Element &lots[],Integer lot_count,
    Element &holes[],Integer hole_count,
    Model output_model,Real tolerance,
    Log_Box lb,Undo_List &undo_list,
    Integer &direct_connections,Integer &unique_lots,
    Integer &catchments_created)
{
    Integer us_pit=pipe_index;
    Integer ds_pit=pipe_index+1;
    if(flow==0)
    {
        us_pit=pipe_index+1;
        ds_pit=pipe_index;
    }

    Segment pipe;
    if(Get_segment(drainage,pipe_index,pipe)!=0)return(FALSE);
    Real usx=0.0,usy=0.0,usz=0.0;
    Real dsx=0.0,dsy=0.0,dsz=0.0;
    if(Get_drainage_pit(drainage,us_pit,usx,usy,usz)!=0)return(FALSE);
    if(Get_drainage_pit(drainage,ds_pit,dsx,dsy,dsz)!=0)return(FALSE);

    Text pit_name="";

    Get_drainage_pit_attribute(drainage, us_pit, "pit name", pit_name);

     if(pit_name=="")
    {
        Get_drainage_pit_name(
            drainage,
            us_pit,
            pit_name);
    }

    if(pit_name=="")
    {
        pit_name="Pit_"+To_text(us_pit);
    }
    Integer selected_indices[MAX_POLYGONS+1];
    Element selected_lots[MAX_POLYGONS+1];
    Integer selected_count=0;
    Integer i=0;

    for(i=1;i<=connection_count;i++)
    {
        Element connection;
        if(Get_item(connections,i,connection)!=0)continue;
        Real lot_x=0.0,lot_y=0.0,lot_z=0.0;
        Integer attached=Connection_belongs_to_pipe(
            connection,pipe,usx,usy,dsx,dsy,tolerance,
            lot_x,lot_y,lot_z);
        if(!attached)continue;

        direct_connections++;
        Integer lot_index=0;
        Integer find_rc=Find_containing_lot(
            lots,lot_count,lot_x,lot_y,lot_index);
        if(find_rc==1)
        {
            log_warn(lb,"Pit "+pit_name+": no selected lot contains connection vertex 1.");
            continue;
        }
        if(find_rc==2)
        {
            log_warn(lb,"Pit "+pit_name+": connection vertex 1 is inside multiple selected lots; connection skipped.");
            continue;
        }
        if(Lot_index_already_collected(
            lot_index,selected_indices,selected_count))continue;
        if(selected_count>=MAX_POLYGONS)
        {
            log_err(lb,"Pit "+pit_name+": too many unique lots. Increase MAX_POLYGONS.");
            return(FALSE);
        }
        selected_count++;
        selected_indices[selected_count]=lot_index;
        selected_lots[selected_count]=lots[lot_index];
        unique_lots++;
    }

    if(selected_count==0)
    {
        log_warn(lb,"Pit "+pit_name+": no catchment created because no unique connected lots were found.");
        return(TRUE);
    }

    Element staged[MAX_POLYGONS+1];
    Integer staged_count=0;
    Text error="";
    if(selected_count==1)
    {
        if(Element_duplicate(selected_lots[1],staged[1])!=0)
        {
            log_err(lb,"Pit "+pit_name+": could not duplicate the single source lot.");
            return(FALSE);
        }
        staged_count=1;
    }
    else
    {
        if(!Dissolve_lot_polygons(
            selected_lots,selected_count,staged,staged_count,error))
        {
            log_err(lb,"Pit "+pit_name+": dissolve failed. "+error);
            return(FALSE);
        }

        // Optional explicit-hole workflow. Hole geometry must be supplied
        // by the user in the optional Hole polygons model.
        if(staged_count>1 && hole_count>0)
        {
            Element hole_catchment;
            Integer holes_added=0;
            Text hole_error="";
            if(Create_catchment_from_explicit_holes(
                selected_lots,selected_count,
                staged,staged_count,
                holes,hole_count,
                hole_catchment,holes_added,hole_error))
            {
                cleanup_results(staged,staged_count);
                staged[1]=hole_catchment;
                staged_count=1;
                log_ok(lb,"Pit "+pit_name+": created one catchment with "+
                    To_text(holes_added)+" explicit hole polygon(s).");
            }
            else
            {
                log_warn(lb,"Pit "+pit_name+
                    ": explicit-hole conversion not applied. "+hole_error);
            }
        }
    }


    pit_name = Make_valid_12d_name(pit_name);
    for(i=1;i<=staged_count;i++)
    {
        Text catchment_name=pit_name;
        if(i>1)catchment_name=pit_name+"_"+To_text(i);

        Text reorder_error="";
        if(!Reorder_catchment_first_vertex_near_pit(
            staged[i],usx,usy,usz,reorder_error))
        {
            Integer j=0;
            for(j=i;j<=staged_count;j++)Element_delete(staged[j]);
            log_err(lb,"Pit "+pit_name+": could not reorder catchment vertices. "+reorder_error);
            return(FALSE);
        }

        Set_name(staged[i],catchment_name);
        Set_weight(staged[i],0.25);
        if(Set_model(staged[i],output_model)!=0)
        {
            Integer j=0;

            for(j=i;j<=staged_count;j++)
                Element_delete(staged[j]);

            log_err(lb,
                "Pit "+pit_name+
                ": could not add catchment to the output model.");

            return(FALSE);
        }
        Calc_extent(staged[i]);
        Element_draw(staged[i]);
        Undo u_add=Add_undo_add("Create catchment "+catchment_name,staged[i]);
        Append(u_add,undo_list);
        catchments_created++;
        add_highlight_log(lb,staged[i],"Created catchment <"+catchment_name+">");
    }

    return(TRUE);
}


Integer Process_drainage_string(
    Element drainage,
    Dynamic_Element &connections,Integer connection_count,
    Element &lots[],Integer lot_count,
    Element &holes[],Integer hole_count,
    Model output_model,Real tolerance,
    Log_Box lb,Undo_List &undo_list,
    Integer &pipes_processed,Integer &direct_connections,
    Integer &unique_lots,Integer &catchments_created)
{
    Text type="";
    if(Get_type(drainage,type)!=0 || type!="Drainage")return(FALSE);
    Integer flow=0,segment_count=0,pit_count=0;
    if(Get_drainage_flow(drainage,flow)!=0)return(FALSE);
    if(Get_segments(drainage,segment_count)!=0 || segment_count<1)return(FALSE);
    if(Get_drainage_pits(drainage,pit_count)!=0 || pit_count<2)return(FALSE);
    if(flow!=0 && flow!=1)return(FALSE);

    Integer pipe_index=0;
    for(pipe_index=1;pipe_index<=segment_count;pipe_index++)
    {
        pipes_processed++;
        Integer pipe_rc=Process_pipe_catchment(
        drainage,pipe_index,flow,
        connections,connection_count,lots,lot_count,
        holes,hole_count,output_model,tolerance,lb,undo_list,
        direct_connections,unique_lots,catchments_created);
        if(!pipe_rc)return(FALSE);
    }
    return(TRUE);
}

/*----------------------------- PANEL -------------------------------*/
void mainPanel()
{
    Text panelName="Create Catchments From Lot Connections";
    Panel panel=Create_panel(panelName,TRUE);
    Vertical_Group vgroup=Create_vertical_group(-1);
    Colour_Message_Box cmbMsg=Create_colour_message_box("");

    Source_Box sb_drainage=Create_source_box("Drainage strings",cmbMsg,0);
    Model_Box mb_connections=Create_model_box(
        "Lot connection model",cmbMsg,CHECK_MODEL_MUST_EXIST);
    Model_Box mb_lots=Create_model_box(
        "Lot boundary model",cmbMsg,CHECK_MODEL_MUST_EXIST);
    Model_Box mb_holes=Create_model_box(
        "Hole polygons model (optional)",cmbMsg,CHECK_MODEL_MUST_EXIST);
    Set_optional(mb_holes,TRUE);
    Model_Box mb_output=Create_model_box(
        "Output catchment model",cmbMsg,CHECK_MODEL_CREATE);
    Real_Box rb_tolerance=Create_real_box(
        "Pipe/pit connection tolerance",cmbMsg);
    Set_data(rb_tolerance,0.01);
    Log_Box lb=Create_log_box("Log",600,150);

    Horizontal_Group bgroup=Create_button_group();
    Button process=Create_button("&Process","process");
    Button finish=Create_finish_button("Finish","Finish");
    Button help_button=Create_help_button(panel,"Help");
    Append(process,bgroup);
    Append(finish,bgroup);
    Append(help_button,bgroup);

    Append(sb_drainage,vgroup);
    Append(mb_connections,vgroup);
    Append(mb_lots,vgroup);
    Append(mb_holes,vgroup);
    Append(mb_output,vgroup);
    Append(rb_tolerance,vgroup);
    Append(lb,vgroup);
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
                Clear(lb);
                Dynamic_Element drainage_selection;
                if(Validate(sb_drainage,drainage_selection)!=TRUE)
                {
                    Set_data(cmbMsg,"Select at least one drainage string.",2);
                    break;
                }
                Integer drainage_count=0;
                if(Get_number_of_items(
                    drainage_selection,drainage_count)!=0 || drainage_count<1)
                {
                    Set_data(cmbMsg,"Select at least one drainage string.",2);
                    break;
                }

                Model connection_model;
                if(Validate(mb_connections,CHECK_MODEL_MUST_EXIST,
                    connection_model)!=MODEL_EXISTS)
                {
                    Set_data(cmbMsg,"Select an existing lot connection model.",2);
                    break;
                }

                Model lot_model;
                if(Validate(mb_lots,CHECK_MODEL_MUST_EXIST,
                    lot_model)!=MODEL_EXISTS)
                {
                    Set_data(cmbMsg,"Select an existing lot boundary model.",2);
                    break;
                }

                Model hole_model;
                Integer use_hole_model=FALSE;
                Integer hole_model_rc=Validate(
                    mb_holes,CHECK_MODEL_MUST_EXIST,hole_model);
                if(hole_model_rc==MODEL_EXISTS)
                    use_hole_model=TRUE;
                else if(hole_model_rc!=NO_NAME)
                {
                    Set_data(cmbMsg,
                        "Select an existing hole polygon model or leave it blank.",2);
                    break;
                }

                Model output_model;
                if(Validate(mb_output,GET_MODEL_CREATE,
                    output_model)!=MODEL_EXISTS)
                {
                    Set_data(cmbMsg,"Provide a valid output catchment model.",2);
                    break;
                }

                Real tolerance=0.0;
                if(Validate(rb_tolerance,tolerance)!=TRUE || tolerance<0.0)
                {
                    Set_data(cmbMsg,"Connection tolerance must be zero or greater.",2);
                    break;
                }


                Dynamic_Element connection_elements;
                Integer raw_connection_count=0;
                if(Get_elements(connection_model,connection_elements,
                    raw_connection_count)!=0)
                {
                    Set_data(cmbMsg,"Unable to read the lot connection model.",2);
                    break;
                }

                Dynamic_Element lot_elements;
                Integer raw_lot_count=0;
                if(Get_elements(lot_model,lot_elements,raw_lot_count)!=0)
                {
                    Set_data(cmbMsg,"Unable to read the lot boundary model.",2);
                    break;
                }

                /* v009: use Dynamic_Element instead of fixed 50,000-element connection array. */
                Dynamic_Element connections;
                Integer connection_count=0;
                Integer i=0;
                for(i=1;i<=raw_connection_count;i++)
                {
                    Element e;
                    if(Get_item(connection_elements,i,e)!=0)continue;
                    Real x1=0.0,y1=0.0,z1=0.0,x2=0.0,y2=0.0,z2=0.0;
                    if(!Get_lot_connection_vertices(
                        e,x1,y1,z1,x2,y2,z2))continue;
                    if(connection_count>=MAX_SEGMENTS)
                    {
                        Set_data(cmbMsg,"Too many valid lot connections. Increase MAX_SEGMENTS.",2);
                        connection_count=0;
                        break;
                    }
                    connection_count++;
                    if(Set_item(connections,connection_count,e)!=0)
                    {
                        Set_data(cmbMsg,"Unable to add valid lot connection to dynamic list.",2);
                        connection_count=0;
                        break;
                    }
                }

                if(connection_count<1)
                {
                    Set_data(cmbMsg,"No valid two-vertex Super lot connections were found.",2);
                    break;
                }

                Element lots[MAX_POLYGONS+1];
                Integer lot_count=0,invalid_lots=0;
                for(i=1;i<=raw_lot_count;i++)
                {
                    Element e;
                    if(Get_item(lot_elements,i,e)!=0)continue;
                    Text validation_error="";
                    if(!Validate_lot_polygon(e,validation_error))
                    {
                        Text type="";
                        Get_type(e,type);
                        if(type=="Super")
                        {
                            invalid_lots++;
                            log_warn(lb,"Skipped invalid lot polygon: "+validation_error);
                        }
                        continue;
                    }
                    if(lot_count>=MAX_POLYGONS)
                    {
                        Set_data(cmbMsg,"Too many valid lot polygons. Increase MAX_POLYGONS.",2);
                        lot_count=0;
                        break;
                    }
                    lot_count++;
                    lots[lot_count]=e;
                }

                if(lot_count<1)
                {
                    Set_data(cmbMsg,"No valid closed Super lot polygons were found.",2);
                    break;
                }

                Element holes[MAX_POLYGONS+1];
                Integer hole_count=0,invalid_holes=0;
                if(use_hole_model)
                {
                    Dynamic_Element hole_elements;
                    Integer raw_hole_count=0;
                    if(Get_elements(hole_model,hole_elements,raw_hole_count)!=0)
                    {
                        Set_data(cmbMsg,"Unable to read the optional hole polygon model.",2);
                        break;
                    }
                    for(i=1;i<=raw_hole_count;i++)
                    {
                        Element e;
                        if(Get_item(hole_elements,i,e)!=0)continue;
                        Text validation_error="";
                        if(!Validate_lot_polygon(e,validation_error))
                        {
                            Text type="";
                            Get_type(e,type);
                            if(type=="Super")
                            {
                                invalid_holes++;
                                log_warn(lb,"Skipped invalid hole polygon: "+
                                    validation_error);
                            }
                            continue;
                        }
                        if(hole_count>=MAX_POLYGONS)
                        {
                            Set_data(cmbMsg,
                                "Too many valid hole polygons. Increase MAX_POLYGONS.",2);
                            hole_count=0;
                            break;
                        }
                        hole_count++;
                        holes[hole_count]=e;
                    }
                    if(raw_hole_count>0 && hole_count<1)
                    {
                        Set_data(cmbMsg,
                            "The optional hole model contains no valid closed Super polygons.",2);
                        break;
                    }
                }

                Undo_List undo_list;
                Null(undo_list);
                Integer drainage_processed=0,pipes_processed=0;
                Integer direct_connections=0,unique_lots=0;
                Integer catchments_created=0;
                
                for(i=1;i<=drainage_count;i++)
                {
                    Element drainage;
                    if(Get_item(drainage_selection,i,drainage)!=0)continue;
                    drainage_processed+=Process_drainage_string(
                        drainage,connections,connection_count,
                        lots,lot_count,holes,hole_count,output_model,tolerance,
                        lb,undo_list,pipes_processed,direct_connections,
                        unique_lots,catchments_created);
                }
                Null(drainage_selection);
                if(catchments_created>0)
                    Add_undo_list("Create Catchments From Lot Connections",undo_list);

                Text summary="Finished. Drainage strings: "+
                    To_text(drainage_processed)+", pipes: "+
                    To_text(pipes_processed)+", direct connections: "+
                    To_text(direct_connections)+", unique lots: "+
                    To_text(unique_lots)+", catchments: "+
                    To_text(catchments_created);
                if(use_hole_model)
                    summary=summary+", valid hole polygons: "+To_text(hole_count);
                if(invalid_lots>0)
                    summary=summary+", invalid lot polygons skipped: "+
                        To_text(invalid_lots);
                if(invalid_holes>0)
                    summary=summary+", invalid hole polygons skipped: "+
                        To_text(invalid_holes);
                Set_data(cmbMsg,summary);

                log_ok(lb,summary);
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
