val extract_text_exact_loc : Pos.t -> string option -> string option
(** Given a position, extract the lines specified in the position
    from the specified file. *)

val open_file_for_text_extraction : Pos.t -> int -> string list
