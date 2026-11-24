abstract class AppRoutes {
  // Auth
  static const splash = '/splash';
  static const login = '/login';
  static const otp = '/otp';

  // Main
  static const home = '/home';

  // Data Module
  static const serviceList = '/service-list';
  static const ownerDetail = '/owner-detail';

  // Shop Module
  static const addShop = '/add-shop';
  static const payment = '/payment';
  static const myShops = '/my-shops';
  static const updateShop = '/update-shop';

  // Post Module
  static const postDetail = '/post-detail';
  static const uploadPost = '/upload-post';
  static const myPosts = '/my-posts';
  static const imageEditor = '/image-editor';
  static const editPost = '/edit-post';
  static const userProfile = '/user-profile';
  static const followersList = '/followers-list';

  // Profile Module
  static const updateProfile = '/update-profile';
  static const notifications = '/notifications';
  static const contactUs = '/contact-us';

  // Admin (live)
  static const adminPanel = '/admin/panel';
  static const adminUsersList = '/admin/users-list';
  static const adminShopsList = '/admin/shops-list';
  static const adminServicesList = '/admin/services-list';
  static const adminPostsList = '/admin/posts-list';
  static const adminBannersList = '/admin/banners-list';
  static const adminContactsList = '/admin/contacts-list';
  static const adminLocationsList = '/admin/locations-list';
  static const adminServiceBannersList = '/admin/service-banners-list';
  static const adminAppVersionsList = '/admin/app-versions-list';
  static const adminPricingList = '/admin/pricing-list';
  static const adminImport = '/admin/import';

  // Admin (legacy dummy)
  static const adminDashboard = '/admin/dashboard';
  static const adminUsers = '/admin/users';
  static const adminFirms = '/admin/firms';
  static const adminData = '/admin/data';
  static const adminOffers = '/admin/offers';
  static const adminContacts = '/admin/contacts';
  static const adminSubscriptions = '/admin/subscriptions';
  static const adminPosts = '/admin/posts';
}