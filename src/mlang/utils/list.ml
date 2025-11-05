include Stdlib.List

let map f l =
  let rec map_aux acc = function
    | [] -> rev acc
    | x :: xs -> map_aux (f x :: acc) xs
  in
  map_aux [] l
