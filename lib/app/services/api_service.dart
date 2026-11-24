import 'dart:convert';
import 'dart:io';

import 'package:get/get.dart' hide FormData, MultipartFile, Response;
import 'package:http/http.dart' as http;

import '../data/api_config.dart';

/// Thrown when the backend replies with `success: false` or a non-2xx code.
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, {this.statusCode});
  @override
  String toString() => message;
}

/// Thin wrapper around the PHP REST API.
/// Every method returns the decoded `data` field of the `{success,message,data}`
/// envelope, or throws [ApiException] with the server message.
class ApiService extends GetxService {
  final String _base = ApiConfig.baseUrl;
  final Duration _timeout = const Duration(seconds: 25);

  Map<String, String> get _jsonHeaders => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  // ---------------------------------------------------------------- core
  dynamic _handle(http.Response res) {
    dynamic body;
    try {
      body = jsonDecode(res.body);
    } catch (_) {
      throw ApiException('Unexpected server response', statusCode: res.statusCode);
    }
    final ok = body is Map && body['success'] == true;
    if (res.statusCode >= 200 && res.statusCode < 300 && ok) {
      return body['data'];
    }
    final msg = (body is Map && body['message'] != null)
        ? body['message'].toString()
        : 'Request failed (${res.statusCode})';
    throw ApiException(msg, statusCode: res.statusCode);
  }

  Future<dynamic> _get(String path, {Map<String, dynamic>? query}) async {
    final uri = Uri.parse('$_base$path').replace(
      queryParameters: query?.map((k, v) => MapEntry(k, '$v')),
    );
    final res = await http.get(uri, headers: _jsonHeaders).timeout(_timeout);
    return _handle(res);
  }

  Future<dynamic> _post(String path, Map<String, dynamic> body) async {
    final res = await http
        .post(Uri.parse('$_base$path'),
            headers: _jsonHeaders, body: jsonEncode(body))
        .timeout(_timeout);
    return _handle(res);
  }

  Future<dynamic> _put(String path, Map<String, dynamic> body) async {
    final res = await http
        .put(Uri.parse('$_base$path'),
            headers: _jsonHeaders, body: jsonEncode(body))
        .timeout(_timeout);
    return _handle(res);
  }

  // ---------------------------------------------------------------- auth
  Future<Map<String, dynamic>> sendOtp(String mobile) async =>
      Map<String, dynamic>.from(await _post('/auth/send-otp', {'mobile_number': mobile}));

  Future<Map<String, dynamic>> resendOtp(String mobile) async =>
      Map<String, dynamic>.from(await _post('/auth/resend-otp', {'mobile_number': mobile}));

  /// Returns the verified user map on success.
  Future<Map<String, dynamic>> verifyOtp(String mobile, String otp) async {
    final data = await _post('/auth/verify-otp', {
      'mobile_number': mobile,
      'otp': otp,
    });
    return Map<String, dynamic>.from(data['user']);
  }

  // ------------------------------------------------------------- services
  /// data: { user_id, premium_access, services: { premium:[], free:[] } }
  Future<Map<String, dynamic>> getServices(
      {int? userId, bool includeInactive = false}) async {
    final data = await _get('/services', query: {
      if (userId != null) 'user_id': userId,
      if (includeInactive) 'include_inactive': 1,
    });
    return Map<String, dynamic>.from(data);
  }

  // ---------------------------------------------------------------- shops
  Future<List<dynamic>> getShops({
    String? service,
    int? serviceId,
    String? state,
    String? city,
    int? userId,
    String? q,
    bool includeInactive = false,
    int? isActive,
  }) async {
    final data = await _get('/shops', query: {
      if (service != null) 'service': service,
      if (serviceId != null) 'service_id': serviceId,
      if (state != null && state != 'All') 'state': state,
      if (city != null && city != 'All') 'city': city,
      if (userId != null) 'user_id': userId,
      if (q != null && q.isNotEmpty) 'q': q,
      if (includeInactive) 'include_inactive': 1,
      if (isActive != null) 'is_active': isActive,
    });
    return List<dynamic>.from(data);
  }

  Future<Map<String, dynamic>> getShopDetail(String id) async =>
      Map<String, dynamic>.from(await _get('/shops/$id'));

