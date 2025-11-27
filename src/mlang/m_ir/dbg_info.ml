module Origin = struct
  type code = Rule of int | Declared | Input | Target of string | Const

  type t = { filename : string; sline : int; eline : int; code_orig : code }

  let make filename sline eline code_orig =
    { filename; sline; eline; code_orig }

  let make_from_pos pos code_orig =
    let filename = Pos.get_file pos in
    let sline = Pos.get_start_line pos in
    let eline = Pos.get_end_line pos in
    { filename; sline; eline; code_orig }

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
      {|"origin": {"code_orig": "%s", "file": "%s", "sline": %d, "eline": %d }|}
      code_orig origin.filename origin.sline origin.eline
end

module Info = struct
  type t = {
    name : string;
    var : Com.Var.t;
    value : Com.literal;
    origin : Origin.t;
  }
  (* We've removed idx_opt, it may be needed for tables. *)

  let make name var value origin = { name; var; value; origin }
end

module Tick = struct
  include Int

  let inner = ref (-1)

  let tick () =
    incr inner;
    !inner

  module Map = struct
    include IntMap
  end
end

module Vertex = struct
  type kind = Literal | Var

  include Tick

  (* Invariant (to be verified): All ticks are different *)
  type t = Tick.t

  (* This feels weird, but String.hash was introduced in 5.0 *)
  let hash t = Hashtbl.hash t
end

module Graph = Graph.Persistent.Digraph.Concrete (Vertex)

module Const = struct
  type t = { name : string; value : Com.literal; origin : Origin.t }

  let make name value fname sline eline =
    let origin = Origin.make fname sline eline Const in
    { name; value; origin }

  let make_from_pos name value pos =
    let origin = Origin.make_from_pos pos Const in
    {name;value;origin}
end

module TickMap = struct
  include StrMap

  let find name map =
    match StrMap.find_opt name map with
    | None ->
        let msg =
          if StrMap.card map > 100 then
            Format.asprintf "could not find %s in tick_map (too long).@." name
          else
            Format.asprintf "could not find %s in tick_map %a.@." name
              (StrMap.pp (fun fmt -> Format.fprintf fmt "%d"))
              map
        in
        raise @@ Failure msg
    | Some tick -> tick
end

type t = {
  graph : Graph.t;
  infos : Info.t IntMap.t;
  consts : Const.t IntMap.t;
  literals : string IntMap.t;
  ledger : Tick.t StrMap.t;
}

let empty =
  {
    graph = Graph.empty;
    infos = IntMap.empty;
    consts = IntMap.empty;
    literals = IntMap.empty;
    ledger = StrMap.empty;
  }

let to_json (fmt : Format.formatter) info : unit =
  let open Format in
  let open Info in
  let open Const in
  let open Vertex in
  let delim = ref "" in
  Format.fprintf fmt "{\"graph\":[";
  let pp_vertex v =
    let var = Graph.V.label v in
    Format.fprintf fmt {|%s@.{"data": %d}|} !delim var;
    (* (match var.kind with *)
    (* | Literal -> *)
    (*     let obj = Format.asprintf {|{"kind": "lit", "value": %S}|} var.name in *)
    (*     Format.fprintf fmt {|%s@.{"data": %s}|} !delim obj *)
    (* | Var -> *)
    (*     let obj = Format.asprintf {|{"name": "%s"}|} var.name in *)
    (*     Format.fprintf fmt {|%s@.{"data": %s}|} !delim obj); *)
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
    Format.fprintf fmt {|,@.{"data": {"source": "%d", "target": "%d"}}|} src dst
  in
  Format.printf "writing edges...@.";
  Graph.iter_edges_e print_edge info.graph;
  let print_info tick { name; var; value; origin; _ } =
    let is_input = match Com.Var.cat_var_loc var with
    | Com.CatVar.LocInput -> true
    | exception Failure _
    | _ -> false in
    let origin = Origin.to_json origin in
    Format.fprintf fmt
      {|%s@."%d": {"name": %S, "value": "%a", "is_input": %b, %s}|} !delim tick
      name Com.format_literal value is_input origin;
    delim := ","
  in
  Format.fprintf fmt "],@.";
  Format.printf "writing info...@.";
  delim := "";
  Format.fprintf fmt {|"info": {@.|};
  IntMap.iter print_info info.infos;
  let print_const id const =
    Format.printf "Printing consts!!!!@.";
    let origin = Origin.to_json const.origin in
    Format.fprintf fmt
      {|%s@."%d": {"name": %S, "value": "%a", "kind": "const", %s}|} !delim id
      const.name Com.format_literal const.value origin;
    delim := ","
  in
  IntMap.iter print_const info.consts;
  let print_lit id lit =
    Format.fprintf fmt {|%s@."%d": {"name": %S}|} !delim id lit;
    delim := ","
  in
  IntMap.iter print_lit info.literals;
  Format.fprintf fmt "}}@."

let write_json_file filename info =
  let filename = filename ^ ".json" in
  let oc = open_out filename in
  let fmt = Format.formatter_of_out_channel oc in
  Format.fprintf fmt "%a@." to_json info
