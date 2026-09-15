from datetime import datetime
from sqlalchemy.orm import Session
from sqlalchemy import func

from app.models.facture import Facture
from app.models.paiement import Paiement
from app.models.depense import Depense


def dashboard_financier(
    db: Session,
    annee: int | None = None,
    mois: int | None = None,
):
    """
    Retourne les principaux indicateurs financiers.
    """

    if annee is None:
        annee = datetime.utcnow().year

    # ========================================================
    # FILTRE DATES
    # ========================================================

    debut = datetime(annee, 1, 1)

    if mois:
        if mois < 1 or mois > 12:
            raise ValueError("Le mois doit être compris entre 1 et 12")

        if mois == 12:
            fin = datetime(annee + 1, 1, 1)
        else:
            fin = datetime(annee, mois + 1, 1)
    else:
        fin = datetime(annee + 1, 1, 1)

    # ========================================================
    # FACTURES
    # ========================================================

    factures = (
        db.query(Facture)
        .filter(
            Facture.actif.is_(True),
            Facture.date_emission >= debut,
            Facture.date_emission < fin,
        )
        .all()
    )

    chiffre_affaires = round(
        sum(f.montant_ht or 0 for f in factures),
        2,
    )

    tva_collectee = round(
        sum(f.montant_tva or 0 for f in factures),
        2,
    )

    total_factures_ttc = round(
        sum(f.montant_ttc or 0 for f in factures),
        2,
    )

    # ========================================================
    # PAIEMENTS
    # ========================================================

    paiements = (
        db.query(Paiement)
        .filter(
            Paiement.actif.is_(True),
            Paiement.statut == "Validé",
            Paiement.date_paiement >= debut,
            Paiement.date_paiement < fin,
        )
        .all()
    )

    total_encaisse = round(
        sum(p.montant or 0 for p in paiements),
        2,
    )

    total_commissions = round(
        sum(p.montant_commission or 0 for p in paiements),
        2,
    )

    # ========================================================
    # DEPENSES
    # ========================================================

    depenses = (
        db.query(Depense)
        .filter(
            Depense.actif.is_(True),
            Depense.date_depense >= debut,
            Depense.date_depense < fin,
        )
        .all()
    )

    total_depenses_ht = round(
        sum(d.montant_ht or 0 for d in depenses),
        2,
    )

    total_depenses_ttc = round(
        sum(d.montant_ttc or 0 for d in depenses),
        2,
    )

    tva_deductible = round(
        sum(d.montant_tva or 0 for d in depenses),
        2,
    )

    # ========================================================
    # CREANCES CLIENTS
    # ========================================================

    creances_clients = round(
        total_factures_ttc - total_encaisse,
        2,
    )

    if creances_clients < 0:
        creances_clients = 0

    # ========================================================
    # BENEFICE
    # ========================================================

    benefice = round(
        chiffre_affaires - total_depenses_ht,
        2,
    )

    # ========================================================
    # TVA A PAYER
    # ========================================================

    tva_a_payer = round(
        tva_collectee - tva_deductible,
        2,
    )

    # ========================================================
    # SOLDE DE TRESORERIE
    # ========================================================

    solde = round(
        total_encaisse - total_depenses_ttc,
        2,
    )

    return {
        "periode": {
            "annee": annee,
            "mois": mois,
        },

        "factures": {
            "nombre": len(factures),
            "chiffre_affaires_ht": chiffre_affaires,
            "tva_collectee": tva_collectee,
            "total_ttc": total_factures_ttc,
        },

        "paiements": {
            "nombre": len(paiements),
            "total_encaisse": total_encaisse,
            "total_commissions": total_commissions,
        },

        "depenses": {
            "nombre": len(depenses),
            "total_ht": total_depenses_ht,
            "total_tva": tva_deductible,
            "total_ttc": total_depenses_ttc,
        },

        "resultats": {
            "benefice": benefice,
            "creances_clients": creances_clients,
            "tva_a_payer": tva_a_payer,
            "solde_tresorerie": solde,
        },
    }


