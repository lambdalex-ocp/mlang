application app;

V_ANCSDED : saisie revenu acompte = 0 avfisc = 0 categorie_TL = 0 classe = 0 cotsoc = 0 ind_abat = 0 modcat = 0 nat_code = 0 primrest = 0 priorite = 0 rapcat = 0 sanction = 0 alias V_POUET: "v_ancsed";
X: calculee restituee primrest = 0: "x";
Y: calculee primrest = 0: "y";
MULTILINE: calculee primrest = 0 : "multiline";
TXMARJ: calculee primrest = 0: "tx_marj";
ANNEE: calculee primrest = 0: "annee";
BLABLA: saisie revenu acompte = 0 avfisc = 0 categorie_TL = 0 classe = 0 cotsoc = 0 ind_abat = 0 modcat = 0 nat_code = 0 primrest = 0 priorite = 0 rapcat = 0 sanction = 0 alias V_BLA: "blabla";
INPUT_UNDEFINED: saisie revenu acompte = 0 avfisc = 0 categorie_TL = 0 classe = 0 cotsoc = 0 ind_abat = 0 modcat = 0 nat_code = 0 primrest = 0 priorite = 0 rapcat = 0 sanction = 0 alias IUND: "blabla";
INPUT_DEFINED: saisie revenu acompte = 0 avfisc = 0 categorie_TL = 0 classe = 0 cotsoc = 0 ind_abat = 0 modcat = 0 nat_code = 0 primrest = 0 priorite = 0 rapcat = 0 sanction = 0 alias IDEF: "blabla";


regle 1337:
application: app;

X = 3;
Y = 3 + X;
TXMARJ = Y;
ANNEE = TXMARJ + INPUT_UNDEFINED + INPUT_DEFINED;
MULTILINE = X
+ Y;
cible target:
application: app;
calculer domaine primitive;
