module Origin = struct
  type code = Rule of int | Declared | Input | Target of string | Const

  type t = { filename : string; line : int; code_orig : code }

  let make filename line code_orig = { filename; line; code_orig }

  let to_json origin =
    let code_orig =
      match origin.code_orig with
      | Rule i -> Format.asprintf "%d" i
      | Input -> "input"
      | Declared -> "Declared"
      | Target s -> Format.asprintf "target-%s" s
      | Const -> "const"
    in
    Format.asprintf
      {|, "origin": {"code_orig": "%s", "file": "%s", "line": %d }|} code_orig
      origin.filename origin.line
end

module Info = struct
  type t = {
    var : Com.Var.t;
    def : string option;
    vval : Com.literal;
    origin : Origin.t;
  }
  (* We've removed idx_opt, it may be needed for tables. *)

  let make var def vval origin = { var; def; vval; origin }
end

module Graph = Graph.Persistent.Digraph.Concrete (struct
  include String

  (* This feels weird, but String.hash was introduced in 5.0 *)
  let hash = Hashtbl.hash
end)

module Const = struct
  type t = { value : Com.literal; origin : Origin.t }

  let make value fname line =
    let origin = Origin.make fname line Const in
    { value; origin }
end

type t = { graph : Graph.t; info : Info.t StrMap.t; consts : Const.t StrMap.t }

let empty = { graph = Graph.empty; info = StrMap.empty; consts = StrMap.empty }

let to_json (fmt : Format.formatter) info : unit =
  let open Format in
  let open Info in
  let open Const in
  let delim = ref "" in
  Format.fprintf fmt "{\"graph\":[";
  let pp_vertex v =
    let var_name = Graph.V.label v in
    let obj = Format.asprintf {|{"name": "%s"}|} var_name in
    Format.fprintf fmt {|%s@.{"data": %s}|} !delim obj;
    (* Small hack to avoid trailing commas *)
    delim := ","
  in
  Format.printf "writing vertices...@.";
  Graph.iter_vertex pp_vertex info.graph;
  let print_edge (e : Graph.E.t) =
    let src = Graph.E.src e in
    let dst = Graph.E.dst e in
    let src = Graph.V.label src in
    let dst = Graph.V.label dst in
    Format.fprintf fmt {|,@.{"data": {"source": "%s", "target": "%s"}}|} src dst
  in
  Format.printf "writing edges...@.";
  Graph.iter_edges_e print_edge info.graph;
  let print_info var_name { var; def; vval; origin; _ } =
    let scope =
      match var.scope with Tgv _ -> "tgv" | Temp _ -> "temp" | Ref -> "ref"
    in
    let tgv_details =
      match var.scope with
      | Temp _ | Ref -> ""
      | Tgv _ ->
          let is_input =
            match Com.Var.cat_var_loc var with
            | Com.CatVar.LocInput -> true
            | _ -> false
          in
          let cat = Com.Var.cat var in
          let attrs =
            let wrap s _ acc =
              let wrapped = Format.asprintf {|"%s"|} s in
              wrapped :: acc
            in
            StrMap.fold wrap (Com.Var.attrs var) []
            |> String.concat ", " |> Format.asprintf "[%s]"
          in
          let given_back = Com.Var.is_given_back var in
          let descr =
            Pos.unmark @@ Com.Var.descr var
            |> Re.Str.global_replace (Re.Str.regexp "\t") "  "
          in
          let str =
            Format.asprintf
              {|, "tgv_details": {
      "cat": "%a", "is_input": %b, "given_back": %b, "attrs": %s, "descr": "%s"
    }|}
              Com.CatVar.pp cat is_input given_back attrs descr
          in
          str
    in
    let pp_string fmt s = fprintf fmt "%s" s in
    let pp_none fmt () = fprintf fmt "" in
    let pp_opt = pp_print_option ~none:pp_none pp_string in
    let origin = Origin.to_json origin in
    Format.fprintf fmt
      {|%s"%s": {"def": "%a", "value": "%a", "scope": "%s" %s %s}|} !delim
      var_name pp_opt def Com.format_literal vval scope origin tgv_details;
    delim := ","
  in
  Format.fprintf fmt "],@.";
  Format.printf "writing info...@.";
  delim := "";
  Format.fprintf fmt {|"info": {@.|};
  StrMap.iter print_info info.info;
  let print_const id const =
    let origin = Origin.to_json const.origin in
    Format.fprintf fmt {|%s@."%s": {"value": "%a", "kind": "const" %s}|} !delim
      id Com.format_literal const.value origin;
    delim := ","
  in
  StrMap.iter print_const info.consts;
  Format.fprintf fmt "}}@."

let write_json_file filename info =
  let filename = filename ^ ".json" in
  let oc = open_out filename in
  let fmt = Format.formatter_of_out_channel oc in
  Format.fprintf fmt "%a@." to_json info
