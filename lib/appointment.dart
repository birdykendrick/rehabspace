import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rehabspace/homedash.dart';
import 'package:rehabspace/map.dart';
import 'package:rehabspace/settings.dart';
import 'package:table_calendar/table_calendar.dart';

class AppointmentCalendar extends StatefulWidget {
  const AppointmentCalendar({super.key});

  @override
  State<AppointmentCalendar> createState() => _AppointmentCalendarState();
}

class _AppointmentCalendarState extends State<AppointmentCalendar> {
  DateTime? selectedDate;
  List<Map<String, dynamic>> allAppointments = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchAppointmentsFromFirestore(); // pulls all the appointments from Firestore when the page loads
    selectedDate = DateTime.now(); // default selected date is today
  }

  // this grabs all appointments from Firestore and stores them locally
  Future<void> fetchAppointmentsFromFirestore() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('PhysioBookings').get();

      setState(() {
        allAppointments =
            snapshot.docs.map((doc) {
              final data = doc.data();
              return {
                'id': doc.id,
                'date': DateTime.parse(data['date_selected']),
                'therapist': data['therapist'],
                'time': data['time_selected'],
                'location': data['location'],
              };
            }).toList();
        isLoading = false; // done loading
      });
    } catch (e) {
      print('Error fetching appointments: $e');
      setState(() => isLoading = false);
    }
  }

  // filters all appointments based on the currently selected date
  List<Map<String, dynamic>> get selectedAppointments {
    if (selectedDate == null) return [];
    return allAppointments.where((a) {
      final date = a['date'] as DateTime;
      return date.year == selectedDate!.year &&
          date.month == selectedDate!.month &&
          date.day == selectedDate!.day;
    }).toList();
  }

  int _selectedIndex = 1;

  // handles bottom navigation bar taps and routes to different screens
  void _onTabTapped(int index) {
    if (index == _selectedIndex) return;

    setState(() => _selectedIndex = index);

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
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const SettingsPage()),
        );
        break;
    }
  }

  // shows a popup to confirm before deleting an appointment
  void _confirmDelete(BuildContext context, String id) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text("Cancel Appointment"),
            content: const Text(
              "Are you sure you want to cancel this appointment?",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("No"),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  await FirebaseFirestore.instance
                      .collection('PhysioBookings')
                      .doc(id)
                      .delete();
                  await fetchAppointmentsFromFirestore(); // refresh the list after deletion
                },
                child: const Text("Yes"),
              ),
            ],
          ),
    );
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
              ? const Center(
                child: CircularProgressIndicator(),
              ) // loading spinner
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
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            appointment['therapist'] ??
                                                'Unknown Therapist',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.delete,
                                              color: Colors.red,
                                            ),
                                            onPressed:
                                                () => _confirmDelete(
                                                  context,
                                                  appointment['id'],
                                                ),
                                          ),
                                        ],
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
