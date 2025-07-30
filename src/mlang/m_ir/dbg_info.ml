module Info = struct
  type t = {
    var : Com.Var.t;
    idx_opt : Com.literal option;
    def : string option;
    vval : Com.literal;
  }
  (* The literal option is an optional index in the table. It should be set to Some _ only if the Com.Var.t is a table *)

  let make var idx_opt def vval = { var; idx_opt; def; vval }
end

module Graph = struct
  include Graph.Persistent.Digraph.Abstract (struct
    type t = string
  end)
end

type t = { graph : Graph.t; info : Info.t StrMap.t }

let to_json (fmt: Format.formatter) graph info_map : unit =
  let open Format in
  let open Info in
  let delim = ref "" in
  Format.fprintf fmt "{\"graph\":[";
  let pp_vertex v =
    let name = Graph.V.label v in
    let {var; def; vval; _} = StrMap.find name info_map in
    let var_name = name in
    let is_input = match Com.Var.cat_var_loc var with
    | Com.CatVar.LocInput -> true
    | _ -> false in
    let scope = match var.scope with
    | Tgv _ -> "tgv"
    | Temp _ -> "temp"
    | Ref -> "ref" in
    let attrs = match Com.Var.attrs var with
    | exception _ -> ""
    | attrs ->
        StrMap.fold (fun s _i acc ->
          let wrapped = Format.asprintf {|"%s"|} s in
          wrapped::acc) attrs []
      |> String.concat ", "
      |> Format.asprintf "[%s]"
    in
    let descr = match Com.Var.descr var with
    | exception _ -> ""
    | descr -> Pos.unmark descr in
    let cat = Com.Var.cat var in
    let pp_string fmt s = fprintf fmt "%s" s in
    let pp_none fmt () = fprintf fmt "input var" in
    let pp_opt = pp_print_option ~none:pp_none pp_string in
    let given_back = Com.Var.is_given_back var in
    Format.fprintf fmt
      {|%s@.{"data":{ "name": "%s", "def": "%a", "value": "%a", "input": %b, "scope": "%s", "attrs": %s,
    "descr": "%s", "given_back": "%b", "cat": "%a"}}|}
      !delim var_name pp_opt def Com.format_literal vval is_input scope attrs descr given_back
      Com.CatVar.pp cat;
    (* Small hack to avoid trailing commas *)
    delim := ","
    in
  Format.printf "writing vertices...@.";
  Graph.iter_vertex pp_vertex graph;
  let print_edge (e : Graph.E.t) =
    let src = Graph.E.src e in
    let dst = Graph.E.dst e in
    let src = Graph.V.label src in
    let dst = Graph.V.label dst in
    Format.fprintf fmt {|,@.{"data": {"source": "%s", "target": "%s"}}|} src dst
    in
  Format.printf "writing edges...@.";
  Graph.iter_edges_e print_edge graph;
  Format.fprintf fmt "]}@."
