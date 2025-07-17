(*This program is free software: you can redistribute it and/or modify it under
  the terms of the GNU General Public License as published by the Free Software
  Foundation, either version 3 of the License, or (at your option) any later
  version.

  This program is distributed in the hope that it will be useful, but WITHOUT
  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
  FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

  You should have received a copy of the GNU General Public License along with
  this program. If not, see <https://www.gnu.org/licenses/>. *)

module G = Dbggraph_types

let rec subgraph_depth n (g : G.t) (v : G.vertex) =
  let module O = Graph.Oper.P (G) in
  match n with
  | 0 -> G.add_vertex G.empty v
  | n ->
      G.fold_succ
        (fun v2 sg ->
          let comp = subgraph_depth (n - 1) g v2 in
          G.add_edge (O.union comp sg) v v2)
        g v (G.add_vertex G.empty v)

let to_dot (fmt : Format.formatter) (g : G.t) : unit =
  let module GPr = Graph.Graphviz.Dot (struct
    include G

    let graph_attributes (_ : t) = []

    let default_vertex_attributes (_ : t) = [ `Style `Filled ]

    let vertex_name (v : vertex) =
      let vhash = G.V.hash v in
      Format.asprintf "%d" vhash

    let vertex_attributes (v : vertex) =
      let var = Node.get_var @@ V.label v in
      let var_name = Pos.unmark var.name in
      [
        `Label (Format.asprintf "%a" G.pp_vertex v);
        `Shape `Box;
        `Comment var_name;
        `Style `Filled;
         `Fillcolor
           (match Com.Var.cat_var_loc var with
           | Some Com.CatVar.LocInput -> 0xadd8e6
           | _ -> if Com.Var.is_given_back var then 0xffa500 else 0xffffff)
      ]

    let get_subgraph (_ : vertex) = None

    let default_edge_attributes (_ : t) = []

    let edge_attributes (_ : edge) = []
  end) in
  GPr.fprint_graph fmt g

let to_json (fmt: Format.formatter) (g : G.t) : unit =
  let open Format in
  let delim = ref "" in
  Format.fprintf fmt "{\"graph\":[";
  let pp_vertex v =
    let G.Node.{var; def; vval; _} = G.V.label v in
    let var_name = Pos.unmark var.name in
    let is_input = match Com.Var.cat_var_loc var with
    | Some Com.CatVar.LocInput -> true
    | _ -> false in
    let pp_string fmt s = fprintf fmt "%s" s in
    let pp_none fmt () = fprintf fmt "input var" in
    let pp_opt = pp_print_option ~none:pp_none pp_string in
    Format.fprintf fmt
      {|%s@.{"data":{ "name": "%s", "def": "%a", "value": "%a", "input": %b}}|}
      !delim var_name pp_opt def Com.format_literal vval is_input;
    (* Small hack to avoid trailing commas *)
    delim := ","
    in
  Format.printf "writing vertices...@.";
  G.iter_vertex pp_vertex g;
  let print_edge (e : G.E.t) =
    let src = G.E.src e in
    let dst = G.E.dst e in
    let src = G.var_name_of_vertex src in
    let dst = G.var_name_of_vertex dst in
    Format.fprintf fmt {|,@.{"data": {"source": "%s", "target": "%s"}}|} src dst
    in
  Format.printf "writing edges...@.";
  G.iter_edges_e print_edge g;
  Format.fprintf fmt "]}@."
  (* Format.fprintf fmt "@.export default graph;@." *)

let calc_subgraph dbg ctxd =
  let focus = !Cli.dbgraph_var_focus in
  let subgraph = match focus with
  | None -> dbg
  | Some v ->
      let v = StrMap.find v ctxd in
      let subgraph = subgraph_depth !Cli.dbgraph_depth dbg v in
      Format.printf "subdbg : %d vertices -- %d edges@." (G.nb_vertex subgraph)
      (G.nb_edges subgraph);
    subgraph in
  subgraph

let write_file filename pp subgraph =
  fun () ->
    let oc = open_out filename in
    let fmt = Format.formatter_of_out_channel oc in
    Format.fprintf fmt "%a@." pp subgraph;
    close_out oc

let output_dot_eval_program (dbg : G.t) (ctxd : G.ctx_dbg) (file : string) :
  unit -> unit =
    let subgraph = calc_subgraph dbg ctxd in
    let filename = file ^ ".dot" in
    write_file filename to_dot subgraph

let output_json_eval_program dbg ctxd file =
  Format.printf "calculating subgraph...@.";
  let subgraph = calc_subgraph dbg ctxd in
  let filename = file ^ ".json" in
  write_file filename to_json subgraph
  (* G.iter_vertex
     (fun v ->
       let var, vdef, _vval = G.V.label v in
match vdef with
       | None when Com.Var.cat_var_loc var = Some Com.CatVar.LocInput ->
           Cli.warning_print "weird stuff on %s@." (Pos.unmark var.name)
  | _ -> ())
     dbg; *)


