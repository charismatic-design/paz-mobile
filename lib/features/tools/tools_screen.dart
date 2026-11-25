import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/paz_theme.dart';
import '../../services/api_service.dart';
import '../alerts/alerts_screen.dart';

class ToolsScreen extends StatefulWidget {
  final int initialSubTab;

  const ToolsScreen({super.key, this.initialSubTab = 0});

  @override
  State<ToolsScreen> createState() => _ToolsScreenState();
}

class _ToolsScreenState extends State<ToolsScreen> {
  final ApiService _apiService = ApiService();
  final NumberFormat _currencyFormat = NumberFormat('#,##0.00');

  late int _selectedSubTab; // 0: Remittance, 1: ESX / Equities, 2: Rate Alerts

  // Remittance state
  final TextEditingController _amountController = TextEditingController(text: '1000');
  String _selectedRemittanceCurrency = 'USD';
  final List<String> _currencies = ['USD', 'EUR', 'GBP', 'AED'];
  bool _isRemittanceLoading = false;
  Map<String, dynamic>? _remittanceData;
  String? _remittanceError;

  // ESX waitlist & Apple Stocks preview state
  final TextEditingController _waitlistEmailController = TextEditingController();
  bool _isWaitlistSubmitting = false;
  bool _waitlistSuccess = false;
  String? _waitlistError;
  String _selectedEsxTicker = 'TELE';
  String _selectedEsxRange = '1D';

  static const List<Map<String, dynamic>> _esxStocks = [
    {
      'ticker': 'TELE',
      'company': 'Ethio Telecom',
      'price': 124.50,
      'changePct': 2.45,
      'series': {
        '1D': [121.2, 121.8, 121.5, 122.4, 122.1, 123.0, 123.6, 124.1, 124.5],
        '1W': [118.4, 119.2, 120.5, 119.8, 121.4, 122.9, 124.5],
        '1M': [112.0, 114.5, 113.8, 116.2, 118.9, 120.4, 122.1, 124.5],
        '1Y': [96.0, 101.5, 104.2, 108.0, 111.5, 115.8, 119.4, 124.5],
      },
    },
    {
      'ticker': 'WGBX',
      'company': 'Wegagen Bank',
      'price': 88.20,
      'changePct': 1.15,
      'series': {
        '1D': [87.1, 87.3, 87.0, 87.5, 87.8, 87.6, 88.0, 88.2],
        '1W': [85.6, 86.0, 86.4, 86.1, 87.0, 87.7, 88.2],
        '1M': [82.4, 83.1, 84.5, 84.0, 85.8, 86.9, 88.2],
        '1Y': [74.0, 76.8, 79.2, 81.0, 83.5, 86.0, 88.2],
      },
    },
    {
      'ticker': 'AWAB',
      'company': 'Awash Bank',
      'price': 142.80,
      'changePct': -0.65,
      'series': {
        '1D': [143.8, 143.5, 143.9, 143.4, 143.1, 143.3, 142.9, 142.8],
        '1W': [145.1, 144.6, 144.9, 144.0, 143.6, 143.1, 142.8],
        '1M': [146.5, 145.8, 145.0, 144.2, 143.9, 143.2, 142.8],
        '1Y': [132.0, 136.4, 139.0, 141.5, 144.8, 143.5, 142.8],
      },
    },
    {
      'ticker': 'BOAX',
      'company': 'Bank of Abyssinia',
      'price': 116.40,
      'changePct': 1.80,
      'series': {
        '1D': [114.2, 114.6, 114.4, 115.0, 115.3, 115.8, 116.1, 116.4],
        '1W': [112.5, 113.1, 113.8, 114.2, 115.0, 115.7, 116.4],
        '1M': [108.0, 109.4, 111.2, 110.8, 112.9, 114.6, 116.4],
        '1Y': [94.5, 99.0, 103.2, 106.8, 110.4, 113.8, 116.4],
      },
    },
    {
      'ticker': 'GDAB',
      'company': 'Gadaa Bank',
      'price': 54.10,
      'changePct': -1.10,
      'series': {
        '1D': [54.7, 54.6, 54.8, 54.5, 54.4, 54.3, 54.2, 54.1],
        '1W': [55.3, 55.0, 54.8, 54.9, 54.5, 54.3, 54.1],
        '1M': [56.8, 56.2, 55.9, 55.4, 54.9, 54.4, 54.1],
        '1Y': [51.0, 52.4, 53.8, 55.6, 55.0, 54.5, 54.1],
      },
    },
  ];

  final List<String> _subTabs = ['Remittance', 'Stocks (Soon)', 'Rate Alerts'];

