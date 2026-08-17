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
      TextEditingController();

  Map<String, dynamic>? customer;
  Map<String, dynamic>? dashboard;

  String? errorMessage;

  bool loading = false;
  bool obscurePassword = true;

  // Hasani Books logo currently stored in your web assets.
  static const String logoUrl =
      'https://raw.githubusercontent.com/wajisumiliya/hasaniarms/main/web/assets/hasani-books-logo.jpg';

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
        throw Exception(
          'Customer information was not returned.',
        );
      }

      final dashboardData =
          await api.get('/api/customer/dashboard');

      if (!mounted) return;

      setState(() {
        customer = Map<String, dynamic>.from(
          customerData,
        );

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
      passwordController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (customer == null) {
      return _buildLoginScreen();
    }

    return _buildDashboard();
  }

  // ============================================================
  // LOGIN SCREEN
  // ============================================================

  Widget _buildLoginScreen() {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xfff5f7fb),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 28,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 56,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 460,
                    ),
                    child: Column(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                        // ------------------------------------------------
                        // LOGO
                        // ------------------------------------------------

                        _buildLoginLogo(),

                        const SizedBox(height: 24),

                        // ------------------------------------------------
                        // EYEBROW
                        // ------------------------------------------------

                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'CUSTOMER PORTAL',
                            style: TextStyle(
                              color: Color(0xff2358d8),
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),

                        // ------------------------------------------------
                        // TITLE
                        // ------------------------------------------------

                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Member Login',
                            style: TextStyle(
                              color: Color(0xff172033),
                              fontSize: 32,
                              height: 1.15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        // ------------------------------------------------
                        // DESCRIPTION
                        // ------------------------------------------------

                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Sign in to view your Hasani Books '
                            'membership, points and purchase history.',
                            style: TextStyle(
                              color: Color(0xff667085),
                              fontSize: 14,
                              height: 1.55,
                            ),
                          ),
                        ),

                        const SizedBox(height: 26),

                        // ------------------------------------------------
                        // LOGIN CARD
                        // ------------------------------------------------

                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(22),
                            child: Column(
                              children: [
                                // Membership number
                                const Align(
                                  alignment:
                                      Alignment.centerLeft,
                                  child: Text(
                                    'Membership Card No.',
                                    style: TextStyle(
                                      color:
                                          Color(0xff172033),
                                      fontSize: 13,
                                      fontWeight:
                                          FontWeight.w700,
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 8),

                                TextField(
                                  controller:
                                      memberController,
                                  keyboardType:
                                      TextInputType.number,
                                  textInputAction:
                                      TextInputAction.next,
                                  decoration:
                                      const InputDecoration(
                                    hintText:
                                        'Enter membership card number',
                                    prefixIcon: Icon(
                                      Icons.badge_outlined,
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 18),

                                // Password
                                const Align(
                                  alignment:
                                      Alignment.centerLeft,
                                  child: Text(
                                    'Password',
                                    style: TextStyle(
                                      color:
                                          Color(0xff172033),
                                      fontSize: 13,
                                      fontWeight:
                                          FontWeight.w700,
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 8),

                                TextField(
                                  controller:
                                      passwordController,
                                  obscureText:
                                      obscurePassword,
                                  textInputAction:
                                      TextInputAction.done,
                                  onSubmitted: (_) {
                                    if (!loading) {
                                      login();
                                    }
                                  },
                                  decoration:
                                      InputDecoration(
                                    hintText:
                                        'Enter your password',
                                    prefixIcon:
                                        const Icon(
                                      Icons.lock_outline,
                                    ),
                                    suffixIcon:
                                        IconButton(
                                      tooltip:
                                          obscurePassword
                                              ? 'Show password'
                                              : 'Hide password',
                                      onPressed: () {
                                        setState(() {
                                          obscurePassword =
                                              !obscurePassword;
                                        });
                                      },
                                      icon: Icon(
                                        obscurePassword
                                            ? Icons
                                                .visibility_outlined
                                            : Icons
                                                .visibility_off_outlined,
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 22),

                                // ------------------------------------------------
                                // LOGIN BUTTON
                                // ------------------------------------------------

                                SizedBox(
                                  width: double.infinity,
                                  height: 52,
                                  child: FilledButton(
                                    onPressed:
                                        loading
                                            ? null
                                            : login,
                                    child: AnimatedSwitcher(
                                      duration:
                                          const Duration(
                                        milliseconds: 180,
                                      ),
                                      child: loading
                                          ? const SizedBox(
                                              key: ValueKey(
                                                'loading',
                                              ),
                                              width: 23,
                                              height: 23,
                                              child:
                                                  CircularProgressIndicator(
                                                strokeWidth:
                                                    2.5,
                                                color:
                                                    Colors.white,
                                              ),
                                            )
                                          : const Text(
                                              'Login',
                                              key: ValueKey(
                                                'login',
                                              ),
                                            ),
                                    ),
                                  ),
                                ),

                                // ------------------------------------------------
                                // ERROR MESSAGE
                                // ------------------------------------------------

                                if (errorMessage != null) ...[
                                  const SizedBox(
                                    height: 16,
                                  ),
                                  _buildLoginError(),
                                ],
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // ------------------------------------------------
                        // TEST ACCOUNT NOTE
                        // ------------------------------------------------

                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xff2358d8,
                            ).withValues(
                              alpha: 0.06,
                            ),
                            borderRadius:
                                BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(
                                0xff2358d8,
                              ).withValues(
                                alpha: 0.12,
                              ),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.info_outline,
                                color: Color(0xff2358d8),
                                size: 19,
                              ),
                              const SizedBox(width: 9),
                              Expanded(
                                child: Text(
                                  'For testing, use your existing '
                                  'test membership and password.',
                                  style: TextStyle(
                                    color: theme
                                        .colorScheme
                                        .onSurface
                                        .withValues(
                                          alpha: 0.7,
                                        ),
                                    fontSize: 12,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        const Text(
                          'HASANI BOOKS',
                          style: TextStyle(
                            color: Color(0xff98a2b3),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ============================================================
  // LOGIN LOGO
  // ============================================================

  Widget _buildLoginLogo() {
    return Container(
      width: 108,
      height: 108,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xffe4e7ec),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: 0.07,
            ),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(17),
        child: Image.network(
          logoUrl,
          fit: BoxFit.cover,
          errorBuilder:
              (context, error, stackTrace) {
            return Container(
              color: const Color(0xff2358d8),
              alignment: Alignment.center,
              child: const Text(
                'HASANI\nBOOKS',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  height: 1.1,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                ),
              ),
            );
          },
          loadingBuilder:
              (context, child, progress) {
            if (progress == null) {
              return child;
            }

            return const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xff2358d8),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ============================================================
  // LOGIN ERROR
  // ============================================================

  Widget _buildLoginError() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red.withValues(
          alpha: 0.06,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.red.withValues(
            alpha: 0.18,
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
            size: 21,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              errorMessage!,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DASHBOARD
  // ============================================================

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
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xffe4e7ec),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(9),
        child: Image.network(
          logoUrl,
          fit: BoxFit.cover,
          errorBuilder:
              (context, error, stackTrace) {
            return const Icon(
              Icons.menu_book_rounded,
              color: Color(0xff2358d8),
              size: 28,
            );
          },
        ),
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
      clipBehavior: Clip.antiAlias,
      color: const Color(0xff2358d8),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xff2358d8),
              Color(0xff153b99),
            ],
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Text(
              'HASANI MEMBER',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
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
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xff2358d8)
                .withValues(alpha: 0.08),
            borderRadius:
                BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: const Color(0xff2358d8),
          ),
        ),
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
                      leading:
                          const CircleAvatar(
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
