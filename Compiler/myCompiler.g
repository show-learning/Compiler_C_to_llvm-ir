grammar myCompiler;

options {
   language = Java;
}

@header {
    // import packages here.
    import java.util.HashMap;
    import java.util.ArrayList;
}

@members {
    boolean TRACEON = false;

    // Type information.
    public enum Type{
       ERR, BOOL, INT, FLOAT, CHAR, CONST_INT;
    }

    // This structure is used to record the information of a variable or a constant.
    class tVar {
	   int   varIndex; // temporary variable's index. Ex: t1, t2, ..., etc.
	   int   iValue;   // value of constant integer. Ex: 123.
	   float fValue;   // value of constant floating point. Ex: 2.314.
	};

    class Info {
       Type theType;  // type information.
       tVar theVar;
	   
	   Info() {
          theType = Type.ERR;
		  theVar = new tVar();
	   }
    };

	
    // ============================================
    // Create a symbol table.
	// ArrayList is easy to extend to add more info. into symbol table.
	//
	// The structure of symbol table:
	// <variable ID, [Type, [varIndex or iValue, or fValue]]>
	//    - type: the variable type   (please check "enum Type")
	//    - varIndex: the variable's index, ex: t1, t2, ...
	//    - iValue: value of integer constant.
	//    - fValue: value of floating-point constant.
    // ============================================

    HashMap<String, Info> symtab = new HashMap<String, Info>();

    // labelCount is used to represent temporary label.
    // The first index is 0.
    int labelCount = 0;
	
    // varCount is used to represent temporary variables.
    // The first index is 0.
    int varCount = 0;

    // Record all assembly instructions.
    List<String> TextCode = new ArrayList<String>();

    int Str_count = 0;
    List<String> Str = new ArrayList<String>();


    /*
     * Output prologue.
     */
    void prologue()
    {
       TextCode.add("; === prologue ====");
       TextCode.add("declare dso_local i32 @printf(i8*, ...)\n");
	   TextCode.add("define dso_local i32 @main()");
	   TextCode.add("{");
    }
    
	
    /*
     * Output epilogue.
     */
    void epilogue()
    {
       /* handle epilogue */
       TextCode.add("\n; === epilogue ===");
	   TextCode.add("ret i32 0");
       TextCode.add("}");
    }
    
    
    /* Generate a new label */
    String newLabel()
    {
       labelCount ++;
       return (new String("L")) + Integer.toString(labelCount);
    } 
    
    
    public List<String> getTextCode()
    {
       return TextCode;
    }

    public List<String> getStr()
    {
       return Str;
    }
}

program: VOID MAIN '(' ')'
        {
           /* Output function prologue */
           prologue();
        }

        '{' 
           declarations
           statements
        '}'
        {
	   if (TRACEON)
	      System.out.println("VOID MAIN () {declarations statements}");

           /* output function epilogue */	  
           epilogue();
        }
        ;


declarations: type Identifier complex_declarations[$type.attr_type] ';' declarations
        {
           if (TRACEON)
              System.out.println("declarations: type Identifier : declarations");

           if (symtab.containsKey($Identifier.text)) {
              // variable re-declared.
              System.out.println("Type Error: " + 
                                  $Identifier.getLine() + 
                                 ": Redeclared identifier.");
              System.exit(0);
           }
                 
           /* Add ID and its info into the symbol table. */
	       Info the_entry = new Info();
		   the_entry.theType = $type.attr_type;
		   the_entry.theVar.varIndex = varCount;
		   varCount ++;
		   symtab.put($Identifier.text, the_entry);

           // issue the instruction.
		   // Ex: \%a = alloca i32, align 4
           if ($type.attr_type == Type.INT) { 
              TextCode.add("\%t" + the_entry.theVar.varIndex + " = alloca i32, align 4");
           }
           else if ($type.attr_type == Type.FLOAT) { 
              TextCode.add("\%t" + the_entry.theVar.varIndex + " = alloca float, align 4");
           }
           else if ($type.attr_type == Type.CHAR) { 
              TextCode.add("\%t" + the_entry.theVar.varIndex + " = alloca i8, align 1");
           }
        }
        | 
        {
           if (TRACEON)
              System.out.println("declarations: ");
        }
        ;

