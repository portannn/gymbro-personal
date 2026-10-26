import 'package:flutter/material.dart';
import '../../utils/admin_colors.dart';
import '../../services/admin_service.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  final AdminService _adminService = AdminService();
  List<dynamic> _users = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await _adminService.getAllUsers();

    if (mounted) {
      if (result['success'] == true) {
        setState(() {
          _users = result['data'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = result['message'];
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminColors.bgColor,
      appBar: AppBar(
        title: const Text('Manage Users', style: TextStyle(color: AdminColors.textPrimary)),
        backgroundColor: AdminColors.cardColor,
        iconTheme: const IconThemeData(color: AdminColors.textPrimary),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchUsers,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AdminColors.accentColor))
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.redAccent, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: AdminColors.accentColor),
                        onPressed: _fetchUsers,
                        child: const Text('Coba Lagi', style: TextStyle(color: Colors.black)),
                      ),
                    ],
                  ),
                )
              : _users.isEmpty
                  ? const Center(
                      child: Text(
                        'Belum ada user',
                        style: TextStyle(color: AdminColors.textSecondary, fontSize: 16),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _users.length,
                      itemBuilder: (context, index) {
                        final user = _users[index];
                        final role = user['role'] ?? 'user';
                        final bool isAdmin = role == 'admin';

                        return Card(
                          color: AdminColors.cardColor,
                          margin: const EdgeInsets.only(bottom: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading: CircleAvatar(
                              backgroundColor: isAdmin ? AdminColors.accentColor : Colors.grey[800],
                              child: Text(
                                user['full_name']?.substring(0, 1).toUpperCase() ?? 'U',
                                style: TextStyle(
                                  color: isAdmin ? Colors.black : AdminColors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              user['full_name'] ?? 'Unknown User',
                              style: const TextStyle(
                                color: AdminColors.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  user['email'] ?? '',
                                  style: const TextStyle(color: AdminColors.textSecondary),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isAdmin ? AdminColors.accentColor.withValues(alpha: 0.2) : Colors.white10,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: isAdmin ? AdminColors.accentColor : Colors.white24,
                                    ),
                                  ),
                                  child: Text(
                                    role.toUpperCase(),
                                    style: TextStyle(
                                      color: isAdmin ? AdminColors.accentColor : AdminColors.textSecondary,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
