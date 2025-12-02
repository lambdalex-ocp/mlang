(* This function should be the same independent of platform *)
let extract_text_exact_loc (pos : Pos.t) (file : string option) : string option
    =
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

let open_file_for_text_extraction (_ : Pos.t) (_ : int) : string list =
  assert false
