include List

let flatten_tail_rec l =
  List.fold_left
    (fun acc l -> List.fold_left (fun acc e -> e :: acc) acc l)
    [] l
  |> List.rev
