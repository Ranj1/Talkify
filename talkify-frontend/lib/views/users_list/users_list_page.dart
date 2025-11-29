import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme.dart';
import '../../widgets/user_tile.dart';
import '../../getx_controllers/user_controller.dart';

class UsersListPage extends StatelessWidget {
  const UsersListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return GetX<UserController>(
      init: Get.isRegistered<UserController>() ? Get.find<UserController>() : Get.put(UserController()),
      builder: (controller) {
        // Fetch users from database when page loads
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (controller.usersList.isEmpty && !controller.isLoadingUsers.value) {
            controller.fetchUsersList();
          }
        });

    return Scaffold(
          backgroundColor: AppColors.lightBackground,
          appBar: _buildAppBar(context, isTablet),
          body: Column(
            children: [
              // Search Bar
              _buildSearchBar(controller, isTablet),
              
              // Filter Tabs
              _buildFilterTabs(controller, isTablet),
              
              // Users List
              Expanded(
                child: _buildUsersList(controller, isTablet),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Builds the app bar with theme consistency
  PreferredSizeWidget _buildAppBar(BuildContext context, bool isTablet) {
    return AppBar(
      title: Text(
        'Users',
        style: TextStyle(
          fontSize: isTablet ? 24 : 20,
          fontWeight: FontWeight.bold,
          color: AppColors.white,
        ),
      ),
      backgroundColor: AppColors.primaryGradientStart,
        elevation: 0,
      centerTitle: true,
        actions: [
          IconButton(
          icon: Icon(
            Icons.refresh,
            color: AppColors.white,
            size: isTablet ? 24 : 20,
          ),
          onPressed: () => Get.find<UserController>().refreshUsersList(),
        ),
          IconButton(
          icon: Icon(
            Icons.more_vert,
            color: AppColors.white,
            size: isTablet ? 24 : 20,
          ),
            onPressed: () {
            Get.snackbar(
              'Menu',
              'Settings and options coming soon!',
              snackPosition: SnackPosition.TOP,
              backgroundColor: AppColors.primaryGradientStart,
              colorText: AppColors.white,
              );
            },
          ),
        ],
    );
  }

  /// Builds the search bar
  Widget _buildSearchBar(UserController controller, bool isTablet) {
    return Container(
      margin: EdgeInsets.all(isTablet ? 20 : 16),
      padding: EdgeInsets.symmetric(horizontal: isTablet ? 20 : 16),
            decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
            color: AppColors.primaryGradientStart.withOpacity(0.1),
            blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
      child: TextField(
        onChanged: (value) {
          // Use local search for immediate response
          controller.searchUsers(value);
          // Also search in database with debounce
          Future.delayed(const Duration(milliseconds: 500), () {
            if (value == controller.searchQuery.value) {
              controller.searchUsersInDatabase(value);
            }
          });
        },
              decoration: InputDecoration(
          hintText: 'Search users...',
          hintStyle: TextStyle(
            color: AppColors.grey,
            fontSize: isTablet ? 16 : 14,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: AppColors.primaryGradientStart,
            size: isTablet ? 24 : 20,
          ),
          suffixIcon: controller.searchQuery.value.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear,
                    color: AppColors.grey,
                    size: isTablet ? 20 : 18,
                  ),
                  onPressed: () => controller.clearSearch(),
                )
              : null,
                border: InputBorder.none,
        ),
        style: TextStyle(
          fontSize: isTablet ? 16 : 14,
          color: AppColors.darkGrey,
        ),
      ),
    );
  }

  /// Builds the filter tabs
  Widget _buildFilterTabs(UserController controller, bool isTablet) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: isTablet ? 20 : 16),
      child: Row(
        children: [
          _buildFilterTab('All Users', true, controller, isTablet),
          SizedBox(width: isTablet ? 16 : 12),
          _buildFilterTab('Online', false, controller, isTablet),
          SizedBox(width: isTablet ? 16 : 12),
          _buildFilterTab('Favorites', false, controller, isTablet),
        ],
      ),
    );
  }

  /// Builds individual filter tab
  Widget _buildFilterTab(String title, bool isSelected, UserController controller, bool isTablet) {
    return GestureDetector(
      onTap: () {
        if (title == 'All Users') {
          controller.fetchUsersList();
        } else if (title == 'Online') {
          controller.filterOnlineUsers();
        } else if (title == 'Favorites') {
          Get.snackbar(
            'Favorites',
            'Favorites feature coming soon!',
            snackPosition: SnackPosition.TOP,
            backgroundColor: AppColors.primaryGradientStart,
            colorText: AppColors.white,
          );
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 20 : 16,
          vertical: isTablet ? 12 : 8,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryGradientStart : AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primaryGradientStart : AppColors.grey.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? AppColors.white : AppColors.darkGrey,
            fontSize: isTablet ? 14 : 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  /// Builds the users list
  Widget _buildUsersList(UserController controller, bool isTablet) {
    if (controller.isLoadingUsers.value) {
      return _buildLoadingState(isTablet);
    }

    if (controller.filteredUsers.isEmpty) {
      return _buildEmptyState(isTablet);
    }

    return RefreshIndicator(
      onRefresh: () async => controller.refreshUsersList(),
      color: AppColors.primaryGradientStart,
      child: ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: isTablet ? 20 : 16),
        itemCount: controller.filteredUsers.length,
        itemBuilder: (context, index) {
          final user = controller.filteredUsers[index];
          return Padding(
            padding: EdgeInsets.only(bottom: isTablet ? 16 : 12),
            child: UserTile(
              user: user,
              onAudioCall: () => controller.audioCall(user),
              onVideoCall: () => controller.videoCall(user),
              isTablet: isTablet,
            ),
          );
        },
      ),
    );
  }

  /// Builds loading state
  Widget _buildLoadingState(bool isTablet) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: isTablet ? 80 : 60,
            height: isTablet ? 80 : 60,
            decoration: BoxDecoration(
              color: AppColors.primaryGradientStart.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGradientStart),
              ),
            ),
          ),
          SizedBox(height: isTablet ? 20 : 16),
                            Text(
            'Loading users...',
                              style: TextStyle(
              fontSize: isTablet ? 16 : 14,
              color: AppColors.darkGrey,
                              ),
                            ),
                          ],
                        ),
    );
  }

  /// Builds empty state
  Widget _buildEmptyState(bool isTablet) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
                      Container(
            width: isTablet ? 120 : 100,
            height: isTablet ? 120 : 100,
                        decoration: BoxDecoration(
              color: AppColors.primaryGradientStart.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
            child: Icon(
              Icons.people_outline,
              size: isTablet ? 60 : 50,
              color: AppColors.primaryGradientStart,
            ),
          ),
          SizedBox(height: isTablet ? 20 : 16),
          Text(
            'No users found',
            style: TextStyle(
              fontSize: isTablet ? 18 : 16,
              fontWeight: FontWeight.w600,
              color: AppColors.darkGrey,
            ),
          ),
          SizedBox(height: isTablet ? 8 : 6),
          Text(
            'Try adjusting your search or filters',
            style: TextStyle(
              fontSize: isTablet ? 14 : 12,
              color: AppColors.grey,
            ),
          ),
        ],
      ),
    );
  }


}