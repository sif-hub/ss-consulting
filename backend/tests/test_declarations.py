import pytest

from app.models.client import Client
from app.models.declaration import Declaration
from app.models.notification import Notification


def creer_client(db_session, nom="Client Test"):
    c = Client(nom=nom, telephone="699000000")
    db_session.add(c)
    db_session.commit()
    db_session.refresh(c)
    return c


def creer_declaration(
    db_session, client_id, mois=1, annee=2026, statut="BROUILLON", **overrides
):
    from datetime import datetime

    d = Declaration(
        client_id=client_id,
        mois=mois,
        annee=annee,
        chiffre_affaires=0,
        total_ventes=0,
        total_achats=0,
        nombre_employes=0,
        statut=statut,
        date_creation=datetime.utcnow(),
        **overrides,
    )
    db_session.add(d)
    db_session.commit()
    db_session.refresh(d)
    return d


DECLARATION_PAYLOAD = {
    "mois": 3,
    "annee": 2026,
    "chiffre_affaires": 1000000,
    "total_ventes": 800000,
    "total_achats": 200000,
    "nombre_employes": 4,
}


# ============================================================
# CREATION
# ============================================================

def test_admin_cree_une_declaration_pour_un_client(
    client, make_user, auth_headers, db_session
):
    mon_client = creer_client(db_session)
    admin = make_user("Administrateur")

    response = client.post(
        "/api/v1/declarations",
        json={**DECLARATION_PAYLOAD, "client_id": mon_client.id},
        headers=auth_headers(admin),
    )

    assert response.status_code == 201
    data = response.json()
    assert data["client_id"] == mon_client.id
    assert data["statut"] == "BROUILLON"
    assert float(data["chiffre_affaires"]) == 1000000


def test_admin_sans_client_id_est_rejete(client, make_user, auth_headers):
    admin = make_user("Administrateur")

    response = client.post(
        "/api/v1/declarations",
        json=DECLARATION_PAYLOAD,
        headers=auth_headers(admin),
    )

    assert response.status_code == 400


def test_compte_client_cree_sa_propre_declaration_sans_client_id(
    client, make_user, auth_headers, db_session
):
    utilisateur = make_user("Client", client_id=None)

    response = client.post(
        "/api/v1/declarations",
        json=DECLARATION_PAYLOAD,
        headers=auth_headers(utilisateur),
    )

    assert response.status_code == 201
    data = response.json()

    db_session.refresh(utilisateur)
    assert utilisateur.client_id is not None
    assert data["client_id"] == utilisateur.client_id


@pytest.mark.parametrize("role_nom", ["Fiscaliste", "Secretaire", "Comptable"])
def test_creation_refusee_pour_les_roles_non_autorises(
    client, make_user, auth_headers, db_session, role_nom
):
    mon_client = creer_client(db_session)
    user = make_user(role_nom)

    response = client.post(
        "/api/v1/declarations",
        json={**DECLARATION_PAYLOAD, "client_id": mon_client.id},
        headers=auth_headers(user),
    )

    assert response.status_code == 403


def test_double_declaration_meme_periode_est_refusee(
    client, make_user, auth_headers, db_session
):
    mon_client = creer_client(db_session)
    admin = make_user("Administrateur")

    payload = {**DECLARATION_PAYLOAD, "client_id": mon_client.id}
    client.post("/api/v1/declarations", json=payload, headers=auth_headers(admin))

    response = client.post(
        "/api/v1/declarations", json=payload, headers=auth_headers(admin)
    )

    assert response.status_code == 409


# ============================================================
# LISTE / DETAIL
# ============================================================

def test_compte_client_ne_voit_que_ses_declarations(
    client, make_user, auth_headers, db_session
):
    mon_client = creer_client(db_session, "Moi")
    autre_client = creer_client(db_session, "Autre")
    creer_declaration(db_session, mon_client.id, mois=1)
    creer_declaration(db_session, autre_client.id, mois=2)

    utilisateur = make_user("Client", client_id=mon_client.id)

    response = client.get("/api/v1/declarations", headers=auth_headers(utilisateur))

    assert response.status_code == 200
    data = response.json()
    assert len(data) == 1
    assert data[0]["client_id"] == mon_client.id


def test_filtre_statut_invalide_renvoie_400(client, make_user, auth_headers):
    admin = make_user("Administrateur")

    response = client.get(
        "/api/v1/declarations?statut=INVENTE",
        headers=auth_headers(admin),
    )

    assert response.status_code == 400


