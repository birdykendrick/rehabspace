import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rehabspace/homedash.dart';
import 'package:rehabspace/map.dart';
import 'package:rehabspace/profile_page.dart';
import 'package:table_calendar/table_calendar.dart';
// import 'package:firebase_auth/firebase_auth.dart';

class AppointmentCalendar extends StatefulWidget {
  const AppointmentCalendar({super.key});

  @override
  State<AppointmentCalendar> createState() => _AppointmentCalendarState();
}

class _AppointmentCalendarState extends State<AppointmentCalendar> {
  DateTime? selectedDate;
  List<Map<String, dynamic>> allAppointments = [];
  bool isLoading = true;
  int _selectedIndex = 1;

  void _onTabTapped(int index) {
    if (index == _selectedIndex) return;

    setState(() {
      _selectedIndex = index;
    });

    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const MapScreen(),
        ), // Replace with your actual map page
      );
    } else if (index == 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const HomeDash(),
        ), // Replace with your home page
      );
    } else if (index == 2) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const ProfilePage(),
        ), // Optional: replace or stub
      );
    }
  }

  @override
  void initState() {
    super.initState();
    fetchAppointmentsFromFirestore();
    selectedDate = DateTime.now();
  }

  Future<void> fetchAppointmentsFromFirestore() async {
    // final uid = FirebaseAuth.instance.currentUser?.uid;
    // if (uid == null) return;
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('PhysioBookings').get();
      //   final snapshot = await FirebaseFirestore.instance
      // .collection('PhysioBookings')
      // .where('userId', isEqualTo: uid) // 🔑 Only fetch current user's bookings
      // .get();

      setState(() {
        allAppointments =
            snapshot.docs.map((doc) {
              final data = doc.data();
              return {
                'date': DateTime.parse(data['date_selected']),
                'therapist': data['therapist'],
                'time': data['time_selected'],
                'location': data['location'],
              };
            }).toList();
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching appointments: $e');
      setState(() => isLoading = false);
    }
  }

  List<Map<String, dynamic>> get selectedAppointments {
    if (selectedDate == null) return [];
    return allAppointments.where((a) {
      final date = a['date'] as DateTime;
      return date.year == selectedDate!.year &&
          date.month == selectedDate!.month &&
          date.day == selectedDate!.day;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Appointments'),
        backgroundColor: const Color(0xFF356899),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  const SizedBox(height: 16),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Select a Date",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  TableCalendar(
                    firstDay: DateTime(2000),
                    lastDay: DateTime(2100),
                    focusedDay: selectedDate!,
                    selectedDayPredicate:
                        (day) =>
                            selectedDate != null &&
                            day.year == selectedDate!.year &&
                            day.month == selectedDate!.month &&
                            day.day == selectedDate!.day,
                    onDaySelected: (selected, _) {
                      setState(() {
                        selectedDate = selected;
                      });
                    },

                    availableCalendarFormats: const {
                      CalendarFormat.month: 'Month',
                    },
                    calendarFormat: CalendarFormat.month,
                    calendarBuilders: CalendarBuilders(
                      markerBuilder: (context, date, _) {
                        final hasAppointments = allAppointments.any(
                          (a) =>
                              a['date'].year == date.year &&
                              a['date'].month == date.month &&
                              a['date'].day == date.day,
                        );
                        if (hasAppointments) {
                          return Positioned(
                            bottom: 1,
                            child: Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.blue,
                              ),
                            ),
                          );
                        }
                        return null;
                      },
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Appointments",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child:
                        selectedAppointments.isEmpty
                            ? const Center(
                              child: Text("No appointments on this date."),
                            )
                            : ListView.builder(
                              itemCount: selectedAppointments.length,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              itemBuilder: (context, index) {
                                final appointment = selectedAppointments[index];
                                return Container(
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 6,
                                  ),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Colors.black12,
                                        blurRadius: 4,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        appointment['therapist'] ??
                                            'Unknown Therapist',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        appointment['time'] ?? 'No time',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        appointment['location'] ??
                                            'No location',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                  ),
                ],
              ),
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
