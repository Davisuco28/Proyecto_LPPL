%{
#include <stdio.h>
#include <string.h>
#include "header.h"
#include "libtds.h"

extern int yylineno;
extern int yylex(void);
extern int verbosidad;
extern int verTdS;

int nMain = 0;
%}

%union {
    char *ident;
    int cent;
    struct {
        int t;      /* tipo de la expresion */
        int d;      /* desplazamiento/valor auxiliar */
    } expre;
    int tipo;
    struct { int ref; int talla; int err; } par;
}

%token INT_ BOOL_ TRUE_ FALSE_ IF_ ELSE_ FOR_ SWITCH_
%token LESS_ EQUAL_ GREATER_ READ_ PRINT_ RETURN_
%token AND_ OR_ IGUAL_ DIF_ MAYORIGUAL_ MENORIGUAL_ MAYOR_ MENOR_
%token ASIG_ MAS_ MENOS_ POR_ DIV_ NOT_
%token PARA_ PARC_ CORA_ CORC_ LLAVA_ LLAVC_ PYC_ COMA_

%token <ident> ID_
%token <cent> CTE_

%type <tipo> tipoSimp
%type <expre> const expre expreLogic expreIgual expreRel expreAd expreMul expreUna expreSufi expreOP
%type <cent> opUna
%type <par> paramForm listParamForm paramAct listParamAct

%%

