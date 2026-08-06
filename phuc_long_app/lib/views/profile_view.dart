import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../state/app_state.dart';
import 'change_pass_view.dart';
import 'login_view.dart';
import 'admin_view.dart';

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

  void _showChangeAvatarDialog() {
    final user = _appState.currentUser;
    final urlController = TextEditingController(text: user?.avatarUrl ?? '');

    // Sample Avatar Suggestions for 1-click select
    final List<Map<String, String>> sampleAvatars = [
      {
        'title': 'Capybara 🦫',
        'url': 'https://images.unsplash.com/photo-1541658016709-82535e94bc69?w=400&auto=format&fit=crop&q=80',
      },
      {
        'title': 'Mèo Trà Sữa 🐱',
        'url': 'https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba?w=400&auto=format&fit=crop&q=80',
      },
      {
        'title': 'Thanh Lịch 👔',
        'url': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&auto=format&fit=crop&q=80',
      },
      {
        'title': 'Nữ Tính 🌸',
        'url': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400&auto=format&fit=crop&q=80',
      },
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final cleanUrl = urlController.text.trim();

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(
              'Đổi ảnh đại diện',
              style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Nhập/dán link ảnh (URL) hoặc chọn mẫu ảnh gợi ý bên dưới:',
                    style: GoogleFonts.beVietnamPro(fontSize: 13, color: AppTheme.textLight),
                  ),
                  const SizedBox(height: 16),

                  // Image Preview Box
                  Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.dividerColor),
                    ),
                    child: Center(
                      child: cleanUrl.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                cleanUrl,
                                headers: const {'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'},
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return const SizedBox(
                                    width: 100,
                                    height: 100,
                                    child: Center(
                                      child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor)),
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) => Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.broken_image_outlined, color: Colors.redAccent, size: 32),
                                    const SizedBox(height: 4),
                                    Text('Không thể tải ảnh từ link này', style: GoogleFonts.beVietnamPro(fontSize: 11, color: Colors.redAccent)),
                                  ],
                                ),
                              ),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.image_search_rounded, color: AppTheme.textLight, size: 36),
                                const SizedBox(height: 4),
                                Text('Xem trước ảnh đại diện', style: GoogleFonts.beVietnamPro(fontSize: 12, color: AppTheme.textLight)),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // TextField with Paste button
                  TextField(
                    controller: urlController,
                    decoration: InputDecoration(
                      labelText: 'Link ảnh (URL)',
                      hintText: 'https://example.com/avatar.jpg',
                      prefixIcon: const Icon(Icons.link_rounded, color: AppTheme.primaryColor),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.content_paste_rounded, color: AppTheme.primaryColor),
                        tooltip: 'Dán từ bộ nhớ tạm',
                        onPressed: () async {
                          final data = await Clipboard.getData(Clipboard.kTextPlain);
                          if (data != null && data.text != null) {
                            setDialogState(() {
                              urlController.text = data.text!.trim();
                            });
                          }
                        },
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onChanged: (val) {
                      setDialogState(() {});
                    },
                  ),
                  const SizedBox(height: 16),

                  // Quick Select Sample Avatars
                  Text(
                    'Hoặc chọn mẫu ảnh gợi ý sẵn:',
                    style: GoogleFonts.beVietnamPro(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: sampleAvatars.map((sample) {
                      return ActionChip(
                        avatar: ClipOval(
                          child: Image.network(
                            sample['url']!,
                            width: 20,
                            height: 20,
                            fit: BoxFit.cover,
                            headers: const {'User-Agent': 'Mozilla/5.0'},
                          ),
                        ),
                        label: Text(sample['title']!, style: GoogleFonts.beVietnamPro(fontSize: 11)),
                        backgroundColor: AppTheme.primaryColor.withOpacity(0.08),
                        onPressed: () {
                          setDialogState(() {
                            urlController.text = sample['url']!;
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Hủy', style: GoogleFonts.beVietnamPro(color: AppTheme.textLight)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  _appState.updateAvatarUrl(urlController.text.trim());
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Đã cập nhật ảnh đại diện mới thành công!', style: GoogleFonts.beVietnamPro()),
                      backgroundColor: AppTheme.primaryColor,
                    ),
                  );
                },
                child: Text('Lưu Ảnh', style: GoogleFonts.beVietnamPro(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
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
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top Header Banner & Avatar Stack
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.bottomCenter,
              children: [
                Container(
                  width: double.infinity,
                  height: 160,
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 8,
                    left: 16,
                    right: 16,
                  ),
                  decoration: const BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(width: 48),
                      Text(
                        'Hồ Sơ Cá Nhân',
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(_isEditing ? Icons.close_rounded : Icons.edit_rounded, color: Colors.white),
                            onPressed: () {
                              setState(() {
                                if (_isEditing) {
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
                    ],
                  ),
                ),

                // Avatar Representation (Clickable with Camera Badge)
                Positioned(
                  bottom: -50,
                  child: GestureDetector(
                    onTap: _showChangeAvatarDialog,
                    child: Stack(
                      children: [
                        Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.12),
                                blurRadius: 15,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(4),
                          child: Container(
                            decoration: const BoxDecoration(
                              color: AppTheme.primaryColor,
                              shape: BoxShape.circle,
                            ),
                            child: ClipOval(
                              child: user.avatarUrl.trim().isNotEmpty
                                  ? Image.network(
                                      user.avatarUrl.trim(),
                                      headers: const {'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'},
                                      width: 102,
                                      height: 102,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => Center(
                                        child: Text(
                                          user.name.isNotEmpty ? user.name.substring(0, 1).toUpperCase() : 'U',
                                          style: GoogleFonts.beVietnamPro(
                                            fontSize: 42,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.goldColor,
                                          ),
                                        ),
                                      ),
                                    )
                                  : Center(
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
                        ),
                        Positioned(
                          bottom: 2,
                          right: 2,
                          child: Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: AppTheme.goldColor,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(Icons.camera_alt_rounded, size: 16, color: AppTheme.primaryColor),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 60),

            // Profile Content Body
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // User Basic Info
                    Text(
                      user.name,
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '@${user.username}',
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryColor,
                        ),
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

                              // Username (Unique handle - Read only)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 16.0),
                                child: Row(
                                  children: [
                                    const Icon(Icons.alternate_email_rounded, color: AppTheme.primaryColor, size: 22),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Tên đăng nhập', style: GoogleFonts.beVietnamPro(fontSize: 12, color: AppTheme.textLight)),
                                        const SizedBox(height: 2),
                                        Text('@${user.username}', style: GoogleFonts.beVietnamPro(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

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
                                keyboardType: TextInputType.multiline,
                                minLines: 2,
                                maxLines: null,
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
                      if (user.isAdmin) ...[
                        Card(
                          margin: EdgeInsets.zero,
                          elevation: 0,
                          color: AppTheme.primaryColor.withOpacity(0.06),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: AppTheme.primaryColor.withOpacity(0.2)),
                          ),
                          child: ListTile(
                            leading: const Icon(Icons.admin_panel_settings_rounded, color: AppTheme.primaryColor),
                            title: Text('Trang Quản Trị Admin', style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                            subtitle: Text('Chuyển sang giao diện quản lý Admin', style: GoogleFonts.beVietnamPro(fontSize: 12, color: AppTheme.textLight)),
                            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppTheme.primaryColor),
                            onTap: () {
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(builder: (context) => const AdminView()),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
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
            ],
          ),
        ),
      );
  }

  Widget _buildProfileField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    bool isEditable = false,
    TextInputType keyboardType = TextInputType.text,
    int? minLines,
    int? maxLines = 1,
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
            minLines: minLines,
            maxLines: maxLines,
            style: GoogleFonts.beVietnamPro(fontSize: 15, color: AppTheme.textDark),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: AppTheme.primaryColor),
              alignLabelWithHint: minLines != null,
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

