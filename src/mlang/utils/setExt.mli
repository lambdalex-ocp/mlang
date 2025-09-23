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
end

module Make : functor (Ord : Set.OrderedType) -> T with type elt = Ord.t
