import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import 'balance_page.dart';
import 'comptabilite_clients_page.dart';
import 'comptes_page.dart';
import 'rapports_page.dart';

class ComptabilitePage extends StatefulWidget {
  const ComptabilitePage({super.key});

  @override
  State<ComptabilitePage> createState() => _ComptabilitePageState();
}

class _ComptabilitePageState extends State<ComptabilitePage> {
  final ApiClient _apiClient = ApiClient();

  bool _loading = true;
  String? _error;

  int _annee = DateTime.now().year;

  Map<String, dynamic> _dashboard = {};
  List<dynamic> _recettes = [];
  List<dynamic> _depensesMensuelles = [];
  List<dynamic> _categories = [];

  @override
  void initState() {
    super.initState();
    _chargerDonnees();
  }

  Future<void> _chargerDonnees() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final responses = await Future.wait([
        _apiClient.dio.get(
          ApiEndpoints.comptabiliteDashboard,
          queryParameters: {'annee': _annee},
        ),
        _apiClient.dio.get(
          ApiEndpoints.recettesMensuelles,
          queryParameters: {'annee': _annee},
        ),
        _apiClient.dio.get(
          ApiEndpoints.depensesMensuelles,
          queryParameters: {'annee': _annee},
        ),
        _apiClient.dio.get(
          ApiEndpoints.depensesCategories,
          queryParameters: {'annee': _annee},
        ),
      ]);

      if (!mounted) return;

