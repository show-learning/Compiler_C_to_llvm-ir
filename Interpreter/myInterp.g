grammar myInterp;

options {
   language = Java;
}
@header {
import java.util.HashMap;
import java.util.Scanner;
import java.util.LinkedList;
import java.util.Queue;
}

@members {
    boolean TRACEON = true;
/** Map variable name to Integer object holding value */
    HashMap memory = new HashMap();
    Queue<Integer> q = new LinkedList<>();
    Scanner sc= new Scanner(System.in); 
}

program:
    VOID MAIN '(' ')' '{' declarations statements[1] '}'
    | calc_statements[1];

declarations:
    type Identifier complex_declarations ';' declarations{
            memory.put($Identifier.text, new Integer(0)); 
    }
    |;

complex_declarations:
    ',' Identifier complex_declarations{
        memory.put($Identifier.text, new Integer(0));
    }
    |;

type:
    INT;

statements[int enable]:
    statement[$enable] statements[1] |;


arith_expression returns [int value]: 
    a = calc_multExpr{$value = $a.value;}(
        '==' b = calc_multExpr{
            if($value == b) $value = 1;
            else $value = 0;
        }
        | '>=' b = calc_multExpr{
            if($value >= b) $value = 1;
            else $value = 0;
        }
        | '<=' b = calc_multExpr{
            if($value <= b) $value = 1;
            else $value = 0;
        }
        | '!=' b = calc_multExpr{
            if($value != b) $value = 1;
            else $value = 0;
        }
        | '>' b = calc_multExpr{
            if($value > b) $value = 1;
            else $value = 0;
        }
        | '<' b = calc_multExpr{
            if($value < b) $value = 1;
            else $value = 0;
        }
	)*;


statement[int enable]: 
    calc_statement[$enable]
    | if_statements[$enable]
	| PRINT print_stament[$enable] 
    | SCAN scan_stament[$enable]
    ;

if_statements[int enable]: 
    r=if_then_statement[$enable]{
        if($r.isrun == 1){
            $enable = 0;
        }
    } if_else_statement[$enable];

if_then_statement[int enable] returns [int isrun]:
    IF '(' cond=arith_expression {
        if($cond.value == 0){
            $enable = $cond.value;
            
        }
        $isrun = $cond.value;
    } ')' '{' statements[$enable] '}'
;

if_else_statement[int enable]:
    ELSE '{' statements[$enable] '}'
    |;

print_stament[int enable]:
    '(' A=LITERAL (',' e=print_int{
        q.add($e.value);
        })*
    ')'  ';'{ 
        if($enable==1){
            String s=$A.text;
            for(int i=1;i<s.length()-1;i++){
                String temp = new String("");
    	    	if(s.charAt(i) =='\%' &&s.charAt(i+1) =='d'){
                    System.out.print(q.poll());
                    i++;
                }
                else if(s.charAt(i) =='\\' &&s.charAt(i+1) =='n'){
                    System.out.println("");
                    i++;
                }else{
                    System.out.print(s.charAt(i));
                }	
            }
        }
    } 
    ;

print_int returns [int value]:
    e=calc_expr{ 
        $value = $e.value;
        }
    |;


scan_stament[int enable]:
    '(' LITERAL scan_int[$enable] ')' ';' ;

scan_int[int enable] returns [int value]:
    ',' '&'Identifier scan_int[$enable]{ 
        if(enable == 1){
            $value = sc.nextInt();
            memory.put($Identifier.text, new Integer($value)); 
        }
    }
    |;


/* calculator */
calc_statements[int enable]:
	calc_statement[$enable] calc_statements[$enable]
	|;

calc_statement[int enable]:  
    calc_expr ';'
    |Identifier '=' calc_expr ';' {
        if(enable == 1)
            memory.put($Identifier.text, new Integer($calc_expr.value)); 
     }
    | ';';

calc_expr returns [int value]:
    e=calc_multExpr {$value = $e.value;}
    ( '+' e=calc_multExpr {$value += $e.value;}
    | '-' e=calc_multExpr {$value -= $e.value;}
    )*;

calc_multExpr returns [int value]:   
    e=atom {$value = $e.value;} 
    ( '*' e=atom {$value *= $e.value;}
    | '/' e=atom {$value /= $e.value;}    
    )*; 

atom returns [int value]:
    Integer_constant {$value = Integer.parseInt($Integer_constant.text);}
    | Identifier{
        Integer v = (Integer)memory.get($Identifier.text);
        if ( v!=null ) $value = v.intValue();
        else System.err.println("undefined variable "+$Identifier.text);
    }
    | '(' calc_expr ')' {$value = $calc_expr.value;};


/* description of the tokens */
INT:'int';
MAIN: 'main';
VOID: 'void';
IF: 'if';
ELSE: 'else';
ELIF: ELSE IF ;

PRINT: 'printf';
SCAN: 'scanf';

Identifier:('a'..'z'|'A'..'Z'|'_') ('a'..'z'|'A'..'Z'|'0'..'9'|'_')*;
Integer_constant:'0'..'9'+;
LITERAL : '"' (.)* '"';

WS:( ' ' | '\t' | '\r' | '\n' ) {$channel=HIDDEN;};
COMMENT:'/*' .* '*/' {$channel=HIDDEN;};