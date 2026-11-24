// =================================================================
// Data Models for the Life Style Exposure app
// All models are simple and use dummy data for the prototype
// =================================================================

class UserModel {
  final String id;
  String name;
  String mobile;
  String city;
  String state;
  String email;
  String avatar;
  String userType; // Interior Designer / Architect / Builder / End Customer / Shop Owner
  bool isAdmin;
  bool hasShop;
  String membership; // 'free' | 'basic' | 'premium'
  bool isActive;
  DateTime joinDate;

  UserModel({
    required this.id,
    required this.name,
    required this.mobile,
    required this.city,
    this.state = '',
    required this.email,
    required this.avatar,
    this.userType = '',
    this.isAdmin = false,
    this.hasShop = false,
    this.membership = 'free',
    this.isActive = true,
    required this.joinDate,
  });

  static const _defaultAvatar =
      'https://ui-avatars.com/api/?name=User&background=D4A853&color=fff';

  /// Maps a backend `users` row (see /auth/verify-otp, /users) to a UserModel.
  factory UserModel.fromJson(Map<String, dynamic> j) {
    return UserModel(
      id: '${j['id'] ?? ''}',
      name: (j['full_name'] ?? j['name'] ?? '').toString(),
      mobile: (j['mobile_number'] ?? j['mobile'] ?? '').toString(),
      city: (j['city'] ?? '').toString(),
      state: (j['state'] ?? '').toString(),
      email: (j['email'] ?? '').toString(),
      avatar: (j['profile_image']?.toString().isNotEmpty ?? false)
          ? j['profile_image'].toString()
          : (j['avatar']?.toString().isNotEmpty ?? false)
              ? j['avatar'].toString()
              : _defaultAvatar,
      userType: (j['user_type'] ?? '').toString(),
      isAdmin: j['is_admin'] == 1 || j['is_admin'] == true || j['isAdmin'] == true,
      hasShop: j['has_shop'] == 1 || j['has_shop'] == true || j['hasShop'] == true,
      membership: (j['membership'] ?? 'free').toString(),
      isActive: (j['status'] ?? 'active') == 'active',
      joinDate:
          DateTime.tryParse((j['created_at'] ?? '').toString()) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'full_name': name,
        'mobile_number': mobile,
        'city': city,
        'state': state,
        'email': email,
        'profile_image': avatar,
        'user_type': userType,
        'is_admin': isAdmin,
        'has_shop': hasShop,
        'membership': membership,
        'status': isActive ? 'active' : 'inactive',
        'created_at': joinDate.toIso8601String(),
      };
}

class ShopModel {
  final String id;
  String firmName;
  String ownerName;
  String mobile;
  String otherMobile;
  String address;
  String city;
  String location;
  String email;
  String latitude;    // '' when not set
  String longitude;   // '' when not set
  String avatar;      // shop OWNER photo (owner_image, falls back to profile)
  String thumbnail;   // shop IMAGE (first uploaded shop image), '' if none
  // A single physical shop can be listed under MULTIPLE categories
  // (Architect, Wallpaper, Builders & Developers etc.)
  List<String> categories;
  List<String> clientImages;
  List<String> onSiteWorkImages;
  final List<ProductModel> products;
  List<String> profileImages;
  String description;
  DateTime createdAt;
  // Structured on-site works & clients (carry title/description, name/details)
  List<OnSiteWorkItem> onSiteWorks;
  List<OnSiteWorkItem> latestUpdates;
  List<OnSiteWorkItem> upcomingProjects; // premium-only section
  List<ClientItem> clientList;
  // True when the shop's service belongs to the PREMIUM category.
  bool isPremium;

  ShopModel({
    required this.id,
    required this.firmName,
    required this.ownerName,
    required this.mobile,
    required this.otherMobile,
    required this.address,
    required this.city,
    required this.location,
    required this.email,
    this.latitude = '',
    this.longitude = '',
    required this.avatar,
    this.thumbnail = '',
    required this.categories,
    required this.clientImages,
    required this.onSiteWorkImages,
    required this.profileImages,
    this.description = '',
    required this.createdAt,
    required this.products,
    this.onSiteWorks = const [],
    this.latestUpdates = const [],
    this.upcomingProjects = const [],
    this.clientList = const [],
    this.isPremium = false,
  });

