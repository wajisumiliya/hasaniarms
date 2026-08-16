import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:barcode_widget/barcode_widget.dart';

import '../../core/network/api_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService api = ApiService();

  final TextEditingController memberController =
      TextEditingController(text: '000101020212');

  final TextEditingController passwordController =
      TextEditingController(text: '123123');

  Map<String, dynamic>? customer;
  Map<String, dynamic>? dashboard;

  String? errorMessage;

  bool loading = false;
  bool obscurePassword = true;

  @override
  void dispose() {
    memberController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> login() async {
    if (loading) return;

    FocusScope.of(context).unfocus();

    setState(() {
      loading = true;
      errorMessage = null;
    });

    try {
      final response = await api.post(
        '/api/customer/login',
        {
          'membership': memberController.text.trim(),
          'password': passwordController.text,
        },
      );

      final customerData = response['customer'];

      if (customerData is! Map) {
        throw Exception('Customer information was not returned.');
      }

      final dashboardData =
          await api.get('/api/customer/dashboard');

      if (!mounted) return;

      setState(() {
        customer = Map<String, dynamic>.from(customerData);
        dashboard = dashboardData;
        errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage = e.toString().replaceFirst(
              'Exception: ',
              '',
            );
      });
    } finally {
      if (!mounted) return;

      setState(() {
        loading = false;
      });
    }
  }

  Future<void> logout() async {
    try {
      await api.post(
        '/api/customer/logout',
        {},
      );
    } catch (_) {
      await api.clearSession();
    }

    if (!mounted) return;

    setState(() {
      customer = null;
      dashboard = null;
      errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (customer == null) {
      return _buildLoginScreen();
    }

    return _buildDashboard();
  }

  Widget _buildLoginScreen() {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 460,
              ),
              child: Card(
                elevation: 5,
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    28,
                    30,
                    28,
                    28,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildLogo(),

                      const SizedBox(height: 22),

                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Hasani Customer',
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),

                      const SizedBox(height: 6),

                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Member Login',
                          style: TextStyle(
                            fontSize: 20,
                          ),
                        ),
                      ),

                      const SizedBox(height: 28),

                      TextField(
                        controller: memberController,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Membership Card Number',
                          prefixIcon: Icon(
                            Icons.badge_outlined,
                          ),
                          border: OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 16),

                      TextField(
                        controller: passwordController,
                        obscureText: obscurePassword,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => login(),
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(
                            Icons.lock_outline,
                          ),
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                obscurePassword =
                                    !obscurePassword;
                              });
                            },
                            icon: Icon(
                              obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons
                                      .visibility_off_outlined,
                            ),
                          ),
                          border: const OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 20),

                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: FilledButton(
                          onPressed: loading ? null : login,
                          child: loading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child:
                                      CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : const Text(
                                  'Login',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight:
                                        FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),

                      if (errorMessage != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(
                              alpha: 0.08,
                            ),
                            borderRadius:
                                BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.red.withValues(
                                alpha: 0.2,
                              ),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: Colors.red,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  errorMessage!,
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 18),

                      const Text(
                        'Initial test password: 123123',
                        style: TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xff2358d8),
            Color(0xff153b99),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_bag_rounded,
              color: Colors.white,
              size: 42,
            ),
            SizedBox(height: 2),
            Text(
              'HASANI',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboard() {
    final purchases =
        dashboard?['purchases'] as List? ?? [];

    final points = _numberValue(
      customer?['points'],
    );

    double totalSpend = 0;

    for (final item in purchases) {
      if (item is Map) {
        totalSpend += _doubleValue(
          item['total'],
        );
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Hasani Customer',
        ),
        actions: [
          IconButton(
            onPressed: logout,
            tooltip: 'Logout',
            icon: const Icon(
              Icons.logout,
            ),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  _smallLogo(),
                  const SizedBox(height: 8),
                  const Text(
                    'Member Menu',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            ListTile(
              leading: const Icon(
                Icons.dashboard_outlined,
              ),
              title: const Text(
                'Dashboard',
              ),
              onTap: () {
                Navigator.pop(context);
              },
            ),

            ListTile(
              leading: const Icon(
                Icons.receipt_long_outlined,
              ),
              title: const Text(
                'Purchase History',
              ),
              onTap: () {
                Navigator.pop(context);

                _showPurchases(
                  context,
                  purchases,
                );
              },
            ),

            ListTile(
              leading: const Icon(
                Icons.stars_outlined,
              ),
              title: const Text(
                'Member Points',
              ),
              onTap: () {
                Navigator.pop(context);

                _showPoints(
                  context,
                  points,
                  totalSpend,
                );
              },
            ),

            const ListTile(
              leading: Icon(
                Icons.card_giftcard_outlined,
              ),
              title: Text(
                'Rewards',
              ),
            ),

            const ListTile(
              leading: Icon(
                Icons.local_offer_outlined,
              ),
              title: Text(
                'Offers',
              ),
            ),

            const ListTile(
              leading: Icon(
                Icons.shopping_cart_outlined,
              ),
              title: Text(
                'Online Store',
              ),
            ),

            const ListTile(
              leading: Icon(
                Icons.location_on_outlined,
              ),
              title: Text(
                'Locations',
              ),
            ),

            const Divider(),

            ListTile(
              leading: const Icon(
                Icons.logout,
              ),
              title: const Text(
                'Logout',
              ),
              onTap: logout,
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: login,
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Text(
              'Welcome, ${customer?['name'] ?? 'Member'}',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 18),

            _memberCard(
              customer!,
            ),

            const SizedBox(height: 14),

            Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _stat(
                    'Points',
                    '$points',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _stat(
                    'Purchase',
                    'RM ${totalSpend.toStringAsFixed(2)}',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _stat(
                    'Transactions',
                    '${purchases.length}',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 22),

            _section(
              'Quick Access',
              [
                _tile(
                  Icons.receipt_long_outlined,
                  'Purchase History',
                  'View your purchases',
                  () => _showPurchases(
                    context,
                    purchases,
                  ),
                ),

                _tile(
                  Icons.stars_outlined,
                  'Member Points',
                  'Points earned from purchases',
                  () => _showPoints(
                    context,
                    points,
                    totalSpend,
                  ),
                ),

                _tile(
                  Icons.card_giftcard_outlined,
                  'Rewards',
                  'Member rewards',
                  null,
                ),

                _tile(
                  Icons.local_offer_outlined,
                  'Offers',
                  'Special offers',
                  null,
                ),

                _tile(
                  Icons.shopping_cart_outlined,
                  'Online Store',
                  'Shop online',
                  null,
                ),

                _tile(
                  Icons.location_on_outlined,
                  'Locations',
                  'Find stores',
                  null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _smallLogo() {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: const Color(0xff2358d8),
      ),
      child: const Icon(
        Icons.shopping_bag_rounded,
        color: Colors.white,
        size: 28,
      ),
    );
  }

  Widget _memberCard(
    Map<String, dynamic> data,
  ) {
    final name =
        data['name']?.toString() ?? 'Member';

    final membership =
        data['membership']?.toString() ?? '';

    return Card(
      color: const Color(0xff2358d8),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Text(
              'HASANI MEMBER',
              style: TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),

            const SizedBox(height: 4),

            Text(
              name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            Text(
              membership,
              style: const TextStyle(
                color: Colors.white70,
              ),
            ),

            const SizedBox(height: 18),

            Wrap(
              spacing: 14,
              runSpacing: 14,
              crossAxisAlignment:
                  WrapCrossAlignment.end,
              children: [
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(7),
                  child: QrImageView(
                    data:
                        'HASANI-MEMBER:$membership',
                    size: 90,
                  ),
                ),

                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(7),
                  width: 210,
                  child: BarcodeWidget(
                    barcode: Barcode.code128(),
                    data: membership,
                    height: 60,
                    drawText: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(
    String title,
    String value,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),

            const SizedBox(height: 5),

            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(
    String title,
    List<Widget> children,
  ) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 10),

        ...children,
      ],
    );
  }

  Widget _tile(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback? onTap,
  ) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(
          Icons.chevron_right,
        ),
        onTap: onTap,
      ),
    );
  }

  void _showPurchases(
    BuildContext context,
    List purchases,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: ListView(
              shrinkWrap: true,
              children: [
                const Text(
                  'Purchase History',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                if (purchases.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(
                      child: Text(
                        'No purchases found.',
                      ),
                    ),
                  ),

                ...purchases.map(
                  (purchase) {
                    final p =
                        Map<String, dynamic>.from(
                      purchase as Map,
                    );

                    final total =
                        _doubleValue(p['total']);

                    return ListTile(
                      leading: const CircleAvatar(
                        child: Icon(
                          Icons.receipt_long,
                        ),
                      ),
                      title: Text(
                        'Receipt #${p['receiptNo'] ?? '-'}',
                      ),
                      subtitle: Text(
                        '${p['date'] ?? '-'} · '
                        '+${p['points'] ?? 0} points',
                      ),
                      trailing: Text(
                        'RM ${total.toStringAsFixed(2)}',
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showPoints(
    BuildContext context,
    int points,
    double spend,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Member Points',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 14),

                Text(
                  'Current points: $points',
                ),

                const SizedBox(height: 6),

                Text(
                  'Verified purchase value: '
                  'RM ${spend.toStringAsFixed(2)}',
                ),

                const SizedBox(height: 6),

                Text(
                  'Points earned: $points',
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  int _numberValue(dynamic value) {
    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  double _doubleValue(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }
}