complex_declarations[Type attr_type]:
    ',' Identifier complex_declarations[$attr_type]{
        if (TRACEON)
              System.out.println("declarations: type Identifier : declarations");
           if (symtab.containsKey($Identifier.text)) {
              // variable re-declared.
              System.out.println("Type Error: " + 
                                  $Identifier.getLine() + 
                                 ": Redeclared identifier.");
              System.exit(0);
           }   
           /* Add ID and its info into the symbol table. */
	       Info the_entry = new Info();
		   the_entry.theType = $attr_type;
		   the_entry.theVar.varIndex = varCount;
		   varCount ++;
		   symtab.put($Identifier.text, the_entry);

           // issue the instruction.
		   // Ex: \%a = alloca i32, align 4
           if ($attr_type == Type.INT) { 
              TextCode.add("\%t" + the_entry.theVar.varIndex + " = alloca i32, align 4");
           }
           else if ($attr_type == Type.FLOAT) { 
              TextCode.add("\%t" + the_entry.theVar.varIndex + " = alloca float, align 4");
           }
           else if ($attr_type == Type.CHAR) { 
              TextCode.add("\%t" + the_entry.theVar.varIndex + " = alloca i8, align 1");
           }
        }
    |;


type
returns [Type attr_type]
    : INT { if (TRACEON) System.out.println("type: INT"); $attr_type=Type.INT; }
    | CHAR { if (TRACEON) System.out.println("type: CHAR"); $attr_type=Type.CHAR; }
    | FLOAT {if (TRACEON) System.out.println("type: FLOAT"); $attr_type=Type.FLOAT; }
	;


statements:statement statements
          |
          ;


statement: assign_stmt ';'
         | if_stmt
         | func_no_return_stmt ';'
         | f = for_stmt{
            int Lend = $f.body + 1;
            TextCode.add("");
            TextCode.add("L" + Lend +":");
         }
         | w = while_stmt{
            int Lend = $w.body + 1;
            TextCode.add("");
            TextCode.add("L" + Lend +":");
         }
         | d = dowhile_stmt{
            int Lend = $d.end;
            TextCode.add("");
            TextCode.add("L" + Lend +":");
         }
         | print_stament
         ;

for_stmt returns[int cond,int inc,int body]: FOR '(' assign_stmt ';'{
                     $cond = labelCount;
                     TextCode.add("br label \%L" + $cond);
                     TextCode.add("");
                     TextCode.add("L" + $cond +":");
                     labelCount++;
                  }
                  cond_expression ';'{
                     $body = labelCount;
                     int Lend = labelCount + 1;
                     TextCode.add("br i1 \%t" + $cond_expression.rst +", label \%L" + $body +", label \%L" + Lend);
                     $inc = labelCount + 2;
                     TextCode.add("");
                     TextCode.add("L" + $inc +":");
                     labelCount = labelCount + 3;
                  }
                  assign_stmt{
                     TextCode.add("br label \%L" + $cond);
                  }
              ')'
                  {
                     TextCode.add("");
                     TextCode.add("L" + $body +":");
                  }
                  block_stmt{
                     TextCode.add("br label \%L" + $inc);
                  }
        ;
		 
while_stmt returns[int cond, int body]: WHILE
            {
               $cond = labelCount;
               TextCode.add("br label \%L" + $cond);
               TextCode.add("");
               TextCode.add("L" + $cond +":");
               labelCount++;
            } '(' cond_expression ')' 
            {
               $body = labelCount;
               int Lend = labelCount + 1;
               TextCode.add("br i1 \%t" + $cond_expression.rst +", label \%L" + $body +", label \%L" + Lend);
               TextCode.add("");
               TextCode.add("L" + $body +":");
               labelCount = labelCount + 2;

            }block_stmt{
               TextCode.add("br label \%L" + $cond);
            };
dowhile_stmt returns[int body, int end]: DO 
            {
               $body = labelCount;
               TextCode.add("br label \%L" + $body);
               TextCode.add("");
               TextCode.add("L" + $body +":");
               labelCount++;
            }
            block_stmt WHILE '(' cond_expression ')' ';'
            {
               $end = labelCount;
               TextCode.add("br i1 \%t" + $cond_expression.rst +", label \%L" + $body +", label \%L" + $end);
               labelCount++;
            } 
            ;
