type process_acc = string list * int StrMap.t

include Test_interpreter

let check_all_tests (p : Mir.program) (test_dir : string)
    (value_sort : Config.value_sort) (round_ops : Config.round_ops)
    (filter_function : string -> bool) =
  let arr = Sys.readdir test_dir in
  let arr =
    Array.of_list
    @@ List.filter filter_function
    @@ List.filter
         (fun x -> not @@ Sys.is_directory (test_dir ^ "/" ^ x))
         (Array.to_list arr)
  in
  Mir_interpreter.exit_on_rte := false;
  (* sort by increasing size, hoping that small files = simple tests *)
  Array.sort compare arr;
  let dbg_warning = !Config.warning_flag in
  let dbg_time = !Config.display_time in
  Config.warning_flag := false;
  Config.display_time := false;
  (* let _, finish = Config.create_progress_bar "Testing files" in*)
  let process (name : string) ((successes, failures) : process_acc) :
      process_acc =
    let module Interp = (val Mir_interpreter.get_interp value_sort round_ops
                           : Mir_interpreter.S)
    in
    try
      Config.debug_flag := false;
      (* FIXME *)
      ignore
      @@ Test_interpreter.check_test p
           (Filename (test_dir ^ name))
           None value_sort round_ops;
      Config.debug_flag := true;
      Cli.result_print "%s" name;
      (name :: successes, failures)
    with
    | Test_interpreter.InterpError nbErr ->
        (successes, StrMap.add name nbErr failures)
    | Errors.StructuredError (msg, pos, kont) ->
        Cli.error_print "Error in test %s: %a" name
          Errors.format_structured_error (msg, pos);
        (match kont with None -> () | Some kont -> kont ());
        (successes, failures)
    | Interp.RuntimeError (run_error, _) -> (
        match run_error with
        | Interp.StructuredError (msg, pos, kont) ->
            Cli.error_print "Error in test %s: %a" name
              Errors.format_structured_error (msg, pos);
            (match kont with None -> () | Some kont -> kont ());
            (successes, failures)
        | Interp.NanOrInf (msg, Pos.Mark (_, pos)) ->
            Cli.error_print "Runtime error in test %s: NanOrInf (%s, %a)" name
              msg Pos.format pos;
            (successes, failures))
    | e ->
        Cli.error_print "Uncatched exception: %s" (Printexc.to_string e);
        raise e
  in
  let s, f =
    Parmap.parfold ~chunksize:5 process (Parmap.A arr) ([], StrMap.empty)
      (fun (old_s, old_f) (new_s, new_f) ->
        (new_s @ old_s, StrMap.union (fun _ x1 x2 -> Some (x1 + x2)) old_f new_f))
    (*
    Array.fold_left (fun acc name -> process name acc) ([], StrMap.empty) arr
*)
  in
  (* finish "done!"; *)
  Config.warning_flag := dbg_warning;
  Config.display_time := dbg_time;
  Cli.result_print "Test results: %d successes" (List.length s);

  if StrMap.cardinal f = 0 then Cli.result_print "No failures!"
  else (
    Cli.warning_print "Failures:";
    StrMap.iter
      (fun name nbErr -> Cli.error_print "\t%d errors in files %s" nbErr name)
      f)
