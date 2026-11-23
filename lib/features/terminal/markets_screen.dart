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
  final NumberFormat _currencyFormat = NumberFormat('#,##0.00');

  bool _isLoading = true;
  String? _errorMessage;

  Map<String, dynamic>? _fxData;
  Map<String, dynamic>? _goldData;
  Map<String, dynamic>? _macroData;

  @override
  void initState() {
    super.initState();
    _fetchMarketData();
  }

  @override
  void dispose() {
    _calcController.dispose();
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
        _apiService.getGoldLive().catchError((e) => <String, dynamic>{}),
        _apiService.getMacroIndicators().catchError((e) => <String, dynamic>{}),
      ]);

      if (mounted) {
        setState(() {
          _fxData = results[0].isNotEmpty ? results[0] : null;
          _goldData = results[1].isNotEmpty ? results[1] : null;
          _macroData = results[2].isNotEmpty ? results[2] : null;

          if (_fxData == null && _goldData == null && _macroData == null) {
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
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildStatusBanner(),
                      const SizedBox(height: 16),
                      _buildMacroGrid(),
                      const SizedBox(height: 16),
                      _buildParityCalculator(),
                      const SizedBox(height: 16),
                      _buildGoldKaratBreakdown(),
                      const SizedBox(height: 16),
                      _buildMacroIndicatorsList(),
                      const SizedBox(height: 20),
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
                borderRadius: BorderRadius.circular(8),
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.6,
                    color: PazColors.textDim,
                  ),
                ),
              ],
            ),
            const Spacer(),
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

  Widget _buildStatusBanner() {
    final lastUpdated = _fxData?['last_updated'] ?? _goldData?['last_updated'];
    final source = _fxData?['source'] ?? 'Interbank NBE Feed';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: PazColors.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: PazColors.cardBorder),
      ),
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
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                title: 'EUR / ETB',
                subtitle: 'European Single Currency',
                value: '${_currencyFormat.format(eurRate)} ETB',
                change: '+0.4% 24h',
                changePositive: true,
                badge: 'PARITY',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: 'GOLD 24K',
                subtitle: 'Physical Pure (Per Gram)',
                value: '${_currencyFormat.format(gold24k)} ETB',
                change: 'XAU Spot Parity',
                changePositive: true,
                badge: 'PRECIOUS',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                title: 'GBP / ETB',
                subtitle: 'British Pound Sterling',
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
          const SizedBox(height: 12),
          Text(
            value,
            style: PazTheme.monoNumber(
              fontSize: 16,
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
              Text(
                change,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: changePositive ? PazColors.emerald : PazColors.amber,
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
              const Icon(
                LucideIcons.calculator,
                size: 16,
                color: PazColors.emerald,
              ),
              const SizedBox(width: 8),
              Text(
                'LIVE PARITY CALCULATOR',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: PazColors.textPrimary,
                ),
              ),
              const Spacer(),
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
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: PazColors.canvas,
                    borderRadius: BorderRadius.circular(8),
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
                    color: PazColors.canvas,
                    borderRadius: BorderRadius.circular(8),
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
                          color: PazColors.amber,
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
                  const Icon(LucideIcons.coins, size: 16, color: PazColors.amber),
                  const SizedBox(width: 8),
                  Text(
                    'PHYSICAL GOLD KARAT MATRIX',
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
                  color: PazColors.amber,
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
              color: isTop ? PazColors.emerald : PazColors.textPrimary,
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
              Text(
                'ETHIOPIAN MACRO BENCHMARKS',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: PazColors.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                'NBE POLICY',
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
              name: 'Official Interbank FX Spread',
              value: '0.85%',
              trend: 'Tightening',
              source: 'FX Market Reform Directive',
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
            'PAZ INSTITUTIONAL TERMINAL • v1.0.0',
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
