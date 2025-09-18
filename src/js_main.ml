open M_ir
open Utils
module Interp = M_ir.Mir_interpreter

(** A minimal value for the [Mir.stats] record type defined in [mir.mli]. *)
let minimal_stats : Mir.stats =
  {
    nb_computed = 0;
    nb_base = 0;
    nb_input = 0;
    nb_vars = 0;
    nb_all_tmps = 0;
    nb_all_refs = 0;
    sz_computed = 0;
    sz_base = 0;
    sz_input = 0;
    sz_vars = 0;
    sz_all_tmps = 0;
    nb_all_tables = 0;
    sz_all_tables = 0;
    max_nb_args = 0;
    table_map = IntMap.empty;
  }

(** A minimal value for the [Com.variable_space] record type defined in [com.mli]. *)
let minimal_variable_space : Com.variable_space =
  {
    vs_id = 0;
    vs_name = Mark ("", Pos.none);
    vs_cats = Com.CatVar.LocMap.empty;
    vs_by_default = false;
  }

(** A minimal value of type [Mir.program], referred to as [m_program]. *)
let minimal_m_program : Mir.program =
  {
    program_safe_prefix = "";
    program_applications = StrMap.empty;
    program_var_categories = Com.CatVar.Map.empty;
    program_rule_domains = Com.DomainIdMap.empty;
    program_verif_domains = Com.DomainIdMap.empty;
    program_dict = IntMap.empty;
    program_vars = StrMap.empty;
    program_alias = StrMap.empty;
    program_var_spaces = StrMap.empty;
    program_var_spaces_idx = IntMap.empty;
    program_var_space_def = minimal_variable_space;
    program_event_fields = StrMap.empty;
    program_event_field_idxs = IntMap.empty;
    program_rules = IntMap.empty;
    program_verifs = IntMap.empty;
    program_chainings = StrMap.empty;
    program_errors = StrMap.empty;
    program_functions = StrMap.empty;
    program_targets = StrMap.empty;
    program_main_target = "";
    program_stats = minimal_stats;
  }

open Js_of_ocaml

let () =
  Format.printf "wejifjiowefj@.";
  Js.Unsafe.global##.console##log "hey ho"
(* let ctx = Interp.BigIntDefInterp.empty_ctx minimal_m_program false in *)
(* Js.Unsafe.global##.console##log ctx *)
