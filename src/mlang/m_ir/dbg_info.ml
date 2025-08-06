module Info = struct
  type t = { var : Com.Var.t; def : string option; vval : Com.literal }
  (* We've removed idx_opt, it may be needed for tables. *)

  let make var def vval = { var; def; vval }
end

module Graph = struct
  include Graph.Persistent.Digraph.Abstract (struct
    type t = string
  end)
end

type t = { graph : Graph.t; info : Info.t StrMap.t }

let empty = { graph = Graph.empty; info = StrMap.empty }

let to_json (fmt : Format.formatter) info : unit =
  let open Format in
  let open Info in
  let delim = ref "" in
  let print_info var_name {var; def; vval; _} =
    let scope = match var.scope with
    | Tgv _ -> "tgv"
    | Temp _ -> "temp"
    | Ref -> "ref" in
    let tgv_details = match var.scope with
    | Temp _ | Ref -> ""
    | Tgv _ ->
        let is_input =
          match Com.Var.cat_var_loc var with
          | Com.CatVar.LocInput -> true
          | _ -> false in
        let cat = Com.Var.cat var in
        let attrs =
          let wrap s _ acc =
            let wrapped = Format.asprintf {|"%s"|} s in
            wrapped :: acc in
          StrMap.fold wrap (Com.Var.attrs var) []
          |> String.concat ", " |> Format.asprintf "[%s]"
        in
        let given_back = Com.Var.is_given_back var in
        let descr = Pos.unmark @@ Com.Var.descr var
          |> Re.Str.global_replace (Re.Str.regexp "	") "  " in
        let str =
          Format.asprintf {|, "tgv_details": {
      "cat": "%a", "is_input": %b, "given_back": %b, "attrs": %s, "descr": "%s"
    }|}
          Com.CatVar.pp cat is_input given_back attrs descr in 
        str
    in
    let pp_string fmt s = fprintf fmt "%s" s in
    let pp_none fmt () = fprintf fmt "" in
    let pp_opt = pp_print_option ~none:pp_none pp_string in
    Format.asprintf
      {|{ "name": "%s", "def": "%a", "value": "%a", "scope": "%s" %s}|}
      var_name pp_opt def Com.format_literal vval scope tgv_details in
  Format.fprintf fmt "{\"graph\":[";
  let pp_vertex v =
        let var_name = Graph.V.label v in
    let dbg_info = StrMap.find_opt var_name info.info in
    let obj = match dbg_info with
    | None -> Format.asprintf {|{"name": "%s"}|} var_name
    | Some info -> print_info var_name info in
    Format.fprintf fmt
      {|%s@.{"data": %s}|} !delim obj;
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
  Format.fprintf fmt "]}@."

let write_json_file filename info =
  let filename = filename ^ ".json" in
  let oc = open_out filename in
  let fmt = Format.formatter_of_out_channel oc in
  Format.fprintf fmt "%a@." to_json info
