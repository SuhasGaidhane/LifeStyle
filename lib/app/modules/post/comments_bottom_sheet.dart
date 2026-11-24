import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../controllers/post_controller.dart';
import '../../data/models.dart';
import '../../services/session_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class CommentsBottomSheet extends StatefulWidget {
  final PostModel post;
  const CommentsBottomSheet({super.key, required this.post});

  /// Opens the comments bottom sheet.
  static Future<void> show(BuildContext context, PostModel post) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.55),
      builder: (_) => CommentsBottomSheet(post: post),
    );
  }

  @override
  State<CommentsBottomSheet> createState() => _CommentsBottomSheetState();
}

class _CommentsBottomSheetState extends State<CommentsBottomSheet> {
  late final TextEditingController _textCtrl;
  late final FocusNode _focusNode;
  late final ScrollController _scrollCtrl;
  PostController? _postCtrl;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _textCtrl = TextEditingController();
    _focusNode = FocusNode();
    _scrollCtrl = ScrollController();
    if (Get.isRegistered<PostController>()) {
      _postCtrl = Get.find<PostController>();
    }
    // Load latest comments from the backend into THIS post instance.
    _reload();
    _focusNode.addListener(() {
      if (mounted) setState(() {});
    });
  }

  /// Pulls comments from the API and binds them to the rendered post.
  Future<void> _reload() async {
    final list = await _postCtrl?.fetchComments(widget.post.id) ?? const [];
    widget.post.comments
      ..clear()
      ..addAll(list);
    widget.post.commentCount = widget.post.comments.length;
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _focusNode.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty || _sending) return;

    HapticFeedback.lightImpact();
    setState(() => _sending = true);

    // Persist via the backend, then reload so THIS post shows the comment.
    await _postCtrl?.addComment(widget.post.id, text);
    await _reload();

    _textCtrl.clear();
    _focusNode.unfocus();

    if (!mounted) return;
    setState(() => _sending = false);

    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    }
  }

  String _timeAgo(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inSeconds < 60) return '${d.inSeconds}s';
    if (d.inMinutes < 60) return '${d.inMinutes}m';
    if (d.inHours < 24) return '${d.inHours}h';
    if (d.inDays < 7) return '${d.inDays}d';
    return '${(d.inDays / 7).floor()}w';
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final maxH = mq.size.height * 0.88;
    final keyboardInset = mq.viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: keyboardInset),
      child: Container(
        constraints: BoxConstraints(maxHeight: maxH),
        decoration: const BoxDecoration(
          color: AppColors.bg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 24,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Grabber
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 8),
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.cardBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 14, 10),
              child: Row(
                children: [
                  Text(
                    'Comments',
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      height: 1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: AppTheme.goldBadgeDecoration(radius: 30),
                    child: Text(
                      '${widget.post.commentCount}',
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.gold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.card,
                        border: Border.all(
                            color: AppColors.cardBorder, width: 0.6),
                      ),
                      child: const Icon(Icons.close,
                          size: 16, color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),

            // Gold divider
            Container(
              height: 1,
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  AppColors.cardBorder.withOpacity(0),
                  AppColors.goldLight.withOpacity(0.5),
                  AppColors.cardBorder.withOpacity(0),
                ]),
              ),
            ),

            // Comments list / empty state
            Flexible(
              child: widget.post.comments.isEmpty
                  ? const _EmptyComments()
                  : ListView.builder(
                controller: _scrollCtrl,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: widget.post.comments.length,
                itemBuilder: (_, i) {
                  final cm = widget.post.comments[i];
                  return _CommentTile(
                    comment: cm,
                    timeAgo: _timeAgo(cm.time),
                  );
                },
              ),
            ),

            // Input bar
            _InputBar(
              textCtrl: _textCtrl,
              focusNode: _focusNode,
              sending: _sending,
              onSend: _send,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// COMMENT TILE (no like, no reply — just username + text + time)
// ─────────────────────────────────────────────────────────────────────────────
class _CommentTile extends StatelessWidget {
  final CommentModel comment;
  final String timeAgo;
  const _CommentTile({required this.comment, required this.timeAgo});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(1.5),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [AppColors.goldLight, AppColors.goldDim],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Container(
              padding: const EdgeInsets.all(1.5),
              decoration: const BoxDecoration(
                color: AppColors.bg,
                shape: BoxShape.circle,
              ),
              child: SafeNetworkImage(
                url: comment.userAvatar,
                width: 32,
                height: 32,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.dmSans(
                      fontSize: 12.5,
                      color: AppColors.textPrimary,
                      height: 1.4,
                    ),
                    children: [
                      TextSpan(
                        text: '${comment.userName}  ',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      TextSpan(
                        text: comment.text,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  timeAgo,
                  style: GoogleFonts.dmSans(
                    fontSize: 10,
                    color: AppColors.textMuted,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// INPUT BAR
// ─────────────────────────────────────────────────────────────────────────────
class _InputBar extends StatelessWidget {
  final TextEditingController textCtrl;
  final FocusNode focusNode;
  final bool sending;
  final VoidCallback onSend;

  const _InputBar({
    required this.textCtrl,
    required this.focusNode,
    required this.sending,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    final safeBottom =
    keyboardOpen ? 10.0 : MediaQuery.of(context).padding.bottom + 10;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.bg,
        border: Border(
          top: BorderSide(
            color: AppColors.cardBorder.withOpacity(0.6),
            width: 0.6,
          ),
        ),
      ),
      padding: EdgeInsets.fromLTRB(14, 10, 14, safeBottom),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            padding: const EdgeInsets.all(1.5),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [AppColors.goldLight, AppColors.goldDim],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeNetworkImage(
              url: Get.find<SessionService>().user?.avatar ?? '',
              width: 30,
              height: 30,
              borderRadius: BorderRadius.circular(15),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              constraints: const BoxConstraints(
                  minHeight: 42, maxHeight: 80),
              decoration: BoxDecoration(
                // color: AppColors.card,
                borderRadius: BorderRadius.circular(22),
                // border: Border.all(
                //   color: focusNode.hasFocus
                //       ? AppColors.goldLight.withOpacity(0.6)
                //       : AppColors.cardBorder,
                //   width: 1,
                // ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: TextField(

                  controller: textCtrl,
                  focusNode: focusNode,
                  maxLines: null,
                  minLines: 2,
                  textCapitalization: TextCapitalization.sentences,
                  cursorColor: AppColors.gold,
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Add a comment...',
                    hintStyle: GoogleFonts.dmSans(
                      fontSize: 13,
                      color: AppColors.textMuted,
                    ),
                    border: InputBorder.none,
                    isCollapsed: true,
                    contentPadding:
                    const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: textCtrl,
            builder: (_, v, __) {
              final enabled = v.text.trim().isNotEmpty && !sending;
              return GestureDetector(
                onTap: enabled ? onSend : null,
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: enabled
                        ? const LinearGradient(
                      colors: [
                        AppColors.goldLight,
                        AppColors.goldDim
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                        : null,
                    color: enabled ? null : AppColors.card,
                    border: enabled
                        ? null
                        : Border.all(
                        color: AppColors.cardBorder, width: 1),
                    boxShadow: enabled
                        ? [
                      BoxShadow(
                        color: AppColors.gold.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 3),
                      ),
                    ]
                        : null,
                  ),
                  child: sending
                      ? const Center(
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: Colors.white,
                      ),
                    ),
                  )
                      : Icon(
                    Icons.send_rounded,
                    color: enabled
                        ? Colors.white
                        : AppColors.textMuted,
                    size: 18,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EMPTY STATE
// ─────────────────────────────────────────────────────────────────────────────
class _EmptyComments extends StatelessWidget {
  const _EmptyComments();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 240,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      AppColors.goldBg,
                      AppColors.goldLight.withOpacity(0.08),
                    ],
                  ),
                  border: Border.all(
                    color: AppColors.goldLight.withOpacity(0.45),
                    width: 1,
                  ),
                ),
                child: const Icon(Icons.mode_comment_outlined,
                    size: 30, color: AppColors.gold),
              ),
              const SizedBox(height: 14),
              Text(
                'No comments yet',
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Be the first to share your thoughts.',
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                  fontSize: 11.5,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}