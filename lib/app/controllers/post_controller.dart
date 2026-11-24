import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../data/models.dart';
import '../routes/app_routes.dart';
import '../services/api_service.dart';
import '../services/session_service.dart';
import 'home_controller.dart';

class PostController extends GetxController {
  final posts = <PostModel>[].obs;
  final followers = <FollowerModel>[].obs;
  final isLoading = false.obs;
  final isUploading = false.obs;

  // Upload-post form
  final descCtrl = TextEditingController();

  ApiService get _api => Get.find<ApiService>();
  SessionService get _session => Get.find<SessionService>();
  int get _uid => _session.userId ?? 0;

  @override
  void onInit() {
    super.onInit();
    loadFeed();
    loadFollowing();
  }

  // ------------------------------------------------------------- feed
  Future<void> loadFeed() async {
    isLoading.value = true;
    try {
      final list = await _api.getPosts(viewerId: _session.userId);
      posts.value =
          list.map((e) => PostModel.fromJson(Map<String, dynamic>.from(e))).toList();
    } catch (_) {
      // keep existing on failure
    } finally {
      isLoading.value = false;
    }
  }

  /// The logged-in user's "Following" list — drives the stories strip.
  Future<void> loadFollowing() async {
    final uid = _session.userId;
    if (uid == null) return;
    try {
      final list = await _api.getFollowing('$uid', viewerId: uid);
      followers.value = list.map((e) {
        final j = Map<String, dynamic>.from(e);
        return FollowerModel(
          id: '${j['id'] ?? ''}',
          name: (j['full_name'] ?? '').toString(),
          avatar: (j['profile_image']?.toString().isNotEmpty ?? false)
              ? j['profile_image'].toString()
              : 'https://ui-avatars.com/api/?name=User&background=D4A853&color=fff',
          city: (j['city'] ?? '').toString(),
        );
      }).toList();
    } catch (_) {
      followers.clear();
    }
  }

  // ------------------------------------------------------------- like
  Future<void> toggleLike(String postId) async {
    final i = posts.indexWhere((p) => p.id == postId);
    if (i == -1) return;
    final p = posts[i];
    // optimistic
    final wasLiked = p.liked;
    p.liked = !wasLiked;
    p.likeCount += p.liked ? 1 : -1;
    posts.refresh();
    try {
      final res = await _api.toggleLike(postId, _uid);
      p.liked = res['liked'] == true;
      p.likeCount = int.tryParse('${res['like_count']}') ?? p.likeCount;
      posts.refresh();
    } catch (_) {
      // revert
      p.liked = wasLiked;
      p.likeCount += wasLiked ? 1 : -1;
      posts.refresh();
    }
  }

  // ----------------------------------------------------------- follow
  Future<void> toggleFollow(String postId) async {
    final i = posts.indexWhere((p) => p.id == postId);
    if (i == -1) return;
    final target = int.tryParse(posts[i].userId) ?? 0;
    final willFollow = !posts[i].following;
    try {
      if (willFollow) {
        await _api.follow(_uid, target);
      } else {
        await _api.unfollow(_uid, target);
      }
      // update every post by that author
      for (final p in posts) {
        if (p.userId == posts[i].userId) p.following = willFollow;
      }
      posts.refresh();
      loadFollowing(); // keep the stories strip in sync
      Get.snackbar(
        willFollow ? 'Followed' : 'Unfollowed',
        '${willFollow ? 'You are now following' : 'You unfollowed'} ${posts[i].userName}',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 1),
      );
    } catch (_) {
      Get.snackbar('Failed', 'Could not update follow status',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  // --------------------------------------------------------- comments
  /// Loads comments for a post into post.comments and returns them.
  Future<List<CommentModel>> fetchComments(String postId) async {
    try {
      final list = await _api.getComments(postId);
      final comments =
          list.map((e) => CommentModel.fromJson(Map<String, dynamic>.from(e))).toList();
      final i = posts.indexWhere((p) => p.id == postId);
      if (i != -1) {
        posts[i].comments
          ..clear()
          ..addAll(comments);
        posts[i].commentCount = comments.length;
        posts.refresh();
      }
      return comments;
    } catch (_) {
      return [];
    }
  }

  Future<bool> addComment(String postId, String text) async {
    if (text.trim().isEmpty) return false;
    try {
      await _api.addComment(postId, _uid, text.trim());
      final i = posts.indexWhere((p) => p.id == postId);
      if (i != -1) {
        final u = _session.user;
        posts[i].comments.add(CommentModel(
              id: 'c${DateTime.now().microsecondsSinceEpoch}',
              userName: u?.name ?? 'You',
              userAvatar: u?.avatar ?? '',
              text: text.trim(),
              time: DateTime.now(),
            ));
        posts[i].commentCount = posts[i].comments.length;
        posts.refresh();
      }
      return true;
    } catch (_) {
      Get.snackbar('Failed', 'Could not post comment',
          snackPosition: SnackPosition.BOTTOM);
      return false;
    }
  }

  // ----------------------------------------------------------- upload
  Future<void> uploadPost({
    required List<File> media,
    required String description,
  }) async {
    if (media.isEmpty && description.trim().isEmpty) {
      Get.snackbar('Empty', 'Add a description or media',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    if (_uid == 0) {
      Get.snackbar('Not logged in', 'Please log in again',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    isUploading.value = true;
    try {
      await _api.uploadPost(userId: _uid, description: description.trim(), media: media);
      await loadFeed();
      descCtrl.clear();
      // Success -> Post home (feed tab).
      if (Get.isRegistered<HomeController>()) {
        Get.find<HomeController>().changeTab(1); // 0=Data,1=Post,2=Profile
      }
      Get.until((route) => Get.currentRoute == AppRoutes.home);
      Get.snackbar('Posted', 'Your post has been published 🎉',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white);
    } on ApiException catch (e) {
      if (e.statusCode == 403) {
        // No premium access -> do NOT upload; send the user to Add Shop.
        Get.snackbar('Premium Access Required',
            'List at least one shop on the portal to unlock posting.',
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 2));
        Get.offNamed(AppRoutes.addShop);
      } else {
        Get.snackbar('Upload failed', e.message, snackPosition: SnackPosition.BOTTOM);
      }
    } catch (_) {
      Get.snackbar('Network error', 'Could not upload post',
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isUploading.value = false;
    }
  }

  PostModel? findPost(String id) {
    final i = posts.indexWhere((p) => p.id == id);
    return i == -1 ? null : posts[i];
  }

  /// Local-only edit (backend edit endpoint not implemented yet).
  void editPost(String id, String desc, List<PostMediaItem> media) {
    final i = posts.indexWhere((p) => p.id == id);
    if (i == -1) return;
    posts[i].description = desc;
    posts[i].media = media;
    posts.refresh();
    Get.snackbar('Updated', 'Post updated', snackPosition: SnackPosition.BOTTOM);
  }

  /// Local-only delete (backend delete endpoint not implemented yet).
  void deletePost(String id) {
    posts.removeWhere((p) => p.id == id);
    Get.snackbar('Deleted', 'Post removed', snackPosition: SnackPosition.BOTTOM);
  }

  @override
  void onClose() {
    descCtrl.dispose();
    super.onClose();
  }
}
