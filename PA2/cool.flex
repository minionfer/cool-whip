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
int string_len;

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
%State STRING
%State STRING_TOO_LONG

%%


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
<INITIAL>--.*$ ;
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

<INITIAL>(?i:class)		{ return (CLASS); }
<INITIAL>(?i:else)		{ return (ELSE); }
<INITIAL>(?i:fi)		{ return (FI); }
<INITIAL>(?i:if)		{ return (IF); }
<INITIAL>(?i:in)		{ return (IN); }
<INITIAL>(?i:inherits)		{ return (INHERITS); }
<INITIAL>(?i:let)		{ return (LET); }
<INITIAL>(?i:loop)		{ return (LOOP); }
<INITIAL>(?i:pool)		{ return (POOL); }
<INITIAL>(?i:then)		{ return (THEN); }
<INITIAL>(?i:while)		{ return (WHILE); }
<INITIAL>(?i:case)		{ return (CASE); }
<INITIAL>(?i:esac)		{ return (ESAC); }
<INITIAL>(?i:new)		{ return (NEW); }
<INITIAL>(?i:isvoid)		{ return (ISVOID); }
<INITIAL>(?i:of)		{ return (OF); }
<INITIAL>(?i:not)		{ return (NOT); }

<INITIAL>{INTEGER}	{
	cool_yylval.symbol = inttable.add_string(yytext);
	return (INT_CONST);
}
<INITIAL>{TRUE} {
	cool_yylval.boolean = 1;
	return (BOOL_CONST);
}
<INITIAL>{FALSE} {
	cool_yylval.boolean = 0;
	return (BOOL_CONST);
}

	/*
	 * special symbols
	 */
	  /* function syntax */
<INITIAL>")" { return ')'; }
<INITIAL>"(" { return '('; }
<INITIAL>"," { return ','; }
		/* dispatch */
<INITIAL>\. { return '.'; }
		/* expression delimiting */
<INITIAL>"}" { return '}'; }
<INITIAL>"{" { return '{'; }
<INITIAL>"@" { return '@'; }
		/* separating expressions */
<INITIAL>";" { return ';'; }
		/* type specifications */
<INITIAL>":" { return ':'; }
		/* arithmetic */
<INITIAL>"+" { return '+'; }
<INITIAL>"-" { return '-'; }
<INITIAL>"*" { return '*'; }
<INITIAL>"/" { return '/'; }
<INITIAL>"~" { return '~'; }
		/* less than */
<INITIAL>"<" { return '<'; }
		/* boolean operators */
<INITIAL>"=" { return '='; }
<INITIAL>"<-" { return (ASSIGN); }
<INITIAL>"<=" { return (LE); }

 /*
  *  String constants (C syntax)
  *  Escape sequence \c is accepted for all characters c. Except for 
  *  \n \t \b \f, the result is c.
  *
  */
<INITIAL>\" {
	BEGIN(STRING);
	string_buf_ptr = string_buf;
	string_len = 0;
}
<STRING>[^\\\"\n\0]* {
	//printf("str '%s'\n", yytext);
	int len = strlen(yytext);
	if (len + string_len >= MAX_STR_CONST) {
		BEGIN(STRING_TOO_LONG);
		cool_yylval.error_msg = "String constant too long";
		return (ERROR);
	}
	strcpy(string_buf_ptr, yytext);
	string_buf_ptr += len;
	string_len += len;
}
<STRING>\0 {
	cool_yylval.error_msg = "NULL character in string constant";
	return (ERROR);
}
<STRING>\n {
	cool_yylval.error_msg = "Unterminated string constant";
	BEGIN(INITIAL);
	return (ERROR);
}
<STRING>\\. {
	//printf("escaped %c (code: %d)\n", yytext[1], (int) yytext[1]);
	switch(yytext[1]) {
		case 'n':
			//printf("inserting newline\n");
			*string_buf_ptr = '\n';
			break;
		case 't':
			//printf("inserting tab\n");
			*string_buf_ptr = '\t';
			break;
		case 'b':
			*string_buf_ptr = '\b';
			break;
		case 'f':
			*string_buf_ptr = '\f';
			break;
		default:
			*string_buf_ptr = yytext[1];
	}

	string_buf_ptr++;
	string_len++;
}
<STRING>\" {
	BEGIN(INITIAL);
	*string_buf_ptr = '\0';
	cool_yylval.symbol = inttable.add_string(string_buf);
	return (STR_CONST);
}
<STRING_TOO_LONG>[^\\"\n] ;
	/* ignore normal escaped characters */
<STRING_TOO_LONG>\\[^\n] ;
	/* continue looking for end of string on seeing an escaped newline */
<STRING_TOO_LONG>\\\n { curr_lineno++; }
	/* terminate string on unescaped newline */
<STRING_TOO_LONG>\n { curr_lineno++; BEGIN(INITIAL); }
	/* also terminate on end of string quote */
<STRING_TOO_LONG>\" { BEGIN(INITIAL); }
<STRING_TOO_LONG,STRING><<EOF>> {
	cool_yylval.error_msg = "EOF in string constant";
	BEGIN(INITIAL);
	return (ERROR);
}


[A-Z]{ID_CHAR}* {
	cool_yylval.symbol = inttable.add_string(yytext);
	return (TYPEID);
}
[a-z]{ID_CHAR}* {
	cool_yylval.symbol = inttable.add_string(yytext);
	return (OBJECTID);
}

\n { curr_lineno++; }
{WS} ;

. {
	cool_yylval.error_msg = strdup(yytext);
	return (ERROR);
}

%%
