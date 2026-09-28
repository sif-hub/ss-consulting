def test_login_reussi_renvoie_un_token(client, utilisateur_actif):
    response = client.post(
        "/api/v1/auth/login",
        json={
            "email": "test@example.com",
            "mot_de_passe": "motdepasse123",
        },
    )

    assert response.status_code == 200

    data = response.json()
    assert data["access_token"]
    assert data["user"]["email"] == "test@example.com"
    assert data["user"]["role"] == "Client"


def test_login_mauvais_mot_de_passe_est_refuse(client, utilisateur_actif):
    response = client.post(
        "/api/v1/auth/login",
        json={
            "email": "test@example.com",
            "mot_de_passe": "mauvais-mot-de-passe",
        },
    )

    assert response.status_code == 401
    assert response.json()["detail"] == "Email ou mot de passe incorrect"


def test_login_email_inconnu_est_refuse(client, role_client):
    response = client.post(
        "/api/v1/auth/login",
        json={
            "email": "inconnu@example.com",
            "mot_de_passe": "peu-importe",
        },
    )

    assert response.status_code == 401
    assert response.json()["detail"] == "Email ou mot de passe incorrect"


def test_login_compte_desactive_est_refuse(client, utilisateur_desactive):
    response = client.post(
        "/api/v1/auth/login",
        json={
            "email": "inactif@example.com",
            "mot_de_passe": "motdepasse123",
        },
    )

    assert response.status_code == 403
    assert response.json()["detail"] == "Compte désactivé"


def test_token_du_login_donne_acces_a_auth_me(client, utilisateur_actif):
    login = client.post(
        "/api/v1/auth/login",
        json={
            "email": "test@example.com",
            "mot_de_passe": "motdepasse123",
        },
    )
    token = login.json()["access_token"]

    me = client.get(
        "/api/v1/auth/me",
        headers={"Authorization": f"Bearer {token}"},
    )

    assert me.status_code == 200
    assert me.json()["email"] == "test@example.com"
