module ILC = Zoo.Main(struct
    let name = "ILC"
    
    type process = Syntax.process

    (* Typing context *)
    type ty_context = (Syntax.name * Syntax.ty) list

    type environment = (Syntax.name * Machine.mvalue) list

    let options = []

    let initial_environment = []

    let read_more _ = false

    let file_parser = Some (Parser.file Lexer.token)

    let toplevel_parser = Some (Parser.toplevel Lexer.token)

    exception Process_error of string

    let string_of_finished_p = function
        | (pid, ([], [v], _)) ->
            Printf.sprintf "%s%d:\n%s\n" "process" pid (Machine.string_of_mvalue v)
        | (pid, (frm :: _, _, _)) ->
            Printf.sprintf "%s%d:\n%s" "process" pid (Machine.string_of_frame frm)
        | (pid, ([], [], _)) ->
            Printf.sprintf "%s%d:\n0\n" "process" pid 
        | _ -> raise (Process_error "illegal final state")

    (* Run everything, including communication *)
    let run_full ps = 
        let init_ps = List.mapi (fun i p ->
            Machine.run (i, ([p], [], [[]]))) ps in
        let rec loop = function
            | (true, ps') -> ps'
            | (false, ps') ->
                loop (Communication.run_comm (Machine.run_until_blocked ps'))
        in
            Machine.init_pid_counter (List.length init_ps); loop (Communication.run_comm (Machine.run_until_blocked init_ps))

    let print_ast = function
        | ps ->
            print_string
            (List.fold_left (fun acc x ->
                match x with
                | Syntax.Process p -> acc ^ Syntax.string_of_expr p ^ "\n")
            "" ps)

    let print_ir = function
        | ps ->
            print_string
            (List.fold_left (fun acc x ->
                match x with
                | Syntax.Process p -> acc ^ (Machine.string_of_frame (Compile.compile p)) ^ "\n")
            "" ps)

    let exec = function
        | ps -> 
            let ps =
                List.map (function | Syntax.Process p -> Compile.compile p) 
                ps in
                List.iter print_endline
                (List.map string_of_finished_p (run_full ps))
end) ;;

ILC.main ()
