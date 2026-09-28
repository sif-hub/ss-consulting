import pytest

from app.models.client import Client
from app.models.facture import Facture
from app.models.paiement import Paiement


def creer_client(db_session, nom="Client Test"):
    c = Client(nom=nom, telephone="699000000")
    db_session.add(c)
    db_session.commit()
    db_session.refresh(c)
    return c


def creer_facture(db_session, client_id, montant_ttc=10000, numero=None, **overrides):
    defaults = {
        "numero": numero or f"FAC-{montant_ttc}-{client_id}",
        "client_id": client_id,
        "montant_ht": montant_ttc,
        "montant_tva": 0,
        "montant_ttc": montant_ttc,
        "statut": "Brouillon",
        "actif": True,
    }
    defaults.update(overrides)
    f = Facture(**defaults)
    db_session.add(f)
    db_session.commit()
    db_session.refresh(f)
    return f


def creer_paiement(db_session, facture_id, montant, statut="Validé", **overrides):
    p = Paiement(
        facture_id=facture_id,
        montant=montant,
        mode_paiement=overrides.pop("mode_paiement", "Espèces"),
        taux_commission=2.0,
        montant_commission=round(montant * 0.02, 2),
        montant_total=round(montant * 1.02, 2),
        statut=statut,
        actif=True,
        **overrides,
    )
    db_session.add(p)
    db_session.commit()
    db_session.refresh(p)
    return p


# ============================================================
# CREATION
# ============================================================

def test_creation_paiement_valide_solde_totalement_la_facture(
    client, make_user, auth_headers, db_session
):
    c = creer_client(db_session)
    facture = creer_facture(db_session, c.id, montant_ttc=10000)
    admin = make_user("Administrateur")

    response = client.post(
        "/api/v1/paiements",
        json={
            "facture_id": facture.id,
            "montant": 10000,
            "mode_paiement": "Espèces",
            "statut": "Validé",
        },
        headers=auth_headers(admin),
    )

    assert response.status_code == 201
    data = response.json()
    assert data["montant_commission"] == 200.0
    assert data["montant_total"] == 10200.0

    db_session.refresh(facture)
    assert facture.statut == "Payée"


def test_creation_paiement_partiel_met_facture_en_partiellement_payee(
    client, make_user, auth_headers, db_session
):
    c = creer_client(db_session)
    facture = creer_facture(db_session, c.id, montant_ttc=10000)
    admin = make_user("Administrateur")

    response = client.post(
        "/api/v1/paiements",
        json={
            "facture_id": facture.id,
            "montant": 4000,
            "mode_paiement": "Espèces",
            "statut": "Validé",
        },
        headers=auth_headers(admin),
    )

    assert response.status_code == 201
    db_session.refresh(facture)
    assert facture.statut == "Partiellement payée"


def test_paiement_en_attente_ne_change_pas_le_statut_de_la_facture(
    client, make_user, auth_headers, db_session
):
    c = creer_client(db_session)
    facture = creer_facture(db_session, c.id, montant_ttc=10000)
    admin = make_user("Administrateur")

    response = client.post(
        "/api/v1/paiements",
        json={
            "facture_id": facture.id,
            "montant": 10000,
            "mode_paiement": "Orange Money",
            "statut": "En attente",
        },
        headers=auth_headers(admin),
    )

    assert response.status_code == 201
    db_session.refresh(facture)
    assert facture.statut == "Brouillon"


def test_paiement_valide_au_dela_du_reste_est_refuse(
    client, make_user, auth_headers, db_session
):
    c = creer_client(db_session)
    facture = creer_facture(db_session, c.id, montant_ttc=10000)
    creer_paiement(db_session, facture.id, 6000, statut="Validé")
    admin = make_user("Administrateur")

    response = client.post(
        "/api/v1/paiements",
        json={
            "facture_id": facture.id,
            "montant": 5000,
            "mode_paiement": "Espèces",
            "statut": "Validé",
        },
        headers=auth_headers(admin),
    )

    assert response.status_code == 400


def test_operateur_invalide_pour_mobile_money_est_refuse(
    client, make_user, auth_headers, db_session
):
    c = creer_client(db_session)
    facture = creer_facture(db_session, c.id)
    admin = make_user("Administrateur")

    response = client.post(
        "/api/v1/paiements",
        json={
            "facture_id": facture.id,
            "montant": 1000,
            "mode_paiement": "Orange Money",
            "operateur": "Visa",
            "statut": "En attente",
        },
        headers=auth_headers(admin),
    )

    assert response.status_code == 400