def test_detail_introuvable_renvoie_404(client, make_user, auth_headers):
    admin = make_user("Administrateur")

    response = client.get("/api/v1/declarations/999", headers=auth_headers(admin))

    assert response.status_code == 404


def test_compte_client_ne_peut_pas_voir_la_declaration_dun_autre(
    client, make_user, auth_headers, db_session
):
    autre_client = creer_client(db_session, "Autre")
    declaration = creer_declaration(db_session, autre_client.id)

    mon_client = creer_client(db_session, "Moi")
    utilisateur = make_user("Client", client_id=mon_client.id)

    response = client.get(
        f"/api/v1/declarations/{declaration.id}",
        headers=auth_headers(utilisateur),
    )

    assert response.status_code == 403


# ============================================================
# MODIFICATION
# ============================================================

def test_modification_en_brouillon_est_acceptee(
    client, make_user, auth_headers, db_session
):
    mon_client = creer_client(db_session)
    declaration = creer_declaration(db_session, mon_client.id, statut="BROUILLON")
    admin = make_user("Administrateur")

    response = client.put(
        f"/api/v1/declarations/{declaration.id}",
        json={**DECLARATION_PAYLOAD, "chiffre_affaires": 5000},
        headers=auth_headers(admin),
    )

    assert response.status_code == 200
    assert float(response.json()["chiffre_affaires"]) == 5000


def test_modification_a_corriger_repasse_en_brouillon(
    client, make_user, auth_headers, db_session
):
    mon_client = creer_client(db_session)
    declaration = creer_declaration(
        db_session,
        mon_client.id,
        statut="A_CORRIGER",
        commentaire_admin="À revoir",
    )
    admin = make_user("Administrateur")

    response = client.put(
        f"/api/v1/declarations/{declaration.id}",
        json=DECLARATION_PAYLOAD,
        headers=auth_headers(admin),
    )

    assert response.status_code == 200
    data = response.json()
    assert data["statut"] == "BROUILLON"
    assert data["commentaire_admin"] is None


@pytest.mark.parametrize("statut", ["SOUMISE", "EN_VERIFICATION", "VALIDEE"])
def test_modification_impossible_hors_brouillon(
    client, make_user, auth_headers, db_session, statut
):
    mon_client = creer_client(db_session)
    declaration = creer_declaration(db_session, mon_client.id, statut=statut)
    admin = make_user("Administrateur")

    response = client.put(
        f"/api/v1/declarations/{declaration.id}",
        json=DECLARATION_PAYLOAD,
        headers=auth_headers(admin),
    )

    assert response.status_code == 400


# ============================================================
# SOUMISSION
# ============================================================

def test_soumission_change_le_statut_et_notifie_admin_et_fiscaliste(
    client, make_user, auth_headers, db_session
):
    mon_client = creer_client(db_session)
    declaration = creer_declaration(db_session, mon_client.id, statut="BROUILLON")

    admin = make_user("Administrateur")
    fiscaliste = make_user("Fiscaliste")  # doit aussi recevoir une notification
    make_user("Secretaire")  # ne doit PAS en recevoir

    response = client.post(
        f"/api/v1/declarations/{declaration.id}/soumettre",
        headers=auth_headers(admin),
    )

    assert response.status_code == 200
    data = response.json()
    assert data["statut"] == "SOUMISE"
    assert data["date_soumission"] is not None

    notifications = (
        db_session.query(Notification)
        .filter(Notification.reference_id == declaration.id)
        .all()
    )
    destinataires = {n.utilisateur_id for n in notifications}
    assert destinataires == {admin.id, fiscaliste.id}


def test_soumission_impossible_si_deja_soumise(
    client, make_user, auth_headers, db_session
):
    mon_client = creer_client(db_session)
    declaration = creer_declaration(db_session, mon_client.id, statut="SOUMISE")
    admin = make_user("Administrateur")

    response = client.post(
        f"/api/v1/declarations/{declaration.id}/soumettre",
        headers=auth_headers(admin),
    )

    assert response.status_code == 400


# ============================================================
# MISE EN VERIFICATION
# ============================================================

def test_mise_en_verification_par_le_fiscaliste(
    client, make_user, auth_headers, db_session
):
    mon_client = creer_client(db_session)
    declaration = creer_declaration(db_session, mon_client.id, statut="SOUMISE")
    fiscaliste = make_user("Fiscaliste")

    response = client.post(
        f"/api/v1/declarations/{declaration.id}/verification",
        headers=auth_headers(fiscaliste),
    )

    assert response.status_code == 200
    data = response.json()
    assert data["statut"] == "EN_VERIFICATION"
    assert data["traite_par_id"] == fiscaliste.id