if_stmt
            : t=if_then_stmt if_else_stmt[$t.Ltrue]
            {
               int Lend = $t.Ltrue + 2;
               TextCode.add("");
               TextCode.add("L" + Lend +":");
            }
            ;

	   
if_then_stmt returns[int Ltrue]
            : IF '(' cond_expression ')' 
            {
               $Ltrue = labelCount;
               int Lfalse = labelCount + 1;
               TextCode.add("br i1 \%t" + $cond_expression.rst +", label \%L" + Ltrue +", label \%L" + Lfalse);
               TextCode.add("");
               TextCode.add("L" + Ltrue +":");
               labelCount += 3 ;
            }block_stmt
            {
               int Lend = $Ltrue + 2;
               TextCode.add("br label \%L" + Lend);
            }
            ;


if_else_stmt[int t]
            :
            ELSE
            {
               int Lfalse = $t + 1;
               TextCode.add("");
               TextCode.add("L" + Lfalse +":");
            }block_stmt
            {
               int Lend = $t + 2;
               TextCode.add("br label \%L" + Lend);
            }
            |{
               int Lfalse = $t + 1;
               TextCode.add("");
               TextCode.add("L" + Lfalse +":");
               int Lend = $t + 2;
               TextCode.add("br label \%L" + Lend);
            };


block_stmt: '{' statements '}'

	  ;

print_stament: PRINT
    '(' A=STRING_LITERAL{int q = 0;} (',' Identifier
      {
        q++;
        Info theIDRS = symtab.get($Identifier.text);
        TextCode.add("\%t" + varCount +"= load i32, i32* \%t" + theIDRS.theVar.varIndex);
        varCount++;
        })*
    ')'  ';'
      { 
         String s=$A.text;
         int len = 0;
         String temp = new String("");
         for(int i=0;i<s.length()-1;i++){
               if(s.charAt(i) =='\\' &&s.charAt(i+1) =='n'){
                    len = len + 1;
                    temp = temp + "\\0A";
                    i++;
                }else{
                    len = len + 1;
                    temp = temp + s.charAt(i);
                }	
            }
         temp = temp + "\\00";
         temp = temp + '"';
         Str_count++;
         Str.add("@str." + Str_count + "= private unnamed_addr constant [" + len + "x i8] c" + temp);
         TextCode.add("\%t" + varCount + "= call i32 (i8*, ...) @printf(i8* getelementptr inbounds([" + len + "x i8], [" + len + " x i8]* @str."+ Str_count +", i64 0, i64 0)");
         for(int i=0;i<q;i++){
            int num  =  varCount - q + i; 
            TextCode.add(", i32 \%t"+ num);
         }
         TextCode.add(")");
         varCount++;
    } 
    ;




assign_stmt: Identifier '=' arith_expression
             {
                Info theRHS = $arith_expression.theInfo;
				Info theLHS = symtab.get($Identifier.text); 
		   
                if ((theLHS.theType == Type.INT) &&
                    (theRHS.theType == Type.INT)) {		   
                   // issue store insruction.
                   // Ex: store i32 \%tx, i32* \%ty
                   TextCode.add("store i32 \%t" + theRHS.theVar.varIndex + ", i32* \%t" + theLHS.theVar.varIndex);
				} else if ((theLHS.theType == Type.INT) &&
				    (theRHS.theType == Type.CONST_INT)) {
                   // issue store insruction.
                   // Ex: store i32 value, i32* \%ty
                   TextCode.add("store i32 " + theRHS.theVar.iValue + ", i32* \%t" + theLHS.theVar.varIndex);				
				}
			 }
             ;

		   
func_no_return_stmt: Identifier '(' argument ')'
                   ;


argument: arg (',' arg)*
        ;

arg: arith_expression
   | STRING_LITERAL
   ;
		   
