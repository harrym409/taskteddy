import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../l10n/app_localizations.dart';
import '../services/api_service.dart';
import '../theme/theme.dart';

/// Lists the users the customer has blocked, with an unblock action per row.
/// Reached from Profile → Account settings → Blocked users.
class BlockedUsersScreen extends StatefulWidget {
  const BlockedUsersScreen({super.key});

  @override
  State<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen> {
  bool _loading = true;
  bool _error = false;
  List<Map<String, dynamic>> _blocks = [];
  final Set<String> _busy = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      final blocks = await ApiService.getBlocks();
      if (!mounted) return;
      setState(() {
        _blocks = blocks;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = true;
      });
    }
  }

  Future<void> _unblock(String blockedId, String name) async {
    setState(() => _busy.add(blockedId));
    try {
      await ApiService.unblockUser(blockedId);
      if (!mounted) return;
      final l = AppL10n.of(context)!;
      setState(() {
        _blocks = _blocks
            .where((b) => b['blocked_id']?.toString() != blockedId)
            .toList();
        _busy.remove(blockedId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.unblockedSuccess(name),
              style: GoogleFonts.nunito(fontWeight: FontWeight.w600)),
          backgroundColor: C.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy.remove(blockedId));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: C.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(title: Text(AppL10n.of(context)!.blockedUsersTitle)),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: C.primary))
          : _error
              ? _errorState()
              : RefreshIndicator(
                  onRefresh: _load,
                  color: C.primary,
                  child: _blocks.isEmpty ? _emptyState() : _list(),
                ),
    );
  }

  Widget _list() {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: _blocks.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final block = _blocks[i];
        final user = block['user'] is Map
            ? Map<String, dynamic>.from(block['user'] as Map)
            : const <String, dynamic>{};
        final blockedId = block['blocked_id']?.toString() ??
            user['id']?.toString() ??
            '';
        final rawName = user['name']?.toString().trim();
        final name = (rawName != null && rawName.isNotEmpty)
            ? rawName
            : AppL10n.of(context)!.userLabel;
        final avatar = ApiService.resolveMediaUrl(user['avatar_url']?.toString());
        final busy = _busy.contains(blockedId);
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: C.border),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: C.primaryLight,
                backgroundImage: avatar != null ? NetworkImage(avatar) : null,
                child: avatar == null
                    ? Text(
                        name.substring(0, 1).toUpperCase(),
                        style: GoogleFonts.nunito(
                          color: C.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.nunito(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: C.text1,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 38,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: C.primary,
                    side: const BorderSide(color: C.primary),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed:
                      (busy || blockedId.isEmpty) ? null : () => _unblock(blockedId, name),
                  child: busy
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              color: C.primary, strokeWidth: 2),
                        )
                      : Text(AppL10n.of(context)!.unblock,
                          style: GoogleFonts.nunito(
                              fontSize: 13.5, fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _emptyState() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(28, 90, 28, 24),
      children: [
        Container(
          width: 64,
          height: 64,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: C.primaryLight,
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Icon(Icons.block, color: C.primary, size: 34),
        ),
        const SizedBox(height: 16),
        Text(
          AppL10n.of(context)!.noBlockedUsers,
          textAlign: TextAlign.center,
          style: GoogleFonts.nunito(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: C.text1,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          AppL10n.of(context)!.blockedUsersEmptyBody,
          textAlign: TextAlign.center,
          style: GoogleFonts.nunito(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: C.text3,
          ),
        ),
      ],
    );
  }

  Widget _errorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 48, color: C.text3),
            const SizedBox(height: 14),
            Text(
              AppL10n.of(context)!.blockedUsersError,
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: C.text2,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh, size: 18),
              label: Text(AppL10n.of(context)!.retry,
                  style: GoogleFonts.nunito(fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      ),
    );
  }
}
