module type T = SetExt.T with type elt = string

include SetExt.Make (struct include String
  let to_yojson = Json.to_string
  let of_yojson = Json.of_string
end)

let pp ?(sep = " ") ?(pp_elt = Format.pp_print_string) (_ : unit)
    (fmt : Format.formatter) (set : t) : unit =
  pp ~sep ~pp_elt () fmt set

let elt_to_yojson = Json.to_string

let to_yojson t =
  to_yojson t

let elt_of_yojson = Json.of_string

let of_yojson json =
  of_yojson json
