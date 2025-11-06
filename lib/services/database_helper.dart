import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:async';

// --- ( MODEL DATA UNTUK NOTE ) ---
class Note {
  final int? id;
  final String title;
  final String content;
  final DateTime date;
  final bool isSecret;

  Note({
    this.id,
    required this.title,
    required this.content,
    required this.date,
    this.isSecret = false,
  });

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'] as int,
      title: map['title'] as String,
      content: map['content'] as String,
      date: DateTime.parse(map['date']),
      isSecret: map['isSecret'] == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'date': date.toIso8601String(),
      'isSecret': isSecret ? 1 : 0,
    };
  }
}

// --- ( MODEL DATA UNTUK TASK ) ---
class Task {
  final int? id;
  final String title;
  final String course;
  final DateTime? dueDate;
  final String description;
  bool isDone;

  Task({
    this.id,
    required this.title,
    required this.course,
    this.dueDate,
    this.description = '',
    this.isDone = false,
  });

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'] as int,
      title: map['title'] as String,
      course: map['course'] as String,
      dueDate: map['dueDate'] != null ? DateTime.parse(map['dueDate']) : null,
      description: map['description'] as String,
      isDone: map['isDone'] == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'course': course,
      'dueDate': dueDate?.toIso8601String(),
      'description': description,
      'isDone': isDone ? 1 : 0,
    };
  }
}

// --- ( MODEL DATA UNTUK SCHEDULE ) ---
class Schedule {
  final int? id;
  final String course;
  final String day;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final String room;
  final String lecturer;

  Schedule({
    this.id,
    required this.course,
    required this.day,
    required this.startTime,
    required this.endTime,
    required this.room,
    required this.lecturer,
  });

  static String _timeOfDayToString(TimeOfDay tod) {
    return '${tod.hour.toString().padLeft(2, '0')}:${tod.minute.toString().padLeft(2, '0')}';
  }

  static TimeOfDay _stringToTimeOfDay(String s) {
    final parts = s.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  factory Schedule.fromMap(Map<String, dynamic> map) {
    return Schedule(
      id: map['id'] as int,
      course: map['course'] as String,
      day: map['day'] as String,
      startTime: _stringToTimeOfDay(map['startTime']),
      endTime: _stringToTimeOfDay(map['endTime']),
      room: map['room'] as String,
      lecturer: map['lecturer'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'course': course,
      'day': day,
      'startTime': _timeOfDayToString(startTime),
      'endTime': _timeOfDayToString(endTime),
      'room': room,
      'lecturer': lecturer,
    };
  }
}

// --- "OTAK" DATABASE ---
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('lofilog.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const textTypeNull = 'TEXT NULL';
    const intType = 'INTEGER NOT NULL';
    const textPkType = 'TEXT PRIMARY KEY'; // <-- Tipe data baru

    await db.execute('''
    CREATE TABLE notes (
      id $idType,
      title $textType,
      content $textType,
      date $textType,
      isSecret $intType
    )
    ''');

    await db.execute('''
    CREATE TABLE tasks (
      id $idType,
      title $textType,
      course $textTypeNull,
      dueDate $textTypeNull,
      description $textTypeNull,
      isDone $intType
    )
    ''');

    await db.execute('''
    CREATE TABLE schedules (
      id $idType,
      course $textType,
      day $textType,
      startTime $textType,
      endTime $textType,
      room $textTypeNull,
      lecturer $textTypeNull
    )
    ''');
    
    await db.execute('''
    CREATE TABLE focus_session (
      id INTEGER PRIMARY KEY, 
      deadline TEXT NOT NULL
    )
    ''');
    
    // --- MODIFIKASI: Tambah Tabel untuk Settings ---
    await db.execute('''
    CREATE TABLE app_settings (
      setting_key $textPkType,
      setting_value $textType
    )
    ''');
    // ------------------------------------------
  }

  // --- (Fungsi Note, Task, Schedule tidak berubah) ---
  Future<Note> insertNote(Note note) async {
    final db = await instance.database;
    final id = await db.insert('notes', note.toMap());
    return Note(
        id: id,
        title: note.title,
        content: note.content,
        date: note.date,
        isSecret: note.isSecret);
  }
  Future<List<Note>> getNotes() async {
    final db = await instance.database;
    final maps = await db.query('notes', orderBy: 'date DESC');
    return maps.map((map) => Note.fromMap(map)).toList();
  }
  Future<int> deleteNote(int id) async {
    final db = await instance.database;
    return await db.delete(
      'notes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
  Future<Task> insertTask(Task task) async {
    final db = await instance.database;
    final id = await db.insert('tasks', task.toMap());
    return Task(
        id: id,
        title: task.title,
        course: task.course,
        dueDate: task.dueDate,
        description: task.description,
        isDone: task.isDone);
  }
  Future<List<Task>> getTasks() async {
    final db = await instance.database;
    final maps = await db.query('tasks', orderBy: 'dueDate ASC');
    return maps.map((map) => Task.fromMap(map)).toList();
  }
  Future<int> updateTaskDone(Task task) async {
    final db = await instance.database;
    return db.update(
      'tasks',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }
  Future<int> deleteTask(int id) async {
    final db = await instance.database;
    return await db.delete(
      'tasks',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
  Future<Schedule> insertSchedule(Schedule schedule) async {
    final db = await instance.database;
    final id = await db.insert('schedules', schedule.toMap());
    return Schedule(
        id: id,
        course: schedule.course,
        day: schedule.day,
        startTime: schedule.startTime,
        endTime: schedule.endTime,
        room: schedule.room,
        lecturer: schedule.lecturer);
  }
  Future<List<Schedule>> getSchedules() async {
    final db = await instance.database;
    final maps = await db.query('schedules');
    return maps.map((map) => Schedule.fromMap(map)).toList();
  }
  Future<int> deleteSchedule(int id) async {
    final db = await instance.database;
    return await db.delete(
      'schedules',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
  
  // --- (Fungsi Timer tidak berubah) ---
  Future<void> saveFocusSession(DateTime deadline) async {
    final db = await instance.database;
    await db.delete('focus_session');
    await db.insert('focus_session', {'id': 1, 'deadline': deadline.toIso8601String()});
  }
  Future<DateTime?> getActiveFocusSession() async {
    final db = await instance.database;
    final maps = await db.query('focus_session', where: 'id = ?', whereArgs: [1]);
    if (maps.isNotEmpty) {
      return DateTime.parse(maps.first['deadline'] as String);
    }
    return null;
  }
  Future<void> clearFocusSession() async {
    final db = await instance.database;
    await db.delete('focus_session');
  }
  
  // --- FUNGSI BARU UNTUK SETTINGS ---
  Future<void> saveSetting(String key, String value) async {
    final db = await instance.database;
    await db.insert(
      'app_settings',
      {'setting_key': key, 'setting_value': value},
      conflictAlgorithm: ConflictAlgorithm.replace, // Timpa jika sudah ada
    );
  }

  Future<String?> getSetting(String key) async {
    final db = await instance.database;
    final maps = await db.query(
      'app_settings',
      where: 'setting_key = ?',
      whereArgs: [key],
    );
    if (maps.isNotEmpty) {
      return maps.first['setting_value'] as String;
    }
    return null;
  }
  // ---------------------------------

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}