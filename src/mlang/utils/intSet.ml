module type T = SetExt.T with type elt = int

include SetExt.Make (struct 
  include Int 
  let of_yojson = Json.of_int
  let to_yojson = Json.to_int
end)

let pp ?(sep = " ") ?(pp_elt = Format.pp_print_int) (_ : unit)
    (fmt : Format.formatter) (set : t) : unit =
  pp ~sep ~pp_elt () fmt set