  /// States (and their cities) that actually have shops for a service.
  Future<Map<String, dynamic>> getShopFacets(int serviceId) async =>
      Map<String, dynamic>.from(await _get('/shops/facets', query: {'service_id': serviceId}));

  /// Creates the shop under each selected service (one row per service_id).
  Future<Map<String, dynamic>> createShop(Map<String, dynamic> body) async =>
      Map<String, dynamic>.from(await _post('/shops', body));

  /// Server-computed listing price for `count` services.
  Future<Map<String, dynamic>> getShopPricing({required int userId, required int count}) async =>
      Map<String, dynamic>.from(
          await _get('/shops/pricing', query: {'user_id': userId, 'count': count}));

  /// Admin-configurable pricing: { first_shop_price, additional_shop_price, currency }
  Future<Map<String, dynamic>> getPricingSettings() async =>
      Map<String, dynamic>.from(await _get('/pricing-settings'));

  Future<Map<String, dynamic>> updatePricingSettings(Map<String, dynamic> body) async =>
      Map<String, dynamic>.from(await _put('/pricing-settings', body));

  /// Update core shop details (name, mobiles, address, lat/long, description...).
  Future<Map<String, dynamic>> updateShop(String id, Map<String, dynamic> body) async =>
      Map<String, dynamic>.from(await _put('/shops/$id', body));

  /// Adds a sub-resource with an uploaded file.
  ///   type: 'images' | 'products' | 'latest-updates' | 'clients'
  ///   fileField: 'image' for images/products/clients, 'media' for latest-updates
  Future<Map<String, dynamic>> addShopChild(
    String shopId,
    String type, {
    required String fileField,
    File? file,
    Map<String, String> fields = const {},
  }) async {
    final req = http.MultipartRequest('POST', Uri.parse('$_base/shops/$shopId/$type'));
    req.fields.addAll(fields);
    if (file != null) {
      req.files.add(await http.MultipartFile.fromPath(fileField, file.path));
    }
    final streamed = await req.send().timeout(const Duration(seconds: 120));
    final res = await http.Response.fromStream(streamed);
    return Map<String, dynamic>.from(_handle(res));
  }

  /// Deletes a shop sub-resource row.
  Future<void> deleteShopChild(String shopId, String type, String childId) async {
    final res = await http
        .delete(Uri.parse('$_base/shops/$shopId/$type/$childId'), headers: _jsonHeaders)
        .timeout(_timeout);
    _handle(res);
  }

  // ----------------------------------------------------------------- posts
  Future<List<dynamic>> getPosts({int? viewerId, int? authorId}) async {
    final data = await _get('/posts', query: {
      if (viewerId != null) 'user_id': viewerId,
      if (authorId != null) 'author_id': authorId,
    });
    return List<dynamic>.from(data);
  }

  /// Uploads a post with any number of image/video files (multipart).
  Future<Map<String, dynamic>> uploadPost({
    required int userId,
    required String description,
    required List<File> media,
  }) async {
    final req = http.MultipartRequest('POST', Uri.parse('$_base/posts'));
    req.fields['user_id'] = '$userId';
    req.fields['description'] = description;
    for (final f in media) {
      req.files.add(await http.MultipartFile.fromPath('media[]', f.path));
    }
    final streamed = await req.send().timeout(const Duration(seconds: 120));
    final res = await http.Response.fromStream(streamed);
    return Map<String, dynamic>.from(_handle(res));
  }

  /// Toggles a like. Returns { liked, like_count }.
  Future<Map<String, dynamic>> toggleLike(String postId, int userId) async =>
      Map<String, dynamic>.from(await _post('/posts/$postId/like', {'user_id': userId}));

  Future<Map<String, dynamic>> getPost(String postId, {int? viewerId}) async =>
      Map<String, dynamic>.from(await _get('/posts/$postId',
          query: {if (viewerId != null) 'user_id': viewerId}));

  Future<void> deletePost(String postId, int userId) async {
    final res = await http
        .delete(Uri.parse('$_base/posts/$postId?user_id=$userId'), headers: _jsonHeaders)
        .timeout(_timeout);
    _handle(res);
  }

  Future<List<dynamic>> getComments(String postId) async =>
      List<dynamic>.from(await _get('/posts/$postId/comments'));

