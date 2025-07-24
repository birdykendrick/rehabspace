import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  void _submitBooking() async {
    if (_selectedTherapist == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all required fields")),
      );
      return;
    }
    await FirebaseFirestore.instance.collection('PhysioBookings').add({
      'therapist': _selectedTherapist,
      'date_selected': _selectedDate!.toIso8601String(),
      'time_selected': _selectedTime,
      'remarks': _remarksController.text.trim(),
      'createdAt': Timestamp.now(),
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Appointment Booked!")));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Book Physio"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: ListView(
          children: [
            const SizedBox(height: 12),
            const Text(
              "Fill up this form to book an appointment",
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
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
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            TextFormField(
              readOnly: true,
              decoration: InputDecoration(
                hintText:
                    _selectedDate == null
                        ? 'Select Date'
                        : '${_selectedDate!.day} ${_selectedDate!.month}, ${_selectedDate!.year}',
                prefixIcon: const Icon(Icons.calendar_today_outlined),
                border: const OutlineInputBorder(),
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

            const SizedBox(height: 20),

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
                      selectedColor: const Color.fromARGB(255, 67, 155, 238),
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
            const SizedBox(height: 20),

            TextFormField(
              controller: _remarksController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Remarks',
                prefixIcon: Icon(Icons.mail_outline),
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[200],
                ),
                onPressed: _submitBooking,
                child: const Text("Submit"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
