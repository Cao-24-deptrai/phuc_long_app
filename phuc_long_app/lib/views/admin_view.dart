import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../models/beverage.dart';
import '../models/user.dart';
import '../models/promotion.dart';
import '../state/app_state.dart';
import '../widgets/vector_logo.dart';
import '../widgets/currency_formatter.dart';
import 'login_view.dart';

class AdminView extends StatefulWidget {
  const AdminView({super.key});

  @override
  State<AdminView> createState() => _AdminViewState();
}

class _AdminViewState extends State<AdminView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AppState _appState = AppState();

  // Role Permissions Tab Controllers & State
  final TextEditingController _searchEmailController = TextEditingController();
  bool _isSearching = false;
  bool _hasSearched = false;
  UserModel? _foundUser;
  bool _selectedIsAdminRole = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    _appState.addListener(_updateState);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchEmailController.dispose();
    _appState.removeListener(_updateState);
    super.dispose();
  }

  void _updateState() {
    if (mounted) setState(() {});
  }

  void _handleLogout() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginView()),
    );
  }

  void _performUserSearch() async {
    final searchEmail = _searchEmailController.text.trim();
    if (searchEmail.isEmpty) return;

    setState(() {
      _isSearching = true;
      _hasSearched = false;
      _foundUser = null;
    });

    final user = await _appState.findUserByEmail(searchEmail);

    if (!mounted) return;

    setState(() {
      _isSearching = false;
      _hasSearched = true;
      _foundUser = user;
      _selectedIsAdminRole = user?.isAdmin ?? false;
    });
  }

  void _saveRolePermission() async {
    if (_foundUser == null) return;

    final targetEmail = _foundUser!.email;
    final newRoleIsAdmin = _selectedIsAdminRole;

    await _appState.updateUserRole(targetEmail, newRoleIsAdmin);

    if (!mounted) return;

    setState(() {
      _foundUser!.isAdmin = newRoleIsAdmin;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Đã cập nhật phân quyền thành công cho $targetEmail!',
          style: GoogleFonts.beVietnamPro(),
        ),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const PhucLongLogo(size: 34),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppTheme.textLight),
            onPressed: _handleLogout,
            tooltip: 'Đăng xuất',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: AppTheme.textLight,
          indicatorColor: AppTheme.primaryColor,
          indicatorWeight: 3,
          isScrollable: false,
          labelPadding: EdgeInsets.zero,
          labelStyle: GoogleFonts.beVietnamPro(fontWeight: FontWeight.bold, fontSize: 11),
          tabs: const [
            Tab(icon: Icon(Icons.dashboard_outlined, size: 20), text: 'Thống Kê'),
            Tab(icon: Icon(Icons.receipt_long_outlined, size: 20), text: 'Đơn Hàng'),
            Tab(icon: Icon(Icons.local_drink_outlined, size: 20), text: 'Sản Phẩm'),
            Tab(icon: Icon(Icons.local_offer_outlined, size: 20), text: 'Khuyến Mãi'),
            Tab(icon: Icon(Icons.admin_panel_settings_outlined, size: 20), text: 'Phân Quyền'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        physics: const BouncingScrollPhysics(),
        children: [
          _buildDashboardTab(),
          _buildOrdersTab(),
          _buildProductsTab(),
          _buildPromotionsTab(),
          _buildPermissionsTab(),
        ],
      ),
      floatingActionButton: _tabController.index == 2
          ? FloatingActionButton(
              onPressed: _showAddProductDialog,
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              tooltip: 'Thêm sản phẩm mới',
              child: const Icon(Icons.add),
            )
          : _tabController.index == 3
              ? FloatingActionButton(
                  onPressed: _showAddPromotionDialog,
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  tooltip: 'Thêm mã khuyến mãi mới',
                  child: const Icon(Icons.add),
                )
              : null,
    );
  }

  // TAB 1: DASHBOARD & ANALYTICS
  Widget _buildDashboardTab() {
    final completedOrders = _appState.allOrdersForAdmin.where((o) => o.status == 'Đã hoàn thành').toList();
    final double totalRevenue = completedOrders.fold(0.0, (sum, o) => sum + o.total);
    final pendingOrdersCount = _appState.allOrdersForAdmin.where((o) => o.status == 'Chờ xử lý' || o.status == 'Đang xử lý' || o.status == 'Đang chuẩn bị').length;
    final totalProducts = _appState.allBeveragesForAdmin.length;
    final totalPromos = _appState.allPromotionsForAdmin.length;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tổng quan cửa hàng (Firebase Firestore)',
            style: GoogleFonts.beVietnamPro(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textDark),
          ),
          const SizedBox(height: 16),

          // Overview Stats Cards
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.4,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: [
              _buildStatCard(
                'Doanh thu (Đã Giao)',
                '${totalRevenue.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} đ',
                Icons.monetization_on_outlined,
                Colors.green,
              ),
              _buildStatCard(
                'Đơn hàng mới',
                '$pendingOrdersCount đơn',
                Icons.hourglass_empty_rounded,
                AppTheme.goldColor,
              ),
              _buildStatCard(
                'Tổng sản phẩm',
                '$totalProducts món',
                Icons.local_cafe_outlined,
                AppTheme.primaryColor,
              ),
              _buildStatCard(
                'Mã khuyến mãi',
                '$totalPromos mã',
                Icons.card_giftcard_rounded,
                Colors.deepOrangeAccent,
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Custom Sales Chart
          Text(
            'Doanh thu tuần này (nghìn đồng)',
            style: GoogleFonts.beVietnamPro(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.dividerColor),
            ),
            child: SizedBox(
              height: 200,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildBarChartColumn('Th 2', 450, 0.45),
                  _buildBarChartColumn('Th 3', 720, 0.72),
                  _buildBarChartColumn('Th 4', 600, 0.60),
                  _buildBarChartColumn('Th 5', 850, 0.85),
                  _buildBarChartColumn('Th 6', 950, 0.95),
                  _buildBarChartColumn('Th 7', 1200, 1.0),
                  _buildBarChartColumn('CN', 1100, 0.90),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Latest Active Orders
          Text(
            'Đơn hàng gần đây (Cloud Firestore)',
            style: GoogleFonts.beVietnamPro(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark),
          ),
          const SizedBox(height: 12),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _appState.orders.length > 3 ? 3 : _appState.orders.length,
            itemBuilder: (context, index) {
              final order = _appState.orders[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  title: Text(order.id, style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.bold)),
                  subtitle: Text('${order.customerName} • ${order.items.length} món', style: GoogleFonts.beVietnamPro(fontSize: 12)),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: order.status == 'Đã hoàn thành'
                          ? Colors.green.withOpacity(0.1)
                          : order.status == 'Hủy'
                              ? Colors.red.withOpacity(0.1)
                              : AppTheme.goldColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      order.status,
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: order.status == 'Đã hoàn thành'
                            ? Colors.green
                            : order.status == 'Hủy'
                                ? Colors.red
                                : AppTheme.goldColor,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String val, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.beVietnamPro(fontSize: 11, color: AppTheme.textLight, fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(icon, color: color, size: 20),
            ],
          ),
          Text(val, style: GoogleFonts.beVietnamPro(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
        ],
      ),
    );
  }

  Widget _buildBarChartColumn(String day, int val, double ratio) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text('$val', style: const TextStyle(fontSize: 9, color: AppTheme.textLight, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: ratio),
          duration: const Duration(milliseconds: 1000),
          curve: Curves.fastOutSlowIn,
          builder: (context, val, child) {
            return Container(
              width: 24,
              height: 120 * val,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primaryColor, Color(0xFF1EA85E)],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
                borderRadius: BorderRadius.circular(6),
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        Text(day, style: GoogleFonts.beVietnamPro(fontSize: 10, color: AppTheme.textDark, fontWeight: FontWeight.w500)),
      ],
    );
  }

  // TAB 2: ORDERS MANAGEMENT
  Widget _buildOrdersTab() {
    final orders = _appState.allOrdersForAdmin;
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.receipt_long_outlined, size: 64, color: AppTheme.textLight),
            const SizedBox(height: 12),
            Text('Chưa có đơn hàng nào trên Cloud Firestore.', style: GoogleFonts.beVietnamPro(color: AppTheme.textLight)),
          ],
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: ExpansionTile(
            title: Row(
              children: [
                Text(order.id, style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: order.status == 'Đã hoàn thành'
                        ? Colors.green.withOpacity(0.1)
                        : order.status == 'Hủy'
                            ? Colors.red.withOpacity(0.1)
                            : AppTheme.goldColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    order.status,
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: order.status == 'Đã hoàn thành'
                          ? Colors.green
                          : order.status == 'Hủy'
                              ? Colors.red
                              : AppTheme.goldColor,
                    ),
                  ),
                ),
              ],
            ),
            subtitle: Text(
              'Khách hàng: ${order.customerName} • ${order.total.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} đ',
              style: GoogleFonts.beVietnamPro(fontSize: 12, color: AppTheme.textLight),
            ),
            childrenPadding: const EdgeInsets.all(16),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Thông tin liên hệ:', style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text('SĐT: ${order.customerPhone}', style: GoogleFonts.beVietnamPro(fontSize: 13)),
                    Text('Địa chỉ: ${order.customerAddress}', style: GoogleFonts.beVietnamPro(fontSize: 13)),
                    if (order.promoCode.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text('Mã giảm giá đã dùng: ${order.promoCode} (-${order.discountAmount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} đ)',
                          style: GoogleFonts.beVietnamPro(fontSize: 13, color: Colors.deepOrangeAccent, fontWeight: FontWeight.w600)),
                    ],
                    const SizedBox(height: 12),
                    Text('Chi tiết sản phẩm:', style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    ...order.items.map((item) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('${item.quantity}x ${item.beverage.name} (${item.size})', style: GoogleFonts.beVietnamPro(fontSize: 13)),
                              Text(
                                '${item.totalPrice.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} đ',
                                style: GoogleFonts.beVietnamPro(fontSize: 13, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        )),
                    const Divider(height: 24, color: AppTheme.dividerColor),
                    
                    // Order status action triggers
                    Text('Cập nhật trạng thái đơn (Đẩy Firestore):', style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _buildStatusButton(order.id, 'Đang chuẩn bị', Colors.orangeAccent),
                        const SizedBox(width: 8),
                        _buildStatusButton(order.id, 'Đã hoàn thành', Colors.green),
                        const SizedBox(width: 8),
                        _buildStatusButton(order.id, 'Hủy', Colors.redAccent),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusButton(String orderId, String status, Color color) {
    return Expanded(
      child: ElevatedButton(
        onPressed: () {
          _appState.updateOrderStatus(orderId, status);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withOpacity(0.15),
          foregroundColor: color,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(vertical: 10),
        ),
        child: Text(
          status == 'Đang chuẩn bị' ? 'Chuẩn bị' : status == 'Đã hoàn thành' ? 'Hoàn thành' : 'Hủy đơn',
          style: GoogleFonts.beVietnamPro(fontSize: 11, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // TAB 3: PRODUCTS MANAGEMENT
  Widget _buildProductsTab() {
    final beverages = _appState.allBeveragesForAdmin;

    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: beverages.length,
      separatorBuilder: (context, index) => const Divider(color: AppTheme.dividerColor, height: 24),
      itemBuilder: (context, index) {
        final beverage = beverages[index];
        return Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                beverage.imageUrl,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 60,
                  height: 60,
                  color: AppTheme.primaryColor.withOpacity(0.05),
                  child: const Icon(Icons.coffee_rounded, color: AppTheme.primaryColor),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 6,
                    runSpacing: 2,
                    children: [
                      Text(
                        beverage.name,
                        style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textDark),
                      ),
                      if (beverage.isPopular)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.deepOrangeAccent.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.deepOrangeAccent.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.local_fire_department_rounded, color: Colors.deepOrangeAccent, size: 12),
                              const SizedBox(width: 2),
                              Text(
                                'Bán chạy',
                                style: GoogleFonts.beVietnamPro(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.deepOrangeAccent),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  Text(
                    '${beverage.price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} đ',
                    style: GoogleFonts.beVietnamPro(color: AppTheme.primaryColor, fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  Text(
                    beverage.isAvailable ? 'Đang kinh doanh' : 'Tạm dừng bán',
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 11,
                      color: beverage.isAvailable ? Colors.green : Colors.redAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            
            // Availability Switch
            Switch(
              value: beverage.isAvailable,
              activeColor: AppTheme.primaryColor,
              onChanged: (val) {
                _appState.toggleAvailability(beverage.id);
              },
            ),

            // Edit button
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: AppTheme.textLight),
              onPressed: () => _showEditProductDialog(beverage),
            ),

            // Delete button
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
              onPressed: () {
                _appState.deleteBeverage(beverage.id);
              },
            ),
          ],
        );
      },
    );
  }

  // TAB 4: PROMOTIONS MANAGEMENT
  Widget _buildPromotionsTab() {
    final promos = _appState.allPromotionsForAdmin;

    if (promos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.local_offer_outlined, size: 64, color: AppTheme.textLight),
            const SizedBox(height: 12),
            Text('Chưa có mã khuyến mãi nào trên Cloud Firestore.', style: GoogleFonts.beVietnamPro(color: AppTheme.textLight)),
          ],
        ),
      );
    }

    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: promos.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final promo = promos[index];
        final discountStr = promo.discountType == 'percent'
            ? '${promo.discountValue.toStringAsFixed(0)}%'
            : '${promo.discountValue.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} đ';

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppTheme.dividerColor),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.goldColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.confirmation_number_outlined, color: AppTheme.goldColor, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              promo.code,
                              style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.primaryColor),
                            ),
                          ),
                          Text(
                            'Giảm $discountStr',
                            style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.deepOrangeAccent),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        promo.title,
                        style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textDark),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        promo.description,
                        style: GoogleFonts.beVietnamPro(fontSize: 12, color: AppTheme.textLight),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),

                // Action Buttons Group
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Transform.scale(
                      scale: 0.8,
                      child: Switch(
                        value: promo.isAvailable,
                        activeColor: AppTheme.primaryColor,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        onChanged: (val) {
                          _appState.togglePromotionAvailability(promo.id);
                        },
                      ),
                    ),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                      icon: const Icon(Icons.edit_outlined, color: AppTheme.textLight, size: 18),
                      onPressed: () => _showEditPromotionDialog(promo),
                      tooltip: 'Sửa',
                    ),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                      onPressed: () {
                        _appState.deletePromotion(promo.id);
                      },
                      tooltip: 'Xóa',
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // TAB 5: ROLE PERMISSIONS MANAGEMENT (ADMIN TAB)
  Widget _buildPermissionsTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Phân Quyền Tài Khoản',
            style: GoogleFonts.beVietnamPro(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textDark),
          ),
          const SizedBox(height: 6),
          Text(
            'Nhập địa chỉ email tài khoản để tìm kiếm và tùy chỉnh quyền sử dụng.',
            style: GoogleFonts.beVietnamPro(fontSize: 13, color: AppTheme.textLight),
          ),
          const SizedBox(height: 20),

          // Search Box Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.dividerColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchEmailController,
                    keyboardType: TextInputType.emailAddress,
                    style: GoogleFonts.beVietnamPro(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Nhập email (ví dụ: user@gmail.com)',
                      hintStyle: GoogleFonts.beVietnamPro(fontSize: 13, color: AppTheme.textLight),
                      prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.primaryColor),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppTheme.dividerColor),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    ),
                    onSubmitted: (val) => _performUserSearch(),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isSearching ? null : _performUserSearch,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: _isSearching
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                        )
                      : Text('Tìm kiếm', style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Search Results
          if (!_hasSearched)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40.0),
                child: Column(
                  children: [
                    Icon(Icons.manage_accounts_outlined, size: 64, color: AppTheme.textLight.withOpacity(0.4)),
                    const SizedBox(height: 12),
                    Text(
                      'Nhập email và bấm Tìm kiếm để phân quyền tài khoản',
                      style: GoogleFonts.beVietnamPro(color: AppTheme.textLight, fontSize: 13),
                    ),
                  ],
                ),
              ),
            )
          else if (_foundUser == null)
            Container(
              padding: const EdgeInsets.all(20),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.04),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.red.withOpacity(0.2)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.error_outline_rounded, size: 40, color: Colors.redAccent),
                  const SizedBox(height: 10),
                  Text(
                    'Không tìm thấy tài khoản',
                    style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.redAccent),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Không có tài khoản nào khớp với email "${_searchEmailController.text.trim()}".',
                    style: GoogleFonts.beVietnamPro(fontSize: 13, color: AppTheme.textLight),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: AppTheme.dividerColor),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: const BoxDecoration(
                            color: AppTheme.primaryColor,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              _foundUser!.name.isNotEmpty ? _foundUser!.name.substring(0, 1).toUpperCase() : 'U',
                              style: GoogleFonts.beVietnamPro(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.goldColor,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _foundUser!.name,
                                style: GoogleFonts.beVietnamPro(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _foundUser!.email,
                                style: GoogleFonts.beVietnamPro(fontSize: 13, color: AppTheme.textLight),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _foundUser!.isAdmin ? AppTheme.goldColor.withOpacity(0.12) : AppTheme.primaryColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _foundUser!.isAdmin ? 'Admin' : 'User',
                            style: GoogleFonts.beVietnamPro(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _foundUser!.isAdmin ? AppTheme.goldColor : AppTheme.primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const Divider(height: 32, color: AppTheme.dividerColor),

                    Text(
                      'Tùy chọn phân quyền:',
                      style: GoogleFonts.beVietnamPro(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                    ),
                    const SizedBox(height: 12),

                    RadioListTile<bool>(
                      value: false,
                      groupValue: _selectedIsAdminRole,
                      activeColor: AppTheme.primaryColor,
                      title: Text('Khách hàng (User)', style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w600, fontSize: 14)),
                      subtitle: Text('Chỉ có quyền xem thực đơn, đặt hàng và xem hồ sơ cá nhân.', style: GoogleFonts.beVietnamPro(fontSize: 12, color: AppTheme.textLight)),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedIsAdminRole = val;
                          });
                        }
                      },
                    ),

                    RadioListTile<bool>(
                      value: true,
                      groupValue: _selectedIsAdminRole,
                      activeColor: AppTheme.primaryColor,
                      title: Text('Quản trị viên (Admin)', style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.primaryColor)),
                      subtitle: Text('Toàn quyền truy cập quản lý sản phẩm, đơn hàng, khuyến mãi, thống kê và phân quyền.', style: GoogleFonts.beVietnamPro(fontSize: 12, color: AppTheme.textLight)),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedIsAdminRole = val;
                          });
                        }
                      },
                    ),

                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _saveRolePermission,
                        icon: const Icon(Icons.check_circle_outline_rounded, size: 20),
                        label: Text('Lưu Phân Quyền', style: GoogleFonts.beVietnamPro(fontSize: 15, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Dialog to Edit Product details
  void _showEditProductDialog(Beverage beverage) {
    final nameController = TextEditingController(text: beverage.name);
    final priceController = TextEditingController(text: CurrencyInputFormatter.format(beverage.price));
    final descController = TextEditingController(text: beverage.description);
    bool isPopular = beverage.isPopular;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Sửa sản phẩm', style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Tên sản phẩm'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [CurrencyInputFormatter()],
                  decoration: const InputDecoration(
                    labelText: 'Giá bán',
                    suffixText: 'đ',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  keyboardType: TextInputType.multiline,
                  minLines: 3,
                  maxLines: null,
                  decoration: const InputDecoration(
                    labelText: 'Mô tả chi tiết',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Row(
                    children: [
                      Text('Sản phẩm Bán chạy', style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w600, fontSize: 14)),
                      const SizedBox(width: 4),
                      const Icon(Icons.local_fire_department_rounded, color: Colors.deepOrangeAccent, size: 18),
                    ],
                  ),
                  subtitle: Text('Hiển thị nhãn Bán Chạy / Nổi Bật cho khách hàng', style: GoogleFonts.beVietnamPro(fontSize: 12, color: AppTheme.textLight)),
                  value: isPopular,
                  activeColor: Colors.deepOrangeAccent,
                  onChanged: (val) {
                    setDialogState(() {
                      isPopular = val;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Hủy', style: GoogleFonts.beVietnamPro(color: AppTheme.textLight)),
            ),
            TextButton(
              onPressed: () {
                final newPrice = CurrencyInputFormatter.parse(priceController.text, defaultValue: beverage.price);
                final updated = beverage.copyWith(
                  name: nameController.text.trim(),
                  price: newPrice,
                  description: descController.text.trim(),
                  isPopular: isPopular,
                );
                _appState.updateBeverage(updated);
                Navigator.pop(context);
              },
              child: Text('Cập nhật', style: GoogleFonts.beVietnamPro(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  // Dialog to Add New Product
  void _showAddProductDialog() {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final descController = TextEditingController();
    BeverageCategory category = BeverageCategory.tea;
    bool isPopular = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Thêm thức uống mới', style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Tên thức uống'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [CurrencyInputFormatter()],
                  decoration: const InputDecoration(
                    labelText: 'Giá bán',
                    hintText: 'Ví dụ: 55.000',
                    suffixText: 'đ',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<BeverageCategory>(
                  value: category,
                  decoration: const InputDecoration(labelText: 'Phân loại'),
                  items: const [
                    DropdownMenuItem(value: BeverageCategory.tea, child: Text('Trà nguyên bản')),
                    DropdownMenuItem(value: BeverageCategory.milkTea, child: Text('Trà sữa')),
                    DropdownMenuItem(value: BeverageCategory.coffee, child: Text('Cà phê')),
                    DropdownMenuItem(value: BeverageCategory.special, child: Text('Đặc biệt')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setDialogState(() {
                        category = val;
                      });
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  keyboardType: TextInputType.multiline,
                  minLines: 3,
                  maxLines: null,
                  decoration: const InputDecoration(
                    labelText: 'Mô tả thành phần',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Row(
                    children: [
                      Text('Sản phẩm Bán chạy', style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w600, fontSize: 14)),
                      const SizedBox(width: 4),
                      const Icon(Icons.local_fire_department_rounded, color: Colors.deepOrangeAccent, size: 18),
                    ],
                  ),
                  subtitle: Text('Hiển thị nhãn Bán Chạy / Nổi Bật cho khách hàng', style: GoogleFonts.beVietnamPro(fontSize: 12, color: AppTheme.textLight)),
                  value: isPopular,
                  activeColor: Colors.deepOrangeAccent,
                  onChanged: (val) {
                    setDialogState(() {
                      isPopular = val;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Hủy', style: GoogleFonts.beVietnamPro(color: AppTheme.textLight)),
            ),
            TextButton(
              onPressed: () {
                if (nameController.text.trim().isEmpty || priceController.text.trim().isEmpty) return;

                final price = CurrencyInputFormatter.parse(priceController.text, defaultValue: 50000);
                final newBeverage = Beverage(
                  id: 'PL-${DateTime.now().millisecondsSinceEpoch}',
                  name: nameController.text.trim(),
                  category: category,
                  price: price,
                  imageUrl: 'https://images.unsplash.com/photo-1541658016709-82535e94bc69?w=500&auto=format&fit=crop&q=60&ixlib=rb-4.0.3',
                  description: descController.text.trim().isNotEmpty
                      ? descController.text.trim()
                      : 'Thức uống Phúc Long đặc trưng thơm ngon mát lạnh.',
                  rating: 5.0,
                  isPopular: isPopular,
                );

                _appState.addBeverage(newBeverage);
                Navigator.pop(context);

                setState(() {});
              },
              child: Text('Thêm mới', style: GoogleFonts.beVietnamPro(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  // Dialog to Add New Promotion
  void _showAddPromotionDialog() {
    final codeController = TextEditingController();
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final discountValController = TextEditingController();
    final minPriceController = TextEditingController();
    String discountType = 'percent';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Thêm mã khuyến mãi', style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: codeController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(labelText: 'Mã Voucher'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Tiêu đề khuyến mãi'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: discountType,
                  decoration: const InputDecoration(labelText: 'Loại giảm giá'),
                  items: const [
                    DropdownMenuItem(value: 'percent', child: Text('Theo phần trăm')),
                    DropdownMenuItem(value: 'amount', child: Text('Theo số tiền cụ thể')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setDialogState(() {
                        discountType = val;
                        discountValController.clear();
                      });
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: discountValController,
                  keyboardType: TextInputType.number,
                  inputFormatters: discountType == 'amount' ? [CurrencyInputFormatter()] : [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: discountType == 'percent' ? 'Mức giảm phần trăm' : 'Mức giảm tiền mặt',
                    suffixText: discountType == 'percent' ? '%' : 'đ',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: minPriceController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [CurrencyInputFormatter()],
                  decoration: const InputDecoration(
                    labelText: 'Giá trị đơn tối thiểu',
                    suffixText: 'đ',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  keyboardType: TextInputType.multiline,
                  minLines: 3,
                  maxLines: null,
                  decoration: const InputDecoration(
                    labelText: 'Mô tả chi tiết điều kiện',
                    alignLabelWithHint: true,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Hủy', style: GoogleFonts.beVietnamPro(color: AppTheme.textLight)),
            ),
            TextButton(
              onPressed: () {
                final code = codeController.text.trim().toUpperCase();
                final title = titleController.text.trim();
                final val = CurrencyInputFormatter.parse(discountValController.text);
                final minP = CurrencyInputFormatter.parse(minPriceController.text);

                if (code.isEmpty || title.isEmpty || val <= 0) return;

                final newPromo = Promotion(
                  id: 'PROMO-${DateTime.now().millisecondsSinceEpoch}',
                  code: code,
                  title: title,
                  description: descController.text.trim(),
                  discountType: discountType,
                  discountValue: val,
                  minOrderPrice: minP,
                  isAvailable: true,
                );

                _appState.addPromotion(newPromo);
                Navigator.pop(context);
                setState(() {});
              },
              child: Text('Lưu Mã', style: GoogleFonts.beVietnamPro(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  // Dialog to Edit Promotion
  void _showEditPromotionDialog(Promotion promo) {
    final titleController = TextEditingController(text: promo.title);
    final descController = TextEditingController(text: promo.description);
    final discountValController = TextEditingController(
      text: promo.discountType == 'amount' ? CurrencyInputFormatter.format(promo.discountValue) : promo.discountValue.toStringAsFixed(0),
    );
    final minPriceController = TextEditingController(text: CurrencyInputFormatter.format(promo.minOrderPrice));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Sửa mã ${promo.code}', style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Tiêu đề khuyến mãi'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: discountValController,
                keyboardType: TextInputType.number,
                inputFormatters: promo.discountType == 'amount' ? [CurrencyInputFormatter()] : [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: promo.discountType == 'percent' ? 'Mức giảm phần trăm' : 'Mức giảm tiền mặt',
                  suffixText: promo.discountType == 'percent' ? '%' : 'đ',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: minPriceController,
                keyboardType: TextInputType.number,
                inputFormatters: [CurrencyInputFormatter()],
                decoration: const InputDecoration(
                  labelText: 'Giá trị đơn tối thiểu',
                  suffixText: 'đ',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                keyboardType: TextInputType.multiline,
                minLines: 3,
                maxLines: null,
                decoration: const InputDecoration(
                  labelText: 'Mô tả chi tiết',
                  alignLabelWithHint: true,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Hủy', style: GoogleFonts.beVietnamPro(color: AppTheme.textLight)),
          ),
          TextButton(
            onPressed: () {
              final val = CurrencyInputFormatter.parse(discountValController.text, defaultValue: promo.discountValue);
              final minP = CurrencyInputFormatter.parse(minPriceController.text, defaultValue: promo.minOrderPrice);
              final updated = promo.copyWith(
                title: titleController.text.trim(),
                description: descController.text.trim(),
                discountValue: val,
                minOrderPrice: minP,
              );
              _appState.updatePromotion(updated);
              Navigator.pop(context);
            },
            child: Text('Cập nhật', style: GoogleFonts.beVietnamPro(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
