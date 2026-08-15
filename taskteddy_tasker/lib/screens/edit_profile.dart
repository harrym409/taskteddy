import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/theme.dart';
import '../theme/app_theme.dart';
import '../services/tasker_state.dart';
import '../l10n/app_localizations.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final TaskerState _state = TaskerState();
  late AppL10n _l;

  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _cityController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: _state.user.name);
    _emailController = TextEditingController(text: _state.user.email);
    _phoneController = TextEditingController(text: _state.user.phone ?? '');
    _cityController = TextEditingController(text: 'Ludhiana');
    _state.addListener(_onStateChange);
  }

  @override
  void dispose() {
    _state.removeListener(_onStateChange);
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  void _onStateChange() {
    if (mounted) setState(() {});
  }

  bool _saving = false;

  Future<void> _onSave() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _saving = true);
      try {
        await _state.updateProfile(
          name: _nameController.text,
          email: _emailController.text,
          phone: _phoneController.text,
          city: _cityController.text,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _l.editProfileUpdated,
              style: GoogleFonts.nunito(fontWeight: FontWeight.w600),
            ),
            backgroundColor: T.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(16),
          ),
        );
        Navigator.pop(context);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _l.editProfileFailed(e.toString()),
              style: GoogleFonts.nunito(fontWeight: FontWeight.w600),
            ),
            backgroundColor: T.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(16),
          ),
        );
      } finally {
        if (mounted) setState(() => _saving = false);
      }
    }
  }

  Future<void> _pickAndUploadAvatar(ImageSource source) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
        source: source, maxWidth: 1024, imageQuality: 85);
    if (file == null || !mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(_l.profileUploadingPhoto)));
    final error = await _state.uploadAvatar(file);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error ?? _l.profilePictureUpdated),
        backgroundColor: error == null ? T.green : T.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showAvatarPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_l.profileUpdatePicture,
                style:
                    GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.photo_library, color: T.primary),
              title: Text(_l.commonChooseGallery,
                  style: GoogleFonts.nunito(fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(context);
                _pickAndUploadAvatar(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: T.primary),
              title: Text(_l.commonTakePhoto,
                  style: GoogleFonts.nunito(fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(context);
                _pickAndUploadAvatar(ImageSource.camera);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _l = AppL10n.of(context)!;
    final initial = _nameController.text.isNotEmpty
        ? _nameController.text[0].toUpperCase()
        : 'R';

    return Scaffold(
      backgroundColor: T.bg,
      appBar: AppTheme.gradientBar(_l.profileEditProfile),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // ── Avatar with camera edit button ──────────────
              GestureDetector(
                onTap: _showAvatarPicker,
                child: Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 52,
                        backgroundColor: T.primaryLight,
                        backgroundImage: _state.user.avatarUrl != null && _state.user.avatarUrl!.isNotEmpty
                            ? NetworkImage(_state.user.avatarUrl!)
                            : null,
                        child: _state.user.avatarUrl == null || _state.user.avatarUrl!.isEmpty
                            ? Text(
                                initial,
                                style: GoogleFonts.nunito(
                                  fontSize: 40,
                                  fontWeight: FontWeight.w800,
                                  color: T.primary,
                                ),
                              )
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          decoration: BoxDecoration(
                            color: T.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2.5),
                          ),
                          padding: const EdgeInsets.all(7),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // ── Full Name ──────────────────────────────────
              _buildField(
                label: _l.editFullName,
                controller: _nameController,
                icon: Icons.person_outline,
                hint: _l.editFullNameHint,
                keyboardType: TextInputType.name,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? _l.editNameRequired : null,
              ),
              const SizedBox(height: 18),

              // ── Email ──────────────────────────────────────
              _buildField(
                label: _l.editEmail,
                controller: _emailController,
                icon: Icons.email_outlined,
                hint: _l.editEmailHint,
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return _l.editEmailRequired;
                  if (!v.contains('@')) return _l.editEmailInvalid;
                  return null;
                },
              ),
              const SizedBox(height: 18),

              // ── Phone Number ───────────────────────────────
              _buildField(
                label: _l.editPhone,
                controller: _phoneController,
                icon: Icons.phone_outlined,
                hint: _l.editPhoneHint,
                keyboardType: TextInputType.phone,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? _l.editPhoneRequired : null,
              ),
              const SizedBox(height: 18),

              // ── City / Location ────────────────────────────
              _buildField(
                label: _l.editCity,
                controller: _cityController,
                icon: Icons.location_on_outlined,
                hint: _l.editCityHint,
                keyboardType: TextInputType.text,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? _l.editCityRequired : null,
              ),
              const SizedBox(height: 36),

              // ── Save Changes Button ────────────────────────
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _onSave,
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.4),
                        )
                      : Text(_l.editSaveChanges),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.nunito(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: T.text2,
          ),
        ),
        const SizedBox(height: 7),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          style: GoogleFonts.nunito(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: T.text1,
          ),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: T.primary, size: 20),
          ),
        ),
      ],
    );
  }
}