def recettes_mensuelles(
    db: Session,
    annee: int,
):
    """
    Retourne les encaissements mois par mois.
    """

    resultats = []

    for mois in range(1, 13):

        debut = datetime(annee, mois, 1)

        if mois == 12:
            fin = datetime(annee + 1, 1, 1)
        else:
            fin = datetime(annee, mois + 1, 1)

        total = (
            db.query(func.coalesce(func.sum(Paiement.montant), 0))
            .filter(
                Paiement.actif.is_(True),
                Paiement.statut == "Validé",
                Paiement.date_paiement >= debut,
                Paiement.date_paiement < fin,
            )
            .scalar()
        )

        resultats.append(
            {
                "mois": mois,
                "montant": round(float(total or 0), 2),
            }
        )

    return resultats


def depenses_mensuelles(
    db: Session,
    annee: int,
):
    """
    Retourne les dépenses mois par mois.
    """

    resultats = []

    for mois in range(1, 13):

        debut = datetime(annee, mois, 1)

        if mois == 12:
            fin = datetime(annee + 1, 1, 1)
        else:
            fin = datetime(annee, mois + 1, 1)

        total = (
            db.query(func.coalesce(func.sum(Depense.montant_ttc), 0))
            .filter(
                Depense.actif.is_(True),
                Depense.date_depense >= debut,
                Depense.date_depense < fin,
            )
            .scalar()
        )

        resultats.append(
            {
                "mois": mois,
                "montant": round(float(total or 0), 2),
            }
        )

    return resultats


def depenses_par_categorie(
    db: Session,
    annee: int,
):
    """
    Regroupe les dépenses par catégorie.
    """

    resultats = (
        db.query(
            Depense.categorie,
            func.sum(Depense.montant_ttc).label("total"),
        )
        .filter(
            Depense.actif.is_(True),
            Depense.date_depense >= datetime(annee, 1, 1),
            Depense.date_depense < datetime(annee + 1, 1, 1),
        )
        .group_by(Depense.categorie)
        .order_by(func.sum(Depense.montant_ttc).desc())
        .all()
    )

    return [
        {
            "categorie": categorie,
            "montant": round(float(total or 0), 2),
        }
        for categorie, total in resultats
    ]
def rapport_annuel(
    db: Session,
    annee: int,
):
    """
    Génère un rapport comptable annuel.
    """

    dashboard = dashboard_financier(
        db,
        annee=annee,
        mois=None,
    )

    recettes = recettes_mensuelles(
        db,
        annee,
    )

    depenses = depenses_mensuelles(
        db,
        annee,
    )

    categories = depenses_par_categorie(
        db,
        annee,
    )

    return {
        "annee": annee,

        "synthese": {
            "chiffre_affaires_ht": dashboard["factures"]["chiffre_affaires_ht"],
            "total_factures_ttc": dashboard["factures"]["total_ttc"],
            "total_encaisse": dashboard["paiements"]["total_encaisse"],
            "total_depenses_ht": dashboard["depenses"]["total_ht"],
            "total_depenses_ttc": dashboard["depenses"]["total_ttc"],
            "benefice": dashboard["resultats"]["benefice"],
            "creances_clients": dashboard["resultats"]["creances_clients"],
            "solde_tresorerie": dashboard["resultats"]["solde_tresorerie"],
        },

        "tva": {
            "tva_collectee": dashboard["factures"]["tva_collectee"],
            "tva_deductible": dashboard["depenses"]["total_tva"],
            "tva_a_payer": dashboard["resultats"]["tva_a_payer"],
        },

        "statistiques": {
            "nombre_factures": dashboard["factures"]["nombre"],
            "nombre_paiements": dashboard["paiements"]["nombre"],
            "nombre_depenses": dashboard["depenses"]["nombre"],
        },

        "recettes_mensuelles": recettes,

        "depenses_mensuelles": depenses,

        "depenses_par_categorie": categories,
    }




