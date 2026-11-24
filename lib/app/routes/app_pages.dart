import 'package:get/get.dart';

import '../modules/post/upload_post_screen.dart';
import 'app_routes.dart';

// Auth
import '../modules/auth/splash_screen.dart';
import '../modules/auth/login_screen.dart';
import '../modules/auth/otp_screen.dart';

// Home
import '../modules/home/home_screen.dart';

// Data
import '../modules/data/service_list_screen.dart';
import '../modules/data/owner_detail_screen.dart';

// Shop
import '../modules/shop/add_shop_screen.dart';
import '../modules/shop/payment_screen.dart';
import '../modules/shop/my_shops_screen.dart';
import '../modules/shop/update_shop_screen.dart';

// Post
// import '../modules/post/post_detail_screen.dart';
// import '../modules/post/upload_post_screen.dart';
import '../modules/post/image_editor_screen.dart';
import '../modules/post/edit_post_screen.dart';
import '../modules/post/user_profile_screen.dart';
import '../modules/post/followers_list_screen.dart';
import '../modules/post/my_posts_screen.dart';

// Profile
import '../modules/profile/update_profile_screen.dart';
import '../modules/profile/notifications_screen.dart';
import '../modules/profile/contact_us_screen.dart';

// Admin (live)
import '../modules/admin/admin_panel.dart';
// Admin
import '../modules/admin/admin_dashboard_screen.dart';
import '../modules/admin/manage_users_screen.dart';
import '../modules/admin/manage_firms_screen.dart';
// import '../modules/admin/manage_data_screen.dart';
// import '../modules/admin/manage_offers_screen.dart';
// import '../modules/admin/manage_contacts_screen.dart';
// import '../modules/admin/manage_subscriptions_screen.dart';
// import '../modules/admin/manage_posts_screen.dart';

abstract class AppPages {
  static final pages = <GetPage>[
    GetPage(name: AppRoutes.splash, page: () => const SplashScreen()),
    GetPage(name: AppRoutes.login, page: () => const LoginScreen()),
    GetPage(name: AppRoutes.otp, page: () => const OtpScreen()),

    GetPage(name: AppRoutes.home, page: () => const HomeScreen()),

    GetPage(name: AppRoutes.serviceList, page: () => const ServiceListScreen()),
    GetPage(name: AppRoutes.ownerDetail, page: () => const OwnerDetailScreen()),

    GetPage(name: AppRoutes.addShop, page: () => const AddShopScreen()),
    GetPage(name: AppRoutes.payment, page: () => const PaymentScreen()),
    GetPage(name: AppRoutes.myShops, page: () => const MyShopsScreen()),
    GetPage(name: AppRoutes.updateShop, page: () => const UpdateShopScreen()),

    // GetPage(name: AppRoutes.postDetail, page: () => const PostDetailScreen()),
    GetPage(name: AppRoutes.uploadPost, page: () => const UploadPostScreen()),
    GetPage(name: AppRoutes.myPosts, page: () => const MyPostsScreen()),
    // GetPage(name: AppRoutes.imageEditor, page: () => const ImageEditorScreen()),
    GetPage(name: AppRoutes.editPost, page: () => const EditPostScreen()),
    GetPage(name: AppRoutes.userProfile, page: () => const UserProfileScreen()),
    GetPage(
        name: AppRoutes.followersList,
        page: () => const FollowersListScreen()),

    GetPage(
        name: AppRoutes.updateProfile, page: () => const UpdateProfileScreen()),
    GetPage(
        name: AppRoutes.notifications, page: () => const NotificationsScreen()),
    GetPage(name: AppRoutes.contactUs, page: () => const ContactUsScreen()),

    // Admin (live)
    GetPage(name: AppRoutes.adminPanel, page: () => const AdminPanelScreen()),
    GetPage(name: AppRoutes.adminUsersList, page: () => const AdminUsersScreen()),
    GetPage(name: AppRoutes.adminShopsList, page: () => const AdminShopsScreen()),
    GetPage(name: AppRoutes.adminServicesList, page: () => const AdminServicesScreen()),
    GetPage(name: AppRoutes.adminPostsList, page: () => const AdminPostsScreen()),
    GetPage(name: AppRoutes.adminBannersList, page: () => const AdminBannersScreen()),
    GetPage(name: AppRoutes.adminContactsList, page: () => const AdminContactsScreen()),
    GetPage(name: AppRoutes.adminLocationsList, page: () => const AdminLocationsScreen()),
    GetPage(name: AppRoutes.adminServiceBannersList, page: () => const AdminServiceBannersScreen()),
    GetPage(name: AppRoutes.adminAppVersionsList, page: () => const AdminAppVersionsScreen()),
    GetPage(name: AppRoutes.adminPricingList, page: () => const AdminPricingScreen()),
    GetPage(name: AppRoutes.adminImport, page: () => const AdminImportScreen()),

    // Admin
    GetPage(
        name: AppRoutes.adminDashboard,
        page: () => const AdminDashboardScreen()),
    GetPage(
        name: AppRoutes.adminUsers, page: () => const ManageUsersScreen()),
    GetPage(
        name: AppRoutes.adminFirms, page: () => const ManageFirmsScreen()),
    // GetPage(name: AppRoutes.adminData, page: () => const ManageDataScreen()),
    // GetPage(
    //     name: AppRoutes.adminOffers, page: () => const ManageOffersScreen()),
    // GetPage(
    //     name: AppRoutes.adminContacts,
    //     page: () => const ManageContactsScreen()),
    // GetPage(
    //     name: AppRoutes.adminSubscriptions,
    //     page: () => const ManageSubscriptionsScreen()),
    // GetPage(
    //     name: AppRoutes.adminPosts, page: () => const ManagePostsScreen()),
  ];
}