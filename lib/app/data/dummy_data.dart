import 'models.dart';

class DummyData {
  // -----------------------------------------------------------
  // SERVICE CATEGORIES (Data tab grid)
  // -----------------------------------------------------------
  static List<ServiceCategory> categories = [
    ServiceCategory(
      id: 'c1',
      name: 'Architect',
      icon: '🏛',
      access: false,
      cities: ['Nagpur', 'Bhandara', 'Akola', 'Mumbai', 'Pune'],
    ),
    ServiceCategory(
      id: 'c2',
      name: 'Interior Designer',
      icon: '🛋',
      access: true,
      cities: ['Nagpur', 'Bhandara', 'Akola', 'Mumbai'],
    ),
    ServiceCategory(
      id: 'c3',
      name: 'Builders & Developers',
      icon: '🏗',
      access: false,
      cities: ['Nagpur', 'Pune', 'Mumbai', 'Indore'],
    ),
    ServiceCategory(
      id: 'c4',
      name: 'Wallpaper',
      icon: '🖼',
      access: true,
      cities: ['Nagpur', 'Bhandara', 'Akola'],
    ),
    ServiceCategory(
      id: 'c5',
      name: 'Curtains',
      icon: '🪟',
      access: true,
      cities: ['Nagpur', 'Pune', 'Mumbai'],
    ),
    ServiceCategory(
      id: 'c6',
      name: 'Furniture',
      icon: '🪑',
      access: true,
      cities: ['Nagpur', 'Bhandara', 'Mumbai'],
    ),
    ServiceCategory(
      id: 'c7',
      name: 'Painter',
      icon: '🎨',
      access: true,
      cities: ['Nagpur', 'Akola', 'Pune'],
    ),
    ServiceCategory(
      id: 'c8',
      name: 'Plumber',
      icon: '🔧',
      access: true,
      cities: ['Nagpur', 'Mumbai', 'Pune'],
    ),
    ServiceCategory(
      id: 'c9',
      name: 'Electrician',
      icon: '💡',
      access: true,
      cities: ['Nagpur', 'Bhandara', 'Akola'],
    ),
  ];

  static List<String> states = [
    'Maharashtra',
    'Madhya Pradesh',
    'Uttar Pradesh',
    'Gujarat',
    'Karnataka',
  ];

