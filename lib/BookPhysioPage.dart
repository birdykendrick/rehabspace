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
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  DateTime? _selectedDate;
  String? _selectedTime;
  String? _selectedTherapist;
  String? _selectedLocation;

  int _selectedIndex = 1;
  bool _submitting = false;
  bool _loadingLocations = true;

  final List<String> timeSlots = const [
    '10am - 11am',
    '11am - 12pm',
    '1:30pm - 2:30pm',
    '2:30pm - 3:30pm',
    '3:30pm - 4:30pm',
    '4:30pm - 6pm',
  ];

  final List<String> therapists = const [
    'Dr. Lester Law',
    'Dr. Kendrick Khoo',
    'Dr. Chris',
  ];

  List<String> _locations = [];

  Future<void> _fetchLocations() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('maplocations').get();

      _locations =
          snapshot.docs
              .map((doc) => (doc['name'] as String?)?.trim() ?? '')
              .where((name) => name.isNotEmpty)
              .toList();
    } catch (e) {
      _locations = [];
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Couldn’t load locations. Pull to retry."),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _loadingLocations = false);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchLocations();
  }

  Future<void> _submitBooking() async {
    if (!_formKey.currentState!.validate() ||
        _selectedDate == null ||
        _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.white,
          content: const Text(
            "Please fill in all required fields",
            style: TextStyle(color: Colors.black),
          ),
        ),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _submitting = true);
    try {
      await FirebaseFirestore.instance.collection('PhysioBookings').add({
        'userId': user.uid,
        'therapist': _selectedTherapist,
        'date_selected': _selectedDate!.toIso8601String(),
        'time_selected': _selectedTime,
        'location': _selectedLocation,
        'remarks': _remarksController.text.trim(),
        'createdAt': Timestamp.now(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.white,
          content: const Text(
            "Appointment Booked!",
            style: TextStyle(color: Colors.black),
          ),
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.white,
          content: const Text(
            "Something went wrong. Please try again.",
            style: TextStyle(color: Colors.black),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

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

  String _formatDate(DateTime d) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${d.day} ${months[d.month - 1]}, ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final primary = const Color(0xFF356899);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          "Book Physio",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchLocations,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFE3F2FD), // soft blue
                Color(0xFFFFFFFF), // white
              ],
            ),
          ),
          child: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              children: [
                _GlassCard(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.healing_outlined,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          "Fill this form to book an appointment",
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                _GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _SectionHeader(
                          icon: Icons.location_on_outlined,
                          title: "Clinic & Therapist",
                        ),

                        DropdownButtonFormField<String>(
                          isExpanded: true,
                          value: _selectedLocation,
                          decoration: const InputDecoration(
                            labelText: 'Select Clinic Location',
                            border: OutlineInputBorder(),
                          ),
                          items:
                              (_loadingLocations && _locations.isEmpty)
                                  ? [
                                    const DropdownMenuItem(
                                      value: null,
                                      child: Text('Loading locations...'),
                                    ),
                                  ]
                                  : _locations.map((location) {
                                    return DropdownMenuItem(
                                      value: location,
                                      child: Text(location),
                                    );
                                  }).toList(),
                          onChanged:
                              _loadingLocations
                                  ? null
                                  : (value) {
                                    setState(() {
                                      _selectedLocation = value;
                                    });
                                  },
                          validator:
                              (value) =>
                                  value == null || value.isEmpty
                                      ? 'Please select a location'
                                      : null,
                        ),
                        const SizedBox(height: 14),

                        DropdownButtonFormField<String>(
                          value: _selectedTherapist,
                          hint: const Text("Select Your Therapist"),
                          items:
                              therapists
                                  .map(
                                    (name) => DropdownMenuItem(
                                      value: name,
                                      child: Text(name),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedTherapist = value;
                            });
                          },
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.person_outline),
                            border: OutlineInputBorder(),
                          ),
                          validator:
                              (v) =>
                                  v == null
                                      ? 'Please select a therapist'
                                      : null,
                        ),

                        const SizedBox(height: 22),
                        _Divider(),

                        _SectionHeader(
                          icon: Icons.calendar_today_outlined,
                          title: "Date & Time",
                        ),

                        TextFormField(
                          readOnly: true,
                          decoration: InputDecoration(
                            hintText:
                                _selectedDate == null
                                    ? 'Select Date'
                                    : _formatDate(_selectedDate!),
                            prefixIcon: const Icon(
                              Icons.calendar_today_outlined,
                            ),
                            border: const OutlineInputBorder(),
                          ),
                          onTap: () async {
                            DateTime now = DateTime.now();
                            DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: now,
                              firstDate: now,
                              lastDate: DateTime(2030),
                            );
                            if (picked != null) {
                              setState(() {
                                _selectedDate = picked;
                              });
                            }
                          },
                          validator:
                              (_) =>
                                  _selectedDate == null
                                      ? 'Please pick a date'
                                      : null,
                        ),

                        const SizedBox(height: 14),

                        Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Text(
                              "Select a timeslot",
                              style: const TextStyle(color: Colors.black),
                            ),
                          ),
                        ),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children:
                              timeSlots.map((slot) {
                                final isSelected = _selectedTime == slot;
                                return ChoiceChip(
                                  label: Text(
                                    slot,
                                    style: TextStyle(
                                      color:
                                          isSelected
                                              ? Colors.white
                                              : Colors.black,
                                    ),
                                  ),
                                  selected: isSelected,
                                  onSelected: (_) {
                                    setState(() {
                                      _selectedTime = slot;
                                    });
                                  },
                                  selectedColor: primary,
                                  backgroundColor: Colors.grey[200],
                                );
                              }).toList(),
                        ),

                        const SizedBox(height: 22),
                        _Divider(),

                        _SectionHeader(
                          icon: Icons.edit_note_outlined,
                          title: "Remarks (Optional)",
                        ),

                        TextFormField(
                          controller: _remarksController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            hintText: 'Add any notes for your therapist',
                            prefixIcon: Icon(Icons.mail_outline),
                            border: OutlineInputBorder(),
                          ),
                        ),

                        const SizedBox(height: 24),

                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: _submitting ? null : _submitBooking,
                            child:
                                _submitting
                                    ? const CircularProgressIndicator(
                                      color: Colors.white,
                                    )
                                    : const Text(
                                      "Book Appointment",
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16,
                                      ),
                                    ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onTabTapped,
        selectedItemColor: primary,
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

class _GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const _GlassCard({required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: padding ?? const EdgeInsets.all(16),
      child: child,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(8),
            child: Icon(icon, size: 18, color: Colors.black),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(vertical: 6),
      color: Colors.black.withOpacity(0.06),
    );
  }
}
