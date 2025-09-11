let extract_text_exact_loc (pos : Pos.t) file : string option =
  let sofst = Pos.get_start_ofst pos in
  let eofst = Pos.get_end_ofst pos in
  let len = eofst - sofst in
  (* TODO: Replace '\n' with "\n" in a performant way.*)
  let replace_newline (buf : string) =
    let buf = Bytes.of_string buf in
    for i = 0 to len - 1 do
      let byte = Bytes.get buf i in
      match byte with
      | '\t' -> BytesLabels.set buf i ' '
      | '\n' -> Bytes.set buf i ' '
      | _ -> ()
    done;
    Bytes.to_string buf
  in
  let read file =
    let str = String.sub file sofst len in
    Some (replace_newline str)
  in
  match file with None -> None | Some file -> read file

let open_file_for_text_extraction (pos: Pos.t) =
  let filename = Pos.get_file pos in
  let sline = Pos.get_start_line pos in
  let eline = Pos.get_end_line pos in
  let oc, input_line_opt =
    try
      if filename == Dgfip_m.internal_m then
        let input_line_opt : unit -> string option =
          let curr = ref 0 in
          let src = Dgfip_m.declarations in
          let lng = String.length src in
          let rec new_curr () =
            if !curr < lng then
              if src.[!curr] = '\n' then (
                let res = !curr in
                incr curr;
                Some res)
              else (
                incr curr;
                new_curr ())
            else None
          in
          function
          | () -> (
              let p0 = !curr in
              match new_curr () with
              | None -> None
              | Some p1 -> Some (String.sub Dgfip_m.declarations p0 (p1 - p0)))
        in
        (None, input_line_opt)
      else
        let ocf = open_in filename in
        let input_line_opt () : string option =
          try Some (input_line ocf) with End_of_file -> None
        in
        (Some ocf, input_line_opt)
    with Sys_error _ ->
      Cli.error_print "File not found for displaying position : \"%s\"" filename;
      failwith "Pos error"
  in
  let rec get_lines (n : int) : string list =
    match input_line_opt () with
    | Some line ->
        if n < sline then get_lines (n + 1)
        else if n >= sline && n <= eline then
          line :: get_lines (n + 1)
        else []
    | None -> []
  in
  (match oc with Some ocf -> close_in ocf | _ -> ());
  get_lines
