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
      TextEditingController(
    text: '000101020212',
  );

  final TextEditingController passwordController =
      TextEditingController();

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

  // ============================================================
  // LOGIN
  // ============================================================

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
        customer =
            Map<String, dynamic>.from(customerData);

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

  // ============================================================
  // LOGOUT
  // ============================================================

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

  // ============================================================
  // BUILD
  // ============================================================

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
    return Scaffold(
      backgroundColor: const Color(0xfff5f7fb),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (
            context,
            constraints,
          ) {
            return SingleChildScrollView(
              keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 30,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight:
                      constraints.maxHeight - 60,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints:
                        const BoxConstraints(
                      maxWidth: 520,
                    ),
                    child: Column(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                        // ==================================================
                        // HASANI BOOKS LOGO
                        // ==================================================

                        _buildHasaniBooksLogo(
                          large: true,
                        ),

                        const SizedBox(height: 30),

                        // ==================================================
                        // CUSTOMER PORTAL
                        // ==================================================

                        const Align(
                          alignment:
                              Alignment.centerLeft,
                          child: Text(
                            'CUSTOMER PORTAL',
                            style: TextStyle(
                              color:
                                  Color(0xff2358d8),
                              fontSize: 13,
                              fontWeight:
                                  FontWeight.w800,
                              letterSpacing: 1.7,
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),

                        // ==================================================
                        // TITLE
                        // ==================================================

                        const Align(
                          alignment:
                              Alignment.centerLeft,
                          child: Text(
                            'Member Login',
                            style: TextStyle(
                              color:
                                  Color(0xff172033),
                              fontSize: 34,
                              height: 1.1,
                              fontWeight:
                                  FontWeight.w800,
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        const Align(
                          alignment:
                              Alignment.centerLeft,
                          child: Text(
                            'Sign in to view your Hasani Books '
                            'membership, points and purchase history.',
                            style: TextStyle(
                              color:
                                  Color(0xff667085),
                              fontSize: 15,
                              height: 1.55,
                            ),
                          ),
                        ),

                        const SizedBox(height: 28),

                        // ==================================================
                        // LOGIN CARD
                        // ==================================================

                        Card(
                          elevation: 0,
                          margin: EdgeInsets.zero,
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(
                              22,
                            ),
                            side: const BorderSide(
                              color:
                                  Color(0xffe4e7ec),
                            ),
                          ),
                          child: Padding(
                            padding:
                                const EdgeInsets.all(
                              24,
                            ),
                            child: Column(
                              children: [
                                // Membership label
                                const Align(
                                  alignment:
                                      Alignment.centerLeft,
                                  child: Text(
                                    'Membership Card No.',
                                    style: TextStyle(
                                      color:
                                          Color(0xff172033),
                                      fontSize: 14,
                                      fontWeight:
                                          FontWeight.w700,
                                    ),
                                  ),
                                ),

                                const SizedBox(
                                  height: 9,
                                ),

                                // Membership field
                                TextField(
                                  controller:
                                      memberController,
                                  keyboardType:
                                      TextInputType
                                          .number,
                                  textInputAction:
                                      TextInputAction.next,
                                  decoration:
                                      InputDecoration(
                                    hintText:
                                        'Enter membership card number',
                                    prefixIcon:
                                        const Icon(
                                      Icons
                                          .badge_outlined,
                                    ),
                                    filled: true,
                                    fillColor:
                                        Colors.white,
                                    border:
                                        OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius
                                              .circular(
                                        16,
                                      ),
                                      borderSide:
                                          const BorderSide(
                                        color:
                                            Color(
                                          0xffdfe3e8,
                                        ),
                                      ),
                                    ),
                                    enabledBorder:
                                        OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius
                                              .circular(
                                        16,
                                      ),
                                      borderSide:
                                          const BorderSide(
                                        color:
                                            Color(
                                          0xffdfe3e8,
                                        ),
                                      ),
                                    ),
                                    focusedBorder:
                                        OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius
                                              .circular(
                                        16,
                                      ),
                                      borderSide:
                                          const BorderSide(
                                        color:
                                            Color(
                                          0xff2358d8,
                                        ),
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(
                                  height: 20,
                                ),

                                // Password label
                                const Align(
                                  alignment:
                                      Alignment.centerLeft,
                                  child: Text(
                                    'Password',
                                    style: TextStyle(
                                      color:
                                          Color(0xff172033),
                                      fontSize: 14,
                                      fontWeight:
                                          FontWeight.w700,
                                    ),
                                  ),
                                ),

                                const SizedBox(
                                  height: 9,
                                ),

                                // Password field
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
                                    filled: true,
                                    fillColor:
                                        Colors.white,
                                    border:
                                        OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius
                                              .circular(
                                        16,
                                      ),
                                      borderSide:
                                          const BorderSide(
                                        color:
                                            Color(
                                          0xffdfe3e8,
                                        ),
                                      ),
                                    ),
                                    enabledBorder:
                                        OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius
                                              .circular(
                                        16,
                                      ),
                                      borderSide:
                                          const BorderSide(
                                        color:
                                            Color(
                                          0xffdfe3e8,
                                        ),
                                      ),
                                    ),
                                    focusedBorder:
                                        OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius
                                              .circular(
                                        16,
                                      ),
                                      borderSide:
                                          const BorderSide(
                                        color:
                                            Color(
                                          0xff2358d8,
                                        ),
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(
                                  height: 24,
                                ),

                                // ==================================================
                                // LOGIN BUTTON
                                // ==================================================

                                SizedBox(
                                  width:
                                      double.infinity,
                                  height: 54,
                                  child:
                                      FilledButton(
                                    onPressed:
                                        loading
                                            ? null
                                            : login,
                                    style:
                                        FilledButton
                                            .styleFrom(
                                      backgroundColor:
                                          const Color(
                                        0xff2d5bd7,
                                      ),
                                      disabledBackgroundColor:
                                          const Color(
                                        0xff9db1e9,
                                      ),
                                      shape:
                                          RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius
                                                .circular(
                                          15,
                                        ),
                                      ),
                                    ),
                                    child:
                                        AnimatedSwitcher(
                                      duration:
                                          const Duration(
                                        milliseconds:
                                            180,
                                      ),
                                      child: loading
                                          ? const SizedBox(
                                              key: ValueKey(
                                                'loading',
                                              ),
                                              width: 24,
                                              height: 24,
                                              child:
                                                  CircularProgressIndicator(
                                                strokeWidth:
                                                    2.5,
                                                color: Colors
                                                    .white,
                                              ),
                                            )
                                          : const Text(
                                              'Login',
                                              key: ValueKey(
                                                'login',
                                              ),
                                              style:
                                                  TextStyle(
                                                fontSize:
                                                    17,
                                                fontWeight:
                                                    FontWeight
                                                        .w800,
                                              ),
                                            ),
                                    ),
                                  ),
                                ),

                                // ==================================================
                                // ERROR
                                // ==================================================

                                if (errorMessage !=
                                    null) ...[
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

                        // ==================================================
                        // TEST MESSAGE
                        // ==================================================

                        Container(
                          width:
                              double.infinity,
                          padding:
                              const EdgeInsets
                                  .symmetric(
                            horizontal: 15,
                            vertical: 14,
                          ),
                          decoration:
                              BoxDecoration(
                            color:
                                const Color(
                              0xff2358d8,
                            ).withValues(
                              alpha: 0.06,
                            ),
                            borderRadius:
                                BorderRadius.circular(
                              14,
                            ),
                            border: Border.all(
                              color:
                                  const Color(
                                0xff2358d8,
                              ).withValues(
                                alpha: 0.12,
                              ),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,
                            children: [
                              const Icon(
                                Icons.info_outline,
                                color:
                                    Color(0xff2358d8),
                                size: 20,
                              ),
                              const SizedBox(
                                width: 10,
                              ),
                              const Expanded(
                                child: Text(
                                  'For testing, use your existing '
                                  'test membership and password.',
                                  style: TextStyle(
                                    color:
                                        Color(0xff667085),
                                    fontSize: 13,
                                    height: 1.45,
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
                            color:
                                Color(0xff98a2b3),
                            fontSize: 11,
                            fontWeight:
                                FontWeight.w700,
                            letterSpacing: 1.8,
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
  // HASANI BOOKS WORDMARK
  // ============================================================

  Widget _buildHasaniBooksLogo({
    bool large = false,
  }) {
    final double hasaniSize =
        large ? 50 : 28;

    final double booksSize =
        large ? 48 : 27;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: large ? 12 : 7,
        vertical: large ? 12 : 7,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(
          large ? 24 : 14,
        ),
        border: Border.all(
          color: const Color(0xffe4e7ec),
        ),
        boxShadow: large
            ? [
                BoxShadow(
                  color:
                      Colors.black.withValues(
                    alpha: 0.07,
                  ),
                  blurRadius: 24,
                  offset:
                      const Offset(0, 10),
                ),
              ]
            : null,
      ),
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          children: [
            TextSpan(
              text: 'hasani',
              style: TextStyle(
                color:
                    const Color(0xff263b91),
                fontSize: hasaniSize,
                fontWeight:
                    FontWeight.w900,
                letterSpacing:
                    large ? -2.2 : -1.2,
                height: 1,
              ),
            ),

            // Red dot above the "i"
            WidgetSpan(
              alignment:
                  PlaceholderAlignment
                      .top,
              child: Transform.translate(
                offset: Offset(
                  large ? -8 : -4,
                  large ? -7 : -4,
                ),
                child: Container(
                  width:
                      large ? 12 : 7,
                  height:
                      large ? 12 : 7,
                  decoration:
                      const BoxDecoration(
                    color:
                        Color(0xffed1c24),
                    shape:
                        BoxShape.circle,
                  ),
                ),
              ),
            ),

            TextSpan(
              text: ' BOOKS',
              style: TextStyle(
                color:
                    const Color(0xffed1c24),
                fontSize: booksSize,
                fontWeight:
                    FontWeight.w900,
                letterSpacing:
                    large ? -1.4 : -0.7,
                height: 1,
              ),
            ),
          ],
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
      padding:
          const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:
            Colors.red.withValues(
          alpha: 0.06,
        ),
        borderRadius:
            BorderRadius.circular(12),
        border: Border.all(
          color:
              Colors.red.withValues(
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
              style:
                  const TextStyle(
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
        dashboard?['purchases']
                as List? ??
            [];

    final points =
        _numberValue(
      customer?['points'],
    );

    double totalSpend = 0;

    for (final item in purchases) {
      if (item is Map) {
        totalSpend +=
            _doubleValue(
          item['total'],
        );
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Hasani Books',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
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

      // ==========================================================
      // DRAWER
      // ==========================================================

      drawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              // Logo header
              Padding(
                padding:
                    const EdgeInsets.fromLTRB(
                  22,
                  22,
                  18,
                  18,
                ),
                child: Row(
                  children: [
                    _buildHasaniBooksLogo(),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Text(
                        'HASANI BOOKS',
                        style: TextStyle(
                          color:
                              Color(0xff172033),
                          fontSize: 20,
                          fontWeight:
                              FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(
                height: 1,
              ),

              // Member information
              Padding(
                padding:
                    const EdgeInsets.all(16),
                child: Container(
                  width:
                      double.infinity,
                  padding:
                      const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color:
                        const Color(0xfff5f7fb),
                    borderRadius:
                        BorderRadius.circular(
                      18,
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor:
                            const Color(
                          0xff2d5bd7,
                        ),
                        child: Text(
                          _initial(
                            customer?['name'],
                          ),
                          style:
                              const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(
                        width: 14,
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,
                          children: [
                            Text(
                              customer?['name']
                                      ?.toString() ??
                                  'Member',
                              maxLines: 1,
                              overflow:
                                  TextOverflow
                                      .ellipsis,
                              style:
                                  const TextStyle(
                                fontSize: 16,
                                fontWeight:
                                    FontWeight.w800,
                              ),
                            ),
                            const SizedBox(
                              height: 4,
                            ),
                            Text(
                              customer?[
                                          'membership']
                                      ?.toString() ??
                                  '',
                              style:
                                  const TextStyle(
                                color:
                                    Color(
                                  0xff667085,
                                ),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ==================================================
              // MENU
              // ==================================================

              Expanded(
                child: ListView(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 12,
                  ),
                  children: [
                    _drawerItem(
                      Icons.dashboard_outlined,
                      'Dashboard',
                      selected: true,
                      onTap: () {
                        Navigator.pop(
                          context,
                        );
                      },
                    ),

                    _drawerItem(
                      Icons.receipt_long_outlined,
                      'Purchase History',
                      onTap: () {
                        Navigator.pop(
                          context,
                        );

                        _showPurchases(
                          context,
                          purchases,
                        );
                      },
                    ),

                    _drawerItem(
                      Icons.stars_outlined,
                      'Member Points',
                      onTap: () {
                        Navigator.pop(
                          context,
                        );

                        _showPoints(
                          context,
                          points,
                          totalSpend,
                        );
                      },
                    ),

                    _drawerItem(
                      Icons.person_outline,
                      'Personal Information',
                      onTap: () {
                        Navigator.pop(
                          context,
                        );

                        _showPersonalInfo(
                          context,
                        );
                      },
                    ),

                    _drawerItem(
                      Icons.card_giftcard_outlined,
                      'Rewards',
                    ),

                    _drawerItem(
                      Icons.local_offer_outlined,
                      'Offers',
                    ),

                    _drawerItem(
                      Icons.shopping_cart_outlined,
                      'Online Store',
                    ),
                  ],
                ),
              ),

              const Divider(
                height: 1,
              ),

              // Logout
              Padding(
                padding:
                    const EdgeInsets.all(12),
                child: ListTile(
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(
                      14,
                    ),
                  ),
                  leading: const Icon(
                    Icons.logout,
                    color:
                        Color(0xffe5484d),
                  ),
                  title: const Text(
                    'Logout',
                    style: TextStyle(
                      color:
                          Color(0xffe5484d),
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),
                  onTap: logout,
                ),
              ),
            ],
          ),
        ),
      ),

      // ==========================================================
      // DASHBOARD BODY
      // ==========================================================

      body: RefreshIndicator(
        onRefresh: login,
        child: ListView(
          padding:
              const EdgeInsets.all(18),
          children: [
            Text(
              'Welcome, '
              '${customer?['name'] ?? 'Member'}',
              style: const TextStyle(
                fontSize: 28,
                fontWeight:
                    FontWeight.w800,
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
                const SizedBox(
                  width: 10,
                ),
                Expanded(
                  child: _stat(
                    'Purchase',
                    'RM ${totalSpend.toStringAsFixed(2)}',
                  ),
                ),
                const SizedBox(
                  width: 10,
                ),
                Expanded(
                  child: _stat(
                    'Transactions',
                    '${purchases.length}',
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 22,
            ),

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
                  Icons.person_outline,
                  'Personal Information',
                  'View your member information',
                  () => _showPersonalInfo(
                    context,
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
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // DRAWER ITEM
  // ============================================================

  Widget _drawerItem(
    IconData icon,
    String title, {
    bool selected = false,
    VoidCallback? onTap,
  }) {
    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 5,
      ),
      child: ListTile(
        selected: selected,
        selectedTileColor:
            const Color(0xffedf2ff),
        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(
            16,
          ),
        ),
        leading: Icon(
          icon,
          size: 28,
          color: selected
              ? const Color(
                  0xff2d5bd7,
                )
              : const Color(
                  0xff667085,
                ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 17,
            fontWeight: selected
                ? FontWeight.w800
                : FontWeight.w600,
            color: selected
                ? const Color(
                    0xff2d5bd7,
                  )
                : const Color(
                    0xff172033,
                  ),
          ),
        ),
        onTap: onTap,
      ),
    );
  }

  // ============================================================
  // MEMBER CARD
  // ============================================================

  Widget _memberCard(
    Map<String, dynamic> data,
  ) {
    final name =
        data['name']?.toString() ??
            'Member';

    final membership =
        data['membership']
                ?.toString() ??
            '';

    return Card(
      clipBehavior:
          Clip.antiAlias,
      color:
          const Color(0xff2358d8),
      child: Container(
        decoration:
            const BoxDecoration(
          gradient:
              LinearGradient(
            begin:
                Alignment.topLeft,
            end:
                Alignment.bottomRight,
            colors: [
              Color(0xff2358d8),
              Color(0xff153b99),
            ],
          ),
        ),
        padding:
            const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Text(
              'HASANI MEMBER',
              style: TextStyle(
                color:
                    Colors.white70,
                fontSize: 12,
                fontWeight:
                    FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),

            const SizedBox(
              height: 4,
            ),

            Text(
              name,
              style:
                  const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            Text(
              membership,
              style:
                  const TextStyle(
                color:
                    Colors.white70,
              ),
            ),

            const SizedBox(
              height: 18,
            ),

            Wrap(
              spacing: 14,
              runSpacing: 14,
              crossAxisAlignment:
                  WrapCrossAlignment
                      .end,
              children: [
                Container(
                  color:
                      Colors.white,
                  padding:
                      const EdgeInsets
                          .all(7),
                  child: QrImageView(
                    data:
                        'HASANI-MEMBER:$membership',
                    size: 90,
                  ),
                ),

                Container(
                  color:
                      Colors.white,
                  padding:
                      const EdgeInsets
                          .all(7),
                  width: 210,
                  child:
                      BarcodeWidget(
                    barcode:
                        Barcode.code128(),
                    data:
                        membership,
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

  // ============================================================
  // STAT
  // ============================================================

  Widget _stat(
    String title,
    String value,
  ) {
    return Card(
      child: Padding(
        padding:
            const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style:
                  const TextStyle(
                color:
                    Colors.grey,
                fontSize: 12,
              ),
            ),
            const SizedBox(
              height: 5,
            ),
            Text(
              value,
              maxLines: 1,
              overflow:
                  TextOverflow.ellipsis,
              style:
                  const TextStyle(
                fontSize: 19,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SECTION
  // ============================================================

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
          style:
              const TextStyle(
            fontSize: 20,
            fontWeight:
                FontWeight.bold,
          ),
        ),

        const SizedBox(
          height: 10,
        ),

        ...children,
      ],
    );
  }

  // ============================================================
  // QUICK TILE
  // ============================================================

  Widget _tile(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback? onTap,
  ) {
    return Card(
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 4,
        ),
        leading: Container(
          width: 44,
          height: 44,
          decoration:
              BoxDecoration(
            color:
                const Color(
              0xff2358d8,
            ).withValues(
              alpha: 0.08,
            ),
            borderRadius:
                BorderRadius.circular(
              12,
            ),
          ),
          child: Icon(
            icon,
            color:
                const Color(
              0xff2358d8,
            ),
          ),
        ),
        title: Text(
          title,
          style:
              const TextStyle(
            fontWeight:
                FontWeight.w700,
          ),
        ),
        subtitle:
            Text(subtitle),
        trailing:
            const Icon(
          Icons.chevron_right,
        ),
        onTap: onTap,
      ),
    );
  }

  // ============================================================
  // PURCHASE HISTORY
  // ============================================================

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
            padding:
                const EdgeInsets.all(
              20,
            ),
            child: ListView(
              shrinkWrap: true,
              children: [
                const Text(
                  'Purchase History',
                  style:
                      TextStyle(
                    fontSize: 24,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(
                  height: 12,
                ),

                if (purchases.isEmpty)
                  const Padding(
                    padding:
                        EdgeInsets.all(
                      20,
                    ),
                    child: Center(
                      child: Text(
                        'No purchases found.',
                      ),
                    ),
                  ),

                ...purchases.map(
                  (purchase) {
                    final p =
                        Map<String,
                            dynamic>.from(
                      purchase as Map,
                    );

                    final total =
                        _doubleValue(
                      p['total'],
                    );

                    return ListTile(
                      leading:
                          const CircleAvatar(
                        child:
                            Icon(
                          Icons
                              .receipt_long,
                        ),
                      ),
                      title: Text(
                        'Receipt #'
                        '${p['receiptNo'] ?? '-'}',
                      ),
                      subtitle:
                          Text(
                        '${p['date'] ?? '-'} · '
                        '+${p['points'] ?? 0} points',
                      ),
                      trailing:
                          Text(
                        'RM '
                        '${total.toStringAsFixed(2)}',
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

  // ============================================================
  // POINTS
  // ============================================================

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
            padding:
                const EdgeInsets.all(
              20,
            ),
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              children: [
                const Text(
                  'Member Points',
                  style:
                      TextStyle(
                    fontSize: 24,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(
                  height: 14,
                ),

                Text(
                  'Current points: $points',
                ),

                const SizedBox(
                  height: 6,
                ),

                Text(
                  'Verified purchase value: '
                  'RM ${spend.toStringAsFixed(2)}',
                ),

                const SizedBox(
                  height: 6,
                ),

                Text(
                  'Points earned: $points',
                ),

                const SizedBox(
                  height: 20,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // PERSONAL INFORMATION
  // ============================================================

  void _showPersonalInfo(
    BuildContext context,
  ) {
    final name =
        customer?['name']
                ?.toString() ??
            'Member';

    final membership =
        customer?['membership']
                ?.toString() ??
            '-';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.all(
              22,
            ),
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              children: [
                const Text(
                  'Personal Information',
                  style:
                      TextStyle(
                    fontSize: 24,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(
                  height: 20,
                ),

                _infoRow(
                  Icons.person_outline,
                  'Name',
                  name,
                ),

                _infoRow(
                  Icons.badge_outlined,
                  'Membership',
                  membership,
                ),

                _infoRow(
                  Icons.stars_outlined,
                  'Points',
                  '${_numberValue(customer?['points'])}',
                ),

                const SizedBox(
                  height: 15,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _infoRow(
    IconData icon,
    String label,
    String value,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 16,
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration:
                BoxDecoration(
              color:
                  const Color(
                0xff2358d8,
              ).withValues(
                alpha: 0.08,
              ),
              borderRadius:
                  BorderRadius.circular(
                12,
              ),
            ),
            child: Icon(
              icon,
              color:
                  const Color(
                0xff2358d8,
              ),
            ),
          ),
          const SizedBox(
            width: 12,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              children: [
                Text(
                  label,
                  style:
                      const TextStyle(
                    color:
                        Color(
                      0xff667085,
                    ),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(
                  height: 3,
                ),
                Text(
                  value,
                  style:
                      const TextStyle(
                    fontSize: 15,
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // INITIAL
  // ============================================================

  String _initial(
    dynamic value,
  ) {
    final text =
        value?.toString().trim() ??
            '';

    if (text.isEmpty) {
      return 'M';
    }

    return text
        .substring(0, 1)
        .toUpperCase();
  }

  // ============================================================
  // NUMBER
  // ============================================================

  int _numberValue(
    dynamic value,
  ) {
    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  // ============================================================
  // DOUBLE
  // ============================================================

  double _doubleValue(
    dynamic value,
  ) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }
}
