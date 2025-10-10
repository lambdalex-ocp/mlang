open M_ir
open Utils
open Js_of_ocaml
module Interp = M_ir.Mir_interpreter

let hello () = Platform.Log.log "hello c:"

let exec_program json =
  let module Interp = Interp.FloatDefInterp in
  let json = Yojson.Safe.from_string json in
  let program =
    match Mir.program_of_yojson json with
    | Ok program -> program
    | Error e -> raise @@ Failure e
  in
  let ctx = Interp.empty_ctx program false in
  Interp.evaluate_program ctx

let parse_file (name, contents) =
  let filebuf = Lexing.from_string contents in
  Mlang.Parsing.parse_lexbuf filebuf name

let parse_files files m_program =
  let prog = List.map parse_file files in
  List.rev m_program @ prog

let parse_file fileMap =
  let d = Js.to_array fileMap in
  let files =
    Array.map
      (fun arr ->
        Js.to_array arr |> Array.map (fun s -> Js.to_string s) |> fun arr ->
        (arr.(0), arr.(1)))
      d
    |> Array.to_list
  in
  let progress_dummy _ = () in
  let m_program =
    Mlang.Parsing.parse_m_dgfip progress_dummy [] |> parse_files files
  in
  Config.mpp_function := "target";
  let m_program = Mlang.Expander.proceed m_program in
  let m_program = Mlang.Validator.proceed "target" m_program in
  let m_program = Mlang.Mast_to_mir.translate m_program in
  let m_program = M_ir.Mir.expand_functions m_program in
  m_program

let obj =
  object%js
    method hello = hello

    method execProgram = exec_program

    method parseFiles = parse_file
  end

let _ = Js.export "mlang" obj
