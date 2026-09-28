import pytest

from app.models.client import Client


CLIENT_MINIMAL = {
    "nom": "Dupont",
    "telephone": "699000000",
}


def creer_client(db_session, **overrides):
    data = {**CLIENT_MINIMAL, **overrides}
    client = Client(**data)
    db_session.add(client)
    db_session.commit()
    db_session.refresh(client)
    return client


# ============================================================
# CREATION
# ============================================================

@pytest.mark.parametrize(
    "role_nom",
    ["Administrateur", "Manager Secretariat", "Secretaire", "Comptable"],
)
def test_creation_autorisee_pour_le_staff(
    client, make_user, auth_headers, role_nom
):
    user = make_user(role_nom)

    response = client.post(
        "/api/v1/clients",
        json=CLIENT_MINIMAL,
        headers=auth_headers(user),
    )

    assert response.status_code == 201
    data = response.json()
    assert data["nom"] == "Dupont"
    assert data["telephone"] == "699000000"
    assert data["actif"] is True


@pytest.mark.parametrize("role_nom", ["Fiscaliste", "Client"])
def test_creation_refusee_pour_les_autres_roles(
    client, make_user, auth_headers, role_nom
):
    user = make_user(role_nom)

    response = client.post(
        "/api/v1/clients",
        json=CLIENT_MINIMAL,
        headers=auth_headers(user),
    )

    assert response.status_code == 403


def test_creation_sans_authentification_est_refusee(client):
    response = client.post("/api/v1/clients", json=CLIENT_MINIMAL)

    assert response.status_code == 401


def test_creation_sans_telephone_est_rejetee(client, make_user, auth_headers):
    user = make_user("Administrateur")

    response = client.post(
        "/api/v1/clients",
        json={"nom": "SansTelephone"},
        headers=auth_headers(user),
    )

    assert response.status_code == 422


# ============================================================
# LISTE
# ============================================================

def test_liste_admin_voit_tous_les_clients_actifs(
    client, make_user, auth_headers, db_session
):
    creer_client(db_session, nom="Alpha")
    creer_client(db_session, nom="Beta")
    inactif = creer_client(db_session, nom="Gamma")
    inactif.actif = False
    db_session.commit()

    admin = make_user("Administrateur")

    response = client.get("/api/v1/clients", headers=auth_headers(admin))

    assert response.status_code == 200
    noms = {c["nom"] for c in response.json()}
    assert noms == {"Alpha", "Beta"}


def test_liste_compte_client_ne_voit_que_son_propre_client(
    client, make_user, auth_headers, db_session
):
    mon_client = creer_client(db_session, nom="MonEntreprise")
    creer_client(db_session, nom="AutreEntreprise")

    utilisateur = make_user("Client", client_id=mon_client.id)

    response = client.get("/api/v1/clients", headers=auth_headers(utilisateur))

    assert response.status_code == 200
    data = response.json()
    assert len(data) == 1
    assert data[0]["nom"] == "MonEntreprise"


def test_liste_compte_client_non_rattache_est_vide(
    client, make_user, auth_headers, db_session
):
    creer_client(db_session, nom="AutreEntreprise")

    utilisateur = make_user("Client", client_id=None)

    response = client.get("/api/v1/clients", headers=auth_headers(utilisateur))

    assert response.status_code == 200
    assert response.json() == []


# ============================================================
# DETAIL
# ============================================================

def test_detail_client_introuvable_renvoie_404(client, make_user, auth_headers):
    admin = make_user("Administrateur")

    response = client.get("/api/v1/clients/999", headers=auth_headers(admin))

    assert response.status_code == 404


def test_compte_client_ne_peut_pas_voir_un_autre_client(
    client, make_user, auth_headers, db_session
):
    mon_client = creer_client(db_session, nom="MonEntreprise")
    autre_client = creer_client(db_session, nom="AutreEntreprise")

    utilisateur = make_user("Client", client_id=mon_client.id)

    response = client.get(
        f"/api/v1/clients/{autre_client.id}",
        headers=auth_headers(utilisateur),
    )

    assert response.status_code == 403


def test_compte_client_peut_voir_son_propre_client(
    client, make_user, auth_headers, db_session
):
    mon_client = creer_client(db_session, nom="MonEntreprise")
    utilisateur = make_user("Client", client_id=mon_client.id)

    response = client.get(
        f"/api/v1/clients/{mon_client.id}",
        headers=auth_headers(utilisateur),
    )

    assert response.status_code == 200
    assert response.json()["nom"] == "MonEntreprise"


# ============================================================
# MODIFICATION
# ============================================================

def test_modification_partielle_ne_touche_pas_les_autres_champs(
    client, make_user, auth_headers, db_session
):
    existant = creer_client(db_session, nom="Avant", ville="Douala")
    admin = make_user("Administrateur")

    response = client.put(
        f"/api/v1/clients/{existant.id}",
        json={"nom": "Après"},
        headers=auth_headers(admin),
    )

    assert response.status_code == 200
    data = response.json()
    assert data["nom"] == "Après"
    assert data["ville"] == "Douala"


def test_modification_client_introuvable_renvoie_404(
    client, make_user, auth_headers
):
    admin = make_user("Administrateur")

    response = client.put(
        "/api/v1/clients/999",
        json={"nom": "Peu importe"},
        headers=auth_headers(admin),
    )

    assert response.status_code == 404


def test_modification_refusee_pour_un_compte_client(
    client, make_user, auth_headers, db_session
):
    existant = creer_client(db_session, nom="Avant")
    mon_client = creer_client(db_session, nom="MonEntreprise")
    utilisateur = make_user("Client", client_id=mon_client.id)

    response = client.put(
        f"/api/v1/clients/{existant.id}",
        json={"nom": "Piraté"},
        headers=auth_headers(utilisateur),
    )

    assert response.status_code == 403


# ============================================================
# SUPPRESSION (désactivation)
# ============================================================

def test_suppression_desactive_sans_effacer_la_ligne(
    client, make_user, auth_headers, db_session
):
    existant = creer_client(db_session, nom="ADesactiver")
    admin = make_user("Administrateur")

    response = client.delete(
        f"/api/v1/clients/{existant.id}",
        headers=auth_headers(admin),
    )

    assert response.status_code == 204

    db_session.refresh(existant)
    assert existant.actif is False

    encore_present = (
        db_session.query(Client).filter(Client.id == existant.id).first()
    )
    assert encore_present is not None


def test_client_desactive_disparait_de_la_liste(
    client, make_user, auth_headers, db_session
):
    existant = creer_client(db_session, nom="ADesactiver")
    admin = make_user("Administrateur")

    client.delete(
        f"/api/v1/clients/{existant.id}",
        headers=auth_headers(admin),
    )

    response = client.get("/api/v1/clients", headers=auth_headers(admin))

    assert existant.id not in [c["id"] for c in response.json()]


def test_suppression_client_introuvable_renvoie_404(
    client, make_user, auth_headers
):
    admin = make_user("Administrateur")

    response = client.delete(
        "/api/v1/clients/999",
        headers=auth_headers(admin),
    )

    assert response.status_code == 404
