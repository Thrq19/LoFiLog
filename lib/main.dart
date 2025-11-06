import 'dart:async';
import 'package:flutter/material.dart' hide FocusManager;
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:lofilog/services/focus_manager.dart';
import 'package:lofilog/services/database_helper.dart';
import 'package:lofilog/pages/about_page.dart';
import 'package:lofilog/pages/daily_notes_page.dart';
import 'package:lofilog/pages/focus_time_page.dart';
import 'package:lofilog/pages/todo_calendar_page.dart';
import 'package:table_calendar/table_calendar.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);

  runApp(
    ChangeNotifierProvider(
      create: (context) => FocusManager(),
      child: const LoFiLogApp(),
    ),
  );
}

class LoFiLogApp extends StatelessWidget {
  const LoFiLogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0A0A12),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
      ),
      home: const DashboardPage(),
    );
  }
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  Timer? _timer;
  String _greeting = "";
  String _currentDate = "";
  String _currentTime = "";

  List<Task> _allTasks = [];
  List<Schedule> _allSchedules = [];

  String _userName = "";

  late FocusManager _focusManager;
  bool _isDialogOpen = false;

  @override
  void initState() {
    super.initState();
    _updateTimeAndGreeting();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateTimeAndGreeting();
    });

    _focusManager = Provider.of<FocusManager>(context, listen: false);
    _focusManager.addListener(_checkTimerStatus);

    _refreshDashboard();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _focusManager.removeListener(_checkTimerStatus);
    super.dispose();
  }

  void _checkTimerStatus() {
    if (_focusManager.timerJustFinished && !_isDialogOpen) {
      _showGlobalFinishedDialog(context);
      _focusManager.acknowledgeTimerFinish();
    }
  }

  void _showGlobalFinishedDialog(BuildContext context) {
    setState(() {
      _isDialogOpen = true;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0A0A12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: FocusManager.neonCyan, width: 0.5),
          ),
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: FocusManager.neonCyan),
              SizedBox(width: 10),
              Text(
                'Sesi Selesai',
                style: TextStyle(fontFamily: 'Orbitron', color: Colors.white),
              ),
            ],
          ),
          content: const Text(
            'Waktu fokusmu telah berakhir. Waktunya istirahat!',
            style: TextStyle(
              fontFamily: 'Share Tech Mono',
              color: Colors.white70,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _focusManager.resetTimer();
                setState(() {
                  _isDialogOpen = false;
                });
              },
              child: const Text(
                'Tutup',
                style: TextStyle(
                  fontFamily: 'Share Tech Mono',
                  color: FocusManager.neonCyan,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _updateTimeAndGreeting() {
    final DateTime now = DateTime.now();
    final int hour = now.hour;
    String greeting;
    if (hour < 11) {
      greeting = 'Selamat Pagi';
    } else if (hour < 15) {
      greeting = 'Selamat Siang';
    } else if (hour < 18) {
      greeting = 'Selamat Sore';
    } else {
      greeting = 'Selamat Malam';
    }
    if (mounted) {
      setState(() {
        _greeting = greeting + (_userName.isEmpty ? "" : ", $_userName");
        _currentDate = DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(now);
        _currentTime = DateFormat('HH:mm:ss').format(now);
      });
    }
  }

  // --- MODIFIKASI 1: Refresh sekarang ambil SEMUA data dari DB ---
  void _refreshDashboard() {
    // Ambil data terbaru dari database dan update state
    DatabaseHelper.instance.getTasks().then((tasks) {
      setState(() {
        _allTasks = tasks;
      });
    });
    DatabaseHelper.instance.getSchedules().then((schedules) {
      setState(() {
        _allSchedules = schedules;
      });
    });
    _loadUserName(); // <-- Panggil nama juga
  }
  // --------------------------------------------------

  void _loadUserName() async {
    final name = await DatabaseHelper.instance.getSetting('userName');
    setState(() {
      _userName = name ?? "";
    });
    _updateTimeAndGreeting();
  }

  void _showNameInputDialog() {
    final nameController = TextEditingController(text: _userName);
    const Color color = Color(0xFFD2FF4D);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              color: const Color(0xFF0A0A12),
              border: Border(top: BorderSide(color: color, width: 0.5)),
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
                      const Icon(Icons.person_outline, color: color),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Atur Nama Panggilan',
                          style: const TextStyle(
                            fontFamily: 'Orbitron',
                            color: Colors.white,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white54),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const Divider(color: color, thickness: 0.2, height: 24),
                  TextField(
                    controller: nameController,
                    autofocus: true,
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'Share Tech Mono',
                    ),
                    decoration: InputDecoration(
                      labelText: 'Nama Panggilan...',
                      labelStyle: TextStyle(color: color.withOpacity(0.7)),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: color.withOpacity(0.5)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: color, width: 2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.black,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    onPressed: () async {
                      await DatabaseHelper.instance.saveSetting(
                        'userName',
                        nameController.text,
                      );
                      _loadUserName();
                      Navigator.of(context).pop();
                    },
                    child: const Text(
                      'Simpan Nama',
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
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final endOfWeek = today.add(Duration(days: 7 - today.weekday + 1));

    // Filter dari list lokal (_allTasks yang sudah diisi dari DB)
    final int tasksThisWeek = _allTasks.where((task) {
      if (task.isDone || task.dueDate == null) return false;
      return task.dueDate!.isAfter(today.subtract(const Duration(days: 1))) &&
          task.dueDate!.isBefore(endOfWeek);
    }).length;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          leading: const Icon(Icons.blur_on, color: Color(0xFF00FFFF)),
          title: const Text(
            'LoFiLog',
            style: TextStyle(
              fontFamily: 'Orbitron',
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.menu, color: Color(0xFF00FFFF)),
              onPressed: () {
                _scaffoldKey.currentState?.openEndDrawer();
              },
            ),
          ],
        ),
        endDrawer: AppMenuDrawer(onNavigate: _refreshDashboard),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _greeting,
                  style: const TextStyle(
                    color: Color(0xFF00FFFF),
                    fontSize: 28,
                    fontFamily: 'Orbitron',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _currentDate,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 16,
                    fontFamily: 'Share Tech Mono',
                  ),
                ),
                Text(
                  _currentTime,
                  style: TextStyle(
                    fontFamily: 'Share Tech Mono',
                    fontSize: 20,
                    color: Colors.white.withOpacity(0.9),
                    shadows: [
                      BoxShadow(
                        color: const Color(0xFF00FFFF).withOpacity(0.5),
                        blurRadius: 5,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00FFFF).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF00FFFF).withOpacity(0.5),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Tugas Minggu Ini',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 16,
                          fontFamily: 'Share Tech Mono',
                        ),
                      ),
                      Text(
                        tasksThisWeek.toString(), // Data dinamis
                        style: const TextStyle(
                          color: Color(0xFFD2FF4D),
                          fontSize: 32,
                          fontFamily: 'Orbitron',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                TodoSnapshotCard(
                  tasks: _allTasks, // Kirim list lokal
                  schedules: _allSchedules, // Kirim list lokal
                ),
                const SizedBox(height: 20),
                ShortcutGrid(
                  onNavigate: _refreshDashboard,
                  onShowNameInput: _showNameInputDialog,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --- MODIFIKASI 2: Card "Tugas & Jadwal" (Dashboard) ---
class TodoSnapshotCard extends StatelessWidget {
  final List<Task> tasks;
  final List<Schedule> schedules;

  const TodoSnapshotCard({
    super.key,
    required this.tasks,
    required this.schedules,
  });

  static const Color neonCyan = Color(0xFF00FFFF);
  static const Color neonMagenta = Color(0xFFFF00C8);
  static const Color neonYellowGreen = Color(0xFFD2FF4D);

  @override
  Widget build(BuildContext context) {
    final Color semiTransparentBlack = Colors.black.withOpacity(0.2);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final endOfWeek = today.add(Duration(days: 8 - today.weekday));
    final String todayString = DateFormat('EEEE', 'id_ID').format(today);

    // Filter "Hari Ini" (Tugas & Jadwal)
    final List<Task> todayTasks = tasks
        .where(
          (t) => t.dueDate != null && isSameDay(t.dueDate, today) && !t.isDone,
        )
        .toList();
    final List<Schedule> todaySchedules = schedules
        .where((s) => s.day == todayString)
        .toList();

    // Filter "Besok" (Hanya Tugas)
    final List<Task> tomorrowTasks = tasks
        .where(
          (t) =>
              t.dueDate != null && isSameDay(t.dueDate, tomorrow) && !t.isDone,
        )
        .toList();

    // Filter "Minggu Ini" (Hanya Tugas)
    final List<Task> weekTasks = tasks
        .where(
          (t) =>
              t.dueDate != null &&
              t.dueDate!.isAfter(tomorrow) &&
              t.dueDate!.isBefore(endOfWeek) &&
              !t.isDone,
        )
        .toList();

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: neonCyan.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: neonCyan.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tugas & Jadwal',
            style: TextStyle(
              fontFamily: 'Orbitron',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 40,
            decoration: BoxDecoration(
              color: semiTransparentBlack,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              indicator: BoxDecoration(
                color: neonCyan,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: neonCyan.withOpacity(0.7),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              labelColor: Colors.black,
              unselectedLabelColor: Colors.white.withOpacity(0.7),
              labelStyle: const TextStyle(
                fontFamily: 'Share Tech Mono',
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              tabs: const [
                Tab(text: 'Hari Ini'),
                Tab(text: 'Besok'),
                Tab(text: 'Minggu Ini'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: ((todayTasks.length + todaySchedules.length) * 72.0).clamp(
              150.0,
              220.0,
            ),
            child: TabBarView(
              children: [
                _buildTaskAndScheduleList(
                  context: context,
                  tasks: todayTasks,
                  schedules: todaySchedules,
                  placeholder: 'Tidak ada jadwal atau tugas hari ini.',
                ),
                _buildTaskAndScheduleList(
                  context: context,
                  tasks: tomorrowTasks,
                  schedules: [], // <-- JADWAL KOSONG (SESUAI PERMINTAANMU)
                  placeholder: 'Tidak ada tugas besok.',
                ),
                _buildTaskAndScheduleList(
                  context: context,
                  tasks: weekTasks,
                  schedules: [], // <-- JADWAL KOSONG (SESUAI PERMINTAANMU)
                  placeholder: 'Tidak ada tugas minggu ini.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // (Sisa kode _buildTaskAndScheduleList, _buildTaskTile, _buildScheduleTile tidak berubah)
  Widget _buildTaskAndScheduleList({
    required BuildContext context,
    required List<Task> tasks,
    required List<Schedule> schedules,
    required String placeholder,
  }) {
    if (tasks.isEmpty && schedules.isEmpty) {
      return Center(
        child: Text(
          placeholder,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 16,
            fontFamily: 'Share Tech Mono',
          ),
        ),
      );
    }
    final List<Widget> items = [];
    for (var schedule in schedules) {
      items.add(
        _buildScheduleTile(
          context: context,
          schedule: schedule,
          color: TodoSnapshotCard.neonMagenta,
        ),
      );
    }
    for (var task in tasks) {
      items.add(_buildTaskTile(task: task, color: TodoSnapshotCard.neonCyan));
    }
    return ListView(physics: const BouncingScrollPhysics(), children: items);
  }

  Widget _buildTaskTile({required Task task, required Color color}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(Icons.task_alt, color: color, size: 20),
        title: Text(
          task.title,
          style: const TextStyle(
            fontFamily: 'Share Tech Mono',
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          task.course,
          style: TextStyle(
            fontFamily: 'Share Tech Mono',
            color: Colors.white.withOpacity(0.7),
          ),
        ),
      ),
    );
  }

  Widget _buildScheduleTile({
    required BuildContext context,
    required Schedule schedule,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(Icons.school, color: color, size: 20),
        title: Text(
          schedule.course,
          style: const TextStyle(
            fontFamily: 'Share Tech Mono',
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${schedule.startTime.format(context)} - ${schedule.endTime.format(context)} | ${schedule.room}',
          style: TextStyle(
            fontFamily: 'Share Tech Mono',
            color: Colors.white.withOpacity(0.7),
          ),
        ),
      ),
    );
  }
}

// --- Menu Samping (Versi Statis) ---
class AppMenuDrawer extends StatelessWidget {
  final VoidCallback onNavigate;

  const AppMenuDrawer({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    const Color neonCyan = Color(0xFF00FFFF);
    const Color neonMagenta = Color(0xFFFF00C8);
    const Color neonYellowGreen = Color(0xFFD2FF4D);

    return Drawer(
      backgroundColor: const Color(0xFF0A0A12).withOpacity(0.95),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: neonCyan.withOpacity(0.1),
              border: Border(
                bottom: BorderSide(color: neonCyan.withOpacity(0.5)),
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(Icons.blur_on, color: neonCyan, size: 40),
                SizedBox(height: 10),
                Text(
                  'LoFiLog',
                  style: TextStyle(
                    fontFamily: 'Orbitron',
                    fontSize: 24,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Main Menu',
                  style: TextStyle(
                    fontFamily: 'Share Tech Mono',
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          _buildMenuTile(
            context,
            title: 'Catatan Harian',
            icon: Icons.edit_note,
            color: neonCyan,
            page: const DailyNotesPage(),
          ),
          _buildMenuTile(
            context,
            title: 'Focus Time',
            icon: Icons.timer,
            color: neonMagenta,
            page: const FocusTimePage(),
          ),
          _buildMenuTile(
            context,
            title: 'To-Do & Calendar',
            icon: Icons.calendar_today,
            color: neonYellowGreen,
            page: const TodoCalendarPage(),
          ),
          const Divider(color: Colors.white24),
          _buildMenuTile(
            context,
            title: 'About App',
            icon: Icons.info_outline,
            color: Colors.white70,
            page: const AboutPage(),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuTile(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required Widget page,
  }) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: const TextStyle(
          fontFamily: 'Share Tech Mono',
          fontSize: 16,
          color: Colors.white,
        ),
      ),
      onTap: () async {
        Navigator.pop(context);
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => page),
        );
        onNavigate(); // <-- Panggil refresh
      },
    );
  }
}

// --- Tombol Shortcut (Versi Statis) ---
class ShortcutGrid extends StatelessWidget {
  final VoidCallback onNavigate; // <-- Terima refresh
  final VoidCallback onShowNameInput;

  const ShortcutGrid({
    super.key,
    required this.onNavigate,
    required this.onShowNameInput,
  });

  @override
  Widget build(BuildContext context) {
    const Color neonCyan = Color(0xFF00FFFF);
    const Color neonMagenta = Color(0xFFFF00C8);
    const Color neonYellowGreen = Color(0xFFD2FF4D);

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      children: [
        NeonButton(
          text: 'Tambah Catatan',
          icon: Icons.edit_note,
          color: neonCyan,
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const DailyNotesPage()),
            );
            onNavigate();
          },
        ),
        NeonButton(
          text: 'Mulai Fokus',
          icon: Icons.timer,
          color: neonMagenta,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const FocusTimePage()),
            );
          },
        ),
        NeonButton(
          text: 'To-Do & Calendar',
          icon: Icons.calendar_today,
          color: neonYellowGreen,
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const TodoCalendarPage()),
            );
            onNavigate();
          },
        ),
        NeonButton(
          text: 'Atur Nama',
          icon: Icons.person_outline,
          color: Colors.white.withOpacity(0.7),
          onPressed: onShowNameInput,
        ),
      ],
    );
  }
}

// --- Widget NeonButton (Tidak berubah) ---
class NeonButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;
  const NeonButton({
    super.key,
    required this.text,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.7)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 10),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Share Tech Mono',
                fontSize: 14,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
