%{
    open Syntax

    exception Parsing_error
%}

/* Identifier and constants */
%token <Syntax.name> NAME
%token <int> INT
%token <string> STRING 

/* Reserved words */
%token LET
%token IN
%token LETREC
%token LAM
%token NU
%token WR
%token RD
%token IF
%token THEN
%token ELSE
%token TRUE
%token FALSE
%token THUNK
%token FORCE

/* Operators */
%token EQUAL
%token LARROW
%token RARROW
%token REPL
%token PAR
%token PARL
%token CHOICE

/* Arithmetic operators */
%token PLUS
%token MINUS
%token TIMES
%token DIVIDE
%token MOD

/* Logical operators */
%token OR
%token AND
%token NOT

/* Relations */
%token LT
%token GT
%token LEQ
%token GEQ
%token EQ
%token NEQ

/* Built-in functions */
%token FST
%token SND
%token RAND
%token SHOW
%token CONS
%token CONCAT
%token LOOKUP

/* Punctuation */
%token DOT
%token LPAREN
%token RPAREN
%token LBRACK
%token RBRACK
%token LBRACE
%token RBRACE
%token COMMA
%token SEMI
%token EOF

/* Precedence and assoc */
%nonassoc NU_PREC
%right PAR PARL CHOICE
%nonassoc REPL
%right DOT
%nonassoc LET_PREC
%nonassoc THEN
%nonassoc ELSE
%right CONS CONCAT
%nonassoc SHOW
%nonassoc OR
%nonassoc AND
%nonassoc NOT
%nonassoc LT GT LEQ GEQ EQ NEQ
%left PLUS MINUS
%left TIMES DIVIDE MOD
%left APP

%start file
%type <Syntax.process list> file
%start toplevel
%type <Syntax.process list> toplevel

%%

/* Grammar */

file:
    | EOF
      { [] }
    | e = expr EOF
      { [Process e] }
    | e = expr SEMI SEMI lst = file
      { Process e :: lst }

toplevel:
    | e = expr EOF
      { [Process e] }

expr:
    | e = atom_expr
      { e }
    | e = arith_expr
      { e }
    | e = bool_expr
      { e }
    | e = app_expr
      { e }
    | e = comm_expr
      { e }
    | e = proc_expr
      { e }
    | LAM x = NAME DOT e = expr
      { Lam (x, e) }
    | LET x = NAME EQUAL e1 = expr IN e2 = expr %prec LET_PREC
      { Let (x, e1, e2) }
    | LET LPAREN p = comma_list RPAREN EQUAL e1 = expr IN e2 = expr %prec LET_PREC
      { LetP (p, e1, e2) }
    | LETREC x = NAME EQUAL e1 = expr IN e2 = expr %prec LET_PREC
      { LetRec (x, e1, e2) }
    | IF b = expr THEN e1 = expr
      { IfT (b, e1) }
    | IF b = expr THEN e1 = expr ELSE e2 = expr
      { IfTE (b, e1, e2) }
    | e1 = expr DOT e2 = expr
      { Seq (e1, e2) }

atom_expr:
    | x = NAME
      { Name x }
    | n = INT
      { Int n }
    | s = STRING
      { String s }
    | TRUE
      { Bool true }
    | FALSE
      { Bool false }
    | LBRACK RBRACK
      { List [] }
    | LBRACK e = comma_list RBRACK
      { List e }
    | LPAREN e1 = expr COMMA e2 = comma_list RPAREN
      { Tuple (e1::e2) }
    | RAND
      { Rand }
    | LPAREN e = expr RPAREN
      { e }
    
arith_expr:
    | e1 = expr PLUS e2 = expr
      { Plus (e1, e2) }
    | e1 = expr MINUS e2 = expr
      { Minus (e1, e2) }
    | e1 = expr TIMES e2 = expr
      { Times (e1, e2) }
    | e1 = expr DIVIDE e2 = expr
      { Divide (e1, e2) }
    | e1 = expr MOD e2 = expr
      { Mod (e1, e2) }

bool_expr:
    | e1 = expr LT e2 = expr
      { Lt (e1, e2) }
    | e1 = expr GT e2 = expr
      { Gt (e1, e2) }
    | e1 = expr LEQ e2 = expr
      { Leq (e1, e2) }
    | e1 = expr GEQ e2 = expr
      { Geq (e1, e2) }
    | e1 = expr OR e2 = expr
      { Or (e1, e2) }
    | e1 = expr AND e2 = expr
      { And (e1, e2) }
    | NOT e1 = expr
      { Not e1 }
    | e1 = expr EQ e2 = expr
      { Eq (e1, e2) }
    | e1 = expr NEQ e2 = expr
      { Neq (e1, e2) }

app_expr:
    | x = NAME e = expr %prec APP
      { App (Name x, e) }
    | LPAREN x = expr RPAREN e = expr %prec APP
      { App (x, e) }
    | THUNK x = NAME
      { Thunk (Name x) }
    | THUNK LPAREN e = expr RPAREN
      { Thunk e }
    | FORCE x = NAME
      { Force (Name x) }
    | FORCE LPAREN e = expr RPAREN
      { Force e }
    | FST x = NAME
      { Fst (Name x) }
    | FST LPAREN e = expr RPAREN
      { Fst e }
    | SND x = NAME
      { Snd (Name x) }
    | SND LPAREN e = expr RPAREN
      { Snd e }
    | SHOW e = expr
      { Show e }
    | e1 = expr CONS e2 = expr
      { Cons (e1, e2) }
    | e1 = expr CONCAT e2 = expr
      { Concat (e1, e2) }
    | LOOKUP e1 = expr IN e2 = expr %prec LET_PREC
      { Lookup (e1, e2) }

comm_expr:
    | WR e = expr RARROW c = NAME
      { Wr (e, c) }
    | RD x = NAME LARROW c = NAME
      { RdBind (x, c) }
    | RD c = NAME
      { Rd c }
    | NU x = NAME DOT e = expr %prec NU_PREC
      { Nu ([x], e) }
    | NU LBRACE x = comma_list RBRACE DOT e = expr %prec NU_PREC
      { Nu (List.map (function
          | Name x -> x
          | _ -> raise Parsing_error)
        x, e) }

proc_expr:
    | REPL e = expr
      { Repl e }
    | e1 = expr PAR e2 = expr
      { ParComp (e1, e2) }
    | e1 = expr PARL e2 = expr
      { ParLeft (e1, e2) }
    | e1 = expr CHOICE e2 = expr
      { Choice (e1, e2) }

comma_list:
    | e = expr
      { [e] }
    | e1 = expr COMMA e2 = comma_list
      { e1 :: e2 }