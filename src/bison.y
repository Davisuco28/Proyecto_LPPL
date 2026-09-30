%{
#include "header.h"

extern int yylineno;
extern int yylex(void);
extern int verbosidad;

void yyerror(const char *msg) {
       fprint(stderr, "\nError sintactico en la linea %d: %s\n", yylineno, msg);
}
%}

%token INT_ BOOL_ TRUE_ FALSE_ IF_ ELSE_ FOR_ SWITCH_
%token LESS_ EQUAL_ GREATER_ READ_ PRINT_ RETURN_
%token AND_ OR_ IGUAL_ DIF_ MAYORIGUAL_ MENORIGUAL_ MAYOR_ MENOR_
%token ASIG_ MAS_ MENOS_ POR_ DIV_ NOT_
%token PARA_ PARC_ CORA_ CORC_ LLAVA_ LLAVC_ PYC_ COMA_
%token ID_ CTE_

%%

programa
       : listDecla
       ;
listDecla
       : listDecla
       | listDecla listDecla
       ;
decla
       : declaVar
       | declaFunc
       ;
declaVar
       : tipoSimp ID_ PYC_
       | tipoSimp ID_ ASIG_ const PYC_
       | tipoSimp ID_ CORA_ CTE_ CORC_ PYC_
       ;
const
       : CTE_
       | TRUE_
       | FALSE_
       ;
tipoSimp
       : INT_
       | BOOL_
       ;
declaFunc
       : tipoSimp ID_ PARA_ paraForm PARC_ bloque
       ;
paramForm
       : // lambda //
       | listParamForm
       ;
listParamForm
       : tipoSimp ID_
       | tipoSimp ID_ COMA_ listParamForm
       ;
bloque
       : LLAVA_ declaVarLocal listInt RETURN_ expre PYC_ LLAVC_
       ;
declaVarLocal
       : // lambda //
       | declaVarLocal declaVar
       ;
listInt
       : // lambda //
       | listInt inst
       ;
inst
       : LLAVA_ listInt LLAVC_
       | instExpre
       | instEntSal
       | instSelec
       | instIter
       | instSwitch
       ;
instSwitch
       : SWITCH_ ID_ LLAVA_ Less Equal Greater LLAVC_
       ;
Less
       : LESS_ inst
       ;
Equal
       : EQUAL_ inst
       ;
Greater
       : GREATER_ inst
       ;
instExpre
       : expre PYC_
       | PYC_
       ;
instEnSal
       : READ_ PARA_ ID_ PARC_ PYC_
       | PRINT_ PARA_ expre PARC_ PYC_
       ;
instSelec
       : IF_ PARA_ expre PARC_ inst ELSE_ inst
       ;
%%