  // No stock-photo fallback — when a shop/owner image is missing the UI
  // shows the Lifestyle logo (via SafeNetworkImage's fallbackAsset).
  static const _defaultAvatar = '';

  /// Maps a backend `shops` row. List rows have a flat shape; the detail
  /// endpoint additionally includes images/products/updates/onsite/clients.
  factory ShopModel.fromJson(Map<String, dynamic> j) {
    List<String> _urls(dynamic list, String key) {
      if (list is! List) return const [];
      return list
          .map((e) => (e is Map ? e[key] : null)?.toString() ?? '')
          .where((s) => s.isNotEmpty)
          .toList();
    }

    final images = _urls(j['images'], 'image_url');
    final onsite = [
      ..._urls(j['onsite_works'], 'media_url'),
      ..._urls(j['latest_updates'], 'media_url'),
    ];
    final thumb = (j['thumbnail']?.toString().isNotEmpty ?? false)
        ? j['thumbnail'].toString()
        : (images.isNotEmpty ? images.first : _defaultAvatar);

    // Owner photo only — independent of the shop image. Empty when unset so
    // the UI shows the Lifestyle logo (not the shop photo) in the owner slot.
    final ownerImg = (j['owner_image']?.toString().isNotEmpty ?? false)
        ? j['owner_image'].toString()
        : '';

    final serviceName = (j['service_name'] ?? '').toString();

    return ShopModel(
      id: '${j['id'] ?? ''}',
      firmName: (j['shop_name'] ?? '').toString(),
      ownerName: (j['owner_name'] ?? '').toString(),
      mobile: (j['owner_mobile'] ?? '').toString(),
      otherMobile: (j['alternative_number'] ?? '').toString(),
      address: (j['address'] ?? '').toString(),
      city: (j['city'] ?? '').toString(),
      location: (j['district'] ?? '').toString(),
      email: (j['email'] ?? '').toString(),
      latitude: (j['latitude'] ?? '').toString(),
      longitude: (j['longitude'] ?? '').toString(),
      avatar: ownerImg,
      thumbnail: (j['thumbnail']?.toString().isNotEmpty ?? false)
          ? j['thumbnail'].toString()
          : (images.isNotEmpty ? images.first : ''),
      categories: serviceName.isEmpty ? <String>[] : [serviceName],
      clientImages: _urls(j['clients'], 'image_url'),
      onSiteWorkImages: onsite,
      profileImages: images.isNotEmpty
          ? images
          : (thumb.isNotEmpty ? [thumb] : <String>[]),
      description: (j['story_description'] ?? '').toString(),
      createdAt:
          DateTime.tryParse((j['created_at'] ?? '').toString()) ?? DateTime.now(),
      products: (j['products'] is List)
          ? (j['products'] as List)
              .map((p) => ProductModel.fromJson(Map<String, dynamic>.from(p)))
              .toList()
          : <ProductModel>[],
      onSiteWorks: (j['onsite_works'] is List)
          ? (j['onsite_works'] as List)
              .map((e) => OnSiteWorkItem.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : <OnSiteWorkItem>[],
      latestUpdates: (j['latest_updates'] is List)
          ? (j['latest_updates'] as List)
              .map((e) => OnSiteWorkItem.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : <OnSiteWorkItem>[],
      upcomingProjects: (j['upcoming_projects'] is List)
          ? (j['upcoming_projects'] as List)
              .map((e) => OnSiteWorkItem.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : <OnSiteWorkItem>[],
      isPremium: (j['category_slug'] ?? '').toString() == 'premium',
      clientList: (j['clients'] is List)
          ? (j['clients'] as List)
              .map((e) => ClientItem.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : <ClientItem>[],
    );
  }
}
class BannerModel {
  final String id;
  final String title;
  final String subtitle;
  final String imageUrl;
  final String linkUrl;

  BannerModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.linkUrl,
  });

  factory BannerModel.fromJson(Map<String, dynamic> j) => BannerModel(
        id: '${j['id'] ?? ''}',
        title: (j['title'] ?? '').toString(),
        subtitle: (j['subtitle'] ?? '').toString(),
        imageUrl: (j['image_url'] ?? '').toString(),
        linkUrl: (j['link_url'] ?? '').toString(),
      );
}

class OnSiteWorkItem {
  final String url;
  final String title;
  final String description;
  final bool isVideo;
  OnSiteWorkItem({
    required this.url,
    this.title = '',
    this.description = '',
    this.isVideo = false,
  });

  factory OnSiteWorkItem.fromJson(Map<String, dynamic> j) => OnSiteWorkItem(
        url: (j['media_url'] ?? '').toString(),
        title: (j['title'] ?? '').toString(),
        description: (j['description'] ?? '').toString(),
        isVideo: (j['media_type'] ?? '') == 'video',
      );
}

class ClientItem {
  final String image;
  final String name;
  final String details;
  ClientItem({this.image = '', this.name = '', this.details = ''});

  factory ClientItem.fromJson(Map<String, dynamic> j) => ClientItem(
        image: (j['image_url'] ?? '').toString(),
        name: (j['name'] ?? '').toString(),
        details: (j['details'] ?? '').toString(),
      );
}

class ProductModel {
  final String name;
  final String image;
  final String description;
  final double price;

  ProductModel({
    required this.name,
    required this.image,
    required this.description,
    required this.price,
  });

  factory ProductModel.fromJson(Map<String, dynamic> j) => ProductModel(
        name: (j['name'] ?? '').toString(),
        image: (j['image_url'] ?? j['image'] ?? '').toString(),
        description: (j['description'] ?? '').toString(),
        price: double.tryParse('${j['price'] ?? 0}') ?? 0,
      );
}
class ServiceCategory {
  final String id;
  final String name;
  final String icon;      // emoji fallback
  final String iconUrl;   // uploaded/URL icon image (empty if none)
  final bool access;
  final List<String> cities;
  final int shopsCount; // number of active shops under this service
  final bool isPremium; // true when the service is in the premium category

  ServiceCategory({
    required this.id,
    required this.name,
    required this.icon,
    this.iconUrl = '',
    required this.access,
    required this.cities,
    this.shopsCount = 0,
    this.isPremium = false,
  });

  static const Map<String, String> _emoji = {
    'architect': '🏛',
    'interior-designer': '🛋',
    'builders-developers': '🏗',
    'wallpaper': '🖼',
    'curtains': '🪟',
    'furniture': '🪑',
    'painter': '🎨',
    'plumber': '🔧',
    'electrician': '💡',
  };

  /// Maps a backend `services` row. `can_click` decides premium access.
  factory ServiceCategory.fromJson(Map<String, dynamic> j) {
    final slug = (j['slug'] ?? '').toString();
    final rawIcon = (j['icon'] ?? '').toString();
    // Backend icon is an image URL when uploaded; keep it separately.
    final isUrl = rawIcon.startsWith('http');
    return ServiceCategory(
      id: '${j['id'] ?? ''}',
      name: (j['name'] ?? '').toString(),
      icon: _emoji[slug] ?? '🏷',
      iconUrl: isUrl ? rawIcon : '',
      access: j['can_click'] == true || j['can_click'] == 1,
      cities: const [],
      shopsCount: int.tryParse(
              '${j['active_shops_count'] ?? j['shops_count'] ?? 0}') ??
          0,
      isPremium: (j['category_slug'] ?? '').toString() == 'premium',
    );
  }
}

class PostMediaItem {
  final String url;
  final bool isVideo;
  final String? overlayText;

  PostMediaItem({
    required this.url,
    this.isVideo = false,
    this.overlayText,
  });

  factory PostMediaItem.fromJson(Map<String, dynamic> j) => PostMediaItem(
        url: (j['media_url'] ?? j['url'] ?? '').toString(),
        isVideo: (j['media_type'] ?? '') == 'video',
      );
}

class PostModel {
  final String id;
  final String userId;
  final String userName;
  final String userAvatar;
  final String userCity;
  String description;
  List<PostMediaItem> media;
  int likeCount;
  int commentCount;
  bool liked;
  bool following;
  String contactNumber;
  DateTime createdAt;
  List<CommentModel> comments;

  PostModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userAvatar,
    required this.userCity,
    required this.description,
    required this.media,
    this.likeCount = 0,
    this.commentCount = 0,
    this.liked = false,
    this.following = false,
    required this.contactNumber,
    required this.createdAt,
    List<CommentModel>? comments,
  }) : comments = comments ?? [];

