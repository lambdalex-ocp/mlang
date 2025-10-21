(* cli.ml *)
open Js_of_ocaml

(**{2 Command line arguments parsing}*)

module Cmdliner = struct
  module Term = struct
    type 'a t = unit
  end

  module Cmd = struct
    module Exit = struct
      type code = int
    end

    type info = unit

    type 'a t = unit

    let eval ?help:(_ = Format.std_formatter) ?err:(_ = Format.std_formatter)
        ?catch:(_ = true) ?env:(_ = fun _ -> None) ?argv:(_ = [||])
        ?term_err:(_ = 1) (_ : unit t) : Exit.code =
      assert false

    let v (_ : info) (_ : 'a Term.t) : 'a t = assert false
  end
end

module ANSITerminal = struct
  type style = unit
end

let mlang_t
    (_ :
      string list ->
      string list ->
      bool ->
      bool ->
      string list ->
      bool ->
      string ->
      bool ->
      string option ->
      string option ->
      string option ->
      bool ->
      string option ->
      string ->
      bool ->
      string option ->
      string option ->
      float option ->
      int ->
      bool ->
      string list option ->
      string option ->
      'a) : 'a Cmdliner.Term.t =
  assert false

let info : Cmdliner.Cmd.info = ()

(**{2 Flags and parameters}*)
let set_all_arg_refs (_ : Config.files) (_ : string list) (_ : bool) (_ : bool)
    (_ : string list) (_ : bool) (_ : string) (_ : bool) (_ : string option)
    (_ : bool) (_ : bool) (_ : float option) (_ : int) (_ : Config.value_sort)
    (_ : Config.round_ops) (_ : Config.backend) (_ : bool) (_ : string)
    (_ : Config.Dgfip_options.flags) (_ : Config.execution_mode)
    (_ : string option) : unit =
  assert false

let add_prefix_to_each_line (_ : string) (_ : int -> string) : string =
  assert false

(**{2 Printers}*)

let format_with_style (_ : ANSITerminal.style list)
    (_ : ('a, unit, string) format) : 'a =
  assert false

let var_info_print (_ : ('a, Format.formatter, unit, unit) format4) : 'a =
  assert false

let debug_print ?(endline = "\n")
    (kont : ('a, Format.formatter, unit, unit) format4) : 'a =
  Format.kasprintf (fun s -> Console.console##log s) kont

let warning_print (kont : ('a, Format.formatter, unit, unit) format4) : 'a =
  Format.kasprintf (fun s -> Console.console##warn s) kont

let error_print (kont : ('a, Format.formatter, unit, unit) format4) : 'a =
  Format.kasprintf (fun s -> Console.console##error s) kont

let result_print (_ : ('a, Format.formatter, unit, unit) format4) : 'a =
  assert false

let create_progress_bar (_ : string) : (string -> unit) * (string -> unit) =
  assert false

let retrieve_loc_text (_ : Pos.t) : string =
  Console.console##log "retrieve loc text!";
  assert false