def test_mise_en_verification_refusee_pour_le_comptable(
    client, make_user, auth_headers, db_session
):
    mon_client = creer_client(db_session)
    declaration = creer_declaration(db_session, mon_client.id, statut="SOUMISE")
    comptable = make_user("Comptable")

    response = client.post(
        f"/api/v1/declarations/{declaration.id}/verification",
        headers=auth_headers(comptable),
    )

    assert response.status_code == 403


def test_mise_en_verification_impossible_si_pas_soumise(
    client, make_user, auth_headers, db_session
):
    mon_client = creer_client(db_session)
    declaration = creer_declaration(db_session, mon_client.id, statut="BROUILLON")
    fiscaliste = make_user("Fiscaliste")

    response = client.post(
        f"/api/v1/declarations/{declaration.id}/verification",
        headers=auth_headers(fiscaliste),
    )

    assert response.status_code == 400


# ============================================================
# TRAITEMENT (validation / correction / rejet)
# ============================================================

def test_validation_notifie_le_client(client, make_user, auth_headers, db_session):
    mon_client = creer_client(db_session)
    declaration = creer_declaration(
        db_session, mon_client.id, statut="EN_VERIFICATION"
    )
    fiscaliste = make_user("Fiscaliste")
    client_user = make_user("Client", client_id=mon_client.id)

    response = client.post(
        f"/api/v1/declarations/{declaration.id}/traiter",
        json={"statut": "VALIDEE"},
        headers=auth_headers(fiscaliste),
    )

    assert response.status_code == 200
    data = response.json()
    assert data["statut"] == "VALIDEE"
    assert data["date_validation"] is not None

    notif = (
        db_session.query(Notification)
        .filter(
            Notification.reference_id == declaration.id,
            Notification.utilisateur_id == client_user.id,
        )
        .first()
    )
    assert notif is not None
    assert notif.type == "DECLARATION_VALIDEE"


@pytest.mark.parametrize("statut", ["A_CORRIGER", "REJETEE"])
def test_correction_ou_rejet_exige_un_commentaire(
    client, make_user, auth_headers, db_session, statut
):
    mon_client = creer_client(db_session)
    declaration = creer_declaration(db_session, mon_client.id, statut="SOUMISE")
    admin = make_user("Administrateur")

    response = client.post(
        f"/api/v1/declarations/{declaration.id}/traiter",
        json={"statut": statut},
        headers=auth_headers(admin),
    )

    assert response.status_code == 400


def test_rejet_avec_commentaire_est_accepte(
    client, make_user, auth_headers, db_session
):
    mon_client = creer_client(db_session)
    declaration = creer_declaration(db_session, mon_client.id, statut="SOUMISE")
    admin = make_user("Administrateur")

    response = client.post(
        f"/api/v1/declarations/{declaration.id}/traiter",
        json={"statut": "REJETEE", "commentaire_admin": "Montants incohérents"},
        headers=auth_headers(admin),
    )

    assert response.status_code == 200
    data = response.json()
    assert data["statut"] == "REJETEE"
    assert data["commentaire_admin"] == "Montants incohérents"


def test_traitement_refuse_statut_invalide(
    client, make_user, auth_headers, db_session
):
    mon_client = creer_client(db_session)
    declaration = creer_declaration(db_session, mon_client.id, statut="SOUMISE")
    admin = make_user("Administrateur")

    response = client.post(
        f"/api/v1/declarations/{declaration.id}/traiter",
        json={"statut": "PAS_UN_STATUT"},
        headers=auth_headers(admin),
    )

    assert response.status_code == 422


def test_traitement_impossible_sur_un_brouillon(
    client, make_user, auth_headers, db_session
):
    mon_client = creer_client(db_session)
    declaration = creer_declaration(db_session, mon_client.id, statut="BROUILLON")
    admin = make_user("Administrateur")

    response = client.post(
        f"/api/v1/declarations/{declaration.id}/traiter",
        json={"statut": "VALIDEE"},
        headers=auth_headers(admin),
    )

    assert response.status_code == 400


def test_traitement_refuse_pour_la_secretaire(
    client, make_user, auth_headers, db_session
):
    mon_client = creer_client(db_session)
    declaration = creer_declaration(db_session, mon_client.id, statut="SOUMISE")
    secretaire = make_user("Secretaire")

    response = client.post(
        f"/api/v1/declarations/{declaration.id}/traiter",
        json={"statut": "VALIDEE"},
        headers=auth_headers(secretaire),
    )

    assert response.status_code == 403
