(* Copyright Inria, contributors: Raphaël Monat <raphael.monat@lip6.fr> (2019)

   This program is free software: you can redistribute it and/or modify it under
   the terms of the GNU General Public License as published by the Free Software
   Foundation, either version 3 of the License, or (at your option) any later
   version.

   This program is distributed in the hope that it will be useful, but WITHOUT
   ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
   FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
   details.

   You should have received a copy of the GNU General Public License along with
   this program. If not, see <https://www.gnu.org/licenses/>. *)

let find_var_of_name (p : Mir.program) (name : string Pos.marked) : Com.Var.t =
  try StrMap.find (Pos.unmark name) p.program_vars
  with Not_found -> (
    let name = Mir.find_var_name_by_alias p name in
    try StrMap.find name p.program_vars
    with Not_found ->
      Cli.error_print "Variable inconnue: %s" name;
      raise (Errors.StructuredError ("Fichier de test incorrect", [], None)))

type instance = {
  label : string;
  vars : Com.literal Com.Var.Map.t;
  events : (Com.literal, Com.Var.t) Com.event_value StrMap.t list;
  expectedVars : float StrMap.t;
  expectedAnos : StrSet.t;
}

let to_MIR_function_and_inputs (program : Mir.program) (t : Irj_ast.irj_file) :
    instance list =
  let vars =
    let map_init =
      try
        let ancsded = find_var_of_name program (Pos.without "V_ANCSDED") in
        let ancsded_val = Com.Float (float_of_int (!Config.income_year + 1)) in
        Com.Var.Map.one ancsded ancsded_val
      with _ -> Com.Var.Map.empty
    in
    List.fold_left
      (fun in_f (Pos.Mark (var, var_pos), Pos.Mark (value, _value_pos)) ->
        let var = find_var_of_name program (Pos.mark var var_pos) in
        let lit =
          match value with
          | Irj_ast.I i -> Com.Float (float i)
          | F f -> Com.Float f
        in
        Com.Var.Map.add var lit in_f)
      map_init t.prim.entrees
  in
  let eventsList rappels =
    let from_var vn =
      match StrMap.find_opt vn program.program_alias with
      | Some var -> Com.RefVar var
      | None -> (
          match StrMap.find_opt vn program.program_vars with
          | Some var -> Com.RefVar var
          | None ->
              Cli.error_print "Variable inconnue: %s" vn;
              let msg = "Fichier de test incorrect" in
              raise (Errors.StructuredError (msg, [], None)))
    in
    let fromDirection = function
      | "R" -> Com.Numeric (Com.Float 0.0)
      | "C" -> Com.Numeric (Com.Float 1.0)
      | "M" -> Com.Numeric (Com.Float 2.0)
      | "P" -> Com.Numeric (Com.Float 3.0)
      | s ->
          Cli.error_print "Sens du rappel: %s, devrait être parmi R, C, M et P"
            s;
          raise (Errors.StructuredError ("Fichier de test incorrect", [], None))
    in
    let toNum p = Com.Numeric (Com.Float (float p)) in
    let optToNum = function
      | Some p -> Com.Numeric (Com.Float (float p))
      | None -> Com.Numeric Com.Undefined
    in
    let toEvent (rappel : Irj_ast.rappel) =
      StrMap.empty
      |> StrMap.add "numero" (toNum rappel.event_nb)
      |> StrMap.add "rappel" (toNum rappel.rappel_nb)
      |> StrMap.add "code" (from_var rappel.variable_code)
      |> StrMap.add "montant" (toNum rappel.change_value)
      |> StrMap.add "sens" (fromDirection rappel.direction)
      |> StrMap.add "penalite" (optToNum rappel.penalty_code)
      |> StrMap.add "base_tl" (optToNum rappel.base_tolerance_legale)
      |> StrMap.add "date" (toNum rappel.month_year)
      |> StrMap.add "2042_rect" (optToNum rappel.decl_2042_rect)
    in
    List.map toEvent rappels
  in
  let expVars vars_init =
    let fold res (Pos.Mark (var, _), Pos.Mark (value, _)) =
      let fVal = match value with Irj_ast.I i -> float i | Irj_ast.F f -> f in
      StrMap.add var fVal res
    in
    List.fold_left fold StrMap.empty vars_init
  in
  let expAnos anos_init =
    let fold res ano = StrSet.add ano res in
    List.fold_left fold StrSet.empty (List.map Pos.unmark anos_init)
  in
  let set_trait f vars =
    try
      let ind_trait = find_var_of_name program (Pos.without "V_IND_TRAIT") in
      Com.Var.Map.add ind_trait (Com.Float f) vars
    with _ -> vars
  in
  match t.rapp with
  | None ->
      let vars = set_trait 4.0 vars in
      let expectedVars = expVars t.prim.resultats_attendus in
      let expectedAnos = expAnos t.prim.controles_attendus in
      [ { label = "primitif"; vars; events = []; expectedVars; expectedAnos } ]
  | Some rapp ->
      let corr =
        let vars = set_trait 5.0 vars in
        let events = eventsList rapp.entrees_rappels in
        let expectedVars = expVars rapp.resultats_attendus in
        let expectedAnos = expAnos rapp.controles_attendus in
        { label = "correctif"; vars; events; expectedVars; expectedAnos }
      in
      let expectedVars = expVars t.prim.resultats_attendus in
      let expectedAnos = expAnos t.prim.controles_attendus in
      if not (StrMap.is_empty expectedVars && StrSet.is_empty expectedAnos) then
        let vars = set_trait 4.0 vars in
        let prim =
          { label = "primitif"; vars; events = []; expectedVars; expectedAnos }
        in
        [ prim; corr ]
      else [ corr ]

exception InterpError of int

let check_test (program : Mir.program) (test_input : Irj_file.input)
    (dep_graph_file : string option) (value_sort : Config.value_sort)
    (round_ops : Config.round_ops) : Dbg_info.t list option =
  let check_vars exp vars =
    let test_error_margin = 0.01 in
    let fold vname f nb =
      let f' =
        let var =
          match StrMap.find_opt vname program.program_vars with
          | Some var -> var
          | None ->
              Cli.error_print "Variable inconnue: %s" vname;
              raise
                (Errors.StructuredError ("Fichier de test incorrect", [], None))
        in
        match Com.Var.Map.find_opt var vars with
        | Some (Com.Float f') -> f'
        | _ -> 0.0
      in
      if abs_float (f -. f') > test_error_margin then (
        Cli.error_print "KO | %s expected: %f - evaluated: %f" vname f f';
        nb + 1)
      else nb
    in
    StrMap.fold fold exp 0
  in
  let check_anos exp errSet =
    let rais =
      let fold e res = StrSet.add (Pos.unmark e.Com.Error.name) res in
      Com.Error.Set.fold fold errSet StrSet.empty
    in
    let missAnos = StrSet.diff exp rais in
    let unexAnos = StrSet.diff rais exp in
    StrSet.iter (Cli.error_print "KO | missing error: %s") missAnos;
    StrSet.iter (Cli.error_print "KO | unexpected error: %s") unexAnos;
    StrSet.cardinal missAnos + StrSet.cardinal unexAnos
  in
  let dbg_warning = !Config.warning_flag in
  let dbg_time = !Config.display_time in
  Config.warning_flag := false;
  Config.display_time := false;
  Cli.debug_print "Parsing %s..."
    (match test_input with Filename s -> s | Contents _ -> "given contents");
  let t = Irj_file.parse_file test_input in
  Cli.debug_print "Running test %s..." t.nom;
  let insts = to_MIR_function_and_inputs program t in
  let rec check = function
    | [] -> []
    | inst :: insts ->
        let dbg_flag = Option.is_some dep_graph_file in
        Cli.debug_print "Executing program %s" inst.label;
        (* Cli.debug_print "Combined Program (w/o verif conds):@.%a@."
           Format_bir.format_program program; *)
        let varMap, anoSet, dbg_info =
          Mir_interpreter.evaluate_program program inst.vars inst.events
            value_sort round_ops dbg_flag
        in
        let dbg_info = (match (dep_graph_file, dbg_info) with
        | None, None -> None
        | Some filename, Some dbg_info ->
            (* Add the input variables value - But only if they have not been set
               (not set == origin = Declared) *)
            let add_to_map var lit map =
              let name = Com.Var.name_str var in
              StrMap.update name
                (function
                  | Some
                      Dbg_info.Info.{ origin = { code_orig = Declared; _ }; _ }
                  | None ->
                      let def = Some "input-set" in
                      let rule_id = Dbg_info.Origin.Input in
                      let file = "test_interpreter.ml" in
                      let origin = Dbg_info.Origin.make file 0 rule_id in
                      let info = Dbg_info.Info.make var def lit origin in
                      Some info
                  | oth -> oth)
                map
            in
            let info = Com.Var.Map.fold add_to_map inst.vars dbg_info.info in
            let dbg_info = { dbg_info with info } in
            (match !Config.platform with
            | Binary -> Dbg_info.write_json_file filename dbg_info
            | Web _ -> ());
            Some dbg_info
        | _ -> assert false) in
        let nbErrs =
          check_vars inst.expectedVars varMap
          + check_anos inst.expectedAnos anoSet
        in
        if nbErrs <= 0 then (
          Cli.debug_print "OK!";
          dbg_info :: check insts)
        else (
          Cli.debug_print "KO!";
          raise (InterpError nbErrs))
  in
  let infos = check insts in
  let clean_infos = List.filter_map (fun i -> i) infos in
  Config.warning_flag := dbg_warning;
  Config.display_time := dbg_time;
  Some clean_infos