cond_expression returns [int rst]:
            a = arith_expression (
               '==' b = arith_expression{
                  if (($a.theInfo.theType == Type.INT) && ($b.theInfo.theType == Type.INT)) 
                     TextCode.add("\%t" + varCount + " = icmp eq i32 \%t" + $a.theInfo.theVar.varIndex + ", \%t" + $b.theInfo.theVar.varIndex);
                  else if (($a.theInfo.theType == Type.INT) && ($b.theInfo.theType == Type.CONST_INT)) 
                     TextCode.add("\%t" + varCount + " = icmp eq i32 \%t" + $a.theInfo.theVar.varIndex + ", " + $b.theInfo.theVar.iValue);
                  else if (($a.theInfo.theType == Type.CONST_INT) && ($b.theInfo.theType == Type.CONST_INT)) 
                     TextCode.add("\%t" + varCount + " = icmp eq i32 " + $a.theInfo.theVar.iValue + ", " + $b.theInfo.theVar.iValue);
                  else if (($a.theInfo.theType == Type.CONST_INT) && ($b.theInfo.theType == Type.INT)) 
                     TextCode.add("\%t" + varCount + " = icmp eq i32 " + $a.theInfo.theVar.iValue + ", \%t" + $b.theInfo.theVar.varIndex);
                  $rst = varCount;
                  varCount++;
               }
               |'!=' b = arith_expression{
                  if (($a.theInfo.theType == Type.INT) && ($b.theInfo.theType == Type.INT)) 
                     TextCode.add("\%t" + varCount + " = icmp ne i32 \%t" + $a.theInfo.theVar.varIndex + ", \%t" + $b.theInfo.theVar.varIndex);
                  else if (($a.theInfo.theType == Type.INT) && ($b.theInfo.theType == Type.CONST_INT)) 
                     TextCode.add("\%t" + varCount + " = icmp ne i32 \%t" + $a.theInfo.theVar.varIndex + ", " + $b.theInfo.theVar.iValue);
                  else if (($a.theInfo.theType == Type.CONST_INT) && ($b.theInfo.theType == Type.CONST_INT)) 
                     TextCode.add("\%t" + varCount + " = icmp ne i32 " + $a.theInfo.theVar.iValue + ", " + $b.theInfo.theVar.iValue);
                  else if (($a.theInfo.theType == Type.CONST_INT) && ($b.theInfo.theType == Type.INT)) 
                     TextCode.add("\%t" + varCount + " = icmp ne i32 " + $a.theInfo.theVar.iValue + ", \%t" + $b.theInfo.theVar.varIndex);
                  $rst = varCount;
                  varCount++;
               }
               |'>' b = arith_expression{
                  if (($a.theInfo.theType == Type.INT) && ($b.theInfo.theType == Type.INT)) 
                     TextCode.add("\%t" + varCount + " = icmp sgt i32 \%t" + $a.theInfo.theVar.varIndex + ", \%t" + $b.theInfo.theVar.varIndex);
                  else if (($a.theInfo.theType == Type.INT) && ($b.theInfo.theType == Type.CONST_INT)) 
                     TextCode.add("\%t" + varCount + " = icmp sgt i32 \%t" + $a.theInfo.theVar.varIndex + ", " + $b.theInfo.theVar.iValue);
                  else if (($a.theInfo.theType == Type.CONST_INT) && ($b.theInfo.theType == Type.CONST_INT)) 
                     TextCode.add("\%t" + varCount + " = icmp sgt i32 " + $a.theInfo.theVar.iValue + ", " + $b.theInfo.theVar.iValue);
                  else if (($a.theInfo.theType == Type.CONST_INT) && ($b.theInfo.theType == Type.INT)) 
                     TextCode.add("\%t" + varCount + " = icmp sgt i32 " + $a.theInfo.theVar.iValue + ", \%t" + $b.theInfo.theVar.varIndex);
                  $rst = varCount;
                  varCount++;
               }
               |'>=' b = arith_expression{
                  if (($a.theInfo.theType == Type.INT) && ($b.theInfo.theType == Type.INT)) 
                     TextCode.add("\%t" + varCount + " = icmp sge i32 \%t" + $a.theInfo.theVar.varIndex + ", \%t" + $b.theInfo.theVar.varIndex);
                  else if (($a.theInfo.theType == Type.INT) && ($b.theInfo.theType == Type.CONST_INT)) 
                     TextCode.add("\%t" + varCount + " = icmp sge i32 \%t" + $a.theInfo.theVar.varIndex + ", " + $b.theInfo.theVar.iValue);
                  else if (($a.theInfo.theType == Type.CONST_INT) && ($b.theInfo.theType == Type.CONST_INT)) 
                     TextCode.add("\%t" + varCount + " = icmp sge i32 " + $a.theInfo.theVar.iValue + ", " + $b.theInfo.theVar.iValue);
                  else if (($a.theInfo.theType == Type.CONST_INT) && ($b.theInfo.theType == Type.INT)) 
                     TextCode.add("\%t" + varCount + " = icmp sge i32 " + $a.theInfo.theVar.iValue + ", \%t" + $b.theInfo.theVar.varIndex);
                  $rst = varCount;
                  varCount++;
               }
               |'<' b = arith_expression{
                  if (($a.theInfo.theType == Type.INT) && ($b.theInfo.theType == Type.INT)) 
                     TextCode.add("\%t" + varCount + " = icmp slt i32 \%t" + $a.theInfo.theVar.varIndex + ", \%t" + $b.theInfo.theVar.varIndex);
                  else if (($a.theInfo.theType == Type.INT) && ($b.theInfo.theType == Type.CONST_INT)) 
                     TextCode.add("\%t" + varCount + " = icmp slt i32 \%t" + $a.theInfo.theVar.varIndex + ", " + $b.theInfo.theVar.iValue);
                  else if (($a.theInfo.theType == Type.CONST_INT) && ($b.theInfo.theType == Type.CONST_INT)) 
                     TextCode.add("\%t" + varCount + " = icmp slt i32 " + $a.theInfo.theVar.iValue + ", " + $b.theInfo.theVar.iValue);
                  else if (($a.theInfo.theType == Type.CONST_INT) && ($b.theInfo.theType == Type.INT)) 
                     TextCode.add("\%t" + varCount + " = icmp slt i32 " + $a.theInfo.theVar.iValue + ", \%t" + $b.theInfo.theVar.varIndex);
                  $rst = varCount;
                  varCount++;
               }
               |'<=' b = arith_expression{
                  if (($a.theInfo.theType == Type.INT) && ($b.theInfo.theType == Type.INT)) 
                     TextCode.add("\%t" + varCount + " = icmp sle i32 \%t" + $a.theInfo.theVar.varIndex + ", \%t" + $b.theInfo.theVar.varIndex);
                  else if (($a.theInfo.theType == Type.INT) && ($b.theInfo.theType == Type.CONST_INT)) 
                     TextCode.add("\%t" + varCount + " = icmp sle i32 \%t" + $a.theInfo.theVar.varIndex + ", " + $b.theInfo.theVar.iValue);
                  else if (($a.theInfo.theType == Type.CONST_INT) && ($b.theInfo.theType == Type.CONST_INT)) 
                     TextCode.add("\%t" + varCount + " = icmp sle i32 " + $a.theInfo.theVar.iValue + ", " + $b.theInfo.theVar.iValue);
                  else if (($a.theInfo.theType == Type.CONST_INT) && ($b.theInfo.theType == Type.INT)) 
                     TextCode.add("\%t" + varCount + " = icmp sle i32 " + $a.theInfo.theVar.iValue + ", \%t" + $b.theInfo.theVar.varIndex);
                  $rst = varCount;
                  varCount++;
               }  
               )*;
			   
