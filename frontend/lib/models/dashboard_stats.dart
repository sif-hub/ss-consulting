class DashboardStats {
  final int clients;
  final int dossiers;
  final int documents;
  final int factures;
  final int paiements;
  final int depenses;
  final int impayes;

  const DashboardStats({
    required this.clients,
    required this.dossiers,
    required this.documents,
    required this.factures,
    required this.paiements,
    required this.depenses,
    required this.impayes,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      clients: json['clients'] ?? 0,
      dossiers: json['dossiers'] ?? 0,
      documents: json['documents'] ?? 0,
      factures: json['factures'] ?? 0,
      paiements: json['paiements'] ?? 0,
      depenses: json['depenses'] ?? 0,
      impayes: json['impayes'] ?? 0,
    );
  }
}