def test_creation_sur_facture_introuvable_renvoie_404(
    client, make_user, auth_headers
):
    admin = make_user("Administrateur")

    response = client.post(
        "/api/v1/paiements",
        json={
            "facture_id": 999,
            "montant": 1000,
            "mode_paiement": "Espèces",
        },
        headers=auth_headers(admin),
    )

    assert response.status_code == 404


def test_creation_sur_facture_inactive_est_refusee(
    client, make_user, auth_headers, db_session
):
    c = creer_client(db_session)
    facture = creer_facture(db_session, c.id, actif=False)
    admin = make_user("Administrateur")

    response = client.post(
        "/api/v1/paiements",
        json={
            "facture_id": facture.id,
            "montant": 1000,
            "mode_paiement": "Espèces",
        },
        headers=auth_headers(admin),
    )

    assert response.status_code == 400


@pytest.mark.parametrize("role_nom", ["Fiscaliste", "Client"])
def test_creation_refusee_pour_les_autres_roles(
    client, make_user, auth_headers, db_session, role_nom
):
    c = creer_client(db_session)
    facture = creer_facture(db_session, c.id)
    user = make_user(role_nom)

    response = client.post(
        "/api/v1/paiements",
        json={
            "facture_id": facture.id,
            "montant": 1000,
            "mode_paiement": "Espèces",
        },
        headers=auth_headers(user),
    )

    assert response.status_code == 403


# ============================================================
# LISTE / DETAIL
# ============================================================

def test_compte_client_ne_voit_que_les_paiements_de_ses_factures(
    client, make_user, auth_headers, db_session
):
    moi = creer_client(db_session, "Moi")
    autre = creer_client(db_session, "Autre")
    facture_moi = creer_facture(db_session, moi.id, numero="F-MOI")
    facture_autre = creer_facture(db_session, autre.id, numero="F-AUTRE")
    creer_paiement(db_session, facture_moi.id, 1000)
    creer_paiement(db_session, facture_autre.id, 2000)

    utilisateur = make_user("Client", client_id=moi.id)

    response = client.get("/api/v1/paiements", headers=auth_headers(utilisateur))

    assert response.status_code == 200
    data = response.json()
    assert len(data) == 1
    assert data[0]["facture_id"] == facture_moi.id


def test_compte_client_non_rattache_voit_une_liste_vide(
    client, make_user, auth_headers, db_session
):
    autre = creer_client(db_session, "Autre")
    facture = creer_facture(db_session, autre.id)
    creer_paiement(db_session, facture.id, 1000)

    utilisateur = make_user("Client", client_id=None)

    response = client.get("/api/v1/paiements", headers=auth_headers(utilisateur))

    assert response.status_code == 200
    assert response.json() == []


def test_liste_refusee_pour_le_fiscaliste(client, make_user, auth_headers):
    fiscaliste = make_user("Fiscaliste")

    response = client.get("/api/v1/paiements", headers=auth_headers(fiscaliste))

    assert response.status_code == 403


def test_detail_introuvable_renvoie_404(client, make_user, auth_headers):
    admin = make_user("Administrateur")

    response = client.get("/api/v1/paiements/999", headers=auth_headers(admin))

    assert response.status_code == 404


def test_compte_client_ne_peut_pas_voir_le_paiement_dun_autre(
    client, make_user, auth_headers, db_session
):
    autre = creer_client(db_session, "Autre")
    facture_autre = creer_facture(db_session, autre.id)
    paiement = creer_paiement(db_session, facture_autre.id, 1000)

    moi = creer_client(db_session, "Moi")
    utilisateur = make_user("Client", client_id=moi.id)

    response = client.get(
        f"/api/v1/paiements/{paiement.id}",
        headers=auth_headers(utilisateur),
    )

    assert response.status_code == 403


# ============================================================
# MODIFICATION
# ============================================================

def test_modification_montant_recalcule_la_commission(
    client, make_user, auth_headers, db_session
):
    c = creer_client(db_session)
    facture = creer_facture(db_session, c.id, montant_ttc=10000)
    paiement = creer_paiement(db_session, facture.id, 4000, statut="Validé")
    admin = make_user("Administrateur")

    response = client.put(
        f"/api/v1/paiements/{paiement.id}",
        json={"montant": 10000},
        headers=auth_headers(admin),
    )

    assert response.status_code == 200
    data = response.json()
    assert data["montant"] == 10000
    assert data["montant_commission"] == 200.0

    db_session.refresh(facture)
    assert facture.statut == "Payée"


