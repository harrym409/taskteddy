import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import '../theme/theme.dart';
import '../theme/app_theme.dart';
import '../l10n/app_localizations.dart';
import 'safety.dart';

// ───────────────────────────────────────────────────────────────────────────────
//  CONVERSATIONS LIST SCREEN
// ───────────────────────────────────────────────────────────────────────────────

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _search;
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;
  List<ChatConversation> _conversations = [];
  String _query = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _search = TextEditingController();
    _search.addListener(_onSearchChanged);
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _loadConversations();
  }

  @override
  void dispose() {
    _search.removeListener(_onSearchChanged);
    _search.dispose();
    _fadeCtrl.dispose();
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
    _fadeCtrl.forward(from: 0);
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
      MaterialPageRoute(
        builder: (_) => ChatScreen(conversation: conversation),
      ),
    );
    await _loadConversations();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: T.bg,
        appBar: AppTheme.gradientBar(
          AppL10n.of(context)!.qaMessages,
          leading: Navigator.of(context).canPop()
              ? IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white, size: 20),
                )
              : const SizedBox.shrink(),
        ),
        body: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusScope.of(context).unfocus(),
          child: Column(
            children: [
              // ── Search bar ──
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: T.border),
                    boxShadow: [
                      BoxShadow(
                        color: T.primary.withValues(alpha: 0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _search,
                    onTapOutside: (_) => FocusScope.of(context).unfocus(),
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: T.text1,
                    ),
                    decoration: InputDecoration(
                      hintText: AppL10n.of(context)!.msgSearchChats,
                      hintStyle: GoogleFonts.nunito(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: T.text3,
                      ),
                      prefixIcon:
                          const Icon(Icons.search_rounded, color: T.text3, size: 20),
                      suffixIcon: _query.isEmpty
                          ? null
                          : IconButton(
                              onPressed: _search.clear,
                              icon: const Icon(Icons.close_rounded,
                                  color: T.text3, size: 18),
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

              // ── List / Empty / Loading ──
              Expanded(
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: T.primary,
                          strokeWidth: 2.5,
                        ),
                      )
                    : _filtered.isEmpty
                        ? _buildEmptyState()
                        : RefreshIndicator(
                            onRefresh: _loadConversations,
                            color: T.primary,
                            backgroundColor: Colors.white,
                            displacement: 30,
                            child: FadeTransition(
                              opacity: _fadeAnim,
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
    final l = AppL10n.of(context)!;
    final isSearch = _query.isNotEmpty;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: const BoxDecoration(
                color: T.primaryLight,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(
                isSearch
                    ? Icons.search_off_rounded
                    : Icons.chat_bubble_outline_rounded,
                size: 38,
                color: T.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isSearch ? l.msgNoResults : l.msgNoConversations,
              style: GoogleFonts.nunito(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: T.text1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isSearch
                  ? l.msgTryDifferentSearch
                  : l.msgChatsWillAppear,
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: T.text3,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Conversation Card ───────────────────────────────────────────────────────

class _ConversationCard extends StatefulWidget {
  final ChatConversation conversation;
  final VoidCallback onTap;
  final int index;

  const _ConversationCard({
    required this.conversation,
    required this.onTap,
    required this.index,
  });

  @override
  State<_ConversationCard> createState() => _ConversationCardState();
}

class _ConversationCardState extends State<_ConversationCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  late final Animation<double> _slide;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _slide = Tween<double>(begin: 24, end: 0).animate(
      CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic),
    );
    _opacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _anim, curve: Curves.easeOut),
    );
    Future.delayed(Duration(milliseconds: 60 * widget.index), () {
      if (mounted) _anim.forward();
    });
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.conversation;
    final avatarLetter = c.name.trim().isEmpty ? '?' : c.name[0].toUpperCase();
    final hasUnread = c.unreadCount > 0;

    return AnimatedBuilder(
      listenable: _anim,
      builder: (_, child) => Opacity(
        opacity: _opacity.value,
        child: Transform.translate(
          offset: Offset(0, _slide.value),
          child: child,
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: hasUnread
                ? T.primary.withValues(alpha: 0.35)
                : T.border,
            width: hasUnread ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: (hasUnread ? T.primary : Colors.black)
                  .withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  // ── Avatar with online dot ──
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: T.primaryLight,
                        backgroundImage: c.avatarUrl != null
                            ? NetworkImage(c.avatarUrl!)
                            : null,
                        child: c.avatarUrl == null
                            ? Text(
                                avatarLetter,
                                style: GoogleFonts.nunito(
                                  color: T.primary,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                ),
                              )
                            : null,
                      ),
                      Positioned(
                        bottom: 1,
                        right: 1,
                        child: Container(
                          width: 13,
                          height: 13,
                          decoration: BoxDecoration(
                            color: T.green,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name + Time
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                c.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.nunito(
                                  fontSize: 15,
                                  fontWeight:
                                      hasUnread ? FontWeight.w900 : FontWeight.w800,
                                  color: T.text1,
                                ),
                              ),
                            ),
                            Text(
                              _formatTime(c.lastMessageAt),
                              style: GoogleFonts.nunito(
                                fontSize: 11,
                                color: hasUnread ? T.primary : T.text3,
                                fontWeight:
                                    hasUnread ? FontWeight.w700 : FontWeight.w500,
                              ),
                            ),
                          ],
                        ),

                        // Task badge
                        if (c.taskTitle != null && c.taskTitle!.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: T.primaryLight,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              c.taskTitle!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.nunito(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: T.primary,
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(height: 4),
                        // Last message + unread badge
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                c.lastMessage.isEmpty
                                    ? AppL10n.of(context)!.msgTapToOpen
                                    : c.lastMessage,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.nunito(
                                  fontSize: 13,
                                  color: T.text3,
                                  fontWeight: FontWeight.w600,
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
                                  color: T.primary,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  c.unreadCount.toString(),
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

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${time.day}/${time.month}';
  }
}

// AnimatedBuilder helper (same as AnimatedWidget but with builder pattern)
class AnimatedBuilder extends AnimatedWidget {
  const AnimatedBuilder({
    super.key,
    required super.listenable,
    required this.builder,
    this.child,
  });

  final Widget Function(BuildContext, Widget?) builder;
  final Widget? child;

  Animation<double> get animation => listenable as Animation<double>;

  @override
  Widget build(BuildContext context) => builder(context, child);
}

// ───────────────────────────────────────────────────────────────────────────────
//  CHAT SCREEN
// ───────────────────────────────────────────────────────────────────────────────

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

  // Track failed temp IDs
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
    final show = _scroll.offset > 200;
    if (show != _showScrollFab) {
      setState(() => _showScrollFab = show);
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
          (a, b) => b.sentAt.compareTo(a.sentAt)); // descending: 0 = newest
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
            AppL10n.of(context)!.msgCouldNotSend,
            style: GoogleFonts.nunito(fontWeight: FontWeight.w600),
          ),
          backgroundColor: T.red,
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
            AppL10n.of(context)!.msgCouldNotSend,
            style: GoogleFonts.nunito(fontWeight: FontWeight.w600),
          ),
          backgroundColor: T.red,
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

  // ── Date separator logic ──
  String? _dateLabelBetween(int index) {
    // Messages are sorted descending (index 0 = newest).
    // We show a label ABOVE index i when the date differs from i+1.
    final current = _messages[index].sentAt;
    if (index == _messages.length - 1) return _dateLabel(current);
    final next = _messages[index + 1].sentAt;
    if (!_isSameDay(current, next)) return _dateLabel(current);
    return null;
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _dateLabel(DateTime d) {
    final l = AppL10n.of(context)!;
    final now = DateTime.now();
    if (_isSameDay(d, now)) return l.today;
    final yesterday = now.subtract(const Duration(days: 1));
    if (_isSameDay(d, yesterday)) return l.msgYesterday;
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[d.month - 1]} ${d.day}';
  }

  // ── Message grouping ──
  bool _isGroupedWithPrevious(int index) {
    // "Previous" in display = index + 1 (because list is reversed)
    if (index >= _messages.length - 1) return false;
    final cur = _messages[index];
    final prev = _messages[index + 1];
    if (cur.isMine != prev.isMine) return false;
    if (!_isSameDay(cur.sentAt, prev.sentAt)) return false;
    return cur.sentAt.difference(prev.sentAt).abs() <
        const Duration(minutes: 2);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: T.bg,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(68),
          child: _buildGradientAppBar(),
        ),
        body: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusScope.of(context).unfocus(),
          child: Stack(
            children: [
              Column(
                children: [
                  // ── Messages ──
                  Expanded(
                    child: _loading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: T.primary,
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
                                itemBuilder: (_, i) => _buildMessageItem(i),
                              ),
                  ),

                  // ── Composer bar (or "closed" notice once the task is done) ──
                  if (widget.conversation.closed)
                    const _ChatClosedBar()
                  else
                    _PresetComposer(
                      onSend: _send,
                      onSendLocation: _sendLocation,
                    ),
                ],
              ),

              // ── Scroll-to-bottom FAB ──
              if (_showScrollFab)
                Positioned(
                  right: 16,
                  bottom: 80,
                  child: AnimatedOpacity(
                    opacity: _showScrollFab ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: Material(
                      elevation: 4,
                      shadowColor: T.primary.withValues(alpha: 0.3),
                      shape: const CircleBorder(),
                      color: Colors.white,
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: _scrollToBottom,
                        child: const Padding(
                          padding: EdgeInsets.all(10),
                          child: Icon(Icons.keyboard_arrow_down_rounded,
                              color: T.primary, size: 24),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );

  // ── Gradient App Bar ──
  Widget _buildGradientAppBar() {
    final c = widget.conversation;
    final letter = c.name.trim().isEmpty ? '?' : c.name[0].toUpperCase();
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [T.primaryDark, T.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 68,
          child: Row(
            children: [
              const SizedBox(width: 4),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 4),
              // Avatar with online dot
              Stack(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.white.withValues(alpha: 0.25),
                    backgroundImage:
                        c.avatarUrl != null ? NetworkImage(c.avatarUrl!) : null,
                    child: c.avatarUrl == null
                        ? Text(
                            letter,
                            style: GoogleFonts.nunito(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                            ),
                          )
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: T.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: T.primaryDark, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      c.name,
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
                          AppL10n.of(context)!.statusOnline,
                          style: GoogleFonts.nunito(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                        if (c.taskTitle != null && c.taskTitle!.isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Text(
                              '·',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.5),
                                fontSize: 12,
                              ),
                            ),
                          ),
                          Flexible(
                            child: Text(
                              c.taskTitle!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.nunito(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withValues(alpha: 0.75),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              if ((c.otherUserId ?? '').isNotEmpty)
                SafetyMenuButton(
                  reportedId: c.otherUserId!,
                  reportedName: c.name,
                  taskId: c.taskId,
                  iconColor: Colors.white,
                  onBlocked: () {
                    if (mounted) Navigator.of(context).pop();
                  },
                )
              else
                const SizedBox(width: 12),
            ],
          ),
        ),
      ),
    );
  }

  // ── Empty chat state ──
  Widget _buildEmptyChatState() {
    final l = AppL10n.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: T.primaryLight,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.waving_hand_rounded,
                  size: 36, color: T.primary),
            ),
            const SizedBox(height: 20),
            Text(
              l.msgSayHello,
              style: GoogleFonts.nunito(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: T.text1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l.msgStartConversation,
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: T.text3,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Message item with date separator, grouping, and bubble ──
  Widget _buildMessageItem(int index) {
    final msg = _messages[index];
    final isGrouped = _isGroupedWithPrevious(index);
    final dateLabel = _dateLabelBetween(index);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Date separator
        if (dateLabel != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Text(
                  dateLabel,
                  style: GoogleFonts.nunito(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: T.text3,
                  ),
                ),
              ),
            ),
          ),

        // Message bubble
        _MessageBubble(
          message: msg,
          isGrouped: isGrouped,
          isFailed: _failedIds.contains(msg.id),
          clockText: _clock(msg.sentAt),
        ),
      ],
    );
  }

  // ── Composer bar ──
}

// ─── Preset-only composer ───────────────────────────────────────────────────
// Free-text and photo sending are intentionally removed. Taskers and customers
// coordinate using curated, ready-made messages only, so no one can pass a
// phone number or take the deal off-platform. Tapping a message sends it.

class _PresetCategory {
  final String title;
  final List<String> messages;
  const _PresetCategory(this.title, this.messages);
}

/// Tasker → customer curated messages, grouped by stage of the job.
const List<_PresetCategory> _presetCategories = [
  _PresetCategory('Greeting', [
    'Hi! Thanks for considering my offer.',
    'Hello, I\'m available for this task.',
    'Happy to help with this.',
  ]),
  _PresetCategory('Scheduling', [
    'I can start at the scheduled time.',
    'Are we still on for the scheduled time?',
    'I\'m on my way now.',
    'I\'ll reach shortly.',
    'Could we start a little later?',
  ]),
  _PresetCategory('Task details', [
    'Could you share a bit more detail about the task?',
    'I\'ll bring the required tools.',
    'Do you have the materials, or should I arrange them?',
    'The quoted price covers the full job.',
    'Understood, I\'ll take care of it.',
  ]),
  _PresetCategory('Arrival & location', [
    'Please share the exact location / landmark.',
    'I\'ve arrived at the location.',
    'I\'m at the gate — please guide me in.',
    'Kindly confirm the address in the task.',
  ]),
  _PresetCategory('Confirming', [
    'Sounds good, I\'ll proceed.',
    'Confirmed, see you then.',
    'Thank you for accepting my offer.',
    'Noted, thank you.',
  ]),
  _PresetCategory('During the task', [
    'I\'ve started the work.',
    'Work is going well.',
    'Here\'s an update on the progress.',
    'I\'m almost done.',
  ]),
  _PresetCategory('Wrapping up', [
    'The task is complete.',
    'Please review the work when you can.',
    'Thank you — it was a pleasure working with you!',
    'Kindly mark the task as completed.',
  ]),
  _PresetCategory('Need to discuss', [
    'I\'ve run into a small issue — can we discuss?',
    'This may take a little more time than expected.',
    'Could you clarify this part for me?',
    'Let\'s sort this out together.',
  ]),
];

/// The most-used messages, surfaced as one-tap chips above the picker.
const List<String> _quickPresets = [
  'Hi! Thanks for considering my offer.',
  'I\'m on my way now.',
  'I\'ve arrived at the location.',
  'I\'ve started the work.',
  'The task is complete.',
  'Thank you!',
];

// ─── Fill-in-the-blank presets ──────────────────────────────────────────────
// A preset with ONE typed slot the user fills via a picker (number wheel, time
// or date+time). The slot is never a free-text field, so a phone number or
// email can't be entered — only a bounded value — yet the message stays specific.

enum _SlotType { minutes, hours, amount, time, dateTime }

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

/// Tasker → customer fill-in messages.
const List<_SlotPreset> _slotPresets = [
  _SlotPreset('Share your ETA', 'I\'ll reach in about {}.', _SlotType.minutes,
      min: 5, max: 120, step: 5, init: 15),
  _SlotPreset('I can start at', 'I can start at {}.', _SlotType.time),
  _SlotPreset('I can arrive by', 'I can arrive by {}.', _SlotType.time),
  _SlotPreset('I\'ll be done by', 'I\'ll be done by {}.', _SlotType.time),
  _SlotPreset(
      'Propose a new date & time', 'Can we reschedule to {}?', _SlotType.dateTime),
  _SlotPreset('Let them know a delay', 'I\'m running about {} late.',
      _SlotType.minutes,
      min: 5, max: 90, step: 5, init: 10),
  _SlotPreset('Quote a price', 'The price for this will be ₹{}.',
      _SlotType.amount,
      min: 50, max: 100000, step: 50, init: 500),
  _SlotPreset('Add an extra charge', 'This will cost ₹{} extra.',
      _SlotType.amount,
      min: 50, max: 50000, step: 50, init: 200),
  _SlotPreset('Estimate materials cost', 'Materials will cost around ₹{}.',
      _SlotType.amount,
      min: 50, max: 50000, step: 50, init: 300),
  _SlotPreset(
      'Estimate the time needed', 'This will take about {}.', _SlotType.hours,
      min: 1, max: 12, step: 1, init: 2),
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
                  color: T.border, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 16),
            Text(widget.preset.title,
                style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: T.text1)),
            const SizedBox(height: 6),
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    height: 46,
                    margin: const EdgeInsets.symmetric(horizontal: 44),
                    decoration: BoxDecoration(
                      color: T.primary.withValues(alpha: 0.08),
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
                              color: T.text1),
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
                    backgroundColor: T.primary,
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
                border: Border.all(color: T.primary.withValues(alpha: 0.35)),
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              child: Row(
                children: [
                  Icon(Icons.edit_outlined,
                      size: 17, color: T.primary.withValues(alpha: 0.9)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(text,
                        style: GoogleFonts.nunito(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: T.text1)),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}

// ─── Location sharing ───────────────────────────────────────────────────────
// The tasker can share their current GPS position as a tappable map card
// (e.g. "I've arrived here"). No free-text field is involved, so it can't be
// used to pass a phone number; the backend also re-checks any text. Tapping the
// card opens the device map app for directions.

class _SharedLocation {
  final double lat;
  final double lng;
  final String label;
  final String address;
  const _SharedLocation({
    required this.lat,
    required this.lng,
    required this.label,
    required this.address,
  });

  Map<String, dynamic> toJson() => {
        'lat': lat,
        'lng': lng,
        'label': label,
        'address': address,
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

/// Bottom sheet: share the tasker's current GPS location.
class _LocationPickerSheet extends StatefulWidget {
  const _LocationPickerSheet();

  @override
  State<_LocationPickerSheet> createState() => _LocationPickerSheetState();
}

class _LocationPickerSheetState extends State<_LocationPickerSheet> {
  bool _locating = false;

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
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      );
      if (!mounted) return;
      Navigator.pop(
        context,
        _SharedLocation(
          lat: pos.latitude,
          lng: pos.longitude,
          label: 'My current location',
          address: '',
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _locating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not get your location. Please enable GPS.',
              style: GoogleFonts.nunito(fontWeight: FontWeight.w600)),
          backgroundColor: T.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
                color: T.border, borderRadius: BorderRadius.circular(2)),
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
                      color: T.text1)),
            ),
          ),
          const SizedBox(height: 10),
          ListTile(
            onTap: _locating ? null : _useCurrentLocation,
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                  color: T.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle),
              child: _locating
                  ? const Padding(
                      padding: EdgeInsets.all(10),
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.my_location_rounded, color: T.primary),
            ),
            title: Text('Use my current location',
                style: GoogleFonts.nunito(
                    fontWeight: FontWeight.w800, color: T.text1)),
            subtitle: Text('Let the customer see where you are',
                style: GoogleFonts.nunito(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: T.text3)),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

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
          color: isMine ? Colors.white : T.bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: T.primary.withValues(alpha: 0.25)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 76,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    T.primary.withValues(alpha: 0.16),
                    T.primary.withValues(alpha: 0.07),
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
                        color: T.primary, size: 32),
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
                          color: T.text1)),
                  if (address.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(address,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.nunito(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: T.text3)),
                  ],
                  if (landmark.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text('Near $landmark',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.nunito(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: T.text3)),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.directions_rounded,
                          size: 15, color: T.primary),
                      const SizedBox(width: 4),
                      Text('Open in Maps',
                          style: GoogleFonts.nunito(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: T.primary)),
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

class _MapLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = T.primary.withValues(alpha: 0.12)
      ..strokeWidth = 2;
    for (double x = -size.height; x < size.width; x += 22) {
      canvas.drawLine(
          Offset(x, 0), Offset(x + size.height, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PresetComposer extends StatelessWidget {
  final Future<void> Function(String) onSend;
  final Future<void> Function(_SharedLocation) onSendLocation;
  const _PresetComposer(
      {required this.onSend, required this.onSendLocation});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
              top: BorderSide(color: T.border.withValues(alpha: 0.6))),
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
                      foregroundColor: T.primary,
                      side:
                          BorderSide(color: T.primary.withValues(alpha: 0.4)),
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
                      foregroundColor: T.primary,
                      side:
                          BorderSide(color: T.primary.withValues(alpha: 0.4)),
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
                  color: T.border, borderRadius: BorderRadius.circular(2)),
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
                        color: T.text1)),
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
                      color: T.text3),
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
                            color: T.primary,
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
                              color: T.primary,
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
        color: T.primary.withValues(alpha: 0.08),
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
                      color: T.primaryDark)),
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
          color: T.bg,
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
                            color: T.text1)),
                  ),
                  const SizedBox(width: 10),
                  const Icon(Icons.send_rounded, size: 16, color: T.primary),
                ],
              ),
            ),
          ),
        ),
      );
}

