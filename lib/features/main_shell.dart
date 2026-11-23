import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../core/theme/paz_theme.dart';
import 'account/account_screen.dart';
import 'ask_paz/ask_paz_screen.dart';
import 'portfolio/portfolio_screen.dart';
import 'terminal/markets_screen.dart';
import 'tools/tools_screen.dart';

class MainShell extends StatefulWidget {
  final bool isGuest;
  final int initialIndex;

  const MainShell({
    super.key,
    this.isGuest = false,
    this.initialIndex = 0,
  });

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int _currentIndex;

  final List<Widget> _screens = const [
    MarketsScreen(),
    ToolsScreen(),
    PortfolioScreen(),
    AskPazScreen(),
    AccountScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PazColors.canvas,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: PazColors.surface,
          border: Border(
            top: BorderSide(color: PazColors.cardBorder, width: 1),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          backgroundColor: PazColors.surface,
          selectedItemColor: PazColors.emerald,
          unselectedItemColor: PazColors.textDim,
          type: BottomNavigationBarType.fixed,
          selectedFontSize: 10,
          unselectedFontSize: 10,
          selectedLabelStyle: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
          unselectedLabelStyle: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w500,
          ),
          items: const [
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(LucideIcons.candlestickChart, size: 20),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(LucideIcons.candlestickChart, size: 20, color: PazColors.emerald),
              ),
              label: 'Markets',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(LucideIcons.compass, size: 20),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(LucideIcons.compass, size: 20, color: PazColors.emerald),
              ),
              label: 'Tools',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(LucideIcons.wallet, size: 20),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(LucideIcons.wallet, size: 20, color: PazColors.emerald),
              ),
              label: 'Portfolio',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(LucideIcons.bot, size: 20),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(LucideIcons.bot, size: 20, color: PazColors.emerald),
              ),
              label: 'Ask PAZ',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(LucideIcons.user, size: 20),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(LucideIcons.user, size: 20, color: PazColors.emerald),
              ),
              label: 'Account',
            ),
          ],
        ),
      ),
    );
  }
}
