// ----------------------------- INCLUDES -----------------------------
#include "..\\..\\include\\standard_library.H"
#include "..\\..\\include\\size_of.H"

#define macro_VER "14.00"
#define tested_ver_lower "V10C1k"
#define tested_ver_upper "V10C1k"

#define Attribute_Integer 1
#define Attribute_Real    2
#define Attribute_Text    3
#define Attribute_Binary  4
#define Attribute_Group   5
#define Attribute_Uid     6

Integer company_about_panel(Panel panel)
// -----------------------------------------------------------------------
// -----------------------------------------------------------------------
	{
	Hide_widget(panel);

	Text macro_name = get_macro_name();

#if defined(__BASE_FILE_DATE__)
	Text date       = __BASE_FILE_DATE__;
#else
	Text date       = __DATE__;
#endif

	fix_date(date);

	Panel            panel3          = Create_panel("About Macro");
	Vertical_Group   vgroup          = Create_vertical_group(-1);
	Vertical_Group   vgroup2         = Create_vertical_group(-1);
	Message_Box      main_message    = Create_message_box(" ");

	Vertical_Group bgroup          = Create_vertical_group(0);

	Set_border(bgroup,"Macro Name");
	Draw_Box draw_box = Create_draw_box(180,180,0);

	Screen_Text screen_txt1 = Create_screen_text(macro_name+".4do" + "  v" + macro_VER);
	Append(screen_txt1,bgroup);
	Screen_Text screen_txt7 = Create_screen_text("Tested for: " + tested_ver_lower + " to " + tested_ver_upper);
	Append(screen_txt7,bgroup);
	Append(bgroup,vgroup);

	Horizontal_Group bgroup2          = Create_button_group();

	Set_border(bgroup2,"Date Compiled");

	Screen_Text screen_txt2 = Create_screen_text(date);
	Append(screen_txt2,bgroup2);

	Append(bgroup2,vgroup);

	Vertical_Group bgroup6          = Create_vertical_group(1);

	Set_border(bgroup6,"-");
	HyperLink_Box   hyper_box =  Create_hyperlink_box   ("forum",  main_message);
	Set_data               (  hyper_box,"forums.12dmodel.com/macros.php");
	Append(hyper_box,bgroup6);

	HyperLink_Box wwwbox = Create_hyperlink_box("www",  main_message);
	Set_data(wwwbox,"www.12d.com");
	Append(wwwbox,bgroup6);

	Append(bgroup6,vgroup);


	Horizontal_Group bgroup4          = Create_horizontal_group(-1);

	Append(draw_box,bgroup4);
	Append(vgroup,bgroup4);
	Append(bgroup4,vgroup2);

	Horizontal_Group bgroup3          = Create_button_group();

	Button okbut = Create_button  ("OK" ,"OK");
	Set_width_in_chars(okbut,5);

	Append(okbut  ,bgroup3);

	Append(bgroup3,vgroup2);
	Append(vgroup2,panel3);

	Show_widget(panel3,350,300);
	Integer doit = 1;

	Integer draw_box_width,draw_box_height;
	Get_size(draw_box,draw_box_width,draw_box_height);

	Text logo_file = "$LIB/4dlogo2.bmp";

	Text company_logo = replace_user_4d    ("$USER/companyLogo.bmp");
	if ( File_exists(company_logo) != 0 )
		{
		logo_file = company_logo;
		}
	Text path = replace_lib_4d(logo_file);

	Start_batch_draw(draw_box);

////the following RGB values match my screen setup
////set it to Clear(draw_box,-1,0,0) to see if you can get the window default
////or if that doesn't work set it to your RGB values

	Clear(draw_box,192,192,192);
	//Draw_transparent_BMP(draw_box,path,0,draw_box_height-0);
	Draw_BMP(draw_box,path,0,draw_box_height-0);
	End_batch_draw(draw_box);

	while(doit)
		{

		Integer id;
		Text    cmd;
		Text    msg;
		Integer ret = Wait_on_widgets(id,cmd,msg);  // this processes standard messages first ?

		switch(id)
			{
			case Get_id(panel3) :
					{
					if(cmd == "Panel Quit")
						{
						doit = 0;
						}
					}
				break;

			case Get_id(okbut) :
					{
					doit = 0;
					}
				break;
			}
		}
	Show_widget(panel);

	return(0);
	}



Text mm_to_meters(Real value,Integer decimals)
	{
	Real met = value * 0.001;
	Text meter = To_text(met,decimals);

	return(meter);
	}

Text meters_to_mm(Real value,Integer decimals)
	{
	Real mil = value * 1000;
	Text mm = To_text( mil,decimals);

	return(mm);
	}


Text mm_to_meters(Text value,Integer decimals)
	{
	Real met = 0;
	From_text(value,met);
	met = met * 0.001;
	Text meter = To_text(met,decimals);

	return(meter);
	}

Text meters_to_mm(Text value,Integer decimals)
	{
	Real mil = 0;
	From_text(value,mil);
	mil = mil * 1000;
	Text mm = To_text( mil,decimals);

	return(mm);
	}




Integer dynamic_elements_duplicate(Dynamic_Element  elts,Dynamic_Element &dup)
	{
	// returns ZERO when all duplicated aOK
	// returns number of failed elements if not Zero
	Null(dup);
	Integer erro = 0;

	Integer no_items;
	Get_number_of_items(elts, no_items);

	for (Integer j = 1; j <= no_items; j++)
		{
		Element string,changed;
		Get_item (elts,j,string);
		if (  Element_duplicate(string,changed) == 0 )
			{
			Append(changed,dup);
			}
		else
			{
			erro +=1;
			}
		}
	return(erro);
	}

//.................
//.................


Integer get_element_locks(Element &elt, Integer &read_locks,Integer &write_locks, Integer &both_locks )
	{
	// get both element locks at the same time and return 0 for no lock in each case
	// note Read locks normally give 1 for no locks but write locks give 0
	// this code brings them in line and both return 0 for no locks
	Integer no_locks = 0;

	Get_read_locks (elt,no_locks);
	if ( no_locks == 1 )
		{
		read_locks = 0;
		}
	else
		{
		read_locks = no_locks;
		}

	no_locks = 0;
	Get_write_locks(elt,no_locks);
	write_locks = no_locks;
	both_locks = read_locks+write_locks;

	return(0);
	}
//.................
//.................


Integer get_elements_locks(Dynamic_Element model_elts,Integer &no_locks)
	{
	// get no of locks in a model

	Integer retval = 0;
	no_locks = 0;

	Integer num_elts;
	Get_number_of_items(model_elts,num_elts);

	for(Integer i=1; i<=num_elts; i++)   // step through each element
		{
		Element element;
		Get_item(model_elts,i,element);

		Integer no_r_locks,no_w_locks, both_locks ;
		get_element_locks(element, no_r_locks,no_w_locks, both_locks );
		retval += both_locks;
		}
	no_locks = retval;
	Null(model_elts);
	return(retval); // 0 = no locks, 1++ = number of locks
	}

//.................
//.................


Integer clean_model(Model &model)
// -------------------------------------------------------------------
// clean (delete) all elements in a model
// -------------------------------------------------------------------
	{
	Dynamic_Element elts;
	Integer         no_elts;
	Get_elements(model,elts,no_elts);

	for(Integer i=1; i<=no_elts; i++)
		{
		Element str;
		Get_item(elts,i,str);
		Element_delete(str);
		}
	Null(elts);
	return(0);
	}


Integer get_model_locks(Model &a_model,Integer &no_locks)
	{
	// get no of locks in a model

	Integer retval = 0;
	no_locks = 0;

	Dynamic_Element model_elts;
	Integer num_elts;
	Get_elements(a_model,model_elts,num_elts);

	for(Integer i=1; i<=num_elts; i++)   // step through each element
		{
		Element element;
		Get_item(model_elts,i,element);

		Integer no_r_locks,no_w_locks, both_locks ;
		get_element_locks(element, no_r_locks,no_w_locks, both_locks );
		retval += both_locks;
		}
	no_locks = retval;
	Null(model_elts);
	return(retval); // 0 = no locks, 1++ = number of locks
	}

//.................
//.................

Integer check_locks_delete_model(Model &model,Message_Box &message)
	{
	//-----------------------------------------------------------
	// clean models if not locked
	// and report to message if fails
	// returns 1 if failed clean due to locked strings
	Integer  no_locks;
	get_model_locks(model,no_locks);

	Text model_name;
	if ( no_locks >= 1 )
		{
		Get_name(model, model_name);
		//Print("\Model: " + model_name + " is LOCKED! Please unlock all elements - click [ESC] key\n");
		Set_data(message, "Model: " + model_name + " is LOCKED! error");
		return(1);
		}
	else
		{
		clean_model(model);
		Model_delete(model);
		}
	return(0);
	}
//.................
//.................
Integer post_text(Text  intext,Text  inwild,Text &post)
	{
	//ignores CASE
	// prepost = zero is no wildcard exists returns blanks
	// prepost = 1 if wildcard does exist and returns text
	// prepost = 2 if option fails

	Text text = Text_lower(intext);
	Text wild = Text_lower(inwild);


	Integer end = Text_length(text);
	Integer lw = Text_length(wild);

	Integer start = Find_text( text,wild);
	if ( start == 0 )
		{
		post = "";
		return(0);
		}
	else
		{
		post = Get_subtext(text,start + lw,end);
		return(1);
		}
	return(2);
	}


Integer get_super_vertex_attribute_text (Element item ,Integer vt ,Text att_name,Text &size)
	{

Integer ers=0;

	if ( Super_vertex_attribute_exists (item, vt ,att_name) != 0   ) {

		Integer att_type=-9099909;
		Get_super_vertex_attribute_type      (item,vt,att_name,att_type);


		if(att_type == Attribute_Text) {

			Text value="";
			ers=Get_super_vertex_attribute (item ,vt, att_name,size);
			}
		else if(att_type == Attribute_Integer) {

			Integer value=0;
			ers=Get_super_vertex_attribute (item ,vt, att_name,value);
			size =  To_text(value);
			}
		else if(att_type == Attribute_Real) {

			Real value=0;
			ers=Get_super_vertex_attribute (item ,vt, att_name,value);
			size =  To_text(value);
			} else{
			size = "";
			}

		}


return(ers );

	}




Integer get_attribute_text(Attributes string ,Integer no,Integer atttype, Text &attvalue )
	{

	if (   atttype  == Attribute_Text )
		{
		Get_attribute(string,no,  attvalue );
		return(0);
		}

	else if ( atttype  ==  Attribute_Real )
		{
		Real att=0;

		Get_attribute(string,no, att );
		attvalue = To_text(att ) ;
		return(0);
		}

	else if (  atttype  == Attribute_Integer  )
		{
		Integer att=0;

		Get_attribute(string,no, att );
		attvalue = To_text(att ) ;
		return(0);
		}

	else if ( atttype  ==  Attribute_Uid )
		{
		Uid att;

		Get_attribute(string,no, att );
		attvalue = To_text(att ) ;
		return(0);
		}

	return(-1);
	}

Integer get_unique_name(Text pitName,Dynamic_Text &pit_uniq_names,Dynamic_Integer  &pit_uniq_index)
	{
	Integer num_i;
	Get_number_of_items(pit_uniq_names,num_i);

	for(Integer i=1; i<=num_i; i++)   // step through each element
		{
		Text element;
		Get_item(pit_uniq_names,i,element);

		if (  pitName == element )
			{
			//get last index
			Integer inde=0;
			Get_item(pit_uniq_index,i,inde);
			inde += 1;
			Set_item(pit_uniq_index,i,inde);
			return(inde);
			}
		}
	Append( pitName, pit_uniq_names  );
	Append( 0, pit_uniq_index  );

	return(0);
	}




Text get_unique_name(Attributes attr,Text name)
	{
	Integer count = 0;
	Text ne_name = name + To_text(count);

	while ( Attribute_exists (  attr,ne_name) != 0 )
		{
		++count;
		ne_name = name + To_text(count);
		}
	return(ne_name);
	}


Text get_unique_pipe_name(Element detm,Integer K,Text name)
	{
	Integer count = 0;
	Text ne_name = name + To_text(count);

	while ( Drainage_pipe_attribute_exists (  detm,K,ne_name) != 0 )
		{
		++count;
		ne_name = name + To_text(count);
		}
	return(ne_name);
	}


Integer attributes_to_delim_text(Attributes att, Text delim, Text &data)
	{

	Integer   no_atts=0;
	Get_number_of_attributes(  att , no_atts) ;
	for (Integer a=1; a<=no_atts; a++)
		{

		Integer  att_type;
		Get_attribute_type    (  att ,  a,   att_type);

		Text one="";
		get_attribute_text(  att ,a,  att_type ,  one) ;

		Text  name;
		Get_attribute_name  (  att,  a, name);

		data += name + delim + one + delim;

		}

	return(0);
	}


