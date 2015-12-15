/*
 * # Chi parser
 * 
 * ## To do:
 * - Boolean lists.
 * - Structs. (Enums?)
 * - Function pointer types.
 * - Generics.
 * - Move values → leaves.
 * - Add type to leaves.
 * - Move inline functions → values.
 * - Types, param numbers… (parse function headers…)
 * - Need AST for inferences.
*/

%{
	#include <stdio.h>
	#include <stdlib.h>
	#include <string.h>
	
	int yylex(void);
	void yyerror(const char*);
	
	#define format malloc(1024); sprintf
	
	const char* translateOp(const char* op) {
		if(strcmp(op, "≠") == 0) { return "!="; }
		if(strcmp(op, "≥") == 0) { return ">="; }
		if(strcmp(op, "≤") == 0) { return "<="; }
		return op;
	}
	char* combine(char* a, char* b, char* d) {
		int x = strlen(a), y = strlen(b), z = strlen(d);
		if(x == 0) { return b; }
		if(y == 0) { return a; }
		char* temp = malloc(x+y+z+1);
		sprintf(temp, "%s%s%s", a, d, b);
		return temp;
	}
	
	static int counter = 1;
	
	struct fn {
		int stackID;
		char* name;
		char* objectType;
		char* returnType;
		int params;
		char** paramTypes;
	};
	struct fnList {
		struct fn* list;
		int length;
	};
	struct fnList fnStack = {0};
	
	void pushFn(struct fn fn) {
		fnStack.list[fnStack.length] = fn;
		fnStack.length += 1;
	}
	struct fn popFn() {
		fnStack.length -= 1;
		return fnStack.list[fnStack.length];
	}
	struct fn* currentFn() {
		if(fnStack.length == 0) return NULL;
		return fnStack.list + fnStack.length - 1;
	}
%}

%code requires {
	struct var {
		char* type;
		char* name;
		char* defaultValue;
		char* failValue;
		char* initialiser;
	};
	struct leaves {
		char* preScope;
		char* preBlock;
		char* blockHead;
		char* blockTail;
		char* postBlock;
	};
	struct array {
		void* array;
		int length;
	};
}
%union	{
	char* str;
	int intVal;
	float floatVal;
	struct var var;
	struct array array;
	struct leaves leaves;
}
%type	<str> commands params body statement value fnCall fnName fnObject type literal
%type	<var> varDef return
%type	<array> varList
%type	<leaves> blocks fnHead fnTail paramList inlineFn
%token	<str> COMMENT WORD CONST QUOTE OP IN OUT CROSS REF DEREF
%token	<intVal> INT
%token	<floatVal> FLOAT

%%

//
// Top-level blocks
//

code:
commands blocks
{
	printf("%s\n%s\n%s\n", $1, $2.preBlock, $2.blockHead);
}
;


//
// Big structures: pre-processing commands, function definition blocks.
//

commands:
{
	$$ = "";
}
|
WORD QUOTE
{
	$$ = format($$, "#%s %s", $1, $2);
}
|
commands WORD QUOTE
{
	$$ = format($$, "%s\n#%s %s", $1, $2, $3);
}
;

blocks:
{
	$$.preBlock = "";
	$$.blockHead = "";
}
|
blocks COMMENT
{
	char* comment = format(comment, "/*%s\n\n*/", $2);
	$$.preBlock = $1.preBlock;
	$$.blockHead = combine($1.blockHead, comment, "\n");
}
|
blocks '#' WORD params return body
{
	char* h = format(h,
		"%s %s(%s);",
		$5.type, $3, $4);
	char* c = format(c,
		"%s %s(%s)\n"
		"{\n"
			"\t%s;\n"
			"%s\n"
			"\treturn %s;\n"
		"}",
		$5.type, $3, $4, $5.initialiser, $6, $5.name);
	$$.preBlock = combine($1.preBlock, h, "\n");
	$$.blockHead = combine($1.blockHead, c, "\n");
}
;

params:
{
	$$ = "void";
}
|
IN varDef
{
	$$ = format($$, "%s %s", $2.type, $2.name);
}
|
params IN varDef
{
	$$ = format($$, "%s, %s %s", $1, $3.type, $3.name);
}
;

