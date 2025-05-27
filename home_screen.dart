import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Task {
  String name;
  String day;
  TimeOfDay time;
  DateTime date;
  bool isCompleted;

  Task({
    required this.name,
    required this.day,
    required this.time,
    required this.date,
    this.isCompleted = false,
  });

  @override
  bool operator ==(Object other) {
    return other is Task &&
        name == other.name &&
        day == other.day &&
        time.hour == other.time.hour &&
        time.minute == other.time.minute &&
        date.year == other.date.year &&
        date.month == other.date.month &&
        date.day == other.date.day;
  }

  @override
  int get hashCode =>
      Object.hash(name, day, time.hour, time.minute, date.year, date.month, date.day);
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  static const List<String> sectionTitles = [
    'Tasks',
    'My Day',
    'Assigned to Me',
    'Important',
    'Planned',
  ];

  final Map<String, List<Task>> tasksBySection = {
    'Important': [],
    'Planned': [],
    'Assigned to Me': [],
    'Tasks': [],
  };

  final List<String> daysOfWeek = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
  ];

  List<Task> get myDayTasks {
    final today = DateTime.now();
    return tasksBySection['Tasks']!
        .where((task) =>
            task.date.year == today.year &&
            task.date.month == today.month &&
            task.date.day == today.day)
        .toList();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      Navigator.pop(context);
    });
  }

  void _addTaskDialog() {
    final formKey = GlobalKey<FormState>();
    String name = '';
    String selectedDay = daysOfWeek[0];
    TimeOfDay selectedTime = TimeOfDay.now();
    DateTime selectedDate = DateTime.now();
    String selectedSection = sectionTitles[_selectedIndex] == 'My Day'
        ? 'Planned'
        : sectionTitles[_selectedIndex];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Add Task'),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Task Name'),
                      validator: (value) =>
                          value!.isEmpty ? 'Enter task name' : null,
                      onSaved: (value) => name = value!,
                    ),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Day'),
                      value: selectedDay,
                      items: daysOfWeek.map((day) {
                        return DropdownMenuItem(
                          value: day,
                          child: Text(day),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() => selectedDay = value!);
                      },
                    ),
                    const SizedBox(height: 8),
                    ListTile(
                      title: Text(
                        'Date: ${DateFormat.yMMMd().format(selectedDate)}',
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now().subtract(const Duration(days: 365)),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          setDialogState(() => selectedDate = picked);
                        }
                      },
                    ),
                    ListTile(
                      title: Text('Time: ${selectedTime.format(context)}'),
                      trailing: const Icon(Icons.access_time),
                      onTap: () async {
                        TimeOfDay? picked = await showTimePicker(
                          context: context,
                          initialTime: selectedTime,
                        );
                        if (picked != null) {
                          setDialogState(() => selectedTime = picked);
                        }
                      },
                    ),
                    DropdownButtonFormField<String>(
                      value: selectedSection,
                      decoration: const InputDecoration(labelText: 'Section'),
                      items: sectionTitles
                          .where((s) => s != 'My Day')
                          .map((section) => DropdownMenuItem(
                                value: section,
                                child: Text(section),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() => selectedSection = value);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                child: const Text('Cancel'),
                onPressed: () => Navigator.pop(context),
              ),
              ElevatedButton(
                child: const Text('Save'),
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    formKey.currentState!.save();
                    final newTask = Task(
                      name: name,
                      day: selectedDay,
                      time: selectedTime,
                      date: selectedDate,
                    );

                    setState(() {
                      final sectionList = tasksBySection[selectedSection]!;
                      final allTasksList = tasksBySection['Tasks']!;

                      if (!sectionList.contains(newTask)) {
                        sectionList.add(newTask);
                      }
                      if (!allTasksList.contains(newTask)) {
                        allTasksList.add(newTask);
                      }
                    });

                    Navigator.pop(context);
                  }
                },
              ),
            ],
          );
        });
      },
    );
  }

  void _toggleTaskCompletion(Task task) {
    setState(() => task.isCompleted = !task.isCompleted);
    if (task.isCompleted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Task completed! Well done!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final String currentSection = sectionTitles[_selectedIndex];
    final List<Task> tasks = currentSection == 'My Day'
        ? myDayTasks
        : tasksBySection[currentSection]!;

    return Scaffold(
      appBar: AppBar(
        title: Text(currentSection),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF7F00FF), Color(0xFFE100FF)],
              begin: Alignment.topLeft,     
              end: Alignment.bottomRight,
            ),
          ),
        ),
        foregroundColor: Colors.white,
      ),
      drawer: Drawer(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(24),
            bottomRight: Radius.circular(24),
          ),
        ),
        child: Column(
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF7f00ff), Color(0xFFe100ff)],
                ),
              ),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  'Day Planner',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: sectionTitles.length,
                itemBuilder: (context, i) {
                  final section = sectionTitles[i];
                  final int count = section == 'My Day'
                      ? myDayTasks.length
                      : tasksBySection[section]?.length ?? 0;

                  final Map<String, IconData> sectionIcons = {
                    'Tasks': Icons.list,
                    'My Day': Icons.wb_sunny,
                    'Assigned to Me': Icons.assignment_ind,
                    'Important': Icons.star,
                    'Planned': Icons.calendar_today,
                  };

                  return ListTile(
                    leading: Icon(
                      sectionIcons[section],
                      color: _selectedIndex == i ? Colors.deepPurple : Colors.black54,
                    ),
                    title: Text(section),
                    trailing: count > 0
                        ? CircleAvatar(
                            radius: 12,
                            backgroundColor: Colors.deepPurple.shade100,
                            child: Text(
                              count.toString(),
                              style: const TextStyle(fontSize: 12),
                            ),
                          )
                        : null,
                    selected: i == _selectedIndex,
                    selectedTileColor: Colors.deepPurple.shade50,
                    onTap: () => _onItemTapped(i),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      body: Container(
        color: const Color(0xFFF4F1FA),
        padding: const EdgeInsets.all(16),
        child: tasks.isEmpty
            ? Center(
                child: Text(
                  'No tasks in $currentSection',
                  style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic, color: Colors.black54),
                ),
              )
            : ListView(
                children: tasks.map((task) {
                  String? taskSection;
                  if (currentSection == 'Tasks') {
                    taskSection = tasksBySection.entries
                        .firstWhere(
                          (entry) => entry.key != 'Tasks' && entry.value.contains(task),
                          orElse: () => const MapEntry('Unknown', []),
                        )
                        .key;
                  }

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    elevation: 6,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  task.name,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    decoration: task.isCompleted
                                        ? TextDecoration.lineThrough
                                        : TextDecoration.none,
                                  ),
                                ),
                              ),
                              Checkbox(
                                value: task.isCompleted,
                                onChanged: (_) => _toggleTaskCompletion(task),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${task.day}, ${DateFormat.yMMMd().format(task.date)} • ${task.time.format(context)}',
                            style: const TextStyle(fontSize: 13, color: Colors.black87),
                          ),
                          if (currentSection == 'Tasks' && taskSection != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 4, horizontal: 8),
                                decoration: BoxDecoration(
                                  color: Colors.deepPurple.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  'Section: $taskSection',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF7F00FF),
        child: const Icon(Icons.add),
        onPressed: _addTaskDialog,
      ),
    );
  }
}