//get_matching_att_pt_value       (  atts,         "has points" ,"Point " , "Point ID" ,"Diameter" ,   DpointNo,       Dvalue );


Integer get_matching_att_pt_value (Attributes atts,Text myValid, Text wild, Text atName, Text atValue, Text &pointNo,  Real &value)
	{

	Integer has_no;
	if ( Attribute_exists        (  atts,myValid,has_no) != 0 )
		{

		Text usehere="0";
		Get_attribute (  atts ,has_no,usehere);
		if ( usehere == "1" )
			{

			Integer   no_atts=0;
			Get_number_of_attributes(  atts, no_atts) ;
			for (Integer a=no_atts; a>=1; a--)
				{

				Integer  att_type;
				Get_attribute_type    (  atts ,  a,   att_type);
				if ( att_type == Attribute_Group )
					{

					Text nameone;
					Get_attribute_name (  atts, a ,nameone);
					if ( Match_name(nameone,wild +"*") != 0 )
						{

						Attributes pointAts;
						Get_attribute (  atts, a ,pointAts);


						value = 0;
						Get_attribute (  pointAts , atValue,value);
						pointNo = "";
						Get_attribute (  pointAts , atName,pointNo);

						return(1);
						}

					}
				}

			}
		}

	return(0);
	}


Integer get_matching_att_pt_value (Attributes atts,Text myValid, Text wild, Text atName, Text atValue, Text &pointNo,  Text &value)
	{

	Integer has_no;
	if ( Attribute_exists        (  atts,myValid,has_no) != 0 )
		{

		Text usehere="0";
		Get_attribute (  atts ,has_no,usehere);
		if ( usehere == "1" )
			{

			Integer   no_atts=0;
			Get_number_of_attributes(  atts, no_atts) ;
			for (Integer a=no_atts; a>=1; a--)
				{

				Integer  att_type;
				Get_attribute_type    (  atts ,  a,   att_type);
				if ( att_type == Attribute_Group )
					{

					Text nameone;
					Get_attribute_name (  atts, a ,nameone);
					if ( Match_name(nameone,wild +"*") != 0 )
						{

						Attributes pointAts;
						Get_attribute (  atts, a ,pointAts);


						value = "";
						Get_attribute (  pointAts , atValue,value);
						pointNo = "";
						Get_attribute (  pointAts , atName,pointNo);

						return(1);
						}

					}
				}

			}
		}

	return(0);
	}
/*
Integer get_matching_att_pt_value (Attributes atts,Text myValid,Text subName , Text wild, Text atName, Text &pointNo,  Real &value)
{
    Integer   no_atts=0;
    Get_number_of_attributes(  atts, no_atts) ;
    for (Integer a=no_atts; a>=1; a--)
    {
        //loop all attributes
        Integer  att_type;
        Get_attribute_type    (  atts ,  a,   att_type);
        if ( att_type == Attribute_Text )
        {
            //if it is a text attribute
            Text  name;
            Get_attribute_name  (  atts,  a, name);
            //check if the name matches wildcard

            if ( name == myValid )
            {
                Text usehere="0";
                Get_attribute (  atts ,name,usehere);
                if ( usehere == "1" )
                {
                    //ok we have a points here
                    Attributes pointAttributes;
                    Get_attribute (  atts, subName ,pointAttributes);


                    Integer   ts=0;
                    Get_number_of_attributes(  pointAttributes, ts) ;
                    for (Integer b=ts; b>=1; b--)
                    {
                        Text nameone;
                        Get_attribute_name (  pointAttributes, b ,nameone);
                        if ( Match_name(nameone,wild +"*") != 0 )
                        {
                            //match

                            pointNo = "";
                            if ( post_text(nameone,wild,pointNo) == 1  )
                            {
                                Attributes pointAts;
                                Get_attribute (  pointAttributes, b ,pointAts);


                                value = 0;
                                Get_attribute (  pointAts , atName,value);

                                return(1);
                            }
                        }


                    }
                }



            }


        }

    }

    return(0);
}
*/


Integer fix_9999_error(Real &value,Real replacewith )
	{
	if ( value < -90 || value > 9999 )
		{
		value = replacewith;
		}
	return(0);
	}


Integer del_att_value(Attributes &topa,Text att_name)
	{
	Integer eek=1;
	if ( Attribute_exists(  topa, att_name ) != 0 )
		{
		eek=Attribute_delete        ( topa,  att_name );
		}
	return(eek);
	}




Integer  text_first_item(Text line, Text &word)
	{

	Dynamic_Text  dtext;
	From_text(  line,   dtext);
	Get_item(dtext,1,word);
	Null(dtext);
	return(0);
	}



void PrintINT(Integer Value)
	{
	Text text = To_text(Value);
	Print(text);
	Print("\n");

	}

void PrintREAL(Real Value)
	{
	Text text = To_text(Value,5);
	Print(text);
	Print("\n");

	}

Text lower_trim( Text  number  )
	{
	Text  trimmed = Text_lower(number);
	//removes start end spaces
	//trimmed = number;
	Integer end = Numchr(trimmed);
	Text first = Get_subtext(trimmed,1,1);
	while ( first == " "   )
		{
		trimmed = Get_subtext(trimmed,2,end);
		end = Numchr(trimmed);
		first = Get_subtext(trimmed,1,1);
		}

	Text last = Get_subtext(trimmed,end-1,end);
	while ( last == " "   )
		{
		trimmed = Get_subtext(trimmed,1,end-1);
		end = Numchr(trimmed);
		last = Get_subtext(trimmed,end-1,end);
		}

	return(trimmed);
	}

Text trim( Text  number  )
	{
	Text  trimmed = number;
	//removes start end spaces
	trimmed = number;
	Integer end = Numchr(trimmed);
	Text first = Get_subtext(trimmed,1,1);
	while ( first == " "   )
		{
		trimmed = Get_subtext(trimmed,2,end);
		end = Numchr(trimmed);
		first = Get_subtext(trimmed,1,1);
		}

	Text last = Get_subtext(trimmed,end-1,end);
	while ( last == " "   )
		{
		trimmed = Get_subtext(trimmed,1,end-1);
		end = Numchr(trimmed);
		last = Get_subtext(trimmed,end-1,end);
		}

	return(trimmed);
	}




Integer check_locks_clean_model(Model &model,Message_Box &message)
	{
	//-----------------------------------------------------------
	// clean models if not locked
	// and report to message if fails
	// returns 1 if failed clean due to locked strings
	Integer  no_locks;
	get_model_locks(model,no_locks);

	Text model_name;
	if ( no_locks >= 1 )
		{
		Get_name(model, model_name);
		//Print("\Model: " + model_name + " is LOCKED! Please unlock all elements - click [ESC] key\n");
		Set_data(message, "Model: " + model_name + " is LOCKED! error");
		return(no_locks);
		}
	else
		{
		clean_model(model);
		}
	return(0);
	}
//.................
//.................


Integer get_drainage_vertex_index(Element drain,Integer pit_index,Integer &vertex)
	{
	//find matching vertex under pit
	Real px,py,pz;
	Get_drainage_pit(drain,pit_index,px,py,pz);

	Integer npts;
	Get_points(drain,npts);

	Integer start = pit_index;

	if ( pit_index > npts )
		{
		//something is not right
		//we have PITs without vertex
		//this might fail
		start = 1;
		}
	Integer mat=0;
	for(Integer i=start; i<=npts; i++)
		{
		Real x ,y ,z, r;
		Integer   f;
		Get_drainage_data( drain , i, x ,y ,z, r,  f );

		if ( xeqy(x,px,1.0e-2) == 1 )
			{
			if ( xeqy(y,py,1.0e-2) == 1 )
				{

				//yay we have a match...
				vertex = i;
				return(i);
				}
			}

		}
	vertex = 0;
	return(mat);
	}




// Match standard element header stuff, form "source" to "target"
Integer match_header(Element  source, Element &target) {
	Integer colour;
	Get_colour(source,colour);
	Text name;
	Get_name(source,name);
	Text style;
	Get_style(source,style);
	Real chainage;
	Get_chainage(source,chainage);
	Integer time_u;
	Get_time_updated(source,time_u);
	Real weight;
	Get_weight(source,weight);

	Integer ok=0;
	ok+=Set_colour(target,colour);
	ok+=Set_name(target,name);
	ok+=Set_style(target,style);
	ok+=Set_chainage(target,chainage);
	ok+=Set_time_updated(target,time_u);
	ok+=Set_weight(target,weight);


	return ok;
	}

Real get_chainage(Element &e, Real x, Real y) {
	Real ch,xf,yf,zf,dir,off;
	Drop_point(e,x,y,0.0,xf,yf,zf,ch,dir,off);
	return ch;
	}


// Create a drainage string using only the "pit points" from "e"
// the new string "out" has no pits withoug verticies, unless preserve_connection_points is true
Integer create_drainage(Element &e, Element &out, Integer preserve_underlying_geometry) {

	Integer npts;
	Get_points(e,npts);

	Integer npits;
	Get_drainage_pits(e,npits);
	if(npits<1)return 1;

	Get_points(e,npts);
	Real xv[npts],yv[npts],zv[npts],rv[npts];
	Integer fv[npts];
	Get_drainage_data(e,xv,yv,zv,rv,fv,npts,npts);
	Real chv[npts];
	for(Integer i=1; i<=npts; i++)   chv[i] = get_chainage(e,xv[i],yv[i]);

	// pit stuff
	Real x[npits],y[npits],z[npits],r[npits];
	Integer f[npits];
	Real angle[npits],diaLength[npits],diaWidth[npits],diameter[npits],lhs[npits],rhs[npits],hgl_lhs[npits],hgl_rhs[npits],hgl[npits],road_chainage[npits];
	Text type[npits],name[npits],road_name[npits];
	Integer float[npits];
	Attributes pit_atts[npits];

	//pipe stuff
	Real pipe_velocity[npits], pipe_flow[npits], pipe_diameter[npits], pipe_lhs[npits], pipe_rhs[npits], pipe_hgl_lhs[npits],pipe_hgl_rhs[npits];
	Text pipe_type[npits], pipe_name[npits];
	Attributes pipe_atts[npits];

	Integer maxn = npts + npits;
	Real xn[maxn],yn[maxn],zn[maxn],rn[maxn];
	Integer fn[maxn];
	Integer countn = 0;

	Integer last_v = 1;
	Integer before[npits];
	Integer new_pit_index[npits];
	Integer extra_pts = 0;

	for( i=1; i<=npits; i++) {
		// for pits;
		Get_drainage_pit(e,i,x[i],y[i],z[i]);
		r[i] = 0.0;
		f[i] = 0;
		diameter[i]=0;
		Get_drainage_pit_diameter     (e,i,diameter[i]);




		if ( Get_drainage_pit_width         ( e,i,diaWidth[i]) != 0 ) {
			Null(diaWidth[i]);
			}

		if ( Get_drainage_pit_length        ( e,i,diaLength[i]) != 0 ) {
			Null( diaLength[i]);
			}
		if ( Get_drainage_pit_symbol_angle  (e,i,angle[i]) != 0 ) {
			Null(angle[i]);
			}


		Get_drainage_pit_type         (e,i,type[i]);
		Get_drainage_pit_name         (e,i,name[i]);
		Get_drainage_pit_inverts      (e,i,lhs[i],rhs[i]);
		Get_drainage_pit_hgls         (e,i,hgl_lhs[i],hgl_rhs[i]);
		Get_drainage_pit_hgl          (e,i,hgl[i]);
		Get_drainage_pit_road_chainage(e,i,road_chainage[i]);
		Get_drainage_pit_road_name    (e,i,road_name[i]);
		Get_drainage_pit_float        (e,i,float[i]);
		float[i] = 0;
		Get_drainage_pit_attributes  (e,i,pit_atts[i]);
		// for pipes
		Get_drainage_pipe_velocity    (e,i,pipe_velocity[i]);
		Get_drainage_pipe_flow        (e,i,pipe_flow[i]);
		Get_drainage_pipe_diameter    (e,i,pipe_diameter[i]);
		Get_drainage_pipe_type        (e,i,pipe_type[i]);
		Get_drainage_pipe_name        (e,i,pipe_name[i]);
		Get_drainage_pipe_inverts     (e,i,pipe_lhs[i],pipe_rhs[i]);
		Get_drainage_pipe_hgls        (e,i,pipe_hgl_lhs[i],pipe_hgl_rhs[i]);
		Get_drainage_pipe_attributes  (e,i,pipe_atts[i]);

		if(preserve_underlying_geometry) {
			Real ch = get_chainage(e,x[i],y[i]);
			before[i] = 0;
			for(Integer j=last_v; j<npts; j++) {
				if(ch > chv[j] && ch < chv[j+1]) {
					extra_pts++;
					new_pit_index[extra_pts] = i;   // pit i is a new pit
					before[i] = j+1;      // and it should be inserted before j+1
					}
				if(ch < chv[j]) {
					last_v = j-1;
					if(j<1)j=0;
					break;
					}
				}
			}
		}

	if(preserve_underlying_geometry) {
		Integer count = 0;
		Integer last_j = 1;
		for(i=1; i<=extra_pts; i++) {
			Integer which_pit = new_pit_index[i];
			for(Integer j=last_j; j<=npts; j++) {
				if(j<before[which_pit]) {
					countn++;
					xn[countn] = xv[j];
					yn[countn] = yv[j];
					zn[countn] = zv[j];
					rn[countn] = rv[j];
					fn[countn] = fv[j];
					}
				else {
					countn++;
					xn[countn] = x[which_pit];
					yn[countn] = y[which_pit];
					zn[countn] = z[which_pit];
					rn[countn] = rv[j];
					fn[countn] = fv[j];
					last_j = j;
					break;
					}
				}
			}
		for(Integer j=last_j; j<=npts; j++) {
			countn++;
			xn[countn] = xv[j];
			yn[countn] = yv[j];
			zn[countn] = zv[j];
			rn[countn] = rv[j];
			fn[countn] = fv[j];
			}
		npts = npts+extra_pts;
		out = Create_drainage(xn, yn, zn, rn, fn, npts,npits);
		}
	else {
		npts = npits;
		out = Create_drainage(x, y, z, r, f, npts,npits);
		}

	for( i=1; i<=npits; i++) {
		// for pits
		Set_drainage_pit(out,i,x[i],y[i],z[i]);
		//Set_drainage_pit_diameter     (out,i,diameter[i]);
		Set_drainage_pit_type         (out,i,type[i]);
		Set_drainage_pit_name         (out,i,name[i]);
		Set_drainage_pit_inverts      (out,i,lhs[i],rhs[i]);
		Set_drainage_pit_hgls         (out,i,hgl_lhs[i],hgl_rhs[i]);
		Set_drainage_pit_hgl          (out,i,hgl[i]);
		Set_drainage_pit_road_chainage(out,i,road_chainage[i]);
		Set_drainage_pit_road_name    (out,i,road_name[i]);
		Set_drainage_pit_float        (out,i,float[i]);
		Set_drainage_pit_attributes   (out,i,pit_atts[i]);

		if ( diaWidth[i]	>= 0.00001 ) {
			Set_drainage_pit_length( out,i,diaLength[i]);
			Set_drainage_pit_width( out,i,diaWidth[i]);
			}
		else {
			Set_drainage_pit_diameter     (out,i,diameter[i]);
			}

		Set_drainage_pit_symbol_angle(out,i,angle[i]);


		// for pipes
		Set_drainage_pipe_velocity    (out,i,pipe_velocity[i]);
		Set_drainage_pipe_flow        (out,i,pipe_flow[i]);
		Set_drainage_pipe_diameter    (out,i,pipe_diameter[i]);
		Set_drainage_pipe_type        (out,i,pipe_type[i]);
		Set_drainage_pipe_name        (out,i,pipe_name[i]);
		Set_drainage_pipe_inverts     (out,i,pipe_lhs[i],pipe_rhs[i]);
		Set_drainage_pipe_hgls        (out,i,pipe_hgl_lhs[i],pipe_hgl_rhs[i]);
		Set_drainage_pipe_attributes  (out,i,pipe_atts[i]);
		}

	Attributes atts;
	Get_attributes(e,atts);
	Set_attributes(out,atts);
	Real ht;
	Get_drainage_outfall_height   (e, ht);
	Set_drainage_outfall_height   (out, ht);
	Integer dir;
	Get_drainage_flow             (e, dir);
	Set_drainage_flow             (out, dir);
	Tin ns_tin;
	Get_drainage_ns_tin           (e, ns_tin);
	Set_drainage_ns_tin           (out, ns_tin);
	Tin fs_tin;
	Get_drainage_fs_tin           (e, fs_tin);
	Set_drainage_fs_tin           (out, fs_tin);
	Integer string_float;
	Get_drainage_float            (e, string_float);
	Set_drainage_float            (out, string_float);

	return Calc_extent(out);
	}