// ─── Message Bubble ──────────────────────────────────────────────────────────

class _MessageBubble extends StatefulWidget {
  final _ChatMessage message;
  final bool isGrouped;
  final bool isFailed;
  final String clockText;

  const _MessageBubble({
    required this.message,
    required this.isGrouped,
    required this.isFailed,
    required this.clockText,
  });

  @override
  State<_MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<_MessageBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  late final Animation<double> _slide;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..forward();
    _slide = Tween<double>(begin: 16, end: 0).animate(
      CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic),
    );
    _opacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _anim, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final msg = widget.message;
    final isMine = msg.isMine;
    final isTemp = msg.id.startsWith('temp_');
    final isFailed = widget.isFailed;
    final topMargin = widget.isGrouped ? 2.0 : 8.0;

    return AnimatedBuilder(
      listenable: _anim,
      builder: (_, child) => Opacity(
        opacity: _opacity.value,
        child: Transform.translate(
          offset: Offset(0, _slide.value),
          child: child,
        ),
      ),
      child: GestureDetector(
        onLongPress: () {
          HapticFeedback.mediumImpact();
          Clipboard.setData(ClipboardData(text: msg.text));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppL10n.of(context)!.msgMessageCopied,
                style: GoogleFonts.nunito(fontWeight: FontWeight.w600),
              ),
              duration: const Duration(seconds: 1),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          );
        },
        child: Align(
          alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: EdgeInsets.only(top: topMargin),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.sizeOf(context).width * 0.75,
            ),
            child: CustomPaint(
              painter: _BubbleTailPainter(
                isMine: isMine,
                color: isMine ? T.primaryLight : Colors.white,
                borderColor: isMine ? null : T.border,
                showTail: !widget.isGrouped,
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
                    if (msg.location != null)
                      _LocationCard(
                          location: msg.location!,
                          isMine: isMine,
                          maxWidth:
                              MediaQuery.sizeOf(context).width * 0.75),
                    if (msg.imageUrl != null)
                      GestureDetector(
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(
                            builder: (_) => Scaffold(
                              backgroundColor: Colors.black,
                              appBar: AppBar(
                                backgroundColor: Colors.black,
                                iconTheme: const IconThemeData(color: Colors.white),
                              ),
                              body: Center(
                                child: InteractiveViewer(
                                  child: isTemp
                                      ? Image.file(File(msg.imageUrl!))
                                      : Image.network(msg.imageUrl!.startsWith('http')
                                          ? msg.imageUrl!
                                          : '${ApiService.baseUrl}${msg.imageUrl!}'),
                                ),
                              ),
                            )
                          ));
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 6.0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: isTemp
                                ? Image.file(File(msg.imageUrl!), fit: BoxFit.cover, height: 200)
                                : Image.network(
                                    msg.imageUrl!.startsWith('http')
                                        ? msg.imageUrl!
                                        : '${ApiService.baseUrl}${msg.imageUrl!}',
                                    fit: BoxFit.cover,
                                    height: 200,
                                  ),
                          ),
                        ),
                      )
                    else
                      Text(
                        msg.text,
                        style: GoogleFonts.nunito(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: T.text1,
                          height: 1.4,
                        ),
                      ),
                    const SizedBox(height: 3),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.clockText,
                          style: GoogleFonts.nunito(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: isMine
                                ? T.primaryDark.withValues(alpha: 0.7)
                                : T.text3,
                          ),
                        ),
                        if (isMine) ...[
                          const SizedBox(width: 4),
                          if (isTemp && !isFailed)
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
                              isFailed
                                  ? Icons.error_outline_rounded
                                  : Icons.done_all_rounded,
                              size: 14,
                              color: isFailed
                                  ? T.red
                                  : T.primary.withValues(alpha: 0.9),
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

// ─── Bubble tail custom painter ──────────────────────────────────────────────

class _BubbleTailPainter extends CustomPainter {
  final bool isMine;
  final Color color;
  final Color? borderColor;
  final bool showTail;

  _BubbleTailPainter({
    required this.isMine,
    required this.color,
    this.borderColor,
    this.showTail = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    const radius = 16.0;
    const tailSize = 6.0;

    // Main bubble rect with rounded corners
    final bubbleLeft = isMine ? 0.0 : tailSize;
    final bubbleRight = isMine ? size.width - tailSize : size.width;
    final bubbleRect = RRect.fromLTRBAndCorners(
      bubbleLeft,
      0,
      bubbleRight,
      size.height,
      topLeft: const Radius.circular(radius),
      topRight: const Radius.circular(radius),
      bottomLeft: Radius.circular(isMine ? radius : (showTail ? 4 : radius)),
      bottomRight: Radius.circular(isMine ? (showTail ? 4 : radius) : radius),
    );

    canvas.drawRRect(bubbleRect, paint);

    // Tail
    if (showTail) {
      final tailPath = Path();
      if (isMine) {
        tailPath.moveTo(bubbleRight, size.height - 8);
        tailPath.lineTo(bubbleRight + tailSize, size.height);
        tailPath.lineTo(bubbleRight, size.height);
        tailPath.close();
      } else {
        tailPath.moveTo(bubbleLeft, size.height - 8);
        tailPath.lineTo(bubbleLeft - tailSize, size.height);
        tailPath.lineTo(bubbleLeft, size.height);
        tailPath.close();
      }
      canvas.drawPath(tailPath, paint);
    }

    // Border for received messages
    if (borderColor != null) {
      final borderPaint = Paint()
        ..color = borderColor!
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      canvas.drawRRect(bubbleRect, borderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _BubbleTailPainter old) =>
      old.isMine != isMine ||
      old.color != color ||
      old.showTail != showTail;
}

// ───────────────────────────────────────────────────────────────────────────────
//  DATA MODELS
// ───────────────────────────────────────────────────────────────────────────────

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
        color: T.bg,
        border: Border(top: BorderSide(color: T.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.lock_outline_rounded, size: 16, color: T.text3),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              AppL10n.of(context)!.chatClosed,
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                  fontSize: 13, fontWeight: FontWeight.w600, color: T.text3),
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
    this.otherUserId,
    this.taskId,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.unreadCount,
    this.taskTitle,
    this.closed = false,
  });

  final String id;
  final String name;
  final String? avatarUrl;
  final String? otherUserId;
  final String? taskId;
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
      otherUserId: otherUser['id']?.toString(),
      taskId: task['id']?.toString(),
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
