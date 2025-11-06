import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
// --- MODIFIKASI: Import Database Helper kita ---
import 'package:lofilog/services/database_helper.dart';

// (Class Model Task dan Schedule sudah tidak ada di sini,
//  karena sudah kita pindah ke database_helper.dart)

class TodoCalendarPage extends StatefulWidget {
  const TodoCalendarPage({super.key});
  // (Data tidak lagi dikirim lewat constructor)

  @override
  State<TodoCalendarPage> createState() => _TodoCalendarPageState();
}

class _TodoCalendarPageState extends State<TodoCalendarPage>
    with TickerProviderStateMixin {
  // Warna tema
  static const Color neonCyan = Color(0xFF00FFFF);
  static const Color neonYellowGreen = Color(0xFFD2FF4D);
  static const Color neonMagenta = Color(0xFFFF00C8);

  late TabController _mainTabController;

  // --- MODIFIKASI: "Database" lokal (state) ---
  List<Task> _allTasks = [];
  List<Schedule> _allSchedules = [];
  bool _isLoadingTasks = true;
  bool _isLoadingSchedules = true;
  // ---------------------------------------------

  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  bool _showCompletedTasks = false;

  @override
  void initState() {
    super.initState();
    _mainTabController = TabController(length: 2, vsync: this);
    // --- MODIFIKASI: Panggil data saat halaman dibuka ---
    _refreshLists();
  }

  // --- MODIFIKASI: Fungsi baru untuk me-refresh data ---
  void _refreshLists() async {
    // Set state ke loading
    setState(() {
      _isLoadingTasks = true;
      _isLoadingSchedules = true;
    });

    // Ambil data dari database
    final tasks = await DatabaseHelper.instance.getTasks();
    final schedules = await DatabaseHelper.instance.getSchedules();

    // Urutkan jadwal
    final List<String> days = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
    ];
    schedules.sort(
      (a, b) => days.indexOf(a.day).compareTo(days.indexOf(b.day)),
    );

    // Set state dengan data baru
    setState(() {
      _allTasks = tasks;
      _allSchedules = schedules;
      _isLoadingTasks = false;
      _isLoadingSchedules = false;
    });
  }
  // ----------------------------------------------------

  @override
  void dispose() {
    _mainTabController.dispose();
    super.dispose();
  }

  // --- MODIFIKASI: Upgrade Fungsi "New Task" ---
  void _showNewTaskSheet() {
    final titleController = TextEditingController();
    final courseController = TextEditingController();
    final descController = TextEditingController();
    DateTime? _selectedDate;
    String _dueDateText = 'Pilih Tanggal Deadline...';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            Future<void> _pickDate() async {
              final DateTime? pickedDate = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime(2101),
                builder: (context, child) {
                  return Theme(
                    data: ThemeData.dark().copyWith(
                      colorScheme: const ColorScheme.dark(
                        primary: neonCyan,
                        onPrimary: Colors.black,
                        onSurface: Colors.white,
                      ),
                      dialogBackgroundColor: const Color(0xFF0A0A12),
                    ),
                    child: child!,
                  );
                },
              );
              if (pickedDate != null && pickedDate != _selectedDate) {
                setSheetState(() {
                  _selectedDate = pickedDate;
                  _dueDateText = DateFormat(
                    'EEEE, dd MMM yyyy',
                    'id_ID',
                  ).format(pickedDate);
                });
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A0A12),
                  border: Border(top: BorderSide(color: neonCyan, width: 0.5)),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.add_task, color: neonCyan),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Tambah Tugas',
                              style: const TextStyle(
                                fontFamily: 'Orbitron',
                                color: Colors.white,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.close,
                              color: Colors.white54,
                            ),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                      const Divider(
                        color: neonCyan,
                        thickness: 0.2,
                        height: 24,
                      ),
                      _buildTextField(
                        label: 'Judul Tugas',
                        controller: titleController,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        label: 'Mata Kuliah',
                        controller: courseController,
                      ),
                      const SizedBox(height: 16),
                      _buildDatePickerField(
                        text: _dueDateText,
                        isSelected: _selectedDate != null,
                        onTap: _pickDate,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        label: 'Catatan...',
                        maxLines: 3,
                        controller: descController,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: neonCyan,
                          foregroundColor: Colors.black,
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        onPressed: () async {
                          // <-- Ubah jadi async
                          if (titleController.text.isNotEmpty) {
                            final newTask = Task(
                              title: titleController.text,
                              course: courseController.text,
                              dueDate: _selectedDate,
                              description: descController.text,
                            );
                            // --- Simpan ke Database ---
                            await DatabaseHelper.instance.insertTask(newTask);
                            _refreshLists(); // <-- Refresh data
                            Navigator.of(context).pop();
                          }
                        },
                        child: const Text(
                          'Buat Tugas',
                          style: TextStyle(
                            fontFamily: 'Share Tech Mono',
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --- MODIFIKASI: Upgrade Fungsi "New Schedule" ---
  void _showNewScheduleSheet() {
    final courseController = TextEditingController();
    final roomController = TextEditingController();
    final lecturerController = TextEditingController();
    final List<String> days = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
    ];
    String? _selectedDay;
    String _startTimeText = 'Jam Mulai...';
    String _endTimeText = 'Jam Selesai...';
    TimeOfDay? _startTime;
    TimeOfDay? _endTime;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            Future<void> _pickTime(bool isStartTime) async {
              final TimeOfDay? pickedTime = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.now(),
                builder: (context, child) {
                  return Theme(
                    data: ThemeData.dark().copyWith(
                      colorScheme: const ColorScheme.dark(
                        primary: neonMagenta,
                        onPrimary: Colors.black,
                        surface: Color(0xFF0A0A12),
                        onSurface: Colors.white,
                      ),
                      dialogBackgroundColor: const Color(0xFF0A0A12),
                    ),
                    child: child!,
                  );
                },
              );
              if (pickedTime != null) {
                setSheetState(() {
                  if (isStartTime) {
                    _startTime = pickedTime;
                    _startTimeText = pickedTime.format(context);
                  } else {
                    _endTime = pickedTime;
                    _endTimeText = pickedTime.format(context);
                  }
                });
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A0A12),
                  border: Border(
                    top: BorderSide(color: neonMagenta, width: 0.5),
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.calendar_month, color: neonMagenta),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Tambah Jadwal',
                              style: const TextStyle(
                                fontFamily: 'Orbitron',
                                color: Colors.white,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.close,
                              color: Colors.white54,
                            ),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                      const Divider(
                        color: neonMagenta,
                        thickness: 0.2,
                        height: 24,
                      ),
                      _buildTextField(
                        label: 'Mata Kuliah',
                        color: neonMagenta,
                        controller: courseController,
                      ),
                      const SizedBox(height: 16),
                      _buildDropdownField(
                        label: 'Hari',
                        value: _selectedDay,
                        items: days,
                        onChanged: (newValue) {
                          setSheetState(() {
                            _selectedDay = newValue;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTimeField(
                              text: _startTimeText,
                              onTap: () => _pickTime(true),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildTimeField(
                              text: _endTimeText,
                              onTap: () => _pickTime(false),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        label: 'Ruang',
                        color: neonMagenta,
                        controller: roomController,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        label: 'Dosen',
                        color: neonMagenta,
                        controller: lecturerController,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: neonMagenta,
                          foregroundColor: Colors.black,
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        onPressed: () async {
                          // <-- Ubah jadi async
                          if (courseController.text.isNotEmpty &&
                              _selectedDay != null &&
                              _startTime != null &&
                              _endTime != null) {
                            final newSchedule = Schedule(
                              course: courseController.text,
                              day: _selectedDay!,
                              startTime: _startTime!,
                              endTime: _endTime!,
                              room: roomController.text,
                              lecturer: lecturerController.text,
                            );
                            // --- Simpan ke Database ---
                            await DatabaseHelper.instance.insertSchedule(
                              newSchedule,
                            );
                            _refreshLists(); // <-- Refresh data
                            Navigator.of(context).pop();
                          }
                        },
                        child: const Text(
                          'Buat Jadwal',
                          style: TextStyle(
                            fontFamily: 'Share Tech Mono',
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --- MODIFIKASI: Upgrade Fungsi Hapus Tugas ---
  void _showDeleteTaskDialog(Task task) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0A0A12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: neonCyan.withOpacity(0.5)),
          ),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: neonCyan),
              SizedBox(width: 10),
              Text(
                'Hapus Tugas',
                style: TextStyle(fontFamily: 'Orbitron', color: Colors.white),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Yakin ingin menghapus tugas ini?',
                  style: TextStyle(
                    fontFamily: 'Share Tech Mono',
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: neonCyan.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: const TextStyle(
                          fontFamily: 'Share Tech Mono',
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (task.course.isNotEmpty)
                        Text(
                          'Matkul: ${task.course}',
                          style: const TextStyle(
                            fontFamily: 'Share Tech Mono',
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      const SizedBox(height: 4),
                      if (task.description.isNotEmpty)
                        Text(
                          'Catatan: ${task.description}',
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Share Tech Mono',
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Batal',
                style: TextStyle(
                  fontFamily: 'Share Tech Mono',
                  color: Colors.white70,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: neonCyan,
                foregroundColor: Colors.black,
              ),
              onPressed: () async {
                // <-- Ubah jadi async
                // --- Hapus dari Database ---
                if (task.id != null) {
                  await DatabaseHelper.instance.deleteTask(task.id!);
                  _refreshLists(); // <-- Refresh data
                }
                Navigator.of(context).pop();
              },
              child: const Text(
                'Hapus',
                style: TextStyle(
                  fontFamily: 'Share Tech Mono',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // --- MODIFIKASI: Upgrade Fungsi Hapus Jadwal ---
  void _showDeleteScheduleDialog(Schedule schedule) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0A0A12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: neonMagenta.withOpacity(0.5)),
          ),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: neonMagenta),
              SizedBox(width: 10),
              Text(
                'Hapus Jadwal',
                style: TextStyle(fontFamily: 'Orbitron', color: Colors.white),
              ),
            ],
          ),
          content: Text(
            'Yakin ingin menghapus jadwal "${schedule.course}"?',
            style: const TextStyle(
              fontFamily: 'Share Tech Mono',
              color: Colors.white70,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Batal',
                style: TextStyle(
                  fontFamily: 'Share Tech Mono',
                  color: Colors.white70,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: neonMagenta,
                foregroundColor: Colors.black,
              ),
              onPressed: () async {
                // <-- Ubah jadi async
                // --- Hapus dari Database ---
                if (schedule.id != null) {
                  await DatabaseHelper.instance.deleteSchedule(schedule.id!);
                  _refreshLists(); // <-- Refresh data
                }
                Navigator.of(context).pop();
              },
              child: const Text(
                'Hapus',
                style: TextStyle(
                  fontFamily: 'Share Tech Mono',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // (Helper-helper tidak berubah)
  Widget _buildTextField({
    required String label,
    int maxLines = 1,
    Color color = neonCyan,
    TextEditingController? controller,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(
        color: Colors.white,
        fontFamily: 'Share Tech Mono',
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: color.withOpacity(0.7)),
        alignLabelWithHint: true,
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: color.withOpacity(0.5)),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: color, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items.map((String day) {
        return DropdownMenuItem<String>(value: day, child: Text(day));
      }).toList(),
      onChanged: onChanged,
      style: const TextStyle(
        color: Colors.white,
        fontFamily: 'Share Tech Mono',
      ),
      dropdownColor: const Color(0xFF0A0A12),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: neonMagenta.withOpacity(0.7)),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: neonMagenta.withOpacity(0.5)),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: neonMagenta, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildTimeField({required String text, required VoidCallback onTap}) {
    bool isPlaceholder = text == 'Jam Mulai...' || text == 'Jam Selesai...';
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: neonMagenta.withOpacity(0.5)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontFamily: 'Share Tech Mono',
                  color: isPlaceholder
                      ? neonMagenta.withOpacity(0.7)
                      : Colors.white,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.access_time,
              color: neonMagenta.withOpacity(0.7),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDatePickerField({
    required String text,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: neonCyan.withOpacity(0.5)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              text,
              style: TextStyle(
                fontFamily: 'Share Tech Mono',
                color: isSelected ? Colors.white : neonCyan.withOpacity(0.7),
              ),
            ),
            Icon(
              Icons.calendar_month,
              color: neonCyan.withOpacity(0.7),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: neonCyan),
          onPressed: () {
            // --- MODIFIKASI: Kirim 'true' saat kembali ---
            // Ini untuk memberitahu dashboard agar me-refresh
            Navigator.of(context).pop(true);
          },
        ),
        title: const Text(
          'To-Do & Calendar',
          style: TextStyle(
            fontFamily: 'Orbitron',
            fontWeight: FontWeight.bold,
            color: neonCyan,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton.icon(
            style: TextButton.styleFrom(foregroundColor: Colors.white),
            onPressed: _showNewTaskSheet,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('New Task'),
          ),
          TextButton.icon(
            style: TextButton.styleFrom(foregroundColor: Colors.white),
            onPressed: _showNewScheduleSheet,
            icon: const Icon(Icons.calendar_month, size: 18),
            label: const Text('New Schedule'),
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _mainTabController,
          indicatorColor: neonCyan,
          indicatorWeight: 3,
          labelStyle: const TextStyle(
            fontFamily: 'Orbitron',
            fontWeight: FontWeight.bold,
          ),
          unselectedLabelStyle: const TextStyle(fontFamily: 'Share Tech Mono'),
          tabs: const [
            Tab(text: 'Tugas'),
            Tab(text: 'Jadwal Kuliah'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _mainTabController,
        children: [_buildTugasView(), _buildScheduleView()],
      ),
    );
  }

  // --- MODIFIKASI: _buildTugasView sekarang menggunakan state ---
  Widget _buildTugasView() {
    if (_isLoadingTasks) {
      return const Center(child: CircularProgressIndicator(color: neonCyan));
    }

    final List<Task> _tasksForSelectedDay = _allTasks.where((task) {
      if (!_showCompletedTasks && task.isDone) {
        return false;
      }
      if (task.dueDate == null) {
        return false;
      }
      return isSameDay(task.dueDate, _selectedDay);
    }).toList();

    return Column(
      children: [
        TableCalendar(
          locale: 'id_ID',
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2100, 12, 31),
          focusedDay: _focusedDay,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
          },
          eventLoader: _getTasksForDay, // <-- SEKARANG INI BERFUNGSI
          headerStyle: HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
            titleTextStyle: const TextStyle(
              fontFamily: 'Orbitron',
              color: neonCyan,
              fontSize: 18,
            ),
            leftChevronIcon: const Icon(Icons.chevron_left, color: neonCyan),
            rightChevronIcon: const Icon(Icons.chevron_right, color: neonCyan),
          ),
          calendarStyle: CalendarStyle(
            todayDecoration: BoxDecoration(
              color: neonYellowGreen.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            todayTextStyle: const TextStyle(color: Colors.white),
            selectedDecoration: BoxDecoration(
              color: neonCyan,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: neonCyan.withOpacity(0.7),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            selectedTextStyle: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
            defaultTextStyle: const TextStyle(
              fontFamily: 'Share Tech Mono',
              color: Colors.white70,
            ),
            weekendTextStyle: TextStyle(
              fontFamily: 'Share Tech Mono',
              color: neonMagenta.withOpacity(0.7),
            ),
            outsideTextStyle: const TextStyle(
              fontFamily: 'Share Tech Mono',
              color: Colors.white24,
            ),
            markerDecoration: const BoxDecoration(
              color: neonYellowGreen,
              shape: BoxShape.circle,
            ),
            markerSize: 6.0,
          ),
        ),
        const Divider(color: neonCyan, thickness: 0.2),
        SwitchListTile(
          title: Text(
            'Tampilkan Tugas Selesai',
            style: TextStyle(
              fontFamily: 'Share Tech Mono',
              color: Colors.white.withOpacity(0.8),
            ),
          ),
          value: _showCompletedTasks,
          onChanged: (newValue) {
            setState(() {
              _showCompletedTasks = newValue;
            });
          },
          activeColor: neonCyan,
          inactiveTrackColor: Colors.grey[800],
        ),
        Expanded(
          child: _tasksForSelectedDay.isEmpty
              ? _buildPlaceholderList("Tidak ada tugas di hari ini.")
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _tasksForSelectedDay.length,
                  itemBuilder: (context, index) {
                    final task = _tasksForSelectedDay[index];
                    return _buildTaskTile(task);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildTaskTile(Task task) {
    return InkWell(
      onLongPress: () {
        _showDeleteTaskDialog(task);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: neonCyan.withOpacity(task.isDone ? 0.05 : 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: neonCyan.withOpacity(task.isDone ? 0.2 : 0.4),
          ),
        ),
        child: ListTile(
          leading: Checkbox(
            value: task.isDone,
            activeColor: neonCyan,
            checkColor: Colors.black,
            onChanged: (bool? newValue) async {
              setState(() {
                task.isDone = newValue ?? false;
              });
              await DatabaseHelper.instance.updateTaskDone(task);
              _refreshLists();
            },
          ),
          title: Text(
            task.title,
            style: TextStyle(
              fontFamily: 'Share Tech Mono',
              color: task.isDone ? Colors.white54 : Colors.white,
              fontWeight: FontWeight.bold,
              decoration: task.isDone ? TextDecoration.lineThrough : null,
            ),
          ),
          subtitle: Text(
            task.course,
            style: TextStyle(
              fontFamily: 'Share Tech Mono',
              color: task.isDone
                  ? Colors.white.withOpacity(0.4)
                  : Colors.white.withOpacity(0.6),
              decoration: task.isDone ? TextDecoration.lineThrough : null,
            ),
          ),
        ),
      ),
    );
  }

  // --- MODIFIKASI: _buildScheduleView sekarang menggunakan state ---
  Widget _buildScheduleView() {
    if (_isLoadingSchedules) {
      return const Center(child: CircularProgressIndicator(color: neonMagenta));
    }
    if (_allSchedules.isEmpty) {
      return _buildPlaceholderList("Belum ada Jadwal Kuliah yang disimpan.");
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _allSchedules.length,
      itemBuilder: (context, index) {
        final schedule = _allSchedules[index];
        final String startTime = schedule.startTime.format(context);
        final String endTime = schedule.endTime.format(context);

        return InkWell(
          onLongPress: () {
            _showDeleteScheduleDialog(schedule);
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: neonMagenta.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: neonMagenta.withOpacity(0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      schedule.day,
                      style: const TextStyle(
                        fontFamily: 'Orbitron',
                        color: neonMagenta,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      '$startTime - $endTime',
                      style: const TextStyle(
                        fontFamily: 'Share Tech Mono',
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const Divider(color: neonMagenta, height: 20, thickness: 0.2),
                Text(
                  schedule.course,
                  style: const TextStyle(
                    fontFamily: 'Share Tech Mono',
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.room_outlined,
                      color: Colors.white70,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      schedule.room.isNotEmpty ? schedule.room : 'Tanpa Ruang',
                      style: const TextStyle(
                        fontFamily: 'Share Tech Mono',
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.person_outline,
                      color: Colors.white70,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      schedule.lecturer.isNotEmpty
                          ? schedule.lecturer
                          : 'Tanpa Dosen',
                      style: const TextStyle(
                        fontFamily: 'Share Tech Mono',
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlaceholderList(String text) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Share Tech Mono',
            fontSize: 16,
            color: Colors.white.withOpacity(0.5),
          ),
        ),
      ),
    );
  }

  // --- MODIFIKASI: _getTasksForDay sekarang membaca dari List lokal ---
  List<Task> _getTasksForDay(DateTime day) {
    return _allTasks.where((task) {
      // <-- PERBAIKAN BUG
      if (task.dueDate == null) return false;
      return isSameDay(task.dueDate, day);
    }).toList();
  }
}
