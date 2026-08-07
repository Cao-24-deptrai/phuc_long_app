import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../state/app_state.dart';

class OrdersView extends StatefulWidget {
  const OrdersView({super.key});

  @override
  State<OrdersView> createState() => _OrdersViewState();
}

class _OrdersViewState extends State<OrdersView> {
  final AppState _appState = AppState();

  @override
  void initState() {
    super.initState();
    _appState.addListener(_updateState);
  }

  @override
  void dispose() {
    _appState.removeListener(_updateState);
    super.dispose();
  }

  void _updateState() {
    if (mounted) {
      setState(() {});
    }
  }

  void _confirmCancelOrder(String orderId) {
    final List<String> reasonOptions = [
      'Đổi ý không muốn mua nữa',
      'Muốn chọn món nước / size khác',
      'Muốn thay đổi địa chỉ nhận hàng',
      'Thời gian chờ giao hàng quá lâu',
      'Đặt trùng đơn hàng',
      'Nhập sai mã giảm giá / ưu đãi',
    ];

    final Set<String> selectedReasons = {};

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final bool canSubmit = selectedReasons.isNotEmpty;

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Xác nhận Hủy Đơn',
                  style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.bold, color: Colors.redAccent, fontSize: 18),
                ),
                const SizedBox(height: 4),
                Text(
                  'Vui lòng chọn ít nhất 1 lý do hủy đơn:',
                  style: GoogleFonts.beVietnamPro(fontSize: 12, color: AppTheme.textLight, fontWeight: FontWeight.normal),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: reasonOptions.map((reason) {
                  final isChecked = selectedReasons.contains(reason);
                  return CheckboxListTile(
                    value: isChecked,
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    activeColor: Colors.redAccent,
                    title: Text(
                      reason,
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 13,
                        color: isChecked ? AppTheme.textDark : AppTheme.textLight,
                        fontWeight: isChecked ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                    onChanged: (val) {
                      setDialogState(() {
                        if (val == true) {
                          selectedReasons.add(reason);
                        } else {
                          selectedReasons.remove(reason);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Quay lại', style: GoogleFonts.beVietnamPro(color: AppTheme.textLight)),
              ),
              ElevatedButton(
                onPressed: canSubmit
                    ? () async {
                        final reasonString = selectedReasons.join('; ');
                        await _appState.updateOrderStatus(orderId, 'Đã hủy', cancelReason: reasonString);
                        if (!mounted) return;
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Đã hủy đơn hàng #$orderId thành công!', style: GoogleFonts.beVietnamPro()),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  disabledBackgroundColor: Colors.grey.shade300,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(
                  'Hủy Đơn',
                  style: GoogleFonts.beVietnamPro(
                    fontWeight: FontWeight.bold,
                    color: canSubmit ? Colors.white : Colors.grey.shade600,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userOrders = _appState.orders;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Đơn Hàng Của Tôi',
          style: GoogleFonts.beVietnamPro(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 18,
          ),
        ),
      ),
      body: userOrders.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.receipt_long_rounded,
                        size: 50,
                        color: AppTheme.primaryColor.withOpacity(0.5),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Chưa có đơn hàng nào',
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Hãy đặt món nước yêu thích của bạn từ cửa hàng nhé!',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 14,
                        color: AppTheme.textLight,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16.0),
              itemCount: userOrders.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final order = userOrders[index];
                final formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(order.date);
                final isCompleted = order.status == 'Đã hoàn thành';
                final isCancelled = order.status == 'Đã hủy';
                final canCancel = !isCompleted && !isCancelled;

                Color statusColor = isCompleted
                    ? Colors.green
                    : isCancelled
                        ? Colors.redAccent
                        : AppTheme.goldColor;

                return Card(
                  margin: EdgeInsets.zero,
                  elevation: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Đơn hàng: #${order.id}',
                              style: GoogleFonts.beVietnamPro(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textDark,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: statusColor.withOpacity(0.3)),
                              ),
                              child: Text(
                                order.status,
                                style: GoogleFonts.beVietnamPro(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: statusColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          formattedDate,
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 12,
                            color: AppTheme.textLight,
                          ),
                        ),
                        const Divider(height: 16, color: AppTheme.dividerColor),
                        // List items summary
                        ...order.items.map((item) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    '${item.beverage.name} (x${item.quantity}) [Size ${item.size}]',
                                    style: GoogleFonts.beVietnamPro(fontSize: 13),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  NumberFormat.currency(locale: 'vi_VN', symbol: 'đ')
                                      .format(item.totalPrice),
                                  style: GoogleFonts.beVietnamPro(
                                      fontSize: 13, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          );
                        }),
                        const Divider(height: 16, color: AppTheme.dividerColor),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Tổng thanh toán',
                              style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              NumberFormat.currency(locale: 'vi_VN', symbol: 'đ')
                                  .format(order.total),
                              style: GoogleFonts.beVietnamPro(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ],
                        ),
                         if (isCancelled && order.cancelReason.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.red.withOpacity(0.2)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.info_outline_rounded, size: 16, color: Colors.redAccent),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Lý do hủy: ${order.cancelReason}',
                                    style: GoogleFonts.beVietnamPro(fontSize: 12, color: Colors.redAccent),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        if (canCancel) ...[
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () => _confirmCancelOrder(order.id),
                              icon: const Icon(Icons.cancel_outlined, size: 16, color: Colors.redAccent),
                              label: Text(
                                'Hủy Đơn Hàng',
                                style: GoogleFonts.beVietnamPro(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.redAccent,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.redAccent),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

