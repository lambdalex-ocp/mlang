module type Elt = sig
  include Set.OrderedType

  val to_yojson : t -> Json.t

  val of_yojson : Json.t -> t Json.err
end

module type T = sig
  include Map.S

  val card : 'a t -> int

  val one : key -> 'a -> 'a t

  val from_assoc_list : (key * 'a) list -> 'a t

  val union_fst : 'a t -> 'a t -> 'a t

  val union_snd : 'a t -> 'a t -> 'a t

  val pp :
    ?sep:string ->
    ?pp_key:(Pp.t -> key -> unit) ->
    ?assoc:string ->
    (Pp.t -> 'a -> unit) ->
    Pp.t ->
    'a t ->
    unit

  val pp_keys :
    ?sep:string -> ?pp_key:(Pp.t -> key -> unit) -> unit -> Pp.t -> 'a t -> unit

  val to_yojson : ('a -> Yojson.Safe.t) -> 'a t -> Yojson.Safe.t

  val of_yojson : (Json.t -> 'a Json.err) -> Json.t -> 'a t Json.err
end

module Make =
functor
  (Elt : Elt)
  ->
  struct
    include Map.Make (Elt)

    let card = cardinal

    let one = singleton

    let from_assoc_list (l : (key * 'a) list) : 'a t =
      let fold map (k, v) = add k v map in
      List.fold_left fold empty l

    let union_fst map0 map1 =
      let merge_fun _ vo0 vo1 =
        match (vo0, vo1) with
        | None, None -> None
        | None, Some v | Some v, None -> Some v
        | Some v0, Some _v1 -> Some v0
      in
      merge merge_fun map0 map1

    let union_snd map0 map1 = union_fst map1 map0

    let pp ?(sep = "; ") ?(pp_key = Pp.nil) ?(assoc = " => ")
        (pp_val : Pp.t -> 'a -> unit) (fmt : Pp.t) (map : 'a t) : unit =
      let pp_content fmt map =
        let foldMap k v first =
          let _ =
            if first then Format.fprintf fmt "%a%s%a" pp_key k assoc pp_val v
            else Format.fprintf fmt "%s%a%s%a" sep pp_key k assoc pp_val v
          in
          false
        in
        ignore (fold foldMap map true)
      in
      Format.fprintf fmt "{ %a }" pp_content map

    let pp_keys ?(sep = "; ") ?(pp_key = Pp.nil) (_ : unit) (fmt : Pp.t)
        (map : 'a t) : unit =
      pp ~sep ~pp_key ~assoc:"" Pp.nil fmt map

    let to_yojson (of_val : 'a -> Yojson.Safe.t) (t : 'a t) : Yojson.Safe.t =
      let open Yojson.Safe in
      let l = bindings t in
      let l =
        List.map
          (fun (a, b) ->
            let key = Elt.to_yojson a in
            let value = of_val b in
            let obj = `Assoc [ ("key", key); ("value", value) ] in
            obj)
          l
      in
      `List l

    let of_yojson to_val (json : Json.t) =
      match json with
      | `List l ->
          let f acc assoc =
            match assoc with
            | `Assoc [ (_, key); (_, value) ] -> (
                let key = Elt.of_yojson key in
                let value = to_val value in
                match (acc, key, value) with
                | Ok acc, Ok key, Ok value -> Ok (add key value acc)
                | Error e, _, _ | _, Error e, _ | _, _, Error e -> Error e)
            | _ -> Json.fmt_err "Wrong shape: expected `Assoc, got: " assoc
          in
          List.fold_left f (Ok empty) l
      | _ -> Json.fmt_err "Could not parse map: " json
  end
