from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.comptabilite_syscohada import CompteComptable


PLAN_COMPTABLE = [
    # ============================================================
    # CLASSE 1 — RESSOURCES DURABLES
    # ============================================================
    ("101", "Capital social", "1", "10"),
    ("104", "Primes liées au capital social", "1", "10"),
    ("106", "Réserves", "1", "10"),
    ("110", "Report à nouveau créditeur", "1", "11"),
    ("119", "Report à nouveau débiteur", "1", "11"),
    ("120", "Résultat de l'exercice - bénéfice", "1", "12"),
    ("129", "Résultat de l'exercice - perte", "1", "12"),
    ("130", "Résultat en instance d'affectation", "1", "13"),
    ("140", "Subventions d'investissement", "1", "14"),
    ("162", "Emprunts et dettes auprès des établissements de crédit", "1", "16"),
    ("164", "Emprunts et dettes financières diverses", "1", "16"),
    ("165", "Dépôts et cautionnements reçus", "1", "16"),
    ("168", "Autres emprunts et dettes", "1", "16"),
    ("191", "Provisions pour risques", "1", "19"),
    ("192", "Provisions pour charges", "1", "19"),

    # ============================================================
    # CLASSE 2 — ACTIF IMMOBILISÉ
    # ============================================================
    ("201", "Frais d'établissement", "2", "20"),
    ("211", "Terrains", "2", "21"),
    ("212", "Agencements et aménagements de terrains", "2", "21"),
    ("213", "Constructions", "2", "21"),
    ("215", "Installations techniques", "2", "21"),
    ("218", "Autres immobilisations corporelles", "2", "21"),
    ("221", "Terrains", "2", "22"),
    ("231", "Bâtiments", "2", "23"),
    ("241", "Matériel et outillage industriel", "2", "24"),
    ("244", "Matériel informatique", "2", "24"),
    ("245", "Matériel de transport", "2", "24"),
    ("248", "Autres matériels", "2", "24"),
    ("275", "Dépôts et cautionnements versés", "2", "27"),
    ("281", "Amortissements des immobilisations incorporelles", "2", "28"),
    ("284", "Amortissements des immobilisations corporelles", "2", "28"),
    ("291", "Dépréciations des immobilisations incorporelles", "2", "29"),
    ("294", "Dépréciations des immobilisations corporelles", "2", "29"),

    # ============================================================
    # CLASSE 3 — STOCKS ET ENCOURS
    # ============================================================
    ("311", "Marchandises", "3", "31"),
    ("321", "Matières premières et fournitures liées", "3", "32"),
    ("331", "Produits en cours", "3", "33"),
    ("341", "Produits finis", "3", "34"),
    ("351", "Produits intermédiaires", "3", "35"),
    ("371", "Marchandises en cours de route", "3", "37"),
    ("391", "Dépréciations des stocks de marchandises", "3", "39"),
    ("392", "Dépréciations des matières premières", "3", "39"),
    ("394", "Dépréciations des produits finis", "3", "39"),

    # ============================================================
    # CLASSE 4 — TIERS
    # ============================================================
    ("401", "Fournisseurs", "4", "40"),
    ("402", "Fournisseurs, effets à payer", "4", "40"),
    ("408", "Fournisseurs, factures non parvenues", "4", "40"),
    ("409", "Fournisseurs débiteurs", "4", "40"),

    ("411", "Clients", "4", "41"),
    ("412", "Clients, effets à recevoir", "4", "41"),
    ("416", "Clients douteux ou litigieux", "4", "41"),
    ("418", "Clients, produits à recevoir", "4", "41"),
    ("419", "Clients créditeurs", "4", "41"),

    ("421", "Personnel, avances et acomptes", "4", "42"),
    ("422", "Personnel, rémunérations dues", "4", "42"),
    ("425", "Personnel, avances et acomptes", "4", "42"),
    ("431", "Sécurité sociale", "4", "43"),
    ("441", "État, impôts et taxes", "4", "44"),
    ("443", "État, TVA facturée", "4", "44"),
    ("444", "État, TVA due", "4", "44"),
    ("445", "État, TVA récupérable", "4", "44"),
    ("447", "État, impôts et taxes à payer", "4", "44"),
    ("448", "État, charges à payer", "4", "44"),
    ("449", "État, créances et dettes diverses", "4", "44"),

    ("471", "Comptes d'attente", "4", "47"),
    ("476", "Charges constatées d'avance", "4", "47"),
    ("477", "Produits constatés d'avance", "4", "47"),

    # ============================================================
    # CLASSE 5 — TRÉSORERIE
    # ============================================================
    ("501", "Titres de placement", "5", "50"),
    ("511", "Valeurs à encaisser", "5", "51"),
    ("521", "Banques", "5", "52"),
    ("525", "Comptes bancaires", "5", "52"),
    ("531", "Caisses", "5", "53"),
    ("541", "Régies d'avances", "5", "54"),
    ("571", "Caisse siège", "5", "57"),
    ("581", "Virements de fonds", "5", "58"),

    # ============================================================
    # CLASSE 6 — CHARGES
    # ============================================================
    ("601", "Achats de marchandises", "6", "60"),
    ("602", "Achats de matières premières et fournitures liées", "6", "60"),
    ("604", "Achats stockés de matières et fournitures", "6", "60"),
    ("605", "Autres achats", "6", "60"),
    ("608", "Achats d'emballages", "6", "60"),
    ("609", "Rabais, remises et ristournes obtenus sur achats", "6", "60"),

    ("611", "Transports sur achats", "6", "61"),
    ("612", "Transports sur ventes", "6", "61"),
    ("613", "Locations et charges locatives", "6", "61"),
    ("614", "Charges locatives et de copropriété", "6", "61"),
    ("621", "Personnel extérieur à l'entreprise", "6", "62"),
    ("622", "Rémunérations d'intermédiaires et de conseils", "6", "62"),
    ("623", "Publicité, publications et relations publiques", "6", "62"),
    ("624", "Transports de biens et transports collectifs du personnel", "6", "62"),
    ("625", "Déplacements, missions et réceptions", "6", "62"),
    ("626", "Frais postaux et télécommunications", "6", "62"),
    ("627", "Services bancaires", "6", "62"),
    ("628", "Autres services extérieurs", "6", "62"),

    ("631", "Frais financiers", "6", "63"),
    ("632", "Charges d'intérêts", "6", "63"),
    ("633", "Pertes sur créances", "6", "63"),

    ("641", "Impôts et taxes directs", "6", "64"),
    ("645", "Impôts et taxes indirects", "6", "64"),
    ("651", "Pertes sur créances clients", "6", "65"),
    ("661", "Rémunérations directes", "6", "66"),
    ("664", "Charges sociales", "6", "66"),
    ("681", "Dotations aux amortissements", "6", "68"),
    ("691", "Dotations aux provisions", "6", "69"),

    # ============================================================
    # CLASSE 7 — PRODUITS
    # ============================================================
    ("701", "Ventes de marchandises", "7", "70"),
    ("702", "Ventes de produits finis", "7", "70"),
    ("703", "Ventes de produits intermédiaires", "7", "70"),
    ("704", "Ventes de produits résiduels", "7", "70"),
    ("705", "Travaux facturés", "7", "70"),
    ("706", "Services vendus", "7", "70"),
    ("707", "Produits accessoires", "7", "70"),
    ("709", "Rabais, remises et ristournes accordés", "7", "70"),

    ("711", "Production stockée", "7", "71"),
    ("712", "Production immobilisée", "7", "71"),
    ("721", "Subventions d'exploitation", "7", "72"),
    ("722", "Autres produits d'exploitation", "7", "72"),
    ("731", "Produits financiers", "7", "73"),
    ("732", "Revenus des titres", "7", "73"),
    ("758", "Produits divers", "7", "75"),
    ("771", "Intérêts de prêts", "7", "77"),
    ("781", "Reprises d'amortissements", "7", "78"),
    ("791", "Reprises de provisions", "7", "79"),

    # ============================================================
    # CLASSE 8 — AUTRES CHARGES ET PRODUITS
    # ============================================================
    ("811", "Valeurs comptables des cessions d'immobilisations", "8", "81"),
    ("821", "Produits des cessions d'immobilisations", "8", "82"),
    ("831", "Charges HAO", "8", "83"),
    ("841", "Produits HAO", "8", "84"),
    ("851", "Dotations HAO", "8", "85"),
    ("861", "Reprises HAO", "8", "86"),
    ("891", "Impôts sur les bénéfices", "8", "89"),
    ("899", "Détermination du résultat", "8", "89"),
]


def seed_plan_comptable(session: Session) -> int:
    """
    Insère le plan comptable dans la base.

    Les comptes déjà présents sont ignorés.
    Retourne le nombre de comptes nouvellement créés.
    """

    comptes_crees = 0

    for numero, libelle, classe, sous_classe in PLAN_COMPTABLE:
        compte_existant = session.scalar(
            select(CompteComptable).where(
                CompteComptable.numero == numero
            )
        )

        if compte_existant:
            continue

        compte = CompteComptable(
            numero=numero,
            libelle=libelle,
            classe=classe,
            sous_classe=sous_classe,
            actif=True,
        )

        session.add(compte)
        comptes_crees += 1

    session.commit()

    return comptes_crees