return:
{
	$$.type = "bool";
	$$.name = "fnSuccess";
	$$.defaultValue = "true";
	$$.failValue = "false";
	$$.initialiser = "bool fnSuccess = true";
}
|
OUT varDef
{
	$$ = $2;
}
;


//
// Function bodies
//

body:
{
	$$ = "";
}
|
statement
|
body statement
{
	$$ = combine($1, $2, "\n");
}
;

statement:
// Function calls
fnCall
{
	$$ = format($$, "\t%s;", $1);
}
|
// Assertions
'?' value
{
	$$ = format($$, "\tif (!(%s))\n\t{\n\t\tfprintf(stderr, \"Failed at check: %s\\n\");\n\t\treturn 0;\n\t}", $2, $2);
}
|
// Assignments
value '=' value
{
	$$ = format($$, "\t%s = %s;", $1, $3);
}
|
// Assignments (including initialisations)
varDef
{
	$$ = format($$, "\t%s;", $1.initialiser);
}
;


//
// Function calls
//

fnCall:
fnTail
{
	char* pre = combine($1.preBlock, $1.blockHead, ";\n\t");
	$$ = format($$, "%s(%s)", pre, $1.blockTail);
	printf("%s\n", $1.preScope);
	popFn();
	counter++;
}
;

fnName:
WORD
{
	if(!currentFn(fnStack) || currentFn(fnStack)->stackID != counter) {
		struct fn f = {0};
		f.stackID = counter;
		f.name = $1;
		pushFn(f);
	} else {
		currentFn()->name = $1;
	}
	
	// Function inferencing stuff goes here.
	// Through here.
	
	$$ = $1;
}
;
fnObject:
value
{
	struct fn f = {0};
	f.stackID = counter;
	f.objectType = $1;
	pushFn(f);
	
	$$ = $1;
}
;

fnHead:
fnName ':' paramList
{
	$$.preScope = $3.preScope;
	$$.blockHead = $1;
	$$.blockTail = $3.blockTail;
}
|
fnName '(' paramList ')'
{
	$$.preScope = $3.preScope;
	$$.blockHead = $1;
	$$.blockTail = $3.blockTail;
}
|
fnObject '.' fnName ':' paramList
{
	char* params = combine($1, $5.blockTail, ", ");
	$$.preScope = $5.preScope;
	$$.blockHead = $3;
	$$.blockTail = params;
}
|
fnObject '.' fnName '(' paramList ')'
{
	char* params = combine($1, $5.blockTail, ", ");
	$$.preScope = $5.preScope;
	$$.blockHead = $3;
	$$.blockTail = params;
}
;

fnTail:
fnHead
{
	$$.preBlock = "";
	$$.blockHead = $1.blockHead;
	$$.blockTail = $1.blockTail;
}
|
fnTail IN WORD
{
	char* ptr = format(ptr, "&%s", $3);
	$$.preBlock = "";
	$$.blockHead = $1.blockHead;
	$$.blockTail = combine($1.blockTail, ptr, ", ");
}
|
fnTail IN WORD '[' type ']'
{
	char* ptr = format(ptr, "&%s", $3);
	char* pre = format(pre, "%s %s = {0}", $5, $3);
	char* preList = combine($1.preBlock, pre, ";\n\t");
	$$.preBlock = preList;
	$$.blockHead = $1.blockHead;
	$$.blockTail = combine($1.blockTail, ptr, ", ");
}
|
fnTail IN WORD '[' type CROSS INT ']'
{
	char* pre = format(pre, "%s %s[%i] = {0}", $5, $3, $7);
	char* preList = combine($1.preBlock, pre, ";\n\t");
	$$.preBlock = preList;
	$$.blockHead = $1.blockHead;
	$$.blockTail = combine($1.blockTail, $3, ", ");
}
|
fnTail IN literal
{
	$$.preBlock = "";
	$$.blockHead = $1.blockHead;
	$$.blockTail = combine($1.blockTail, $3, ", ");
}
;

paramList:
{
	$$.preScope = "";
	$$.blockTail = "";
}
|
inlineFn
{
	$$.preScope = $1.preScope;
	$$.blockTail = $1.blockTail;
}
|
value
{
	$$.preScope = "";
	$$.blockTail = $1;	
}
|
paramList ',' inlineFn
{
	$$.preScope = combine($1.preScope, $3.preScope, "\n");
	$$.blockTail = format($$.blockTail,
		"%s, %s",
		$1.blockTail, $3.blockTail);
}
|
paramList ',' value
{
	$$.preScope = $1.preScope;
	$$.blockTail = format($$.blockTail,
		"%s, %s",
		$1.blockTail, $3);
}
;

