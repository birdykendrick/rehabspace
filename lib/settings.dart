import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rehabspace/loginpage.dart';
import 'package:rehabspace/map.dart';
import 'package:rehabspace/homedash.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  int _selectedIndex = 2; // The tab index for "Settings"

  /// Handles bottom navigation between Map, Home, and Settings
  void _onTabTapped(int index) {
    if (index == _selectedIndex) return; // Do nothing if already selected

    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MapScreen()),
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeDash()),
        );
        break;
      case 2:
        // Already on settings page
        break;
    }
  }

  /// Retrieves the current user's profile details from Firestore.
  Future<Map<String, dynamic>?> _getProfileData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    DocumentSnapshot doc =
        await FirebaseFirestore.instance
            .collection('loginData')
            .doc(user.uid)
            .get();

    return doc.data() as Map<String, dynamic>?;
  }

  /// Sends a password reset email to the user's registered email.
  Future<void> _changePassword(BuildContext context) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null && user.email != null) {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: user.email!);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password reset email sent!")),
      );
    }
  }

  /// Lets the user pick a new Date of Birth and updates it in Firestore.
  Future<void> _changeDob(BuildContext context) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (pickedDate != null) {
      await FirebaseFirestore.instance
          .collection('loginData')
          .doc(user.uid)
          .update({'dob': pickedDate.toIso8601String()});

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Date of Birth updated!")));
    }
  }

  /// Logs the user out and clears navigation history.
  Future<void> _logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => LoginPage()),
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Logout failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: _SettingsBody(
        getProfileData: _getProfileData,
        changePassword: _changePassword,
        changeDob: _changeDob,
        logout: _logout,
      ),

      // Bottom navigation for switching between pages
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onTabTapped,
        selectedItemColor: const Color(0xFF356899),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.map), label: "Map"),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: "Settings",
          ),
        ],
      ),
    );
  }
}

class _SettingsBody extends StatelessWidget {
  final Future<Map<String, dynamic>?> Function() getProfileData;
  final Future<void> Function(BuildContext) changePassword;
  final Future<void> Function(BuildContext) changeDob;
  final Future<void> Function(BuildContext) logout;

  const _SettingsBody({
    required this.getProfileData,
    required this.changePassword,
    required this.changeDob,
    required this.logout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: const Color(0xFFF7F9FC),
      child: ListView(
        children: [
          const _SectionHeader(title: 'Account'),
          _SettingsCard(
            children: [
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('View Profile Details'),
                onTap: () async {
                  final profileData = await getProfileData();
                  if (profileData != null) {
                    showDialog(
                      context: context,
                      builder:
                          (_) => AlertDialog(
                            title: const Text('Profile Details'),
                            content: Text(
                              'Name: ${profileData['displayName'] ?? 'N/A'}\n'
                              'Email: ${profileData['email'] ?? 'N/A'}\n'
                              'DOB: ${profileData['dob'] ?? 'N/A'}',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Close'),
                              ),
                            ],
                          ),
                    );
                  }
                },
              ),
              const Divider(height: 0),
              ListTile(
                leading: const Icon(Icons.lock),
                title: const Text('Change Password'),
                onTap: () => changePassword(context),
              ),
              const Divider(height: 0),
              ListTile(
                leading: const Icon(Icons.cake),
                title: const Text('Change Date of Birth'),
                onTap: () => changeDob(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const _SectionHeader(title: 'Session'),
          _SettingsCard(
            children: [
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Logout'),
                onTap: () => logout(context),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Colors.black, width: 2.0),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children:
            children.map((w) {
              if (w is ListTile) {
                return ListTile(
                  leading: w.leading,
                  title: w.title,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: w.onTap,
                  visualDensity: VisualDensity.comfortable,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                );
              }
              return w;
            }).toList(),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: const Color(0xFF5A6A7A),
          letterSpacing: .2,
        ),
      ),
    );
  }
}