arith_expression
returns [Info theInfo]
@init {theInfo = new Info();}
                : a=multExpr { $theInfo=$a.theInfo; }
                 ( '+' b=multExpr
                    {
                       // We need to do type checking first.
                       // ...
   
                       // code generation.					   
                       if (($a.theInfo.theType == Type.INT) &&
                           ($b.theInfo.theType == Type.INT)) {
                           TextCode.add("\%t" + varCount + " = add nsw i32 \%t" + $theInfo.theVar.varIndex + ", \%t" + $b.theInfo.theVar.varIndex);
					   
					       // Update arith_expression's theInfo.
					       $theInfo.theType = Type.INT;
					       $theInfo.theVar.varIndex = varCount;
					       varCount ++;
                       } 
                       else if (($a.theInfo.theType == Type.INT) &&
					       ($b.theInfo.theType == Type.CONST_INT)) {
                           TextCode.add("\%t" + varCount + " = add nsw i32 \%t" + $theInfo.theVar.varIndex + ", " + $b.theInfo.theVar.iValue);
					   
					       // Update arith_expression's theInfo.
					       $theInfo.theType = Type.INT;
					       $theInfo.theVar.varIndex = varCount;
					       varCount ++;
                       }
                       else if (($a.theInfo.theType == Type.CONST_INT) &&
					       ($b.theInfo.theType == Type.CONST_INT)) {
                           TextCode.add("\%t" + varCount + " = add nsw i32 " + $theInfo.theVar.iValue + ", " + $b.theInfo.theVar.iValue);
					   
					       // Update arith_expression's theInfo.
					       $theInfo.theType = Type.INT;
					       $theInfo.theVar.varIndex = varCount;
					       varCount ++;
                       }
                       else if (($a.theInfo.theType == Type.CONST_INT) &&
					       ($b.theInfo.theType == Type.INT)) {
                           TextCode.add("\%t" + varCount + " = add nsw i32 " + $theInfo.theVar.iValue + ", \%t" + $b.theInfo.theVar.varIndex);
					   
					       // Update arith_expression's theInfo.
					       $theInfo.theType = Type.INT;
					       $theInfo.theVar.varIndex = varCount;
					       varCount ++;
                       }
                    }
                 | '-' b=multExpr
                     {
                       // We need to do type checking first.
                       // ...
					  
                       // code generation.					   
                       if (($a.theInfo.theType == Type.INT) &&
                           ($b.theInfo.theType == Type.INT)) {
                           TextCode.add("\%t" + varCount + " = sub nsw i32 \%t" + $theInfo.theVar.varIndex + ", \%t" + $b.theInfo.theVar.varIndex);
					   
					       // Update arith_expression's theInfo.
					       $theInfo.theType = Type.INT;
					       $theInfo.theVar.varIndex = varCount;
					       varCount ++;
                       } 
                       else if (($a.theInfo.theType == Type.INT) &&
					       ($b.theInfo.theType == Type.CONST_INT)) {
                           TextCode.add("\%t" + varCount + " = sub nsw i32 \%t" + $theInfo.theVar.varIndex + ", " + $b.theInfo.theVar.iValue);
					   
					       // Update arith_expression's theInfo.
					       $theInfo.theType = Type.INT;
					       $theInfo.theVar.varIndex = varCount;
					       varCount ++;
                       }
                       else if (($a.theInfo.theType == Type.CONST_INT) &&
					       ($b.theInfo.theType == Type.CONST_INT)) {
                           TextCode.add("\%t" + varCount + " = sub nsw i32 " + $theInfo.theVar.iValue + ", " + $b.theInfo.theVar.iValue);
					   
					       // Update arith_expression's theInfo.
					       $theInfo.theType = Type.INT;
					       $theInfo.theVar.varIndex = varCount;
					       varCount ++;
                       }
                       else if (($a.theInfo.theType == Type.CONST_INT) &&
					       ($b.theInfo.theType == Type.INT)) {
                           TextCode.add("\%t" + varCount + " = sub nsw i32 " + $theInfo.theVar.iValue + ", \%t" + $b.theInfo.theVar.varIndex);
					   
					       // Update arith_expression's theInfo.
					       $theInfo.theType = Type.INT;
					       $theInfo.theVar.varIndex = varCount;
					       varCount ++;
                       }
                    }
                 )*
                 ;

