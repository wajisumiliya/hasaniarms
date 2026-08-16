import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:barcode_widget/barcode_widget.dart';

import '../../core/network/api_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

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

  @override
  void dispose() {
    memberController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> login() async {
    if (loading) {
      return;
    }

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

      final loggedCustomer = response['customer'];

      if (loggedCustomer == null) {
        throw Exception(
          'Invalid customer data returned by server.',
        );
      }

      final customerData =
          Map<String, dynamic>.from(loggedCustomer);

      Map<String, dynamic> dashboardData = {};

      try {
        final dashboardResponse =
            await api.get('/api/customer/dashboard');

        dashboardData =
            Map<String, dynamic>.from(dashboardResponse);
      } catch (_) {
        dashboardData = {};
      }

      if (!mounted) {
        return;
      }

      setState(() {
        customer = customerData;
        dashboard = dashboardData;
        errorMessage = null;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        errorMessage = e.toString();
      });
    } finally {
      if (!mounted) {
        return;
      }

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
    } catch (_) {}

    try {
      await api.clearSession();
    } catch (_) {}

    if (!mounted) {
      return;
    }

    setState(() {
      customer = null;
      dashboard = null;
      errorMessage = null;
    });
  }

  List<Map<String, dynamic>> get purchases {
    final value = dashboard?['purchases'];

    if (value is! List) {
      return [];
    }

    return value
        .whereType<Map>()
        .map(
          (item) => Map<String, dynamic>.from(item),
        )
        .toList();
  }

  int get points {
    final value = customer?['points'];

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
          value?.toString() ?? '0',
        ) ??
        0;
  }

  double get totalSpend {
    double total = 0;

    for (final purchase in purchases) {
      final value = purchase['total'];

      if (value is num) {
        total += value.toDouble();
      } else {
        total +=
            double.tryParse(
              value?.toString() ?? '0',
            ) ??
            0;
      }
    }

    return total;
  }

  @override
  Widget build(BuildContext context) {
    if (customer == null) {
      return _buildLoginScreen();
    }

    return _buildDashboardScreen();
  }

  Widget _buildLoginScreen() {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 450,
              ),
              child: Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Hasani Customer',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Member Login',
                        style: TextStyle(
                          fontSize: 17,
                        ),
                      ),
                      const SizedBox(height: 26),
                      TextField(
                        controller: memberController,
                        keyboardType:
                            TextInputType.number,
                        decoration:
                            const InputDecoration(
                          labelText:
                              'Membership Card Number',
                          prefixIcon:
                              Icon(Icons.badge_outlined),
                          border:
                              OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: passwordController,
                        obscureText: true,
                        decoration:
                            const InputDecoration(
                          labelText: 'Password',
                          prefixIcon:
                              Icon(Icons.lock_outline),
                          border:
                              OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: FilledButton(
                          onPressed:
                              loading ? null : login,
                          child: Text(
                            loading
                                ? 'Signing in...'
                                : 'Login',
                          ),
                        ),
                      ),
                      if (errorMessage != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding:
                              const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red
                                .withValues(alpha: 0.08),
                            borderRadius:
                                BorderRadius.circular(8),
                          ),
                          child: Text(
                            errorMessage!,
                            style:
                                const TextStyle(
                              color: Colors.red,
                            ),
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

  Widget _buildDashboardScreen() {
    final name =
        customer?['name']?.toString() ?? 'Member';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hasani Customer'),
        actions: [
          IconButton(
            tooltip: 'Logout',
            onPressed: logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: RefreshIndicator(
        onRefresh: _refreshDashboard,
        child: ListView(
          physics:
              const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(18),
          children: [
            Text(
              'Welcome, $name',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 18),
            _buildMemberCard(customer ?? {}),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Points',
                    points.toString(),
                    Icons.stars,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildStatCard(
                    'Purchase',
                    'RM ${totalSpend.toStringAsFixed(2)}',
                    Icons.receipt_long,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildStatCard(
                    'Transactions',
                    purchases.length.toString(),
                    Icons.shopping_bag,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            _buildSection(
              'Quick Access',
              [
                _buildMenuTile(
                  icon: Icons.receipt_long,
                  title: 'Purchase History',
                  subtitle: 'View your purchases',
                  onTap: () {
                    _showPurchases(
                      context,
                      purchases,
                    );
                  },
                ),
                _buildMenuTile(
                  icon: Icons.stars,
                  title: 'Member Points',
                  subtitle:
                      'Points earned from purchases',
                  onTap: () {
                    _showPoints(
                      context,
                      points,
                      totalSpend,
                    );
                  },
                ),
                _buildMenuTile(
                  icon: Icons.card_giftcard,
                  title: 'Rewards',
                  subtitle: 'Member rewards',
                  onTap: () {
                    _showComingSoon(
                      context,
                      'Rewards',
                    );
                  },
                ),
                _buildMenuTile(
                  icon: Icons.local_offer,
                  title: 'Offers',
                  subtitle: 'Special member offers',
                  onTap: () {
                    _showComingSoon(
                      context,
                      'Offers',
                    );
                  },
                ),
                _buildMenuTile(
                  icon: Icons.shopping_cart,
                  title: 'Online Store',
                  subtitle: 'Shop online',
                  onTap: () {
                    _showComingSoon(
                      context,
                      'Online Store',
                    );
                  },
                ),
                _buildMenuTile(
                  icon: Icons.location_on,
                  title: 'Locations',
                  subtitle: 'Find Hasani stores',
                  onTap: () {
                    _showComingSoon(
                      context,
                      'Locations',
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _refreshDashboard() async {
    try {
      final response =
          await api.get('/api/customer/dashboard');

      if (!mounted) {
        return;
      }

      setState(() {
        dashboard =
            Map<String, dynamic>.from(response);
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to refresh dashboard: $e',
          ),
        ),
      );
    }
  }

  Widget _buildDrawer() {
    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.account_circle,
                    size: 58,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Member Menu',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading:
                  const Icon(Icons.dashboard),
              title:
                  const Text('Dashboard'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.receipt_long,
              ),
              title:
                  const Text('Purchase History'),
              onTap: () {
                Navigator.pop(context);
                _showPurchases(
                  context,
                  purchases,
                );
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.stars),
              title:
                  const Text('Member Points'),
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
              leading:
                  Icon(Icons.card_giftcard),
              title:
                  Text('Rewards'),
            ),
            const ListTile(
              leading:
                  Icon(Icons.local_offer),
              title:
                  Text('Offers'),
            ),
            const ListTile(
              leading:
                  Icon(Icons.shopping_cart),
              title:
                  Text('Online Store'),
            ),
            const ListTile(
              leading:
                  Icon(Icons.location_on),
              title:
                  Text('Locations'),
            ),
            const Divider(),
            ListTile(
              leading:
                  const Icon(Icons.logout),
              title:
                  const Text('Logout'),
              onTap: () async {
                Navigator.pop(context);
                await logout();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberCard(
    Map<String, dynamic> data,
  ) {
    final name =
        data['name']?.toString() ?? 'Member';

    final membership =
        data['membership']?.toString() ?? '';

    return Card(
      clipBehavior: Clip.antiAlias,
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
            const SizedBox(height: 6),
            Text(
              name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              membership,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 14,
              runSpacing: 14,
              children: [
                Container(
                  color: Colors.white,
                  padding:
                      const EdgeInsets.all(8),
                  child: QrImageView(
                    data:
                        'HASANI-MEMBER:$membership',
                    size: 100,
                  ),
                ),
                Container(
                  width: 210,
                  color: Colors.white,
                  padding:
                      const EdgeInsets.all(8),
                  child: BarcodeWidget(
                    barcode:
                        Barcode.code128(),
                    data: membership.isEmpty
                        ? 'HASANI'
                        : membership,
                    height: 65,
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

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              size: 22,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 5),
            FittedBox(
              alignment:
                  Alignment.centerLeft,
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
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

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing:
            const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  void _showPurchases(
    BuildContext context,
    List<Map<String, dynamic>> purchaseList,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              height:
                  MediaQuery.of(context)
                          .size
                          .height *
                      0.75,
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Purchase History',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (purchaseList.isEmpty)
                    const Expanded(
                      child: Center(
                        child: Text(
                          'No purchases found.',
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child:
                          ListView.builder(
                        itemCount:
                            purchaseList.length,
                        itemBuilder:
                            (context, index) {
                          final purchase =
                              purchaseList[
                                  index];

                          final receipt =
                              purchase[
                                          'receiptNo']
                                      ?.toString() ??
                                  '-';

                          final date =
                              purchase['date']
                                      ?.toString() ??
                                  '-';

                          final purchasePoints =
                              purchase[
                                          'points']
                                      ?.toString() ??
                                  '0';

                          final totalValue =
                              _toDouble(
                            purchase['total'],
                          );

                          return Card(
                            child: ListTile(
                              title: Text(
                                'Receipt #$receipt',
                              ),
                              subtitle: Text(
                                '$date · +'
                                '$purchasePoints points',
                              ),
                              trailing: Text(
                                'RM '
                                '${totalValue.toStringAsFixed(2)}',
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showPoints(
    BuildContext context,
    int currentPoints,
    double spend,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Member Points',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Current points: '
                  '$currentPoints',
                ),
                const SizedBox(height: 8),
                Text(
                  'Verified purchase value: '
                  'RM ${spend.toStringAsFixed(2)}',
                ),
                const SizedBox(height: 8),
                Text(
                  'Points earned: '
                  '$currentPoints',
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showComingSoon(
    BuildContext context,
    String feature,
  ) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(
          '$feature will be available soon.',
        ),
      ),
    );
  }

  double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ?? '0',
        ) ??
        0;
  }
}