  static const _defaultAvatar =
      'https://ui-avatars.com/api/?name=User&background=D4A853&color=fff';

  factory PostModel.fromJson(Map<String, dynamic> j) => PostModel(
        id: '${j['id'] ?? ''}',
        userId: '${j['user_id'] ?? ''}',
        userName: (j['full_name'] ?? '').toString(),
        userAvatar: (j['profile_image']?.toString().isNotEmpty ?? false)
            ? j['profile_image'].toString()
            : _defaultAvatar,
        userCity: (j['city'] ?? '').toString(),
        description: (j['description'] ?? '').toString(),
        media: (j['media'] is List)
            ? (j['media'] as List)
                .map((m) => PostMediaItem.fromJson(Map<String, dynamic>.from(m)))
                .toList()
            : <PostMediaItem>[],
        likeCount: int.tryParse('${j['like_count'] ?? 0}') ?? 0,
        commentCount: int.tryParse('${j['comment_count'] ?? 0}') ?? 0,
        liked: j['liked'] == true || j['liked'] == 1,
        following: j['following'] == true || j['following'] == 1,
        contactNumber: (j['mobile_number'] ?? '').toString(),
        createdAt:
            DateTime.tryParse((j['created_at'] ?? '').toString()) ?? DateTime.now(),
      );
}

class CommentModel {
  final String id;
  final String userName;
  final String userAvatar;
  final String text;
  final DateTime time;