  @override
  void initState() {
    super.initState();
    _selectedSubTab = widget.initialSubTab;
    _calculateRemittance();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _waitlistEmailController.dispose();
    super.dispose();
  }

  Future<void> _calculateRemittance() async {
    final amount = double.tryParse(_amountController.text.trim()) ?? 1000.0;
    if (amount <= 0) return;

    setState(() {
      _isRemittanceLoading = true;
      _remittanceError = null;
    });

    try {
      final data = await _apiService.getRemittance(
        amount: amount,
        currency: _selectedRemittanceCurrency,
      );
      if (mounted) {
        setState(() {
          _remittanceData = data;
          _isRemittanceLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _remittanceError = 'Unable to fetch live remittance corridors.';
          _isRemittanceLoading = false;
        });
      }
    }
  }

  Future<void> _submitEsxWaitlist() async {
    final email = _waitlistEmailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() {
        _waitlistError = 'Please enter a valid email address.';
      });
      return;
    }

    setState(() {
      _isWaitlistSubmitting = true;
      _waitlistError = null;
      _waitlistSuccess = false;
    });

    try {
      final res = await http.post(
        Uri.parse('https://api.web3forms.com/submit'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'access_key': 'd8da34a4-5843-43bb-b18d-8413d0252efa',
          'subject': 'PAZ Mobile — ESX Early Access Signup',
          'email': email,
          'message': 'New ESX Early Access waitlist signup from mobile app: $email',
          'botcheck': false,
        }),
      );

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode >= 200 && res.statusCode < 300 && data['success'] == true) {
        if (mounted) {
          setState(() {
            _waitlistSuccess = true;
            _isWaitlistSubmitting = false;
            _waitlistEmailController.clear();
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _waitlistError = data['message']?.toString() ?? 'Submission rejected. Please try again.';
            _isWaitlistSubmitting = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _waitlistError = 'Network failure submitting waitlist entry: $e';
          _isWaitlistSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PazColors.canvas,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            _buildSubTabBar(),
            Expanded(
              child: _selectedSubTab == 2
                  ? const AlertsScreen()
                  : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_selectedSubTab == 0) ..._buildRemittanceContent(),
                          if (_selectedSubTab == 1) ..._buildEsxContent(),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: PazColors.cardElevated,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: PazColors.cardBorderStrong),
            ),
            child: const Icon(LucideIcons.compass, size: 16, color: PazColors.emerald),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'FINANCIAL TOOLS & MARKETS',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: PazColors.textPrimary,
                  ),
                ),
                Text(
                  'REMITTANCE OPTIMIZER • ESX PIPELINE • ALERTS',
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
        ],
      ),
    );
  }

  Widget _buildSubTabBar() {
    return Container(
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
    );
  }

  // ==================== REMITTANCE CONTENT ====================

  List<Widget> _buildRemittanceContent() {
    final channels = (_remittanceData?['channels'] as List?)
            ?.map((e) => Map<String, dynamic>.from(e as Map))
            .toList() ??
        [];

    final baseRate = (_remittanceData?['base_market_rate'] as num?)?.toDouble() ?? 163.29;

    return [
      Container(
        padding: const EdgeInsets.all(16),
        decoration: PazTheme.cardDecoration(glow: true),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(LucideIcons.send, size: 16, color: PazColors.emerald),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'DIASPORA REMITTANCE OPTIMIZER',
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
                  '@ ${_currencyFormat.format(baseRate)} ETB',
                  style: PazTheme.monoNumber(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: PazColors.emerald,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Compare effective net Birr received in Ethiopia across digital remittance apps, commercial SWIFT wires, and airport counter cash.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: PazColors.textMuted,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: PazTheme.monoNumber(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      labelText: 'TRANSFER PRINCIPAL',
                      prefixText: '$_selectedRemittanceCurrency ',
                      prefixStyle: const TextStyle(
                        color: PazColors.emerald,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    onSubmitted: (_) => _calculateRemittance(),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: PazColors.inputFill,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: PazColors.inputBorder),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedRemittanceCurrency,
                        isExpanded: true,
                        dropdownColor: PazColors.cardElevated,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: PazColors.textPrimary,
                        ),
                        items: _currencies.map((curr) {
                          return DropdownMenuItem(
                            value: curr,
                            child: Text(curr),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedRemittanceCurrency = val);
                            _calculateRemittance();
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 42,
              child: ElevatedButton.icon(
                onPressed: _isRemittanceLoading ? null : _calculateRemittance,
                icon: _isRemittanceLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: PazColors.canvas,
                        ),
                      )
                    : const Icon(LucideIcons.arrowRightLeft, size: 16),
                label: Text(
                  'COMPUTE CORRIDOR PAYOUT',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      if (_remittanceError != null) ...[
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: PazColors.redMuted,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: PazColors.red),
          ),
          child: Row(
            children: [
              const Icon(LucideIcons.alertCircle, size: 16, color: PazColors.red),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _remittanceError!,
                  style: GoogleFonts.plusJakartaSans(fontSize: 12, color: PazColors.red),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
      if (channels.isEmpty) ...[
        _buildFallbackRemittanceCard(
          title: 'Digital Remittance Apps',
          subtitle: 'LemFi, Remitly, Western Union Digital',
          netAmount: 162960.00,
          fee: 0.0,
          parity: 162.96,
          diffVsBest: 0.0,
          badge: 'Highest Payout',
          isBest: true,
        ),
        const SizedBox(height: 12),
        _buildFallbackRemittanceCard(
          title: 'Direct Commercial Bank Wire',
          subtitle: 'Official SWIFT Wire (1–2 Days)',
          netAmount: 161850.00,
          fee: 25.00,
          parity: 161.85,
          diffVsBest: -1110.00,
          badge: 'SWIFT Official',
        ),
        const SizedBox(height: 12),
        _buildFallbackRemittanceCard(
          title: 'Airport / Bole Counter Cash Exchange',
          subtitle: 'Physical Cash Terminal (Customs Declaration)',
          netAmount: 159800.00,
          fee: 0.0,
          parity: 159.80,
          diffVsBest: -3160.00,
          badge: 'In-Person Cash',
        ),
      ] else
        for (int i = 0; i < channels.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          _buildLiveRemittanceCard(channels[i]),
        ],
    ];
  }

  Widget _buildLiveRemittanceCard(Map<String, dynamic> channel) {
    final title = channel['name']?.toString() ?? 'Remittance Channel';
    final subtitle = channel['subtitle']?.toString() ?? '';
    final netAmount = (channel['net_payout_etb'] as num?)?.toDouble() ??
        (channel['net_received_etb'] as num?)?.toDouble() ??
        160000.0;
    final fee = (channel['transfer_fee'] as num?)?.toDouble() ?? 0.0;
    final parity = (channel['effective_parity'] as num?)?.toDouble() ?? 160.0;
    final diffVsBest = (channel['diff_vs_best'] as num?)?.toDouble() ?? 0.0;
    final badge = channel['badge']?.toString() ?? (channel['is_best'] == true ? 'Highest Payout' : 'Corridor');
    final isBest = channel['is_best'] == true;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PazColors.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isBest ? PazColors.emeraldBorder : PazColors.cardBorder,
          width: isBest ? 1.5 : 1,
        ),
        boxShadow: isBest
            ? [
                BoxShadow(
                  color: PazColors.emerald.withValues(alpha: 0.08),
                  blurRadius: 14,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: PazColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: isBest ? PazColors.emeraldMuted : PazColors.cardElevated,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  badge,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: isBest ? PazColors.emerald : PazColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                color: PazColors.textDim,
              ),
            ),
          ],
          const SizedBox(height: 14),
          Text(
            'NET RECEIVED IN ETHIOPIA',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: PazColors.textDim,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${_currencyFormat.format(netAmount)} ETB',
            style: PazTheme.monoNumber(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: isBest ? PazColors.emerald : PazColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TRANSFER FEE',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: PazColors.textDim,
                      ),
                    ),
                    Text(
                      fee == 0.0 ? 'Free' : '${_currencyFormat.format(fee)} $_selectedRemittanceCurrency',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: PazTheme.monoNumber(fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'EFFECTIVE RATE',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: PazColors.textDim,
                      ),
                    ),
                    Text(
                      '${_currencyFormat.format(parity)} ETB',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: PazTheme.monoNumber(fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'VS BEST',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: PazColors.textDim,
                      ),
                    ),
                    Text(
                      isBest ? 'Winner' : '${_currencyFormat.format(diffVsBest)} ETB',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: PazTheme.monoNumber(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isBest ? PazColors.emerald : PazColors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackRemittanceCard({
    required String title,
    required String subtitle,
    required double netAmount,
    required double fee,
    required double parity,
    required double diffVsBest,
    required String badge,
    bool isBest = false,
  }) {
    return _buildLiveRemittanceCard({
      'name': title,
      'subtitle': subtitle,
      'net_payout_etb': netAmount,
      'transfer_fee': fee,
      'effective_parity': parity,
      'diff_vs_best': diffVsBest,
      'badge': badge,
      'is_best': isBest,
    });
  }

  // ==================== ESX CONTENT (APPLE STOCKS PREVIEW) ====================

  List<Widget> _buildEsxContent() {
    final selectedStock = _esxStocks.firstWhere(
      (s) => s['ticker'] == _selectedEsxTicker,
      orElse: () => _esxStocks.first,
    );
    final ticker = selectedStock['ticker'] as String;
    final company = selectedStock['company'] as String;
    final price = (selectedStock['price'] as num).toDouble();
    final changePct = (selectedStock['changePct'] as num).toDouble();
    final isPos = changePct >= 0;
    final seriesMap = selectedStock['series'] as Map<String, List<double>>;
    final points = seriesMap[_selectedEsxRange] ?? seriesMap['1D']!;
    final minVal = points.reduce((a, b) => a < b ? a : b);
    final maxVal = points.reduce((a, b) => a > b ? a : b);

    return [
      // Coming Soon Banner
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: PazColors.emeraldMuted,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: PazColors.emerald.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(LucideIcons.sparkles, size: 15, color: PazColors.emerald),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'ESX Stock Market • Coming Soon — Tap any company below to preview its interactive price chart using sample ETB prices.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: PazColors.textSecondary,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),

      // Interactive Preview XY Line Chart
      Container(
        padding: const EdgeInsets.all(16),
        decoration: PazTheme.cardDecoration(glow: true),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            ticker,
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: PazColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: PazColors.emeraldMuted,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: PazColors.emerald.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              'PREVIEW',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 8,
                                fontWeight: FontWeight.w700,
                                color: PazColors.emerald,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        company,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: PazColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${price.toStringAsFixed(2)} ETB',
                      style: PazTheme.monoNumber(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: PazColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isPos ? PazColors.emerald : PazColors.red,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${isPos ? '+' : ''}${changePct.toStringAsFixed(2)}%',
                        style: PazTheme.monoNumber(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isPos ? const Color(0xFF06281C) : Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 1D, 1W, 1M, 1Y toggles
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: PazColors.inputFill,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: PazColors.borderSubtle),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: ['1D', '1W', '1M', '1Y'].map((range) {
                  final active = _selectedEsxRange == range;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedEsxRange = range),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: active ? PazColors.emeraldMuted : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        range,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: active ? PazColors.emerald : PazColors.textMuted,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),

            // XY Line Chart with ETB labels
            Container(
              height: 150,
              padding: const EdgeInsets.fromLTRB(10, 12, 10, 10),
              decoration: BoxDecoration(
                color: PazColors.inputFill,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: PazColors.borderSubtle),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: CustomPaint(
                      size: Size.infinite,
                      painter: _EsxLineChartPainter(
                        points: points,
                        color: isPos ? PazColors.emerald : PazColors.red,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${maxVal.toStringAsFixed(1)} ETB',
                        style: PazTheme.monoNumber(fontSize: 10, color: PazColors.textDim),
                      ),
                      Text(
                        '${((minVal + maxVal) / 2).toStringAsFixed(1)} ETB',
                        style: PazTheme.monoNumber(fontSize: 10, color: PazColors.textDim),
                      ),
                      Text(
                        '${minVal.toStringAsFixed(1)} ETB',
                        style: PazTheme.monoNumber(fontSize: 10, color: PazColors.textDim),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),

      // Apple Stocks-style Horizontal Watchlist Rows
      Container(
        padding: const EdgeInsets.all(14),
        decoration: PazTheme.cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'ETHIOPIAN STOCKS WATCHLIST',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: PazColors.textDim,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Tap row to preview',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10,
                    color: PazColors.textDim,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ..._esxStocks.asMap().entries.map((entry) {
              final idx = entry.key;
              final stock = entry.value;
              final rowTicker = stock['ticker'] as String;
              final rowCompany = stock['company'] as String;
              final rowPrice = (stock['price'] as num).toDouble();
              final rowChange = (stock['changePct'] as num).toDouble();
              final rowIsPos = rowChange >= 0;
              final rowSeries = (stock['series'] as Map<String, List<double>>)['1D']!;
              final isSelected = rowTicker == _selectedEsxTicker;

              return Column(
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => setState(() => _selectedEsxTicker = rowTicker),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
                      decoration: BoxDecoration(
                        color: isSelected ? PazColors.emeraldMuted : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  rowTicker,
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: PazColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  rowCompany,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    color: PazColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 72,
                            height: 28,
                            child: CustomPaint(
                              painter: _MiniSparklinePainter(
                                points: rowSeries,
                                color: rowIsPos ? PazColors.emerald : PazColors.red,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${rowPrice.toStringAsFixed(2)} ETB',
                                style: PazTheme.monoNumber(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: PazColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: rowIsPos ? PazColors.emerald : PazColors.red,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  '${rowIsPos ? '+' : ''}${rowChange.toStringAsFixed(2)}%',
                                  style: PazTheme.monoNumber(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: rowIsPos ? const Color(0xFF06281C) : Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (idx < _esxStocks.length - 1) const Divider(height: 6),
                ],
              );
            }),
          ],
        ),
      ),
      const SizedBox(height: 14),

      // Email Notify Card
      Container(
        padding: const EdgeInsets.all(16),
        decoration: PazTheme.cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(LucideIcons.mail, size: 16, color: PazColors.emerald),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'GET NOTIFIED WHEN LIVE TRADING OPENS',
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
            const SizedBox(height: 8),
            Text(
              'Enter your email to be notified when live ESX stock prices and price alerts launch.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: PazColors.textMuted,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            if (_waitlistSuccess) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: PazColors.emeraldMuted,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: PazColors.emerald),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.checkCircle2, size: 16, color: PazColors.emerald),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'You are on the list! We will email you when live ESX stock prices launch.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: PazColors.emerald,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],
            if (_waitlistError != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: PazColors.redMuted,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: PazColors.red),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.alertCircle, size: 16, color: PazColors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _waitlistError!,
                        style: GoogleFonts.plusJakartaSans(fontSize: 12, color: PazColors.red),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],
            TextField(
              controller: _waitlistEmailController,
              keyboardType: TextInputType.emailAddress,
              style: GoogleFonts.plusJakartaSans(fontSize: 13, color: PazColors.textPrimary),
              decoration: const InputDecoration(
                hintText: 'you@example.com',
                prefixIcon: Icon(LucideIcons.mail, size: 16, color: PazColors.textDim),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 42,
              child: ElevatedButton.icon(
                onPressed: _isWaitlistSubmitting ? null : _submitEsxWaitlist,
                icon: _isWaitlistSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: PazColors.canvas),
                      )
                    : const Icon(LucideIcons.send, size: 16),
                label: Text(
                  'NOTIFY ME',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ];
  }
}

class _EsxLineChartPainter extends CustomPainter {
  final List<double> points;
  final Color color;

  _EsxLineChartPainter({required this.points, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    final minVal = points.reduce((a, b) => a < b ? a : b);
    final maxVal = points.reduce((a, b) => a > b ? a : b);
    final span = (maxVal - minVal) == 0 ? 1.0 : (maxVal - minVal);

    // Faint horizontal gridlines
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..strokeWidth = 1;
    for (final frac in [0.0, 0.5, 1.0]) {
      final y = size.height * frac;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final linePath = Path();
    final fillPath = Path();
    Offset? lastOffset;

    for (var i = 0; i < points.length; i++) {
      final x = (i / (points.length - 1)) * size.width;
      final y = size.height - ((points[i] - minVal) / span) * size.height;
      final offset = Offset(x, y);
      if (i == 0) {
        linePath.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        linePath.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
      lastOffset = offset;
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withValues(alpha: 0.28),
          color.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(fillPath, fillPaint);

    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(linePath, linePaint);

    if (lastOffset != null) {
      canvas.drawCircle(lastOffset, 4.0, Paint()..color = color);
      canvas.drawCircle(
        lastOffset,
        4.0,
        Paint()
          ..color = PazColors.canvas
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _EsxLineChartPainter oldDelegate) {
    return oldDelegate.points != points || oldDelegate.color != color;
  }
}

class _MiniSparklinePainter extends CustomPainter {
  final List<double> points;
  final Color color;

  _MiniSparklinePainter({required this.points, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    final minVal = points.reduce((a, b) => a < b ? a : b);
    final maxVal = points.reduce((a, b) => a > b ? a : b);
    final span = (maxVal - minVal) == 0 ? 1.0 : (maxVal - minVal);

    // Faint dotted baseline at starting value
    final baselineY = size.height - ((points.first - minVal) / span) * size.height;
    final dotPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.25)
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 5) {
      canvas.drawLine(
        Offset(x, baselineY),
        Offset((x + 2.5).clamp(0, size.width), baselineY),
        dotPaint,
      );
    }

    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final x = (i / (points.length - 1)) * size.width;
      final y = size.height - ((points[i] - minVal) / span) * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 1.75
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _MiniSparklinePainter oldDelegate) {
    return oldDelegate.points != points || oldDelegate.color != color;
  }
}
