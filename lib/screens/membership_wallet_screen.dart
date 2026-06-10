import 'package:flutter/material.dart';

class MembershipWalletScreen extends StatelessWidget {
  const MembershipWalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Membership', style: TextStyle(color: primary, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_none_rounded, color: primary),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Primary Wallet Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFD9001B), Color(0xFF8B0011)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: const [
                BoxShadow(color: Color(0x30000000), blurRadius: 20, offset: Offset(0, 10)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFC9A900),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text(
                              'PLATINUM MEMBER',
                              style: TextStyle(
                                color: Color(0xFF221B00),
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Savings Balance',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Rp 1.200.000',
                            style: theme.textTheme.displayLarge?.copyWith(
                              color: Colors.white,
                              fontSize: 34,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(Icons.qr_code_2_rounded, size: 72, color: const Color(0xFF191C1D)),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(color: Colors.white24),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Reward Points',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: const [
                            Icon(Icons.star_rounded, color: Color(0xFFFFE16D), size: 22),
                            SizedBox(width: 6),
                            Text(
                              '1.250',
                              style: TextStyle(
                                color: Color(0xFFFFE16D),
                                fontWeight: FontWeight.w700,
                                fontSize: 22,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      icon: const Icon(Icons.add_circle_outline_rounded),
                      label: const Text('Top Up', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Active Benefits
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE8BCB8)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Active Benefits', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
                _BenefitRow(
                  icon: Icons.percent_rounded,
                  iconBg: const Color(0xFFFFF3CD),
                  iconColor: const Color(0xFFC9A900),
                  title: '5% extra discount',
                  subtitle: 'Applied to all cooperative retail items',
                ),
                const SizedBox(height: 14),
                _BenefitRow(
                  icon: Icons.priority_high_rounded,
                  iconBg: const Color(0xFFFFE9E6),
                  iconColor: primary,
                  title: 'Priority restock',
                  subtitle: 'Be first to know when items are back',
                ),
                const SizedBox(height: 14),
                _BenefitRow(
                  icon: Icons.event_seat_outlined,
                  iconBg: const Color(0xFFDFE0E0),
                  iconColor: const Color(0xFF5D5F5F),
                  title: 'Member Lounge',
                  subtitle: 'Access to village business hub',
                ),
                const SizedBox(height: 18),
                OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    side: BorderSide(color: primary, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('View All Benefits'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Recent Transactions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Recent Transactions', style: theme.textTheme.headlineMedium),
              TextButton(
                onPressed: () {},
                child: Text('See History', style: TextStyle(color: primary, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE8BCB8)),
            ),
            child: Column(
              children: const [
                _TransactionItem(
                  icon: Icons.shopping_basket_outlined,
                  iconBg: Color(0xFFE7E8E9),
                  iconColor: Color(0xFF5D5F5F),
                  title: 'Cooperative Purchase - Store A',
                  date: '24 Oct 2023 • 14:30',
                  amount: '- Rp 45.000',
                  amountColor: Color(0xFFD9001B),
                  detail: '+12 pts',
                  detailColor: Color(0xFFC9A900),
                  isLast: false,
                ),
                _TransactionItem(
                  icon: Icons.payments_outlined,
                  iconBg: Color(0xFFFFF3CD),
                  iconColor: Color(0xFFC9A900),
                  title: 'Quarterly Dividend Payout',
                  date: '20 Oct 2023 • 09:00',
                  amount: '+ Rp 150.000',
                  amountColor: Color(0xFF1A7F42),
                  detail: 'Direct Savings',
                  detailColor: Color(0xFF6D5A58),
                  isLast: false,
                ),
                _TransactionItem(
                  icon: Icons.receipt_long_outlined,
                  iconBg: Color(0xFFE7E8E9),
                  iconColor: Color(0xFF5D5F5F),
                  title: 'Membership Monthly Contribution',
                  date: '15 Oct 2023 • 10:15',
                  amount: '- Rp 20.000',
                  amountColor: Color(0xFFD9001B),
                  detail: 'Fixed Contribution',
                  detailColor: Color(0xFF6D5A58),
                  isLast: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  const _BenefitRow({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });
  final IconData icon;
  final Color iconBg, iconColor;
  final String title, subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600)),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: const Color(0xFF6D5A58)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TransactionItem extends StatelessWidget {
  const _TransactionItem({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.date,
    required this.amount,
    required this.amountColor,
    required this.detail,
    required this.detailColor,
    required this.isLast,
  });
  final IconData icon;
  final Color iconBg, iconColor;
  final String title, date, amount, detail;
  final Color amountColor, detailColor;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: isLast ? null : const Border(bottom: BorderSide(color: Color(0xFFE8BCB8))),
      ),
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600)),
                Text(date, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: const Color(0xFF6D5A58))),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(amount, style: TextStyle(color: amountColor, fontWeight: FontWeight.w700, fontSize: 14)),
              Text(detail, style: TextStyle(color: detailColor, fontSize: 12, fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }
}