def rapport_tva(
    db: Session,
    annee: int,
):
    """
    Retourne le suivi annuel de la TVA :
    TVA collectée, TVA déductible et TVA à payer.
    """

    resultats = []

    total_collectee = 0.0
    total_deductible = 0.0

    for mois in range(1, 13):

        debut = datetime(annee, mois, 1)

        if mois == 12:
            fin = datetime(annee + 1, 1, 1)
        else:
            fin = datetime(annee, mois + 1, 1)

        tva_collectee = (
            db.query(
                func.coalesce(
                    func.sum(Facture.montant_tva),
                    0,
                )
            )
            .filter(
                Facture.actif.is_(True),
                Facture.date_emission >= debut,
                Facture.date_emission < fin,
            )
            .scalar()
        )

        tva_deductible = (
            db.query(
                func.coalesce(
                    func.sum(Depense.montant_tva),
                    0,
                )
            )
            .filter(
                Depense.actif.is_(True),
                Depense.date_depense >= debut,
                Depense.date_depense < fin,
            )
            .scalar()
        )

        collectee = float(tva_collectee or 0)
        deductible = float(tva_deductible or 0)

        a_payer = collectee - deductible

        total_collectee += collectee
        total_deductible += deductible

        resultats.append(
            {
                "mois": mois,
                "tva_collectee": round(collectee, 2),
                "tva_deductible": round(deductible, 2),
                "tva_a_payer": round(a_payer, 2),
            }
        )

    return {
        "annee": annee,
        "totaux": {
            "tva_collectee": round(total_collectee, 2),
            "tva_deductible": round(total_deductible, 2),
            "tva_a_payer": round(
                total_collectee - total_deductible,
                2,
            ),
        },
        "mensuel": resultats,
    }


def rapport_tresorerie(
    db: Session,
    annee: int,
):
    """
    Retourne le suivi annuel de la trésorerie.
    """

    resultats = []
    solde_cumule = 0.0

    for mois in range(1, 13):

        debut = datetime(annee, mois, 1)

        if mois == 12:
            fin = datetime(annee + 1, 1, 1)
        else:
            fin = datetime(annee, mois + 1, 1)

        encaissements = (
            db.query(
                func.coalesce(
                    func.sum(Paiement.montant),
                    0,
                )
            )
            .filter(
                Paiement.actif.is_(True),
                Paiement.statut == "Validé",
                Paiement.date_paiement >= debut,
                Paiement.date_paiement < fin,
            )
            .scalar()
        )

        decaissements = (
            db.query(
                func.coalesce(
                    func.sum(Depense.montant_ttc),
                    0,
                )
            )
            .filter(
                Depense.actif.is_(True),
                Depense.date_depense >= debut,
                Depense.date_depense < fin,
            )
            .scalar()
        )

        encaissements = float(encaissements or 0)
        decaissements = float(decaissements or 0)

        variation = encaissements - decaissements
        solde_cumule += variation

        resultats.append(
            {
                "mois": mois,
                "encaissements": round(encaissements, 2),
                "decaissements": round(decaissements, 2),
                "variation": round(variation, 2),
                "solde_cumule": round(solde_cumule, 2),
            }
        )

    total_encaissements = round(
        sum(r["encaissements"] for r in resultats),
        2,
    )

    total_decaissements = round(
        sum(r["decaissements"] for r in resultats),
        2,
    )

    return {
        "annee": annee,
        "totaux": {
            "encaissements": total_encaissements,
            "decaissements": total_decaissements,
            "solde": round(
                total_encaissements - total_decaissements,
                2,
            ),
        },
        "mensuel": resultats,
    }


# ============================================================
# COMPTABILITE SYSCOHADA — MOTEUR COMPTABLE
# ============================================================

from decimal import Decimal

from sqlalchemy import and_

from app.models.comptabilite_syscohada import (
    PeriodeComptable,
    CompteComptable,
    EcritureComptable,
    LigneEcriture,
)


def get_compte(
    db: Session,
    numero: str,
) -> CompteComptable | None:
    """
    Recherche un compte comptable par son numéro.
    """

    return (
        db.query(CompteComptable)
        .filter(
            CompteComptable.numero == numero,
            CompteComptable.actif.is_(True),
        )
        .first()
    )


def lister_comptes(db: Session) -> list[CompteComptable]:
    """
    Retourne le plan comptable (comptes actifs), trié par numéro.
    """

    return (
        db.query(CompteComptable)
        .filter(CompteComptable.actif.is_(True))
        .order_by(CompteComptable.numero.asc())
        .all()
    )


def get_periode(
    db: Session,
    exercice: int,
    mois: int,
) -> PeriodeComptable | None:
    """
    Recherche une période comptable.
    """

    return (
        db.query(PeriodeComptable)
        .filter(
            PeriodeComptable.exercice == exercice,
            PeriodeComptable.mois == mois,
        )
        .first()
    )


