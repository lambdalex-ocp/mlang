(* Copyright (C) 2019-2021 Inria, contributor: Denis Merigoux
   <denis.merigoux@inria.fr>

   This program is free software: you can redistribute it and/or modify it under
   the terms of the GNU General Public License as published by the Free Software
   Foundation, either version 3 of the License, or (at your option) any later
   version.

   This program is distributed in the hope that it will be useful, but WITHOUT
   ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
   FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
   details.

   You should have received a copy of the GNU General Public License along with
   this program. If not, see <https://www.gnu.org/licenses/>. *)

(** Abstract Syntax Tree for M *)

(** {1 Abstract Syntax Tree} *)

(** This AST is very close to the concrete syntax. It features many elements
    that are just dropped in later phases of the compiler, but may be used by
    other DGFiP applications *)

(**{2 Names}*)

type application = string [@@deriving yojson]
(** Applications are rule annotations. The 3 main DGFiP applications seem to be:

    - [batch]: deprecated, used to compute the income tax but not anymore;
    - [bareme]: seems to compute the income tax;
    - [iliad]: usage unkown, much bigger than [bareme]. *)

type chaining = string [@@deriving yojson]
(** "enchaineur" in the M source code, utility unknown *)

type func_name = string [@@deriving yojson]
(** Func names are just string for the moment *)

type error_name = string [@@deriving yojson]
(** Ununsed for now *)

(**{2 Literals}*)

type table_size = LiteralSize of int | SymbolSize of string
[@@deriving yojson]

let get_table_size = function
  | LiteralSize i -> i
  | SymbolSize _ -> assert false

let get_table_size_opt = function
  | Some (Pos.Mark (LiteralSize i, pos)) -> Some (Pos.mark i pos)
  | None -> None
  | Some (Pos.Mark (SymbolSize _, _)) -> assert false

(**{2 Expressions}*)

type var_category_id = string Pos.marked list Pos.marked [@@deriving yojson]

type set_value = Com.m_var_name Com.set_value

type expression = Com.m_var_name Com.expression [@@deriving yojson]

type m_expression = expression Pos.marked

(**{1 Toplevel clauses}*)

(**{2 Rules}*)

(** The rule is the main feature of the M language. It defines the expression of
    one or several variables. *)

type instruction = (Com.m_var_name, error_name) Com.instruction
[@@deriving yojson]

type m_instruction = instruction Pos.marked [@@deriving yojson]

type rule = {
  rule_number : int Pos.marked;
  rule_tag_names : string Pos.marked list Pos.marked;
  rule_apps : application Pos.marked StrMap.t;
  rule_chainings : chaining Pos.marked StrMap.t;
  rule_tmp_vars : (string Pos.marked * table_size Pos.marked option) list;
  rule_formulaes : instruction Pos.marked list;
      (** A rule can contain many variable definitions *)
}
[@@deriving yojson]

type target = {
  target_name : string Pos.marked;
  target_file : string option;
  target_apps : string Pos.marked StrMap.t;
  target_args : string Pos.marked list;
  target_result : string Pos.marked option;
  target_tmp_vars : (string Pos.marked * table_size Pos.marked option) list;
  target_prog : m_instruction list;
}
[@@deriving yojson]

type 'a domain_decl = {
  dom_names : string Pos.marked list Pos.marked list;
  dom_parents : string Pos.marked list Pos.marked list;
  dom_by_default : bool;
  dom_data : 'a;
}
[@@deriving yojson]

type rule_domain_data = { rdom_computable : bool } [@@deriving yojson]

type rule_domain_decl = rule_domain_data domain_decl [@@deriving yojson]

(**{2 Variable declaration}*)

(** The M language has prototypes for declaring variables with types and various
    attributes. There are three kind of variables: input variables, computed
    variables and constant variables.

    Variable declaration is not application-specific, which is not coherent. *)

(**{3 Input variables}*)

type variable_attribute = string Pos.marked * int Pos.marked [@@deriving yojson]

type input_variable = {
  input_name : string Pos.marked;
  input_category : string Pos.marked list;
  input_attributes : variable_attribute list;
  input_alias : string Pos.marked;  (** Unused for now *)
  input_is_givenback : bool;
  input_description : string Pos.marked;
  input_typ : Com.value_typ Pos.marked option;
}
[@@deriving yojson]

type computed_variable = {
  comp_name : string Pos.marked;
  comp_table : table_size Pos.marked option;
      (** size of the table, [None] for non-table variables *)
  comp_attributes : variable_attribute list;
  comp_category : string Pos.marked list;
  comp_typ : Com.value_typ Pos.marked option;
  comp_is_givenback : bool;
  comp_description : string Pos.marked;
}
[@@deriving yojson]

type variable_decl =
  | ComputedVar of computed_variable Pos.marked
  | ConstVar of string Pos.marked * Com.m_var_name Com.atom Pos.marked
      (** The literal is the constant value *)
  | InputVar of input_variable Pos.marked
[@@deriving yojson]

type var_type = Input | Computed [@@deriving yojson]

type var_category_decl = {
  var_type : var_type;
  var_category : string Pos.marked list;
  var_attributes : string Pos.marked list;
}
[@@deriving yojson]

(* standard categories *)
let input_category = "saisie"

let computed_category = "calculee"

let base_category = "base"

let givenback_category = "restituee"

(**{2 Verification clauses}*)

(** These clauses are expression refering to the variables of the program. They
    seem to be dynamically checked and trigger errors when false. *)

type verification_condition = {
  verif_cond_expr : expression Pos.marked;
  verif_cond_error : error_name Pos.marked * string Pos.marked option;
      (** A verification condition error can ba associated to a variable *)
}
[@@deriving yojson]

type verification = {
  verif_number : int Pos.marked;
  verif_tag_names : string Pos.marked list Pos.marked;
  verif_apps : application Pos.marked StrMap.t;
      (** Verification conditions are application-specific *)
  verif_conditions : verification_condition Pos.marked list;
}
[@@deriving yojson]

type verif_domain_data = {
  vdom_auth : var_category_id list;
  vdom_verifiable : bool;
}
[@@deriving yojson]

type verif_domain_decl = verif_domain_data domain_decl [@@deriving yojson]

type error_ = {
  error_name : error_name Pos.marked;
  error_typ : Com.Error.typ Pos.marked;
  error_descr : string Pos.marked list;
}
[@@deriving yojson]

(**{1 M programs}*)

type source_file_item =
  | Application of application Pos.marked  (** Declares an application *)
  | Chaining of chaining Pos.marked * application Pos.marked list
  | VariableDecl of variable_decl
  | EventDecl of Com.event_field list
  | Function of target
  | Rule of rule
  | Target of target
  | Verification of verification
  | Error of error_  (** Declares an error *)
  | Output of string Pos.marked  (** Declares an output variable *)
  | Func  (** Declares a function, unused *)
  | VarCatDecl of var_category_decl Pos.marked
  | RuleDomDecl of rule_domain_decl
  | VerifDomDecl of verif_domain_decl
  | VariableSpaceDecl of Com.variable_space
[@@deriving yojson]

(* TODO: parse something here *)

type source_file = source_file_item Pos.marked list [@@deriving yojson]

type program = source_file list [@@deriving yojson]