multExpr
returns [Info theInfo]
@init {theInfo = new Info();}
          : a=signExpr { $theInfo=$a.theInfo; }
          ( '*' b=signExpr
          {
                       // We need to do type checking first.
                       // ...
					  
                       // code generation.					   
                       if (($a.theInfo.theType == Type.INT) &&
                           ($b.theInfo.theType == Type.INT)) {
                           TextCode.add("\%t" + varCount + " = mul nsw i32 \%t" + $theInfo.theVar.varIndex + ", \%t" + $b.theInfo.theVar.varIndex);
					   
					       // Update arith_expression's theInfo.
					       $theInfo.theType = Type.INT;
					       $theInfo.theVar.varIndex = varCount;
					       varCount ++;
                       } 
                       else if (($a.theInfo.theType == Type.INT) &&
					       ($b.theInfo.theType == Type.CONST_INT)) {
                           TextCode.add("\%t" + varCount + " = mul nsw i32 \%t" + $theInfo.theVar.varIndex + ", " + $b.theInfo.theVar.iValue);
					   
					       // Update arith_expression's theInfo.
					       $theInfo.theType = Type.INT;
					       $theInfo.theVar.varIndex = varCount;
					       varCount ++;
                       }
                       else if (($a.theInfo.theType == Type.CONST_INT) &&
					       ($b.theInfo.theType == Type.CONST_INT)) {
                           TextCode.add("\%t" + varCount + " = mul nsw i32 " + $theInfo.theVar.iValue + ", " + $b.theInfo.theVar.iValue);
					   
					       // Update arith_expression's theInfo.
					       $theInfo.theType = Type.INT;
					       $theInfo.theVar.varIndex = varCount;
					       varCount ++;
                       }
                       else if (($a.theInfo.theType == Type.CONST_INT) &&
					       ($b.theInfo.theType == Type.INT)) {
                           TextCode.add("\%t" + varCount + " = mul nsw i32 " + $theInfo.theVar.iValue + ", \%t" + $b.theInfo.theVar.varIndex);
					   
					       // Update arith_expression's theInfo.
					       $theInfo.theType = Type.INT;
					       $theInfo.theVar.varIndex = varCount;
					       varCount ++;
                       }
                    }
          | '/' b=signExpr
          {
                       // We need to do type checking first.
                       // ...
					  
                       // code generation.					   
                       if (($a.theInfo.theType == Type.INT) &&
                           ($b.theInfo.theType == Type.INT)) {
                           TextCode.add("\%t" + varCount + " = sdiv i32 \%t" + $theInfo.theVar.varIndex + ", \%t" + $b.theInfo.theVar.varIndex);
					   
					       // Update arith_expression's theInfo.
					       $theInfo.theType = Type.INT;
					       $theInfo.theVar.varIndex = varCount;
					       varCount ++;
                       } 
                       else if (($a.theInfo.theType == Type.INT) &&
					       ($b.theInfo.theType == Type.CONST_INT)) {
                           TextCode.add("\%t" + varCount + " = sdiv i32 \%t" + $theInfo.theVar.varIndex + ", " + $b.theInfo.theVar.iValue);
					   
					       // Update arith_expression's theInfo.
					       $theInfo.theType = Type.INT;
					       $theInfo.theVar.varIndex = varCount;
					       varCount ++;
                       }
                       else if (($a.theInfo.theType == Type.CONST_INT) &&
					       ($b.theInfo.theType == Type.CONST_INT)) {
                           TextCode.add("\%t" + varCount + " = sdiv i32 " + $theInfo.theVar.iValue + ", " + $b.theInfo.theVar.iValue);
					   
					       // Update arith_expression's theInfo.
					       $theInfo.theType = Type.INT;
					       $theInfo.theVar.varIndex = varCount;
					       varCount ++;
                       }
                       else if (($a.theInfo.theType == Type.CONST_INT) &&
					       ($b.theInfo.theType == Type.INT)) {
                           TextCode.add("\%t" + varCount + " = sdiv i32 " + $theInfo.theVar.iValue + ", \%t" + $b.theInfo.theVar.varIndex);
					   
					       // Update arith_expression's theInfo.
					       $theInfo.theType = Type.INT;
					       $theInfo.theVar.varIndex = varCount;
					       varCount ++;
                       }
                    }
         | '%' b=signExpr
          {
                       // We need to do type checking first.
                       // ...
					  
                       // code generation.					   
                       if (($a.theInfo.theType == Type.INT) &&
                           ($b.theInfo.theType == Type.INT)) {
                           TextCode.add("\%t" + varCount + " = srem i32 \%t" + $theInfo.theVar.varIndex + ", \%t" + $b.theInfo.theVar.varIndex);
					   
					       // Update arith_expression's theInfo.
					       $theInfo.theType = Type.INT;
					       $theInfo.theVar.varIndex = varCount;
					       varCount ++;
                       } 
                       else if (($a.theInfo.theType == Type.INT) &&
					       ($b.theInfo.theType == Type.CONST_INT)) {
                           TextCode.add("\%t" + varCount + " = srem i32 \%t" + $theInfo.theVar.varIndex + ", " + $b.theInfo.theVar.iValue);
					   
					       // Update arith_expression's theInfo.
					       $theInfo.theType = Type.INT;
					       $theInfo.theVar.varIndex = varCount;
					       varCount ++;
                       }
                       else if (($a.theInfo.theType == Type.CONST_INT) &&
					       ($b.theInfo.theType == Type.CONST_INT)) {
                           TextCode.add("\%t" + varCount + " = srem i32 " + $theInfo.theVar.iValue + ", " + $b.theInfo.theVar.iValue);
					   
					       // Update arith_expression's theInfo.
					       $theInfo.theType = Type.INT;
					       $theInfo.theVar.varIndex = varCount;
					       varCount ++;
                       }
                       else if (($a.theInfo.theType == Type.CONST_INT) &&
					       ($b.theInfo.theType == Type.INT)) {
                           TextCode.add("\%t" + varCount + " = srem i32 " + $theInfo.theVar.iValue + ", \%t" + $b.theInfo.theVar.varIndex);
					   
					       // Update arith_expression's theInfo.
					       $theInfo.theType = Type.INT;
					       $theInfo.theVar.varIndex = varCount;
					       varCount ++;
                       }
                    }
	  )*
	  ;

