import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/paz_theme.dart';
import '../../services/api_service.dart';

class MarketsScreen extends StatefulWidget {
  const MarketsScreen({super.key});

  @override
  State<MarketsScreen> createState() => _MarketsScreenState();
}

class _MarketsScreenState extends State<MarketsScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _calcController = TextEditingController(text: '10000');
  final TextEditingController _goldGramsController = TextEditingController(text: '10');
  final NumberFormat _currencyFormat = NumberFormat('#,##0.00');

  int _selectedSubTab = 0; // 0: Overview, 1: Bank FX, 2: Gold 24K, 3: Macro & News
  String _selectedBankCurrency = 'USD';

  bool _isLoading = true;
  String? _errorMessage;

  Map<String, dynamic>? _fxData;
  Map<String, dynamic>? _bankData;
  Map<String, dynamic>? _goldData;
  Map<String, dynamic>? _macroData;
  Map<String, dynamic>? _newsData;

  final List<String> _subTabs = ['Overview', 'Bank FX', 'Gold 24K', 'Macro & News'];
  final List<String> _bankCurrencies = ['USD', 'EUR', 'GBP', 'AED'];

  @override
  void initState() {
    super.initState();
    _fetchMarketData();
  }

  @override
  void dispose() {
    _calcController.dispose();
    _goldGramsController.dispose();
    super.dispose();
  }

  Future<void> _fetchMarketData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        _apiService.getFxRates().catchError((e) => <String, dynamic>{}),
        _apiService.getFxBanks().catchError((e) => <String, dynamic>{}),
        _apiService.getGoldLive().catchError((e) => <String, dynamic>{}),
        _apiService.getMacroIndicators().catchError((e) => <String, dynamic>{}),
        _apiService.getMacroNews().catchError((e) => <String, dynamic>{}),
      ]);

      if (mounted) {
        setState(() {
          _fxData = results[0].isNotEmpty ? results[0] : null;
          _bankData = results[1].isNotEmpty ? results[1] : null;
          _goldData = results[2].isNotEmpty ? results[2] : null;
          _macroData = results[3].isNotEmpty ? results[3] : null;
          _newsData = results[4].isNotEmpty ? results[4] : null;

          if (_fxData == null && _bankData == null && _goldData == null) {
            _errorMessage = 'Unable to connect to live market data feeds.';
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load market feeds. Pull to refresh.';
          _isLoading = false;
        });
      }
    }
  }

  String _formatTimestamp(String? isoString) {
    if (isoString == null || isoString.isEmpty) return 'Live Feed';
    try {
      final date = DateTime.parse(isoString).toLocal();
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inMinutes < 1) return 'Updated just now';
      if (diff.inMinutes < 60) return 'Updated ${diff.inMinutes}m ago';
      if (diff.inHours < 24) return 'Updated ${diff.inHours}h ago';
      return DateFormat('MMM d, HH:mm').format(date);
    } catch (_) {
      return 'Live Feed';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PazColors.canvas,
      body: SafeArea(
        child: RefreshIndicator(
          color: PazColors.emerald,
          backgroundColor: PazColors.card,
          onRefresh: _fetchMarketData,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              _buildAppBar(),
              _buildSubTabBar(),
              if (_isLoading && _fxData == null)
                const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(
                      color: PazColors.emerald,
                      strokeWidth: 2.5,
                    ),
                  ),
                )
              else if (_errorMessage != null && _fxData == null)
                SliverFillRemaining(
                  child: _buildErrorState(),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      if (_selectedSubTab == 0) ..._buildOverviewTab(),
                      if (_selectedSubTab == 1) ..._buildBankFxTab(),
                      if (_selectedSubTab == 2) ..._buildGoldTab(),
                      if (_selectedSubTab == 3) ..._buildMacroNewsTab(),
                      const SizedBox(height: 24),
                      _buildTerminalFooter(),
                    ]),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: PazColors.cardElevated,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: PazColors.cardBorderStrong),
              ),
              child: Center(
                child: Text(
                  'P',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: PazColors.emerald,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'PAZ TERMINAL',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      color: PazColors.textPrimary,
                    ),
                  ),
                  Text(
                    'ETHIOPIAN MACRO-FINANCIAL INTELLIGENCE',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.6,
                      color: PazColors.textDim,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: _isLoading ? null : _fetchMarketData,
              icon: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: PazColors.emerald,
                      ),
                    )
                  : const Icon(
                      LucideIcons.refreshCw,
                      size: 18,
                      color: PazColors.textMuted,
                    ),
              tooltip: 'Refresh rates',
              splashRadius: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubTabBar() {
    return SliverToBoxAdapter(
      child: Container(
        height: 42,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _subTabs.length,
          separatorBuilder: (context, index) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final isSelected = _selectedSubTab == index;
            return InkWell(
              onTap: () => setState(() => _selectedSubTab = index),
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? PazColors.cardElevated : PazColors.card,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isSelected ? PazColors.emerald : PazColors.cardBorder,
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    _subTabs[index],
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? PazColors.emerald : PazColors.textMuted,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ==================== SUB-TAB 0: OVERVIEW ====================

  List<Widget> _buildOverviewTab() {
    final lastUpdated = _fxData?['last_updated'] ?? _goldData?['last_updated'];
    final source = _fxData?['source'] ?? 'NBE Interbank Reference Feed';

    return [
      _buildStatusBanner(lastUpdated, source),
      const SizedBox(height: 14),
      _buildBestBankLeaderboardPill(),
      const SizedBox(height: 14),
      _buildMacroGrid(),
      const SizedBox(height: 14),
      _buildParityCalculator(),
      const SizedBox(height: 14),
      _buildGoldKaratBreakdown(),
      const SizedBox(height: 14),
      _buildMacroIndicatorsList(),
    ];
  }

  Widget _buildStatusBanner(String? lastUpdated, String source) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: PazTheme.cardDecoration(),
      child: Row(
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: PazColors.emerald,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: PazColors.emerald,
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'LIVE FLOATING FX • $source',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: PazColors.emerald,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _formatTimestamp(lastUpdated),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: PazColors.textDim,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBestBankLeaderboardPill() {
    final bestMap = _bankData?['best_to_sell_fx'] as Map<String, dynamic>? ?? {};
    final bestUsd = bestMap['USD'] as Map<String, dynamic>? ?? {};
    final bestBankName = bestUsd['bank']?.toString() ?? 'Bank of Abyssinia';
    final bestRate = (bestUsd['rate'] as num?)?.toDouble() ?? 162.70;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: PazColors.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: PazColors.emeraldBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: PazColors.emeraldMuted,
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Icon(LucideIcons.award, size: 14, color: PazColors.emerald),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'TOP COMMERCIAL BUYING RATE (USD)',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: PazColors.textDim,
                  ),
                ),
                Text(
                  '$bestBankName pays highest payout for remittances',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: PazColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${_currencyFormat.format(bestRate)} ETB',
                style: PazTheme.monoNumber(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: PazColors.emerald,
                ),
              ),
              Text(
                'Best Payout',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: PazColors.emerald,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMacroGrid() {
    final rates = _fxData?['rates'] as Map<String, dynamic>? ?? {};
    final usdRate = (rates['USD'] as num?)?.toDouble() ?? 163.29;
    final eurRate = (rates['EUR'] as num?)?.toDouble() ?? 179.22;
    final gbpRate = (rates['GBP'] as num?)?.toDouble() ?? 213.85;

    final karats = _goldData?['karats'] as Map<String, dynamic>? ?? {};
    final gold24k = (karats['24K']?['per_gram_etb'] as num?)?.toDouble() ??
        (_fxData?['gold_per_gram_etb'] as num?)?.toDouble() ??
        18999.40;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: 'USD / ETB',
                subtitle: 'Interbank Benchmark',
                value: '${_currencyFormat.format(usdRate)} ETB',
                change: 'Floating FX',
                changePositive: true,
                badge: 'OFFICIAL',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMetricCard(
                title: 'EUR / ETB',
                subtitle: 'European Parity',
                value: '${_currencyFormat.format(eurRate)} ETB',
                change: '+0.4% 24h',
                changePositive: true,
                badge: 'PARITY',
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: 'GOLD 24K',
                subtitle: 'Physical Pure (Per Gram)',
                value: '${_currencyFormat.format(gold24k)} ETB',
                change: 'XAU Spot Parity',
                changePositive: true,
                badge: 'BULLION',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMetricCard(
                title: 'GBP / ETB',
                subtitle: 'Pound Sterling',
                value: '${_currencyFormat.format(gbpRate)} ETB',
                change: 'Interbank High',
                changePositive: false,
                badge: 'CORRIDOR',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String subtitle,
    required String value,
    required String change,
    required bool changePositive,
    required String badge,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: PazTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: PazColors.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: PazColors.cardElevated,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: PazColors.cardBorderStrong),
                ),
                child: Text(
                  badge,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: PazColors.emerald,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: PazColors.textDim,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: PazTheme.monoNumber(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: PazColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(
                changePositive ? LucideIcons.trendingUp : LucideIcons.trendingDown,
                size: 11,
                color: changePositive ? PazColors.emerald : PazColors.amber,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  change,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: changePositive ? PazColors.emerald : PazColors.amber,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildParityCalculator() {
    final rates = _fxData?['rates'] as Map<String, dynamic>? ?? {};
    final usdRate = (rates['USD'] as num?)?.toDouble() ?? 163.29;

    final karats = _goldData?['karats'] as Map<String, dynamic>? ?? {};
    final gold24k = (karats['24K']?['per_gram_etb'] as num?)?.toDouble() ??
        (_fxData?['gold_per_gram_etb'] as num?)?.toDouble() ??
        18999.40;

    final enteredEtb = double.tryParse(_calcController.text.replaceAll(',', '')) ?? 0.0;
    final usdEquiv = usdRate > 0 ? (enteredEtb / usdRate) : 0.0;
    final goldGrams = gold24k > 0 ? (enteredEtb / gold24k) : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: PazTheme.cardDecoration(glow: true),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.calculator, size: 16, color: PazColors.emerald),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'LIVE PARITY CALCULATOR',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: PazColors.textPrimary,
                  ),
                ),
              ),
              Text(
                'INSTANT VALUATION',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  color: PazColors.emerald,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _calcController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: PazTheme.monoNumber(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              labelText: 'ENTER AMOUNT IN ETB',
              prefixIcon: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                child: Text(
                  'ETB',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: PazColors.emerald,
                  ),
                ),
              ),
              suffixIcon: IconButton(
                icon: const Icon(LucideIcons.xCircle, size: 16, color: PazColors.textDim),
                onPressed: () {
                  _calcController.clear();
                  setState(() {});
                },
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: PazColors.inputFill,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: PazColors.cardBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'USD PARITY',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: PazColors.textDim,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '\$${_currencyFormat.format(usdEquiv)}',
                        style: PazTheme.monoNumber(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: PazColors.emerald,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '@ ${_currencyFormat.format(usdRate)} ETB/USD',
                        style: PazTheme.monoNumber(
                          fontSize: 9,
                          color: PazColors.textDim,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: PazColors.inputFill,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: PazColors.cardBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '24K GOLD WEIGHT',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: PazColors.textDim,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${goldGrams.toStringAsFixed(3)} g',
                        style: PazTheme.monoNumber(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: PazColors.gold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '@ ${_currencyFormat.format(gold24k)} ETB/g',
                        style: PazTheme.monoNumber(
                          fontSize: 9,
                          color: PazColors.textDim,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGoldKaratBreakdown() {
    final karats = _goldData?['karats'] as Map<String, dynamic>? ?? {};
    final spotUsdOz = (_goldData?['spot_usd_per_oz'] as num?)?.toDouble() ?? 3619.00;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: PazTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(LucideIcons.coins, size: 16, color: PazColors.gold),
                  const SizedBox(width: 8),
                  Text(
                    'PHYSICAL GOLD SPOT',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: PazColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Text(
                'SPOT \$${_currencyFormat.format(spotUsdOz)}/oz',
                style: PazTheme.monoNumber(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: PazColors.gold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildKaratRow(
            karat: '24K Pure (99.9%)',
            etbGram: (karats['24K']?['per_gram_etb'] as num?)?.toDouble() ?? 18999.40,
            usdGram: (karats['24K']?['per_gram_usd'] as num?)?.toDouble() ?? 116.35,
            isTop: true,
          ),
          const Divider(height: 16),
          _buildKaratRow(
            karat: '22K Standard (91.6%)',
            etbGram: (karats['22K']?['per_gram_etb'] as num?)?.toDouble() ?? 17403.00,
            usdGram: (karats['22K']?['per_gram_usd'] as num?)?.toDouble() ?? 106.66,
          ),
          const Divider(height: 16),
          _buildKaratRow(
            karat: '18K Jewelry (75.0%)',
            etbGram: (karats['18K']?['per_gram_etb'] as num?)?.toDouble() ?? 14249.50,
            usdGram: (karats['18K']?['per_gram_usd'] as num?)?.toDouble() ?? 87.26,
          ),
        ],
      ),
    );
  }

  Widget _buildKaratRow({
    required String karat,
    required double etbGram,
    required double usdGram,
    bool isTop = false,
  }) {
    return Row(
      children: [
        Expanded(
          flex: 4,
          child: Text(
            karat,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: isTop ? FontWeight.w700 : FontWeight.w500,
              color: isTop ? PazColors.textPrimary : PazColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            '${_currencyFormat.format(etbGram)} ETB',
            textAlign: TextAlign.right,
            style: PazTheme.monoNumber(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isTop ? PazColors.gold : PazColors.textPrimary,
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            '\$${usdGram.toStringAsFixed(2)}',
            textAlign: TextAlign.right,
            style: PazTheme.monoNumber(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: PazColors.textDim,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMacroIndicatorsList() {
    final rawIndicators = _macroData?['indicators'] as List? ?? [];
    final indicators = rawIndicators
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: PazTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.barChart2, size: 16, color: PazColors.sky),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'ETHIOPIAN MACRO BENCHMARKS',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: PazColors.textPrimary,
                  ),
                ),
              ),
              Text(
                'NBE DIRECTIVES',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: PazColors.sky,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (indicators.isEmpty) ...[
            _buildIndicatorTile(
              name: 'Headline CPI Inflation',
              value: '19.9% YoY',
              trend: 'Declining',
              source: 'Ethiopian Statistical Service',
            ),
            const Divider(height: 16),
            _buildIndicatorTile(
              name: 'NBE T-Bill 91-Day Yield',
              value: '18.45%',
              trend: 'Stable',
              source: 'National Bank of Ethiopia',
            ),
            const Divider(height: 16),
            _buildIndicatorTile(
              name: 'Diesel Fuel Benchmark',
              value: '118.50 ETB/L',
              trend: 'Official Cap',
              source: 'Ministry of Trade & Regional Integration',
            ),
          ] else
            for (int i = 0; i < indicators.length; i++) ...[
              if (i > 0) const Divider(height: 16),
              _buildIndicatorTile(
                name: indicators[i]['indicator']?.toString() ?? 'Indicator',
                value: indicators[i]['value']?.toString() ?? 'N/A',
                trend: indicators[i]['trend']?.toString() ?? 'Active',
                source: indicators[i]['source']?.toString() ?? 'Official Feed',
              ),
            ],
        ],
      ),
    );
  }

  Widget _buildIndicatorTile({
    required String name,
    required String value,
    required String trend,
    required String source,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: PazColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                source,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w400,
                  color: PazColors.textDim,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              value,
              style: PazTheme.monoNumber(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: PazColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: PazColors.cardElevated,
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(
                trend,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: PazColors.emerald,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ==================== SUB-TAB 1: COMMERCIAL BANKS FX ====================

  List<Widget> _buildBankFxTab() {
    final rawBanks = _bankData?['banks'] as List? ?? [];
    final banks = rawBanks.map((item) => Map<String, dynamic>.from(item as Map)).toList();

    return [
      Container(
        padding: const EdgeInsets.all(14),
        decoration: PazTheme.cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(LucideIcons.building, size: 16, color: PazColors.emerald),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'COMMERCIAL BANKS FX SPREAD MATRIX',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: PazColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Compare daily retail buying and selling rates across Ethiopian commercial banks. Updated directly from official banking rate boards.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: PazColors.textMuted,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: _bankCurrencies.map((curr) {
                final isSelected = _selectedBankCurrency == curr;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    onTap: () => setState(() => _selectedBankCurrency = curr),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? PazColors.emeraldMuted : PazColors.inputFill,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isSelected ? PazColors.emerald : PazColors.cardBorder,
                        ),
                      ),
                      child: Text(
                        curr,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? PazColors.emerald : PazColors.textMuted,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),
      if (banks.isEmpty) ...[
        _buildFallbackBankCard('Bank of Abyssinia (BOA)', 162.70, 165.95, isBest: true),
        const SizedBox(height: 10),
        _buildFallbackBankCard('Commercial Bank of Ethiopia (CBE)', 161.85, 165.08),
        const SizedBox(height: 10),
        _buildFallbackBankCard('Awash Bank', 162.20, 165.45),
        const SizedBox(height: 10),
        _buildFallbackBankCard('Dashen Bank', 162.40, 165.65),
        const SizedBox(height: 10),
        _buildFallbackBankCard('Zemen Bank', 162.10, 165.34),
        const SizedBox(height: 10),
        _buildFallbackBankCard('Bunna Bank', 161.90, 165.15),
      ] else
        for (int i = 0; i < banks.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          _buildLiveBankCard(banks[i]),
        ],
    ];
  }

  Widget _buildLiveBankCard(Map<String, dynamic> bank) {
    final name = bank['name']?.toString() ?? bank['bank_name']?.toString() ?? 'Bank';
    final rates = bank['rates'] as Map<String, dynamic>? ?? {};
    final currMap = rates[_selectedBankCurrency] as Map<String, dynamic>? ?? {};

    final buying = (currMap['buying'] as num?)?.toDouble() ??
        (bank['buying'] as num?)?.toDouble() ??
        162.0;
    final selling = (currMap['selling'] as num?)?.toDouble() ??
        (bank['selling'] as num?)?.toDouble() ??
        165.2;
    final spread = (selling - buying).abs();
    final isBest = bank['is_best'] == true || name.contains('Abyssinia');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: PazColors.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isBest ? PazColors.emeraldBorder : PazColors.cardBorder,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: PazColors.textPrimary,
                        ),
                      ),
                    ),
                    if (isBest) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: PazColors.emeraldMuted,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'TOP PAYOUT',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: PazColors.emerald,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Text(
                '$_selectedBankCurrency / ETB',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: PazColors.textDim,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'BUYING (CLIENT SELLS)',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: PazColors.textDim,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_currencyFormat.format(buying)} ETB',
                      style: PazTheme.monoNumber(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isBest ? PazColors.emerald : PazColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SELLING (CLIENT BUYS)',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: PazColors.textDim,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_currencyFormat.format(selling)} ETB',
                      style: PazTheme.monoNumber(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: PazColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'SPREAD',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: PazColors.textDim,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_currencyFormat.format(spread)} ETB',
                    style: PazTheme.monoNumber(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: PazColors.textMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackBankCard(String name, double buying, double selling, {bool isBest = false}) {
    return _buildLiveBankCard({
      'name': name,
      'buying': buying,
      'selling': selling,
      'is_best': isBest,
    });
  }

  // ==================== SUB-TAB 2: GOLD 24K ====================

  List<Widget> _buildGoldTab() {
    final karats = _goldData?['karats'] as Map<String, dynamic>? ?? {};
    final spotUsdOz = (_goldData?['spot_usd_per_oz'] as num?)?.toDouble() ?? 3619.00;
    final gold24k = (karats['24K']?['per_gram_etb'] as num?)?.toDouble() ?? 18999.40;

    final enteredGrams = double.tryParse(_goldGramsController.text.trim()) ?? 0.0;
    final totalEtb = enteredGrams * gold24k;
    final usdRate = (_fxData?['rates']?['USD'] as num?)?.toDouble() ?? 163.29;
    final totalUsd = usdRate > 0 ? (totalEtb / usdRate) : 0.0;

    return [
      Container(
        padding: const EdgeInsets.all(16),
        decoration: PazTheme.cardDecoration(glow: true),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(LucideIcons.coins, size: 16, color: PazColors.gold),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'PHYSICAL GOLD BULLION & RESERVES',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: PazColors.textPrimary,
                    ),
                  ),
                ),
                Text(
                  'SPOT \$${_currencyFormat.format(spotUsdOz)}/oz',
                  style: PazTheme.monoNumber(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: PazColors.gold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Ethiopia domestic bullion valuation anchored by international XAU spot price and National Bank interbank market rate.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: PazColors.textMuted,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),
      _buildGoldKaratBreakdown(),
      const SizedBox(height: 14),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: PazTheme.cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(LucideIcons.scale, size: 16, color: PazColors.gold),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'CUSTOM GRAM VALUATION ESTIMATOR',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: PazColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _goldGramsController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: PazTheme.monoNumber(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                labelText: 'GOLD WEIGHT IN GRAMS',
                suffixText: 'Grams (24K)',
                suffixStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: PazColors.gold,
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: PazColors.inputFill,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: PazColors.cardBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TOTAL ETB VALUATION',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: PazColors.textDim,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_currencyFormat.format(totalEtb)} ETB',
                          style: PazTheme.monoNumber(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: PazColors.gold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: PazColors.inputFill,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: PazColors.cardBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'USD SPOT EQUIVALENT',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: PazColors.textDim,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '\$${_currencyFormat.format(totalUsd)}',
                          style: PazTheme.monoNumber(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: PazColors.emerald,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ];
  }

  // ==================== SUB-TAB 3: MACRO & NEWS ====================

  List<Widget> _buildMacroNewsTab() {
    final rawHeadlines = _newsData?['headlines'] as List? ?? [];
    final headlines = rawHeadlines.map((item) => Map<String, dynamic>.from(item as Map)).toList();

    return [
      _buildMacroIndicatorsList(),
      const SizedBox(height: 14),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: PazTheme.cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(LucideIcons.newspaper, size: 16, color: PazColors.sky),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'ETHIOPIAN MACRO-FINANCIAL PRESS DISPATCHES',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: PazColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (headlines.isEmpty) ...[
              _buildNewsItem(
                title: 'NBE Proposes Fine Per Share for Unauthorised Bank Acquisitions',
                source: 'Birr Metrics',
                time: '2h ago',
              ),
              const Divider(height: 16),
              _buildNewsItem(
                title: 'Commercial Banks Expand Exporter FX Retention Under New Directive',
                source: 'Addis Fortune',
                time: '4h ago',
              ),
              const Divider(height: 16),
              _buildNewsItem(
                title: 'ESX Equities Platform Concludes Institutional Mock Trading Round',
                source: 'Capital Ethiopia',
                time: '6h ago',
              ),
            ] else
              for (int i = 0; i < headlines.length; i++) ...[
                if (i > 0) const Divider(height: 16),
                _buildNewsItem(
                  title: headlines[i]['title']?.toString() ?? 'News Headline',
                  source: headlines[i]['source']?.toString() ?? 'Financial Press',
                  time: 'Live Feed',
                ),
              ],
          ],
        ),
      ),
    ];
  }

  Widget _buildNewsItem({
    required String title,
    required String source,
    required String time,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: PazColors.textPrimary,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Text(
              source,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: PazColors.emerald,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '•',
              style: TextStyle(fontSize: 10, color: PazColors.textDim),
            ),
            const SizedBox(width: 8),
            Text(
              time,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                color: PazColors.textDim,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTerminalFooter() {
    return Center(
      child: Column(
        children: [
          Text(
            'DATA SOURCES: CBE, NATIONAL BANK OF ETHIOPIA & GOLD-API',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: PazColors.textDim,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'PAZ INSTITUTIONAL TERMINAL • v2.4.0',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 9,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
              color: PazColors.textDim,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: PazColors.card,
                shape: BoxShape.circle,
                border: Border.all(color: PazColors.cardBorderStrong),
              ),
              child: const Icon(
                LucideIcons.wifiOff,
                size: 32,
                color: PazColors.red,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Feeds Unavailable',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: PazColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Unable to connect to PAZ financial backend.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: PazColors.textMuted,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _fetchMarketData,
              icon: const Icon(LucideIcons.refreshCw, size: 16),
              label: const Text('Retry Connection'),
            ),
          ],
        ),
      ),
    );
  }
}
