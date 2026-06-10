import 'package:flutter/material.dart';

class PaymentMethodsScreen extends StatelessWidget {
  const PaymentMethodsScreen({super.key});

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
        title: Text('Payment Methods', style: TextStyle(color: primary, fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Payment Methods', style: theme.textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(
            'Manage your linked accounts and payment options.',
            style: theme.textTheme.bodyLarge?.copyWith(color: const Color(0xFF6D5A58)),
          ),
          const SizedBox(height: 24),

          // KDMP Cooperative Balance
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFD9001B), Color(0xFF8B0011)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [BoxShadow(color: Color(0x26000000), blurRadius: 16, offset: Offset(0, 8))],
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.account_balance_wallet_outlined, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'KDMP Cooperative Balance',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Rp 450.000',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 22),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Top Up',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Linked Bank Accounts
          _GroupTitle(title: 'Linked Bank Accounts'),
          const SizedBox(height: 12),
          _PaymentCard(
            icon: Icons.account_balance_outlined,
            iconColor: const Color(0xFF1565C0),
            iconBg: const Color(0xFFE3F2FD),
            title: 'Bank BRI - Savings',
            subtitle: '•••• •••• •••• 4821',
            badge: 'PRIMARY',
            badgeFg: const Color(0xFF116C46),
            badgeBg: const Color(0xFFDFF5E8),
            onEdit: () {},
            onDelete: () {},
          ),
          const SizedBox(height: 12),
          _PaymentCard(
            icon: Icons.account_balance_outlined,
            iconColor: const Color(0xFF5D5F5F),
            iconBg: const Color(0xFFDFE0E0),
            title: 'Bank Mandiri - Savings',
            subtitle: '•••• •••• •••• 7743',
            badge: null,
            badgeFg: Colors.transparent,
            badgeBg: Colors.transparent,
            onEdit: () {},
            onDelete: () {},
          ),
          const SizedBox(height: 24),

          // E-wallets
          _GroupTitle(title: 'Linked E-Wallets'),
          const SizedBox(height: 12),
          _PaymentCard(
            icon: Icons.phone_android_outlined,
            iconColor: const Color(0xFF1A7F42),
            iconBg: const Color(0xFFDFF5E8),
            title: 'GoPay',
            subtitle: '+62 812-3456-7890',
            badge: 'VERIFIED',
            badgeFg: const Color(0xFF116C46),
            badgeBg: const Color(0xFFDFF5E8),
            onEdit: () {},
            onDelete: () {},
          ),
          const SizedBox(height: 24),

          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const AddPaymentMethodScreen()),
            ),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(62),
              side: BorderSide(color: primary, width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            ),
            icon: Icon(Icons.add_rounded, color: primary),
            label: const Text('Add Payment Method'),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _GroupTitle extends StatelessWidget {
  const _GroupTitle({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: const Color(0xFF6D5A58),
          ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.badgeFg,
    required this.badgeBg,
    required this.onEdit,
    required this.onDelete,
  });

  final IconData icon;
  final Color iconColor, iconBg;
  final String title, subtitle;
  final String? badge;
  final Color badgeFg, badgeBg;
  final VoidCallback onEdit, onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8BCB8)),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconColor, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (badge != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: badgeBg,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              badge!,
                              style: TextStyle(
                                color: badgeFg,
                                fontWeight: FontWeight.w700,
                                fontSize: 10,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF6D5A58),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                onPressed: onEdit,
                icon: Icon(
                  Icons.edit_outlined,
                  color: theme.colorScheme.primary,
                  size: 22,
                ),
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: Color(0xFFBA1A1A),
                  size: 22,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Add Payment Method Screen ────────────────────────────────────────────────

class AddPaymentMethodScreen extends StatefulWidget {
  const AddPaymentMethodScreen({super.key});

  @override
  State<AddPaymentMethodScreen> createState() => _AddPaymentMethodScreenState();
}

class _AddPaymentMethodScreenState extends State<AddPaymentMethodScreen> {
  int _selectedType = 0; // 0 = bank, 1 = e-wallet

  final _accountController = TextEditingController();
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _accountController.dispose();
    _nameController.dispose();
    super.dispose();
  }

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
        title: Text('Add Payment Method', style: TextStyle(color: primary, fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Add Payment Method', style: theme.textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(
            'Choose the type of account you want to add.',
            style: theme.textTheme.bodyLarge?.copyWith(color: const Color(0xFF6D5A58)),
          ),
          const SizedBox(height: 24),

          // Type selector
          Row(
            children: [
              Expanded(
                child: _TypeButton(
                  icon: Icons.account_balance_outlined,
                  label: 'Bank Account',
                  selected: _selectedType == 0,
                  onTap: () => setState(() => _selectedType = 0),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _TypeButton(
                  icon: Icons.phone_android_outlined,
                  label: 'E-Wallet',
                  selected: _selectedType == 1,
                  onTap: () => setState(() => _selectedType = 1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          if (_selectedType == 0) ...[
            _buildLabel(context, 'Bank Name'),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F3F5),
                borderRadius: BorderRadius.circular(18),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: 'Bank BRI',
                  isExpanded: true,
                  items: ['Bank BRI', 'Bank BNI', 'Bank Mandiri', 'Bank BCA', 'Bank BTN']
                      .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                      .toList(),
                  onChanged: (_) {},
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildLabel(context, 'Account Number'),
            const SizedBox(height: 6),
            TextField(
              controller: _accountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Enter account number',
                filled: true,
                fillColor: const Color(0xFFF1F3F5),
                suffixIcon: const Icon(Icons.credit_card_outlined, color: Color(0xFF9F7E79)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: primary, width: 1.5)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
              ),
            ),
            const SizedBox(height: 16),
            _buildLabel(context, 'Account Holder Name'),
            const SizedBox(height: 6),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'As shown on your bank',
                filled: true,
                fillColor: const Color(0xFFF1F3F5),
                suffixIcon: const Icon(Icons.person_outline_rounded, color: Color(0xFF9F7E79)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: primary, width: 1.5)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
              ),
            ),
          ] else ...[
            _buildLabel(context, 'E-Wallet Provider'),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F3F5),
                borderRadius: BorderRadius.circular(18),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: 'GoPay',
                  isExpanded: true,
                  items: ['GoPay', 'OVO', 'DANA', 'ShopeePay', 'LinkAja']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (_) {},
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildLabel(context, 'Registered Phone Number'),
            const SizedBox(height: 6),
            TextField(
              controller: _accountController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                hintText: '+62 000-0000-0000',
                filled: true,
                fillColor: const Color(0xFFF1F3F5),
                suffixIcon: const Icon(Icons.call_outlined, color: Color(0xFF9F7E79)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: primary, width: 1.5)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
              ),
            ),
          ],
          const SizedBox(height: 32),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            style: FilledButton.styleFrom(
              backgroundColor: primary,
              minimumSize: const Size.fromHeight(62),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            ),
            child: const Text('Add Account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildLabel(BuildContext context, String label) {
    return Text(
      label,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
    );
  }
}

class _TypeButton extends StatelessWidget {
  const _TypeButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: selected ? primary.withValues(alpha: 0.08) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: selected ? primary : const Color(0xFFE8BCB8), width: selected ? 2 : 1),
        ),
        child: Column(
          children: [
            Icon(icon, color: selected ? primary : const Color(0xFF6D5A58), size: 30),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: selected ? primary : const Color(0xFF6D5A58),
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
