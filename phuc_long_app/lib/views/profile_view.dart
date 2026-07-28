import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../state/app_state.dart';
import 'change_pass_view.dart';
import 'login_view.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  final AppState _appState = AppState();
  
  bool _isEditing = false;
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;

  @override
  void initState() {
    super.initState();
    final user = _appState.currentUser;
    _nameController = TextEditingController(text: user?.name ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
    _addressController = TextEditingController(text: user?.address ?? '');
    _appState.addListener(_updateState);
  }

  @override
  void dispose() {
    _appState.removeListener(_updateState);
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _updateState() {
    if (mounted && !_isEditing) {
      final user = _appState.currentUser;
      setState(() {
        _nameController.text = user?.name ?? '';
        _phoneController.text = user?.phone ?? '';
        _addressController.text = user?.address ?? '';
      });
    }
  }

  void _saveProfile() {
    if (!_formKey.currentState!.validate()) return;
    
    _appState.updateProfile(
      _nameController.text.trim(),
      _phoneController.text.trim(),
      _addressController.text.trim(),
    );

    setState(() {
      _isEditing = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã cập nhật thông tin cá nhân thành công!', style: GoogleFonts.beVietnamPro()),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Đăng xuất', style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.bold)),
        content: Text('Bạn có chắc chắn muốn đăng xuất khỏi ứng dụng?', style: GoogleFonts.beVietnamPro()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Hủy', style: GoogleFonts.beVietnamPro(color: AppTheme.textLight)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Pop dialog
              _appState.logout();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginView()),
                (route) => false,
              );
            },
            child: Text('Đồng ý', style: GoogleFonts.beVietnamPro(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _appState.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Vui lòng đăng nhập')),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: CustomScrollView(
        slivers: [
          // Header banner color
          SliverAppBar(
            expandedHeight: 180,
            floating: false,
            pinned: true,
            backgroundColor: AppTheme.primaryColor,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: AppTheme.primaryColor,
                child: Stack(
                  children: [
                    Positioned(
                      top: -50,
                      right: -50,
                      child: Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.04),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -20,
                      left: -20,
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.03),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(_isEditing ? Icons.close_rounded : Icons.edit_rounded, color: Colors.white),
                onPressed: () {
                  setState(() {
                    if (_isEditing) {
                      // Cancel editing, restore initial values
                      _nameController.text = user.name;
                      _phoneController.text = user.phone;
                      _addressController.text = user.address;
                    }
                    _isEditing = !_isEditing;
                  });
                },
                tooltip: _isEditing ? 'Hủy chỉnh sửa' : 'Chỉnh sửa hồ sơ',
              ),
              IconButton(
                icon: const Icon(Icons.logout_rounded, color: Colors.white),
                onPressed: _handleLogout,
                tooltip: 'Đăng xuất',
              ),
            ],
          ),

          // Profile content body
          SliverToBoxAdapter(
            child: Transform.translate(
              offset: const Offset(0, -60),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Avatar representation
                      Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(5),
                        child: Container(
                          decoration: const BoxDecoration(
                            color: AppTheme.primaryColor,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              user.name.isNotEmpty ? user.name.substring(0, 1).toUpperCase() : 'U',
                              style: GoogleFonts.beVietnamPro(
                                fontSize: 42,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.goldColor,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // User Basic Info
                      Text(
                        user.name,
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.email,
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 14,
                          color: AppTheme.textLight,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Profile Details Card
                      Card(
                        margin: EdgeInsets.zero,
                        elevation: 0,
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Thông Tin Cá Nhân',
                                style: GoogleFonts.beVietnamPro(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                              const Divider(height: 24, color: AppTheme.dividerColor),

                              // Name field (view or edit)
                              _buildProfileField(
                                label: 'Họ và tên',
                                controller: _nameController,
                                icon: Icons.person_outline_rounded,
                                isEditable: _isEditing,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Họ và tên không được để trống';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              // Phone field
                              _buildProfileField(
                                label: 'Số điện thoại',
                                controller: _phoneController,
                                icon: Icons.phone_outlined,
                                isEditable: _isEditing,
                                keyboardType: TextInputType.phone,
                              ),
                              const SizedBox(height: 16),

                              // Address field
                              _buildProfileField(
                                label: 'Địa chỉ giao hàng',
                                controller: _addressController,
                                icon: Icons.location_on_outlined,
                                isEditable: _isEditing,
                                maxLines: 2,
                              ),
                              
                              if (_isEditing) ...[
                                const SizedBox(height: 24),
                                ElevatedButton.icon(
                                  onPressed: _saveProfile,
                                  icon: const Icon(Icons.check_rounded, size: 18),
                                  label: Text('Lưu Thay Đổi', style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.bold)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryColor,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 0,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Quick actions
                      Card(
                        margin: EdgeInsets.zero,
                        elevation: 0,
                        child: ListTile(
                          leading: const Icon(Icons.key_outlined, color: AppTheme.goldColor),
                          title: Text('Đổi mật khẩu', style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w500)),
                          trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppTheme.textLight),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const ChangePassView()),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    bool isEditable = false,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.beVietnamPro(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppTheme.textLight,
          ),
        ),
        const SizedBox(height: 6),
        if (!isEditable)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 18, color: AppTheme.textLight),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  controller.text.isNotEmpty ? controller.text : '(Chưa thiết lập)',
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 15,
                    color: controller.text.isNotEmpty ? AppTheme.textDark : AppTheme.textLight.withOpacity(0.6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          )
        else
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            style: GoogleFonts.beVietnamPro(fontSize: 15, color: AppTheme.textDark),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: AppTheme.primaryColor),
              contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppTheme.dividerColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1.5),
              ),
            ),
            validator: validator,
          ),
      ],
    );
  }
}

