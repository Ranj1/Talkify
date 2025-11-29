import 'package:get/get.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';
import 'call_controller.dart';

class UserController extends GetxController {
  // Reactive variables for state management
  final RxList<Map<String, dynamic>> usersList = <Map<String, dynamic>>[].obs;
  final RxBool isLoadingUsers = false.obs;
  final RxString searchQuery = ''.obs;
  final RxList<Map<String, dynamic>> filteredUsers = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    // Initialize controller with sample data
    //_loadSampleUsers();
    fetchUsersList();
  }

  @override
  void onReady() {
    super.onReady();
    // Controller is ready
    // Fetch initial user data
  }

  @override
  void onClose() {
    // Clean up resources
    super.onClose();
  }

  // Load sample users for demonstration
  void _loadSampleUsers() {
    usersList.value = [
      {
        'id': '1',
        'name': 'John Doe',
        'avatar': null, // Use null to show default person icon
        'isOnline': true,
        'lastSeen': 'Online now',
        'phone': '+1 234 567 8901',
      },
      {
        'id': '2',
        'name': 'Jane Smith',
        'avatar': null, // Use null to show default person icon
        'isOnline': false,
        'lastSeen': '2 hours ago',
        'phone': '+1 234 567 8902',
      },
      {
        'id': '3',
        'name': 'Mike Johnson',
        'avatar': null, // Use null to show default person icon
        'isOnline': true,
        'lastSeen': 'Online now',
        'phone': '+1 234 567 8903',
      },
      {
        'id': '4',
        'name': 'Sarah Wilson',
        'avatar': null, // Use null to show default person icon
        'isOnline': false,
        'lastSeen': '1 day ago',
        'phone': '+1 234 567 8904',
      },
      {
        'id': '5',
        'name': 'David Brown',
        'avatar': null, // Use null to show default person icon
        'isOnline': true,
        'lastSeen': 'Online now',
        'phone': '+1 234 567 8905',
      },
      {
        'id': '6',
        'name': 'Lisa Davis',
        'avatar': null, // Use null to show default person icon
        'isOnline': false,
        'lastSeen': '3 hours ago',
        'phone': '+1 234 567 8906',
      },
    ];
    filteredUsers.value = List.from(usersList);
  }

  // Fetch and manage user list from backend database
  Future<void> fetchUsersList({
    int page = 1,
    int limit = 20,
    String search = '',
    bool onlineOnly = false,
  }) async {
    isLoadingUsers.value = true;
    print("ranjana");
    try {
      print('🔄 Fetching users from backend database...');
      
      // Fetch from backend API with parameters
      final users = await ApiService.getUsersList(
        page: page,
        limit: limit,
        search: search,
        onlineOnly: onlineOnly,
      );

      if (users.isNotEmpty) {
        // Transform backend data to match UI expectations
        final transformedUsers = users.map((user) => {
          'id': user['uid'] ?? user['_id'],
          'uid': user['uid'],
          'name': user['name'] ?? 'Unknown User',
          'avatar': user['profilePicture'],
          'isOnline': user['isOnline'] ?? false,
          'lastSeen': _formatLastSeen(user['lastSeen']),
          'phone': user['phone'] ?? 'No phone',
        }).toList();
        
        usersList.value = transformedUsers;
        filteredUsers.value = List.from(usersList);
        print('✅ ${users.length} users fetched from database');
        
        Get.snackbar(
          'Success',
          'Fetched ${users.length} users from database',
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 2),
          backgroundColor: Get.theme.primaryColor,
          colorText: Get.theme.colorScheme.onPrimary,
        );
      } else {
        // Fallback to sample data if no users found
        _loadSampleUsers();
        print('⚠️ No users found in database, using sample data');
        
        Get.snackbar(
          'Info',
          'No users found in database, showing sample data',
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 3),
        );
      }
    } catch (e) {
      print('❌ Database fetch failed: $e');
      // Fallback to sample data
      _loadSampleUsers();
      Get.snackbar(
        'Error',
        'Failed to fetch users: ${e.toString()}',
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 4),
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
    } finally {
      isLoadingUsers.value = false;
    }
  }
  
  // Format last seen timestamp
  String _formatLastSeen(dynamic lastSeen) {
    if (lastSeen == null) return 'Unknown';
    
    try {
      final date = DateTime.parse(lastSeen.toString());
      final now = DateTime.now();
      final difference = now.difference(date);
      
      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h ago';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}d ago';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return 'Unknown';
    }
  }

  void refreshUsersList() {
    fetchUsersList();
  }
  
  // Search users in backend database
  Future<void> searchUsersInDatabase(String query) async {
    searchQuery.value = query;
    
    if (query.isEmpty) {
      // If search is empty, fetch all users
      await fetchUsersList();
    } else {
      // Search in backend database
      await fetchUsersList(search: query);
    }
  }
  
  // Filter online users only
  Future<void> filterOnlineUsers() async {
    await fetchUsersList(onlineOnly: true);
  }
  
  // Load more users (pagination)
  Future<void> loadMoreUsers() async {
    final currentPage = (usersList.length / 20).ceil() + 1;
    await fetchUsersList(page: currentPage);
  }

  // Search and filter users (local filtering for immediate response)
  void searchUsers(String query) {
    searchQuery.value = query;
    if (query.isEmpty) {
      filteredUsers.value = List.from(usersList);
    } else {
      filteredUsers.value = usersList
          .where((user) => 
            user['name'].toLowerCase().contains(query.toLowerCase()) ||
            user['phone'].toString().contains(query)
          )
          .toList();
    }
  }

  void clearSearch() {
    searchQuery.value = '';
    filteredUsers.value = List.from(usersList);
  }

  // Audio call action
  void audioCall(Map<String, dynamic> user) {
    final targetUserId = user['uid'] ?? user['id'];
    final userName = user['name'] ?? 'Unknown';
    
    if (targetUserId == null) {
      Get.snackbar('Error', 'User ID not found', snackPosition: SnackPosition.TOP);
      return;
    }
    
    // Check if Socket.IO is connected
    if (!SocketService.isConnected) {
      Get.snackbar(
        'Connection Error',
        'Not connected to server. Please try again.',
        snackPosition: SnackPosition.TOP,
      );
      return;
    }
    
    // Get or create CallController
    CallController callController;
    try {
      callController = Get.find<CallController>();
    } catch (e) {
      callController = Get.put(CallController());
    }
    
    // Initiate call
    callController.initiateCall(targetUserId, 'audio', userName);
    
    // Navigate to call page
    Get.toNamed('/calling', arguments: {
      'user': user,
      'callType': 'audio',
      'isIncoming': false,
    });
  }

  // Video call action
  void videoCall(Map<String, dynamic> user) {
    final targetUserId = user['uid'] ?? user['id'];
    final userName = user['name'] ?? 'Unknown';
    
    if (targetUserId == null) {
      Get.snackbar('Error', 'User ID not found', snackPosition: SnackPosition.TOP);
      return;
    }
    
    // Check if Socket.IO is connected
    if (!SocketService.isConnected) {
      Get.snackbar(
        'Connection Error',
        'Not connected to server. Please try again.',
        snackPosition: SnackPosition.TOP,
      );
      return;
    }
    
    // Get or create CallController
    CallController callController;
    try {
      callController = Get.find<CallController>();
    } catch (e) {
      callController = Get.put(CallController());
    }
    
    // Initiate call
    callController.initiateCall(targetUserId, 'video', userName);
    
    // Navigate to call page
    Get.toNamed('/calling', arguments: {
      'user': user,
      'callType': 'video',
      'isIncoming': false,
    });
  }
}
