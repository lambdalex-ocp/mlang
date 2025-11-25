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

  let make name value fname line =
    let origin = Origin.make fname line Const in
    { name; value; origin }
end

module TickMap = struct
  include StrMap

  let find name map =
    match StrMap.find_opt name map with
    | None ->
        raise
        @@ Failure
             (Format.asprintf "could not find %s in tick_map %a" name
                (StrMap.pp (fun fmt -> Format.fprintf fmt "%d"))
                map)
    | Some tick -> tick
end

type t = {
  graph : Graph.t;
  infos : Info.t IntMap.t;
  consts : Const.t IntMap.t;
  literals: string IntMap.t;
  tick_name_map : Tick.t StrMap.t;
}

let empty =
  {
    graph = Graph.empty;
    infos = IntMap.empty;
    consts = IntMap.empty;
    literals = IntMap.empty;
    tick_name_map = StrMap.empty;
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
            |> String.map (fun c -> if c == '\t' then ' ' else c)
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
    let origin = Origin.to_json origin in
    Format.fprintf fmt
      {|%s"%d": {"name": %S, "value": "%a", "scope": "%s" %s %s}|} !delim tick
      name Com.format_literal value scope origin tgv_details;
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
    Format.fprintf fmt {|%s@."%d": {"value": "%a", "kind": "const" %s}|} !delim
      id Com.format_literal const.value origin;
    delim := ","
  in
  IntMap.iter print_const info.consts;
  let print_lit id lit =
    Format.fprintf fmt {|%s@."%d": %S|} !delim id lit;
    delim := "," in
  IntMap.iter print_lit info.literals;
  Format.fprintf fmt "}}@."

let write_json_file filename info =
  let filename = filename ^ ".json" in
  let oc = open_out filename in
  let fmt = Format.formatter_of_out_channel oc in
  Format.fprintf fmt "%a@." to_json info