  // -----------------------------------------------------------
  // SHOPS (Owner / Firm data)
  // -----------------------------------------------------------
  static List<ShopModel> shops = [
    ShopModel(
      id: 's1',
      firmName: 'Maa Sharda Furnishing',
      ownerName: 'Manoj Mahi',
      mobile: '7972726558',
      otherMobile: '8530412675',
      address: 'Plot No. 5, Dubey Layout, Jaitala Road',
      city: 'Nagpur',
      location: 'West Nagpur',
      email: 'siddhi.ent22@gmail.com',
      avatar:
      'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200',
      categories: ['Wallpaper', 'Curtains', 'Interior Designer'],
      clientImages: [
        'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=80',
        'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=80',
        'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=80',
      ],
      onSiteWorkImages: [
        'https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=400',
        // 🎥 video
        'https://auzrestorage05012002.blob.core.windows.net/video/2.mp4',
        'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=400',
        'https://images.unsplash.com/photo-1567016432779-094069958ea5?w=400',
        // 🎥 video
        'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
      ],
      profileImages: [
        'https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=400',
        // 🎥 video
        'https://auzrestorage05012002.blob.core.windows.net/video/1.mp4',
        'https://images.unsplash.com/photo-1502005229762-cf1b2da7c5d6?w=400',
        'https://images.unsplash.com/photo-1558002038-1055907df827?w=400',
      ],
      description:
      'Premium curtains, wallpapers and interior solutions in Nagpur. Over 10 years of experience.',
      createdAt: DateTime.now().subtract(const Duration(days: 200)),
      products: [
        ProductModel(
          name: 'Italian Wallpaper',
          image:
          'https://images.unsplash.com/photo-1567016432779-094069958ea5?w=800',
          description:
          'Luxury imported textured wallpaper.',
          price: 2499,
        ),

        ProductModel(
          name: 'Modern Curtains',
          image:
          'https://images.unsplash.com/photo-1558002038-1055907df827?w=800',
          description:
          'Premium silk curtains for luxury homes.',
          price: 5999,
        ),
      ],
    ),
    ShopModel(
      id: 's2',
      firmName: 'Shree Krishna Architects',
      ownerName: 'Rajesh Patil',
      mobile: '9823456701',
      otherMobile: '7020123456',
      address: 'Office 12, Civil Lines',
      city: 'Nagpur',
      location: 'Central Nagpur',
      email: 'shreekrishna@example.com',
      avatar:
      'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=200',
      categories: ['Architect', 'Builders & Developers'],
      clientImages: [
        'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=80',
        'https://images.unsplash.com/photo-1502685104226-ee32379fefbe?w=80',
      ],
      onSiteWorkImages: [
        'https://images.unsplash.com/photo-1503387762-592deb58ef4e?w=400',
        // 🎥 video
        'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4',
        'https://images.unsplash.com/photo-1486325212027-8081e485255e?w=400',
      ],
      profileImages: [
        'https://images.unsplash.com/photo-1503387762-592deb58ef4e?w=400',
        // 🎥 video
        'https://auzrestorage05012002.blob.core.windows.net/video/3.mp4',
        'https://images.unsplash.com/photo-1486325212027-8081e485255e?w=400',
      ],
      description:
      'Award-winning architectural consultancy specializing in residential and commercial projects.',
      createdAt: DateTime.now().subtract(const Duration(days: 120)),
      products: [
        ProductModel(
          name: 'Italian Wallpaper',
          image:
          'https://images.unsplash.com/photo-1567016432779-094069958ea5?w=800',
          description:
          'Luxury imported textured wallpaper.',
          price: 2499,
        ),

        ProductModel(
          name: 'Modern Curtains',
          image:
          'https://images.unsplash.com/photo-1558002038-1055907df827?w=800',
          description:
          'Premium silk curtains for luxury homes.',
          price: 5999,
        ),
      ],
    ),
    // ... s3 and s4 unchanged
    ShopModel(
      id: 's3',
      firmName: 'Modern Wallpaper House',
      ownerName: 'Sunil Verma',
      mobile: '9988776655',
      otherMobile: '',
      address: 'Shop 4, MG Road',
      city: 'Bhandara',
      location: 'Main Market',
      email: 'modernwall@example.com',
      avatar:
      'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=200',
      categories: ['Wallpaper'],
      clientImages: [
        'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=80',
      ],
      onSiteWorkImages: [
        'https://images.unsplash.com/photo-1567016432779-094069958ea5?w=400',
      ],
      profileImages: [
        'https://images.unsplash.com/photo-1567016432779-094069958ea5?w=400',
      ],
      description: 'Largest collection of imported wallpapers.',
      createdAt: DateTime.now().subtract(const Duration(days: 60)),
      products: [
        ProductModel(
          name: 'Italian Wallpaper',
          image:
          'https://images.unsplash.com/photo-1567016432779-094069958ea5?w=800',
          description:
          'Luxury imported textured wallpaper.',
          price: 2499,
        ),

        ProductModel(
          name: 'Modern Curtains',
          image:
          'https://images.unsplash.com/photo-1558002038-1055907df827?w=800',
          description:
          'Premium silk curtains for luxury homes.',
          price: 5999,
        ),
      ],
    ),
    ShopModel(
      id: 's4',
      firmName: 'Royal Curtain Studio',
      ownerName: 'Ankita Joshi',
      mobile: '9156432109',
      otherMobile: '8657891234',
      address: 'Studio 7, Dharampeth',
      city: 'Nagpur',
      location: 'West Nagpur',
      email: 'royalcurtain@example.com',
      avatar:
      'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=200',
      categories: ['Curtains', 'Interior Designer'],
      clientImages: [
        'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=80',
        'https://images.unsplash.com/photo-1502685104226-ee32379fefbe?w=80',
      ],
      onSiteWorkImages: [
        'https://images.unsplash.com/photo-1558002038-1055907df827?w=400',
      ],
      profileImages: [
        'https://images.unsplash.com/photo-1558002038-1055907df827?w=400',
      ],
      description: 'Hand-crafted curtains designed in Italian fabric.',
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      products: [
        ProductModel(
          name: 'Italian Wallpaper',
          image:
          'https://images.unsplash.com/photo-1567016432779-094069958ea5?w=800',
          description:
          'Luxury imported textured wallpaper.',
          price: 2499,
        ),

        ProductModel(
          name: 'Modern Curtains',
          image:
          'https://images.unsplash.com/photo-1558002038-1055907df827?w=800',
          description:
          'Premium silk curtains for luxury homes.',
          price: 5999,
        ),
      ],
    ),

    ShopModel(
      id: 's5',
      firmName: 'Elite Interior Studio',
      ownerName: 'Priya Deshmukh',
      mobile: '9876543210',
      otherMobile: '9012345678',
      address: '2nd Floor, Residency Road',
      city: 'Mumbai',
      location: 'Andheri West',
      email: 'eliteinterior@example.com',
      avatar:
      'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=200',

      // 👇 Interior Designer category
      categories: ['Interior Designer'],

      clientImages: [
        'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=80',
        'https://images.unsplash.com/photo-1502685104226-ee32379fefbe?w=80',
      ],

      onSiteWorkImages: [
        'https://images.unsplash.com/photo-1505693416388-ac5ce068fe85?w=400',
        'https://images.unsplash.com/photo-1484154218962-a197022b5858?w=400',
        'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
      ],

      profileImages: [
        'https://images.unsplash.com/photo-1505693416388-ac5ce068fe85?w=400',
        'https://images.unsplash.com/photo-1484154218962-a197022b5858?w=400',
      ],

      description:
      'Luxury interior design solutions for modern homes, offices, and commercial spaces.',

      createdAt: DateTime.now().subtract(const Duration(days: 15)),
      products: [
        ProductModel(
          name: 'Italian Wallpaper',
          image:
          'https://images.unsplash.com/photo-1567016432779-094069958ea5?w=800',
          description:
          'Luxury imported textured wallpaper.',
          price: 2499,
        ),

        ProductModel(
          name: 'Modern Curtains',
          image:
          'https://images.unsplash.com/photo-1558002038-1055907df827?w=800',
          description:
          'Premium silk curtains for luxury homes.',
          price: 5999,
        ),
      ],
    ),

  ];

