let log s =
  (* This is to allow compatibility with jsoo in platform_js *)
  let s = Obj.magic s in
  print_endline s
