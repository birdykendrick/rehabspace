import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

import 'package:rehabspace/homedash.dart';
import 'package:rehabspace/map.dart';
import 'package:rehabspace/settings.dart';

class WeeklyProgress extends StatefulWidget {
  const WeeklyProgress({Key? key}) : super(key: key);

  @override
  State<WeeklyProgress> createState() => _WeeklyProgressState();
}

class _WeeklyProgressState extends State<WeeklyProgress> {
  final TextEditingController _workoutController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> _workouts = []; // each workout with name + day
  List<int> _weeklyData = List.filled(7, 0); // holds counts for Mon-Sun

  // icons that match workout names
  final Map<String, IconData> workoutIcons = {
    "pushup": Icons.fitness_center,
    "situp": Icons.accessibility_new,
    "pullup": Icons.sports_kabaddi,
    "squat": Icons.accessibility,
    "lunges": Icons.directions_walk,
    "plank": Icons.self_improvement,
    "bridge": Icons.airline_seat_flat,
    "band": Icons.sports,
    "stretch": Icons.accessibility_new,
    "walk": Icons.directions_walk,
    "cycle": Icons.pedal_bike,
    "step": Icons.stairs,
    "wall slide": Icons.swap_vert,
    "heel raise": Icons.arrow_upward,
    "ankle circle": Icons.circle,
    "hip abduction": Icons.transfer_within_a_station,
    "bird dog": Icons.pets,
    "pelvic tilt": Icons.accessibility,
    "hamstring stretch": Icons.airline_seat_recline_extra,
    "quad stretch": Icons.directions_run,
    "calf stretch": Icons.directions_walk,
  };

  @override
  void initState() {
    super.initState();
    _loadDataFromFirestore(); // pull previous data
  }

  // get workouts + chart data from Firestore
  Future<void> _loadDataFromFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final docRef = FirebaseFirestore.instance
        .collection('weeklyProgress')
        .doc(user.uid);
    final docSnap = await docRef.get();

    if (docSnap.exists) {
      final data = docSnap.data()!;
      setState(() {
        _workouts = List<Map<String, dynamic>>.from(data['workouts'] ?? []);
        _weeklyData = List<int>.from(data['weeklyData'] ?? List.filled(7, 0));
      });
    } else {
      await docRef.set({
        'userId': user.uid,
        'workouts': [],
        'weeklyData': List.filled(7, 0),
      });
    }
  }

  // save the workouts + chart data back to Firestore
  Future<void> _saveDataToFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('weeklyProgress')
        .doc(user.uid)
        .set({
          'userId': user.uid,
          'workouts': _workouts,
          'weeklyData': _weeklyData,
        });
  }

  // pick matching icon for workout
  IconData _getWorkoutIcon(String workout) {
    final lower = workout.toLowerCase();
    for (var key in workoutIcons.keys) {
      if (lower.contains(key)) return workoutIcons[key]!;
    }
    return Icons.fitness_center;
  }

  int _selectedIndex = 1;

  // handles nav bar tab switch
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

  // when user adds workout manually or via chip
  void _addWorkout() {
    final workout = _workoutController.text.trim();
    if (workout.isNotEmpty && !_workouts.any((w) => w['name'] == workout)) {
      int today = DateTime.now().weekday;
      setState(() {
        _workouts.add({'name': workout, 'dayIndex': today - 1});
        _weeklyData[today - 1] += 1;
      });
      _workoutController.clear();
      _saveDataToFirestore();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  // remove workout from list + chart
  void _deleteWorkout(int index) {
    final dayIndex = _workouts[index]['dayIndex'];
    setState(() {
      _weeklyData[dayIndex] = max(0, _weeklyData[dayIndex] - 1);
      _workouts.removeAt(index);
    });
    _saveDataToFirestore();
  }

  // builds the line chart
  Widget _buildLineChart() {
    final maxY = max(5, _weeklyData.reduce(max) + 1);

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: true, horizontalInterval: 1),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget:
                  (value, _) => Text(
                    value.toInt().toString(),
                    style: const TextStyle(fontSize: 12),
                  ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (value, _) {
                const days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
                int index = value.toInt();
                return (index >= 0 && index < days.length)
                    ? Text(days[index], style: const TextStyle(fontSize: 12))
                    : const SizedBox.shrink();
              },
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        minX: 0,
        maxX: 6,
        minY: 0,
        maxY: maxY.toDouble(),
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(
              7,
              (i) => FlSpot(i.toDouble(), _weeklyData[i].toDouble()),
            ),
            isCurved: true,
            preventCurveOverShooting: true,
            curveSmoothness: 0.25,
            color: Colors.indigo,
            barWidth: 4,
            dotData: FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.indigo.withOpacity(0.2),
            ),
          ),
        ],
      ),
    );
  }

  // shows horizontal list of workout chips for quick-add
  Widget _buildWorkoutChips() {
    return SizedBox(
      height: 60,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children:
            workoutIcons.entries.take(10).map((entry) {
              final name = entry.key;
              final icon = entry.value;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: GestureDetector(
                  onTap: () {
                    _workoutController.text = name;
                    _addWorkout();
                  },
                  child: Chip(
                    label: Text(name),
                    avatar: Icon(icon, size: 18, color: Colors.white),
                    backgroundColor: Colors.indigo.shade400,
                    labelStyle: const TextStyle(color: Colors.white),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final maxIndex = _weeklyData.indexWhere(
      (v) => v == _weeklyData.reduce(max),
    );
    const days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Weekly Progress"),
        backgroundColor: Colors.indigo,
      ),
      body: RefreshIndicator(
        onRefresh: _loadDataFromFirestore,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWorkoutChips(),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _workoutController,
                      decoration: InputDecoration(
                        labelText: "Enter today's workout",
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _addWorkout,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 18,
                      ),
                    ),
                    child: const Text("Add"),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Card(
                color: Colors.white,
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: SizedBox(height: 200, child: _buildLineChart()),
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: Text(
                  "Most active: ${days[maxIndex]} (${_weeklyData[maxIndex]} workouts)",
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Workouts This Week",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Expanded(
                child:
                    _workouts.isEmpty
                        ? const Center(child: Text("No workouts logged yet."))
                        : ListView.builder(
                          controller: _scrollController,
                          itemCount: _workouts.length,
                          itemBuilder: (context, index) {
                            final name = _workouts[index]['name'];
                            final icon = _getWorkoutIcon(name);
                            return Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: ListTile(
                                leading: Icon(
                                  icon,
                                  color: Colors.indigo,
                                  size: 30,
                                ),
                                title: Text(
                                  name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                trailing: IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () => _deleteWorkout(index),
                                ),
                              ),
                            );
                          },
                        ),
              ),
            ],
          ),
        ),
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
