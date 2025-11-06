open M_ir
open Utils
open Js_of_ocaml
open Mlang
module Interp = M_ir.Mir_interpreter

module Dbg_info_Jsoo = struct end

let hello () = Platform.Log.log "hello c:"

(* Menhir makes us load files one by one, so we build the filesystem through
   several calls. *)
let filesystem = ref StrMap.empty

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
  print_string "parsing ";
  print_endline name;
  filesystem := StrMap.add name contents !filesystem;
  Config.platform := Config.Web !filesystem;
  try
    let filebuf = Lexing.from_string contents in
    print_endline "after lexing.";
    Mlang.Parsing.parse_lexbuf filebuf name
  with Errors.StructuredError (msg, pos_list, _kont) as _e ->
    Cli.error_print "%a" Errors.format_structured_error (msg, pos_list);
    []

let parse_files files callbacks m_program =
  let prog = List.map (fun (filename, contents) ->
    callbacks##parsing (Js.string filename);
    let m_file = parse_file (filename, contents) in
    callbacks##doneParsing (Js.string filename);
    m_file)
    files in
  List.rev m_program @ prog

let parse_filemap file_map callbacks =
  Console.console##log callbacks;
  let d = Js.to_array file_map in
  let files =
    Array.map
      (fun arr ->
        Js.to_array arr |> Array.map (fun s -> Js.to_string s) |> fun arr ->
        (arr.(0), arr.(1)))
      d
    |> Array.to_list
  in
  let filemap = StrMap.from_assoc_list files in
  let progress_dummy _ = () in
  print_endline "before parsing.";
  let m_program =
    Mlang.Parsing.parse_m_dgfip progress_dummy [] |> parse_files files callbacks
  in
  Config.platform := Config.Web filemap;
  m_program

let run m_program irj_contents target application =
  Config.mpp_function := Js.to_string target;
  Config.application_names := [ Js.to_string application ];
  (* Config.mpp_function := "target"; *)
  (* Config.application_names := [ "app" ]; *)
  print_endline "before expand";
  let m_program = Mlang.Expander.proceed m_program in
  print_endline "after expand";
  print_endline "proceeding";
  let m_program = Mlang.Validator.proceed !Config.mpp_function m_program in
  print_endline "translating";
  let m_program = Mlang.Mast_to_mir.translate m_program in
  print_endline "expanding functions";
  let m_program = M_ir.Mir.expand_functions m_program in
  print_endline "before runnning";
  let dbg_infos =
    Mlang.Test_interpreter.check_test m_program (Contents irj_contents)
      (Some "") !Config.value_sort !Config.round_ops
  in
  print_endline "we've run  it all.";
  (* dbg_infos *)
  let buf = Buffer.create 1000 in
  let fmt = Format.formatter_of_buffer buf in
  let delim = ref "" in
  Buffer.add_char buf '[';
  dbg_infos
  |> List.iter (fun Test_interpreter.{ target; dbg_info } ->
         Buffer.add_string buf !delim;
         delim := ",";
         Format.fprintf fmt {|{"target": "%s", "dbg_info": |} target;
         Dbg_info.to_json fmt dbg_info;
         Buffer.add_string buf "}");
  Buffer.add_char buf ']';
  Buffer.to_bytes buf |> Bytes.to_string |> Js.string

let obj =
  object%js
    method hello = hello

    method execProgram = exec_program

    method parseFile name contents =
      let name = Js.to_string name in
      let contents = Js.to_string contents in
      parse_file (name, contents)

    method parseFiles = parse_filemap

    method run = run
  end

let _ = Js.export "mlang" obj