  // -----------------------------------------------------------
  // POSTS (Social feed)
  // -----------------------------------------------------------
// POSTS (Social feed) — with mixed image + video media
// -----------------------------------------------------------
  static List<PostModel> posts = [
    PostModel(
      id: 'p1',
      userId: 'u1',
      userName: 'Manoj Mahi',
      userAvatar:
      'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=120',
      userCity: 'Nagpur',
      description:
      'Just finished installing this beautiful imported wallpaper at a client\'s villa! ✨ #InteriorDesign #LuxuryHome',
      media: [
        PostMediaItem(
            url:
            'https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=800'),
        PostMediaItem(
          url:
          'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4',
          isVideo: true,
        ),
        PostMediaItem(
            url:
            'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=800'),
      ],
      likeCount: 124,
      commentCount: 18,
      contactNumber: '7972726558',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      comments: [
        CommentModel(
            id: 'cm1',
            userName: 'Priya Singh',
            userAvatar:
            'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=80',
            text: 'Looks stunning! Can you share the rate?',
            time: DateTime.now().subtract(const Duration(hours: 1))),
        CommentModel(
            id: 'cm2',
            userName: 'Rohit Sharma',
            userAvatar:
            'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=80',
            text: 'Beautiful work 👏',
            time: DateTime.now().subtract(const Duration(minutes: 30))),
      ],
    ),
    PostModel(
      id: 'p2',
      userId: 'u2',
      userName: 'Rajesh Patil',
      userAvatar:
      'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=120',
      userCity: 'Nagpur',
      description:
      'New residential project handed over today. 3BHK luxury villa in Civil Lines.',
      media: [
        PostMediaItem(
          url:
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
          isVideo: true,
        ),
      ],
      likeCount: 86,
      commentCount: 9,
      following: true,
      contactNumber: '9823456701',
      createdAt: DateTime.now().subtract(const Duration(hours: 6)),
    ),
    PostModel(
      id: 'p3',
      userId: 'u3',
      userName: 'Sunil Verma',
      userAvatar:
      'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=120',
      userCity: 'Bhandara',
      description:
      '50% Off on Imported Italian Wallpapers this week only! 🎉',
      media: [
        PostMediaItem(
            url:
            'https://images.unsplash.com/photo-1567016432779-094069958ea5?w=800'),
        PostMediaItem(
          url:
          'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4',
          isVideo: true,
        ),
        PostMediaItem(
            url:
            'https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=800'),
        PostMediaItem(
            url:
            'https://images.unsplash.com/photo-1502005229762-cf1b2da7c5d6?w=800'),
      ],
      likeCount: 220,
      commentCount: 32,
      liked: true,
      contactNumber: '9988776655',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    PostModel(
      id: 'p4',
      userId: 'u4',
      userName: 'Ankita Joshi',
      userAvatar:
      'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=120',
      userCity: 'Nagpur',
      description:
      'Custom-stitched silk curtains delivered to a beautiful penthouse in West Nagpur.',
      media: [
        PostMediaItem(
            url:
            'https://images.unsplash.com/photo-1558002038-1055907df827?w=800'),
        PostMediaItem(
          url:
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
          isVideo: true,
        ),
      ],
      likeCount: 65,
      commentCount: 4,
      contactNumber: '9156432109',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
  ];

  // -----------------------------------------------------------
  // FOLLOWERS (top of feed)
  // -----------------------------------------------------------
  static List<FollowerModel> followers = [
    FollowerModel(
        id: 'f1',
        name: 'Manoj',
        avatar:
            'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=120',
        city: 'Nagpur'),
    FollowerModel(
        id: 'f2',
        name: 'Priya',
        avatar:
            'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=120',
        city: 'Nagpur'),
    FollowerModel(
        id: 'f3',
        name: 'Rajesh',
        avatar:
            'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=120',
        city: 'Nagpur'),
    FollowerModel(
        id: 'f4',
        name: 'Sunil',
        avatar:
            'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=120',
        city: 'Bhandara'),
    FollowerModel(
        id: 'f5',
        name: 'Ankita',
        avatar:
            'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=120',
        city: 'Nagpur'),
    FollowerModel(
        id: 'f6',
        name: 'Sahil',
        avatar:
            'https://images.unsplash.com/photo-1502685104226-ee32379fefbe?w=120',
        city: 'Pune'),
    FollowerModel(
        id: 'f7',
        name: 'Neha',
        avatar:
            'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=120',
        city: 'Mumbai'),
  ];

  // -----------------------------------------------------------
  // NOTIFICATIONS
  // -----------------------------------------------------------
  static List<NotificationModel> notifications = [
    NotificationModel(
      id: 'n1',
      type: 'like',
      userName: 'Priya Singh',
      userAvatar:
          'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=80',
      message: 'liked your post',
      time: DateTime.now().subtract(const Duration(minutes: 10)),
    ),
    NotificationModel(
      id: 'n2',
      type: 'comment',
      userName: 'Rohit Sharma',
      userAvatar:
          'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=80',
      message: 'commented on your post: "Beautiful work 👏"',
      time: DateTime.now().subtract(const Duration(hours: 1)),
    ),
    NotificationModel(
      id: 'n3',
      type: 'follow',
      userName: 'Anuj Mehta',
      userAvatar:
          'https://images.unsplash.com/photo-1502685104226-ee32379fefbe?w=80',
      message: 'started following you',
      time: DateTime.now().subtract(const Duration(hours: 5)),
    ),
    NotificationModel(
      id: 'n4',
      type: 'like',
      userName: 'Neha Kumar',
      userAvatar:
          'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=80',
      message: 'liked your post',
      time: DateTime.now().subtract(const Duration(days: 1)),
      read: true,
    ),
  ];

  // -----------------------------------------------------------
  // ADMIN: USERS, OFFERS, INQUIRIES, PLANS
  // -----------------------------------------------------------
  static List<UserModel> adminUsers = [
    UserModel(
      id: 'u1',
      name: 'Manoj Mahi',
      mobile: '7972726558',
      city: 'Nagpur',
      email: 'manoj@example.com',
      avatar:
          'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=120',
      hasShop: true,
      membership: 'premium',
      joinDate: DateTime.now().subtract(const Duration(days: 200)),
    ),
    UserModel(
      id: 'u2',
      name: 'Rajesh Patil',
      mobile: '9823456701',
      city: 'Nagpur',
      email: 'rajesh@example.com',
      avatar:
          'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=120',
      hasShop: true,
      membership: 'basic',
      joinDate: DateTime.now().subtract(const Duration(days: 120)),
    ),
    UserModel(
      id: 'u3',
      name: 'Sunil Verma',
      mobile: '9988776655',
      city: 'Bhandara',
      email: 'sunil@example.com',
      avatar:
          'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=120',
      hasShop: true,
      membership: 'basic',
      joinDate: DateTime.now().subtract(const Duration(days: 60)),
    ),
    UserModel(
      id: 'u4',
      name: 'Ankita Joshi',
      mobile: '9156432109',
      city: 'Nagpur',
      email: 'ankita@example.com',
      avatar:
          'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=120',
      hasShop: true,
      membership: 'free',
      joinDate: DateTime.now().subtract(const Duration(days: 30)),
    ),
    UserModel(
      id: 'u5',
      name: 'Priya Singh',
      mobile: '9876543210',
      city: 'Pune',
      email: 'priya@example.com',
      avatar:
          'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=120',
      hasShop: false,
      membership: 'free',
      isActive: false,
      joinDate: DateTime.now().subtract(const Duration(days: 10)),
    ),
  ];

  static List<OfferModel> offers = [
    OfferModel(
      id: 'o1',
      title: 'New Year Special',
      description: 'Get 20% off on all premium subscriptions',
      discount: '20%',
      validTill: DateTime.now().add(const Duration(days: 30)),
    ),
    OfferModel(
      id: 'o2',
      title: 'Refer & Earn',
      description: 'Refer 3 friends and get 1 month free subscription',
      discount: '100%',
      validTill: DateTime.now().add(const Duration(days: 60)),
    ),
    OfferModel(
      id: 'o3',
      title: 'Multi Category Discount',
      description: 'Add 3 categories at flat ₹4500 instead of ₹5000',
      discount: '₹500',
      validTill: DateTime.now().add(const Duration(days: 15)),
      active: false,
    ),
  ];

  static List<SubscriptionPlanModel> plans = [
    SubscriptionPlanModel(
      id: 'pl1',
      name: 'Single Shop',
      price: 3000,
      duration: '1 Year',
      benefits: [
        'List shop in 1 category',
        'Featured for 6 months',
        'Customer leads via WhatsApp',
      ],
    ),
    SubscriptionPlanModel(
      id: 'pl2',
      name: 'Two Categories',
      price: 4000,
      duration: '1 Year',
      benefits: [
        '1st category: ₹3000',
        '2nd category: +₹1000',
        'Wider visibility',
      ],
    ),
    SubscriptionPlanModel(
      id: 'pl3',
      name: 'Three Categories',
      price: 5000,
      duration: '1 Year',
      benefits: [
        '1st category: ₹3000',
        '+₹1000 per extra category',
        'Maximum reach',
        'Priority support',
      ],
    ),
  ];

  static List<ContactInquiryModel> inquiries = [
    ContactInquiryModel(
      id: 'q1',
      name: 'Akash Verma',
      mobile: '9876541230',
      email: 'akash@example.com',
      message:
          'I want to add my furniture shop. Please call me at your earliest.',
      time: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    ContactInquiryModel(
      id: 'q2',
      name: 'Sneha Patil',
      mobile: '8765432109',
      email: 'sneha@example.com',
      message: 'How do I delete my account permanently?',
      time: DateTime.now().subtract(const Duration(days: 1)),
      resolved: true,
    ),
    ContactInquiryModel(
      id: 'q3',
      name: 'Vivek Joshi',
      mobile: '7654321098',
      email: 'vivek@example.com',
      message: 'Is there any discount for first 100 customers?',
      time: DateTime.now().subtract(const Duration(days: 2)),
    ),
  ];

  // -----------------------------------------------------------
  // CURRENT LOGGED IN USER (start fresh - no shop)
  // -----------------------------------------------------------
  static UserModel currentUser = UserModel(
    id: 'me',
    name: 'Abhijit Mahalle',
    mobile: '+91 1234567890',
    city: 'Nagpur',
    email: 'abhijit@example.com',
    avatar:
        'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=200',
    isAdmin: true, // demo: enable admin to access admin panel
    hasShop: false,
    joinDate: DateTime.now().subtract(const Duration(days: 5)),
  );




}
