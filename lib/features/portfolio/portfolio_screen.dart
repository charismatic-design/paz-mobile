import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/paz_theme.dart';
import '../../services/api_service.dart';
import '../../services/storage_service.dart';
import '../auth/login_screen.dart';

class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({super.key});

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> {
  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();
  final NumberFormat _currencyFormat = NumberFormat('#,##0.00');

  bool _isLoading = true;
  bool _isGuest = false;
  String? _errorMessage;

  Map<String, dynamic>? _summaryData;
  Map<String, dynamic>? _fxData;
  Map<String, dynamic>? _goldData;

  @override
  void initState() {
    super.initState();
    _fetchPortfolioData();
  }

  Future<void> _fetchPortfolioData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final token = await _storageService.getToken();
    if (token == null || token.isEmpty) {
      if (mounted) {
        setState(() {
          _isGuest = true;
          _isLoading = false;
        });
      }
      return;
    }

    try {
      final results = await Future.wait([
        _apiService.getBankSummary().catchError((e) => <String, dynamic>{}),
        _apiService.getFxRates().catchError((e) => <String, dynamic>{}),
        _apiService.getGoldLive().catchError((e) => <String, dynamic>{}),
      ]);

      if (mounted) {
        setState(() {
          _summaryData = results[0].isNotEmpty ? results[0] : null;
          _fxData = results[1].isNotEmpty ? results[1] : null;
          _goldData = results[2].isNotEmpty ? results[2] : null;
          _isGuest = false;
          _isLoading = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          if (e.statusCode == 401) {
            _isGuest = true;
          } else {
            _errorMessage = e.message;
          }
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Unable to load portfolio records. Pull to refresh.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteAccountBalance(dynamic id) async {
    try {
      await _apiService.deleteBankAccount(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Account balance removed from portfolio',
              style: GoogleFonts.plusJakartaSans(fontSize: 13),
            ),
            backgroundColor: PazColors.cardElevated,
            duration: const Duration(seconds: 2),
          ),
        );
      }
      _fetchPortfolioData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete account balance: $e'),
            backgroundColor: PazColors.red,
          ),
        );
      }
    }
  }

  void _showSyncMoneySheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: PazColors.cardElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        side: BorderSide(color: PazColors.cardBorderStrong),
      ),
      builder: (ctx) => _SyncMoneyBottomSheet(
        fxData: _fxData,
        goldData: _goldData,
        onCreated: () {
          Navigator.of(ctx).pop();
          _fetchPortfolioData();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final usdRate = (_fxData?['rates']?['USD'] as num?)?.toDouble() ?? 163.29;
    final gold24k = (_goldData?['karats']?['24K']?['per_gram_etb'] as num?)?.toDouble() ??
        (_fxData?['gold_per_gram_etb'] as num?)?.toDouble() ??
        18999.40;

    final totalEtb = (_summaryData?['total_net_worth_etb'] as num?)?.toDouble() ??
        (_summaryData?['total_balance_etb'] as num?)?.toDouble() ??
        0.0;
    final totalUsd = usdRate > 0 ? (totalEtb / usdRate) : 0.0;
    final totalGoldGrams = gold24k > 0 ? (totalEtb / gold24k) : 0.0;

    final rawAccounts = _summaryData?['accounts'] as List? ?? [];
    final accounts = rawAccounts.map((item) => Map<String, dynamic>.from(item as Map)).toList();

    return Scaffold(
      backgroundColor: PazColors.canvas,
      body: SafeArea(
        child: RefreshIndicator(
          color: PazColors.emerald,
          backgroundColor: PazColors.card,
          onRefresh: _fetchPortfolioData,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              _buildAppBar(),
              if (_isGuest)
                SliverFillRemaining(
                  child: _buildGuestPrompt(),
                )
              else if (_isLoading && _summaryData == null)
                const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(
                      color: PazColors.emerald,
                      strokeWidth: 2.5,
                    ),
                  ),
                )
              else if (_errorMessage != null && _summaryData == null)
                SliverFillRemaining(
                  child: _buildErrorState(),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildNetWorthHeroCard(totalEtb, totalUsd, totalGoldGrams),
                      const SizedBox(height: 16),
                      _buildAccountsSectionHeader(accounts.length),
                      const SizedBox(height: 10),
                      if (accounts.isEmpty)
                        _buildEmptyAccountsCard()
                      else
                        for (int i = 0; i < accounts.length; i++) ...[
                          if (i > 0) const SizedBox(height: 10),
                          _buildAccountCard(accounts[i]),
                        ],
                    ]),
                  ),
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: !_isGuest
          ? FloatingActionButton.extended(
              onPressed: _showSyncMoneySheet,
              backgroundColor: PazColors.emerald,
              foregroundColor: PazColors.canvas,
              elevation: 4,
              icon: const Icon(LucideIcons.plus, size: 18),
              label: Text(
                'SYNC MONEY',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildAppBar() {
    return SliverToBoxAdapter(
      child: Padding(
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
              child: const Icon(LucideIcons.wallet, size: 16, color: PazColors.emerald),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'PORTFOLIO & MONEY SYNC',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      color: PazColors.textPrimary,
                    ),
                  ),
                  Text(
                    'DOMESTIC BALANCES • USD PARITY • GOLD EQUIVALENT',
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
            if (!_isGuest)
              IconButton(
                onPressed: _showSyncMoneySheet,
                icon: const Icon(LucideIcons.plusCircle, size: 20, color: PazColors.emerald),
                tooltip: 'Sync Money / Add Account',
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNetWorthHeroCard(double totalEtb, double totalUsd, double totalGoldGrams) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: PazTheme.cardDecoration(glow: true),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'CONSOLIDATED DOMESTIC NET WORTH',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: PazColors.textDim,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: PazColors.emeraldMuted,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'SYNCED',
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
          const SizedBox(height: 8),
          Text(
            '${_currencyFormat.format(totalEtb)} ETB',
            style: PazTheme.monoNumber(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: PazColors.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          const Divider(),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'USD PARITY VALUE',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: PazColors.textDim,
                      ),
                    ),
                    const SizedBox(height: 2),
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '24K PURE GOLD WEIGHT',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: PazColors.textDim,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${totalGoldGrams.toStringAsFixed(3)} g',
                      style: PazTheme.monoNumber(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: PazColors.gold,
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

  Widget _buildAccountsSectionHeader(int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'SYNCED BANK & WALLET BALANCES ($count)',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: PazColors.textDim,
          ),
        ),
        InkWell(
          onTap: _showSyncMoneySheet,
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Row(
              children: [
                const Icon(LucideIcons.plus, size: 12, color: PazColors.emerald),
                const SizedBox(width: 4),
                Text(
                  '+ Sync Money',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: PazColors.emerald,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAccountCard(Map<String, dynamic> account) {
    final id = account['id'] ?? account['account_id'];
    final bank = account['bank_name']?.toString() ?? 'Commercial Bank';
    final accNum = account['account_number']?.toString() ?? '••••';
    final balance = (account['balance'] as num?)?.toDouble() ?? 0.0;
    final currency = account['currency']?.toString() ?? 'ETB';

    return Dismissible(
      key: Key('acc_$id'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: PazColors.redMuted,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: PazColors.red),
        ),
        child: const Icon(LucideIcons.trash2, color: PazColors.red, size: 20),
      ),
      onDismissed: (_) => _deleteAccountBalance(id),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: PazTheme.cardDecoration(),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: PazColors.cardElevated,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: PazColors.cardBorderStrong),
              ),
              child: const Center(
                child: Icon(LucideIcons.landmark, size: 18, color: PazColors.emerald),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bank,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: PazColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Acc: $accNum',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: PazColors.textDim,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${_currencyFormat.format(balance)} $currency',
                  style: PazTheme.monoNumber(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: PazColors.textPrimary,
                  ),
                ),
                Text(
                  'Domestic Ledger',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    color: PazColors.textDim,
                  ),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(LucideIcons.trash2, size: 16, color: PazColors.textDim),
              onPressed: () => _deleteAccountBalance(id),
              splashRadius: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyAccountsCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: PazTheme.cardDecoration(),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: PazColors.cardElevated,
              shape: BoxShape.circle,
              border: Border.all(color: PazColors.cardBorderStrong),
            ),
            child: const Icon(LucideIcons.walletCards, size: 24, color: PazColors.textDim),
          ),
          const SizedBox(height: 14),
          Text(
            'No Domestic Accounts Synced',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: PazColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Track your cash reserves across CBE, Awash, Dashen, and Telebirr. Monitor instant USD parity and gold purchasing power.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: PazColors.textMuted,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _showSyncMoneySheet,
            icon: const Icon(LucideIcons.plus, size: 16),
            label: const Text('+ Sync First Account'),
          ),
        ],
      ),
    );
  }

  Widget _buildGuestPrompt() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: PazTheme.cardDecoration(glow: true),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: const BoxDecoration(
                  color: PazColors.emeraldMuted,
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.shieldCheck, size: 28, color: PazColors.emerald),
              ),
              const SizedBox(height: 16),
              Text(
                'Authenticated Portfolio Session',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: PazColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Personal banking and money ledger synchronization require a secure PAZ session stored on Neon Postgres with encrypted endpoints.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: PazColors.textMuted,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
                icon: const Icon(LucideIcons.logIn, size: 16),
                label: const Text('Sign In or Register'),
              ),
            ],
          ),
        ),
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
            const Icon(LucideIcons.alertTriangle, size: 32, color: PazColors.amber),
            const SizedBox(height: 14),
            Text(
              _errorMessage ?? 'Failed to load portfolio records',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: PazColors.textMuted,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchPortfolioData,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SyncMoneyBottomSheet extends StatefulWidget {
  final Map<String, dynamic>? fxData;
  final Map<String, dynamic>? goldData;
  final VoidCallback onCreated;

  const _SyncMoneyBottomSheet({
    required this.fxData,
    required this.goldData,
    required this.onCreated,
  });

  @override
  State<_SyncMoneyBottomSheet> createState() => _SyncMoneyBottomSheetState();
}

class _SyncMoneyBottomSheetState extends State<_SyncMoneyBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _bankController = TextEditingController(text: 'Commercial Bank of Ethiopia (CBE)');
  final _accNumController = TextEditingController();
  final _balanceController = TextEditingController(text: '50000');
  final NumberFormat _currencyFormat = NumberFormat('#,##0.00');
  final ApiService _apiService = ApiService();

  final String _currency = 'ETB';
  bool _isSubmitting = false;
  String? _inlineError;

  final List<String> _popularBanks = [
    'Commercial Bank of Ethiopia (CBE)',
    'Awash Bank',
    'Dashen Bank',
    'Bank of Abyssinia (BOA)',
    'Telebirr (Ethio Telecom)',
    'CBE Birr',
    'Zemen Bank',
    'Bunna Bank',
  ];

  @override
  void dispose() {
    _bankController.dispose();
    _accNumController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  Future<void> _submitSync() async {
    if (!_formKey.currentState!.validate()) return;

    final balance = double.tryParse(_balanceController.text.replaceAll(',', '').trim());
    if (balance == null || balance < 0) {
      setState(() => _inlineError = 'Please enter a valid non-negative balance.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _inlineError = null;
    });

    try {
      await _apiService.addBankAccount(
        bankName: _bankController.text,
        accountNumber: _accNumController.text.isNotEmpty ? _accNumController.text : '••••',
        balance: balance,
        currency: _currency,
      );
      widget.onCreated();
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _inlineError = e.message;
          _isSubmitting = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _inlineError = 'Failed to sync account balance. Please try again.';
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final usdRate = (widget.fxData?['rates']?['USD'] as num?)?.toDouble() ?? 163.29;
    final gold24k = (widget.goldData?['karats']?['24K']?['per_gram_etb'] as num?)?.toDouble() ??
        (widget.fxData?['gold_per_gram_etb'] as num?)?.toDouble() ??
        18999.40;

    final entered = double.tryParse(_balanceController.text.replaceAll(',', '').trim()) ?? 0.0;
    final usdEquiv = usdRate > 0 ? (entered / usdRate) : 0.0;
    final goldGrams = gold24k > 0 ? (entered / gold24k) : 0.0;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: PazColors.cardBorderStrong,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '+ SYNC MONEY / ACCOUNT',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      color: PazColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.x, size: 18, color: PazColors.textDim),
                    onPressed: () => Navigator.of(context).pop(),
                    splashRadius: 18,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (_inlineError != null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
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
                          _inlineError!,
                          style: GoogleFonts.plusJakartaSans(fontSize: 12, color: PazColors.red),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],
              Text(
                'BANK OR DIGITAL WALLET',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: PazColors.textDim,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: PazColors.inputFill,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: PazColors.inputBorder),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _popularBanks.contains(_bankController.text) ? _bankController.text : _popularBanks.first,
                    isExpanded: true,
                    dropdownColor: PazColors.cardElevated,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: PazColors.textPrimary,
                    ),
                    items: _popularBanks.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _bankController.text = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'ACCOUNT NUMBER / IDENTIFIER (OPTIONAL)',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: PazColors.textDim,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _accNumController,
                style: GoogleFonts.plusJakartaSans(fontSize: 13, color: PazColors.textPrimary),
                decoration: const InputDecoration(
                  hintText: 'e.g. 1000293847291 or Telebirr Phone',
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'CURRENT BALANCE (ETB)',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: PazColors.textDim,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _balanceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: PazTheme.monoNumber(fontSize: 16, fontWeight: FontWeight.w700),
                decoration: const InputDecoration(
                  prefixText: 'ETB ',
                  prefixStyle: TextStyle(color: PazColors.emerald, fontWeight: FontWeight.w700),
                ),
                onChanged: (_) => setState(() {}),
                validator: (val) => val == null || val.trim().isEmpty ? 'Balance is required' : null,
              ),
              const SizedBox(height: 14),

              // Real-time Parity Preview Card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: PazColors.card,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: PazColors.cardBorderStrong),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'INSTANT PARITY PREVIEW',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: PazColors.textDim,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'USD EQUIVALENT',
                                style: GoogleFonts.plusJakartaSans(fontSize: 9, color: PazColors.textDim),
                              ),
                              Text(
                                '\$${_currencyFormat.format(usdEquiv)}',
                                style: PazTheme.monoNumber(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: PazColors.emerald,
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
                                '24K GOLD WEIGHT',
                                style: GoogleFonts.plusJakartaSans(fontSize: 9, color: PazColors.textDim),
                              ),
                              Text(
                                '${goldGrams.toStringAsFixed(3)} g',
                                style: PazTheme.monoNumber(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: PazColors.gold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitSync,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: PazColors.canvas),
                        )
                      : Text(
                          'SAVE ACCOUNT BALANCE',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
