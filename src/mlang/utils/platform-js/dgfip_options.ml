(* dgfip_options.ml *)

type flags = {
  annee_revenu : int;
  flg_correctif : bool;
  flg_iliad : bool;
  flg_pro : bool;
  flg_cfir : bool;
  flg_gcos : bool;
  flg_tri_ebcdic : bool;
  flg_short : bool;
  flg_register : bool;
  flg_optim_min_max : bool;
  flg_extraction : bool;
  flg_genere_libelle_restituee : bool;
  flg_controle_separe : bool;
  flg_controle_immediat : bool;
  flg_overlays : bool;
  flg_colors : bool;
  flg_ticket : bool;
  flg_trace : bool;
  flg_debug : bool;
  nb_debug_c : int;
  xflg : bool;
}

let default_flags : flags = {
  annee_revenu = 0;
  flg_correctif = false;
  flg_iliad = false;
  flg_pro = false;
  flg_cfir = false;
  flg_gcos = false;
  flg_tri_ebcdic = false;
  flg_short = false;
  flg_register = false;
  flg_optim_min_max = false;
  flg_extraction = false;
  flg_genere_libelle_restituee = false;
  flg_controle_separe = false;
  flg_controle_immediat = false;
  flg_overlays = false;
  flg_colors = false;
  flg_ticket = false;
  flg_trace = false;
  flg_debug = false;
  nb_debug_c = 0;
  xflg = false;
}

let handler
    ~application_names:(_ : string list)
    (_ : int)
    (_ : bool)
    (_ : bool)
    (_ : int option)
    (_ : bool)
    (_ : bool)
    (_ : bool)
    (_ : bool)
    (_ : bool)
    (_ : bool)
    (_ : bool)
    (_ : bool)
    (_ : bool)
    (_ : bool)
    (_ : int)
    (_ : bool)
    (_ : bool)
    (_ : bool)
    (_ : bool) : flags =
  assert false

let process_dgfip_options
    ~application_names:(_ : string list)
    (_ : string list) : flags option =
  assert false
