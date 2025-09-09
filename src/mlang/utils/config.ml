
type value_sort =
  | RegularFloat
  | MPFR of int (* bitsize of the floats *)
  | BigInt of int (* precision of the fixed point *)
  | Interval
  | Rational

type round_ops = RODefault | ROMulti | ROMainframe of int
(* size of type long, either 32 or 64 *)

type backend = Dgfip_c | UnknownBackend

type execution_mode =
  | SingleTest of string
  | MultipleTests of string
  | Extraction

type files = NonEmpty of string list

(* Flags inherited from the old compiler *)
type dgfip_options_flags = {
  (* -m *) annee_revenu : int;
  (* -P *) flg_correctif : bool;
  (* flg_correctif true by default, -P makes it false *)
  (* -R *) flg_iliad : bool;
  (* also implied by "iliad" in !Cli.application_names; disabled by -U *)
  (* -R *) flg_pro : bool;
  (* also implied by "pro" in !Cli.application_names; disabled by -U *)
  (* -U *) flg_cfir : bool;
  (* disabled by -R *)
  (* -b *) flg_gcos : bool;
  (* -b0 and -b1 ; disabled by -U and -R *)
  (* -b *) flg_tri_ebcdic : bool;
  (* -b1 only *)
  (* -s *) flg_short : bool;
  (* -r *) flg_register : bool;
  (* -O *) flg_optim_min_max : bool;
  (* -X *) flg_extraction : bool;
  (* -D *) flg_genere_libelle_restituee : bool;
  (* -S *) flg_controle_separe : bool;
  (* -I *) flg_controle_immediat : bool;
  (* unused *)
  (* -o *) flg_overlays : bool;
  (* -Z *) flg_colors : bool;
  (* -L *) flg_ticket : bool;
  (* -t *) flg_trace : bool;
  (* -g *) flg_debug : bool;
  (* also implied by -t *)
  (* -k *) nb_debug_c : int;
  (* -x *)
  xflg : bool;
      (* Flags to deal with in a particular way : -c compilation mode -l link
         mode -v specify the variable file (tgv.m) -e specify the error file
         (err.m) *)
      (* Other flags, not used in makefiles -h dir_var_h -i flg_ident
         -K flg_optim_cte -G flg_listing (+genere_cre = FALSE) -p
         flag_phase -f flg_ench_init -E cvt_file -g flg_debug -a flg_api -T
         flg_trace_irdata *)
}


let dgfip_options_default_flags =
  {
    annee_revenu = 1991;
    flg_correctif = true;
    flg_iliad = false;
    flg_pro = false;
    flg_cfir = false;
    flg_gcos = false;
    flg_tri_ebcdic = false;
    flg_short = false;
    flg_register = false;
    flg_optim_min_max = false;
    flg_extraction = false;
    flg_genere_libelle_restituee = false;
    flg_controle_separe = false;
    flg_controle_immediat = false;
    flg_overlays = false;
    flg_colors = false;
    flg_ticket = false;
    flg_trace = false;
    flg_debug = false;
    nb_debug_c = 0;
    xflg = false;
  }



let get_files = function NonEmpty l -> l

(* This feels weird to put here, but by construction it should not happen.*)
let source_files : files ref = ref (NonEmpty [])

let application_names : string list ref = ref []

let without_dgfip_m = ref false

let dbg_graph_file : string ref = ref "dbg_graph.dot"

let verify_flag = ref false

let debug_flag = ref false

let var_info_flag = ref false

let var_info_debug : string option list ref = ref []

let warning_flag = ref true

let no_print_cycles_flag = ref false

let display_time = ref false

let output_file = ref ""

let optimize_unsafe_float = ref false

let m_clean_calls = ref false

let value_sort = ref RegularFloat

let round_ops = ref RODefault

let backend = ref UnknownBackend

let dgfip_test_filter = ref false

let mpp_function = ref ""

let dgfip_flags = ref dgfip_options_default_flags

let execution_mode = ref Extraction

(* Default value for the epsilon slack when comparing things in the
   interpreter *)
let comparison_error_margin = ref 0.000001

let income_year = ref 0

let dbgraph_var_focus = ref None