signExpr
returns [Info theInfo]
@init {theInfo = new Info();}
        : a=primaryExpr { $theInfo=$a.theInfo; } 
        | '-' primaryExpr
	;
		  
primaryExpr
returns [Info theInfo]
@init {theInfo = new Info();}
           : Integer_constant
	     {
            $theInfo.theType = Type.CONST_INT;
			$theInfo.theVar.iValue = Integer.parseInt($Integer_constant.text);
         }
           | Floating_point_constant
           | Identifier
              {
                // get type information from symtab.
                Type the_type = symtab.get($Identifier.text).theType;
				$theInfo.theType = the_type;

                // get variable index from symtab.
                int vIndex = symtab.get($Identifier.text).theVar.varIndex;
				
                switch (the_type) {
                case INT: 
                         // get a new temporary variable and
						 // load the variable into the temporary variable.
                         
						 // Ex: \%tx = load i32, i32* \%ty.
						 TextCode.add("\%t" + varCount + "=load i32, i32* \%t" + vIndex);
				         
						 // Now, Identifier's value is at the temporary variable \%t[varCount].
						 // Therefore, update it.
						 $theInfo.theVar.varIndex = varCount;
						 varCount ++;
                         break;
                case FLOAT:
                         break;
                case CHAR:
                         break;
			
                }
              }
	   | '&' Identifier
	   | '(' a=arith_expression ')'{$theInfo=$a.theInfo;
}
           ;

		   
/* description of the tokens */
FLOAT:'float';
INT:'int';
CHAR: 'char';

MAIN: 'main';
VOID: 'void';
IF: 'if';
ELSE: 'else';
ELIF: ELSE IF ;
FOR: 'for';
WHILE: 'while';
DO: 'do';
PRINT: 'printf';


Identifier:('a'..'z'|'A'..'Z'|'_') ('a'..'z'|'A'..'Z'|'0'..'9'|'_')*;
Integer_constant:'0'..'9'+;
Floating_point_constant:'0'..'9'+ '.' '0'..'9'+;

STRING_LITERAL
    :  '"' ( EscapeSequence | ~('\\'|'"') )* '"'
    ;

WS:( ' ' | '\t' | '\r' | '\n' ) {$channel=HIDDEN;};
COMMENT:'/*' .* '*/' {$channel=HIDDEN;};


fragment
EscapeSequence
    :   '\\' ('b'|'t'|'n'|'f'|'r'|'\"'|'\''|'\\')
    ;
