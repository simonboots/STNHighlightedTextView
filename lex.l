/* no default main() function */
%option nomain
/* interactive input to lex */
%option never-interactive
/* generate 8bit scanner */
%option 8bit
/* don't call yywrap() on eof */
%option noyywrap
/* use stack for start conditions */
%option stack

/* STATES */
%x QUOTE
%x UTF8

/* C stuff */
%{
#include "lextokens.h"
int remainingutf8bytes = 0;
int expectedutf8bytes = 0;
char utf8buffer[5];
%}

/* DEFINITIONS */
white		[ \t\n]+

digit		[0-9]
integer 	{digit}+
exponant	[eE][+-]?{integer}
text        [A-z]+

real		{integer}("."{integer})?{exponant}?

/* definitions for UTF-8 handling */
/* see "The Unicode Standard Version 5.0", page 103 */

/* -> 2 bytes */
utf8_2      [\xC0-\xDF]  
/* -> 3 bytes */
utf8_3      [\xE0-\xEF]
/* -> 4 bytes */
utf8_4      [\xF0-\xF7]
/* trailing bytes */
utf8_t      [\x80-\xBF]

%%
 /* RULES */

 /* utf8 handling rules */

<*>{utf8_2}         { yy_push_state(UTF8); utf8buffer[0] = *yytext; remainingutf8bytes = 1; expectedutf8bytes = 2; }
<*>{utf8_3}         { yy_push_state(UTF8); utf8buffer[0] = *yytext; remainingutf8bytes = 2; expectedutf8bytes = 3; }
<*>{utf8_4}         { yy_push_state(UTF8); utf8buffer[0] = *yytext; remainingutf8bytes = 3; expectedutf8bytes = 4; }
<UTF8>.             { if (appendUTF8() == 1) { yy_pop_state(); return UTF8CHAR; }}

 /* quoting */
\"                  { yy_push_state(QUOTE); return TEXT; }
<QUOTE>\"           { yy_pop_state(); return TEXT; }

 /* whitespaces */
<*>{white}          { return TEXT; }

 /* real number */
{real}              { return REAL; }
<QUOTE>{real}       { return QUOTEDREAL; }

 /* Text */
<*>{text}           { return TEXT; }

 /* everything else */
<*>.                { return TEXT; }


%%
/* SUBROUTINES */
/* helper function to handle UTF-8 bytes */
int appendUTF8()
{
    utf8buffer[expectedutf8bytes - (remainingutf8bytes--)] = *yytext;

    if (remainingutf8bytes == 0) {
        utf8buffer[expectedutf8bytes] = '\0';
        yytext = utf8buffer;
        return 1;
    }
    return 0;
}
    
/* reset start condition stack */
void yystatereset()
{
    int i = yy_start_stack_depth;
    for (; i > YY_START_STACK_INCR; i -= YY_START_STACK_INCR) {
        yy_pop_state();
    }
    yy_push_state(INITIAL);
}