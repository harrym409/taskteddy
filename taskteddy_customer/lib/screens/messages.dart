import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../l10n/app_localizations.dart';
import '../services/api_service.dart';
import '../theme/theme.dart';

// ─── Conversations List Screen ─────────────────────────────────────────────────

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _search;
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;
  List<ChatConversation> _conversations = [];
  String _query = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _search = TextEditingController();
    _search.addListener(_onSearchChanged);
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _loadConversations();
  }

  @override
  void dispose() {
    _search.removeListener(_onSearchChanged);
    _search.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadConversations() async {
    setState(() => _loading = true);
    final rows = await ApiService.getConversations();
    final next = rows
        .map(ChatConversation.fromJson)
        .where((conversation) => conversation.name.trim().isNotEmpty)
        .toList()
      ..sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));
    if (!mounted) return;
    setState(() {
      _conversations = next;
      _loading = false;
    });
    _fadeController.forward(from: 0);
  }

  void _onSearchChanged() {
    if (!mounted) return;
    setState(() => _query = _search.text.trim().toLowerCase());
  }

  List<ChatConversation> get _filtered {
    if (_query.isEmpty) return _conversations;
    return _conversations.where((conversation) {
      final searchText = [
        conversation.name,
        conversation.lastMessage,
        conversation.taskTitle ?? '',
      ].join(' ').toLowerCase();
      return searchText.contains(_query);
    }).toList();
  }

  Future<void> _openChat(ChatConversation conversation) async {
    await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => ChatScreen(conversation: conversation),
        transitionsBuilder: (_, animation, __, child) {
          return SlideTransition(
            position: Tween(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
    await _loadConversations();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: C.bg,
        appBar: AppBar(
          title: Text(AppL10n.of(context)!.messagesTitle),
          automaticallyImplyLeading: Navigator.of(context).canPop(),
        ),
        body: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusScope.of(context).unfocus(),
          child: Column(
            children: [
              // ── Search Bar ──
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: C.border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _search,
                    onTapOutside: (_) => FocusScope.of(context).unfocus(),
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: C.text1,
                    ),
                    decoration: InputDecoration(
                      hintText: AppL10n.of(context)!.messagesSearchHint,
                      hintStyle: GoogleFonts.nunito(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: C.text3,
                      ),
                      prefixIcon: const Icon(Icons.search_rounded,
                          color: C.text3, size: 20),
                      suffixIcon: _query.isEmpty
                          ? null
                          : IconButton(
                              onPressed: _search.clear,
                              icon: const Icon(Icons.close_rounded,
                                  color: C.text3, size: 18),
                            ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 13,
                      ),
                    ),
                  ),
                ),
              ),

              // ── Conversations List ──
              Expanded(
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: C.primary,
                          strokeWidth: 2.5,
                        ),
                      )
                    : _filtered.isEmpty
                        ? _buildEmptyState()
                        : RefreshIndicator(
                            onRefresh: _loadConversations,
                            color: C.primary,
                            backgroundColor: Colors.white,
                            strokeWidth: 2.5,
                            displacement: 40,
                            child: FadeTransition(
                              opacity: _fadeAnimation,
                              child: ListView.builder(
                                keyboardDismissBehavior:
                                    ScrollViewKeyboardDismissBehavior.onDrag,
                                padding:
                                    const EdgeInsets.fromLTRB(16, 2, 16, 16),
                                itemCount: _filtered.length,
                                itemBuilder: (_, i) => _ConversationCard(
                                  conversation: _filtered[i],
                                  onTap: () => _openChat(_filtered[i]),
                                  index: i,
                                ),
                              ),
                            ),
                          ),
              ),
            ],
          ),
        ),
      );

  Widget _buildEmptyState() {
    final isSearching = _query.isNotEmpty;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: C.primaryLight,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: C.primary.withValues(alpha: 0.15),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  isSearching
                      ? Icons.search_off_rounded
                      : Icons.forum_rounded,
                  size: 44,
                  color: C.primary,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              isSearching
                  ? AppL10n.of(context)!.messagesNoResults
                  : AppL10n.of(context)!.messagesNoConversations,
              style: GoogleFonts.nunito(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: C.text1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isSearching
                  ? AppL10n.of(context)!.messagesTryDifferentSearch
                  : AppL10n.of(context)!.messagesBookToChat,
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: C.text3,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Conversation Card ─────────────────────────────────────────────────────────

class _ConversationCard extends StatelessWidget {
  final ChatConversation conversation;
  final VoidCallback onTap;
  final int index;

  const _ConversationCard({
    required this.conversation,
    required this.onTap,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final avatarSeed =
        conversation.name.trim().isEmpty ? '?' : conversation.name[0];
    final hasUnread = conversation.unreadCount > 0;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 350 + (index * 60).clamp(0, 300)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Transform.translate(
        offset: Offset(0, 16 * (1 - value)),
        child: Opacity(opacity: value, child: child),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasUnread
                ? C.primary.withValues(alpha: 0.35)
                : C.border,
            width: hasUnread ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: hasUnread
                  ? C.primary.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.03),
              blurRadius: hasUnread ? 12 : 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            splashColor: C.primary.withValues(alpha: 0.06),
            highlightColor: C.primary.withValues(alpha: 0.03),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  // ── Avatar with online dot ──
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: C.primaryLight,
                        backgroundImage: conversation.avatarUrl != null
                            ? NetworkImage(conversation.avatarUrl!)
                            : null,
                        child: conversation.avatarUrl == null
                            ? Text(
                                avatarSeed.toUpperCase(),
                                style: GoogleFonts.nunito(
                                  color: C.primary,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                ),
                              )
                            : null,
                      ),
                      Positioned(
                        right: 1,
                        bottom: 1,
                        child: Container(
                          width: 13,
                          height: 13,
                          decoration: BoxDecoration(
                            color: C.green,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),

                  // ── Content ──
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                conversation.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.nunito(
                                  fontSize: 15,
                                  fontWeight:
                                      hasUnread ? FontWeight.w900 : FontWeight.w800,
                                  color: C.text1,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _formatTime(
                                  AppL10n.of(context)!, conversation.lastMessageAt),
                              style: GoogleFonts.nunito(
                                fontSize: 11,
                                color: hasUnread ? C.primary : C.text3,
                                fontWeight:
                                    hasUnread ? FontWeight.w700 : FontWeight.w500,
                              ),
                            ),
                          ],
                        ),

                        // ── Task badge ──
                        if (conversation.taskTitle != null &&
                            conversation.taskTitle!.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: C.primaryLight,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              conversation.taskTitle!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.nunito(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: C.primaryDark,
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                conversation.lastMessage.isEmpty
                                    ? AppL10n.of(context)!.messagesTapToOpen
                                    : conversation.lastMessage,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.nunito(
                                  fontSize: 13,
                                  color: C.text3,
                                  fontWeight: hasUnread
                                      ? FontWeight.w700
                                      : FontWeight.w600,
                                ),
                              ),
                            ),
                            if (hasUnread)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: C.primary,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  conversation.unreadCount.toString(),
                                  style: GoogleFonts.nunito(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(AppL10n l, DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return l.msgTimeNow;
    if (diff.inMinutes < 60) return l.msgTimeMinutes(diff.inMinutes);
    if (diff.inHours < 24) return l.msgTimeHours(diff.inHours);
    if (diff.inDays < 7) return l.msgTimeDays(diff.inDays);
    return '${time.day}/${time.month}';
  }
}

// ─── Chat Screen ────────────────────────────────────────────────────────────────

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.conversation});

  final ChatConversation conversation;

  @override
  State<ChatScreen> createState() => ChatScreenState();
}

class ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  late final TextEditingController _composer;
  late final ScrollController _scroll;
  String _currentUserId = '';
  List<_ChatMessage> _messages = [];
  bool _loading = true;
  bool _showScrollFab = false;
  Timer? _pollingTimer;

  // Track failed messages
  final Set<String> _failedIds = {};

  @override
  void initState() {
    super.initState();
    _composer = TextEditingController();
    _scroll = ScrollController()..addListener(_onScroll);
    _bootstrap();
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted) _loadMessages(hideLoading: true);
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _composer.dispose();
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final shouldShow = _scroll.offset > 300;
    if (shouldShow != _showScrollFab) {
      setState(() => _showScrollFab = shouldShow);
    }
  }

  Future<void> _bootstrap() async {
    final user = await Session.getUser();
    _currentUserId = user?['id']?.toString() ?? '';
    await _loadMessages();
  }

  Future<void> _loadMessages({bool hideLoading = false}) async {
    if (!hideLoading) setState(() => _loading = true);
    final rows = await ApiService.getMessages(widget.conversation.id);
    final next = rows
        .map((row) => _ChatMessage.fromJson(row, myUserId: _currentUserId))
        .toList()
      ..sort(
          (a, b) => b.sentAt.compareTo(a.sentAt)); // sort descending: 0=newest

    if (!mounted) return;

    final shouldScroll = _messages.length != next.length;

    setState(() {
      _messages = next;
      _loading = false;
    });

    if (shouldScroll) _scrollToBottom();
  }

  Future<void> _sendMessage() async {
    final text = _composer.text.trim();
    if (text.isEmpty) return;
    _composer.clear();

    // Haptic feedback
    HapticFeedback.lightImpact();

    // Optimistic UI update
    final tempMsg = _ChatMessage(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      text: text,
      isMine: true,
      sentAt: DateTime.now(),
    );
    setState(() {
      _messages.insert(0, tempMsg);
    });
    _scrollToBottom();

    final success = await ApiService.sendMessage(
      conversationId: widget.conversation.id,
      text: text,
    );
    if (!success) {
      if (!mounted) return;
      setState(() {
        _failedIds.add(tempMsg.id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppL10n.of(context)!.messagesCouldNotSend,
            style: GoogleFonts.nunito(fontWeight: FontWeight.w600),
          ),
          backgroundColor: C.red,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }
    await _loadMessages(hideLoading: true);
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: C.bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded, color: C.text1),
                title: Text(AppL10n.of(context)!.messagesTakePhoto, style: GoogleFonts.nunito(fontWeight: FontWeight.w700, color: C.text1)),
                onTap: () {
                  Navigator.pop(context);
                  _processImagePick(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded, color: C.text1),
                title: Text(AppL10n.of(context)!.messagesChooseGallery, style: GoogleFonts.nunito(fontWeight: FontWeight.w700, color: C.text1)),
                onTap: () {
                  Navigator.pop(context);
                  _processImagePick(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _processImagePick(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: source, imageQuality: 70);
      if (pickedFile == null) return;

      final tempMsg = _ChatMessage(
        id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
        text: '',
        isMine: true,
        sentAt: DateTime.now(),
        imageUrl: pickedFile.path,
      );

      setState(() {
        _messages.insert(0, tempMsg);
      });
      _scrollToBottom();

      final response = await ApiService.sendImageMessage(
        conversationId: widget.conversation.id,
        file: pickedFile,
      );

      if (!mounted) return;

      if (response == null) {
        setState(() {
          _failedIds.add(tempMsg.id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppL10n.of(context)!.messagesCouldNotSendImage, style: GoogleFonts.nunito(fontWeight: FontWeight.w600)),
            backgroundColor: C.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        await _loadMessages(hideLoading: true);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppL10n.of(context)!.messagesErrorSelectingImage(e.toString().replaceAll('Exception: ', '')), style: GoogleFonts.nunito(fontWeight: FontWeight.w600)),
          backgroundColor: C.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(0.0,
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    });
  }

  String _clock(DateTime time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _dateSeparatorLabel(DateTime date) {
    final l = AppL10n.of(context)!;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final msgDay = DateTime(date.year, date.month, date.day);
    final diff = today.difference(msgDay).inDays;

    if (diff == 0) return l.dateToday;
    if (diff == 1) return l.dateYesterday;
    if (diff < 7) {
      final days = [
        l.weekdayFullMonday,
        l.weekdayFullTuesday,
        l.weekdayFullWednesday,
        l.weekdayFullThursday,
        l.weekdayFullFriday,
        l.weekdayFullSaturday,
        l.weekdayFullSunday,
      ];
      return days[date.weekday - 1];
    }

    final months = [
      l.monthJan,
      l.monthFeb,
      l.monthMar,
      l.monthApr,
      l.monthMay,
      l.monthJun,
      l.monthJul,
      l.monthAug,
      l.monthSep,
      l.monthOct,
      l.monthNov,
      l.monthDec,
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  bool _needsDateSeparator(int index) {
    if (index >= _messages.length - 1) return true; // last item (oldest)
    final current = _messages[index].sentAt;
    final next = _messages[index + 1].sentAt; // older message
    return DateTime(current.year, current.month, current.day) !=
        DateTime(next.year, next.month, next.day);
  }

  bool _isGroupedWithPrevious(int index) {
    // index 0 = newest. "previous" in display = index-1 (newer)
    if (index == 0) return false;
    final current = _messages[index];
    final newer = _messages[index - 1];
    if (current.isMine != newer.isMine) return false;
    return newer.sentAt.difference(current.sentAt).inMinutes.abs() < 2;
  }

  void _copyMessage(String text) {
    Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppL10n.of(context)!.messagesCopied,
          style: GoogleFonts.nunito(fontWeight: FontWeight.w600),
        ),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        backgroundColor: C.text1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: const Color(0xFFF5F3F0),
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(68),
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [C.primary, C.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Color(0x22000000),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white, size: 20),
                    ),
                    // Avatar
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.white.withValues(alpha: 0.25),
                          backgroundImage:
                              widget.conversation.avatarUrl != null
                                  ? NetworkImage(
                                      widget.conversation.avatarUrl!)
                                  : null,
                          child: widget.conversation.avatarUrl == null
                              ? Text(
                                  widget.conversation.name.trim().isEmpty
                                      ? '?'
                                      : widget.conversation.name[0]
                                          .toUpperCase(),
                                  style: GoogleFonts.nunito(
                                    color: Colors.white,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w900,
                                  ),
                                )
                              : null,
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: C.green,
                              shape: BoxShape.circle,
                              border:
                                  Border.all(color: C.primaryDark, width: 2),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    // Name + status
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.conversation.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.nunito(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Row(
                            children: [

                              Text(
                                AppL10n.of(context)!.messagesOnline,
                                style: GoogleFonts.nunito(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withValues(alpha: 0.85),
                                ),
                              ),
                              if (widget.conversation.taskTitle != null &&
                                  widget.conversation.taskTitle!
                                      .isNotEmpty) ...[
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 6),
                                  child: Text(
                                    '•',
                                    style: TextStyle(
                                      color:
                                          Colors.white.withValues(alpha: 0.5),
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                                Flexible(
                                  child: Text(
                                    widget.conversation.taskTitle!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.nunito(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color:
                                          Colors.white.withValues(alpha: 0.75),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        body: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusScope.of(context).unfocus(),
          child: Stack(
            children: [
              Column(
                children: [
                  // ── Message List ──
                  Expanded(
                    child: _loading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: C.primary,
                              strokeWidth: 2.5,
                            ),
                          )
                        : _messages.isEmpty
                            ? _buildEmptyChatState()
                            : ListView.builder(
                                reverse: true,
                                controller: _scroll,
                                keyboardDismissBehavior:
                                    ScrollViewKeyboardDismissBehavior.onDrag,
                                padding:
                                    const EdgeInsets.fromLTRB(12, 8, 12, 16),
                                itemCount: _messages.length,
                                itemBuilder: (_, i) {
                                  final message = _messages[i];
                                  final isGrouped = _isGroupedWithPrevious(i);
                                  final showDateSep = _needsDateSeparator(i);
                                  final isTemp = message.id.startsWith('temp_');
                                  final isFailed = _failedIds.contains(message.id);

                                  return Column(
                                    children: [
                                      // Date separator (shown below because list is reversed)
                                      if (showDateSep)
                                        _DateSeparator(
                                          label: _dateSeparatorLabel(
                                              message.sentAt),
                                        ),
                                      // Message bubble
                                      _MessageBubble(
                                        message: message,
                                        clock: _clock(message.sentAt),
                                        isGrouped: isGrouped,
                                        isTemp: isTemp,
                                        isFailed: isFailed,
                                        maxWidth:
                                            MediaQuery.sizeOf(context).width *
                                                0.75,
                                        onLongPress: () =>
                                            _copyMessage(message.text),
                                      ),
                                    ],
                                  );
                                },
                              ),
                  ),

                  // ── Composer Bar (or a "closed" notice once the task is done) ──
                  if (widget.conversation.closed)
                    const _ChatClosedBar()
                  else
                    _ComposerBar(
                      controller: _composer,
                      onSend: _sendMessage,
                      onPickImage: _pickImage,
                    ),
                ],
              ),

              // ── Scroll to bottom FAB ──
              if (_showScrollFab)
                Positioned(
                  right: 16,
                  bottom: 90,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOut,
                    builder: (_, v, child) => Transform.scale(
                      scale: v,
                      child: Opacity(opacity: v, child: child),
                    ),
                    child: FloatingActionButton.small(
                      onPressed: _scrollToBottom,
                      backgroundColor: Colors.white,
                      elevation: 4,
                      shape: const CircleBorder(),
                      child: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: C.text1,
                        size: 24,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );

  Widget _buildEmptyChatState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: C.primaryLight,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: C.primary.withValues(alpha: 0.12),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Center(
                child: Icon(Icons.waving_hand_rounded,
                    size: 44, color: C.primary),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              AppL10n.of(context)!.messagesSayHello,
              style: GoogleFonts.nunito(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: C.text1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppL10n.of(context)!
                  .messagesStartConversation(widget.conversation.name),
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: C.text3,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Date Separator ─────────────────────────────────────────────────────────────

class _DateSeparator extends StatelessWidget {
  final String label;
  const _DateSeparator({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(
              child: Divider(
                  color: Colors.black.withValues(alpha: 0.06), height: 1)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Text(
                label,
                style: GoogleFonts.nunito(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: C.text3,
                ),
              ),
            ),
          ),
          Expanded(
              child: Divider(
                  color: Colors.black.withValues(alpha: 0.06), height: 1)),
        ],
      ),
    );
  }
}

// ─── Message Bubble ─────────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final _ChatMessage message;
  final String clock;
  final bool isGrouped;
  final bool isTemp;
  final bool isFailed;
  final double maxWidth;
  final VoidCallback onLongPress;

  const _MessageBubble({
    required this.message,
    required this.clock,
    required this.isGrouped,
    required this.isTemp,
    required this.isFailed,
    required this.maxWidth,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final isMine = message.isMine;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      builder: (_, v, child) => Transform.translate(
        offset: Offset(0, 12 * (1 - v)),
        child: Opacity(opacity: v, child: child),
      ),
      child: Align(
        alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
        child: GestureDetector(
          onLongPress: onLongPress,
          child: Container(
            margin: EdgeInsets.only(
              top: isGrouped ? 2 : 8,
              left: isMine ? 48 : 0,
              right: isMine ? 0 : 48,
            ),
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: CustomPaint(
              painter: _BubbleTailPainter(
                isMine: isMine,
                showTail: !isGrouped,
                color: isMine ? C.primaryLight : Colors.white,
                borderColor: isMine ? null : C.border,
              ),
              child: Container(
                padding: EdgeInsets.fromLTRB(
                  isMine ? 14 : 16,
                  10,
                  isMine ? 16 : 14,
                  6,
                ),
                margin: EdgeInsets.only(
                  left: isMine ? 0 : 6,
                  right: isMine ? 6 : 0,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (message.imageUrl != null)
                      GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => Dialog(
                              backgroundColor: Colors.transparent,
                              insetPadding: EdgeInsets.zero,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  InteractiveViewer(
                                    child: message.id.startsWith('temp_')
                                        ? Image.file(File(message.imageUrl!))
                                        : Image.network(message.imageUrl!.startsWith('http')
                                            ? message.imageUrl!
                                            : '${ApiService.baseUrl}${message.imageUrl!}'),
                                  ),
                                  Positioned(
                                    top: 40,
                                    right: 20,
                                    child: IconButton(
                                      icon: const Icon(Icons.close, color: Colors.white, size: 30),
                                      onPressed: () => Navigator.pop(context),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: message.id.startsWith('temp_')
                              ? Image.file(
                                  File(message.imageUrl!),
                                  width: maxWidth * 0.8,
                                  fit: BoxFit.cover,
                                )
                              : Image.network(
                                  message.imageUrl!.startsWith('http')
                                      ? message.imageUrl!
                                      : '${ApiService.baseUrl}${message.imageUrl!}',
                                  width: maxWidth * 0.8,
                                  fit: BoxFit.cover,
                                ),
                        ),
                      ),
                    if (message.text.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(top: message.imageUrl != null ? 8.0 : 0),
                        child: Text(
                          message.text,
                          style: GoogleFonts.nunito(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: C.text1,
                            height: 1.4,
                          ),
                        ),
                      ),
                    const SizedBox(height: 3),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          clock,
                          style: GoogleFonts.nunito(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: isMine
                                ? C.primaryDark.withValues(alpha: 0.7)
                                : C.text3,
                          ),
                        ),
                        if (isMine) ...[
                          const SizedBox(width: 3),
                          if (isFailed)
                            Icon(
                              Icons.error_outline_rounded,
                              size: 14,
                              color: Colors.white.withValues(alpha: 0.9),
                            )
                          else if (isTemp)
                            SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.5,
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                            )
                          else
                            Icon(
                              Icons.done_all_rounded,
                              size: 14,
                              color: isFailed
                                  ? C.red
                                  : C.primary.withValues(alpha: 0.9),
                            ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Bubble Tail Painter ────────────────────────────────────────────────────────

class _BubbleTailPainter extends CustomPainter {
  final bool isMine;
  final bool showTail;
  final Color color;
  final Color? borderColor;

  _BubbleTailPainter({
    required this.isMine,
    required this.showTail,
    required this.color,
    this.borderColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    const radius = 16.0;
    const tailW = 8.0;
    const tailH = 10.0;

    final rrect = RRect.fromLTRBAndCorners(
      isMine && showTail ? 0 : 0,
      0,
      size.width,
      size.height,
      topLeft: const Radius.circular(radius),
      topRight: const Radius.circular(radius),
      bottomLeft: Radius.circular(isMine ? radius : (showTail ? 4 : radius)),
      bottomRight: Radius.circular(isMine ? (showTail ? 4 : radius) : radius),
    );

    // Draw border first if needed
    if (borderColor != null) {
      final borderPaint = Paint()
        ..color = borderColor!
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      canvas.drawRRect(rrect, borderPaint);
    }

    canvas.drawRRect(rrect, paint);

    // Draw tail
    if (showTail) {
      final tailPath = Path();
      if (isMine) {
        tailPath.moveTo(size.width - 2, size.height - tailH);
        tailPath.lineTo(size.width + tailW - 2, size.height);
        tailPath.lineTo(size.width - 2, size.height);
      } else {
        tailPath.moveTo(2, size.height - tailH);
        tailPath.lineTo(2 - tailW, size.height);
        tailPath.lineTo(2, size.height);
      }
      tailPath.close();
      canvas.drawPath(tailPath, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BubbleTailPainter oldDelegate) =>
      isMine != oldDelegate.isMine ||
      showTail != oldDelegate.showTail ||
      color != oldDelegate.color;
}

// ─── Composer Bar ───────────────────────────────────────────────────────────────

class _ComposerBar extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onPickImage;

  const _ComposerBar({required this.controller, required this.onSend, required this.onPickImage});

  @override
  State<_ComposerBar> createState() => _ComposerBarState();
}

class _ComposerBarState extends State<_ComposerBar> {
  bool _hasText = false;
  bool _sendPressed = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    final has = widget.controller.text.trim().isNotEmpty;
    if (has != _hasText) setState(() => _hasText = has);
  }

  void _handleSend() {
    setState(() => _sendPressed = true);
    Future.delayed(const Duration(milliseconds: 120), () {
      if (mounted) setState(() => _sendPressed = false);
    });
    widget.onSend();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
        padding: const EdgeInsets.fromLTRB(6, 4, 4, 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: C.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Attachment hint
            IconButton(
              onPressed: widget.onPickImage,
              icon: Icon(
                Icons.add_circle_outline_rounded,
                color: C.text3.withValues(alpha: 0.6),
                size: 24,
              ),
              splashRadius: 20,
            ),
            // Text field
            Expanded(
              child: TextField(
                controller: widget.controller,
                onTapOutside: (_) => FocusScope.of(context).unfocus(),
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.newline,
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: C.text1,
                ),
                decoration: InputDecoration(
                  hintText: AppL10n.of(context)!.messagesTypeHint,
                  hintStyle: GoogleFonts.nunito(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: C.text3,
                  ),
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                ),
              ),
            ),
            // Send button with scale animation
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              width: 42,
              height: 42,
              child: AnimatedScale(
                scale: _sendPressed ? 0.85 : 1.0,
                duration: const Duration(milliseconds: 120),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  decoration: BoxDecoration(
                    gradient: _hasText
                        ? const LinearGradient(
                            colors: [C.primary, C.primaryDark],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : LinearGradient(
                            colors: [
                              C.text3.withValues(alpha: 0.3),
                              C.text3.withValues(alpha: 0.25),
                            ],
                          ),
                    shape: BoxShape.circle,
                    boxShadow: _hasText
                        ? [
                            BoxShadow(
                              color: C.primary.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : [],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _hasText ? _handleSend : null,
                      borderRadius: BorderRadius.circular(21),
                      child: const Center(
                        child: Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Data Models ────────────────────────────────────────────────────────────────

/// Replaces the composer when a chat is closed (task completed/cancelled).
class _ChatClosedBar extends StatelessWidget {
  const _ChatClosedBar();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
          16, 14, 16, 14 + MediaQuery.of(context).padding.bottom),
      decoration: const BoxDecoration(
        color: C.bg,
        border: Border(top: BorderSide(color: C.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.lock_outline_rounded, size: 16, color: C.text3),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              AppL10n.of(context)!.chatClosed,
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                  fontSize: 13, fontWeight: FontWeight.w600, color: C.text3),
            ),
          ),
        ],
      ),
    );
  }
}

class ChatConversation {
  const ChatConversation({
    required this.id,
    required this.name,
    this.avatarUrl,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.unreadCount,
    this.taskTitle,
    this.closed = false,
  });

  final String id;
  final String name;
  final String? avatarUrl;
  final String lastMessage;
  final DateTime lastMessageAt;
  final int unreadCount;
  final String? taskTitle;
  // True once the task is completed/cancelled — the chat is read-only.
  final bool closed;

  factory ChatConversation.fromJson(Map<String, dynamic> json) {
    final task = json['task'] is Map
        ? Map<String, dynamic>.from(json['task'] as Map)
        : <String, dynamic>{};
    final otherUser = json['other_user'] is Map
        ? Map<String, dynamic>.from(json['other_user'] as Map)
        : <String, dynamic>{};
    return ChatConversation(
      id: json['id']?.toString() ?? '',
      name: otherUser['name']?.toString() ?? '',
      avatarUrl:
          (otherUser['avatar_url']?.toString().isNotEmpty ?? false)
              ? otherUser['avatar_url']?.toString()
              : null,
      lastMessage: json['last_message']?.toString() ?? '',
      lastMessageAt:
          DateTime.tryParse(json['last_message_at']?.toString() ?? '') ??
              DateTime.now(),
      unreadCount: (json['unread_count'] as num?)?.toInt() ?? 0,
      taskTitle: task['title']?.toString(),
      closed: json['closed'] == true,
    );
  }
}

class _ChatMessage {
  const _ChatMessage({
    required this.id,
    required this.text,
    required this.isMine,
    required this.sentAt,
    this.imageUrl,
  });

  final String id;
  final String text;
  final bool isMine;
  final DateTime sentAt;
  final String? imageUrl;

  factory _ChatMessage.fromJson(
    Map<String, dynamic> json, {
    required String myUserId,
  }) =>
      _ChatMessage(
        id: json['id']?.toString() ?? '',
        text: json['text']?.toString() ?? '',
        isMine:
            myUserId.isNotEmpty && json['sender_id']?.toString() == myUserId,
        sentAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
            DateTime.now(),
        imageUrl: json['image_url']?.toString(),
      );
}
