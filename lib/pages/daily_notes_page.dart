import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
// --- MODIFIKASI 1: Import Database Helper ---
import 'package:lofilog/services/database_helper.dart';

class DailyNotesPage extends StatefulWidget {
  const DailyNotesPage({super.key});

  @override
  State<DailyNotesPage> createState() => _DailyNotesPageState();
}

class _DailyNotesPageState extends State<DailyNotesPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  // --- MODIFIKASI 2: Ganti List menjadi Future ---
  late Future<List<Note>> _notesFuture;
  List<Note> _allNotes = []; // Cache untuk pencarian
  List<Note> _filteredNotes = []; // Daftar yang ditampilkan

  bool _isSecretNote = false;
  bool _showSecretNotes = false;
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    // Panggil data saat halaman dibuka
    _refreshNotes();
  }

  // --- MODIFIKASI 3: Fungsi baru untuk me-refresh data ---
  void _refreshNotes() {
    _notesFuture = DatabaseHelper.instance.getNotes();

    // Kita juga perlu update daftar untuk pencarian
    _notesFuture.then((notes) {
      setState(() {
        _allNotes = notes;
        _filterNotes(); // Panggil filter
      });
    });
  }

  // --- MODIFIKASI 4: Fungsi baru untuk memfilter pencarian ---
  void _filterNotes() {
    final query = _searchQuery.toLowerCase();

    setState(() {
      _filteredNotes = _allNotes.where((note) {
        // Cek filter rahasia
        final matchesSecret = !note.isSecret || _showSecretNotes;
        if (!matchesSecret) return false;

        // Cek filter pencarian
        if (query.isEmpty) return true; // Tampilkan jika tidak ada query

        final matchesTitle = note.title.toLowerCase().contains(query);
        final matchesContent = note.content.toLowerCase().contains(query);

        return matchesTitle || matchesContent;
      }).toList();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // --- MODIFIKASI 5: Upgrade Fungsi "Save" ---
  void _saveNote() async {
    // <-- Ubah jadi async
    final String title = _titleController.text;
    final String content = _contentController.text;
    final bool isSecret = _isSecretNote;

    if (title.isEmpty && content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Catatan tidak boleh kosong!',
            style: TextStyle(fontFamily: 'Share Tech Mono'),
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final newNote = Note(
      title: title.isEmpty ? "Tanpa Judul" : title,
      content: content,
      date: DateTime.now(),
      isSecret: isSecret,
    );

    // --- Simpan ke Database ---
    await DatabaseHelper.instance.insertNote(newNote);

    // Reset UI
    _titleController.clear();
    _contentController.clear();
    setState(() {
      _isSecretNote = false;
    });

    _refreshNotes(); // <-- Refresh daftar

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Catatan "${newNote.title}" berhasil disimpan!',
          style: const TextStyle(fontFamily: 'Share Tech Mono'),
        ),
        backgroundColor: const Color(0xFFD2FF4D),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // --- MODIFIKASI 6: Upgrade Fungsi "Hapus" ---
  void _showNoteDialog(Note note) {
    final String formattedDate = DateFormat(
      'EEEE, dd MMM yyyy (HH:mm)',
      'id_ID',
    ).format(note.date);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0A0A12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFF00FFFF), width: 0.5),
          ),
          title: Row(
            children: [
              Icon(
                note.isSecret ? Icons.lock : Icons.notes,
                color: const Color(0xFF00FFFF),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  note.title,
                  style: const TextStyle(
                    fontFamily: 'Orbitron',
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formattedDate,
                  style: TextStyle(
                    fontFamily: 'Share Tech Mono',
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(color: Color(0xFF00FFFF), thickness: 0.5),
                const SizedBox(height: 16),
                Text(
                  note.content,
                  style: TextStyle(
                    fontFamily: 'Share Tech Mono',
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                // <-- Ubah jadi async
                // --- Hapus dari Database ---
                if (note.id != null) {
                  await DatabaseHelper.instance.deleteNote(note.id!);
                  _refreshNotes(); // <-- Refresh daftar
                }
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Catatan "${note.title}" telah dihapus.',
                      style: const TextStyle(fontFamily: 'Share Tech Mono'),
                    ),
                    backgroundColor: Colors.redAccent,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: const Text(
                'Hapus',
                style: TextStyle(
                  fontFamily: 'Share Tech Mono',
                  color: Color(0xFFFF00C8),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'Tutup',
                style: TextStyle(
                  fontFamily: 'Share Tech Mono',
                  color: Color(0xFF00FFFF),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color neonCyan = Color(0xFF00FFFF);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: neonCyan),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: const Text(
          'Daily Notes',
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
          IconButton(
            onPressed: () {
              setState(() {
                _showSecretNotes = !_showSecretNotes;
                _filterNotes(); // <-- Refresh filter
              });
            },
            icon: Icon(
              _showSecretNotes ? Icons.lock_open : Icons.lock,
              color: _showSecretNotes ? neonCyan : Colors.white70,
            ),
            tooltip: _showSecretNotes
                ? 'Sembunyikan Catatan Rahasia'
                : 'Tampilkan Catatan Rahasia',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Bagian Input Catatan (Tidak Berubah) ---
            Text(
              'Bagaimana kabarmu hari ini?',
              style: TextStyle(
                fontFamily: 'Share Tech Mono',
                fontSize: 18,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _titleController,
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'Share Tech Mono',
              ),
              decoration: InputDecoration(
                labelText: 'Judul Notes',
                labelStyle: TextStyle(color: neonCyan.withOpacity(0.7)),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: neonCyan.withOpacity(0.5)),
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: neonCyan, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _contentController,
              maxLines: 5,
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'Share Tech Mono',
              ),
              decoration: InputDecoration(
                labelText: 'Isi Notes...',
                labelStyle: TextStyle(color: neonCyan.withOpacity(0.7)),
                alignLabelWithHint: true,
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: neonCyan.withOpacity(0.5)),
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: neonCyan, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Theme(
                  data: ThemeData(
                    unselectedWidgetColor: neonCyan.withOpacity(0.7),
                  ),
                  child: Checkbox(
                    value: _isSecretNote,
                    activeColor: neonCyan,
                    checkColor: Colors.black,
                    onChanged: (bool? newValue) {
                      setState(() {
                        _isSecretNote = newValue ?? false;
                      });
                    },
                  ),
                ),
                Text(
                  'Tandai sebagai catatan rahasia',
                  style: TextStyle(
                    fontFamily: 'Share Tech Mono',
                    color: _isSecretNote
                        ? neonCyan
                        : Colors.white.withOpacity(0.7),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: neonCyan,
                foregroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                shadowColor: neonCyan,
                elevation: 5,
              ),
              onPressed: _saveNote,
              child: const Text(
                'Save Note',
                style: TextStyle(
                  fontFamily: 'Orbitron',
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),

            // --- Bagian Riwayat Catatan ---
            const SizedBox(height: 40),
            Text(
              'Note History',
              style: TextStyle(
                fontFamily: 'Orbitron',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
            const SizedBox(height: 16),

            // --- MODIFIKASI 7: Search Bar dihubungkan ---
            TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                  _filterNotes(); // Panggil filter
                });
              },
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'Share Tech Mono',
              ),
              decoration: InputDecoration(
                hintText: 'Cari catatan...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                prefixIcon: Icon(
                  Icons.search,
                  color: neonCyan.withOpacity(0.7),
                ),
                filled: true,
                fillColor: Colors.black.withOpacity(0.3),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: neonCyan.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: neonCyan, width: 1),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // --- MODIFIKASI 8: Tampilkan Daftar Catatan dari Future ---
            FutureBuilder<List<Note>>(
              future: _notesFuture, // Gunakan Future
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: neonCyan),
                  );
                }

                // Cek setelah loading
                if (_filteredNotes.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Text(
                        _allNotes.isEmpty
                            ? 'Belum ada riwayat catatan.'
                            : 'Catatan tidak ditemukan.',
                        style: TextStyle(
                          fontFamily: 'Share Tech Mono',
                          color: Colors.white.withOpacity(0.5),
                        ),
                      ),
                    ),
                  );
                }

                // Tampilkan daftar yang sudah difilter
                return ListView.builder(
                  itemCount: _filteredNotes.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    final note = _filteredNotes[index];
                    final String formattedDate = DateFormat(
                      'dd MMM yyyy, HH:mm',
                    ).format(note.date);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00FFFF).withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF00FFFF).withOpacity(0.2),
                        ),
                      ),
                      child: ListTile(
                        onTap: () => _showNoteDialog(note), // Panggil dialog
                        leading: note.isSecret
                            ? const Icon(Icons.lock, color: neonCyan, size: 20)
                            : const Icon(
                                Icons.notes,
                                color: Colors.white54,
                                size: 20,
                              ),
                        title: Text(
                          note.title,
                          style: const TextStyle(
                            fontFamily: 'Share Tech Mono',
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          '${note.content}\n($formattedDate)',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Share Tech Mono',
                            color: Colors.white.withOpacity(0.6),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