Integer drainage_to_pits_with_vertex(Element &e) {
	Element new;
	Integer preserve_underlying_geometry = 1;
	if(create_drainage(e,new,preserve_underlying_geometry)) {
		Print("ERROR: create_drainage() - failed!\n");
		Element_delete(new);
		return 1;
		}
	Integer ok=0;
	ok+=match_header(e,new);
	ok+=String_replace(new,e);
	ok+=Element_delete(new);
	return ok;
	}



//---- match text would be better here
Integer pre_wild_post_case(Text  intext,Text  inwild,Text &pre, Text &post) {
//ignores CASE
	// prepost = zero is no wildcard exists returns blanks
	// prepost = 1 if wildcard does exist and returns text
	// prepost = 2 if option fails

	Text text =  intext;
	Text wild =  inwild;

	Integer end = Text_length(text);
	Integer lw = Text_length(wild);

	Integer start = Find_text( Text_lower(text),Text_lower(wild));
	if ( start <= 0 ) {
		pre = text;
		post = "";
		return(0);
		}
	else {
		pre = Get_subtext(text,1, start - 1);
		post = Get_subtext(text,start + lw,end);
		return(1);
		}
	return(2);
	}



Integer validate_pipe_Sizes(Text ppitSize,Real &SizeDia,Real &SizeWidth )
	{


	Text pitsiz="",pitwid="";
	pre_wild_post_case( ppitSize ,"x",pitsiz,pitwid);

	Real sizPit=0,widthPit=0;
	From_text(pitsiz,sizPit);
	From_text(pitwid,widthPit);
	if ( sizPit < -0.0001 ) {
		SizeDia = 0;
		}
	else {
//mm to m
		SizeDia =  0.001 * sizPit;
		}
	if ( widthPit <= 0.01 ) {
		SizeWidth = 0;
		}
	else {
		SizeWidth = 0.001 * widthPit;
		}


	return(0);
	}



