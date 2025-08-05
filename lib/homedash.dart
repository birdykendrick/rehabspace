import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rehabspace/BookPhysioPage.dart';
import 'package:rehabspace/appointment.dart';
import 'package:rehabspace/chat_page.dart';
import 'package:rehabspace/map.dart';
import 'package:rehabspace/progress.dart';
import 'package:rehabspace/settings.dart';

class HomeDash extends StatefulWidget {
  const HomeDash({super.key});

  @override
  State<HomeDash> createState() => _HomeDashState();
}

class _HomeDashState extends State<HomeDash> {
  String? displayName;
  bool isLoading = true;
  Map<String, dynamic>? nextAppointment;
  String? doctorPhotoUrl;
  List<Map<String, dynamic>> _reminders = [];

  int _selectedIndex = 1;

  @override
  void initState() {
    super.initState();
    _loadDisplayName(); // get user name
    _loadNextAppointment(); // get the next upcoming appointment
    _loadReminders(); // fetch reminder list
  }

  void _onTabTapped(int index) {
    if (index == _selectedIndex) return;

    setState(() => _selectedIndex = index);

    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MapScreen()),
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeDash()),
        );
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const SettingsPage()),
        );
        break;
    }
  }

  // grab the user display name from Firestore
  Future<void> _loadDisplayName() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final doc =
          await FirebaseFirestore.instance
              .collection('loginData')
              .doc(uid)
              .get();
      if (doc.exists) {
        setState(() {
          displayName = doc['displayName'] ?? 'User';
          isLoading = false;
        });
      }
    }
  }

  // get all future appointments for this user and show the soonest one
  Future<void> _loadNextAppointment() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final now = DateTime.now();

    final snapshot =
        await FirebaseFirestore.instance
            .collection('PhysioBookings')
            .where('userId', isEqualTo: user.uid)
            .get();

    final upcoming =
        snapshot.docs.map((doc) => doc.data()).where((data) {
          final dateStr = data['date_selected'] as String?;
          if (dateStr == null) return false;
          final date = DateTime.tryParse(dateStr);
          return date != null && date.isAfter(now);
        }).toList();

    upcoming.sort(
      (a, b) => DateTime.parse(
        a['date_selected'],
      ).compareTo(DateTime.parse(b['date_selected'])),
    );

    if (upcoming.isNotEmpty) {
      final data = upcoming.first;
      setState(() => nextAppointment = data);

      final therapistName = data['therapist'];
      if (therapistName != null) {
        final doctorSnap =
            await FirebaseFirestore.instance
                .collection('Doctors')
                .where('name', isEqualTo: therapistName)
                .limit(1)
                .get();

        if (doctorSnap.docs.isNotEmpty) {
          setState(
            () => doctorPhotoUrl = doctorSnap.docs.first.data()['photoUrl'],
          );
        }
      }
    } else {
      setState(() => nextAppointment = null);
    }
  }

  // load reminders from Firestore
  Future<void> _loadReminders() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final snapshot =
        await FirebaseFirestore.instance
            .collection('reminders')
            .doc(uid)
            .collection('items')
            .get();

    setState(() {
      _reminders =
          snapshot.docs
              .map((doc) => {'id': doc.id, 'text': doc['text']})
              .toList();
    });
  }

  // add reminder to Firestore
  Future<void> _addReminder(String text) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final docRef = await FirebaseFirestore.instance
        .collection('reminders')
        .doc(uid)
        .collection('items')
        .add({'text': text});

    setState(() {
      _reminders.add({'id': docRef.id, 'text': text});
    });
  }

  // remove reminder from Firestore
  Future<void> _removeReminder(String id) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await FirebaseFirestore.instance
        .collection('reminders')
        .doc(uid)
        .collection('items')
        .doc(id)
        .delete();

    setState(() {
      _reminders.removeWhere((r) => r['id'] == id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      body: ListView(
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildActionsSection(context),
          const SizedBox(height: 32),
          _buildUpcomingAppointmentSection(),
          const SizedBox(height: 24),
          _buildRemindersSection(),
          const SizedBox(height: 40),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onTabTapped,
        selectedItemColor: const Color.fromARGB(255, 9, 95, 255),
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

  // greeting section with display name and app logo
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
      decoration: const BoxDecoration(
        color: Color(0xFF256899),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Welcome Back!',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 4),
              isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                    '$displayName 👋',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
            ],
          ),
          const CircleAvatar(
            radius: 24,
            backgroundImage: AssetImage("assets/logo.png"),
          ),
        ],
      ),
    );
  }

  // shows 4 main options: Book, Chat, Appointments, Progress
  Widget _buildActionsSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "How can we help you today?",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0D0D26),
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 3.2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: [
              _buildActionCard(context, Icons.event_note, "Book Physio"),
              _buildActionCard(
                context,
                Icons.chat_bubble_outline,
                "AI Chatbot",
              ),
              _buildActionCard(context, Icons.calendar_month, "Appointments"),
              _buildActionCard(context, Icons.bar_chart, "My Progress"),
            ],
          ),
        ],
      ),
    );
  }

  // show info about the user's next appointment
  Widget _buildUpcomingAppointmentSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Your Upcoming Appointment",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0D0D26),
            ),
          ),
          const SizedBox(height: 12),
          nextAppointment == null
              ? const Text("No upcoming appointments.")
              : Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF356899),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundImage:
                          doctorPhotoUrl != null
                              ? NetworkImage(doctorPhotoUrl!)
                              : const AssetImage("assets/Doctor_picture.jpg")
                                  as ImageProvider,
                      radius: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nextAppointment!['therapist'] ?? "Your Physio",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.calendar_today,
                                color: Colors.white,
                                size: 14,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _formatDate(nextAppointment!['date_selected']),
                                style: const TextStyle(color: Colors.white),
                              ),
                              const SizedBox(width: 12),
                              const Icon(
                                Icons.access_time,
                                color: Colors.white,
                                size: 14,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                nextAppointment!['time_selected'] ?? "N/A",
                                style: const TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }

  // show reminders list + add option
  Widget _buildRemindersSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Reminders",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0D0D26),
            ),
          ),
          const SizedBox(height: 8),
          ..._reminders.map(
            (r) => Row(
              children: [
                Checkbox(
                  value: false,
                  onChanged: (_) => _removeReminder(r['id']),
                ),
                Expanded(child: Text(r['text'])),
              ],
            ),
          ),
          const SizedBox(height: 6),
          TextButton.icon(
            onPressed: _showAddReminderDialog,
            icon: const Icon(Icons.add),
            label: const Text("Add Reminder"),
          ),
        ],
      ),
    );
  }

  // reusable action card builder
  Widget _buildActionCard(BuildContext context, IconData icon, String label) {
    return GestureDetector(
      onTap: () async {
        if (label == "Book Physio") {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const BookPhysioPage()),
          );
          if (result == true) _loadNextAppointment();
        } else if (label == "AI Chatbot") {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ChatPage()),
          );
        } else if (label == "Appointments") {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AppointmentCalendar()),
          );
        } else if (label == "My Progress") {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const WeeklyProgress()),
          );
        }
      },
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE1E1E8)),
          borderRadius: BorderRadius.circular(10),
          color: Colors.white,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF356899)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, size: 20),
          ],
        ),
      ),
    );
  }

  // formats ISO date string into dd/mm/yyyy
  String _formatDate(String isoString) {
    final date = DateTime.tryParse(isoString);
    if (date == null) return "Unknown";
    return "${date.day}/${date.month}/${date.year}";
  }

  // popup to add a new reminder
  void _showAddReminderDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text("New Reminder"),
            content: TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: "Enter your reminder",
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () {
                  final text = controller.text.trim();
                  if (text.isNotEmpty) {
                    _addReminder(text);
                  }
                  Navigator.pop(ctx);
                },
                child: const Text("Add"),
              ),
            ],
          ),
    );
  }
}
