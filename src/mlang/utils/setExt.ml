module type Elt = sig
  include Set.OrderedType

  val to_yojson : t -> Json.t

  val of_yojson : Json.t -> t Json.err
end

module type T = sig
  include Set.S

  val card : t -> int

  val one : elt -> t

  val from_list : elt list -> t

  val from_marked_list : elt Pos.marked list -> t

  val pp :
    ?sep:string ->
    ?pp_elt:(Format.formatter -> elt -> unit) ->
    unit ->
    Format.formatter ->
    t ->
    unit

  val pp_deriving :
    (Format.formatter -> elt -> unit) -> Format.formatter -> t -> unit

  val to_yojson : t -> Yojson.Safe.t

  val of_yojson : Json.t -> t Json.err
end

module Make =
functor
  (Ord : Set.OrderedType)
  ->
  struct
    include Set.Make (Ord)

    let card = cardinal

    let one = singleton

    let from_list (l : elt list) : t =
      let fold set elt = add elt set in
      List.fold_left fold empty l

    let from_marked_list (l : elt Pos.marked list) : t =
      let fold set elt = add (Pos.unmark elt) set in
      List.fold_left fold empty l

    let pp ?(sep = " ") ?(pp_elt = Pp.nil) (_ : unit) (fmt : Pp.t) (set : t) :
        unit =
      let foldSet elt first =
        let _ =
          if first then Format.fprintf fmt "%a" pp_elt elt
          else Format.fprintf fmt "%s%a" sep pp_elt elt
        in
        false
      in
      ignore (fold foldSet set true)

    let pp_deriving pp_elt fmt t =
      Format.fprintf fmt "{";
      pp ~pp_elt () fmt t;
      Format.fprintf fmt "}"

    let elt_to_yojson _elt = `Null

    let to_yojson t =
      let f t acc = elt_to_yojson t :: acc in
      let l = fold f t [] in
      `List l

    let elt_of_yojson _json =
      Error "Unspecified transformation function in elt_of_yojson"

    let of_yojson json =
      let open Yojson.Safe in
      match json with
      | `List l ->
          let f acc elt =
            match acc with
            | Error _ -> acc
            | Ok set -> (
                let elt = elt_of_yojson elt in
                match elt with
                | Ok elt -> Ok (add elt set)
                | Error error -> Error error)
          in
          let set = List.fold_left f (Ok empty) l in
          set
      | _ ->
          let json = to_string json in
          let msg = Format.asprintf "Could not make a set of json: %s" json in
          Error msg
  end
