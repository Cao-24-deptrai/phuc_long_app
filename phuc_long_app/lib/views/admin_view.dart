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
import 'main_page.dart';

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
  String _revenueTimeframe = 'day'; // 'day', 'month', 'year'
  DateTimeRange _selectedDateRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 6)),
    end: DateTime.now(),
  );

  Future<void> _pickCustomDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: _selectedDateRange,
      firstDate: DateTime(2023),
      lastDate: DateTime(2030),
      helpText: 'CHỌN KHOẢNG NGÀY THỐNG KÊ (TỐI ĐA 7 NGÀY)',
      saveText: 'ÁP DỤNG',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.white,
              onSurface: AppTheme.textDark,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final daysDiff = picked.end.difference(picked.start).inDays + 1;
      if (daysDiff > 7) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚠️ Khoảng ngày thống kê tối đa là 7 ngày! Đã tự chọn 7 ngày tính từ ${picked.start.day}/${picked.start.month}.', style: GoogleFonts.beVietnamPro()),
            backgroundColor: Colors.deepOrangeAccent,
          ),
        );
        setState(() {
          _selectedDateRange = DateTimeRange(
            start: picked.start,
            end: picked.start.add(const Duration(days: 6)),
          );
        });
      } else {
        setState(() {
          _selectedDateRange = picked;
        });
      }
    }
  }

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

  void _toggleUserLock() async {
    if (_foundUser == null) return;
    final targetEmail = _foundUser!.email;
    final isLockedNow = _foundUser!.isLocked;
    final actionText = isLockedNow ? 'MỞ KHÓA' : 'KHÓA';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Xác nhận $actionText tài khoản', style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.bold)),
        content: Text(
          isLockedNow
              ? 'Bạn có muốn mở khóa tài khoản "$targetEmail" để người dùng tiếp tục đăng nhập?'
              : 'Bạn có chắc chắn muốn KHÓA tài khoản "$targetEmail"? Người dùng này sẽ bị chặn đăng nhập vào ứng dụng.',
          style: GoogleFonts.beVietnamPro(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Hủy', style: GoogleFonts.beVietnamPro(color: AppTheme.textLight)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isLockedNow ? AppTheme.primaryColor : Colors.orangeAccent,
              foregroundColor: Colors.white,
            ),
            child: Text(actionText, style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _appState.toggleUserLock(targetEmail);
      if (!mounted) return;
      setState(() {
        _foundUser!.isLocked = !_foundUser!.isLocked;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Đã ${_foundUser!.isLocked ? "KHÓA" : "MỞ KHÓA"} tài khoản $targetEmail thành công!',
            style: GoogleFonts.beVietnamPro(),
          ),
          backgroundColor: _foundUser!.isLocked ? Colors.orangeAccent : AppTheme.primaryColor,
        ),
      );
    }
  }

  void _deleteUserAccount() async {
    if (_foundUser == null) return;
    final targetEmail = _foundUser!.email;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Xác nhận XÓA TÀI KHOẢN', style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.bold, color: Colors.redAccent)),
        content: Text(
          '⚠️ BẠN CÓ CHẮC CHẮN MUỐN XÓA VĨNH VIỄN TÀI KHOẢN "$targetEmail"? Hành động này không thể hoàn tác.',
          style: GoogleFonts.beVietnamPro(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Hủy', style: GoogleFonts.beVietnamPro(color: AppTheme.textLight)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            child: Text('XÓA VĨNH VIỄN', style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _appState.deleteUserAccount(targetEmail);
      if (!mounted) return;
      setState(() {
        _foundUser = null;
        _hasSearched = true;
        _searchEmailController.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Đã xóa tài khoản $targetEmail khỏi hệ thống!',
            style: GoogleFonts.beVietnamPro(),
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const PhucLongLogo(size: 34),
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.only(left: 6.0),
          child: IconButton(
            icon: const Icon(Icons.storefront_rounded, color: AppTheme.primaryColor, size: 24),
            tooltip: 'Chuyển sang giao diện Cửa Hàng (User)',
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const MainPage()),
              );
            },
          ),
        ),
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

          // Overview Stats Cards (Giữ nguyên)
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
          const SizedBox(height: 24),

          // 1. Interactive Bar Chart: Revenue by Day / Month / Year
          _buildRevenueChartSection(),

          const SizedBox(height: 24),

          // 2. Donut / Pie Chart: Order Status (Đang giao, Đã hủy, Đã giao)
          _buildOrderStatusPieChartSection(),

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

  Widget _buildRevenueChartSection() {
    final Map<String, double> dataMap = {};
    final orders = _appState.allOrdersForAdmin;

    final startStr = '${_selectedDateRange.start.day.toString().padLeft(2, '0')}/${_selectedDateRange.start.month.toString().padLeft(2, '0')}/${_selectedDateRange.start.year}';
    final endStr = '${_selectedDateRange.end.day.toString().padLeft(2, '0')}/${_selectedDateRange.end.month.toString().padLeft(2, '0')}/${_selectedDateRange.end.year}';

    if (_revenueTimeframe == 'day') {
      final start = _selectedDateRange.start;
      final end = _selectedDateRange.end;
      final daysCount = end.difference(start).inDays + 1;

      for (int i = 0; i < daysCount; i++) {
        final d = start.add(Duration(days: i));
        final key = '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
        dataMap[key] = 0.0;
      }

      for (var order in orders) {
        if (order.status == 'Đã hoàn thành') {
          final oDate = DateTime(order.date.year, order.date.month, order.date.day);
          final startDateOnly = DateTime(start.year, start.month, start.day);
          final endDateOnly = DateTime(end.year, end.month, end.day);
          if ((oDate.isAfter(startDateOnly) || oDate.isAtSameMomentAs(startDateOnly)) &&
              (oDate.isBefore(endDateOnly) || oDate.isAtSameMomentAs(endDateOnly))) {
            final key = '${oDate.day.toString().padLeft(2, '0')}/${oDate.month.toString().padLeft(2, '0')}';
            if (dataMap.containsKey(key)) {
              dataMap[key] = (dataMap[key] ?? 0.0) + order.total;
            }
          }
        }
      }
    } else if (_revenueTimeframe == 'month') {
      final List<String> months = ['T1', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'T8', 'T9', 'T10', 'T11', 'T12'];
      for (var m in months) {
        dataMap[m] = 0.0;
      }
      for (var order in orders) {
        if (order.status == 'Đã hoàn thành') {
          final mKey = 'T${order.date.month}';
          if (dataMap.containsKey(mKey)) {
            dataMap[mKey] = (dataMap[mKey] ?? 0.0) + order.total;
          }
        }
      }
    } else {
      final List<String> years = ['2024', '2025', '2026'];
      for (var y in years) {
        dataMap[y] = 0.0;
      }
      for (var order in orders) {
        if (order.status == 'Đã hoàn thành') {
          final yKey = '${order.date.year}';
          if (dataMap.containsKey(yKey)) {
            dataMap[yKey] = (dataMap[yKey] ?? 0.0) + order.total;
          }
        }
      }
    }

    final maxVal = dataMap.values.fold(0.0, (max, v) => v > max ? v : max);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Tab Folder Header (Nằm ngoài khung phía trên bên phải như hình thư mục)
        Align(
          alignment: Alignment.centerRight,
          child: Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              border: Border.all(color: AppTheme.dividerColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTimeframeChip('day', 'Ngày'),
                _buildTimeframeChip('month', 'Tháng'),
                _buildTimeframeChip('year', 'Năm'),
              ],
            ),
          ),
        ),

        // Khung Thống kê Doanh Thu (Thân thư mục)
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
              topRight: Radius.circular(4),
            ),
            border: Border.all(color: AppTheme.dividerColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Thống kê Doanh thu',
                style: GoogleFonts.beVietnamPro(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark),
              ),

              // Date Range Picker Chip (Format: dd/mm/yyyy - dd/mm/yyyy)
              if (_revenueTimeframe == 'day') ...[
                const SizedBox(height: 8),
                InkWell(
                  onTap: _pickCustomDateRange,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.calendar_today_rounded, size: 14, color: AppTheme.primaryColor),
                        const SizedBox(width: 8),
                        Text(
                          '$startStr - $endStr',
                          style: GoogleFonts.beVietnamPro(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.edit_calendar_rounded, size: 14, color: AppTheme.primaryColor),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),

          // Chart Display
          SizedBox(
            height: 210,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: dataMap.entries.map((entry) {
                  final ratio = maxVal > 0 ? entry.value / maxVal : 0.0;
                  final formattedVal = _formatShortValue(entry.value);

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          formattedVal,
                          style: GoogleFonts.beVietnamPro(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                        ),
                        const SizedBox(height: 6),
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: ratio),
                          duration: const Duration(milliseconds: 800),
                          curve: Curves.fastOutSlowIn,
                          builder: (context, val, child) {
                            return Container(
                              width: _revenueTimeframe == 'month' ? 20 : 32,
                              height: 140 * (val < 0.03 ? 0.03 : val),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: entry.value > 0
                                      ? [AppTheme.primaryColor, const Color(0xFF1EA85E)]
                                      : [Colors.grey.shade300, Colors.grey.shade400],
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                        Text(
                          entry.key,
                          style: GoogleFonts.beVietnamPro(fontSize: 11, color: AppTheme.textDark, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    ),
  ],
);
  }

  Widget _buildTimeframeChip(String type, String label) {
    final isSelected = _revenueTimeframe == type;
    return InkWell(
      onTap: () {
        setState(() {
          _revenueTimeframe = type;
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: GoogleFonts.beVietnamPro(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : AppTheme.textLight,
          ),
        ),
      ),
    );
  }

  String _formatShortValue(double val) {
    if (val <= 0) return '0đ';
    if (val >= 1000000000) {
      return '${(val / 1000000000).toStringAsFixed(1)}B';
    } else if (val >= 1000000) {
      return '${(val / 1000000).toStringAsFixed(1)}M';
    } else if (val >= 1000) {
      return '${(val / 1000).toStringAsFixed(0)}k';
    }
    return val.toStringAsFixed(0);
  }

  Widget _buildOrderStatusPieChartSection() {
    final orders = _appState.allOrdersForAdmin;
    int delivered = 0;
    int shipping = 0;
    int cancelled = 0;

    for (var o in orders) {
      if (o.status == 'Đã hoàn thành') {
        delivered++;
      } else if (o.status == 'Hủy') {
        cancelled++;
      } else {
        shipping++;
      }
    }

    final totalCount = delivered + shipping + cancelled;
    final delPercent = totalCount > 0 ? (delivered / totalCount * 100).toStringAsFixed(0) : '0';
    final shipPercent = totalCount > 0 ? (shipping / totalCount * 100).toStringAsFixed(0) : '0';
    final canPercent = totalCount > 0 ? (cancelled / totalCount * 100).toStringAsFixed(0) : '0';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Thống kê Đơn hàng theo Trạng thái',
            style: GoogleFonts.beVietnamPro(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark),
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              // Donut / Pie Chart Visual
              SizedBox(
                width: 130,
                height: 130,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(130, 130),
                      painter: PieChartPainter(
                        values: [delivered.toDouble(), shipping.toDouble(), cancelled.toDouble()],
                        colors: const [
                          AppTheme.primaryColor,
                          AppTheme.goldColor,
                          Colors.redAccent,
                        ],
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$totalCount',
                          style: GoogleFonts.beVietnamPro(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                        ),
                        Text(
                          'Đơn hàng',
                          style: GoogleFonts.beVietnamPro(fontSize: 10, color: AppTheme.textLight, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),

              // Legend and Details
              Expanded(
                child: Column(
                  children: [
                    _buildPieLegendItem('Đã giao', '$delivered đơn ($delPercent%)', AppTheme.primaryColor),
                    const SizedBox(height: 10),
                    _buildPieLegendItem('Đang xử lý', '$shipping đơn ($shipPercent%)', AppTheme.goldColor),
                    const SizedBox(height: 10),
                    _buildPieLegendItem('Đã hủy', '$cancelled đơn ($canPercent%)', Colors.redAccent),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPieLegendItem(String label, String detail, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.beVietnamPro(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textDark),
              ),
              Text(
                detail,
                style: GoogleFonts.beVietnamPro(fontSize: 11, color: AppTheme.textLight),
              ),
            ],
          ),
        ),
      ],
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
                        Builder(
                          builder: (context) {
                            final liveUser = _appState.users[_foundUser!.email.toLowerCase()] ?? _foundUser!;
                            final avatarUrl = liveUser.avatarUrl.trim();
                            final fallbackWidget = Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: _foundUser!.isLocked ? Colors.redAccent : AppTheme.primaryColor,
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
                            );

                            if (avatarUrl.isNotEmpty) {
                              return ClipOval(
                                child: Image.network(
                                  avatarUrl,
                                  headers: const {'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'},
                                  width: 56,
                                  height: 56,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => fallbackWidget,
                                ),
                              );
                            }
                            return fallbackWidget;
                          },
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
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
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
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: _foundUser!.isLocked ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: _foundUser!.isLocked ? Colors.red.withOpacity(0.3) : Colors.green.withOpacity(0.3)),
                              ),
                              child: Text(
                                _foundUser!.isLocked ? '🔒 Đã bị khóa' : '✅ Hoạt động',
                                style: GoogleFonts.beVietnamPro(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: _foundUser!.isLocked ? Colors.redAccent : Colors.green,
                                ),
                              ),
                            ),
                          ],
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

                    const SizedBox(height: 16),

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

                    const Divider(height: 32, color: AppTheme.dividerColor),

                    Text(
                      'Tùy chọn quản lý trạng thái & tài khoản:',
                      style: GoogleFonts.beVietnamPro(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _toggleUserLock,
                            icon: Icon(
                              _foundUser!.isLocked ? Icons.lock_open_rounded : Icons.lock_outline_rounded,
                              size: 18,
                              color: _foundUser!.isLocked ? Colors.green : Colors.orangeAccent,
                            ),
                            label: Text(
                              _foundUser!.isLocked ? 'Mở Khóa' : 'Khóa Tài Khoản',
                              style: GoogleFonts.beVietnamPro(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: _foundUser!.isLocked ? Colors.green : Colors.orangeAccent,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              side: BorderSide(color: _foundUser!.isLocked ? Colors.green : Colors.orangeAccent),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _deleteUserAccount,
                            icon: const Icon(Icons.delete_forever_rounded, size: 18, color: Colors.redAccent),
                            label: Text(
                              'Xóa Tài Khoản',
                              style: GoogleFonts.beVietnamPro(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.redAccent,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              side: const BorderSide(color: Colors.redAccent),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
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
    final imageUrlController = TextEditingController(text: beverage.imageUrl);
    bool isPopular = beverage.isPopular;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Sửa sản phẩm', style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
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
                  controller: imageUrlController,
                  decoration: InputDecoration(
                    labelText: 'Link hình ảnh (URL)',
                    hintText: 'https://images.unsplash.com/...',
                    prefixIcon: const Icon(Icons.image_outlined, color: AppTheme.primaryColor),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.content_paste_rounded, color: AppTheme.primaryColor),
                      tooltip: 'Dán link ảnh từ bộ nhớ tạm',
                      onPressed: () async {
                        final data = await Clipboard.getData(Clipboard.kTextPlain);
                        if (data != null && data.text != null) {
                          setDialogState(() {
                            imageUrlController.text = data.text!.trim();
                          });
                        }
                      },
                    ),
                  ),
                  onChanged: (val) => setDialogState(() {}),
                ),
                if (imageUrlController.text.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    height: 90,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.dividerColor),
                    ),
                    child: Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          imageUrlController.text.trim(),
                          headers: const {'User-Agent': 'Mozilla/5.0'},
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.broken_image_outlined, color: Colors.redAccent, size: 24),
                              const SizedBox(height: 2),
                              Text('Link ảnh không hợp lệ', style: GoogleFonts.beVietnamPro(fontSize: 10, color: Colors.redAccent)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
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
                  imageUrl: imageUrlController.text.trim().isNotEmpty ? imageUrlController.text.trim() : beverage.imageUrl,
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
    final imageUrlController = TextEditingController(
      text: 'https://images.unsplash.com/photo-1541658016709-82535e94bc69?w=500&auto=format&fit=crop&q=60',
    );
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
                  controller: imageUrlController,
                  decoration: InputDecoration(
                    labelText: 'Link hình ảnh (URL)',
                    hintText: 'https://images.unsplash.com/...',
                    prefixIcon: const Icon(Icons.image_outlined, color: AppTheme.primaryColor),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.content_paste_rounded, color: AppTheme.primaryColor),
                      tooltip: 'Dán link ảnh từ bộ nhớ tạm',
                      onPressed: () async {
                        final data = await Clipboard.getData(Clipboard.kTextPlain);
                        if (data != null && data.text != null) {
                          setDialogState(() {
                            imageUrlController.text = data.text!.trim();
                          });
                        }
                      },
                    ),
                  ),
                  onChanged: (val) => setDialogState(() {}),
                ),
                if (imageUrlController.text.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    height: 90,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.dividerColor),
                    ),
                    child: Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          imageUrlController.text.trim(),
                          headers: const {'User-Agent': 'Mozilla/5.0'},
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.broken_image_outlined, color: Colors.redAccent, size: 24),
                              const SizedBox(height: 2),
                              Text('Link ảnh không hợp lệ', style: GoogleFonts.beVietnamPro(fontSize: 10, color: Colors.redAccent)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
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
                final imgUrl = imageUrlController.text.trim().isNotEmpty
                    ? imageUrlController.text.trim()
                    : 'https://images.unsplash.com/photo-1541658016709-82535e94bc69?w=500&auto=format&fit=crop&q=60';

                final newBeverage = Beverage(
                  id: 'PL-${DateTime.now().millisecondsSinceEpoch}',
                  name: nameController.text.trim(),
                  category: category,
                  price: price,
                  imageUrl: imgUrl,
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

class PieChartPainter extends CustomPainter {
  final List<double> values;
  final List<Color> colors;

  PieChartPainter({required this.values, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final total = values.fold(0.0, (sum, v) => sum + v);
    if (total == 0) {
      final paint = Paint()
        ..color = Colors.grey.shade200
        ..style = PaintingStyle.stroke
        ..strokeWidth = 18.0;
      canvas.drawCircle(Offset(size.width / 2, size.height / 2), size.width / 2 - 12, paint);
      return;
    }

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;
    double startAngle = -3.14159 / 2; // -90 deg

    for (int i = 0; i < values.length; i++) {
      if (values[i] <= 0) continue;
      final sweepAngle = (values[i] / total) * 2 * 3.14159;
      final paint = Paint()
        ..color = colors[i]
        ..style = PaintingStyle.stroke
        ..strokeWidth = 18.0
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle + 0.05,
        sweepAngle - 0.1,
        false,
        paint,
      );
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant PieChartPainter oldDelegate) => true;
}