def creer_periode(
    db: Session,
    exercice: int,
    mois: int,
) -> PeriodeComptable:
    """
    Crée une période comptable mensuelle.

    Une seule période est autorisée pour un couple
    exercice + mois.
    """

    if mois < 1 or mois > 12:
        raise ValueError(
            "Le mois doit être compris entre 1 et 12."
        )

    periode_existante = get_periode(
        db,
        exercice,
        mois,
    )

    if periode_existante:
        return periode_existante

    if mois == 12:
        date_debut = datetime(
            exercice,
            mois,
            1,
        ).date()

        date_fin = datetime(
            exercice + 1,
            1,
            1,
        ).date()

    else:
        date_debut = datetime(
            exercice,
            mois,
            1,
        ).date()

        date_fin = datetime(
            exercice,
            mois + 1,
            1,
        ).date()

    periode = PeriodeComptable(
        exercice=exercice,
        mois=mois,
        date_debut=date_debut,
        date_fin=date_fin,
        statut="OUVERTE",
    )

    db.add(periode)
    db.commit()
    db.refresh(periode)

    return periode


def verifier_ecriture_equilibree(
    lignes: list,
) -> tuple[Decimal, Decimal]:
    """
    Vérifie que le total débit est égal au total crédit.

    Retourne :
        total_debit, total_credit
    """

    if not lignes:
        raise ValueError(
            "Une écriture doit contenir au moins une ligne."
        )

    total_debit = Decimal("0")
    total_credit = Decimal("0")

    for ligne in lignes:
        debit = Decimal(str(ligne.debit or 0))
        credit = Decimal(str(ligne.credit or 0))

        if debit < 0:
            raise ValueError(
                "Le montant au débit ne peut pas être négatif."
            )

        if credit < 0:
            raise ValueError(
                "Le montant au crédit ne peut pas être négatif."
            )

        if debit > 0 and credit > 0:
            raise ValueError(
                "Une ligne ne peut pas avoir simultanément "
                "un débit et un crédit."
            )

        if debit == 0 and credit == 0:
            raise ValueError(
                "Une ligne doit contenir un montant au débit "
                "ou au crédit."
            )

        total_debit += debit
        total_credit += credit

    if total_debit != total_credit:
        raise ValueError(
            f"Écriture déséquilibrée : "
            f"débit={total_debit}, "
            f"crédit={total_credit}."
        )

    return total_debit, total_credit


def creer_ecriture(
    db: Session,
    *,
    periode_id: int,
    date_ecriture: datetime,
    journal: str,
    reference: str | None,
    libelle: str,
    lignes: list,
    source_type: str | None = None,
    source_id: int | None = None,
) -> EcritureComptable:
    """
    Crée une écriture comptable en brouillon.

    L'écriture doit être équilibrée :
        total débit = total crédit.

    Les comptes doivent exister et être actifs.
    """

    periode = (
        db.query(PeriodeComptable)
        .filter(
            PeriodeComptable.id == periode_id,
        )
        .first()
    )

    if not periode:
        raise ValueError(
            "La période comptable demandée n'existe pas."
        )

    if periode.statut != "OUVERTE":
        raise ValueError(
            "La période comptable n'est pas ouverte."
        )

    if (
        date_ecriture.date() < periode.date_debut
        or date_ecriture.date() >= periode.date_fin
    ):
        raise ValueError(
            "La date de l'écriture ne correspond pas "
            "à la période comptable."
        )

    total_debit, total_credit = verifier_ecriture_equilibree(
        lignes
    )

    ecriture = EcritureComptable(
        periode_id=periode_id,
        date_ecriture=date_ecriture,
        journal=journal,
        reference=reference,
        libelle=libelle,
        statut="BROUILLON",
        source_type=source_type,
        source_id=source_id,
    )

    db.add(ecriture)
    db.flush()

    for ligne in lignes:

        compte = (
            db.query(CompteComptable)
            .filter(
                CompteComptable.id == ligne.compte_id,
                CompteComptable.actif.is_(True),
            )
            .first()
        )

        if not compte:
            db.rollback()
            raise ValueError(
                f"Le compte ID {ligne.compte_id} "
                f"n'existe pas ou est inactif."
            )

        ligne_db = LigneEcriture(
            ecriture_id=ecriture.id,
            compte_id=ligne.compte_id,
            libelle=ligne.libelle,
            debit=Decimal(str(ligne.debit or 0)),
            credit=Decimal(str(ligne.credit or 0)),
        )

        db.add(ligne_db)

    db.commit()
    db.refresh(ecriture)

    return ecriture