programa
        : { niv = 0; dvar = 0; cargaContexto(niv); }
          listDecla
          { if (nMain == 0) yyerror("No existe la funcion main");
            else if (nMain > 1) yyerror("El programa tiene mas de un main");
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
                yyerror("Error de tipos en la inicializacion de la variable");
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
        : tipoSimp ID_
          { niv++; cargaContexto(niv);
            $<cent>$ = dvar;               /* guarda el dvar global */
            dvar = 0;
          }
          PARA_ paramForm PARC_
          { if (!insTdS($2, FUNCION, $1, niv-1, -1, $5.ref))
                yyerror("Identificador de funcion repetido");
            if (strcmp($2, "main") == 0) nMain++;
          }
          bloque
          { if (verTdS) mostrarTdS();
            descargaContexto(niv); niv--;
            dvar = $<cent>3;               /* restaura el dvar global */
          }
        ;

paramForm
        : /* lambda */
          { $$.ref = insTdD(-1, T_VACIO); $$.talla = 0; $$.err = 0; }
        | listParamForm
          { $$ = $1; }
        ;

listParamForm
        : tipoSimp ID_
          { $$.ref = insTdD(-1, $1);
            $$.talla = TALLA_TIPO_SIMPLE; $$.err = 0;
            if (!insTdS($2, PARAMETRO, $1, niv,
                        -TALLA_SEGENLACES - $$.talla, -1))
                yyerror("Identificador de parametro repetido");
          }
        | tipoSimp ID_ COMA_ listParamForm
          { $$.ref = insTdD($4.ref, $1);
            $$.talla = $4.talla + TALLA_TIPO_SIMPLE; $$.err = 0;
            if (!insTdS($2, PARAMETRO, $1, niv,
                        -TALLA_SEGENLACES - $$.talla, -1))
                yyerror("Identificador de parametro repetido");
          }
        ;

/* obtTdD(-1) devuelve la informacion de la funcion que se esta compilando;
   si su declaracion fallo (p.ej. identificador repetido) tipo == T_ERROR   */
bloque
        : LLAVA_ declaVarLocal listInst RETURN_ expre PYC_ LLAVC_
          { INF inf = obtTdD(-1);
            if (inf.tipo == T_ERROR)
                yyerror("Error en la declaracion de la funcion");
            else if ($5.t != T_ERROR && inf.tipo != $5.t)
                yyerror("Error de tipos en el 'return'");
          }
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
          { SIMB sim = obtTdS($2);
            if (sim.t == T_ERROR)
                yyerror("Objeto no declarado");
            else if (sim.t != T_ENTERO || sim.ref >= 0)
                yyerror("El selector del SWITCH debe ser una variable de tipo entero");
          }
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
          { SIMB sim = obtTdS($3);
            if (sim.t == T_ERROR)
                yyerror("Objeto no declarado");
            else if (sim.t != T_ENTERO || sim.ref >= 0)
                yyerror("La instruccion read requiere una variable de tipo entero");
          }
        | PRINT_ PARA_ expre PARC_ PYC_
          { if ($3.t != T_ERROR && $3.t != T_ENTERO)
                yyerror("La instruccion print requiere una expresion de tipo entero");
          }
        ;

instSelec
        : IF_ PARA_ expre PARC_ inst ELSE_ inst
          { if ($3.t != T_ERROR && $3.t != T_LOGICO)
                yyerror("La condicion del if debe ser de tipo logico (bool)");
          }
        ;

instIter
        : FOR_ PARA_ expreOP PYC_ expre PYC_ expreOP PARC_ inst
          { if ($5.t != T_ERROR && $5.t != T_LOGICO)
                yyerror("La condicion de control del for debe ser de tipo logico (bool)");
          }
        ;

expreOP
        : /* lambda */ { $$.t = T_VACIO; $$.d = 0; }
        | expre        { $$ = $1; }
        ;

expre
        : expreLogic
          { $$ = $1; }
        | ID_ ASIG_ expre
          { SIMB sim = obtTdS($1);
            $$.t = T_ERROR; $$.d = 0;
            if (sim.t == T_ERROR)
                yyerror("Objeto no declarado");
            else if (sim.t == T_ARRAY)
                yyerror("No se puede asignar a un array sin indice");
            else if (sim.ref >= 0)
                yyerror("Una funcion no puede usarse como variable");
            else if ($3.t != T_ERROR) {
                if (sim.t != $3.t)
                    yyerror("Error de tipos en la asignacion");
                else $$.t = sim.t;
            }
          }
        | ID_ CORA_ expre CORC_ ASIG_ expre
          { SIMB sim = obtTdS($1);
            $$.t = T_ERROR; $$.d = 0;
            if (sim.t == T_ERROR)
                yyerror("Objeto no declarado");
            else if (sim.t != T_ARRAY)
                yyerror("La variable debe ser de tipo array");
            else {
                DIM dim = obtTdA(sim.ref);
                int ok = 1;
                if ($3.t != T_ERROR && $3.t != T_ENTERO) {
                    yyerror("El indice del array debe ser entero");
                    ok = 0;
                }
                if ($6.t != T_ERROR && $6.t != dim.telem) {
                    yyerror("El tipo de la expresion no coincide con el del array");
                    ok = 0;
                }
                if (ok && $3.t != T_ERROR && $6.t != T_ERROR)
                    $$.t = dim.telem;
            }
          }
        ;

expreLogic
        : expreIgual
          { $$ = $1; }
        | expreLogic opLogic expreIgual
          { $$.t = T_ERROR; $$.d = 0;
            if ($1.t != T_ERROR && $3.t != T_ERROR) {
                if ($1.t == T_LOGICO && $3.t == T_LOGICO)
                    $$.t = T_LOGICO;
                else
                    yyerror("Los operandos de && y || deben ser logicos");
            }
          }
        ;

expreIgual
        : expreRel
          { $$ = $1; }
        | expreIgual opIgual expreRel
          { $$.t = T_ERROR; $$.d = 0;
            if ($1.t != T_ERROR && $3.t != T_ERROR) {
                if ($1.t == $3.t && ($1.t == T_ENTERO || $1.t == T_LOGICO))
                    $$.t = T_LOGICO;
                else
                    yyerror("Los operandos de == y != deben ser del mismo tipo (entero o logico)");
            }
          }
        ;

expreRel
        : expreAd
          { $$ = $1; }
        | expreRel opRel expreAd
          { $$.t = T_ERROR; $$.d = 0;
            if ($1.t != T_ERROR && $3.t != T_ERROR) {
                if ($1.t == T_ENTERO && $3.t == T_ENTERO)
                    $$.t = T_LOGICO;
                else
                    yyerror("Los operandos de la comparacion deben ser enteros");
            }
          }
        ;

expreAd
        : expreMul
          { $$ = $1; }
        | expreAd opAd expreMul
          { $$.t = T_ERROR; $$.d = 0;
            if ($1.t != T_ERROR && $3.t != T_ERROR) {
                if ($1.t == T_ENTERO && $3.t == T_ENTERO)
                    $$.t = T_ENTERO;
                else
                    yyerror("Los operandos de + y - deben ser enteros");
            }
          }
        ;

expreMul
        : expreUna
          { $$ = $1; }
        | expreMul opMul expreUna
          { $$.t = T_ERROR; $$.d = 0;
            if ($1.t != T_ERROR && $3.t != T_ERROR) {
                if ($1.t == T_ENTERO && $3.t == T_ENTERO)
                    $$.t = T_ENTERO;
                else
                    yyerror("Los operandos de * y / deben ser enteros");
            }
          }
        ;

expreUna
        : expreSufi
          { $$ = $1; }
        | opUna expreUna
          { $$.t = T_ERROR; $$.d = 0;
            if ($2.t != T_ERROR) {
                if ($1 == 3) {                      /* NOT */
                    if ($2.t == T_LOGICO) $$.t = T_LOGICO;
                    else yyerror("El operador ! requiere un operando logico");
                } else {                            /* + y - unarios */
                    if ($2.t == T_ENTERO) $$.t = T_ENTERO;
                    else yyerror("Los operadores unarios + y - requieren un operando entero");
                }
            }
          }
        ;

expreSufi
        : const
          { $$ = $1; }
        | PARA_ expre PARC_
          { $$ = $2; }
        | ID_
          { SIMB sim = obtTdS($1);
            $$.t = T_ERROR; $$.d = 0;
            if (sim.t == T_ERROR)
                yyerror("Objeto no declarado");
            else if (sim.t == T_ARRAY)
                yyerror("Un array debe usarse con indice");
            else if (sim.ref >= 0)
                yyerror("Una funcion no puede usarse como variable");
            else $$.t = sim.t;
          }
        | ID_ CORA_ expre CORC_
          { SIMB sim = obtTdS($1);
            $$.t = T_ERROR; $$.d = 0;
            if (sim.t == T_ERROR)
                yyerror("Objeto no declarado");
            else if (sim.t != T_ARRAY)
                yyerror("La variable debe ser de tipo array");
            else {
                if ($3.t != T_ERROR && $3.t != T_ENTERO)
                    yyerror("El indice del array debe ser entero");
                $$.t = obtTdA(sim.ref).telem;
            }
          }
        | ID_ PARA_ paramAct PARC_
          { SIMB sim = obtTdS($1);
            $$.t = T_ERROR; $$.d = 0;
            if (sim.t == T_ERROR)
                yyerror("Objeto no declarado");
            else if (sim.t == T_ARRAY || sim.ref < 0)
                yyerror("El identificador no es una funcion");
            else if (!$3.err) {
                if (!cmpDom(sim.ref, $3.ref))
                    yyerror("En el dominio de los parametros actuales");
                else $$.t = obtTdD(sim.ref).tipo;   /* tipo del rango de la funcion */
            }
          }
        ;

paramAct
        : /* lambda */
          { $$.ref = insTdD(-1, T_VACIO); $$.talla = 0; $$.err = 0; }
        | listParamAct
          { $$ = $1; }
        ;

listParamAct
        : expre
          { $$.ref = insTdD(-1, $1.t);
            $$.talla = TALLA_TIPO_SIMPLE;
            $$.err = ($1.t == T_ERROR);
          }
        | expre COMA_ listParamAct
          { $$.ref = insTdD($3.ref, $1.t);
            $$.talla = $3.talla + TALLA_TIPO_SIMPLE;
            $$.err = ($1.t == T_ERROR) || $3.err;
          }
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
        : MAS_      { $$ = 1; }
        | MENOS_    { $$ = 2; }
        | NOT_      { $$ = 3; }
        ;

%%