def test_modification_au_dela_du_reste_disponible_est_refusee(
    client, make_user, auth_headers, db_session
):
    c = creer_client(db_session)
    facture = creer_facture(db_session, c.id, montant_ttc=10000)
    autre_paiement = creer_paiement(db_session, facture.id, 6000, statut="Validé")
    paiement = creer_paiement(db_session, facture.id, 1000, statut="Validé")
    admin = make_user("Administrateur")

    response = client.put(
        f"/api/v1/paiements/{paiement.id}",
        json={"montant": 5000},
        headers=auth_headers(admin),
    )

    assert response.status_code == 400


def test_modification_paiement_introuvable_renvoie_404(
    client, make_user, auth_headers
):
    admin = make_user("Administrateur")

    response = client.put(
        "/api/v1/paiements/999",
        json={"montant": 1000},
        headers=auth_headers(admin),
    )

    assert response.status_code == 404


# ============================================================
# SUPPRESSION
# ============================================================

def test_suppression_desactive_et_recalcule_la_facture(
    client, make_user, auth_headers, db_session
):
    c = creer_client(db_session)
    facture = creer_facture(db_session, c.id, montant_ttc=10000)
    paiement = creer_paiement(db_session, facture.id, 10000, statut="Validé")
    facture.statut = "Payée"
    db_session.commit()

    admin = make_user("Administrateur")

    response = client.delete(
        f"/api/v1/paiements/{paiement.id}",
        headers=auth_headers(admin),
    )

    assert response.status_code == 204

    db_session.refresh(paiement)
    assert paiement.actif is False

    db_session.refresh(facture)
    assert facture.statut == "Brouillon"


def test_paiement_supprime_disparait_de_la_liste(
    client, make_user, auth_headers, db_session
):
    c = creer_client(db_session)
    facture = creer_facture(db_session, c.id)
    paiement = creer_paiement(db_session, facture.id, 1000)
    admin = make_user("Administrateur")

    client.delete(f"/api/v1/paiements/{paiement.id}", headers=auth_headers(admin))

    response = client.get("/api/v1/paiements", headers=auth_headers(admin))

    assert paiement.id not in [p["id"] for p in response.json()]


def test_suppression_paiement_introuvable_renvoie_404(
    client, make_user, auth_headers
):
    admin = make_user("Administrateur")

    response = client.delete("/api/v1/paiements/999", headers=auth_headers(admin))

    assert response.status_code == 404


# ============================================================
# RESUME FACTURE
# ============================================================

def test_resume_facture_totaux_corrects(client, make_user, auth_headers, db_session):
    c = creer_client(db_session)
    facture = creer_facture(db_session, c.id, montant_ttc=10000)
    creer_paiement(db_session, facture.id, 4000, statut="Validé")
    creer_paiement(db_session, facture.id, 1000, statut="En attente")
    admin = make_user("Administrateur")

    response = client.get(
        f"/api/v1/paiements/facture/{facture.id}/resume",
        headers=auth_headers(admin),
    )

    assert response.status_code == 200
    data = response.json()
    assert data["total_paye"] == 4000
    assert data["reste_a_payer"] == 6000


def test_resume_facture_introuvable_renvoie_404(client, make_user, auth_headers):
    admin = make_user("Administrateur")

    response = client.get(
        "/api/v1/paiements/facture/999/resume",
        headers=auth_headers(admin),
    )

    assert response.status_code == 404


# ============================================================
# PAIEMENT MOBILE
# ============================================================

def test_initier_paiement_mobile_refuse_mode_invalide(
    client, make_user, auth_headers, db_session
):
    c = creer_client(db_session)
    facture = creer_facture(db_session, c.id)
    utilisateur = make_user("Client", client_id=c.id)

    response = client.post(
        "/api/v1/paiements/mobile/initier",
        json={
            "facture_id": facture.id,
            "montant": 1000,
            "mode_paiement": "Espèces",
        },
        headers=auth_headers(utilisateur),
    )

    assert response.status_code == 400


def test_initier_paiement_mobile_facture_introuvable(
    client, make_user, auth_headers
):
    utilisateur = make_user("Client")

    response = client.post(
        "/api/v1/paiements/mobile/initier",
        json={
            "facture_id": 999,
            "montant": 1000,
            "mode_paiement": "Orange Money",
        },
        headers=auth_headers(utilisateur),
    )

    assert response.status_code == 404


