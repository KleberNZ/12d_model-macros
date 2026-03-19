// ------------------------------------------------------------------------------------------------
//       Lesson 1 Parse Error (spelling mistake) - Syntax Error (poor grammar but correct spelling)
//                Parse errors often lead to syntax errors
// ------------------------------------------------------------------------------------------------
  
  
  void main ( {
  
  }// -----------------------------------------------------------------------------------------------------------
//        Lesson 2 variable name already defined - note there are some names you cannot use - Reserved names.
//        Model,Text,Real,Integer...
// -----------------------------------------------------------------------------------------------------------
  
void main ()
{
    Real x = 10;
  
    Real x = 9;
}// -------------------------------------------------------------------------
//        Lesson 5: The most common error of all, missing semi colon.
// -------------------------------------------------------------------------

void main()
{

  Print("Hello World\n");
  Print()

}
// ------------------------------------------------------------------------------------------------------------------
//        Lesson 11: Run time errors - Arrays and referencing array outside it's range - heap array bounds error 
// ------------------------------------------------------------------------------------------------------------------
 
 #define DEBUG 1 // a new compiler directive to create a compiler variable
 
 
 void print(Text &stuff)
 {
    Print (stuff+"\n");
 }
 
void main () {
    
	Integer number_of_names = 10;
	// Integer number_of_names = 0;  // this will cause a run time error as well
	
	Text names[number_of_names];
	// for big arrays the use of a variable to define the size is better (uses the memory heap which is larger)
	// Text names[10];
	
	for(Integer i=1;i<=number_of_names+1;i++) {   // if we go past the end of the array the macro will terminate
       names[i] = "Rob "+To_text(i);

	   
#if DEBUG
  Print(__FILE__ + " " + To_text(__LINE__)+"\n");
#endif
	   
#if DEBUG
	   print(names[i]);
#endif

	 }

}

/*
  run this macro to get the "run time" error
*/// ------------------------------------------------------------------------------------------------------------------
//        Lesson 11: Run time errors - Arrays and referencing array outside it's range - heap array bounds error 
// ------------------------------------------------------------------------------------------------------------------
 
 #define DEBUG 1 // a new compiler directive to create a compiler variable
 
 
 void print(Text &stuff)
 {
    Print (stuff+"\n");
 }
 
void main () {
    
	Integer number_of_names = 10;
	// Integer number_of_names = 0;  // this will cause a run time error as well
	
	Text names[number_of_names];
	// for big arrays the use of a variable to define the size is better (uses the memory heap which is larger)
	// Text names[10];
	
	for(Integer i=1;i<=number_of_names;i++) {   // if we go past the end of the array the macro will terminate
       names[i] = "Rob "+To_text(i);

	   
#if DEBUG
  Print(__FILE__ + " " + To_text(__LINE__)+"\n");
#endif
	   
#if DEBUG
	   print(names[i]);
#endif

	 }

}

/*
  run this macro to get the "run time" error
*/