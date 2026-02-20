import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          color: AppTheme.backgroundLight,
        ),
        child: Stack(
          children: <Widget>[
            Positioned(
              top: 120,
              right: -90,
              child: Container(
                width: 220,
                height: 220,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: <Color>[
                      Color(0x228B5CF6),
                      Color(0x008B5CF6),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 40,
              left: -100,
              child: Container(
                width: 240,
                height: 240,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: <Color>[
                      Color(0x220EA5E9),
                      Color(0x000EA5E9),
                    ],
                  ),
                ),
              ),
            ),
            CustomScrollView(
              slivers: <Widget>[
                _buildHeader(),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate(
                      <Widget>[
                        _buildHeroCard(),
                        const SizedBox(height: 20),
                        _buildDeploySection(context),
                        const SizedBox(height: 20),
                        _buildStatsSection(),
                        const SizedBox(height: 20),
                        _buildLockerSection(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  SliverAppBar _buildHeader() {
    return SliverAppBar(
      pinned: true,
      floating: false,
      expandedHeight: 88,
      backgroundColor: AppTheme.backgroundLight.withValues(alpha: 0.96),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: Colors.black12),
      ),
      flexibleSpace: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: <Widget>[
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: <Color>[AppTheme.neonPurple, AppTheme.neonBlue],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: const <BoxShadow>[
                    BoxShadow(
                      blurRadius: 14,
                      color: Color(0x2E8B5CF6),
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    'M',
                    style: GoogleFonts.blackOpsOne(
                      color: Colors.white,
                      fontSize: 24,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'MathInk',
                      style: GoogleFonts.blackOpsOne(
                        fontSize: 20,
                        letterSpacing: 1.1,
                        color: AppTheme.textMain,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: <Widget>[
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: AppTheme.onlineGreen,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'ONLINE',
                          style: GoogleFonts.chakraPetch(
                            fontSize: 10,
                            letterSpacing: 1.3,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.neonBlue,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: AppTheme.neonGold),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: <Widget>[
                    const Icon(Icons.auto_awesome, color: AppTheme.neonGold, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '2,450',
                      style: GoogleFonts.blackOpsOne(
                        color: AppTheme.textMain,
                        fontSize: 13,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.notifications_none, color: AppTheme.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroCard() {
    return ClipPath(
      clipper: const _CutCornerClipper(cut: 12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppTheme.neonPurple, width: 2),
          boxShadow: const <BoxShadow>[
            BoxShadow(color: Color(0x33000000), blurRadius: 14, offset: Offset(0, 6)),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    color: AppTheme.accentRed,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        const Icon(Icons.bolt, color: Colors.white, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          'DAILY OPS',
                          style: GoogleFonts.chakraPetch(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '12:45:00 LEFT',
                    style: GoogleFonts.chakraPetch(
                      color: AppTheme.neonGold,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Linear Warfare',
                style: GoogleFonts.blackOpsOne(
                  fontSize: 30,
                  color: AppTheme.textMain,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.only(left: 8),
                decoration: const BoxDecoration(
                  border: Border(
                    left: BorderSide(color: AppTheme.neonPurple, width: 2),
                  ),
                ),
                child: Text(
                  'Solve 5 complex equations. Dominate the server. Double XP active.',
                  style: GoogleFonts.chakraPetch(
                    color: AppTheme.textMuted,
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: <Color>[AppTheme.neonPurple, Color(0xFF4F46E5)],
                  ),
                ),
                child: Center(
                  child: Text(
                    'ENGAGE',
                    style: GoogleFonts.blackOpsOne(
                      color: Colors.white,
                      fontSize: 20,
                      letterSpacing: 2,
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

  Widget _buildDeploySection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Container(width: 4, height: 16, color: AppTheme.neonBlue),
            const SizedBox(width: 8),
            Text(
              'Deploy',
              style: GoogleFonts.blackOpsOne(
                fontSize: 22,
                letterSpacing: 1.2,
                color: AppTheme.textMain,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        InkWell(
          onTap: () {
            Navigator.of(context).pushNamed('/quick-test');
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFE5E7EB)),
              borderRadius: BorderRadius.circular(12),
              boxShadow: const <BoxShadow>[
                BoxShadow(color: Color(0x22000000), blurRadius: 10, offset: Offset(0, 5)),
              ],
            ),
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Container(
                      width: 52,
                      height: 52,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: <Color>[AppTheme.neonBlue, Color(0xFF22D3EE)],
                        ),
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                      child: const Icon(Icons.timer, color: Colors.white, size: 30),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Quick Test',
                            style: GoogleFonts.blackOpsOne(
                              fontSize: 24,
                              color: AppTheme.textMain,
                            ),
                          ),
                          Text(
                            'RANKED • SOLO QUEUE',
                            style: GoogleFonts.chakraPetch(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.neonBlue,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'XP+',
                      style: GoogleFonts.blackOpsOne(
                        fontSize: 24,
                        color: AppTheme.textMain,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    _chip(
                      dot: AppTheme.onlineGreen,
                      icon: null,
                      text: 'LOW LATENCY',
                    ),
                    _chip(
                      dot: null,
                      icon: Icons.emoji_events,
                      text: 'PRIZE POOL',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: AppTheme.neonBlue, width: 2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      'Quick Match',
                      style: GoogleFonts.chakraPetch(
                        color: AppTheme.neonBlue,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsSection() {
    return Row(
      children: <Widget>[
        Expanded(
          child: _statCard(
            title: 'League',
            icon: Icons.workspace_premium,
            iconColor: AppTheme.neonGold,
            value: '#4',
            chipText: 'SILVER DIV',
            chipColor: AppTheme.neonGold,
            footerText: 'RANK UP IMMINENT',
            footerColor: AppTheme.onlineGreen,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _statCard(
            title: 'Streak',
            icon: Icons.local_fire_department,
            iconColor: AppTheme.accentRed,
            value: '12',
            chipText: 'DAYS ACTIVE',
            chipColor: AppTheme.accentRed,
            footerText: 'MULTIPLIER 1.2x',
            footerColor: AppTheme.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildLockerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Container(width: 4, height: 16, color: AppTheme.neonPurple),
            const SizedBox(width: 8),
            Text(
              'Locker',
              style: GoogleFonts.blackOpsOne(
                fontSize: 22,
                color: AppTheme.textMain,
                letterSpacing: 1.2,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: const Color(0xFFD1D5DB)),
              ),
              child: Text(
                '8/24 UNLOCKED',
                style: GoogleFonts.chakraPetch(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textMuted,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 182,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: const <Widget>[
              _LockerCard(
                emoji: '🦊',
                title: 'FOX OPS',
                rarity: 'LEGENDARY',
                rarityColor: AppTheme.neonPurple,
                equipped: true,
              ),
              SizedBox(width: 12),
              _LockerCard(
                emoji: '🦉',
                title: 'PROFESSOR',
                rarity: 'RARE',
                rarityColor: AppTheme.neonBlue,
              ),
              SizedBox(width: 12),
              _LockerCard(
                emoji: '🐼',
                title: 'PANDA',
                rarity: 'LOCKED',
                rarityColor: AppTheme.textMuted,
                locked: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _chip({Color? dot, IconData? icon, required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (dot != null) ...<Widget>[
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
            ),
            const SizedBox(width: 5),
          ],
          if (icon != null) ...<Widget>[
            Icon(icon, size: 12, color: AppTheme.neonGold),
            const SizedBox(width: 5),
          ],
          Text(
            text,
            style: GoogleFonts.chakraPetch(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required String value,
    required String chipText,
    required Color chipColor,
    required String footerText,
    required Color footerColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const <BoxShadow>[
          BoxShadow(color: Color(0x22000000), blurRadius: 8, offset: Offset(0, 5)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(
                title,
                style: GoogleFonts.blackOpsOne(
                  fontSize: 14,
                  letterSpacing: 1,
                  color: AppTheme.textMuted,
                ),
              ),
              const Spacer(),
              Icon(icon, color: iconColor, size: 20),
            ],
          ),
          const SizedBox(height: 10),
          Center(
            child: Text(
              value,
              style: GoogleFonts.blackOpsOne(
                fontSize: 42,
                color: AppTheme.textMain,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: chipColor.withValues(alpha: 0.12),
                border: Border.all(color: chipColor.withValues(alpha: 0.32)),
              ),
              child: Text(
                chipText,
                style: GoogleFonts.chakraPetch(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: chipColor,
                  letterSpacing: 1.1,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Container(height: 1, color: const Color(0xFFE5E7EB)),
          const SizedBox(height: 8),
          Center(
            child: Text(
              footerText,
              style: GoogleFonts.chakraPetch(
                color: footerColor,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LockerCard extends StatelessWidget {
  const _LockerCard({
    required this.emoji,
    required this.title,
    required this.rarity,
    required this.rarityColor,
    this.equipped = false,
    this.locked = false,
  });

  final String emoji;
  final String title;
  final String rarity;
  final Color rarityColor;
  final bool equipped;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final Color cardColor = locked ? const Color(0xFFF3F4F6) : Colors.white;
    final Color borderColor = equipped
        ? AppTheme.neonPurple
        : (locked ? const Color(0xFFD1D5DB) : const Color(0xFFE5E7EB));
    return Container(
      width: 132,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Stack(
        children: <Widget>[
          if (equipped)
            Align(
              alignment: Alignment.topLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                color: AppTheme.neonPurple,
                child: Text(
                  'EQUIPPED',
                  style: GoogleFonts.chakraPetch(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.7,
                  ),
                ),
              ),
            ),
          Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              const Spacer(),
              Text(
                emoji,
                style: TextStyle(
                  fontSize: 52,
                  color: locked ? Colors.black45 : null,
                ),
              ),
              const SizedBox(height: 8),
              Container(height: 1, color: const Color(0xFFE5E7EB)),
              const SizedBox(height: 8),
              Text(
                title,
                style: GoogleFonts.blackOpsOne(
                  fontSize: 14,
                  color: locked ? AppTheme.textMuted : AppTheme.textMain,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                rarity,
                style: GoogleFonts.chakraPetch(
                  fontSize: 9,
                  color: rarityColor,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.9,
                ),
              ),
            ],
          ),
          if (locked)
            const Positioned(
              top: 58,
              left: 0,
              right: 0,
              child: Icon(Icons.lock, color: AppTheme.textMain),
            ),
        ],
      ),
    );
  }
}

class _CutCornerClipper extends CustomClipper<Path> {
  const _CutCornerClipper({this.cut = 10});

  final double cut;

  @override
  Path getClip(Size size) {
    return Path()
      ..moveTo(cut, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height - cut)
      ..lineTo(size.width - cut, size.height)
      ..lineTo(0, size.height)
      ..lineTo(0, cut)
      ..close();
  }

  @override
  bool shouldReclip(covariant _CutCornerClipper oldClipper) {
    return oldClipper.cut != cut;
  }
}