inlineFn:
varList IN value '[' type ']'
{
	char *varSetup = "", *varGet = "";
	for(int i = 0; i < $1.length; i++)
	{
		varGet = format(varGet,
			"%s = va_arg(args, %s)",
			((struct var*)$1.array)[i].name, ((struct var*)$1.array)[i].type);
		varSetup = combine(varSetup, varGet, ";\n\t");
	}
	$$.preScope = format($$.preScope,
		"%s inlineFn%i(void* extras, ...)\n"
		"{\n"
		"\tva_list args;\n"
		"\tva_start(args, extras);\n"
		"\t%s;\n"
		"\tva_end(args);\n"
		"\treturn %s;\n"
		"}",
		$5, counter, varSetup, $3);
	$$.blockTail = format($$.blockTail, "inlineFn%i", counter);
	counter++;
}
;


//
// Small details: variables, types, literals and their lists.
//

type:
WORD
| WORD OP {
	$$ = format($$, "%s*", $1);
}
| type WORD {
	$$ = format($$, "%s %s", $1, $2);
}
| type OP {
	$$ = format($$, "%s*", $1);
}
;

varDef:
WORD '[' type ']' {
	$$.type = $3;
	$$.name = $1;
	$$.defaultValue = "{0}";
	$$.failValue = "{0}";
	$$.initialiser = format($$.initialiser,
		"%s %s = %s",
		$$.type, $$.name, $$.defaultValue);
}
| WORD '[' type CROSS INT ']' {
	$$.type = format($$.type, "%s*", $3);
	$$.name = $1;
	$$.defaultValue = "{0}";
	$$.failValue = "{0}";
	$$.initialiser = format($$.initialiser,
		"%s %s[%i] = %s",
		$$.type, $$.name, $$.defaultValue);
}
| WORD '[' type ']' '=' value {
	$$.type = $3;
	$$.name = $1;
	$$.defaultValue = $6;
	$$.failValue = "{0}";
	$$.initialiser = format($$.initialiser,
		"%s %s = %s",
		$$.type, $$.name, $$.defaultValue);
}
;

varList:
WORD ',' varDef {
	$$.array = malloc(sizeof(struct var) * 100);
	$$.length = 2;
	((struct var*)$$.array)[0] = $3;
	((struct var*)$$.array)[0].name = $1;
	((struct var*)$$.array)[1] = $3;
}
| varDef {
	$$.array = malloc(sizeof(struct var) * 100);
	$$.length = 1;
	((struct var*)$$.array)[0] = $1;
}
| varList ',' varDef {
	((struct var*)$$.array)[$$.length] = $3;
	$$.length += 1;
}
;

literal:
INT {
	$$ = format($$, "%i", $1);
}
| FLOAT {
	$$ = format($$, "%f", $1);
}
| CONST | QUOTE
;

value:
WORD | literal
|
// Negatives, etc.
OP value
{
	$1 = translateOp($1);
	$$ = format($$, "%s%s", $1, $2);
}
|
// Infix operator
value OP value
{
	$2 = translateOp($2);
	$$ = format($$, "%s %s %s", $1, $2, $3);
}
|
// Array element
value '.' INT
{
	$$ = format($$, "%s[%i]", $1, $3-1);
}
|
// Dereferencing
value '.' DEREF
{
	$$ = format($$, "*%s", $1);
	// Should test non-null here.
}
|
// Referencing
value '.' REF
{
	$$ = format($$, "&%s", $1);
}
|
// Function call
fnCall
|
// Struct field
value '.' WORD
{
	$$ = format($$, "%s.%s", $1, $3);
}
|
// Grouping by parentheses
'(' value ')'
{
	$$ = format($$, "(%s)", $2);
}
;


%%

void yyerror(const char* errorText)
{
	fprintf(stderr, "%s\n", errorText);
}

int main(void)
{
	fnStack.list = malloc(sizeof(struct fn) * 100);
	return yyparse();
}
