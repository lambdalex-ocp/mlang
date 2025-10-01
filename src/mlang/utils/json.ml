type t = Yojson.Safe.t

type 'a err = 'a Ppx_deriving_yojson_runtime.error_or

let fmt_err msg json =
  let msg = Format.asprintf "%s%s" msg @@ Yojson.Safe.to_string json in
  Error msg

let of_string = function
  | `String s -> Ok s
  | json -> fmt_err "Could not decode string: " json

let to_string s = `String s

let of_int = function `Int i -> Ok i | json -> fmt_err "Not an int: " json

let to_int i = `Int i
