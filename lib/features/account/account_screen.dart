import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/paz_theme.dart';
import '../../services/api_service.dart';
import '../../services/storage_service.dart';
import '../auth/login_screen.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();

  bool _isLoading = true;
  bool _isGuest = false;
  Map<String, dynamic>? _user;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() => _isLoading = true);

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
      final user = await _apiService.getMe();
      if (mounted) {
        setState(() {
          _user = user;
          _isGuest = false;
          _isLoading = false;
        });
      }
    } catch (_) {
      final cached = await _storageService.getUser();
      if (mounted) {
        setState(() {
          _user = cached;
          _isGuest = cached == null;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleSignOut() async {
    await _apiService.logout();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  Future<void> _handleDeleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: PazColors.cardElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: PazColors.cardBorderStrong),
        ),
        title: Row(
          children: [
            const Icon(LucideIcons.alertTriangle, color: PazColors.red, size: 20),
            const SizedBox(width: 8),
            Text(
              'Delete Account',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: PazColors.textPrimary,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to permanently delete your PAZ account and all associated alerts and portfolio records from Neon Postgres? This action is irreversible.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: PazColors.textMuted,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Cancel',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: PazColors.textMuted,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: PazColors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(
              'Permanently Delete',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _apiService.deleteAccount();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Your account and data have been permanently deleted.',
                style: GoogleFonts.plusJakartaSans(fontSize: 13),
              ),
              backgroundColor: PazColors.cardElevated,
            ),
          );
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete account: $e'),
              backgroundColor: PazColors.red,
            ),
          );
        }
      }
    }
  }

  String _getInitials(String? name) {
    if (name == null || name.trim().isEmpty) return 'NS';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PazColors.canvas,
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: PazColors.emerald,
                  strokeWidth: 2.5,
                ),
              )
            : CustomScrollView(
                slivers: [
                  _buildAppBar(),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        if (_isGuest)
                          _buildGuestCard()
                        else ...[
                          _buildProfileCard(),
                          const SizedBox(height: 16),
                          _buildPreferencesCard(),
                        ],
                        const SizedBox(height: 16),
                        _buildTerminalSettingsCard(),
                        const SizedBox(height: 16),
                        if (!_isGuest) ...[
                          _buildDangerZoneCard(),
                          const SizedBox(height: 16),
                        ],
                        _buildAuthActionButton(),
                        const SizedBox(height: 24),
                        _buildVersionFooter(),
                      ]),
                    ),
                  ),
                ],
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'ACCOUNT & SETTINGS',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      color: PazColors.textPrimary,
                    ),
                  ),
                  Text(
                    'TERMINAL CONFIGURATION & INSTITUTIONAL PROFILE',
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
      ),
    );
  }

  Widget _buildGuestCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: PazTheme.cardDecoration(glow: true),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: PazColors.cardElevated,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: PazColors.cardBorderStrong),
                ),
                child: const Center(
                  child: Icon(LucideIcons.userX, size: 22, color: PazColors.textMuted),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Guest Terminal Session',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: PazColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Limited read-only session',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: PazColors.textDim,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Sign in or register an account to sync live watchlist alerts, portfolio assets, and store custom bank preferences.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: PazColors.textMuted,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
              icon: const Icon(LucideIcons.logIn, size: 16),
              label: const Text('Sign In or Register'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard() {
    final fullName = _user?['full_name']?.toString() ?? 'PAZ Institutional Member';
    final email = _user?['email']?.toString() ?? 'user@paz.et';
    final initials = _getInitials(fullName);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: PazTheme.cardDecoration(),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: PazColors.cardElevated,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: PazColors.emerald.withValues(alpha: 0.3)),
            ),
            child: Center(
              child: Text(
                initials,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: PazColors.emerald,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        fullName,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: PazColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: PazColors.emeraldMuted,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'INSTITUTIONAL',
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
                const SizedBox(height: 3),
                Text(
                  email,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: PazColors.textMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferencesCard() {
    final currency = _user?['preferred_currency']?.toString() ?? 'USD';
    final bank = _user?['preferred_bank']?.toString() ?? 'CBE';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: PazTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.sliders, size: 16, color: PazColors.sky),
              const SizedBox(width: 8),
              Text(
                'PORTFOLIO PREFERENCES',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: PazColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildInfoRow(
            label: 'Benchmark Currency',
            value: currency,
            badge: 'BASE FX',
          ),
          const Divider(height: 20),
          _buildInfoRow(
            label: 'Primary Commercial Bank',
            value: bank,
            badge: 'CORRIDOR',
          ),
        ],
      ),
    );
  }

  Widget _buildTerminalSettingsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: PazTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.cpu, size: 16, color: PazColors.emerald),
              const SizedBox(width: 8),
              Text(
                'TERMINAL TELEMETRY & NETWORK',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: PazColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildInfoRow(
            label: 'Color Theme',
            value: 'Obsidian Dark (#080A0D)',
            badge: 'LOCKED',
          ),
          const Divider(height: 20),
          _buildInfoRow(
            label: 'Active Node',
            value: 'paz-backend-onat (Render/US-East)',
            badge: 'ONLINE',
          ),
          const Divider(height: 20),
          _buildInfoRow(
            label: 'Data Integrity Feed',
            value: 'NBE + CBE + Gold-API',
            badge: 'REAL-TIME',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required String label,
    required String value,
    required String badge,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: PazColors.textMuted,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: PazColors.textPrimary,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
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
    );
  }

  Widget _buildDangerZoneCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PazColors.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: PazColors.red.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.alertOctagon, size: 16, color: PazColors.red),
              const SizedBox(width: 8),
              Text(
                'DANGER ZONE',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  color: PazColors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Permanently delete your user account, watchlist triggers, and portfolio records from Neon Postgres database.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: PazColors.textMuted,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _handleDeleteAccount,
              icon: const Icon(LucideIcons.trash2, size: 16, color: PazColors.red),
              label: Text(
                'DELETE ACCOUNT',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: PazColors.red,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: PazColors.red),
                backgroundColor: PazColors.redMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthActionButton() {
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: OutlinedButton.icon(
        onPressed: _isGuest
            ? () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              }
            : _handleSignOut,
        icon: Icon(
          _isGuest ? LucideIcons.logIn : LucideIcons.logOut,
          size: 16,
          color: _isGuest ? PazColors.emerald : PazColors.textSecondary,
        ),
        label: Text(
          _isGuest ? 'SIGN IN OR CREATE ACCOUNT' : 'SIGN OUT OF TERMINAL',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: _isGuest ? PazColors.emerald : PazColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildVersionFooter() {
    return Center(
      child: Text(
        'PAZ FINANCIAL MOBILE • v1.0.0 (BUILD 1)',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
          color: PazColors.textDim,
        ),
      ),
    );
  }
}
