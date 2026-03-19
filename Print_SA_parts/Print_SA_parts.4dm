#define SELECT_STRING   5509

void report_sa_horiz(Element &e){
	Text t="";
	Integer num_parts;
	Get_super_alignment_horz_parts    (e ,num_parts);
	for(Integer i=1;i<=num_parts;i++){
		Text elt_part;
		Get_super_alignment_horz_part(e,i,elt_part);
		t+=elt_part+"\n";

	}
	Print(t);
}

void report_sa_vert(Element &e){
	Text t="";
	Integer num_parts;
	Get_super_alignment_vert_parts    (e ,num_parts);
	for(Integer i=1;i<=num_parts;i++){
		Text elt_part;
		Get_super_alignment_vert_part(e,i,elt_part);
		t+=elt_part+"\n";
	}
	Print(t);
}

void report_sa(Element &e){
	Text type;
	Get_type(e,type);
	Text name;
	Get_name(e,name);
	if(type=="Super_Alignment"){
		Print("\nReporting Super Alignment [" + name + "]\nHorizontal parts:\n\n\n");
		report_sa_horiz(e);
		Print("\n\n\nReporting Super Alignment [" + name + "]\nVertical parts:\n\n\n");
		report_sa_vert(e);
		Print("\n\n\n<<< Finished Reporting Super Alignment [" + name + "]\n");
	}else{
		Print("\n[" + name + "]is not a Super Alignment, it is a " + type + "\n");
	}
}

void manage_a_panel()
{
	Panel          panel   = Create_panel("SA report parts to output window");
	Message_Box    message = Create_message_box("  ");
	Vertical_Group vg1  = Create_vertical_group(0);
	Vertical_Group vg_all  = Create_vertical_group(0);
	Horizontal_Group button_group = Create_button_group();

	Select_Box select_box = Create_select_box("   String to repot    ","Pick source string", SELECT_STRING,message);

	Button process  = Create_button("&Process" ,"process");

	Append(select_box,vg1);
	Append(process ,button_group);
	Append(vg1 ,vg_all);
	Append(message,vg_all); 
	Append(button_group ,vg_all);
	Append(vg_all,panel);

	Show_widget(panel);

	while (1) {
		Integer id;
		Text    cmd,msg;
		Integer ret = Wait_on_widgets(id,cmd,msg);
		if(cmd == "keystroke") continue;
		switch(id){
		case Get_id(panel) : {
			if(cmd == "Panel Quit") return;
			} break;

			case Get_id(process) : {

				Element e;
				if(Validate(select_box,e)!=1){
					Set_data(message,"Dud source!");
					break;
				}
				Clear_console();
				report_sa(e);
				Show_console(1);

				Set_data(message,"Finished");

			}break;
		}
	}
}



void main(){
	manage_a_panel();
}