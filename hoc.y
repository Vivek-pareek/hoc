%{
double mem[26];
%}

/* stack type defined as union where val represents actual double value and
   index is the index into memory for variables */

%union {           /* stack type */
        double val; /* actual value */
        int index;  /* index into mem[] */
}

%token <val> NUMBER
%token <index> VAR
%type <val> expr
%right '='
%left '+' '-'
%left '*' '/' '%'
%left UNARYMINUS /*new*/
%left UNARYPLUS /*new*/

%%

/* start of grammar */

list : /* -- */
      | list term
      | list expr term { printf("\t%.8g\n", $2); }
      | list error term { yyerrok; }
      ;

/* production for terminating symbol */
term : '\n'
      | ';'

/* production for handling operations */
expr : NUMBER          { $$ = $1; }
      | VAR            { $$ = mem[$1]; }
      | VAR '=' expr   { $$ = mem[$1] = $3; }
      | expr '+' expr  { $$ = $1 + $3; }
      | expr '-' expr  { $$ = $1 - $3; }
      | expr '*' expr  { $$ = $1 * $3; }
      | expr '/' expr  {
                        if($3 == 0.0)
                          execerror("division by zero", "");
                        $$ = $1 / $3; }
      | expr '%' expr  { $$ = mod($1,$3); }
      | '(' expr ')'   { $$ = $2; }
      | '-' expr %prec UNARYMINUS { $$ = -$2; }
      | '+' expr %prec UNARYPLUS { $$ = $2; }
      ;
%%

/* end of grammar */

#include<stdio.h>
#include<ctype.h>
#include<math.h>
#include<signal.h>
#include<setjmp.h>

jmp_buf begin;

char *progname;
int lineNo = 1;

main(argc, argv)  /* hoc1 */
      char* argv[];
{
    int fpecatch();

    progname = argv[0];
    setjmp(begin);
    signal(SIGFPE, fpecatch);
    yyparse();
}

execerror(s, t)
    char* s, *t;
{
  warning(s, t);
  longjmp(begin, 0);
}

fpecatch(){
  execerror("floating point exception", (char* ) 0);
}

//Lexical analyzer called by yyparse in the final c code produced by yacc
yylex(){
  int c;

  while((c = getchar()) == ' ' || c == '\t');

  if(c == EOF){
    return 0;
  }

  if( c == '.' || isdigit(c)){
    ungetc(c,stdin);
    scanf("%lf",&yylval.val);
    return NUMBER;
  }

  if(islower(c)){
    yylval.index = c - 'a';
    return VAR;
  }

  if(c == '\n')
    lineNo++;

  return c;
}

//error message handling
yyerror(s)
  char* s;
{
  warning(s, (char *) 0);
}

warning(s,t)
  char* s, *t;
{
  fprintf(stderr, "%s: %s",progname, s);
  if(t)
    fprintf(stderr, " %s", t);
  fprintf(stderr, " near line %d\n", lineNo);
}

//Function implemented to handle modulus operations
mod(num1,num2)
  double num1,num2;
{
  double mod;
  if(num1 < 0)
    mod = -num1;
  else
    mod = num1;
  if(num2 < 0)
    num2 = -num2;
  while(mod >= num2)
    mod = mod - num2;
  if(num1 < 0)
    return -mod;
  return mod;
}
