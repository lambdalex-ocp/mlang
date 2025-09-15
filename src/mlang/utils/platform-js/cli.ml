(* cli.ml *)

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

    let eval
        ?help:(_ = Format.std_formatter)
        ?err:(_ = Format.std_formatter)
        ?catch:(_ = true)
        ?env:(_ = fun _ -> None)
        ?argv:(_ = Sys.argv)
        ?term_err:(_ = 1)
        (_ : unit t) : Exit.code =
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
      int option ->
      bool ->
      string list option ->
      string option ->
      'a) : 'a Cmdliner.Term.t =
  assert false

let info : Cmdliner.Cmd.info = ()

(**{2 Flags and parameters}*)

type value_sort =
  | RegularFloat
  | MPFR of int
  | BigInt of int
  | Interval
  | Rational

type round_ops = RODefault | ROMulti | ROMainframe of int
type backend = Dgfip_c | UnknownBackend
type execution_mode = SingleTest of string | MultipleTests of string | Extraction
type files = NonEmpty of string list

let get_files (_ : files) : string list = assert false
let source_files : files ref = ref (NonEmpty [])
let application_names : string list ref = ref []
let dbg_graph_file : string ref = ref ""
let without_dgfip_m : bool ref = ref false
let verify_flag : bool ref = ref false
let debug_flag : bool ref = ref false
let var_info_flag : bool ref = ref false
let var_info_debug : string list ref = ref []
let warning_flag : bool ref = ref false
let no_print_cycles_flag : bool ref = ref false
let display_time : bool ref = ref false
let output_file : string ref = ref ""
let optimize_unsafe_float : bool ref = ref false
let m_clean_calls : bool ref = ref false
let comparison_error_margin : float ref = ref 0.0
let income_year : int ref = ref 0
let value_sort : value_sort ref = ref RegularFloat
let round_ops : round_ops ref = ref RODefault
let backend : backend ref = ref UnknownBackend
let dgfip_test_filter : bool ref = ref false
let mpp_function : string ref = ref ""
let dgfip_flags : Dgfip_options.flags ref = ref (Obj.magic ())
let execution_mode : execution_mode ref = ref Extraction
let dbgraph_var_focus : string option ref = ref None

let set_all_arg_refs
    (_ : files)
    (_ : string list)
    (_ : bool)
    (_ : bool)
    (_ : string list)
    (_ : bool)
    (_ : string)
    (_ : bool)
    (_ : string option)
    (_ : bool)
    (_ : bool)
    (_ : float option)
    (_ : int option)
    (_ : value_sort)
    (_ : round_ops)
    (_ : backend)
    (_ : bool)
    (_ : string)
    (_ : Dgfip_options.flags)
    (_ : execution_mode)
    (_ : string option) : unit =
  assert false

let add_prefix_to_each_line (_ : string) (_ : int -> string) : string =
  assert false

(**{2 Printers}*)

let format_with_style
    (_ : ANSITerminal.style list)
    (_ : ('a, unit, string) format) : 'a =
  assert false

let var_info_print (_ : ('a, Format.formatter, unit, unit) format4) : 'a =
  assert false

let debug_print
    ?(endline = "\n")
    (_ : ('a, Format.formatter, unit, unit) format4) : 'a =
  assert false

let warning_print (_ : ('a, Format.formatter, unit, unit) format4) : 'a =
  assert false

let error_print (_ : ('a, Format.formatter, unit, unit) format4) : 'a =
  assert false

let result_print (_ : ('a, Format.formatter, unit, unit) format4) : 'a =
  assert false

let create_progress_bar (_ : string) : (string -> unit) * (string -> unit) =
  assert false

let retrieve_loc_text (_ : Pos.t) : string = assert false
