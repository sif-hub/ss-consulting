from app.core.database import SessionLocal
from app.seeds.plan_comptable_syscohada import seed_plan_comptable
from app.seeds.seed_roles import seed_roles


def main():
    db = SessionLocal()

    try:
        nombre_roles = seed_roles(db)
        print(f"✓ Seed rôles terminé : {nombre_roles} rôle(s) ajouté(s).")

        nombre_comptes = seed_plan_comptable(db)
        print(f"✓ Seed comptes terminé : {nombre_comptes} compte(s) ajouté(s).")
    except Exception as e:
        db.rollback()
        print(f"✗ Erreur pendant le seed : {e}")
        raise
    finally:
        db.close()


if __name__ == "__main__":
    main()
