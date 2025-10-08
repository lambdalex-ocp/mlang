open M_ir
open Utils
open Js_of_ocaml
module Interp = M_ir.Mir_interpreter

let hello () =
  Platform.Log.log "hello c:"

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

let obj = object%js
  method hello = hello
  method execProgram = exec_program
end

let _ =
  Js.export "mlang" obj

