module type Printer = sig
  val var_info_print : ('a, Format.formatter, unit, unit) format4 -> 'a

  val debug_print :
    ?endline:string -> ('a, Format.formatter, unit, unit) format4 -> 'a

  val warning_print : ('a, Format.formatter, unit, unit) format4 -> 'a

  val error_print : ('a, Format.formatter, unit, unit) format4 -> 'a

  val result_print : ('a, Format.formatter, unit, unit) format4 -> 'a
end
