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
    ?sep:string -> ?pp_elt:(Pp.t -> elt -> unit) -> unit -> Pp.t -> t -> unit

  val pp_deriving :
    (Format.formatter -> elt -> unit) -> Format.formatter -> t -> unit

  val to_yojson : t -> Yojson.Safe.t

  val of_yojson : Yojson.Safe.t -> t Json.err
end

module Make : functor (Ord : Elt) -> T with type elt = Ord.t
