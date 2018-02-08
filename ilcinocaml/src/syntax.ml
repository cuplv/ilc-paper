(* -------------------------------------------------------------------------- *)
(* Abstract syntax tree *)

type name = string

(* Types *)
type ty = 
    | TNat
    | TBool
    | TString of string
    | TArrow of ty * ty

type expr =
    (* Identifier, constants, values *)
    | Name of name
    | Int of int
    | Bool of bool
    | String of string
    | List of expr list
    | Tuple of expr list

    (* Arithmetic operators *)
    | Plus of expr * expr
    | Minus of expr * expr
    | Times of expr * expr
    | Divide of expr * expr
    | Mod of expr * expr

    (* Logical operators *)
    | Or of expr * expr
    | And of expr * expr
    | Not of expr

    (* Relations *)
    | Lt of expr * expr
    | Gt of expr * expr
    | Leq of expr * expr
    | Geq of expr * expr
    | Eq of expr * expr
    | Neq of expr * expr
    
    (* Let *)
    | Let of name * expr * expr
    | LetRec of name * expr * expr
    | LetP of expr list * expr * expr

    (* Conditionals *)
    | IfTE of expr * expr * expr
    | IfT of expr * expr

    (* Lambda *)
    | Lam of name * expr
    | App of expr * expr

    (* Pi *)
    | Wr of expr * name
    | Rd of name
    | RdBind of name * name
    | Nu of name list * expr
    | ParComp of expr * expr
    | ParLeft of expr * expr
    | Choice of expr * expr
    | Repl of expr
    | Seq of expr * expr

    (* Laziness *)
    | Thunk of expr
    | Force of expr
    
    (* Built-in functions *)
    | Fst of expr
    | Snd of expr
    | Rand
    | Show of expr
    | Cons of expr * expr
    | Concat of expr * expr
    | Lookup of expr * expr

type process =
    | Process of expr

(* -------------------------------------------------------------------------- *)
(* Printing *)

let name_to_str = function
    | x -> "Name(" ^ x ^ ")"

let str_of_list f es = 
    let rec to_str acc = function
        | [] -> acc
        | [e] -> acc ^ (f e)
        | e :: es -> to_str (acc ^ (f e) ^ ",") es
    in
    to_str "" es

let string_of_expr e =
    let rec to_str e = 
        match e with
        (* Identifier, constants, and values *)
        | Name x -> name_to_str x
        | Int n -> "Int(" ^ string_of_int n ^ ")"
        | Bool b -> "Bool(" ^ string_of_bool b ^ ")"
        | String s -> "String(" ^ s ^ ")"
        | List es -> "List(" ^ str_of_list to_str es ^ ")"
        | Tuple es -> "Tuple(" ^ str_of_list to_str es ^ ")"

        (* Arithmetic operators *)
        | Plus (e1, e2) -> "Plus(" ^ to_str e1 ^ "," ^ to_str e2 ^ ")"
        | Minus (e1, e2) -> "Minus(" ^ to_str e1 ^ "," ^ to_str e2 ^ ")"
        | Times (e1, e2) -> "Times(" ^ to_str e1 ^ "," ^ to_str e2 ^ ")"
        | Divide (e1, e2) -> "Divide(" ^ to_str e1 ^ "," ^ to_str e2 ^ ")"
        | Mod (e1, e2) -> "Mod(" ^ to_str e1 ^ "," ^ to_str e2 ^ ")"

        (* Logical operators *)
        | Or (e1, e2) -> "Or(" ^ to_str e1 ^ "," ^ to_str e2 ^ ")"
        | And (e1, e2) -> "And(" ^ to_str e1 ^ "," ^ to_str e2 ^ ")"
        | Not e1 -> "Not(" ^ to_str e1 ^ ")"

        (* Relations *)
        | Lt (e1, e2) -> "Lt(" ^ to_str e1 ^ "," ^ to_str e2 ^ ")"
        | Gt (e1, e2) -> "Gt(" ^ to_str e1 ^ "," ^ to_str e2 ^ ")"
        | Leq (e1, e2) -> "Leq(" ^ to_str e1 ^ "," ^ to_str e2 ^ ")"
        | Geq (e1, e2) -> "Geq(" ^ to_str e1 ^ "," ^ to_str e2 ^ ")"
        | Eq (e1, e2) -> "Eq(" ^ to_str e1 ^ "," ^ to_str e2 ^ ")"
        | Neq (e1, e2) -> "Neq(" ^ to_str e1 ^ "," ^ to_str e2 ^ ")"

        (* Let *)
        | Let (x, e1, e2) -> "Let(" ^ name_to_str x ^ "," ^ 
          to_str e1 ^ "," ^ to_str e2 ^ ")"
        | LetRec (x, e1, e2) -> "LetRec(" ^ name_to_str x ^ "," ^ 
          to_str e1 ^ "," ^ to_str e2 ^ ")"
        | LetP (p, e1, e2) -> "LetP(" ^ "(" ^ str_of_list to_str p ^ ")," ^ 
          to_str e1 ^ "," ^ to_str e2 ^ ")"

        (* Conditionals *)
        | IfTE (e1, e2, e3) -> "IfTE(" ^ to_str e1 ^ "," ^ 
          to_str e2 ^ "," ^ to_str e3 ^ ")"
        | IfT (e1, e2) -> "IfT(" ^ to_str e1 ^ "," ^ 
          to_str e2 ^ ")"

        (* Lambda *)
        | Lam (x, e) -> "Lam(" ^ name_to_str x ^ "," ^ to_str e ^ ")"
        | App (e1, e2) -> "App(" ^ to_str e1 ^ "," ^ to_str e2 ^ ")"

        (* Pi *)
        | Wr (e, x) -> "Wr(" ^ to_str e ^ "," ^ name_to_str x ^ ")"
        | Rd x -> "Rd(" ^ name_to_str x ^ ")"
        | RdBind (x1, x2) -> "RdBind(" ^ name_to_str x1 ^ "," ^ name_to_str x2 ^ ")"
        | Nu (x, e) -> "Nu(" ^ str_of_list name_to_str x ^ "," ^ to_str e ^ ")"
        | ParComp (e1, e2) -> "ParComp(" ^ to_str e1 ^ "," ^ to_str e2 ^ ")"
        | ParLeft (e1, e2) -> "ParLeft(" ^ to_str e1 ^ "," ^ to_str e2 ^ ")"
        | Choice (e1, e2) -> "Choice(" ^ to_str e1 ^ "," ^ to_str e2 ^ ")"
        | Repl e -> "Repl(" ^ to_str e ^ ")"
        | Seq (e1, e2) -> "Seq(" ^ to_str e1 ^ "," ^ to_str e2 ^ ")"

        (* Laziness *)
        | Thunk e1 -> "Thunk(" ^ to_str e1 ^ ")"
        | Force e1 -> "Force(" ^ to_str e1 ^ ")"
        
        (* Built-in functions *) 
        | Fst e -> "Fst(" ^ to_str e ^ ")"
        | Snd e -> "Snd(" ^ to_str e ^ ")"
        | Rand -> "Rand()"
        | Show e -> "Show(" ^ to_str e ^ ")"
        | Cons (e1, e2) -> "Cons(" ^ to_str e1 ^ "," ^ to_str e2 ^ ")"
        | Concat (e1, e2) -> "Concat(" ^ to_str e1 ^ "," ^ to_str e2 ^ ")"
        | Lookup (e1, e2) -> "Lookup(" ^ to_str e1 ^ "," ^ to_str e2 ^ ")"
    in to_str e