def valider_ecriture(
    db: Session,
    ecriture_id: int,
) -> EcritureComptable:
    """
    Valide définitivement une écriture comptable.

    Une écriture validée ne doit plus être modifiée directement.
    """

    ecriture = (
        db.query(EcritureComptable)
        .filter(
            EcritureComptable.id == ecriture_id,
        )
        .first()
    )

    if not ecriture:
        raise ValueError(
            "L'écriture comptable n'existe pas."
        )

    if ecriture.statut == "VALIDE":
        return ecriture

    if ecriture.statut != "BROUILLON":
        raise ValueError(
            f"Impossible de valider une écriture "
            f"au statut '{ecriture.statut}'."
        )

    periode = ecriture.periode

    if not periode:
        raise ValueError(
            "La période comptable de l'écriture est introuvable."
        )

    if periode.statut != "OUVERTE":
        raise ValueError(
            "Impossible de valider une écriture "
            "dans une période fermée."
        )

    total_debit = Decimal("0")
    total_credit = Decimal("0")

    if not ecriture.lignes:
        raise ValueError(
            "Impossible de valider une écriture sans lignes."
        )

    for ligne in ecriture.lignes:
        total_debit += Decimal(str(ligne.debit or 0))
        total_credit += Decimal(str(ligne.credit or 0))

    if total_debit != total_credit:
        raise ValueError(
            "Impossible de valider : "
            "l'écriture n'est pas équilibrée."
        )

    ecriture.statut = "VALIDE"

    db.commit()
    db.refresh(ecriture)

    return ecriture


def journal_comptable(
    db: Session,
    *,
    exercice: int,
    journal: str | None = None,
    mois: int | None = None,
) -> list[dict]:
    """
    Retourne le journal comptable.

    Seules les écritures validées sont prises en compte.
    """

    query = (
        db.query(
            EcritureComptable,
            LigneEcriture,
            CompteComptable,
        )
        .join(
            LigneEcriture,
            LigneEcriture.ecriture_id
            == EcritureComptable.id,
        )
        .join(
            CompteComptable,
            CompteComptable.id
            == LigneEcriture.compte_id,
        )
        .join(
            PeriodeComptable,
            PeriodeComptable.id
            == EcritureComptable.periode_id,
        )
        .filter(
            PeriodeComptable.exercice == exercice,
            EcritureComptable.statut == "VALIDE",
        )
    )

    if journal:
        query = query.filter(
            EcritureComptable.journal == journal
        )

    if mois:
        query = query.filter(
            PeriodeComptable.mois == mois
        )

    lignes = query.order_by(
        EcritureComptable.date_ecriture.asc(),
        EcritureComptable.id.asc(),
        LigneEcriture.id.asc(),
    ).all()

    return [
        {
            "ecriture_id": ecriture.id,
            "date_ecriture": ecriture.date_ecriture,
            "journal": ecriture.journal,
            "reference": ecriture.reference,
            "libelle_ecriture": ecriture.libelle,
            "compte_id": compte.id,
            "compte_numero": compte.numero,
            "compte_libelle": compte.libelle,
            "libelle_ligne": ligne.libelle,
            "debit": Decimal(str(ligne.debit or 0)),
            "credit": Decimal(str(ligne.credit or 0)),
        }
        for ecriture, ligne, compte in lignes
    ]