      setState(() {
        _dashboard = Map<String, dynamic>.from(responses[0].data as Map);

        _recettes = List<dynamic>.from(responses[1].data as List);

        _depensesMensuelles = List<dynamic>.from(responses[2].data as List);

        _categories = List<dynamic>.from(responses[3].data as List);

        _loading = false;
      });
    } on DioException catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = _messageErreur(e);
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = 'Une erreur inattendue est survenue.';
      });
    }
  }

  String _messageErreur(DioException e) {
    final status = e.response?.statusCode;

    if (status == 401) {
      return 'Session expirée. Veuillez vous reconnecter.';
    }

    if (status == 403) {
      return 'Vous n’avez pas les autorisations nécessaires.';
    }

    if (status == 404) {
      return 'Service de comptabilité introuvable.';
    }

    if (e.type == DioExceptionType.connectionError) {
      return 'Impossible de contacter le serveur.';
    }

    return 'Impossible de charger les données comptables.';
  }

  double _number(dynamic value) {
    if (value == null) return 0;

    if (value is num) return value.toDouble();

    return double.tryParse(value.toString()) ?? 0;
  }

  String _money(dynamic value) {
    final amount = _number(value);

    return '${amount.toStringAsFixed(0)} FCFA'.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => ' ',
    );
  }

  String _monthName(int month) {
    const months = [
      'Jan',
      'Fév',
      'Mar',
      'Avr',
      'Mai',
      'Juin',
      'Juil',
      'Aoû',
      'Sep',
      'Oct',
      'Nov',
      'Déc',
    ];

    if (month < 1 || month > 12) return '';

    return months[month - 1];
  }

  Map<String, dynamic> get _factures {
    return Map<String, dynamic>.from(_dashboard['factures'] ?? {});
  }

  Map<String, dynamic> get _paiements {
    return Map<String, dynamic>.from(_dashboard['paiements'] ?? {});
  }

  Map<String, dynamic> get _depenses {
    return Map<String, dynamic>.from(_dashboard['depenses'] ?? {});
  }

  Map<String, dynamic> get _resultats {
    return Map<String, dynamic>.from(_dashboard['resultats'] ?? {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: Navigator.of(context).canPop()
          ? AppBar(
              backgroundColor: const Color(0xFFF5F7FB),
              surfaceTintColor: const Color(0xFFF5F7FB),
              elevation: 0,
              foregroundColor: const Color(0xFF111827),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: _chargerDonnees,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(context)),
            SliverToBoxAdapter(child: _buildModulesNav(context)),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.only(top: 80),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF3155D9),
                        ),
                      ),
                    )
                  else if (_error != null)
                    _buildError()
                  else ...[
                    _buildMainIndicators(),
                    const SizedBox(height: 24),
                    _buildFinancialSummary(),
                    const SizedBox(height: 24),
                    _buildCharts(),
                    const SizedBox(height: 24),
                    _buildBottomSection(),
                  ],
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3155D9), Color(0xFF6C42D9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3155D9).withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 650;

          return Flex(
            direction: compact ? Axis.vertical : Axis.horizontal,
            crossAxisAlignment: compact
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: compact ? 0 : 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(11),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.account_balance_rounded,
                            color: Colors.white,
                            size: 27,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Text(
                          'Comptabilité',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Vue d’ensemble de la situation financière',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.82),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              if (compact) const SizedBox(height: 20),
              Row(
                children: [
                  _buildYearSelector(),
                  const SizedBox(width: 10),
                  _buildRefreshButton(),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildModulesNav(BuildContext context) {
    final modules = [
      (
        'Balance',
        'Soldes par compte (cabinet)',
        Icons.balance_rounded,
        const Color(0xFF3155D9),
        () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const BalancePage()),
        ),
      ),
      (
        'Comptes',
        'Journal & grand livre (cabinet)',
        Icons.menu_book_rounded,
        const Color(0xFF0F9D58),
        () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ComptesPage()),
        ),
      ),
      (
        'Rapports',
        'Annuel, TVA, trésorerie',
        Icons.summarize_rounded,
        const Color(0xFF7C3AED),
        () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const RapportsPage()),
        ),
      ),
      (
        'Clients',
        'Comptabilité tenue par client',
        Icons.groups_rounded,
        const Color(0xFFEA580C),
        () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const ComptabiliteClientsPage(),
          ),
        ),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 650;

          final cards = modules
              .map(
                (module) => _ModuleCard(
                  titre: module.$1,
                  sousTitre: module.$2,
                  icone: module.$3,
                  couleur: module.$4,
                  onTap: module.$5,
                ),
              )
              .toList();

          if (compact) {
            return Column(
              children: [
                for (final card in cards) ...[
                  card,
                  if (card != cards.last) const SizedBox(height: 12),
                ],
              ],
            );
          }

          return Row(
            children: [
              for (final card in cards) ...[
                Expanded(child: card),
                if (card != cards.last) const SizedBox(width: 12),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildYearSelector() {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _annee,
          dropdownColor: Colors.white,
          iconEnabledColor: Colors.white,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
          items: List.generate(5, (index) {
            final year = DateTime.now().year - index;

            return DropdownMenuItem(
              value: year,
              child: Text(
                'Exercice $year',
                style: const TextStyle(color: Color(0xFF111827)),
              ),
            );
          }),
          onChanged: (value) {
            if (value == null) return;

            setState(() {
              _annee = value;
            });

            _chargerDonnees();
          },
        ),
      ),
    );
  }

  Widget _buildRefreshButton() {
    return Material(
      color: Colors.white.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: _loading ? null : _chargerDonnees,
        borderRadius: BorderRadius.circular(12),
        child: const SizedBox(
          width: 44,
          height: 44,
          child: Icon(Icons.refresh_rounded, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildMainIndicators() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        int columns = 4;

        if (width < 700) {
          columns = 2;
        }

        if (width < 420) {
          columns = 1;
        }

        final cards = [
          _indicatorCard(
            title: 'Chiffre d’affaires',
            value: _money(_factures['chiffre_affaires_ht']),
            subtitle: 'Facturation HT',
            icon: Icons.trending_up_rounded,
            iconColor: const Color(0xFF10B981),
          ),
          _indicatorCard(
            title: 'Encaissements',
            value: _money(_paiements['total_encaisse']),
            subtitle: 'Paiements validés',
            icon: Icons.payments_rounded,
            iconColor: const Color(0xFF0EA5E9),
          ),
          _indicatorCard(
            title: 'Dépenses',
            value: _money(_depenses['total_ttc']),
            subtitle: 'Dépenses TTC',
            icon: Icons.shopping_cart_rounded,
            iconColor: const Color(0xFFF59E0B),
          ),
          _indicatorCard(
            title: 'Résultat',
            value: _money(_resultats['benefice']),
            subtitle: 'Bénéfice estimé',
            icon: Icons.account_balance_wallet_rounded,
            iconColor: const Color(0xFF8B5CF6),
          ),
        ];

        return GridView.count(
          crossAxisCount: columns,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: width < 700 ? 1.3 : 1.05,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: cards,
        );
      },
    );
  }

  Widget _indicatorCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const Spacer(),
              const Icon(Icons.more_horiz_rounded, color: Color(0xFF9CA3AF)),
            ],
          ),
          const Spacer(),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 5),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF111827),
                fontSize: 21,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialSummary() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Synthèse financière', Icons.analytics_outlined),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 700;

              final items = [
                _summaryItem(
                  'Créances clients',
                  _money(_resultats['creances_clients']),
                  Icons.people_alt_outlined,
                  const Color(0xFFEF4444),
                ),
                _summaryItem(
                  'Trésorerie',
                  _money(_resultats['solde_tresorerie']),
                  Icons.account_balance_rounded,
                  const Color(0xFF10B981),
                ),
                _summaryItem(
                  'TVA collectée',
                  _money(_factures['tva_collectee']),
                  Icons.receipt_long_outlined,
                  const Color(0xFF3155D9),
                ),
                _summaryItem(
                  'TVA à payer',
                  _money(_resultats['tva_a_payer']),
                  Icons.warning_amber_rounded,
                  const Color(0xFFF59E0B),
                ),
              ];

              if (compact) {
                return Column(
                  children: items
                      .map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: item,
                        ),
                      )
                      .toList(),
                );
              }

              return Row(
                children: [
                  for (int i = 0; i < items.length; i++) ...[
                    Expanded(child: items[i]),
                    if (i < items.length - 1)
                      Container(
                        width: 1,
                        height: 55,
                        margin: const EdgeInsets.symmetric(horizontal: 12),
                        color: const Color(0xFFE5E7EB),
                      ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _summaryItem(String title, String value, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.09),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 21),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  color: Color(0xFF111827),
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCharts() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 850) {
          return Column(
            children: [
              _buildMonthlyChart(
                title: 'Encaissements mensuels',
                data: _recettes,
                valueKey: 'montant',
                barColor: const Color(0xFF3155D9),
              ),
              const SizedBox(height: 20),
              _buildMonthlyChart(
                title: 'Dépenses mensuelles',
                data: _depensesMensuelles,
                valueKey: 'montant',
                barColor: const Color(0xFFF59E0B),
              ),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildMonthlyChart(
                title: 'Encaissements mensuels',
                data: _recettes,
                valueKey: 'montant',
                barColor: const Color(0xFF3155D9),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: _buildMonthlyChart(
                title: 'Dépenses mensuelles',
                data: _depensesMensuelles,
                valueKey: 'montant',
                barColor: const Color(0xFFF59E0B),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMonthlyChart({
    required String title,
    required List<dynamic> data,
    required String valueKey,
    required Color barColor,
  }) {
    final values = data.map((item) {
      final map = Map<String, dynamic>.from(item as Map);
      return _number(map[valueKey]);
    }).toList();

    final maxValue = values.isEmpty
        ? 0.0
        : values.reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(title, Icons.bar_chart_rounded),
          const SizedBox(height: 25),
          SizedBox(
            height: 210,
            child: data.isEmpty
                ? const Center(
                    child: Text(
                      'Aucune donnée disponible',
                      style: TextStyle(color: Color(0xFF9CA3AF)),
                    ),
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(data.length, (index) {
                      final item = Map<String, dynamic>.from(
                        data[index] as Map,
                      );

                      final value = _number(item[valueKey]);

                      final ratio = maxValue <= 0 ? 0.0 : value / maxValue;

                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (value > 0)
                                FittedBox(
                                  child: Text(
                                    _compactMoney(value),
                                    style: const TextStyle(
                                      fontSize: 9,
                                      color: Color(0xFF6B7280),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 5),
                              Container(
                                height: 125 * ratio + 3,
                                decoration: BoxDecoration(
                                  color: barColor,
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(6),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 7),
                              Text(
                                _monthName(_number(item['mois']).toInt()),
                                style: const TextStyle(
                                  fontSize: 9,
                                  color: Color(0xFF9CA3AF),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
          ),
        ],
      ),
    );
  }

  String _compactMoney(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)} M';
    }

    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)} K';
    }

    return value.toStringAsFixed(0);
  }

  Widget _buildBottomSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 850) {
          return Column(
            children: [
              _buildExpenseCategories(),
              const SizedBox(height: 20),
              _buildStatistics(),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 3, child: _buildExpenseCategories()),
            const SizedBox(width: 20),
            Expanded(flex: 2, child: _buildStatistics()),
          ],
        );
      },
    );
  }

  Widget _buildExpenseCategories() {
    final total = _categories.fold<double>(0, (sum, item) {
      final map = Map<String, dynamic>.from(item as Map);

      return sum + _number(map['montant']);
    });

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            'Dépenses par catégorie',
            Icons.pie_chart_outline_rounded,
          ),
          const SizedBox(height: 20),
          if (_categories.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: Text(
                  'Aucune dépense enregistrée.',
                  style: TextStyle(color: Color(0xFF9CA3AF)),
                ),
              ),
            )
          else
            ..._categories.take(6).map((item) {
              final map = Map<String, dynamic>.from(item as Map);

              final amount = _number(map['montant']);

              final percentage = total <= 0 ? 0 : amount / total;

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            map['categorie']?.toString() ?? 'Sans catégorie',
                            style: const TextStyle(
                              color: Color(0xFF374151),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          _money(amount),
                          style: const TextStyle(
                            color: Color(0xFF111827),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: LinearProgressIndicator(
                        value: percentage.toDouble(),
                        minHeight: 7,
                        backgroundColor: const Color(0xFFF1F3F7),
                        valueColor: const AlwaysStoppedAnimation(
                          Color(0xFF6C42D9),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildStatistics() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Activité', Icons.insights_rounded),
          const SizedBox(height: 18),
          _statRow(
            'Factures',
            '${_factures['nombre'] ?? 0}',
            Icons.receipt_long_outlined,
          ),
          _statRow(
            'Paiements',
            '${_paiements['nombre'] ?? 0}',
            Icons.payments_outlined,
          ),
          _statRow(
            'Dépenses',
            '${_depenses['nombre'] ?? 0}',
            Icons.shopping_bag_outlined,
          ),
          _statRow(
            'Commissions',
            _money(_paiements['total_commissions']),
            Icons.percent_rounded,
          ),
        ],
      ),
    );
  }

  Widget _statRow(String title, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F7FB),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 18, color: const Color(0xFF3155D9)),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF111827),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF3155D9).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, size: 19, color: const Color(0xFF3155D9)),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF111827),
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFE5E7EB)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.025),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  Widget _buildError() {
    return Container(
      margin: const EdgeInsets.only(top: 60),
      padding: const EdgeInsets.all(30),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            size: 52,
            color: Color(0xFFEF4444),
          ),
          const SizedBox(height: 16),
          const Text(
            'Impossible de charger la comptabilité',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF111827),
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _chargerDonnees,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Réessayer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3155D9),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  final String titre;
  final String sousTitre;
  final IconData icone;
  final Color couleur;
  final VoidCallback onTap;

  const _ModuleCard({
    required this.titre,
    required this.sousTitre,
    required this.icone,
    required this.couleur,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: couleur.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icone, color: couleur, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titre,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      sousTitre,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}
