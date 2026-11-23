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

  // ESX waitlist state
  final TextEditingController _waitlistEmailController = TextEditingController();
  bool _isWaitlistSubmitting = false;
  bool _waitlistSuccess = false;
  String? _waitlistError;

  final List<String> _subTabs = ['Remittance', 'ESX / Equities', 'Rate Alerts'];

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
        _waitlistError = 'Please enter a valid institutional or personal email address.';
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

  // ==================== ESX CONTENT ====================

  List<Widget> _buildEsxContent() {
    return [
      Container(
        padding: const EdgeInsets.all(16),
        decoration: PazTheme.cardDecoration(glow: true),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(LucideIcons.trendingUp, size: 16, color: PazColors.emerald),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'ETHIOPIAN SECURITIES EXCHANGE (ESX)',
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: PazColors.emeraldMuted,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'LAUNCH READY',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: PazColors.emerald,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Ethiopia’s first organized electronic exchange. PAZ is preparing real-time order-book telemetry, trade prints, and corporate bond yields.',
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
      Container(
        padding: const EdgeInsets.all(16),
        decoration: PazTheme.cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'MARKET ARCHITECTURE',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: PazColors.textDim,
              ),
            ),
            const SizedBox(height: 12),
            _buildEsxSegmentRow(
              title: 'Equities Main Board',
              subtitle: 'Commercial Banks, Telecom, Breweries & SOEs',
              status: 'Mock Trading',
            ),
            const Divider(height: 16),
            _buildEsxSegmentRow(
              title: 'Government Securities',
              subtitle: 'NBE T-Bills (28d, 91d, 182d, 364d) & Sovereign Bonds',
              status: 'Secondary Trading',
            ),
            const Divider(height: 16),
            _buildEsxSegmentRow(
              title: 'Corporate Debt & Sukuk',
              subtitle: 'Commercial paper & Islamic capital instruments',
              status: 'Structuring',
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: PazTheme.cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(LucideIcons.mail, size: 16, color: PazColors.gold),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'JOIN INSTITUTIONAL EARLY ACCESS LIST',
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
              'Receive beta invitations for ESX live order book streaming, trade notifications, and corporate prospectus filings.',
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
                        'You are on the PAZ ESX Access List! We will notify you when trading order books go live.',
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
                hintText: 'Enter your institutional or personal email...',
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
                  'JOIN ACCESS LIST',
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

  Widget _buildEsxSegmentRow({
    required String title,
    required String subtitle,
    required String status,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: PazColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: PazColors.textDim,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: PazColors.cardElevated,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: PazColors.cardBorderStrong),
          ),
          child: Text(
            status,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: PazColors.emerald,
            ),
          ),
        ),
      ],
    );
  }
}
