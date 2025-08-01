import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';
import 'package:intl/intl.dart';

import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../models/profile.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final _fullNameController = TextEditingController();
  final _dobController = TextEditingController();
  final _addressController = TextEditingController();
  final _avatarController = TextEditingController();
  final _identityNumberController = TextEditingController();
  final _issuedDateController = TextEditingController();
  final _issuedPlaceController = TextEditingController();
  final _emergencyNameController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();
  final _emergencyRelationController = TextEditingController();

  String? _gender;
  String? _nationality;
  bool _isLoading = false;
  bool _isInit = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final authProvider = context.read<AuthProvider>();
      final profileProvider = context.read<ProfileProvider>();

      if (authProvider.user == null) {
        try {
          await authProvider.loadMe();
        } catch (e) {
          _showError('❌ Không thể tải người dùng: $e');
          return;
        }
      }

      if (profileProvider.profile == null) {
        await profileProvider.fetchMyProfile();
      }

      final profile = profileProvider.profile;
      if (profile != null) {
        _fullNameController.text = profile.fullName ?? '';
        _dobController.text = _formatDate(profile.dob);
        _addressController.text = profile.address ?? '';
        _avatarController.text = profile.avatar ?? '';
        _identityNumberController.text = profile.identityNumber ?? '';
        _issuedDateController.text = _formatDate(profile.issuedDate);
        _issuedPlaceController.text = profile.issuedPlace ?? '';
        _gender = profile.gender;
        _nationality = profile.nationality;

        final ec = profile.emergencyContact;
        if (ec != null) {
          _emergencyNameController.text = ec.name ?? '';
          _emergencyPhoneController.text = ec.phone ?? '';
          _emergencyRelationController.text = ec.relationship ?? '';
        }
      }

      setState(() => _isInit = true);
    });
  }

  String _formatDate(String? rawDate) {
    if (rawDate == null || rawDate.isEmpty) return '';
    try {
      final milliseconds = int.tryParse(rawDate);
      if (milliseconds != null && milliseconds > 1000000000) {
        final date = DateTime.fromMillisecondsSinceEpoch(milliseconds);
        return DateFormat('yyyy-MM-dd').format(date);
      }
      final parsed = DateTime.tryParse(rawDate);
      return parsed != null ? DateFormat('yyyy-MM-dd').format(parsed) : rawDate;
    } catch (_) {
      return rawDate;
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _dobController.dispose();
    _addressController.dispose();
    _avatarController.dispose();
    _identityNumberController.dispose();
    _issuedDateController.dispose();
    _issuedPlaceController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    _emergencyRelationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authUser = context.watch<AuthProvider>().user;
    final profile = context.watch<ProfileProvider>().profile;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          'Thông tin cá nhân',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6), // ✅ Giảm padding
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back, size: 18), // ✅ Giảm icon size
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: !_isInit
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Đang tải thông tin...'),
          ],
        ),
      )
          : Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16), // ✅ Giảm padding từ 20 -> 16
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar Section
                    _buildAvatarSection(),
                    const SizedBox(height: 24), // ✅ Giảm spacing

                    // Email Section
                    _buildEmailSection(authUser?.email),
                    const SizedBox(height: 16), // ✅ Giảm spacing

                    // Personal Info Section
                    _buildSectionCard(
                      title: 'Thông tin cá nhân',
                      icon: Icons.person_outline,
                      color: Colors.blue,
                      children: [
                        _buildTextField(
                          'Họ và tên',
                          _fullNameController,
                          Icons.badge_outlined,
                          required: true,
                        ),
                        const SizedBox(height: 12), // ✅ Giảm spacing
                        _buildGenderDropdown(),
                        const SizedBox(height: 12),
                        _buildDateField('Ngày sinh', _dobController, Icons.cake_outlined),
                        const SizedBox(height: 12),
                        _buildTextField(
                          'Địa chỉ',
                          _addressController,
                          Icons.location_on_outlined,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Identity Section
                    _buildSectionCard(
                      title: 'Giấy tờ tùy thân',
                      icon: Icons.credit_card_outlined,
                      color: Colors.green,
                      children: [
                        _buildTextField(
                          'Số CCCD/CMND',
                          _identityNumberController,
                          Icons.credit_card,
                        ),
                        const SizedBox(height: 12),
                        _buildDateField('Ngày cấp', _issuedDateController, Icons.event_outlined),
                        const SizedBox(height: 12),
                        _buildTextField(
                          'Nơi cấp',
                          _issuedPlaceController,
                          Icons.location_city_outlined,
                        ),
                        const SizedBox(height: 12),
                        _buildNationalityDropdown(),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Emergency Contact Section
                    _buildSectionCard(
                      title: 'Liên hệ khẩn cấp',
                      icon: Icons.emergency_outlined,
                      color: Colors.orange,
                      children: [
                        _buildTextField(
                          'Họ tên người liên hệ',
                          _emergencyNameController,
                          Icons.person_outline,
                        ),
                        const SizedBox(height: 12),
                        _buildTextField(
                          'Số điện thoại',
                          _emergencyPhoneController,
                          Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 12),
                        _buildTextField(
                          'Mối quan hệ',
                          _emergencyRelationController,
                          Icons.favorite_outline,
                        ),
                      ],
                    ),
                    const SizedBox(height: 100), // ✅ Extra space để button không bị che
                  ],
                ),
              ),
            ),
          ),
          // ✅ Fixed submit button - Đặt ngoài ScrollView
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16), // ✅ Padding tối ưu
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: _buildSubmitButton(profile),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarSection() {
    final hasAvatar = _avatarController.text.isNotEmpty;
    return Center(
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15), // ✅ Giảm shadow opacity
                      blurRadius: 15, // ✅ Giảm blur
                      offset: const Offset(0, 6), // ✅ Giảm offset
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 50, // ✅ Giữ nguyên size phù hợp
                  backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  backgroundImage: hasAvatar ? NetworkImage(_avatarController.text) : null,
                  child: !hasAvatar
                      ? Icon(
                    Icons.person_outline,
                    size: 40, // ✅ Giảm icon size
                    color: Theme.of(context).colorScheme.primary,
                  )
                      : null,
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _pickAvatar,
                  child: Container(
                    padding: const EdgeInsets.all(6), // ✅ Giảm padding
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 6, // ✅ Giảm blur
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 18, // ✅ Giảm icon size
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8), // ✅ Giảm spacing
          Text(
            'Nhấn để thay đổi ảnh đại diện',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              fontSize: 12, // ✅ Giảm font size
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailSection(String? email) {
    return Container(
      padding: const EdgeInsets.all(12), // ✅ Giảm padding từ 16 -> 12
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6), // ✅ Giảm padding
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.email_outlined,
              color: Theme.of(context).colorScheme.primary,
              size: 18, // ✅ Giảm icon size
            ),
          ),
          const SizedBox(width: 10), // ✅ Giảm spacing
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Email',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    fontSize: 11, // ✅ Giảm font size
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  email ?? 'Chưa có email',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 14, // ✅ Giảm font size
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), // ✅ Giảm padding
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Đã xác thực',
              style: TextStyle(
                color: Colors.green.shade700,
                fontSize: 10, // ✅ Giảm font size
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12), // ✅ Giảm border radius
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03), // ✅ Giảm shadow opacity
            blurRadius: 6, // ✅ Giảm blur
            offset: const Offset(0, 2), // ✅ Giảm offset
          ),
        ],
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12), // ✅ Giảm padding từ 16 -> 12
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6), // ✅ Giảm padding
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 18), // ✅ Giảm icon size
                ),
                const SizedBox(width: 10), // ✅ Giảm spacing
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14, // ✅ Giảm font size
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12), // ✅ Giảm padding từ 16 -> 12
            child: Column(
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
      String label,
      TextEditingController controller,
      IconData icon, {
        bool required = false,
        TextInputType? keyboardType,
      }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 13), // ✅ Giảm font size
        prefixIcon: Container(
          margin: const EdgeInsets.all(6), // ✅ Giảm margin
          padding: const EdgeInsets.all(6), // ✅ Giảm padding
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 18), // ✅ Giảm icon size
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10), // ✅ Giảm border radius
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 2,
          ),
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12), // ✅ Giảm padding
        isDense: true, // ✅ Make more compact
      ),
      validator: required
          ? (value) => value?.trim().isEmpty ?? true ? 'Vui lòng nhập $label' : null
          : null,
    );
  }

  Widget _buildDateField(String label, TextEditingController controller, IconData icon) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 13), // ✅ Giảm font size
        prefixIcon: Container(
          margin: const EdgeInsets.all(6),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 18),
        ),
        suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 2,
          ),
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        isDense: true,
      ),
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: DateTime.tryParse(controller.text) ?? DateTime(2000),
          firstDate: DateTime(1900),
          lastDate: DateTime.now(),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: Theme.of(context).colorScheme.primary,
                ),
              ),
              child: child!,
            );
          },
        );
        if (date != null) {
          controller.text = DateFormat('yyyy-MM-dd').format(date);
        }
      },
    );
  }

  Widget _buildGenderDropdown() {
    return DropdownButtonFormField<String>(
      value: _gender,
      decoration: InputDecoration(
        labelText: 'Giới tính',
        labelStyle: const TextStyle(fontSize: 13),
        prefixIcon: Container(
          margin: const EdgeInsets.all(6),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Icon(Icons.wc_outlined, size: 18),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 2,
          ),
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        isDense: true,
      ),
      items: [
        DropdownMenuItem(value: 'male', child: Row(children: [const Icon(Icons.male, size: 14), const SizedBox(width: 6), const Text('Nam', style: TextStyle(fontSize: 14))])),
        DropdownMenuItem(value: 'female', child: Row(children: [const Icon(Icons.female, size: 14), const SizedBox(width: 6), const Text('Nữ', style: TextStyle(fontSize: 14))])),
        DropdownMenuItem(value: 'other', child: Row(children: [const Icon(Icons.transgender, size: 14), const SizedBox(width: 6), const Text('Khác', style: TextStyle(fontSize: 14))])),
      ],
      onChanged: (val) => setState(() => _gender = val),
      isExpanded: true,
      dropdownColor: Theme.of(context).colorScheme.surface,
    );
  }

  Widget _buildNationalityDropdown() {
    final nationalities = [
      {'code': 'Vietnam', 'name': 'Việt Nam', 'flag': '🇻🇳'},
      {'code': 'USA', 'name': 'Hoa Kỳ', 'flag': '🇺🇸'},
      {'code': 'UK', 'name': 'Anh', 'flag': '🇬🇧'},
      {'code': 'Japan', 'name': 'Nhật Bản', 'flag': '🇯🇵'},
      {'code': 'Other', 'name': 'Khác', 'flag': '🌍'},
    ];

    return DropdownButtonFormField<String>(
      value: _nationality,
      decoration: InputDecoration(
        labelText: 'Quốc tịch',
        labelStyle: const TextStyle(fontSize: 13),
        prefixIcon: Container(
          margin: const EdgeInsets.all(6),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Icon(Icons.flag_outlined, size: 18),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 2,
          ),
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        isDense: true,
      ),
      items: nationalities
          .map((nat) => DropdownMenuItem(
        value: nat['code'],
        child: Row(
          children: [
            Text(nat['flag']!, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Text(nat['name']!, style: const TextStyle(fontSize: 14)),
          ],
        ),
      ))
          .toList(),
      onChanged: (val) => setState(() => _nationality = val),
      isExpanded: true,
      dropdownColor: Theme.of(context).colorScheme.surface,
    );
  }

  Widget _buildSubmitButton(Profile? profile) {
    return SizedBox(
      width: double.infinity,
      height: 48, // ✅ Giảm height từ 56 -> 48
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12), // ✅ Giảm border radius
          ),
          elevation: 0,
          shadowColor: Colors.transparent,
        ),
        child: _isLoading
            ? const SizedBox(
          width: 20, // ✅ Giảm size
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white,
          ),
        )
            : Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              profile == null ? Icons.person_add : Icons.save,
              size: 18, // ✅ Giảm icon size
            ),
            const SizedBox(width: 6), // ✅ Giảm spacing
            Text(
              profile == null ? 'Tạo hồ sơ' : 'Cập nhật hồ sơ',
              style: const TextStyle(
                fontSize: 14, // ✅ Giảm font size
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _isLoading = true);
      try {
        final mimeType = lookupMimeType(picked.path);
        final mediaType = mimeType != null ? MediaType.parse(mimeType) : null;

        final formData = FormData.fromMap({
          'file': await MultipartFile.fromFile(
            picked.path,
            filename: picked.name,
            contentType: mediaType,
          ),
        });

        final response = await Dio().post(
          'http://172.27.145.10:4000/api/upload',
          data: formData,
        );

        if (response.statusCode == 200 && response.data['urls'] != null) {
          final imageUrl = response.data['urls'][0];
          setState(() => _avatarController.text = imageUrl);
          _showSuccess('Tải ảnh lên thành công! 📸');
        } else {
          _showError('Upload thất bại: Server không trả URL');
        }
      } catch (e) {
        _showError('❌ Upload ảnh thất bại: $e');
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(msg)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(msg)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final authProvider = context.read<AuthProvider>();
    final profileProvider = context.read<ProfileProvider>();
    final userId = authProvider.user?.id;

    if (userId == null) {
      _showError('❌ Không tìm thấy ID người dùng');
      setState(() => _isLoading = false);
      return;
    }

    final profile = Profile(
      fullName: _fullNameController.text.trim(),
      dob: _dobController.text.trim(),
      address: _addressController.text.trim(),
      gender: _gender,
      avatar: _avatarController.text.trim(),
      identityNumber: _identityNumberController.text.trim(),
      issuedDate: _issuedDateController.text.trim(),
      issuedPlace: _issuedPlaceController.text.trim(),
      nationality: _nationality,
      emergencyContact: EmergencyContact(
        name: _emergencyNameController.text.trim(),
        phone: _emergencyPhoneController.text.trim(),
        relationship: _emergencyRelationController.text.trim(),
      ),
    );

    bool success = false;
    if (profileProvider.profile == null) {
      success = await profileProvider.createProfile(userId, profile);
    } else {
      success = await profileProvider.updateMyProfile(profile);
    }

    if (mounted) {
      if (success) {
        _showSuccess('✅ Cập nhật thông tin thành công!');
        Navigator.pop(context);
      } else {
        _showError('❌ Cập nhật thất bại. Vui lòng thử lại!');
      }
      setState(() => _isLoading = false);
    }
  }
}