  Future<void> addComment(String postId, int userId, String comment) async {
    await _post('/posts/$postId/comments', {'user_id': userId, 'comment': comment});
  }

  // ---------------------------------------------------------------- social
  Future<Map<String, dynamic>> follow(int followerId, int followingId) async =>
      Map<String, dynamic>.from(
          await _post('/follow', {'follower_id': followerId, 'following_id': followingId}));

  Future<Map<String, dynamic>> unfollow(int followerId, int followingId) async =>
      Map<String, dynamic>.from(
          await _post('/unfollow', {'follower_id': followerId, 'following_id': followingId}));

  Future<Map<String, dynamic>> getUserProfile(String id, {int? viewerId}) async =>
      Map<String, dynamic>.from(
          await _get('/users/$id/profile', query: {if (viewerId != null) 'viewer_id': viewerId}));

  /// Users the given user follows (their "Following" list).
  Future<List<dynamic>> getFollowing(String id, {int? viewerId}) async =>
      List<dynamic>.from(await _get('/users/$id/following',
          query: {if (viewerId != null) 'viewer_id': viewerId}));

  /// Users who follow the given user.
  Future<List<dynamic>> getFollowers(String id, {int? viewerId}) async =>
      List<dynamic>.from(await _get('/users/$id/followers',
          query: {if (viewerId != null) 'viewer_id': viewerId}));

  Future<List<dynamic>> searchUsers({String? q, int? viewerId}) async {
    final data = await _get('/users/search', query: {
      if (q != null && q.isNotEmpty) 'q': q,
      if (viewerId != null) 'user_id': viewerId,
    });
    return List<dynamic>.from(data);
  }

  // ----------------------------------------------------------- app version
  /// Latest active app version. Returns the `latest_version` object (or null).
  Future<Map<String, dynamic>?> getLatestVersion({String platform = 'Android'}) async {
    final uri = Uri.parse('$_base/app-version').replace(queryParameters: {'platform': platform});
    final res = await http.get(uri, headers: _jsonHeaders).timeout(_timeout);
    final body = jsonDecode(res.body);
    final lv = (body is Map) ? body['latest_version'] : null;
    return lv == null ? null : Map<String, dynamic>.from(lv);
  }

  Future<List<dynamic>> getAppVersions() async =>
      List<dynamic>.from(await _get('/app-versions'));

  Future<Map<String, dynamic>> createAppVersion(Map<String, dynamic> body) async =>
      Map<String, dynamic>.from(await _post('/app-versions', body));

  Future<Map<String, dynamic>> updateAppVersion(String id, Map<String, dynamic> body) async =>
      Map<String, dynamic>.from(await _put('/app-versions/$id', body));

  // ----------------------------------------------------------------- admin
  Future<List<dynamic>> getUsers({String? q, String? status, String? state, String? city, String? userType, bool hasFcm = false}) async {
    final data = await _get('/users', query: {
      if (q != null && q.isNotEmpty) 'q': q,
      if (status != null && status.isNotEmpty) 'status': status,
      if (state != null && state.isNotEmpty) 'state': state,
      if (city != null && city.isNotEmpty) 'city': city,
      if (userType != null && userType.isNotEmpty) 'user_type': userType,
      if (hasFcm) 'has_fcm': 1,
    });
    return List<dynamic>.from(data);
  }

  /// Deletes a user (server-side this also deletes their shops).
  Future<void> deleteUser(String id) async {
    final res = await http.delete(Uri.parse('$_base/users/$id'), headers: _jsonHeaders).timeout(_timeout);
    _handle(res);
  }

  /// Returns the raw CSV text of filtered users (+ shop details).
  Future<String> exportUsersCsv({String? q, String? status, String? state, String? city, String? userType, bool hasFcm = false}) async {
    final uri = Uri.parse('$_base/users/export').replace(queryParameters: {
      if (q != null && q.isNotEmpty) 'q': q,
      if (status != null && status.isNotEmpty) 'status': status,
      if (state != null && state.isNotEmpty) 'state': state,
      if (city != null && city.isNotEmpty) 'city': city,
      if (userType != null && userType.isNotEmpty) 'user_type': userType,
      if (hasFcm) 'has_fcm': '1',
    });
    final res = await http.get(uri).timeout(_timeout);
    if (res.statusCode >= 200 && res.statusCode < 300) return res.body;
    throw ApiException('Export failed (${res.statusCode})', statusCode: res.statusCode);
  }