def test_initier_paiement_mobile_refuse_pour_la_facture_dun_autre_client(
    client, make_user, auth_headers, db_session
):
    autre = creer_client(db_session, "Autre")
    facture_autre = creer_facture(db_session, autre.id)

    moi = creer_client(db_session, "Moi")
    utilisateur = make_user("Client", client_id=moi.id)

    response = client.post(
        "/api/v1/paiements/mobile/initier",
        json={
            "facture_id": facture_autre.id,
            "montant": 1000,
            "mode_paiement": "MTN MoMo",
        },
        headers=auth_headers(utilisateur),
    )

    assert response.status_code == 403


def test_initier_paiement_mobile_force_le_statut_en_attente(
    client, make_user, auth_headers, db_session
):
    c = creer_client(db_session)
    facture = creer_facture(db_session, c.id, montant_ttc=10000)
    utilisateur = make_user("Client", client_id=c.id)

    response = client.post(
        "/api/v1/paiements/mobile/initier",
        json={
            "facture_id": facture.id,
            "montant": 10000,
            "mode_paiement": "MTN MoMo",
            "statut": "Validé",  # doit être ignoré et forcé à "En attente"
        },
        headers=auth_headers(utilisateur),
    )

    assert response.status_code == 201
    assert response.json()["statut"] == "En attente"

    db_session.refresh(facture)
    assert facture.statut == "Brouillon"


def test_confirmer_paiement_mobile_solde_la_facture(
    client, make_user, auth_headers, db_session
):
    c = creer_client(db_session)
    facture = creer_facture(db_session, c.id, montant_ttc=10000)
    paiement = creer_paiement(
        db_session,
        facture.id,
        10000,
        statut="En attente",
        mode_paiement="Orange Money",
    )
    utilisateur = make_user("Client", client_id=c.id)

    response = client.post(
        f"/api/v1/paiements/mobile/{paiement.id}/confirmer",
        headers=auth_headers(utilisateur),
    )

    assert response.status_code == 200
    assert response.json()["statut"] == "Validé"

    db_session.refresh(facture)
    assert facture.statut == "Payée"


def test_confirmer_paiement_deja_valide_est_refuse(
    client, make_user, auth_headers, db_session
):
    c = creer_client(db_session)
    facture = creer_facture(db_session, c.id)
    paiement = creer_paiement(
        db_session, facture.id, 1000, statut="Validé", mode_paiement="Orange Money"
    )
    utilisateur = make_user("Client", client_id=c.id)

    response = client.post(
        f"/api/v1/paiements/mobile/{paiement.id}/confirmer",
        headers=auth_headers(utilisateur),
    )

    assert response.status_code == 400


def test_confirmer_paiement_non_mobile_est_refuse(
    client, make_user, auth_headers, db_session
):
    c = creer_client(db_session)
    facture = creer_facture(db_session, c.id)
    paiement = creer_paiement(
        db_session, facture.id, 1000, statut="En attente", mode_paiement="Espèces"
    )
    utilisateur = make_user("Client", client_id=c.id)

    response = client.post(
        f"/api/v1/paiements/mobile/{paiement.id}/confirmer",
        headers=auth_headers(utilisateur),
    )

    assert response.status_code == 400


def test_confirmer_refuse_pour_le_paiement_dun_autre_client(
    client, make_user, auth_headers, db_session
):
    autre = creer_client(db_session, "Autre")
    facture_autre = creer_facture(db_session, autre.id)
    paiement = creer_paiement(
        db_session,
        facture_autre.id,
        1000,
        statut="En attente",
        mode_paiement="MTN MoMo",
    )

    moi = creer_client(db_session, "Moi")
    utilisateur = make_user("Client", client_id=moi.id)

    response = client.post(
        f"/api/v1/paiements/mobile/{paiement.id}/confirmer",
        headers=auth_headers(utilisateur),
    )

    assert response.status_code == 403


# ============================================================
# TAUX DE COMMISSION
# ============================================================

def test_taux_commission_est_accessible_a_tout_utilisateur_connecte(
    client, make_user, auth_headers
):
    utilisateur = make_user("Client")

    response = client.get("/api/v1/paiements/commission", headers=auth_headers(utilisateur))

    assert response.status_code == 200
    assert "taux" in response.json()
