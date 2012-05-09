/*
 *  The scanner definition for COOL.
 */

/*
 *  Stuff enclosed in %{ %} in the first section is copied verbatim to the
 *  output, so headers and global definitions are placed here to be visible
 * to the code in the file.  Don't remove anything that was here initially
 */
%{
#include <cool-parse.h>
#include <stringtab.h>
#include <utilities.h>

/* The compiler assumes these identifiers. */
#define yylval cool_yylval
#define yylex  cool_yylex

/* Max size of string constants */
#define MAX_STR_CONST 1025
#define YY_NO_UNPUT   /* keep g++ happy */

extern FILE *fin; /* we read from this file */

/* define YY_INPUT so we read from the FILE fin:
 * This change makes it possible to use this scanner in
 * the Cool compiler.
 */
#undef YY_INPUT
#define YY_INPUT(buf,result,max_size) \
	if ( (result = fread( (char*)buf, sizeof(char), max_size, fin)) < 0) \
		YY_FATAL_ERROR( "read() in flex scanner failed");

char string_buf[MAX_STR_CONST]; /* to assemble string constants */
char *string_buf_ptr;

extern int curr_lineno;
extern int verbose_flag;

extern YYSTYPE cool_yylval;

/*
 *  Add Your own definitions here
 */

%}

/*
 * Define names for regular expressions here.
 */

DARROW          =>
INTEGER					[0-9]+
TRUE						t(?i:rue)
FALSE						f(?i:alse)
WS							[ \t\f\v\r]+
ID_CHAR					[a-zA-Z0-9_]

%State COMMENT

%%

\n { curr_lineno++; }
{WS} ;

 /*
  *  Nested comments
  */
<INITIAL>"(*" { BEGIN(COMMENT); }
<INITIAL>"*)" {
	cool_yylval.error_msg = "Unexpected *)";
	return (ERROR);
}
	/*
	 * single-line cmment
	 */
<INITIAL>^--.*$ ;
<COMMENT>[^*\n]* ;
<COMMENT>"*" ;
<COMMENT>"*)" { BEGIN(INITIAL); }
<COMMENT><<EOF>> {
	cool_yylval.error_msg = "EOF in comment";
	BEGIN(INITIAL);
	return (ERROR);
}

 /*
  *  The multiple-character operators.
  */
{DARROW}		{ return (DARROW); }

 /*
  * Keywords are case-insensitive except for the values true and false,
  * which must begin with a lower-case letter.
  */

(?i:class)		{ return (CLASS); }
(?i:else)		{ return (ELSE); }
(?i:fi)		{ return (FI); }
(?i:if)		{ return (IF); }
(?i:in)		{ return (IN); }
(?i:inherits)		{ return (INHERITS); }
(?i:let)		{ return (LET); }
(?i:loop)		{ return (LOOP); }
(?i:pool)		{ return (POOL); }
(?i:then)		{ return (THEN); }
(?i:while)		{ return (WHILE); }
(?i:case)		{ return (CASE); }
(?i:esac)		{ return (ESAC); }
(?i:new)		{ return (NEW); }
(?i:isvoid)		{ return (ISVOID); }
(?i:of)		{ return (OF); }
(?i:not)		{ return (NOT); }

[A-Z]{ID_CHAR}* {
	cool_yylval.symbol = inttable.add_string(yytext);
	return (TYPEID);
}
[a-z]{ID_CHAR}* {
	cool_yylval.symbol = inttable.add_string(yytext);
	return (OBJECTID);
}
{INTEGER}	{
	cool_yylval.symbol = inttable.add_string(yytext);
	return (INT_CONST);
}
{TRUE}	{
	cool_yylval.boolean = 1;
	return (BOOL_CONST);
}
{FALSE} {
	cool_yylval.boolean = 0;
	return (BOOL_CONST);
}

	/*
	 * special symbols
	 */
")" { return ')'; }
"(" { return '('; }
"}" { return '}'; }
"{" { return '{'; }
"]" { return ']'; }
"[" { return '['; }
"@" { return '@'; }
"." { return '.'; }
";" { return ';'; }
":" { return ':'; }
"+" { return '+'; }
"-" { return '-'; }
"*" { return '*'; }
"/" { return '/'; }
"<" { return '<'; }
"=" { return '='; }
"<-" { return (ASSIGN); }
"<=" { return (LE); }

 /*
  *  String constants (C syntax)
  *  Escape sequence \c is accepted for all characters c. Except for 
  *  \n \t \b \f, the result is c.
  *
  */


%%
