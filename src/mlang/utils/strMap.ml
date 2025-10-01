include MapExt.Make (struct
  include String

  let to_yojson = Json.to_string

  let of_yojson = Json.of_string
end)

module type T = MapExt.T with type key = string

let pp ?(sep = "; ") ?(pp_key = Format.pp_print_string) ?(assoc = " => ")
    (pp_val : Format.formatter -> 'a -> unit) (fmt : Format.formatter)
    (map : 'a t) : unit =
  pp ~sep ~pp_key ~assoc pp_val fmt map

let keySet t = fold (fun k _ s -> StrSet.add k s) t StrSet.empty

let to_yojson of_data t = to_yojson of_data t

let of_yojson to_data t = of_yojson to_data t
