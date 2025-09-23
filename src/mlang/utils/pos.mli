(* Copyright (C) 2019-2021 Inria, contributor: Denis Merigoux
   <denis.merigoux@inria.fr>

   Licensed under the Apache License, Version 2.0 (the "License"); you may not
   use this file except in compliance with the License. You may obtain a copy of
   the License at

   http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
   WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
   License for the specific language governing permissions and limitations under
   the License. *)

(** A position in the source code is a file, as well as begin and end location
    of the form col:line *)

(** {2 Source code position} *)

type ofst = { sofst : int; eofst : int }

type t [@@deriving show]

val make : string -> Lexing.position * Lexing.position -> ofst -> t

val make_between : t -> t -> t

val format_short : Format.formatter -> t -> unit

val format_gnu : Format.formatter -> t -> unit
(** Respects https://www.gnu.org/prep/standards/standards.html#Formatting-Error-Messages *)

val format : Format.formatter -> t -> unit

(** Everything related to the source code should keep its t stored, to improve
    error messages *)
type 'a marked = Mark of 'a * t [@@deriving show]

val pp_marked :
  (Format.formatter -> 'a -> unit) -> Format.formatter -> 'a marked -> unit

val none : t
(** Placeholder t *)

val without : 'a -> 'a marked

val mark : 'a -> t -> 'a marked

val unmark : 'a marked -> 'a

val get : 'a marked -> t

val to_couple : 'a marked -> 'a * t

val map : ('a -> 'b) -> 'a marked -> 'b marked

val same : 'a -> 'b marked -> 'a marked

val unmark_option : 'a marked option -> 'a option

val get_start_line : t -> int

val get_start_column : t -> int

val get_end_line : t -> int

val get_end_column : t -> int

val get_file : t -> string

val get_start_ofst : t -> int
(** Returns the starting offset of the pos [t]. *)

val get_end_ofst : t -> int
(** Returns the ending offset of the pos [t]. *)
