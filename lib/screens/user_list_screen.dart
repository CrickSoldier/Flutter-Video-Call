import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../providers/auth_provider.dart';
import 'video_call_screen.dart';

class UserListScreen extends StatefulWidget {
  const UserListScreen({super.key});

  @override
  _UserListScreenState createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Provider.of<UserProvider>(context, listen: false).fetchUsers();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      Provider.of<UserProvider>(context, listen: false).fetchUsers();
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('User List'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Provider.of<AuthProvider>(context, listen: false).logout();
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/login',
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: OrientationBuilder(
        builder: (context, orientation) {
          return userProvider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : userProvider.errorMessage != null && userProvider.users.isEmpty
              ? Center(child: Text(userProvider.errorMessage!))
              : RefreshIndicator(
                  onRefresh: () => userProvider.fetchUsers(),
                  child: ListView.builder(
                    itemCount: userProvider.users.length,
                    itemBuilder: (context, index) {
                      final user = userProvider.users[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: CachedNetworkImageProvider(
                            user.avatar,
                          ),
                          onBackgroundImageError: (_, __) =>
                              const Icon(Icons.error),
                        ),
                        title: Text('${user.firstName} ${user.lastName}'),
                        subtitle: Text(user.email),
                      );
                    },
                  ),
                );
        },
      ),
    );
  }
}
