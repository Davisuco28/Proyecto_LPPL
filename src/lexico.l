/*****************************************************************************/
/**  Ejemplo de FLEX: S E M - 1           2023-2024 <jmbenedi@prhlt.upv.es> **/
/*****************************************************************************/
%{
#include <stdio.h>
#include <string.h>
#include "header.h"

#define  retornar(x) {if (verbosidad) ECHO; }
%}
/*-----------------------------------------------------------------------------
  Estas opciones evitan "warnings" innecesarios y permiten obtener el
  numero de linea actual en la variable global "yylineno".
-----------------------------------------------------------------------------*/
%option noinput       
%option nounput       
%option yylineno  

delimitador    [ \t\n]+
digito         [0-9]
entero         {digito}+ 
char           [a-zA-Z_]
identificador  {char}({char}|{digito}[-])*
real         ({entero}([\,]|[\.]))|(([\,]|[\.]){entero})|({entero}([\,]|[\.]){entero})
comentario     "//".*

%%
{delimitador}  { if (verbosidad) ECHO; }
{comentario}   { if (verbosidad) ECHO; }

/*simbolso dobles*/

"=="           { retornar (IGUAL_); }
"!="           { retornar (DIF_); }
">="           { retornar (MAYORIGUAL_); }
"<="           { retornar (MENORIGUAL_); }
"&&"           { retornar (AND_); }
"||"           { retornar (OR_); }

/* simbolos de un simbolo*/

"+"	       	   { retornar (MAS_);      }
"="	       	   { retornar (ASIG_);     }
"-"            { retornar (MENOS_);    }
"*"            { retornar (POR_);      }
"/"            { retornar (DIV_);      }
"("            { retornar (PARA_);     }
")"            { retornar (PARC_);     }
"["	       	   { retornar (CORA_);     }
"]"	       	   { retornar (CORC_);     }
"{"	       	   { retornar (LLAVA_);    }
"}"	       	   { retornar (LLAVC_);    }
";"	       	   { retornar (PYC_);      }
","	       	   { retornar (COMA_);     }
{entero}       { retornar (CTE_);      }
"<"	       	   { retornar (MAYOR_);    }
">"	       	   { retornar (MENOR_);    }
"!"	       	   { retornar (NOT_);      }

/* palabras reservadas */

"int"          { retornar (INT_);      }
"bool"         { retornar (BOOL_);     }
"true"         { retornar (TRUE_);     }
"false"        { retornar (FALSE_);    }
"if"           { retornar (IF_);       }
"else"         { retornar (ELSE_);     }
"for"          { retornar (FOR_);      }
"return"       { retornar (RETURN_);   }
"read"         { retornar (READ_);     }
"print"        { retornar (PRINT_);    }
"SWITCH"       { retornar (SWITCH_);   }
"LESS"         { retornar (LESS_);     }
"EQUAL"        { retornar (EQUAL_);    }
"GREATER"      { retornar (GREATER_);  }
/* Macros */
{identificador} { retornar (ID_); }
{real}          { retornar (CTE_); } 
{entero}        { retornar (CTE_); }

.	       { yyerror("Caracter desconocido"); }

%%
/*****************************************************************************/
