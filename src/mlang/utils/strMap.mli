module type T = MapExt.T with type key = string

include T

val keySet : 'a t -> StrSet.t

val to_yojson : ('a -> Yojson.Safe.t) -> 'a t -> Yojson.Safe.t

val of_yojson : (Yojson.Safe.t -> 'a Json.err) -> Yojson.Safe.t -> 'a t Json.err