  CommentModel({
    required this.id,
    required this.userName,
    required this.userAvatar,
    required this.text,
    required this.time,
  });

  static const _defaultAvatar =
      'https://ui-avatars.com/api/?name=User&background=D4A853&color=fff';

  factory CommentModel.fromJson(Map<String, dynamic> j) => CommentModel(
        id: '${j['id'] ?? ''}',
        userName: (j['full_name'] ?? j['userName'] ?? '').toString(),
        userAvatar: (j['profile_image']?.toString().isNotEmpty ?? false)
            ? j['profile_image'].toString()
            : _defaultAvatar,
        text: (j['comment'] ?? j['text'] ?? '').toString(),
        time: DateTime.tryParse((j['created_at'] ?? '').toString()) ?? DateTime.now(),
      );
}

class FollowerModel {
  final String id;
  final String name;
  final String avatar;
  final String city;
  bool followingBack;

  FollowerModel({
    required this.id,
    required this.name,
    required this.avatar,
    required this.city,
    this.followingBack = false,
  });
}

class NotificationModel {
  final String id;
  final String type; // 'like' | 'comment' | 'follow'
  final String userName;
  final String userAvatar;
  final String message;
  final DateTime time;
  bool read;

  NotificationModel({
    required this.id,
    required this.type,
    required this.userName,
    required this.userAvatar,
    required this.message,
    required this.time,
    this.read = false,
  });
}

class OfferModel {
  final String id;
  String title;
  String description;
  String discount;
  DateTime validTill;
  bool active;

  OfferModel({
    required this.id,
    required this.title,
    required this.description,
    required this.discount,
    required this.validTill,
    this.active = true,
  });
}

class SubscriptionPlanModel {
  final String id;
  String name;
  double price;
  String duration;
  List<String> benefits;

  SubscriptionPlanModel({
    required this.id,
    required this.name,
    required this.price,
    required this.duration,
    required this.benefits,
  });
}

class ContactInquiryModel {
  final String id;
  final String name;
  final String mobile;
  final String email;
  final String message;
  final DateTime time;
  bool resolved;

  ContactInquiryModel({
    required this.id,
    required this.name,
    required this.mobile,
    required this.email,
    required this.message,
    required this.time,
    this.resolved = false,
  });
}
