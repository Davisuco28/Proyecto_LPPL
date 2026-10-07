%{
#include <stdio.h>
#include "header.h"

extern int yylineno;
extern int yylex(void);
extern int verbosidad;


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
        : decla
        | listDecla decla
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
        : tipoSimp ID_ PARA_ paramForm PARC_ bloque
        ;

paramForm
        : /* lambda */
        | listParamForm
        ;

listParamForm
        : tipoSimp ID_
        | tipoSimp ID_ COMA_ listParamForm
        ;

bloque
        : LLAVA_ declaVarLocal listInst RETURN_ expre PYC_ LLAVC_
        ;

declaVarLocal
        : /* lambda */
        | declaVarLocal declaVar
        ;

listInst
        : /* lambda */
        | listInst inst
        ;

inst
        : LLAVA_ listInst LLAVC_
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

instEntSal
        : READ_ PARA_ ID_ PARC_ PYC_
        | PRINT_ PARA_ expre PARC_ PYC_
        ;

instSelec
        : IF_ PARA_ expre PARC_ inst ELSE_ inst
        ;

instIter
        : FOR_ PARA_ expreOP PYC_ expre PYC_ expreOP PARC_ inst
        ;

expreOP
        : /* lambda */
        | expre
        ;

expre
        : expreLogic
        | ID_ ASIG_ expre
        | ID_ CORA_ expre CORC_ ASIG_ expre
        ;

expreLogic
        : expreIgual
        | expreLogic opLogic expreIgual
        ;

expreIgual
        : expreRel
        | expreIgual opIgual expreRel
        ;

expreRel
        : expreAd
        | expreRel opRel expreAd
        ;

expreAd
        : expreMul
        | expreAd opAd expreMul
        ;

expreMul
        : expreUna
        | expreMul opMul expreUna
        ;

expreUna
        : expreSufi
        | opUna expreUna
        ;

expreSufi
        : const
        | PARA_ expre PARC_
        | ID_
        | ID_ CORA_ expre CORC_
        | ID_ PARA_ paramAct PARC_
        ;

paramAct
        : /* lambda */
        | listParamAct
        ;

listParamAct
        : expre
        | expre COMA_ listParamAct
        ;

opLogic
        : AND_
        | OR_
        ;

opIgual
        : IGUAL_
        | DIF_
        ;

opRel
        : MAYOR_
        | MENOR_
        | MAYORIGUAL_
        | MENORIGUAL_
        ;

opAd
        : MAS_
        | MENOS_
        ;

opMul
        : POR_
        | DIV_
        ;

opUna
        : MAS_
        | MENOS_
        | NOT_
        ;

%%
