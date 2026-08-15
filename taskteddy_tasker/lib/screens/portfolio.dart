import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/theme.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../l10n/app_localizations.dart';

// ════════════════════════════════════════════════════════
//  WORK PORTFOLIO GALLERY
//  View / add / delete portfolio photos (max 12).
// ════════════════════════════════════════════════════════

const int _maxItems = 12;

class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({super.key});

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> {
  bool _loading = true;
  bool _uploading = false;
  String? _error;
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await ApiService.getPortfolio();
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _loading = false;
      });
    }
  }

  void _snack(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message,
            style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
        backgroundColor: error ? T.red : T.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _addPhoto(ImageSource source) async {
    final l = AppL10n.of(context)!;
    if (_items.length >= _maxItems) {
      _snack(l.portfolioFull(_maxItems), error: true);
      return;
    }
    final picker = ImagePicker();
    final file =
        await picker.pickImage(source: source, maxWidth: 1600, imageQuality: 85);
    if (file == null || !mounted) return;

    final caption = await _askCaption();
    if (!mounted) return;

    setState(() => _uploading = true);
    try {
      final item = await ApiService.addPortfolioItem(file, caption: caption);
      if (!mounted) return;
      setState(() {
        _items = [item, ..._items];
        _uploading = false;
      });
      _snack(l.portfolioPhotoAdded);
    } catch (e) {
      if (!mounted) return;
      setState(() => _uploading = false);
      _snack(e.toString().replaceAll('Exception: ', ''), error: true);
    }
  }

  Future<String?> _askCaption() async {
    final l = AppL10n.of(context)!;
    final ctrl = TextEditingController();
    try {
      return await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l.portfolioAddCaption,
            style: GoogleFonts.nunito(
                fontWeight: FontWeight.w800, color: T.text1)),
        content: TextField(
          controller: ctrl,
          maxLength: 80,
          style: GoogleFonts.nunito(fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: l.portfolioCaptionHint,
            counterText: '',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, ''),
            child: Text(l.portfolioSkip,
                style: GoogleFonts.nunito(
                    fontWeight: FontWeight.w700, color: T.text3)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            style: ElevatedButton.styleFrom(
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(l.profileAdd,
                style: GoogleFonts.nunito(
                    color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      );
    } finally {
      ctrl.dispose();
    }
  }

  void _showSourcePicker() {
    final l = AppL10n.of(context)!;
    if (_items.length >= _maxItems) {
      _snack(l.portfolioFull(_maxItems), error: true);
      return;
    }
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l.portfolioAddWorkPhoto,
                style: GoogleFonts.nunito(
                    fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.photo_library, color: T.primary),
              title: Text(l.commonChooseGallery,
                  style: GoogleFonts.nunito(fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(context);
                _addPhoto(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: T.primary),
              title: Text(l.commonTakePhoto,
                  style: GoogleFonts.nunito(fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(context);
                _addPhoto(ImageSource.camera);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteItem(Map<String, dynamic> item) async {
    final l = AppL10n.of(context)!;
    final id = item['id']?.toString();
    if (id == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l.portfolioRemovePhoto,
            style: GoogleFonts.nunito(
                fontWeight: FontWeight.w800, color: T.text1)),
        content: Text(l.portfolioRemoveConfirm,
            style: GoogleFonts.nunito(color: T.text2)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.actionCancel,
                style: GoogleFonts.nunito(
                    fontWeight: FontWeight.w700, color: T.text3)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: T.red,
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(l.commonRemove,
                style: GoogleFonts.nunito(
                    color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ApiService.deletePortfolioItem(id);
      if (!mounted) return;
      setState(() => _items.removeWhere((it) => it['id']?.toString() == id));
      _snack(l.portfolioPhotoRemoved);
    } catch (e) {
      _snack(e.toString().replaceAll('Exception: ', ''), error: true);
    }
  }

  void _viewItem(Map<String, dynamic> item) {
    final url = ApiService.resolveMediaUrl(item['image_url']?.toString());
    final caption = item['caption']?.toString() ?? '';
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: url == null
                  ? const SizedBox.shrink()
                  : Image.network(url, fit: BoxFit.contain),
            ),
            if (caption.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(caption,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700)),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context)!;
    return Scaffold(
      backgroundColor: T.bg,
      appBar: AppTheme.gradientBar(
        l.profileWorkPortfolio,
        actions: [
          if (!_loading && _error == null)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('${_items.length}/$_maxItems',
                      style: GoogleFonts.nunito(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w800)),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: (_loading || _error != null)
          ? null
          : FloatingActionButton.extended(
              backgroundColor: T.primary,
              onPressed: _uploading ? null : _showSourcePicker,
              icon: _uploading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.add_a_photo, color: Colors.white),
              label: Text(_uploading ? l.portfolioUploading : l.portfolioAddPhoto,
                  style: GoogleFonts.nunito(
                      color: Colors.white, fontWeight: FontWeight.w800)),
            ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: T.primary))
          : _error != null
              ? FriendlyState(
                  icon: Icons.cloud_off_rounded,
                  iconColor: T.text3,
                  title: _error!,
                  action: ElevatedButton(
                    onPressed: _load,
                    child: Text(l.actionRetry,
                        style: GoogleFonts.nunito(fontWeight: FontWeight.w800)),
                  ),
                )
              : _items.isEmpty
                  ? _emptyState()
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: T.primary,
                      child: GridView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.85,
                        ),
                        itemCount: _items.length,
                        itemBuilder: (_, i) => _tile(_items[i]),
                      ),
                    ),
    );
  }

  Widget _emptyState() {
    final l = AppL10n.of(context)!;
    return FriendlyState(
      icon: Icons.photo_library_outlined,
      title: l.portfolioEmpty,
      body: l.portfolioEmptyBody,
    );
  }

  Widget _tile(Map<String, dynamic> item) {
    final url = ApiService.resolveMediaUrl(item['image_url']?.toString());
    final caption = item['caption']?.toString() ?? '';
    return GestureDetector(
      onTap: () => _viewItem(item),
      child: Container(
        decoration: AppTheme.card(),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(17)),
                    child: url == null
                        ? Container(color: T.primaryLight)
                        : Image.network(
                            url,
                            fit: BoxFit.cover,
                            loadingBuilder: (ctx, child, progress) =>
                                progress == null
                                    ? child
                                    : Container(
                                        color: T.primaryLight,
                                        child: const Center(
                                          child: SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: T.primary),
                                          ),
                                        ),
                                      ),
                            errorBuilder: (_, __, ___) => Container(
                              color: T.primaryLight,
                              child: const Icon(Icons.broken_image_outlined,
                                  color: T.text3),
                            ),
                          ),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: GestureDetector(
                      onTap: () => _deleteItem(item),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: .5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.delete_outline,
                            color: Colors.white, size: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Text(
                caption.isEmpty ? AppL10n.of(context)!.portfolioUntitled : caption,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: caption.isEmpty ? T.text3 : T.text1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
