import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/paz_theme.dart';

class AboutPazScreen extends StatelessWidget {
  const AboutPazScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PazColors.canvas,
      appBar: AppBar(
        title: Text(
          'ABOUT PAZ TERMINAL',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: PazTheme.cardDecoration(glow: true),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: PazColors.cardElevated,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(LucideIcons.terminal, size: 16, color: PazColors.emerald),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'STUDIO-GRADE FINTECH INTELLIGENCE',
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
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Architected for the Post-Reform Ethiopian Economy',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: PazColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Following the historic July 28, 2024 National Bank of Ethiopia foreign exchange market liberalization (Directive FXD/01/2024), PAZ provides real-time transparency into floating interbank benchmarks, bank exchange rates, today\'s gold prices, and upcoming Ethiopian stocks.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: PazColors.textMuted,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildSection(
              title: 'DATA SOVEREIGNTY & SOURCES',
              content:
                  'PAZ directly ingests rate boards from the Commercial Bank of Ethiopia (CBE), leading private commercial banks (Awash, Dashen, Bank of Abyssinia, Zemen, Bunna), the National Bank of Ethiopia (NBE), and Gold-API for live 24K gold prices.',
            ),
            const SizedBox(height: 12),
            _buildSection(
              title: 'ADDIS ABABA FINANCIAL CENTER',
              content:
                  'Headquartered in Addis Ababa, Ethiopia, PAZ is engineered to serve retail remittance recipients, diaspora investors, corporate treasurers, and commercial financial institutions.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required String content}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: PazTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: PazColors.textDim,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: PazColors.textSecondary,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  final List<Map<String, String>> _faqs = const [
    {
      'q': 'What is the Ethiopian floating exchange rate reform?',
      'a': 'On July 28, 2024, the National Bank of Ethiopia transitioned from a decades-long crawling peg regime to a market-determined floating exchange rate. This reduced the parallel market gap and opened up interbank and retail currency operations.',
    },
    {
      'q': 'Why do commercial bank rates differ from the NBE interbank rate?',
      'a': 'The NBE interbank rate reflects wholesale currency transactions between commercial banks and the central bank. Retail banks set their own competitive buying and selling boards based on liquidity, customer demand, and treasury margins.',
    },
    {
      'q': 'How is the 24K physical gold price calculated?',
      'a': 'PAZ computes domestic gold valuation using the live international spot price of Gold (XAU/USD per troy ounce) divided by 31.1035 grams, multiplied by the live market-determined USD/ETB interbank floating rate.',
    },
    {
      'q': 'What is the Diaspora Remittance Optimizer?',
      'a': 'The remittance tool calculates net Birr received in Ethiopia after deducting provider transfer fees and applying live currency conversion, ranking digital apps, SWIFT wire transfers, and airport cash counters.',
    },
    {
      'q': 'What is the ESX Early Access pipeline?',
      'a': 'The Ethiopian Securities Exchange (ESX) is Ethiopia’s first electronic stock exchange. PAZ is preparing real-time order-book data, trade prints, and corporate prospectus filings for early subscribers.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PazColors.canvas,
      appBar: AppBar(
        title: Text(
          'FREQUENTLY ASKED QUESTIONS',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _faqs.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final faq = _faqs[index];
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: PazTheme.cardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  faq['q']!,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: PazColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  faq['a']!,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: PazColors.textMuted,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PazColors.canvas,
      appBar: AppBar(
        title: Text(
          'LEGAL & REGULATORY NOTICES',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                      Text(
                        'REGULATORY STATUS',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color: PazColors.gold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'PAZ Financial is an independent macro-financial data intelligence platform and analytics provider. PAZ is not a bank, deposit-taking institution, foreign exchange bureau, asset manager, or registered broker-dealer under the National Bank of Ethiopia or Ethiopian Capital Market Authority.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: PazColors.textSecondary,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _buildSection(
              title: 'NO INVESTMENT ADVICE',
              content:
                  'All exchange rates, gold prices, treasury yields, and automated AI analysis are generated for informational, telemetry, and educational purposes only. Nothing contained within PAZ constitutes investment, financial, tax, or legal advice.',
            ),
            const SizedBox(height: 12),
            _buildSection(
              title: 'NBE DIRECTIVE COMPLIANCE',
              content:
                  'All foreign exchange rate publication and bank exchange rate displays adhere to National Bank of Ethiopia Directive No. FXD/01/2024 on Foreign Exchange Market Operations.',
            ),
            const SizedBox(height: 12),
            _buildSection(
              title: 'DATA INTEGRITY & LATENCY',
              content:
                  'While PAZ strives for sub-second accuracy, market conditions and bank reporting schedules may cause periodic latency. Users should confirm execution pricing with their licensed banking institution before executing high-value wire transfers.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required String content}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: PazTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: PazColors.textDim,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: PazColors.textMuted,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class HowToUseScreen extends StatelessWidget {
  const HowToUseScreen({super.key});

  static const List<String> _exampleQuestions = [
    'Which bank has the highest USD buying rate today?',
    'How much did gold change this month?',
    'How much Birr will I get for \$1,000 today?',
    'Compare Gov Savings Rate vs keeping cash in Birr',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PazColors.canvas,
      appBar: AppBar(
        title: Text(
          'HOW TO USE PAZ',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
          ),
        ),
        backgroundColor: PazColors.surface,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildGuideCard(
            step: '01',
            title: 'Compare Bank Exchange Rates',
            description:
                'Open Markets -> Bank Rates to see which Ethiopian bank (CBE, Abyssinia, Awash, Dashen, Bunna, or Zemen) pays the most Birr for USD, EUR, GBP, or AED right now.',
            tip:
                'All live XY price charts on Overview, Bank Rates, and Gold Prices are 100% free for both Free and Guest users.',
          ),
          const SizedBox(height: 14),
          _buildGuideCard(
            step: '02',
            title: 'Track Gold Prices & Market News',
            description:
                'Open Markets -> Gold Prices to check today’s 24K, 22K, 21K, and 18K gold prices per gram in ETB, and read Market News to spot trends before buying or selling.',
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
                    _stepBadge('03'),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Ask PAZ AI Anything',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: PazColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Tap the Ask PAZ tab to ask plain-English questions about today’s rates. Tap any example below to copy it:',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: PazColors.textMuted,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 12),
                ..._exampleQuestions.map(
                  (q) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: q));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: PazColors.card,
                            content: Text(
                              'Copied question to clipboard',
                              style: GoogleFonts.plusJakartaSans(
                                color: PazColors.textPrimary,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: PazColors.inputFill,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: PazColors.borderSubtle),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '"$q"',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: PazColors.textPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'COPY',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: PazColors.emerald,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _buildGuideCard(
            step: '04',
            title: 'Free Account vs. Guest Mode',
            description:
                'Guest Mode lets you check Overview, Bank Rates, Gold Prices, Market News, and all XY charts without signing in.',
            tip:
                'Create a Free Account to unlock Ask PAZ AI (10 messages/day), save your bank balances, and set custom price alerts.',
          ),
        ],
      ),
    );
  }

  Widget _stepBadge(String step) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: PazColors.emeraldMuted,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: PazColors.emerald.withValues(alpha: 0.35)),
      ),
      child: Text(
        step,
        style: GoogleFonts.jetBrainsMono(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: PazColors.emerald,
        ),
      ),
    );
  }

  Widget _buildGuideCard({
    required String step,
    required String title,
    required String description,
    String? tip,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: PazTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _stepBadge(step),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: PazColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: PazColors.textSecondary,
              height: 1.45,
            ),
          ),
          if (tip != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: PazColors.inputFill,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: PazColors.borderSubtle),
              ),
              child: Text(
                tip,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: PazColors.textMuted,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
