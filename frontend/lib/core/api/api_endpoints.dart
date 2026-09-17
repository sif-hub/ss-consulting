class ApiEndpoints {
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String me = '/auth/me';

  static const String clients = '/clients';
  static const String dossiers = '/dossiers';
  static String affecterDossier(int dossierId) =>
      '$dossiers/$dossierId/affecter';
  static String desaffecterDossier(int dossierId) =>
      '$dossiers/$dossierId/desaffecter';
  static const String mesDossiers = '$dossiers/mes-dossiers';
  static const String documents = '/documents';
  static const String factures = '/factures';
  static const String paiements = '/paiements';
  static const String depenses = '/depenses';

  // ============================================================
  // COMPTABILITE
  // ============================================================

  static const String comptabilite = '/comptabilite';

  static const String comptabiliteDashboard = '$comptabilite/dashboard';

  static const String recettesMensuelles = '$comptabilite/recettes-mensuelles';

  static const String depensesMensuelles = '$comptabilite/depenses-mensuelles';

  static const String depensesCategories = '$comptabilite/depenses-categories';

  static const String rapportAnnuel = '$comptabilite/rapport-annuel';

  static const String rapportTva = '$comptabilite/tva';

  static const String rapportTresorerie = '$comptabilite/tresorerie';

  static const String comptabiliteBalance = '$comptabilite/balance';

  static const String comptabiliteGrandLivre = '$comptabilite/grand-livre';

  static const String comptabiliteJournal = '$comptabilite/journal';

  static const String comptabiliteComptes = '$comptabilite/comptes';

  static const String comptabilitePeriodes = '$comptabilite/periodes';

  static const String comptabiliteEcritures = '$comptabilite/ecritures';

  static String validerEcriture(int ecritureId) =>
      '$comptabilite/ecritures/$ecritureId/valider';

  static const String comptabiliteClients = '$comptabilite/clients';

  static String initialiserComptabiliteClient(int clientId) =>
      '$comptabilite/clients/$clientId/initialiser';

  // PDF
  static const String comptabilitePdf = '/pdf/comptabilite';

  // ============================================================
  // INTELLIGENCE ARTIFICIELLE
  // ============================================================

  static const String iaChat = '/ia/chat';

  static const String iaSuggestionDeclaration = '/ia/declarations/observations';

  static String iaAnalyserDocument(int documentId) =>
      '/ia/documents/$documentId/analyser';
}
