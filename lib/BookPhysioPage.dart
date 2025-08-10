import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rehabspace/map.dart';
import 'package:rehabspace/homedash.dart';
import 'package:rehabspace/settings.dart';

class BookPhysioPage extends StatefulWidget {
  const BookPhysioPage({super.key});

  @override
  State<BookPhysioPage> createState() => _BookPhysioPageState();
}

class _BookPhysioPageState extends State<BookPhysioPage> {
  final TextEditingController _remarksController = TextEditingController();

  DateTime? _selectedDate;
  String? _selectedTime;
  String? _selectedTherapist;
  String? _selectedLocation;

  int _selectedIndex = 1;

  final List<String> timeSlots = [
    '10am - 11am',
    '11am - 12pm',
    '1:30pm - 2:30pm',
    '2:30pm - 3:30pm',
    '3:30pm - 4:30pm',
    '4:30pm - 6pm',
  ];

  final List<String> therapists = [
    'Dr. Lester Law',
    'Dr. Kendrick Khoo',
    'Dr. Chris',
  ];

  List<String> _locations = [];

  // pulls all clinic names from Firestore to show in the location dropdown
  Future<void> _fetchLocations() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('maplocations').get();

    setState(() {
      _locations =
          snapshot.docs
              .map((doc) => doc['name'] as String)
              .where((name) => name.isNotEmpty)
              .toList();
    });
  }

  @override
  void initState() {
    super.initState();
    _fetchLocations(); // run this when the screen loads
  }

  // when user hits "submit", this function checks if everything’s filled and then books the appointment
  void _submitBooking() async {
    if (_selectedTherapist == null ||
        _selectedTime == null ||
        _selectedLocation == null ||
        _selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all required fields")),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance.collection('PhysioBookings').add({
      'userId': user.uid,
      'therapist': _selectedTherapist,
      'date_selected': _selectedDate!.toIso8601String(),
      'time_selected': _selectedTime,
      'location': _selectedLocation,
      'remarks': _remarksController.text.trim(),
      'createdAt': Timestamp.now(),
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Appointment Booked!")));

    Navigator.pop(context, true); // go back to previous screen
  }

  // handles bottom nav taps: lets user jump between map/home/settings
  void _onTabTapped(int index) {
    if (index == _selectedIndex) return;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Book Physio"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1),
        ),
        surfaceTintColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: ListView(
          children: [
            const SizedBox(height: 12),
            const Text(
              "Fill up this form to book an appointment",
              style: TextStyle(color: Colors.black, fontSize: 16),
            ),
            const SizedBox(height: 24),

            // LOCATION
            _FormSectionCard(
              title: 'Clinic',
              children: [
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  value: _selectedLocation,
                  decoration: _boldInputDecoration(
                    labelText: 'Select Clinic Location',
                  ),
                  items:
                      _locations.map((location) {
                        return DropdownMenuItem(
                          value: location,
                          child: Text(location),
                        );
                      }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedLocation = value;
                    });
                  },
                  validator:
                      (value) =>
                          value == null ? 'Please select a location' : null,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // THERAPIST + DATE
            _FormSectionCard(
              title: 'Appointment',
              children: [
                DropdownButtonFormField<String>(
                  value: _selectedTherapist,
                  hint: const Text("Select Your Therapist"),
                  items:
                      therapists.map((name) {
                        return DropdownMenuItem(value: name, child: Text(name));
                      }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedTherapist = value;
                    });
                  },
                  decoration: _boldInputDecoration(
                    prefixIcon: const Icon(Icons.person_outline),
                    labelText: 'Therapist',
                  ),
                ),
                const SizedBox(height: 5),
                TextFormField(
                  readOnly: true,
                  decoration: _boldInputDecoration(
                    prefixIcon: const Icon(Icons.calendar_today_outlined),
                    hintText:
                        _selectedDate == null
                            ? 'Select Date'
                            : '${_selectedDate!.day} ${_selectedDate!.month}, ${_selectedDate!.year}',
                    labelText: 'Date',
                  ),
                  onTap: () async {
                    DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) {
                      setState(() {
                        _selectedDate = picked;
                      });
                    }
                  },
                ),
              ],
            ),

            const SizedBox(height: 16),

            // TIMESLOTS
            _FormSectionCard(
              title: 'Time Slot',
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      timeSlots.map((slot) {
                        final isSelected = _selectedTime == slot;
                        return ChoiceChip(
                          label: Text(slot),
                          selected: isSelected,
                          onSelected: (_) {
                            setState(() {
                              _selectedTime = slot;
                            });
                          },
                          selectedColor: const Color.fromARGB(
                            255,
                            67,
                            155,
                            238,
                          ), // keep yours
                          backgroundColor: Colors.grey[200],
                          labelStyle: TextStyle(
                            color:
                                isSelected
                                    ? Colors.white
                                    : const Color.fromARGB(255, 0, 0, 0),
                          ),
                        );
                      }).toList(),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // REMARKS
            _FormSectionCard(
              title: 'Remarks',
              children: [
                TextFormField(
                  controller: _remarksController,
                  maxLines: 3,
                  decoration: _boldInputDecoration(
                    prefixIcon: const Icon(Icons.mail_outline),
                    hintText: 'Remarks',
                    labelText: 'Remarks',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // SUBMIT
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[200], // keep your original
                ),
                onPressed: _submitBooking,
                child: const Text("Submit"),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onTabTapped,
        selectedItemColor: const Color(0xFF356899),
        unselectedItemColor: Colors.blue[100],
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

/// Bold outline for all inputs (TextField / Dropdown)
InputDecoration _boldInputDecoration({
  String? labelText,
  String? hintText,
  Widget? prefixIcon,
}) {
  const borderColor = Color(0xFF356899);
  const boldSide = BorderSide(color: borderColor, width: 2);

  return const InputDecoration().copyWith(
    labelText: labelText,
    hintText: hintText,
    prefixIcon: prefixIcon,
    enabledBorder: const OutlineInputBorder(
      borderSide: boldSide,
      borderRadius: BorderRadius.all(Radius.circular(12)),
    ),
    focusedBorder: const OutlineInputBorder(
      borderSide: boldSide,
      borderRadius: BorderRadius.all(Radius.circular(12)),
    ),
    errorBorder: const OutlineInputBorder(
      borderSide: BorderSide(color: Colors.red, width: 2),
      borderRadius: BorderRadius.all(Radius.circular(12)),
    ),
    focusedErrorBorder: const OutlineInputBorder(
      borderSide: BorderSide(color: Colors.red, width: 2),
      borderRadius: BorderRadius.all(Radius.circular(12)),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    filled: true,
    fillColor: Colors.white,
  );
}

/// Card with bold outline to group fields
class _FormSectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _FormSectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(
          color: Color(0xFF356899), // same accent as inputs
          width: 2.0, // bold outline
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF356899),
              ),
            ),
            const SizedBox(height: 12),
            ..._withDividers(children),
          ],
        ),
      ),
    );
  }

  // adds spacing between child widgets
  List<Widget> _withDividers(List<Widget> items) {
    final result = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      result.add(items[i]);
      if (i != items.length - 1) {
        result.add(const SizedBox(height: 12));
      }
    }
    return result;
  }
}