def grand_livre(
    db: Session,
    *,
    exercice: int,
    compte_numero: str | None = None,
) -> list[dict]:
    """
    Retourne le grand livre par compte.

    Seules les écritures validées sont prises en compte.
    """

    query = (
        db.query(
            EcritureComptable,
            LigneEcriture,
            CompteComptable,
        )
        .join(
            LigneEcriture,
            LigneEcriture.ecriture_id
            == EcritureComptable.id,
        )
        .join(
            CompteComptable,
            CompteComptable.id
            == LigneEcriture.compte_id,
        )
        .join(
            PeriodeComptable,
            PeriodeComptable.id
            == EcritureComptable.periode_id,
        )
        .filter(
            PeriodeComptable.exercice == exercice,
            EcritureComptable.statut == "VALIDE",
        )
    )

    if compte_numero:
        query = query.filter(
            CompteComptable.numero == compte_numero
        )

    lignes = query.order_by(
        CompteComptable.numero.asc(),
        EcritureComptable.date_ecriture.asc(),
        EcritureComptable.id.asc(),
        LigneEcriture.id.asc(),
    ).all()

    comptes = {}

    for ecriture, ligne, compte in lignes:

        if compte.id not in comptes:
            comptes[compte.id] = {
                "compte_id": compte.id,
                "numero": compte.numero,
                "libelle": compte.libelle,
                "total_debit": Decimal("0"),
                "total_credit": Decimal("0"),
                "solde_debiteur": Decimal("0"),
                "solde_crediteur": Decimal("0"),
                "lignes": [],
            }

        debit = Decimal(str(ligne.debit or 0))
        credit = Decimal(str(ligne.credit or 0))

        comptes[compte.id]["total_debit"] += debit
        comptes[compte.id]["total_credit"] += credit

        solde = (
            comptes[compte.id]["total_debit"]
            - comptes[compte.id]["total_credit"]
        )

        comptes[compte.id]["lignes"].append(
            {
                "date_ecriture": ecriture.date_ecriture,
                "journal": ecriture.journal,
                "reference": ecriture.reference,
                "libelle": (
                    ligne.libelle
                    or ecriture.libelle
                ),
                "debit": debit,
                "credit": credit,
                "solde": solde,
            }
        )

    for compte in comptes.values():

        solde = (
            compte["total_debit"]
            - compte["total_credit"]
        )

        if solde > 0:
            compte["solde_debiteur"] = solde
        elif solde < 0:
            compte["solde_crediteur"] = abs(solde)

    return list(comptes.values())


def balance_comptable(
    db: Session,
    *,
    exercice: int,
) -> dict:
    """
    Génère la balance comptable de l'exercice.

    Seules les écritures validées sont prises en compte.
    """

    resultats = (
        db.query(
            CompteComptable,
            func.coalesce(
                func.sum(LigneEcriture.debit),
                0,
            ).label("total_debit"),
            func.coalesce(
                func.sum(LigneEcriture.credit),
                0,
            ).label("total_credit"),
        )
        .join(
            LigneEcriture,
            LigneEcriture.compte_id
            == CompteComptable.id,
        )
        .join(
            EcritureComptable,
            EcritureComptable.id
            == LigneEcriture.ecriture_id,
        )
        .join(
            PeriodeComptable,
            PeriodeComptable.id
            == EcritureComptable.periode_id,
        )
        .filter(
            CompteComptable.actif.is_(True),
            PeriodeComptable.exercice == exercice,
            EcritureComptable.statut == "VALIDE",
        )
        .group_by(
            CompteComptable.id,
        )
        .order_by(
            CompteComptable.numero.asc(),
        )
        .all()
    )

    comptes = []

    total_debit_general = Decimal("0")
    total_credit_general = Decimal("0")
    total_solde_debiteur = Decimal("0")
    total_solde_crediteur = Decimal("0")

    for compte, debit, credit in resultats:

        debit = Decimal(str(debit or 0))
        credit = Decimal(str(credit or 0))

        solde = debit - credit

        solde_debiteur = (
            solde if solde > 0
            else Decimal("0")
        )

        solde_crediteur = (
            abs(solde) if solde < 0
            else Decimal("0")
        )

        total_debit_general += debit
        total_credit_general += credit
        total_solde_debiteur += solde_debiteur
        total_solde_crediteur += solde_crediteur

        comptes.append(
            {
                "compte_id": compte.id,
                "numero": compte.numero,
                "libelle": compte.libelle,
                "total_debit": debit,
                "total_credit": credit,
                "solde_debiteur": solde_debiteur,
                "solde_crediteur": solde_crediteur,
            }
        )

    return {
        "exercice": exercice,
        "total_debit": total_debit_general,
        "total_credit": total_credit_general,
        "total_solde_debiteur": total_solde_debiteur,
        "total_solde_crediteur": total_solde_crediteur,
        "comptes": comptes,
    }
