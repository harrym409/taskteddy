import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:url_launcher/url_launcher.dart';
import '../l10n/app_localizations.dart';
import '../models/models.dart';
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
    _scroll = ScrollController()..addListener(_onScroll);
    _bootstrap();
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted) _loadMessages(hideLoading: true);
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
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

  Future<void> _send(String rawText) async {
    final text = rawText.trim();
    if (text.isEmpty) return;

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

  Future<void> _sendLocation(_SharedLocation loc) async {
    HapticFeedback.lightImpact();
    final payload = loc.toJson();
    final tempMsg = _ChatMessage(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      text: '',
      isMine: true,
      sentAt: DateTime.now(),
      location: payload,
    );
    setState(() {
      _messages.insert(0, tempMsg);
    });
    _scrollToBottom();

    final success = await ApiService.sendMessage(
      conversationId: widget.conversation.id,
      text: '',
      location: payload,
    );
    if (!success) {
      if (!mounted) return;
      setState(() => _failedIds.add(tempMsg.id));
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
                    _PresetComposer(
                      onSend: _send,
                      onSendLocation: _sendLocation,
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
                    if (message.location != null)
                      _LocationCard(
                          location: message.location!,
                          isMine: isMine,
                          maxWidth: maxWidth),
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

// ─── Preset-only composer ───────────────────────────────────────────────────
// Free-text and photo sending are intentionally removed. Customers and taskers
// coordinate using curated, ready-made messages only, so no one can pass a
// phone number or take the deal off-platform. Tapping a message sends it.

class _PresetCategory {
  final String title;
  final List<String> messages;
  const _PresetCategory(this.title, this.messages);
}

/// Customer → tasker curated messages, grouped by stage of the job.
const List<_PresetCategory> _presetCategories = [
  _PresetCategory('Greeting', [
    'Hi! Thanks for your offer.',
    'Hello, are you available for this task?',
    'Thanks for reaching out.',
  ]),
  _PresetCategory('Scheduling', [
    'When can you start?',
    'Does the scheduled time still work for you?',
    'Please let me know your ETA.',
    'Can we start a little earlier?',
    'Can we reschedule to another time?',
  ]),
  _PresetCategory('Task details', [
    'Could you share how you plan to do this?',
    'Do you have the tools needed for the job?',
    'Should you arrange the materials, or will I?',
    'Is the quoted price final?',
    'Please note the specific instructions in the task.',
  ]),
  _PresetCategory('Arrival & location', [
    'The location is in the task details.',
    'Please message me when you arrive.',
    'Come to the main entrance / gate.',
    'I\'ll guide you once you reach.',
  ]),
  _PresetCategory('Confirming', [
    'Sounds good, let\'s proceed.',
    'Yes, that works for me.',
    'Please go ahead.',
    'I\'ve accepted your offer.',
  ]),
  _PresetCategory('During the task', [
    'How is the work going?',
    'Take your time, no rush.',
    'Could you share a photo of the progress?',
    'Let me know if you need anything.',
  ]),
  _PresetCategory('Wrapping up', [
    'The work looks great, thank you!',
    'Task done — thanks for your help!',
    'I\'ll leave you a review shortly.',
    'Please mark the task as completed.',
  ]),
  _PresetCategory('Need changes', [
    'I have a small concern — can we discuss?',
    'This isn\'t quite what I expected.',
    'Could you please redo this part?',
    'Let\'s sort this out together.',
  ]),
];

/// The most-used messages, surfaced as one-tap chips above the picker.
const List<String> _quickPresets = [
  'Hi! Thanks for your offer.',
  'When can you start?',
  'Please let me know your ETA.',
  'Sounds good, let\'s proceed.',
  'Please message me when you arrive.',
  'Thank you!',
];

// ─── Fill-in-the-blank presets ──────────────────────────────────────────────
// A preset with ONE typed slot the user fills via a picker (number wheel, time
// or date+time). The slot is never a free-text field, so a phone number or
// email can't be entered — only a bounded value — yet the message stays specific.

enum _SlotType { minutes, hours, number, amount, time, dateTime }

class _SlotPreset {
  final String title; // menu label
  final String template; // contains a single "{}" placeholder
  final _SlotType type;
  final int min;
  final int max;
  final int step;
  final int init; // default value the wheel opens on
  const _SlotPreset(
    this.title,
    this.template,
    this.type, {
    this.min = 0,
    this.max = 0,
    this.step = 1,
    this.init = 0,
  });
}

/// Customer → tasker fill-in messages.
const List<_SlotPreset> _slotPresets = [
  _SlotPreset('Suggest a start time', 'Can we start at {}?', _SlotType.time),
  _SlotPreset(
      'Ask them to arrive by', 'Please try to arrive by {}.', _SlotType.time),
  _SlotPreset(
      'Propose a new date & time', 'Can we reschedule to {}?', _SlotType.dateTime),
  _SlotPreset('Share your budget', 'My budget for this is ₹{}.',
      _SlotType.amount,
      min: 50, max: 100000, step: 50, init: 500),
  _SlotPreset('Make an offer', 'Can you do it for ₹{}?', _SlotType.amount,
      min: 50, max: 100000, step: 50, init: 500),
  _SlotPreset(
      'Estimate the time needed', 'This should take about {}.', _SlotType.hours,
      min: 1, max: 12, step: 1, init: 2),
  _SlotPreset('Give a quantity', 'There are about {} items in total.',
      _SlotType.number,
      min: 1, max: 50, step: 1, init: 2),
  _SlotPreset('Tell them to take their time', 'Take up to {}, no rush.',
      _SlotType.minutes,
      min: 5, max: 120, step: 5, init: 15),
];

String _money(int v) {
  final s = v.toString();
  final b = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return b.toString();
}

String _fmtTime(TimeOfDay t) {
  final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
  final m = t.minute.toString().padLeft(2, '0');
  final ap = t.period == DayPeriod.am ? 'AM' : 'PM';
  return '$h:$m $ap';
}

String _fmtDateTime(DateTime d, TimeOfDay t) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  return '${days[d.weekday - 1]}, ${d.day} ${months[d.month - 1]}, ${_fmtTime(t)}';
}

/// Value as it reads inside the sent message (with its unit word).
String _slotValueForMessage(_SlotType type, int v) {
  switch (type) {
    case _SlotType.minutes:
      return '$v minutes';
    case _SlotType.hours:
      return v == 1 ? '1 hour' : '$v hours';
    case _SlotType.amount:
      return _money(v);
    default:
      return '$v';
  }
}

/// Short value label shown on the spinning wheel.
String _wheelLabel(_SlotType type, int v) {
  switch (type) {
    case _SlotType.minutes:
      return '$v min';
    case _SlotType.hours:
      return v == 1 ? '1 hour' : '$v hours';
    case _SlotType.amount:
      return '₹${_money(v)}';
    default:
      return '$v';
  }
}

/// Opens the right picker for a slot preset and returns the finished message
/// (or null if the user cancels).
Future<String?> _resolveSlot(BuildContext context, _SlotPreset p) async {
  switch (p.type) {
    case _SlotType.time:
      final t =
          await showTimePicker(context: context, initialTime: TimeOfDay.now());
      if (t == null) return null;
      return p.template.replaceFirst('{}', _fmtTime(t));
    case _SlotType.dateTime:
      final now = DateTime.now();
      final d = await showDatePicker(
        context: context,
        initialDate: now,
        firstDate: now,
        lastDate: now.add(const Duration(days: 60)),
      );
      if (d == null) return null;
      if (!context.mounted) return null;
      final t =
          await showTimePicker(context: context, initialTime: TimeOfDay.now());
      if (t == null) return null;
      return p.template.replaceFirst('{}', _fmtDateTime(d, t));
    default:
      final v = await showModalBottomSheet<int>(
        context: context,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        builder: (ctx) => _NumberWheelSheet(preset: p),
      );
      if (v == null) return null;
      return p.template.replaceFirst('{}', _slotValueForMessage(p.type, v));
  }
}

class _NumberWheelSheet extends StatefulWidget {
  final _SlotPreset preset;
  const _NumberWheelSheet({required this.preset});

  @override
  State<_NumberWheelSheet> createState() => _NumberWheelSheetState();
}

class _NumberWheelSheetState extends State<_NumberWheelSheet> {
  late final List<int> _values;
  late int _selected;
  late final FixedExtentScrollController _ctrl;

  @override
  void initState() {
    super.initState();
    final p = widget.preset;
    _values = [for (int v = p.min; v <= p.max; v += p.step) v];
    var idx = _values.indexOf(p.init);
    if (idx < 0) idx = 0;
    _selected = _values[idx];
    _ctrl = FixedExtentScrollController(initialItem: idx);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        height: 344,
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: C.border, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 16),
            Text(widget.preset.title,
                style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: C.text1)),
            const SizedBox(height: 6),
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    height: 46,
                    margin: const EdgeInsets.symmetric(horizontal: 44),
                    decoration: BoxDecoration(
                      color: C.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  ListWheelScrollView.useDelegate(
                    controller: _ctrl,
                    itemExtent: 46,
                    perspective: 0.004,
                    diameterRatio: 1.5,
                    physics: const FixedExtentScrollPhysics(),
                    onSelectedItemChanged: (i) {
                      setState(() => _selected = _values[i]);
                      HapticFeedback.selectionClick();
                    },
                    childDelegate: ListWheelChildBuilderDelegate(
                      childCount: _values.length,
                      builder: (_, i) => Center(
                        child: Text(
                          _wheelLabel(widget.preset.type, _values[i]),
                          style: GoogleFonts.nunito(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: C.text1),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, _selected),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: C.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text('Send',
                      style: GoogleFonts.nunito(
                          fontSize: 15, fontWeight: FontWeight.w800)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SlotRow extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  const _SlotRow({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: C.primary.withValues(alpha: 0.35)),
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              child: Row(
                children: [
                  Icon(Icons.edit_outlined,
                      size: 17, color: C.primary.withValues(alpha: 0.9)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(text,
                        style: GoogleFonts.nunito(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: C.text1)),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}

// ─── Location sharing ───────────────────────────────────────────────────────
// The customer can share a pin from their saved address book (or their current
// GPS position) as a tappable map card. No free-text field is involved, so it
// can't be used to smuggle a phone number; the backend also re-checks the
// address text. Tapping the card opens the device map app for directions.

class _SharedLocation {
  final double lat;
  final double lng;
  final String label;
  final String address;
  final String? landmark;
  const _SharedLocation({
    required this.lat,
    required this.lng,
    required this.label,
    required this.address,
    this.landmark,
  });

  Map<String, dynamic> toJson() => {
        'lat': lat,
        'lng': lng,
        'label': label,
        'address': address,
        if (landmark != null && landmark!.isNotEmpty) 'landmark': landmark,
      };
}

Future<void> _openLocationInMaps(Map<String, dynamic> loc) async {
  final lat = (loc['lat'] as num?)?.toDouble();
  final lng = (loc['lng'] as num?)?.toDouble();
  if (lat == null || lng == null) return;
  final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng');
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

/// Bottom sheet: pick a saved address or the current GPS location to share.
class _LocationPickerSheet extends StatefulWidget {
  const _LocationPickerSheet();

  @override
  State<_LocationPickerSheet> createState() => _LocationPickerSheetState();
}

class _LocationPickerSheetState extends State<_LocationPickerSheet> {
  List<AddressModel> _addresses = [];
  bool _loading = true;
  bool _locating = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final rows = await ApiService.getAddresses();
      if (!mounted) return;
      setState(() {
        _addresses = rows.where((a) => a.latitude != null && a.longitude != null).toList();
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _locating = true);
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        throw Exception('Location permission denied');
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      String address = '';
      try {
        final marks = await placemarkFromCoordinates(pos.latitude, pos.longitude);
        if (marks.isNotEmpty) {
          final p = marks.first;
          address = [
            p.name,
            p.subLocality,
            p.locality,
            p.administrativeArea,
          ].where((s) => s != null && s.trim().isNotEmpty).join(', ');
        }
      } catch (_) {}
      if (!mounted) return;
      Navigator.pop(
        context,
        _SharedLocation(
          lat: pos.latitude,
          lng: pos.longitude,
          label: 'Current location',
          address: address,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _locating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not get your location. Please enable GPS.',
              style: GoogleFonts.nunito(fontWeight: FontWeight.w600)),
          backgroundColor: C.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: C.border, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Text('Share a location',
                    style: GoogleFonts.poppins(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: C.text1)),
              ),
            ),
            const SizedBox(height: 10),
            // Use current location
            ListTile(
              onTap: _locating ? null : _useCurrentLocation,
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                    color: C.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle),
                child: _locating
                    ? const Padding(
                        padding: EdgeInsets.all(10),
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.my_location_rounded, color: C.primary),
              ),
              title: Text('Use my current location',
                  style: GoogleFonts.nunito(
                      fontWeight: FontWeight.w800, color: C.text1)),
              subtitle: Text('Share where you are right now',
                  style: GoogleFonts.nunito(
                      fontSize: 12, fontWeight: FontWeight.w600, color: C.text3)),
            ),
            const Divider(height: 1),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _addresses.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              'No saved addresses with a pin yet.\nAdd one in your profile to share it here.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.nunito(
                                  fontWeight: FontWeight.w600, color: C.text3),
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: _addresses.length,
                          separatorBuilder: (_, __) =>
                              const Divider(height: 1, indent: 70),
                          itemBuilder: (context, i) {
                            final a = _addresses[i];
                            return ListTile(
                              onTap: () => Navigator.pop(
                                context,
                                _SharedLocation(
                                  lat: a.latitude!,
                                  lng: a.longitude!,
                                  label: a.label,
                                  address: a.address,
                                  landmark: a.landmark,
                                ),
                              ),
                              leading: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                    color: C.primary.withValues(alpha: 0.1),
                                    shape: BoxShape.circle),
                                child: Icon(_addressIcon(a.label),
                                    color: C.primary, size: 20),
                              ),
                              title: Text(a.label,
                                  style: GoogleFonts.nunito(
                                      fontWeight: FontWeight.w800,
                                      color: C.text1)),
                              subtitle: Text(
                                a.address,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.nunito(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: C.text3),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _addressIcon(String label) {
    switch (label.toLowerCase()) {
      case 'home':
        return Icons.home_rounded;
      case 'work':
        return Icons.work_rounded;
      default:
        return Icons.location_on_rounded;
    }
  }
}

class _PresetComposer extends StatelessWidget {
  final Future<void> Function(String) onSend;
  final Future<void> Function(_SharedLocation) onSendLocation;
  const _PresetComposer({required this.onSend, required this.onSendLocation});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
              top: BorderSide(color: C.border.withValues(alpha: 0.6))),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _quickPresets.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) => _PresetChip(
                  text: _quickPresets[i],
                  onTap: () => onSend(_quickPresets[i]),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _shareLocation(context),
                    icon: const Icon(Icons.location_on_outlined, size: 18),
                    label: Text(
                      'Location',
                      style: GoogleFonts.nunito(fontWeight: FontWeight.w800),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: C.primary,
                      side:
                          BorderSide(color: C.primary.withValues(alpha: 0.4)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _openPicker(context),
                    icon: const Icon(Icons.forum_outlined, size: 18),
                    label: Text(
                      'More messages',
                      style: GoogleFonts.nunito(fontWeight: FontWeight.w800),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: C.primary,
                      side:
                          BorderSide(color: C.primary.withValues(alpha: 0.4)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _shareLocation(BuildContext context) async {
    final loc = await showModalBottomSheet<_SharedLocation>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => const _LocationPickerSheet(),
    );
    if (loc != null) onSendLocation(loc);
  }

  void _openPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.72,
        minChildSize: 0.45,
        maxChildSize: 0.92,
        builder: (ctx, scroll) => Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: C.border, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Choose a message',
                    style: GoogleFonts.poppins(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: C.text1)),
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'To keep everyone safe, chat uses ready-made messages.',
                  style: GoogleFonts.nunito(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: C.text3),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: ListView(
                controller: scroll,
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(2, 8, 2, 8),
                    child: Text('FILL IN THE DETAILS',
                        style: GoogleFonts.poppins(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            color: C.primary,
                            letterSpacing: 0.5)),
                  ),
                  ..._slotPresets.map((p) => _SlotRow(
                        text: p.template.replaceFirst('{}', '_____'),
                        onTap: () async {
                          Navigator.pop(ctx);
                          final msg = await _resolveSlot(context, p);
                          if (msg != null) onSend(msg);
                        },
                      )),
                  for (final cat in _presetCategories) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(2, 14, 2, 8),
                      child: Text(cat.title.toUpperCase(),
                          style: GoogleFonts.poppins(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              color: C.primary,
                              letterSpacing: 0.5)),
                    ),
                    ...cat.messages.map((m) => _PresetRow(
                          text: m,
                          onTap: () {
                            Navigator.pop(ctx);
                            onSend(m);
                          },
                        )),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  const _PresetChip({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) => Material(
        color: C.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            child: Center(
              child: Text(text,
                  style: GoogleFonts.nunito(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: C.primaryDark)),
            ),
          ),
        ),
      );
}

class _PresetRow extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  const _PresetRow({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Material(
          color: C.bg,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              child: Row(
                children: [
                  Expanded(
                    child: Text(text,
                        style: GoogleFonts.nunito(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: C.text1)),
                  ),
                  const SizedBox(width: 10),
                  const Icon(Icons.send_rounded, size: 16, color: C.primary),
                ],
              ),
            ),
          ),
        ),
      );
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

/// A tappable location bubble — shows the shared pin and opens the map app.
class _LocationCard extends StatelessWidget {
  final Map<String, dynamic> location;
  final bool isMine;
  final double maxWidth;
  const _LocationCard({
    required this.location,
    required this.isMine,
    required this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    final label = (location['label'] ?? 'Location').toString();
    final address = (location['address'] ?? '').toString();
    final landmark = (location['landmark'] ?? '').toString();
    return GestureDetector(
      onTap: () => _openLocationInMaps(location),
      child: Container(
        width: maxWidth * 0.72,
        decoration: BoxDecoration(
          color: isMine ? Colors.white : C.bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: C.primary.withValues(alpha: 0.25)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Faux map strip with a pin — no external tiles, fully offline.
            Container(
              height: 76,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    C.primary.withValues(alpha: 0.16),
                    C.primary.withValues(alpha: 0.07),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(painter: _MapLinesPainter()),
                  ),
                  const Center(
                    child: Icon(Icons.location_on,
                        color: C.primary, size: 32),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: GoogleFonts.nunito(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: C.text1)),
                  if (address.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(address,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.nunito(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: C.text3)),
                  ],
                  if (landmark.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text('Near $landmark',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.nunito(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: C.text3)),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.directions_rounded,
                          size: 15, color: C.primary),
                      const SizedBox(width: 4),
                      Text('Open in Maps',
                          style: GoogleFonts.nunito(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: C.primary)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Subtle criss-cross "streets" behind the pin so the card reads as a map.
class _MapLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = C.primary.withValues(alpha: 0.12)
      ..strokeWidth = 2;
    for (double x = -size.height; x < size.width; x += 22) {
      canvas.drawLine(Offset(x, 0), Offset(x + size.height, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ChatMessage {
  const _ChatMessage({
    required this.id,
    required this.text,
    required this.isMine,
    required this.sentAt,
    this.imageUrl,
    this.location,
  });

  final String id;
  final String text;
  final bool isMine;
  final DateTime sentAt;
  final String? imageUrl;
  final Map<String, dynamic>? location;

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
        location: json['location'] is Map
            ? Map<String, dynamic>.from(json['location'] as Map)
            : null,
      );
}
