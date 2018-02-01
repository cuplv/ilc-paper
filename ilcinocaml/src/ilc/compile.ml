open Machine

exception Compilation_error

let pid_counter = ref 0

let rec compile = function
    | Syntax.Name x ->  [IVar x]
    | Syntax.Int n -> [IInt n]
    | Syntax.Bool b -> [IBool b]
    | Syntax.Plus (e1, e2) -> (compile e1) @ (compile e2) @ [IAdd]
    | Syntax.Minus (e1, e2) -> (compile e1) @ (compile e2) @ [ISub]
    | Syntax.Times (e1, e2) -> (compile e1) @ (compile e2) @ [IMult]
    | Syntax.Divide (e1, e2) -> (compile e1) @ (compile e2) @ [IDiv]
    | Syntax.Mod (e1, e2) -> (compile e1) @ (compile e2) @ [IMod]
    | Syntax.Less (e1, e2) -> (compile e1) @ (compile e2) @ [ILess]
    | Syntax.If (e1, e2, e3) -> (compile e1) @ [IBranch (compile e2, compile e3)]
    | Syntax.Let (x, e1, e2) -> (compile e1) @ [ILet x] @ (compile e2)
    | Syntax.Lam (x, e) -> [IClosure ("anon", x, compile e @ [IPopEnv])]
    | Syntax.App (e1, e2) -> (compile e1) @ (compile e2) @ [ICall]
    | Syntax.Nu (x, e) -> (compile e) (* TODO: This is a noop for now *)
    | Syntax.ParComp (e1, e2) ->
        let pid = !pid_counter in
        pid_counter := pid + 2; [IStartP pid] @
        (compile e1) @ [IEndP pid; IStartP (pid + 1)] @
        (compile e2) @ [IEndP (pid + 1)]
    | Syntax.ParLeft (e1, e2) ->
        let pid = !pid_counter in
        pid_counter := pid + 2; [IStartP pid] @
        (compile e1) @ [IEndP pid; IStartP (pid + 1)] @
        (compile e2) @ [IEndP (pid + 1); IHole (pid+1)]
    | Syntax.Wr (e, x) -> (compile e) @ [IWr (MHole, x)]
    | Syntax.Rd (x1, x2) -> [IRd (x1, x2)]
    | Syntax.Seq (e1, e2) -> (compile e1) @ (compile e2)
    | _ -> raise (Compilation_error)