  Future<void> deleteShop(String id) async {
    final res = await http.delete(Uri.parse('$_base/shops/$id'), headers: _jsonHeaders).timeout(_timeout);
    _handle(res);
  }

  Future<Map<String, dynamic>> createService(Map<String, dynamic> body) async =>
      Map<String, dynamic>.from(await _post('/services', body));

  Future<Map<String, dynamic>> updateService(String id, Map<String, dynamic> body) async =>
      Map<String, dynamic>.from(await _put('/services/$id', body));

  /// Create a service with an optional uploaded icon image (multipart).
  Future<Map<String, dynamic>> createServiceForm({
    required Map<String, String> fields,
    File? icon,
  }) async {
    final req = http.MultipartRequest('POST', Uri.parse('$_base/services'));
    req.fields.addAll(fields);
    if (icon != null) {
      req.files.add(await http.MultipartFile.fromPath('icon', icon.path));
    }
    final streamed = await req.send().timeout(const Duration(seconds: 60));
    final res = await http.Response.fromStream(streamed);
    return Map<String, dynamic>.from(_handle(res));
  }

  /// Upload/replace a service icon (POST — PHP can't parse multipart on PUT).
  Future<Map<String, dynamic>> uploadServiceIcon(String id, File icon) async {
    final req = http.MultipartRequest('POST', Uri.parse('$_base/services/$id/icon'));
    req.files.add(await http.MultipartFile.fromPath('icon', icon.path));
    final streamed = await req.send().timeout(const Duration(seconds: 60));
    final res = await http.Response.fromStream(streamed);
    return Map<String, dynamic>.from(_handle(res));
  }

  Future<Map<String, dynamic>> createBanner(Map<String, dynamic> body) async =>
      Map<String, dynamic>.from(await _post('/banners', body));

  Future<Map<String, dynamic>> updateBanner(String id, Map<String, dynamic> body) async =>
      Map<String, dynamic>.from(await _put('/banners/$id', body));

  /// Create a banner with an uploaded image file (multipart) + text fields.
  Future<Map<String, dynamic>> createBannerUpload({
    required Map<String, String> fields,
    File? file,
  }) async {
    final req = http.MultipartRequest('POST', Uri.parse('$_base/banners'));
    req.fields.addAll(fields);
    if (file != null) {
      req.files.add(await http.MultipartFile.fromPath('image', file.path));
    }
    final streamed = await req.send().timeout(const Duration(seconds: 60));
    final res = await http.Response.fromStream(streamed);
    return Map<String, dynamic>.from(_handle(res));
  }

  /// Update a contact-us message (e.g. its status).
  Future<Map<String, dynamic>> updateContact(String id, Map<String, dynamic> body) async =>
      Map<String, dynamic>.from(await _put('/contact/$id', body));

  Future<void> deleteBanner(String id) async {
    final res = await http.delete(Uri.parse('$_base/banners/$id'), headers: _jsonHeaders).timeout(_timeout);
    _handle(res);
  }

  Future<List<dynamic>> getContacts({String? status, int? userId}) async {
    final data = await _get('/contact', query: {
      if (status != null && status.isNotEmpty) 'status': status,
      if (userId != null) 'user_id': userId,
    });
    return List<dynamic>.from(data);
  }

  // --------------------------------------------------- service banners
  Future<List<dynamic>> getServiceBanners(int serviceId, {bool all = false}) async {
    final data = await _get('/service-banners', query: {
      'service_id': serviceId,
      if (all) 'all': 1,
    });
    return List<dynamic>.from(data);
  }

  Future<Map<String, dynamic>> createServiceBanner({
    required Map<String, String> fields,
    File? file,
  }) async {
    final req = http.MultipartRequest('POST', Uri.parse('$_base/service-banners'));
    req.fields.addAll(fields);
    if (file != null) {
      req.files.add(await http.MultipartFile.fromPath('image', file.path));
    }
    final streamed = await req.send().timeout(const Duration(seconds: 60));
    final res = await http.Response.fromStream(streamed);
    return Map<String, dynamic>.from(_handle(res));
  }

