%{
#include <stdio.h>
#include "header.h"

extern int yylineno;
extern int yylex(void);
extern int verbosidad;


%}

%union {
    char *ident;
    int cent;
    struct {
        int t;      /* tipo de la expresión */
        int d;      /* desplazamiento/valor auxiliar */
    } expre;
    int tipo; 
}

%token INT_ BOOL_ TRUE_ FALSE_ IF_ ELSE_ FOR_ SWITCH_
%token LESS_ EQUAL_ GREATER_ READ_ PRINT_ RETURN_
%token AND_ OR_ IGUAL_ DIF_ MAYORIGUAL_ MENORIGUAL_ MAYOR_ MENOR_
%token ASIG_ MAS_ MENOS_ POR_ DIV_ NOT_
%token PARA_ PARC_ CORA_ CORC_ LLAVA_ LLAVC_ PYC_ COMA_

%token <ident> ID_
%token <cent> CTE_

%type <tipo> tipoSimp const
%type <expre> expre expreLogic expreIgual expreRel expreAd expreMul expreUna expreSufi expreOP
%type <cent> opLogic opIgual opRel opAd opMul opUna

%%

programa
        : 
        { niv = 0; dvar = 0; cargaContexto(niv); }
          listDecla
          { SIMB sim = obtTdS("main");
            if (sim.t == T_ERROR) yyerror("No existe la función main");
            if (verbosidad) mostrarTdS();
          }
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

        { if (!insTdS($2, VARIABLE, $1, niv, dvar, -1))
              yyerror("Identificador repetido");
          else dvar += TALLA_TIPO_SIMPLE;
        }


        | tipoSimp ID_ ASIG_ const PYC_

        { if ($4.t != T_ERROR && $4.t != $1)
              yyerror("Error de tipos en la inicialización de la variable");
          if (!insTdS($2, VARIABLE, $1, niv, dvar, -1))
              yyerror("Identificador repetido");
          else dvar += TALLA_TIPO_SIMPLE;
        }
        

        | tipoSimp ID_ CORA_ CTE_ CORC_ PYC_

        { int numelem = $4;
          if ($4 <= 0) {
              yyerror("Talla inapropiada del array");
              numelem = 0;
          }
          int refe = insTdA($1, numelem);
          if (!insTdS($2, VARIABLE, T_ARRAY, niv, dvar, refe))
              yyerror("Identificador repetido");
          else dvar += numelem * TALLA_TIPO_SIMPLE;
        }
        ;

const
        : CTE_   { $$.t = T_ENTERO; $$.d = $1; }
        | TRUE_  { $$.t = T_LOGICO; $$.d = 1; }
        | FALSE_ { $$.t = T_LOGICO; $$.d = 0; }
        ;

tipoSimp
        : INT_  { $$ = T_ENTERO; }
        | BOOL_ { $$ = T_LOGICO; }
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
        {
                $$.t = $1.t;
        }
        | ID_ ASIG_ expre
        {
                SIMB sim = obtTdS($1);
                if ($3.t == T_ERROR) {
                        $$.t = T_ERROR;
                }else if(sim.t == T_ERROR){
                        $$.t = T_ERROR;
                        yyerror("variable no declarada");
                }else if((sim.t != T_ENTERO && sim.t != T_LOGICO) || sim.t != $3.t){

                        $$.t = T_ERROR;
                        yyerror("Error de tipos");
                }else{
                        $$.t = sim.t;
                }
        }
        | ID_ CORA_ expre CORC_ ASIG_ expre
        {       SIMB sim = obtTdS($1);
                if ($6.t == T_ERROR || $3.t == T_ERROR) {
                        $$.t = T_ERROR;
                }else if(sim.t == T_ERROR){
                        $$.t = T_ERROR;
                        yyerror("Variable no declarada");
                }else if(sim.t != T_ARRAY){
                        $$.t = T_ERROR;
                        yyerror(" El tipo de la variable no es correcto ");
                }else if ($3.t != T_ENTERO){
                        $$.t = T_ERROR;
                        yyerror(" El rango del array debe ser un entero ");

                }else{
                        DIM dim = obtTdA(sim.ref);
                        if(dim.telem != $6.t){
                                $$.t = T_ERROR;
                                yyerror(" El tipo del Array y de la expresion no coinciden ");
                        }else{
                                $$.t = dim.telem;
                        }
                }
                


        }
        ;

expreLogic
        : expreIgual
        {
                $$.t = $1.t;
        }
        | expreLogic opLogic expreIgual
        {
                if ($1.t == T_ERROR || $3.t == T_ERROR) {
                        $$.t = T_ERROR;
                } else if (!($1.t == T_LOGICO && $3.t == T_LOGICO)) {
                        yyerror("Los operadores deben ser booleanos");
                        $$.t = T_ERROR;
                } else {
                        $$.t = T_LOGICO;
                }
        }
        ;

expreIgual
        : expreRel
        {
                $$.t = $1.t;
        }
        | expreIgual opIgual expreRel
        {
                if ($1.t == T_ERROR || $3.t == T_ERROR) {
                        $$.t = T_ERROR;
                } else if (!(($1.t == T_LOGICO && $3.t == T_LOGICO) ||($1.t == T_ENTERO && $3.t == T_ENTERO) )) {
                        yyerror("Los operadores deben ser ambos del mismo tipo y booleanos o enteros");
                        $$.t = T_ERROR;
                } else {
                        $$.t = T_LOGICO;
                }
        }
        ;

expreRel
        : expreAd
        {

                $$.t = $1.t;
        }
        | expreRel opRel expreAd
        {
                if($1.t == T_ERROR ||$3.t == T_ERROR ){
                        $$.t = T_ERROR;
                }
                else if(!($1.t == T_ENTERO && $3.t == T_ENTERO)){
                        yyerror("Los operadores deben ser Enteros");
                        $$.t = T_ERROR;
                        }else {
                                $$.t = T_LOGICO;
                        }
        }
        ;

expreAd
        : expreMul
        {
                $$.t = $1.t;
        }
        | expreAd opAd expreMul
        {
                if ($1.t == T_ERROR || $3.t == T_ERROR) {
                        $$.t = T_ERROR;
                } else if (!($1.t == T_ENTERO && $3.t == T_ENTERO)) {
                        yyerror("Los operadores deben ser enteros");
                        $$.t = T_ERROR;
                } else {
                        $$.t = T_ENTERO;
                }
        }
        ;

expreMul
        : expreUna
        {
                 $$.t = $1.t;
        }
        | expreMul opMul expreUna
        {
               if ($1.t == T_ERROR || $3.t == T_ERROR) {
                        $$.t = T_ERROR;
                } else if (!($1.t == T_ENTERO && $3.t == T_ENTERO)) {
                        yyerror("Los operadores deben ser enteros");
                        $$.t = T_ERROR;
                } else {
                        $$.t = T_ENTERO;
                } 
        }
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