//--- define panels and process
void manage_a_panel()
// ----------------------------------------------------------
// ----------------------------------------------------------
	{
	//--- create the panel

//should be 10
	Integer ver_p = Get_program_version_number();
//should be 1
	Integer ver_m = Get_program_major_version_number();
//should be
	Integer ver_n = Get_program_minor_version_number();

	Integer eekeks =0;
	if ( ver_p < 10 ) {
		eekeks +=1;
		}
	if ( ver_m < 1 ) {
		eekeks +=1;
		}
	if ( ver_n < 11 ) {
		eekeks +=1;
		}
	if ( eekeks > 0 ) {
		Print("Error, 12d model version older than C1k.");
		return;
		}

	// create the panel
	Panel          panel   = Create_panel("Survey Points to Drainage Pits");
	Vertical_Group vgroup  = Create_vertical_group(0);
	Message_Box    message = Create_message_box("  ");

	// if you want to have 3 tabs you need 3 Vgroups
	Vertical_Group g1 = Create_vertical_group(-1);
	Set_border(g1,"");
	Vertical_Group g2 = Create_vertical_group(-1);
	Set_border(g2,"");
	Vertical_Group g3 = Create_vertical_group(-1);
	Set_border(g3,"");
	Vertical_Group g4 = Create_vertical_group(-1);
	Set_border(g4,"");


	// this is what creates the tab box
	Tab_Box tab_pages = Create_tab_box();

	// add these Vgroups to the pages widget
	Append(g1,"Data",tab_pages);
	Append(g2,"Schema",tab_pages);
	Append(g3,"Attributes",tab_pages);
	Append(g4,"Settings",tab_pages);

	// set tab 1 active at start of the macro
	Integer page = 1 , no_pages = 4;
	Set_page(tab_pages,page);
	Append(tab_pages ,vgroup);
	//------------------------------------------------------

	Source_Box  source_box = Create_source_box("from survey",message,0);
	Append(source_box ,g1);

	Model_Box mod_bx = Create_model_box("Drainage Model to change",message,CHECK_MODEL_EXISTS			);
	Append(mod_bx,g1);

	Named_Tick_Box rep_bx = Create_named_tick_box("Replace Data",0,"replace");
	Append(rep_bx,g1);

	Model_Box mod_bx1 = Create_model_box("copy to Model",message,CHECK_MODEL_CREATE);
	Append(mod_bx1,g1);

	Named_Tick_Box clean_bx = Create_named_tick_box("Clean model B4hand",0,"clean");
	Append(clean_bx,g1);

	File_Box rep_box = Create_file_box(  "QA Report",  message,GET_FILE_CREATE,"*.csv" );
	Append(rep_box,g1);

	Named_Tick_Box showin_bx = Create_named_tick_box("show more QA data in report",0,"show");
	Append(showin_bx,g1);

	Named_Tick_Box showatt_bx = Create_named_tick_box("show all survey field data in QA report",0,"show");
	Append(showatt_bx,g1);

	//-------------------------------------------------

	Input_Box  code0_box = Create_input_box("pitName = Vertex Att", message);
	Set_data(code0_box, "PIT NAME" ) ;
	Append(code0_box,g2);

	Screen_Text  str_names_box = Create_screen_text("--------- String Names --------");
	Append(str_names_box,g2);

	Input_Box  code1_box = Create_input_box("Pit Centre Code", message);
	Set_data(code1_box, "PITC") ;
	Append(code1_box,g2);

	Named_Tick_Box useRL_bx = Create_named_tick_box("Use point [RL Code] for PIT grate Z value",1,"use Z");
	Append(useRL_bx,g2);

	Input_Box  code4_box = Create_input_box("RL Code", message);
	Set_data(code4_box, "PITL") ;
	Append(code4_box,g2);

	Input_Box  sump_rl_box = Create_input_box("Sump RL",message);
	Set_data(sump_rl_box,"SUMPRL");
	Append(sump_rl_box,g2);

	Input_Box  code2_box = Create_input_box("Other Point Code", message);
	Set_data(code2_box, "ignore") ;
	Append(code2_box,g2);

	//pipe RL attribute requires connected to MH asset id
	Input_Box  code3_box = Create_input_box("Pipe INV RL Code(main)", message);
	Set_data(code3_box, "PIPEL") ;
	Append(code3_box,g2);

	//pipe RL attribute requires connected to MH asset id
	Input_Box  code99_box = Create_input_box("Pipe INV RL Code(submain)", message);
	Set_data(code99_box, "SUBL") ;
	Append(code99_box,g2);

	Screen_Text  str2_names_box = Create_screen_text("--------- Pit Vertex Attributes ---------");
	Append(str2_names_box,g2);


	Input_Box  accur_box = Create_input_box("Vt Accuracy", message);
	Set_data(accur_box, "Vt Accuracy") ;

	//25 mm
	//10 mm
	// 5 mm

	Append(accur_box,g2);


	Input_Box  code1a_box = Create_input_box("Pit Dia/Length (mm)", message);
	Set_data(code1a_box, "PIT SIZE") ;
	Append(code1a_box,g2);

	Input_Box  code00a_box = Create_input_box("Pit Width (mm)", message);
	Set_data(code00a_box, "PIT WIDTH") ;
	Append(code00a_box,g2);


	Input_Box  code1b_box = Create_input_box("Pit type", message);
	Set_data(code1b_box,"PIT TYPE" ) ;
	Append(code1b_box,g2);

	Input_Box  codeAngle_box = Create_input_box("Pit Rotation Azimuth D.dd", message);
	Set_data(codeAngle_box,"PIT ANGLE" ) ;
	Append(codeAngle_box,g2);


	Named_Tick_Box correctNorth_bx = Create_named_tick_box("Correct for Magnetic North approx 23deg",1,"deg Z");
	Append(correctNorth_bx,g2);



	Input_Box  code1c_box = Create_input_box("Sump Offset -ve(mm)", message);
	Set_data(code1c_box,"SUMP OFFSET" ) ;
	Append(code1c_box,g2);



	Screen_Text  str3_names_box = Create_screen_text("--------- Pipe Vertex Attributes ---------");
	Append(str3_names_box,g2);



	Input_Box  code3a_box  = Create_input_box("to Pit Name", message);
	Set_data(code3a_box , "TO PIT NAME") ;
	Append(code3a_box ,g2);

	Input_Box  code3b_box  = Create_input_box("Pipe Size(mm)", message);
	Set_data(code3b_box , "PIPE SIZE" ) ;
	Append(code3b_box ,g2);

	Input_Box  code3c_box  = Create_input_box("Pipe Type", message);
	Set_data(code3c_box , "PIPE TYPE" ) ;
	Append(code3c_box ,g2);


	Input_Box  code3f_box  = Create_input_box("invert-obvert-centre", message);
	Set_data(code3f_box , "OBS TO" );
	Append(code3f_box ,g2);

	Input_Box  code3e_box  = Create_input_box("Invert offset(mm)", message);
	Set_data(code3e_box , "OBS OFFSET" ) ;
	Append(code3e_box ,g2);



	//--------------------------------------------------

	Input_Box  code1f_box = Create_input_box("output PIT type prefix", message);
	Set_data(code1f_box,"" ) ;
	Append(code1f_box,g4);

	Input_Box  code3d_box  = Create_input_box("output PIPE type prefix", message);
	Set_data(code3d_box , "" ) ;
	Append(code3d_box ,g4);

	Named_Tick_Box flotZ_bx = Create_named_tick_box("set LID 2 tin (float Z)",0,"flz");
	//Append(flotZ_bx,g4);

	Named_Tick_Box fixa_box = Create_named_tick_box("Fix errors 999-999",1,"fix");
	//Append(fixa_box,g4);


	Named_Tick_Box code0a_box = Create_named_tick_box("Lock Survey Values",1,"lock");
	//Append(code0a_box,g4);

	Named_Tick_Box code0b_box = Create_named_tick_box("Set HGL to Obvert",1,"lock");
	//Append(code0b_box,g4);


	Integer no_chs = 2;
	Text    chs[no_chs];

	chs[1] = "meters";
	chs[2] = "millimetres";

	Choice_Box mm_box = Create_choice_box("Report in Units",message);
	Set_data(mm_box,no_chs,chs);
	Set_data(mm_box,chs[2]);

	Append(mm_box,g4);





	//--------------------------------------------------



	Input_Box  att1_box  = Create_input_box("Survey Company Name", message);
	Set_data(att1_box , "" ) ;
	Append(att1_box ,g3);

	Input_Box att1_s_box = Create_input_box("Surveyors Reference",  message);
	Append(att1_s_box,g3);


	Input_Box job_no_b =   Create_input_box("Client SWP number",  message);
	Append(job_no_b,g3);

	Input_Box job_name_b = Create_input_box("Job Name/Location",  message);
	Append(job_name_b,g3);



	Integer no_acc = 3;
	Text    accurs[no_acc];

	accurs[1] = "GPS 25mm";
	accurs[2] = "Level/TS 10mm";
	accurs[3] = "Precise 5mm";

	Choice_Box accurs_box = Create_choice_box("Survey Accuracy",message);
	Set_data(accurs_box,no_acc,accurs);
	Set_data(accurs_box,accurs[1]);

	Append(accurs_box,g3);


	Integer no_choices = 3;
	Text    choices[no_choices];

	choices[1] = "Preliminary - Not Approved";
	choices[2] = "QA Checks";
	choices[3] = "Approved for Release";

	Choice_Box pages_box = Create_choice_box("Survey Data Approval",message);
	Set_data(pages_box,no_choices,choices);
	Set_data(pages_box,choices[1]);

	Append(pages_box,g3);

	Date_Time_Box  surv_date_b =   Create_date_time_box   ("Date of Survey",message);
	Set_width_in_chars(  surv_date_b,  10) ;
	Set_format             (  surv_date_b, 0 );
	Set_gmt                (  surv_date_b, 12);
	Append(surv_date_b,g3);


	Input_Box surveyor_name_b = Create_input_box("Surveyor's Name",  message);
	Append(surveyor_name_b,g3);

	Input_Box eqp_name_b = Create_input_box("Equipment Used",  message);
	Append(eqp_name_b,g3);

	Input_Box origin_name_b = Create_input_box("Origin Mark Name",  message);
	Append(origin_name_b,g3);

	Real_Box origin_level_b =  Create_real_box("Origin Mark RL", message);
	Append(origin_level_b,g3);

	Input_Box origin_datum_b = Create_input_box("Level Datum Name",  message);
	Append(origin_datum_b,g3);



	//--------------------------------------------------
	Horizontal_Group bgroup = Create_button_group();


	Button process = Create_button("SET","left");

	Button finish  = Create_button("&Finish" ,"finish");

	Append(process,bgroup );
	Append(finish ,bgroup);

	// append groups to panel
	Append(message,vgroup);
	Append(bgroup ,vgroup);
	Append(vgroup ,panel);

	Show_widget(panel);

	Integer  da,  mo,   yr;
	Date            (da,  mo,   yr) ;

	Set_data               (surv_date_b,To_text(da) + "-" + To_text(mo) +  "-" + To_text(yr) + " 12:00:00");


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
					if(cmd == "Panel Quit") {
						doit = 0;
						}
					if(cmd == "Panel About")
						{
						company_about_panel(panel);
						}
					}
				break;

			case Get_id(finish) :
					{
					if(cmd == "finish") {
						doit = 0;
						}
					}
				break;
			case Get_id(rep_bx) :
					{
					if(cmd == "toggle tick")
						{
						Integer  result;
						Validate(rep_bx,result);
						if ( result == 0 )
							{
							Set_enable(  mod_bx1,1);
							Set_enable(  clean_bx,1);
							}
						else
							{
							Set_enable(  mod_bx1,0);
							Set_enable(  clean_bx,0);
							}
						}
					}
				break;




			case Get_id(process) :
					{
//get all custom attributes and add them to a list

					Attributes compAtts;
					Attribute_delete_all    (  compAtts) ;

					Text page3_text="Not Approved";
					Integer pierr = Validate(pages_box,page3_text);
					if(pierr != TRUE)
						{
						Set_data(message,"bad Approval state");
						break;
						}



					Text surv_refer="";
					Validate(att1_s_box,surv_refer);

					Text global_acc_text="GPS 25mm";
					Integer aierr = Validate(accurs_box,global_acc_text);
					if(aierr != TRUE)
						{
						Set_data(message,"Accuracy choice invalid");
						break;
						}

					Text glob_acc="";
					//accurs[1] = "GPS 25mm";
					//accurs[2] = "Level/TS 10mm";
					//accurs[3] = "Precise 5mm";
					if ( global_acc_text == accurs[1] )
						{
						glob_acc = "25 mm";
						}
					else if ( global_acc_text == accurs[2] )
						{
						glob_acc = "10 mm";
						}
					else if ( global_acc_text == accurs[3] )
						{
						glob_acc = "5 mm";
						}
					else
						{
						glob_acc = "eek";
						}

					Text t_id;
					Validate(job_no_b,t_id);

					Text surv_com="";
					Validate(att1_box,surv_com);


					Text s_name="";
					Validate(job_name_b,s_name);

					Text s_date="";
					Validate(surv_date_b,s_date);

					Text fs_name="";
					Validate(surveyor_name_b,fs_name);

					Text eq_name="";
					Validate(eqp_name_b,eq_name);

					Text d_name="";
					Validate(origin_datum_b,d_name);

					Real mark_rl=-999999;
					Validate(origin_level_b,mark_rl);

					Text mark_name="";
					Validate(origin_name_b,mark_name);

					Set_attribute(compAtts ,"SWP", t_id );

					Set_attribute(compAtts ,"Job Name",s_name );
					Set_attribute(compAtts ,"Survey Firm Name",surv_com);
					Set_attribute(compAtts ,"Surveyors Reference",surv_refer);
					Set_attribute(compAtts ,"Data State",page3_text );
					Set_attribute(compAtts ,"Date of Survey",s_date );
					Set_attribute(compAtts ,"Field Surveyors Name",fs_name );
					Set_attribute(compAtts ,"Equipment Used",eq_name );
					Set_attribute(compAtts ,"Origin Mark Name", mark_name );
					Set_attribute(compAtts ,"Origin Mark RL", mark_rl );
					Set_attribute(compAtts ,"Level Datum Name", d_name );


					Text units="";
					Integer useUNIT = 1;
					Get_data(mm_box,units);
					if ( units == chs[1] )
						{
						//meters
						useUNIT = 1;
						}
					else
						{
						//millimeters
						useUNIT = 2;
						}




					Text delim = ",";

					// add tick box here
					//top of MH snaps to tin or not

					//float Z setting to snap to tin
					//must also set attributes or clean attributes about this
					Integer fl_top = 0;
					Validate(flotZ_bx,fl_top);

					// add attributes for survey company etc.

					Integer  replace_data,clean_mod,show_inputs,show_atts;
					Validate(rep_bx,replace_data);
					Validate(clean_bx,clean_mod);
					Validate(showin_bx,show_inputs);
					Validate(showatt_bx,show_atts);



					Model   model;
					Integer ierr = Validate(mod_bx,GET_MODEL, model);
					if(ierr != MODEL_EXISTS)
						{
						Set_data(message, "No Drainage model selected") ;
						break;
						}

					Attributes modatt;
					Attribute_delete_all    (  modatt) ;
					Get_model_attributes          (  model,  modatt);

					Set_attribute           (modatt,"confirm set pit details" ,0) ;
					Set_attribute           (modatt,"confirm regrade pipes"   ,0) ;
					//Set_attribute           (modatt,"use pit connect pts"   ,1) ;

					//take a copy of the elements just in case we need to add them to another model
					Dynamic_Element org_elts;
					Null(org_elts);
					Integer  total_no_dne;
					Get_elements(  model,org_elts,  total_no_dne);

					//lets get all the elements from the model
					Dynamic_Element  de;
					Null(de);

					Model   copy_model;
					if ( replace_data == 0 )
						{
						//copy to model
						ierr = Validate(mod_bx1,GET_MODEL_CREATE ,copy_model);
						if(ierr != MODEL_EXISTS)
							{
							Set_data(message, "No Copy to model selected") ;
							Null(org_elts);
							Null(de);
							break;
							}
						Text  model_name;
						Get_name(  copy_model, model_name);
						//first clean the model and copy the data to it...
						if ( clean_mod == 1 )
							{
							//clean model
							if ( check_locks_clean_model(  copy_model,  message) != 0 )
								{
								Set_data(message, "EEK model for results is locked") ;
								Null(org_elts);
								Null(de);
								break;
								}
							}
						Null(model);
						model = copy_model;
						//we need to keep whats in the model so lets just add data to the model
						//so take a copy of the elements and add them to the model
						dynamic_elements_duplicate(  org_elts ,de);
						Set_model(de,model );


						//and set the attributes to it
						Set_model_attributes          (  model,  modatt);
						Calc_extent(model);
						}
					else
						{

						Get_elements(  model, de,  total_no_dne);
						}
					Null(org_elts);



					//lets ensure that each pit has a vertex and all vertices are preserved
					for (Integer VT=1; VT<=total_no_dne; VT++)
						{
						Element str;
						Get_item(de,VT,str);
						drainage_to_pits_with_vertex(  str);
						}



					//QA report
					File      file;
					Text      reportfile;

					ierr = Validate(rep_box,GET_FILE_CREATE,reportfile);
					if(ierr != NO_FILE) break;


					Text mch_code = " ";
					Get_data(code0_box,  mch_code) ;


					Integer corrMags=0;
					Validate(correctNorth_bx,corrMags);



					Text  pit_code=" ";
					Get_data(code1_box,  pit_code) ;

					Text pit_prefix = " ";
					Get_data(code1f_box,  pit_prefix) ;


					Text  lid_code=" ";
					Get_data(code2_box,  lid_code) ;


					Text  pipe_code=" ";
					Get_data(code3_box,  pipe_code) ;

					Text  submain_code=" ";
					Get_data(code99_box,  submain_code) ;

					Text 	mh_size_att_name = " ";
					Get_data(code1a_box,  mh_size_att_name) ;

					Text 	mh_width_att_name = " ";
					Get_data(code00a_box,  mh_width_att_name) ;


					Text 	accur_attrib_name = "Vt Accuracy";
					Get_data(accur_box,  accur_attrib_name) ;



					Text mh_angle_name = " ";
					Get_data(codeAngle_box,  mh_angle_name) ;



					Integer  nec_used = 0;
					Validate(useRL_bx,nec_used);
					Text  nec_code=" ";
					Get_data(code4_box,  nec_code) ;


					Text  sumRL_code="?";
					Get_data(sump_rl_box,  sumRL_code) ;




					Text mh_type_att_name = " ";
					Get_data(code1b_box,  mh_type_att_name) ;

					Text mh_sump_att_name = " ";
					Get_data(code1c_box,  mh_sump_att_name) ;

					Text pipe_to_mh_name = " ";
					Get_data(code3a_box,  pipe_to_mh_name) ;

					Text pipe_size_att = "";
					Get_data(code3b_box,  pipe_size_att) ;

					Text pipe_type_att = "";
					Get_data(code3c_box,  pipe_type_att) ;

					Text pipe_type_prefix = "";
					Get_data(code3d_box,  pipe_type_prefix) ;

					Text  pipe_justify="";
					Get_data(code3f_box,  pipe_justify) ;

					Text  pipe_inv_offset="";
					Get_data(code3e_box,  pipe_inv_offset);


					Integer lockit = 0;
					Validate(code0a_box,   lockit);

					Integer hgl_to_obv = 0;
					Validate(code0b_box,   hgl_to_obv);


					Integer fix_code = 0;
					Validate(fixa_box,   fix_code);

					// get survey elements
					Dynamic_Element			orelts;
					Null(orelts);
					ierr = Validate(source_box,orelts);
					if(ierr != TRUE)
						{
						Set_data(message,"Invalid Source points");
						break;
						}

					//text for reports
					Dynamic_Text dt_pt_id, dt_pt_name, dt_pt_att,dt_matched,dt_pipe_set,dt_dist_to_pit,dt_pipe_inv_comp;
					Null(dt_pt_id);
					Null( dt_pt_name);
					Null( dt_pt_att);
					Null( dt_matched);
					Null( dt_pipe_set);
					Null( dt_dist_to_pit);
					Null( dt_pipe_inv_comp);

					Dynamic_Text nec_names;
					Dynamic_Real nec_zds;
					Null( nec_names );
					Null( nec_zds );


					Dynamic_Text SumRL_names;
					Dynamic_Real SumRL_zds;
					Null( SumRL_names );
					Null( SumRL_zds );


					//number of survey strings
					Integer  nume=0;
					Get_number_of_items(orelts,nume);


					//loop all survey strings and
					//get the NEC codes if applicable
					if ( nec_used == 1 || sumRL_code != "?" )
						{
						for (Integer rr=1; rr<=nume; rr++)
							{
							//get survey string
							Element item;
							Get_item(orelts,rr,item);


							//get string type
							Text sup_type="";
							Get_type(item,sup_type);
							//if it is super string carry on
							if(sup_type != "Super") continue;

							//get string name
							Text  elt_name="";
							Get_name(  item, elt_name);
							//get all points on a string
							Integer ver_ct=0;
							Get_points(item,ver_ct);

							if ( lower_trim(elt_name) == lower_trim(nec_code) )
								{
								//if MHNEC is the code or string name - eg centre of manhole

								//loop each vertex and match each to a pit
								for (Integer PT=1; PT<=ver_ct; PT++)
									{

									//get the attribute that should match pit name
									Text pitName="";
									get_super_vertex_attribute_text           (item ,PT,mch_code,pitName);

									Real  x, y, z;
									Get_super_vertex_coord ( item ,PT,x, y, z);

									//use the z value for the PIT Grade value
									//ok so this point is manhole centre point

									//lets append the z value and the pit name to a list to be used later
									Append( pitName,nec_names);
									Append( z,nec_zds);

									}
								}
							if ( lower_trim(elt_name) == lower_trim(sumRL_code) )
								{
								//if MHNEC is the code or string name - eg centre of manhole

								//loop each vertex and match each to a pit
								for (Integer PT=1; PT<=ver_ct; PT++)
									{

									//get the attribute that should match pit name
									Text pitName="";
									get_super_vertex_attribute_text           (item ,PT,mch_code,pitName);

									Real  x, y, z;
									Get_super_vertex_coord ( item ,PT,x, y, z);

									Append( pitName,SumRL_names);
									Append( z,SumRL_zds);

									}
								}









							}

						}




					Dynamic_Text pit_uniq_names;
					Null(pit_uniq_names);
					Dynamic_Integer pit_uniq_index;
					Null(pit_uniq_index);
					Dynamic_Text lid_uniq_names;
					Null(lid_uniq_names);
					Dynamic_Integer lid_uniq_index;
					Null(lid_uniq_index);



					//loop all survey strings and match them to drainage strings
					for (Integer i=1; i<=nume; i++)
						{
						//get survey string
						Element item;
						Get_item(orelts,i,item);

						//get string type
						Text sup_type="";
						Get_type(item,sup_type);
						//if it is super string carry on
						if(sup_type != "Super") continue;



						//get string name
						Text  elt_name="";
						Get_name(  item, elt_name);
						//get all points on a string
						Integer ver_ct=0;
						Get_points(item,ver_ct);




						//loop each vertex and match each to a pit
						for (Integer PT=1; PT<=ver_ct; PT++)
							{

							//get the attribute that should match pit name
							Text pitName="";
							get_super_vertex_attribute_text           (item ,PT,mch_code,pitName);

							//vertex ID is needed for QA report
							Text  pt_n="";
							Get_super_vertex_point_number        (item ,PT,pt_n) ;

							//add info to the QA report text arrays
							Append(pt_n, dt_pt_id );
							Append(elt_name, dt_pt_name );
							Append(pitName, dt_pt_att );


							//define values
							Real  x, y, z,pipeINV,pitSump=0;
							Real pitSIZEm =0,pitSIZEwM =0,pipeDIAm=0,pipeDIAmwidth=0,pitAngle=-99999;
							Text pitType="",pitACCUR="",pitRot="";
							Attributes mh_atts,lid_atts,pipe_atts;

							Attribute_delete_all    (  mh_atts) ;
							Attribute_delete_all    (  lid_atts) ;
							Attribute_delete_all    (  pipe_atts) ;

							Text pipe_type="";
							Text othr_pipe="";
							Text point_number="";

							//string name is the field feature code and hence the mode here
							Integer codeMode=0,main_not_sub=1; //1 means MHC, 2 means LID, 3 means PIPE

							Get_super_vertex_coord ( item ,PT,x, y, z);
							Get_super_vertex_point_number        (item ,PT,point_number) ;


							//if MHC is the code or string name - eg centre of manhole
							if ( lower_trim(elt_name) == lower_trim(pit_code) )
								{
								//Manhole Centre code was found lets record some survey info
								Text size="";
								get_super_vertex_attribute_text (item ,PT,mh_size_att_name,size);
								Text sizeW="";
								get_super_vertex_attribute_text           (item ,PT,mh_width_att_name,sizeW);

								//lets convert the size to meters
								From_text(size,pitSIZEm);
								pitSIZEm = 0.001 * pitSIZEm;

								From_text(sizeW,pitSIZEwM);
								pitSIZEwM = 0.001 * pitSIZEwM;




								Text pit_Sump_tx="-99999";
								get_super_vertex_attribute_text           (item ,PT,mh_sump_att_name,pit_Sump_tx);
								From_text(pit_Sump_tx,pitSump);
								pitSump = -0.001 * Absolute(pitSump);
								//"sump level"

								//get the angle for this pit if supplied
								get_super_vertex_attribute_text           (item ,PT,mh_angle_name,pitRot);
								From_text(pitRot,pitAngle);
								if ( corrMags == 1 ) {
									pitAngle += 23.4;
									}


								//type of MH to be added to the pit
								get_super_vertex_attribute_text           (item ,PT,mh_type_att_name,pitType);
								pitType = pit_prefix + pitType;

								//get all survey attributes and store them to be added to the new string
								Get_super_vertex_attributes           (item ,PT,mh_atts);


								Text exist_val = "eek";
								get_super_vertex_attribute_text (  item,PT,accur_attrib_name,  exist_val);
								if ( exist_val != "eek" && exist_val != "" && exist_val != " "  )
									{
									pitACCUR =  exist_val;
									}
								else
									{
									pitACCUR =  glob_acc;
									}

								//ok so this point is manhole centre point
								codeMode =1;
								}//if mhc
							//else it must be a LID
							else if ( lower_trim(elt_name) == lower_trim(lid_code) )
								{
								//this is a LID string name

								//create subgroup of attributes with all lid points
								Attributes lidsa,grlid;
								Attribute_delete_all    (  lidsa) ;
								Attribute_delete_all    (  grlid) ;
								Set_attribute           (grlid,"Pt ID",point_number) ;
								Set_attribute           (grlid,"X",To_text ( x,3)) ;
								Set_attribute           (grlid,"Y",To_text ( y,3)) ;
								Set_attribute           (grlid,"Z",To_text ( z,3)) ;

								Get_super_vertex_attributes           (item ,PT,lidsa);
								Set_attribute           (grlid,"Time Stamp",lidsa) ;

								//Text lid_name_point = get_unique_name(lidQA,"Lid ");

								Integer in = get_unique_name(pitName,lid_uniq_names,lid_uniq_index);
								Text lid_name_point = "PT " + To_text(in);



								Set_attribute           (lid_atts,lid_name_point,grlid) ;
								//ok so this point is LID point
								codeMode= 2;

								}//if lid
							//slse it must be a pipe
							else if ( lower_trim(elt_name) == lower_trim(pipe_code)  )
								{


								//ok so this is a pipe
								//get the pit name this pipe is going to
								othr_pipe="";
								get_super_vertex_attribute_text           (item ,PT,pipe_to_mh_name,othr_pipe);

								//get size of the pipe in mm
								Text pipeSize="";
								get_super_vertex_attribute_text           (item ,PT,pipe_size_att,pipeSize);
								//convert it to meters
								//From_text(pipeSize,pipeDIAm);
								//pipeDIAm = 0.001 * Absolute(pipeDIAm);

								validate_pipe_Sizes(pipeSize,pipeDIAm,pipeDIAmwidth );

								pipeDIAm =   Absolute(pipeDIAm);
								pipeDIAmwidth =   Absolute(pipeDIAmwidth);


								//get the attributes on the point
								Attributes grlid;
								Attribute_delete_all    (  grlid) ;
								get_super_vertex_attribute_text           (item ,PT,pipe_type_att,pipe_type);
								pipe_type = pipe_type_prefix + pipe_type ;

								Get_super_vertex_attributes          (item ,PT,grlid);

								Text invOffset="";
								get_super_vertex_attribute_text           (item ,PT,pipe_inv_offset,invOffset);
								Real invalue=0;
								From_text(invOffset,invalue);
								//convert it to meters
								invalue = 0.001 * invalue;
								z += invalue;

								Text just_type="";
								get_super_vertex_attribute_text           (item ,PT,pipe_justify,just_type);
								if ( lower_trim(just_type) == "soffit" || lower_trim(just_type) == "obvert" || lower_trim(just_type) == "obv" )
									{
									z = z - pipeDIAm;
									}
								else if ( lower_trim(just_type) == "centre" || lower_trim(just_type) == "ctr" )
									{
									z = z - ( 0.5*pipeDIAm );
									}


								pipeINV = z;
								//we are using point RL as the invert
								Set_attribute           (grlid,"Pipe Invert",To_text ( z,3)) ;

								Set_attribute           (grlid,"Point ID",point_number) ;

								//Text pipe_name_point = get_unique_name(pipeQA,"Point ");

								Integer in = get_unique_name( pitName,pit_uniq_names,pit_uniq_index);
								Text pipe_name_point = "Point " + To_text(in);

								Set_attribute           (pipe_atts,pipe_name_point ,grlid) ;
								//this is a pipe point
								codeMode= 3;
								}//all other codes are ignored
							else if (   lower_trim(elt_name) == lower_trim(submain_code) )
								{

								//ok so this is a pipe
								//get the pit name this pipe is going to
								othr_pipe="";
								get_super_vertex_attribute_text           (item ,PT,pipe_to_mh_name,othr_pipe);

								//get size of the pipe in mm
								Text pipeSize="";
								get_super_vertex_attribute_text           (item ,PT,pipe_size_att,pipeSize);
								//convert it to meters
								//From_text(pipeSize,pipeDIAm);

								validate_pipe_Sizes(pipeSize,pipeDIAm,pipeDIAmwidth );

								pipeDIAm =   Absolute(pipeDIAm);
								pipeDIAmwidth =   Absolute(pipeDIAmwidth);


								//get the attributes on the point
								Attributes grlid;
								Attribute_delete_all    (  grlid) ;
								get_super_vertex_attribute_text           (item ,PT,pipe_type_att,pipe_type);
								pipe_type = pipe_type_prefix + pipe_type ;

								Get_super_vertex_attributes          (item ,PT,grlid);

								Text invOffset="";
								get_super_vertex_attribute_text           (item ,PT,pipe_inv_offset,invOffset);
								Real invalue=0;
								From_text(invOffset,invalue);
								//convert it to meters
								invalue = 0.001 * invalue;
								z += invalue;

								Text just_type="";
								get_super_vertex_attribute_text           (item ,PT,pipe_justify,just_type);
								if ( lower_trim(just_type) == "soffit" || lower_trim(just_type) == "obvert" || lower_trim(just_type) == "obv" )
									{
									z = z - pipeDIAm;
									}
								else if ( lower_trim(just_type) == "centre" || lower_trim(just_type) == "ctr" )
									{
									z = z - ( 0.5*pipeDIAm );
									}


								pipeINV = z;
								//we are using point RL as the invert
								Set_attribute           (grlid,"Pipe Invert",To_text ( z,3)) ;

								Set_attribute           (grlid,"Point ID",point_number) ;

								//Text pipe_name_point = get_unique_name(pipeQA,"Point ");

								Integer in = get_unique_name( pitName,pit_uniq_names,pit_uniq_index);
								Text pipe_name_point = "Point " + To_text(in);

								Set_attribute           (pipe_atts,pipe_name_point ,grlid) ;
								//this is a pipe point
								codeMode= 4;
								}//all other codes are ignored

							//the QA report will translate the field code to
							//text description
							if ( codeMode == -1 )
								{
								Append("Pit Z Value Code",dt_matched);
								}
							else if ( codeMode == 1 )
								{
								Append("Centre of Pit Code",dt_matched);
								}
							else if ( codeMode == 2 )
								{
								Append("Edge of Lid Code",dt_matched);
								}
							else if ( codeMode == 3 )
								{
								Append("Pipe Code",dt_matched);
								}
							else if ( codeMode == 4 )
								{
								Append("Submain Code",dt_matched);
								}
							else
								{
								//all other field codes are unknown
								Append("unknown",dt_matched);
								}

							//count how many pit have been matched
							Integer matched_pit=0;
							//QA report needs so info about the inverts of pipes matched
							Text INVsCOMP="";










							//lets start with pipes
							//if this point is a pipe point do this
							if ( codeMode == 3)
								{

								Text name_sub = "old inv:",surv_sub = "surveyed main inv:";

								//SET PIPE INVERTS
								//loop all drainage strings and locate surveyed pipe
								for (Integer d=1; d<=total_no_dne; d++)
									{
									Text just_type,invOffset;
									get_super_vertex_attribute_text           (item ,PT,pipe_justify,just_type);
									get_super_vertex_attribute_text           (item ,PT,pipe_inv_offset,invOffset);


									Element detm;
									Get_item(de,d,detm);

									//get string type
									Text dstr_type;
									Get_type(detm,dstr_type);
									//if it is drainage carry on
									if(dstr_type != "Drainage") continue;

									//get flow direction
									Integer dir;
									Get_drainage_flow(detm,dir);

									//get number of pits
									//string has one less pipes
									Integer npits;
									Get_drainage_pits(detm,npits);

									//loop through pits
									for(Integer K=1; K<npits; K++)
										{
										//skip last pit as it doesn't have a pipe
										//get pit name before and after
										Text DSname="";
										Get_drainage_pit_name         (  detm,K, DSname) ;
										Text USname="";
										Get_drainage_pit_name         (  detm,K+1, USname) ;
										//we use pit names to match a pipe
										//surveyor doesnt know what us or ds
										//but if they know the pipe connects between
										//two pits we have a unique match

										if ( lower_trim(DSname) == "" || lower_trim(DSname) == " " || lower_trim(USname) == "" || lower_trim(USname) == " ")
											{
											//this is not good we have blank names on pits
											continue;
											//skip this pit
											}

										Integer matchis=0;

										if ( lower_trim(pitName) == lower_trim(USname) && lower_trim(othr_pipe) == lower_trim(DSname)  )
											{

											matchis=1;
											//lets set the pipe inverts and HGL values
											Real ild,ilu;
											Real hglhs,hgrhs;

											Get_drainage_pipe_inverts(detm,K,ild ,ilu);
											Get_drainage_pipe_hgls (detm,K,hglhs,hgrhs);
											//do we need to fix up -999 null values or silly +9999 GIS values?


											if ( fix_code == 1 )
												{
												fix_9999_error(ild,pipeINV );
												fix_9999_error(ilu,pipeINV);
												fix_9999_error(hglhs,ild+  pipeDIAm );
												fix_9999_error(hgrhs,ilu+  pipeDIAm );
												}


// useUNIT = 2  mm
//mm_to_meters
//meters_to_mm

											//lets add some QA data to our report
											if (  useUNIT == 2 )
												{
												//in mm
												INVsCOMP +=  name_sub + delim + meters_to_mm(ilu,0) + delim + surv_sub + delim + meters_to_mm(pipeINV,0) + delim + "diff:" + delim + meters_to_mm(pipeINV - ilu,0);
												}
											else
												{
												//in m
												INVsCOMP +=  name_sub + delim + To_text(ilu,3) + delim + surv_sub + delim + To_text(pipeINV,3) + delim + "diff:" + delim + To_text(pipeINV - ilu,3);
												}

											INVsCOMP += delim + pipe_justify + delim + just_type + delim + pipe_inv_offset + delim + invOffset;





											Set_drainage_pipe_inverts(detm,K,ild ,pipeINV );
											//do we need to set the HGL to obvert?
											if ( hgl_to_obv == 1 )
												{
												Set_drainage_pipe_hgls (detm,K,ild +  pipeDIAm ,pipeINV +  pipeDIAm);
												}
											else
												{
												Set_drainage_pipe_hgls (detm,K,hglhs,hgrhs);
												}

											//we have matched a pipe here?
											++matched_pit;
											}
										//we could find a match if the US and DS swap
										else  if ( lower_trim(pitName) == lower_trim(DSname) && lower_trim(othr_pipe) == lower_trim(USname)  )
											{

											matchis=1;
											//lets set the pipe inverts and HGL values
											Real ild,ilu;
											Real hglhs,hgrhs;

											Get_drainage_pipe_inverts(detm,K,ilu ,ild );
											Get_drainage_pipe_hgls (detm,K,hglhs,hgrhs);
											//do we need to fix up -999 null values or silly +9999 GIS values?

											if ( fix_code == 1 )
												{
												fix_9999_error(ild,pipeINV );
												fix_9999_error(ilu,pipeINV);
												fix_9999_error(hglhs,ilu+  pipeDIAm );
												fix_9999_error(hgrhs,ild+  pipeDIAm );
												}

											//lets add some QA data to our report

// useUNIT = 2  mm
//mm_to_meters
//meters_to_mm


											//lets add some QA data to our report
											if (  useUNIT == 2 )
												{
												//in mm
												INVsCOMP +=  name_sub + delim + meters_to_mm(ilu,0) + delim + surv_sub + delim + meters_to_mm(pipeINV,0) + delim + "diff:" + delim + meters_to_mm(pipeINV - ilu,0);
												}
											else
												{
//in m
												INVsCOMP +=  name_sub + delim + To_text(ilu,3) + delim + surv_sub + delim + To_text(pipeINV,3) + delim + "diff:" + delim + To_text(pipeINV - ilu,3);
												}
											INVsCOMP += delim + pipe_justify + delim + just_type + delim + pipe_inv_offset + delim + invOffset;


											Set_drainage_pipe_inverts(detm,K,pipeINV ,ild );
											//Set_drainage_pipe_hgls (detm,K,hglhs,hgrhs);
											//do we need to set the HGL to obvert?

											if ( hgl_to_obv == 1 )
												{
												Set_drainage_pipe_hgls (detm,K, pipeINV +  pipeDIAm , ild +  pipeDIAm);
												}
											else
												{
												Set_drainage_pipe_hgls (detm,K,hglhs,hgrhs);
												}
											//we have matched a pipe here?


											++matched_pit;
											}



										if ( matchis == 1 )
											{
											//we should check if there is another dia or type from another point
											//get pipe attributes that match * name
											//split the name to get the point number
											//get the value to report on if different
											//put a not possible error inputs
											Attributes atts;
											Attribute_delete_all    (  atts) ;

											Get_drainage_pipe_attributes           (detm,K, atts);
											Text  DpointNo="";
											Real  Dvalue=-999;
											//Integer hdia = get_matching_att_pt_value (  atts, "Diameter at point " ,  DpointNo, Dvalue );
											//get_matching_att_pt_value       (        atts,   "has points" ,"Point " , "Point ID" ,"Diameter" ,   DpointNo,       Dvalue );

											Integer hdia = get_matching_att_pt_value (  atts, "has points" ,"Point ", "Pt ID" , "Diameter" ,  DpointNo, Dvalue );
											Text  TpointNo="", Tvalue="";
											//Integer htp = get_matching_att_pt_value (  atts, "Type at point " ,  TpointNo, Tvalue );
											Integer htp = get_matching_att_pt_value (  atts, "has points" ,"Point ", "Pt ID",  "Type" , TpointNo, Tvalue );

											if ( hdia == 1 )
												{
												if (  Dvalue != pipeDIAm )   //Dvalue > 0.001 && Is_null(Dvalue) == 0 &&
													{
													//add the dia and type of pipe to report //lets add some QA data to our report
													if (  useUNIT == 2 )
														{
														//in mm
														INVsCOMP +=  delim + "dia: " + delim + meters_to_mm(pipeDIAm,0)  + delim + "Dia at pt " + DpointNo+ " : " + delim + meters_to_mm(Dvalue,0) ;
														}
													else
														{
														//in m
														INVsCOMP +=  delim + "dia: " + delim + To_text(pipeDIAm,3)  + delim + "Dia at pt " + DpointNo+ " : " + delim + To_text(Dvalue,3) ;
														}


													}
												}
											if ( htp == 1 )
												{
												if (Tvalue != " " && Tvalue != "" && pipe_type != "" && pipe_type != " " )
													{
													if (  Tvalue != pipe_type  )
														{
														INVsCOMP +=   delim + "type: " + delim + pipe_type + delim + "Type at pt " + TpointNo + " : " + delim + Tvalue;
														}
													}
												}

											//this is a pipe that matches
											//set the new attribute values for QA



											Attributes   p_at_gr;
											Attribute_delete_all    (  p_at_gr) ;
											Set_attribute           (p_at_gr,"Pt ID",point_number) ;
											Set_attribute           (p_at_gr,"diameter",pipeDIAm) ;
											if ( pipeDIAmwidth > 0.01 ) Set_attribute           (p_at_gr,"width",pipeDIAmwidth) ;
											Set_attribute           (p_at_gr,"Type",pipe_type) ;


											Text pi_name_point = get_unique_pipe_name(detm,K,"Point ");

											Set_drainage_pipe_attribute           (detm,K,pi_name_point,p_at_gr) ;


											//  Set_drainage_pipe_attribute           (detm,K,"points/at point " + point_number + "/Diameter" , pipeDIAm );
											//  Set_drainage_pipe_attribute           (detm,K,"points/at point " + point_number +"/Type", pipe_type);

											Set_drainage_pipe_attribute           (detm,K,"has points", "1" );


											if ( pipeDIAm <= 0.001 )
												{
												if (  Dvalue >= 0.001  )
													{
													pipeDIAm =  Dvalue;
													}

												}

											//we need to set the pipe values
											Set_drainage_pipe_diameter    (detm,K,  pipeDIAm);
											if ( pipeDIAmwidth > 0.01 ) Set_drainage_pipe_width(detm,K,pipeDIAmwidth);
											if ( pipeDIAmwidth > 0.01 ) Set_drainage_pipe_top_width(detm,K,pipeDIAmwidth);

											Set_drainage_pipe_type        (detm,K,  pipe_type);

											//also set the pipe attributes that match
											Set_drainage_pipe_attribute           (detm,K,"diameter", pipeDIAm);
											Text ppssiz=meters_to_mm(pipeDIAm,0);
											if ( pipeDIAmwidth > 0.01 ) {
												Set_drainage_pipe_attribute           (detm,K,"width", pipeDIAmwidth);
												Set_drainage_pipe_attribute           (detm,K,"width top", pipeDIAmwidth);
												ppssiz =    meters_to_mm(pipeDIAmwidth,0) + "x"+ meters_to_mm(pipeDIAm,0);
												}

											Set_drainage_pipe_attribute           (detm,K,"pipe size", ppssiz );
											Set_drainage_pipe_attribute           (detm,K,"pipe type", pipe_type);


											//lock the pipe inverts if set
											Set_drainage_pipe_attribute           (detm,K,"lock ds il", lockit);
											Set_drainage_pipe_attribute           (detm,K,"lock us il", lockit);
											Set_drainage_pipe_attribute           (detm,K,"lock size", lockit);
											//delete invert attributes as these need to be set by DNE
											if ( Drainage_pipe_attribute_exists(  detm,  K,"invert us") != 0 )
												{
												Drainage_pipe_attribute_delete        ( detm,  K,"invert us");
												}
											if ( Drainage_pipe_attribute_exists(  detm,  K,"invert ds") != 0 )
												{
												Drainage_pipe_attribute_delete        ( detm,  K,"invert ds");
												}
											if ( Drainage_pipe_attribute_exists(  detm,  K,"minimum cover") != 0 )
												{
												Drainage_pipe_attribute_delete        ( detm,  K,"minimum cover");
												}

											}


										}//for K


									}//for d



								}//if pipe








							//lets start with pipes
							//if this point is a pipe point do this
							if ( codeMode == 4)
								{

								Text name_sub = "main inv:",surv_sub = "surveyed SUB inv:";




								//SET PIPE INVERTS
								//loop all drainage strings and locate surveyed pipe
								for (Integer d=1; d<=total_no_dne; d++)
									{
									Text just_type,invOffset;
									get_super_vertex_attribute_text           (item ,PT,pipe_justify,just_type);
									get_super_vertex_attribute_text           (item ,PT,pipe_inv_offset,invOffset);


									Element detm;
									Get_item(de,d,detm);

									//get string type
									Text dstr_type;
									Get_type(detm,dstr_type);
									//if it is drainage carry on
									if(dstr_type != "Drainage") continue;

									//get flow direction
									Integer dir;
									Get_drainage_flow(detm,dir);

									//get number of pits
									//string has one less pipes
									Integer npits;
									Get_drainage_pits(detm,npits);

									//loop through pits
									for(Integer K=1; K<npits; K++)
										{
										//skip last pit as it doesn't have a pipe
										//get pit name before and after
										Text DSname="";
										Get_drainage_pit_name         (  detm,K, DSname) ;
										Text USname="";
										Get_drainage_pit_name         (  detm,K+1, USname) ;
										//we use pit names to match a pipe
										//surveyor doesnt know what us or ds
										//but if they know the pipe connects between
										//two pits we have a unique match

										if ( lower_trim(DSname) == "" || lower_trim(DSname) == " " || lower_trim(USname) == "" || lower_trim(USname) == " ")
											{
											//this is not good we have blank names on pits
											continue;
											//skip this pit
											}

										Integer matchis=0;

										if ( lower_trim(pitName) == lower_trim(USname) && lower_trim(othr_pipe) == lower_trim(DSname)  )
											{

											matchis=1;
											//lets set the pipe inverts and HGL values
											Real ild,ilu;
											Real hglhs,hgrhs;

											Get_drainage_pipe_inverts(detm,K,ild ,ilu);
											Get_drainage_pipe_hgls (detm,K,hglhs,hgrhs);
											//do we need to fix up -999 null values or silly +9999 GIS values?



											//lets add some QA data to our report
											if (  useUNIT == 2 )
												{
												//in mm
												INVsCOMP +=  name_sub + delim + meters_to_mm(ilu,0) + delim + surv_sub + delim + meters_to_mm(pipeINV,0) + delim + "diff:" + delim + meters_to_mm(pipeINV - ilu,0);
												}
											else
												{
												//in m
												INVsCOMP +=  name_sub + delim + To_text(ilu,3) + delim + surv_sub + delim + To_text(pipeINV,3) + delim + "diff:" + delim + To_text(pipeINV - ilu,3);
												}

											INVsCOMP += delim + pipe_justify + delim + just_type + delim + pipe_inv_offset + delim + invOffset;


											Set_drainage_pipe_attribute           (detm,K,"SUBpipeUse", "YES");
											Set_drainage_pipe_attribute           (detm,K,"SUBpipe invert us", pipeINV );


											//we have matched a pipe here?
											++matched_pit;
											}
										//we could find a match if the US and DS swap
										else  if ( lower_trim(pitName) == lower_trim(DSname) && lower_trim(othr_pipe) == lower_trim(USname)  )
											{

											matchis=1;
											//lets set the pipe inverts and HGL values
											Real ild,ilu;
											Real hglhs,hgrhs;

											Get_drainage_pipe_inverts(detm,K,ilu ,ild );
											Get_drainage_pipe_hgls (detm,K,hglhs,hgrhs);
											//do we need to fix up -999 null values or silly +9999 GIS values?


											//lets add some QA data to our report
											if (  useUNIT == 2 )
												{
												//in mm
												INVsCOMP +=  name_sub + delim + meters_to_mm(ilu,0) + delim + surv_sub + delim + meters_to_mm(pipeINV,0) + delim + "diff:" + delim + meters_to_mm(pipeINV - ilu,0);
												}
											else
												{
//in m
												INVsCOMP +=  name_sub + delim + To_text(ilu,3) + delim + surv_sub + delim + To_text(pipeINV,3) + delim + "diff:" + delim + To_text(pipeINV - ilu,3);
												}
											INVsCOMP += delim + pipe_justify + delim + just_type + delim + pipe_inv_offset + delim + invOffset;


											Set_drainage_pipe_attribute           (detm,K,"SUBpipeUse", "YES");
											Set_drainage_pipe_attribute           (detm,K,"SUBpipe invert ds", pipeINV);


											++matched_pit;
											}



										if ( matchis == 1 )
											{
											//we should check if there is another dia or type from another point
											//get pipe attributes that match * name
											//split the name to get the point number
											//get the value to report on if different
											//put a not possible error inputs
											Attributes atts;
											Attribute_delete_all    (  atts) ;

											Get_drainage_pipe_attributes           (detm,K, atts);
											Text  DpointNo="";
											Real  Dvalue=-999;
											//Integer hdia = get_matching_att_pt_value (  atts, "Diameter at point " ,  DpointNo, Dvalue );
											//get_matching_att_pt_value       (        atts,   "has points" ,"Point " , "Point ID" ,"Diameter" ,   DpointNo,       Dvalue );

											Integer hdia = get_matching_att_pt_value (  atts, "has points" ,"Point ", "Pt ID" , "Diameter" ,  DpointNo, Dvalue );
											Text  TpointNo="", Tvalue="";
											//Integer htp = get_matching_att_pt_value (  atts, "Type at point " ,  TpointNo, Tvalue );
											Integer htp = get_matching_att_pt_value (  atts, "has points" ,"Point ", "Pt ID",  "Type" , TpointNo, Tvalue );

											//this is a pipe that matches
											//set the new attribute values for QA



											Attributes   p_at_gr;
											Attribute_delete_all    (  p_at_gr) ;
											Set_attribute           (p_at_gr,"Pt ID",point_number) ;
											Set_attribute           (p_at_gr,"diameter",pipeDIAm) ;
											if ( pipeDIAmwidth > 0.1 ) Set_attribute           (p_at_gr,"width",pipeDIAmwidth) ;
											Set_attribute           (p_at_gr,"Type",pipe_type) ;


											Text pi_name_point = get_unique_pipe_name(detm,K,"Point ");

											Set_drainage_pipe_attribute           (detm,K,pi_name_point,p_at_gr) ;


											//  Set_drainage_pipe_attribute           (detm,K,"points/at point " + point_number + "/Diameter" , pipeDIAm );
											//  Set_drainage_pipe_attribute           (detm,K,"points/at point " + point_number +"/Type", pipe_type);

											Set_drainage_pipe_attribute           (detm,K,"has points", "1" );



											Set_drainage_pipe_attribute           (detm,K,"SUBpipe pipe diameter", pipeDIAm);
											Set_drainage_pipe_attribute           (detm,K,"SUBpipe pipe size", meters_to_mm(pipeDIAm,0) );
											Set_drainage_pipe_attribute           (detm,K,"SUBpipe type", pipe_type);

											Real ds_inv_t =0,us_inv_t =0,plength=0;
											Get_drainage_pipe_attribute           (detm,K,"SUBpipe invert ds", ds_inv_t);
											Get_drainage_pipe_attribute           (detm,K,"SUBpipe invert us", us_inv_t);
											Get_drainage_pipe_length              (detm,K,plength);

											Real delh= us_inv_t - ds_inv_t;

											Real slop = plength / delh;

											Set_drainage_pipe_attribute           (detm,K,"SUBpipe grade 1 in", slop);
											Set_drainage_pipe_attribute           (detm,K,"SUBpipe grade", 100/slop);




											}


										}//for K


									}//for d



								}//if pipe






























































































































							// QA report has to show number of pipes found
							if ( matched_pit == 0)
								{
								Append(" ",dt_pipe_set);
								Append(" ",dt_pipe_inv_comp);

								}
							else	if ( matched_pit > 0)
								{
								Append("INV Set x" + To_text(matched_pit) ,dt_pipe_set);
								Append(INVsCOMP,dt_pipe_inv_comp);
								}



							//QA text to be added to pits
							Text mhDistances="";
							//number of pits matched
							Integer matched_MH=0;
							//loop all drainage strings and lets focus on adding data to pits
							for (Integer d=1; d<=total_no_dne; d++)
								{
								Element detm;
								Get_item(de,d,detm);
//Set_drainage_use_connection_points(detm,1);
//Calc_extent(detm);

//Drainage_Adjust_Pit_Connection_Points_All(  detm);
//Calc_extent(detm);

								//get element type and only work with drainage
								Text dstr_type="";
								Get_type(detm,dstr_type);
								if(dstr_type != "Drainage") continue;

								//number or pits available
								Integer npits=0;
								Get_drainage_pits             (  detm,  npits) ;

								//number of points is also important - not all points have a MH on them
								Integer numverts=0;
								Get_points   (  detm, numverts);
								//we need to keep matching the vertex posn to pit posn

								//manual set pit cover level
								Set_drainage_float            (detm  ,  fl_top);

								for (Integer p=1; p<=npits; p++)
									{
									//manual set pit cover level
									Set_drainage_pit_float            (detm  ,p,  fl_top );

									Text dpitname="";
									Get_drainage_pit_name (  detm,p, dpitname) ;

									if ( lower_trim(dpitname) == "" || lower_trim(dpitname) == " " )
										{
										//this is not good we have blank names on pits
										continue;
										//skip this pit
										}


									if ( lower_trim(dpitname) == lower_trim(pitName) )
										{
										//match string attribute to the pit name

										//get vertex data that match the pit
										//each pit must have a vertex
										Integer vertex;
										get_drainage_vertex_index(detm,p,vertex);

										//keep existing attributes
										Attributes topa,orgatt;
										Attribute_delete_all    (  topa) ;
										Attribute_delete_all    (  orgatt) ;
										Get_drainage_pit_attributes  ( detm,p,topa);
										Get_drainage_pit_attributes  ( detm,p,orgatt);

										Integer dCy,mCy,yCy;
										Date(dCy,mCy,yCy);
										Text Cdatnow = To_text(yCy) + " " + To_text(mCy) + " " +To_text(dCy);

										if ( codeMode == 1 || codeMode == 2  || codeMode == 3 )
											{

											if ( Attribute_exists        (  topa,"SurveyInfo/Date") != 0  )
												{
												//check if it is on the same date

												Text olddate="";
												Get_attribute (  topa,"SurveyInfo/Date",olddate);
												if ( Text_lower(olddate ) != Text_lower(Cdatnow)  )
													{
													//this is old survey info data
													//lets archive it
													Set_attribute           (topa,"OriginalInfo",orgatt) ;
													Set_attribute           (topa,"OriginalInfo/Date of Copy OI",Cdatnow) ;
													Attribute_delete        (topa,"SurveyInfo");
													Set_attribute (topa,"SurveyInfo/Date",Cdatnow) ;

													}
												}
											else
												{
												Set_attribute (topa,"SurveyInfo/Date",Cdatnow) ;
												Set_attribute (topa,"OriginalInfo",orgatt) ;
												Set_attribute (topa,"OriginalInfo/Date of Copy OI",Cdatnow) ;
												}
											}

										if ( codeMode == 1 )
											{

											if ( nec_used == 1 )
												{
												//use the z value for the PIT Grade value

												Integer no_zzs;
												Get_number_of_items(nec_names, no_zzs);

												for (Integer zz = 1; zz <= no_zzs; zz++)
													{
													Text zzsg;
													Get_item (nec_names,zz,zzsg);
													if ( lower_trim(zzsg) == lower_trim(pitName) )
														{
														Get_item (nec_zds,zz,z);
														break;
														}
													}

												}


											Real RL_sump_pt= -999999.0 ;

											if ( sumRL_code != "?" )
												{
												//use the z value for the PIT Grade value

												Integer no_zzs;
												Get_number_of_items(SumRL_names, no_zzs);

												for (Integer zsz = 1; zsz <= no_zzs; zsz++)
													{
													Text smrlg;
													Get_item (SumRL_names,zsz,smrlg);
													if ( lower_trim(smrlg) == lower_trim(pitName) )
														{
														Get_item (SumRL_zds,zsz,RL_sump_pt);
														break;
														}
													}

												}

											// this is a Manhole Centre code point
											Real orgx,orgy,orgz;
											//get the coordinates of this pit
											//NOTE to set new we need to also find vertex coordinates
											Get_drainage_pit              (detm,p,orgx,orgy,orgz);

											Real xd,yd,zd,rd;
											Integer fd;
											//cool so lets get the vertex data
											Get_drainage_data(detm,vertex,xd,yd,zd,rd,fd);

											//we need some QA data for the report
											Real deltx = x-orgx;
											Real delty = y-orgy;
											Real dist = Sqrt( (deltx*deltx) + (delty*delty) );
											Text detm_n="";
											Get_name(  detm, detm_n);

											// useUNIT = 2  mm
//mm_to_meters
//meters_to_mm


											//lets add some QA data to our report
											if (  useUNIT == 2 )
												{
												//mm
												mhDistances +=  "Name" + delim +detm_n + delim + "Dist to PIT" + delim +  meters_to_mm(dist,0) + delim ;
												}
											else       //m
												{
												mhDistances +=  "Name" + delim +detm_n + delim + "Dist to PIT" + delim +  To_text(dist,2) + delim ;
												}

											if ( show_inputs == 1 )
												{
												if (  useUNIT == 2 )
													{
													//mm
													mhDistances += "Type"  + delim + pitType + delim + "Dia"  + delim + meters_to_mm(pitSIZEm,0)  + delim + "Width"  + delim + meters_to_mm(pitSIZEwM,0)  + delim;
													}
												else
													{
													//m
													mhDistances += "Type"  + delim + pitType + delim + "Dia"  + delim + To_text(pitSIZEm,3)  + delim + "Width"  + delim + To_text(pitSIZEwM,3)  + delim;
													}
												if ( pitSump > -99 )
													{
													if (  useUNIT == 2 )
														{
														//mm
														mhDistances +=  "SumpOffset"  + delim + meters_to_mm(pitSump,0) + delim;
														}
													else
														{
														//m
														mhDistances +=  "SumpOffset"  + delim + To_text(pitSump,3) + delim;

														}
													}
												}

											if ( show_atts == 1 )
												{
												Text  data;
												attributes_to_delim_text(  mh_atts ,   delim,   data);

												mhDistances += data + delim;
												}

											if ( Attribute_exists        (  topa,  "SurveyInfo") != 0 )
												{

												Text olddate="";
												Get_attribute (  topa,"SurveyInfo/Date",olddate);
												if ( Text_lower(olddate ) != Text_lower(Cdatnow)  )
													{
													Print("something is wrong, the surveyInfo doesnt match today!");
													Print();
													}
												else
													{
													//group of attributes exist
													Attributes infatt;
													Attribute_delete_all    (  infatt) ;
													Get_attribute (  topa,"SurveyInfo",  infatt);

													Set_attribute (infatt,"FieldPITatts",mh_atts) ;
													Set_attribute (infatt,"SurveyFirm",compAtts) ;
													Set_attribute (  topa,"SurveyInfo",  infatt);
													}
												}
											else
												{
												Print("something is wrong, the surveyInfo doesnt match today!");
												Print();
												Set_attribute (topa,"SurveyInfo/FieldPITatts",mh_atts) ;
												Set_attribute (topa,"SurveyInfo/SurveyFirm",compAtts) ;
												Set_attribute (topa,"SurveyInfo/Date",Cdatnow) ;
												}


											Set_attribute (topa,"SurveyInfo/" + accur_attrib_name,pitACCUR) ;

											//we have a match
											++matched_MH;
											//lets set the vertex first
											Integer flt = 0;
											Get_drainage_pit_float(detm,p,flt);
											Set_drainage_pit_float(detm,p,0);

											Set_drainage_data(detm,vertex,x,y,z,rd,fd);
											//set the pit details nextedc
											Set_drainage_pit (detm,p,x, y,z);

											//lets recalc the string making a change
											Calc_extent(detm  );
											//Set_drainage_pit_float(detm,p,flt);
											Real r=0;
											Integer f=0;

											//lets set the values and attributes


											Set_drainage_pit_type         (  detm,p, pitType);


											if ( pitSIZEwM	>= 0.001 ) {
												Set_drainage_pit_diameter     (  detm,p,pitSIZEm);
												Set_drainage_pit_width( detm,p,pitSIZEwM);
												Set_drainage_pit_length( detm,p,pitSIZEm);
												Set_attribute  (topa,"pit length", pitSIZEm);
												Set_attribute  (topa,"pit width", pitSIZEwM);
												del_att_value(  topa,"pit diameter");
												}
											else {
												Set_drainage_pit_diameter     (  detm,p,pitSIZEm);
												Set_attribute  (topa,"pit diameter", pitSIZEm );
												}

											Set_attribute  (topa,"cover rl mode", 2);
											Set_attribute  (topa,"grate rl mode", 7);
											Set_attribute  (topa,"pit type", pitType );
											Set_attribute  (topa,"pit name", dpitname );
											Set_attribute (topa,accur_attrib_name,pitACCUR) ;



											Real rad,brg,degs;
											Degrees_to_radians   (pitAngle, rad);

											Bearing_to_angle   (rad, brg);
											Radians_to_degrees   (  brg,degs);
											Set_drainage_pit_symbol_angle(detm,p,degs);
											Set_attribute  (topa,"pit symbol angle mode", "Manual" );
											//Set_attribute  (topa,"con point mode", "Centre" );
											Set_attribute  (topa,"con point mode", "Unrestricted" );
											Drainage_Adjust_Pit_Connection_Points(detm,p);

//Integer conpts=1;
//
											//										Set_attribute  (detm,"using con points", conpts);




											//we only set sump rls if they exist
											if ( pitSump > -99 )
												{
												Set_drainage_pit_float_sump(detm,p,1);
												Set_attribute  (topa,"sump offset", pitSump );
												del_att_value(  topa,"sump level");
												Set_attribute  (topa,"sump floating", 1 );
												}
											else
												{
												del_att_value(  topa,"sump offset");
												}
											if ( RL_sump_pt > -999.0 ) {
												Set_drainage_pit_float_sump(detm,p,0); // ID = 2786
												Set_drainage_pit_sump_level(detm,p,RL_sump_pt); // ID = 2788
												Set_attribute  (topa,"sump level", RL_sump_pt );
												Set_attribute  (topa,"sump floating", 0 );
												Set_attribute  (topa,"sump offset", 0.0 );
												}
											else {
												del_att_value(  topa,"sump level");
												}

											del_att_value(  topa,"grate level");
											del_att_value(  topa,"cover elev");

											del_att_value(  topa,"pit depth");

											del_att_value(  topa,"cover rl");
											del_att_value(  topa,"grate level");
											del_att_value(  topa,"pit centre x");
											del_att_value(  topa,"pit centre y");
											del_att_value(  topa,"pit centre z");
											del_att_value(  topa,"pit centre fs level");
											del_att_value(  topa,"pit centre ns level");
											del_att_value(  topa,"ds invert");
											del_att_value(  topa,"us invert");
											del_att_value(  topa,"invert ds");
											del_att_value(  topa,"invert us");




											}
										else   if ( codeMode == 2 )
											{
											//if the code is LID lets add attributes to the pit
											if ( Attribute_exists        (  topa,  "SurveyInfo") != 0 )
												{

												Text olddate="";
												Get_attribute (  topa,"SurveyInfo/Date",olddate);
												if ( Text_lower(olddate ) != Text_lower(Cdatnow)  )
													{
													Print("something is wrong, the surveyInfo doesnt match today!");
													Print();
													}
												else
													{

													//group of attributes exist
													Attributes infatt;
													Attribute_delete_all    (  infatt) ;
													Get_attribute (  topa,"SurveyInfo",  infatt);

													if ( Attribute_exists(  infatt,"FieldOTHERatts") != 0 )
														{
														//group of lid info exists
														Attributes lev2;
														Attribute_delete_all    (  lev2) ;
														Get_attribute (  infatt,"FieldOTHERatts",  lev2);

														Text lidbeadd="";

														Get_attribute_name (  lid_atts,1,  lidbeadd);
														Attributes  attcons;
														Attribute_delete_all    (  attcons) ;
														Get_attribute (lid_atts,1,  attcons);

														Set_attribute (lev2,lidbeadd,attcons) ;

														Set_attribute (infatt,"FieldOTHERatts",lev2) ;
														Set_attribute (  topa,"SurveyInfo",  infatt);


														}
													else
														{
														Set_attribute (infatt,"FieldOTHERatts",lid_atts) ;
														Set_attribute (  topa,"SurveyInfo",  infatt);
														}
													}
												}
											else
												{
												Print("something is wrong, the surveyInfo doesnt match today!");
												Print();
												Set_attribute (topa,"SurveyInfo/FieldOTHERatts",lid_atts) ;
												Set_attribute (topa,"SurveyInfo/Date",Cdatnow) ;
												}

											}
										else  if ( codeMode == 3 )
											{
											//if the code is PIPE lets add attributes to the pit



											if ( Attribute_exists        (  topa,  "SurveyInfo") != 0 )
												{
												Text olddate="";
												Get_attribute (  topa,"SurveyInfo/Date",olddate);
												if ( Text_lower(olddate ) != Text_lower(Cdatnow)  )
													{
													Print("something is wrong, the surveyInfo doesnt match today!");
													Print();
													}
												else
													{
													//group of attributes exist
													Attributes infatt;
													Attribute_delete_all    (  infatt) ;
													Get_attribute (  topa,"SurveyInfo",  infatt);

													if ( Attribute_exists(  infatt,"FieldPIPEatts") != 0 )
														{
														//group of lid info exists
														Attributes lev2;
														Attribute_delete_all    (  lev2) ;
														Get_attribute (  infatt,"FieldPIPEatts",  lev2);

														Text lidbeadd="";

														Get_attribute_name (  pipe_atts,1,  lidbeadd);
														Attributes  attcons;
														Attribute_delete_all    (  attcons) ;
														Get_attribute (pipe_atts,1,  attcons);

														Set_attribute (lev2,lidbeadd,attcons) ;

														Set_attribute (infatt,"FieldPIPEatts",lev2) ;
														Set_attribute (  topa,"SurveyInfo",  infatt);


														}
													else
														{
														Set_attribute (infatt,"FieldPIPEatts",pipe_atts) ;
														Set_attribute (  topa,"SurveyInfo",  infatt);
														}
													}
												}
											else
												{
												Print("something is wrong, the surveyInfo doesnt match today!");
												Print();
												Set_attribute (topa,"SurveyInfo/FieldPIPEatts",pipe_atts) ;
												Set_attribute (topa,"SurveyInfo/Date",Cdatnow) ;
												}


											}
										// now that we have added all the attributes to the group lets set them on the string
										Set_drainage_pit_attributes          ( detm,p,topa);

										Calc_extent(detm  );

										}//if pit name is asset
									}//for p

								}//for d


							//QA report to show how many MH were found and how far
							if ( matched_MH == 0)
								{
								mhDistances = 		 " " + delim + mhDistances;
								}
							else	if ( matched_MH > 0)
								{
								mhDistances = 		 "Found x" + To_text(matched_MH) + delim + mhDistances;
								}
							Append(mhDistances,dt_dist_to_pit);


							}// this is the one that end looping survey points vertex




						}//if i

					Null(nec_names);
					Null(nec_zds);

					//lets create the QA report


					File_open(reportfile,"w+",file);
					File_write_line(file, "Survey Points update Drainage Network");
					File_write_line(file, "QA report");
					File_write_line(file, "-------------------------------------");
					File_write_line(file, "Point ID, Feature Code,Pit Name to Match,Code Desc,Pipe INVs set,Pit Found ,String Details");




					Integer  rep_no;
					Get_number_of_items(dt_pt_id,rep_no);

					for (Integer f=1; f<=rep_no; f++)
						{	Integer tP = 0;
						Text line;
						Text item;
						Get_item(dt_pt_id,f,item);
						line = item + delim;
						Get_item(dt_pt_name,f,item);
						line += item + delim;
						Get_item(dt_pt_att,f,item);
						line += item + delim;
						Get_item(dt_matched,f,item);
						if ( item == "Pipe Code") {
							tP = 1; //pipe
							}
						else if (item == "Centre of Pit Code" ) {
							tP = 2; //pit
							}
						else if ( item == "unknown") {
							tP = 3; //other
							}
						line += item + delim;
						Get_item(dt_pipe_set,f,item);
						if ( tP == 1 ) {
							if ( trim(item) != "" )
								{

								Integer start = Find_text( item,"INV Set x");
								if ( start != 0 )
									{
									//  found this is NOT a blank line
									line += item + delim;
									}
								else
									{
									line += "ERROR 1 - match not found - check your attributes" + delim;
									}
								}
							else
								{
								line += "ERROR 2 - match not found - check your attributes" + delim;
								}
							}
						else {
							line += item + delim;
							}
						Get_item(dt_dist_to_pit,f,item);
						if ( tP == 2 ) {
							if ( trim(item) != "" )
								{

								Integer start = Find_text( item,"Found x");
								if ( start != 0 )
									{
									//  found this is NOT a blank line
									line += item + delim;
									}
								else
									{
									line += "ERROR 3 - match not found - check your attributes" + delim;
									}
								}
							else
								{
								line += "ERROR 4 - match not found - check your attributes" + delim;
								}
							}
						else if (tP == 3 ) {
							line += "other point - string name not processed" + delim;
							}
						else {
							line += item + delim;
							}


						Get_item(dt_pipe_inv_comp,f,item);
						line += item ;

						File_write_line(file, line);

						}

					File_flush(file);
					File_rewind(file);

					File_close(file);

					Text cmdline =  "start notepad " + reportfile;
					System(cmdline);

					Null(dt_pt_id);
					Null(dt_pt_name);
					Null(dt_pt_att);
					Null(dt_matched);
					Null(dt_pipe_set);
					Null(dt_dist_to_pit);
					Null(dt_pipe_inv_comp);



					Set_data(message,"DONE");



					}
				break;





			}
		}
	}

void main()
//---------------------------------------------------------
//
//---------------------------------------------------------
	{
	manage_a_panel();
	}