  Future<Map<String, dynamic>> updateServiceBanner(String id, Map<String, dynamic> body) async =>
      Map<String, dynamic>.from(await _put('/service-banners/$id', body));

  Future<void> deleteServiceBanner(String id) async {
    final res = await http
        .delete(Uri.parse('$_base/service-banners/$id'), headers: _jsonHeaders)
        .timeout(_timeout);
    _handle(res);
  }

  // --------------------------------------------------------------- banners
  Future<List<dynamic>> getBanners({bool all = false}) async =>
      List<dynamic>.from(await _get('/banners', query: {if (all) 'all': 1}));

  // -------------------------------------------------------------- location
  Future<List<dynamic>> getStates() async => List<dynamic>.from(await _get('/states'));

  Future<List<dynamic>> getDistricts(int stateId) async =>
      List<dynamic>.from(await _get('/districts', query: {'state_id': stateId}));

  // location management (admin)
  Future<List<dynamic>> getStatesRaw() async => List<dynamic>.from(await _get('/states'));

  Future<Map<String, dynamic>> createState(Map<String, dynamic> body) async =>
      Map<String, dynamic>.from(await _post('/states', body));
  Future<Map<String, dynamic>> updateState(String id, Map<String, dynamic> body) async =>
      Map<String, dynamic>.from(await _put('/states/$id', body));

  Future<Map<String, dynamic>> createDistrict(Map<String, dynamic> body) async =>
      Map<String, dynamic>.from(await _post('/districts', body));
  Future<Map<String, dynamic>> updateDistrict(String id, Map<String, dynamic> body) async =>
      Map<String, dynamic>.from(await _put('/districts/$id', body));

  // --------------------------------------------------------------- contact
  Future<void> submitContact(Map<String, dynamic> payload) async {
    await _post('/contact', payload);
  }

  // ----------------------------------------------------------------- users
  Future<Map<String, dynamic>> getUserById(String id) async =>
      Map<String, dynamic>.from(await _get('/users/$id'));

  Future<Map<String, dynamic>> updateUser(String id, Map<String, dynamic> body) async =>
      Map<String, dynamic>.from(await _put('/users/$id', body));

  /// Admin: bulk import shops (+ owner users) from parsed Excel rows.
  /// Returns the summary { total, shops_created, users_created, users_reused,
  /// skipped, errors }.
  Future<Map<String, dynamic>> importShops({
    required int serviceId,
    required String state,
    required String city,
    required List<Map<String, String>> rows,
    String userType = 'Shop Owner',
  }) async {
    final data = await _post('/import/shops', {
      'service_id': serviceId,
      'state': state,
      'city': city,
      'user_type': userType,
      'rows': rows,
    });
    return Map<String, dynamic>.from(data);
  }

  /// Saves the device's FCM push token (+ platform) against the user.
  Future<void> saveFcmToken(String userId, String token, {String? platform}) async {
    await _post('/users/$userId/fcm-token', {
      'token': token,
      if (platform != null) 'platform': platform,
    });
  }

  // ---------------------------------------------------------------- payments
  /// Creates a Razorpay order (amount computed server-side).
  /// Returns { order_id, amount, currency, key_id, receipt }.
  Future<Map<String, dynamic>> createRazorpayOrder(
      {required int userId, required int count}) async {
    final data = await _post('/razorpay/order', {
      'user_id': userId,
      'count': count,
    });
    return Map<String, dynamic>.from(data);
  }

  /// Verifies a completed Razorpay payment's signature on the server.
  Future<Map<String, dynamic>> verifyRazorpayPayment({
    required String orderId,
    required String paymentId,
    required String signature,
  }) async {
    final data = await _post('/razorpay/verify', {
      'razorpay_order_id': orderId,
      'razorpay_payment_id': paymentId,
      'razorpay_signature': signature,
    });
    return Map<String, dynamic>.from(data);
  }

  /// Uploads a profile image file and returns the updated user map.
  Future<Map<String, dynamic>> updateProfileImage(String id, File image) async {
    final req = http.MultipartRequest('POST', Uri.parse('$_base/users/$id/image'));
    req.files.add(await http.MultipartFile.fromPath('profile_image', image.path));
    final streamed = await req.send().timeout(_timeout);
    final res = await http.Response.fromStream(streamed);
    return Map<String, dynamic>.from(_handle(res));
  }
}
