import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:lofilog/services/database_helper.dart';

class FocusManager extends ChangeNotifier {
  static const Color neonMagenta = Color(0xFFFF00C8);
  static const Color neonCyan = Color(0xFF00FFFF);

  final AudioPlayer _audioPlayer = AudioPlayer();
  Timer? _uiTimer; // Timer ini HANYA untuk update UI

  bool _isRunning = false;
  int _selectedMinutes = 25;
  int _currentSecondsRemaining = 25 * 60;
  bool _timerJustFinished = false;
  DateTime? _deadline; // "Deadline" yang kita simpan

  // Getters
  bool get isRunning => _isRunning;
  int get selectedMinutes => _selectedMinutes;
  int get currentSecondsRemaining => _currentSecondsRemaining;
  bool get timerJustFinished => _timerJustFinished;

  FocusManager() {
    _audioPlayer.setSource(AssetSource('sounds/alarm.mp3'));
    _audioPlayer.setReleaseMode(ReleaseMode.loop);
    _loadSessionFromDB(); // <-- Muat sesi saat app dibuka
  }

  // --- FUNGSI BARU: Muat sesi dari DB ---
  Future<void> _loadSessionFromDB() async {
    _deadline = await DatabaseHelper.instance.getActiveFocusSession();

    if (_deadline == null) {
      // Tidak ada sesi aktif, kondisi normal
      _isRunning = false;
      _currentSecondsRemaining = _selectedMinutes * 60;
      notifyListeners();
      return;
    }

    // Jika ada sesi aktif, hitung sisa waktu
    final now = DateTime.now();

    if (now.isAfter(_deadline!)) {
      // --- Deadline terlewat saat app ditutup ---
      _currentSecondsRemaining = 0;
      _isRunning = false;
      _timerJustFinished = true; // Kibarkan bendera untuk alarm
      await DatabaseHelper.instance.clearFocusSession();
    } else {
      // --- Timer masih berjalan ---
      _currentSecondsRemaining = _deadline!.difference(now).inSeconds;
      _isRunning = true;
      _startUiTimer(); // Mulai timer UI untuk hitung mundur
    }

    notifyListeners();
  }

  // --- MODIFIKASI: Timer UI ---
  void _startUiTimer() {
    _uiTimer?.cancel(); // Hentikan timer lama
    _uiTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      // Hitung sisa waktu
      _currentSecondsRemaining = _deadline!
          .difference(DateTime.now())
          .inSeconds;

      if (_currentSecondsRemaining > 0) {
        // Biarkan timer UI berjalan
      } else {
        // --- Waktu Habis ---
        _uiTimer?.cancel();
        _isRunning = false;
        _currentSecondsRemaining = 0;
        _playAlarmSound();
        _timerJustFinished = true;
        DatabaseHelper.instance.clearFocusSession(); // Hapus dari DB
      }
      notifyListeners(); // Update UI
    });
  }

  // --- MODIFIKASI: Fungsi "Start" ---
  Future<void> startTimer() async {
    if (_isRunning) return; // Jangan lakukan apa-apa jika sudah jalan

    _isRunning = true;
    _deadline = DateTime.now().add(Duration(minutes: _selectedMinutes));
    _currentSecondsRemaining = _selectedMinutes * 60;

    // Simpan "deadline" ke database
    await DatabaseHelper.instance.saveFocusSession(_deadline!);

    // Mulai timer UI
    _startUiTimer();
    notifyListeners();
  }

  // --- MODIFIKASI: Fungsi "Reset" ---
  Future<void> resetTimer() async {
    _uiTimer?.cancel();
    _audioPlayer.stop();
    await DatabaseHelper.instance.clearFocusSession(); // Hapus dari DB

    _isRunning = false;
    _deadline = null;
    _currentSecondsRemaining = _selectedMinutes * 60;
    _timerJustFinished = false;
    notifyListeners();
  }

  // --- MODIFIKASI: Fungsi "Set Preset" ---
  Future<void> setPresetTime(int minutes) async {
    await resetTimer(); // Reset timer lama
    _selectedMinutes = minutes;
    _currentSecondsRemaining = minutes * 60;
    notifyListeners();
  }

  void acknowledgeTimerFinish() {
    _timerJustFinished = false;
  }

  void _playAlarmSound() {
    _audioPlayer.play(AssetSource('sounds/alarm.mp3'));
  }

  String formatTime(int totalSeconds) {
    final int minutes = totalSeconds ~/ 60;
    final int seconds = totalSeconds % 60;
    final String minutesStr = minutes.toString().padLeft(2, '0');
    final String secondsStr = seconds.toString().padLeft(2, '0');
    return '$minutesStr:$secondsStr';
  }

  @override
  void dispose() {
    _uiTimer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }
}
