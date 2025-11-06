import 'package:flutter/material.dart' hide FocusManager;
import 'package:provider/provider.dart';
import 'package:lofilog/services/focus_manager.dart';

class FocusTimePage extends StatelessWidget {
  const FocusTimePage({super.key});

  Widget _buildPresetButton(BuildContext context, int minutes) {
    final manager = context.watch<FocusManager>();
    bool isActive = manager.selectedMinutes == minutes;
    Color color = isActive
        ? FocusManager.neonMagenta
        : Colors.white.withOpacity(0.5);

    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color, width: isActive ? 2 : 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shadowColor: isActive ? FocusManager.neonMagenta : null,
        elevation: isActive ? 5 : 0,
      ),
      onPressed: () {
        // --- MODIFIKASI: Panggil fungsi baru ---
        context.read<FocusManager>().setPresetTime(minutes);
      },
      child: Text(
        '$minutes\nmin',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'Share Tech Mono',
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final manager = context.watch<FocusManager>();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: FocusManager.neonCyan,
          ),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: const Text(
          'Focus Time Clock',
          style: TextStyle(
            fontFamily: 'Orbitron',
            fontWeight: FontWeight.bold,
            color: FocusManager.neonCyan,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Spacer(flex: 2),

            // --- MODIFIKASI: Baca sisa waktu yang baru ---
            Text(
              manager.formatTime(manager.currentSecondsRemaining),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Orbitron',
                fontSize: 90,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [
                  BoxShadow(
                    color: FocusManager.neonCyan,
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
            ),
            Text(
              manager.isRunning ? 'stay focused...' : 'ready to focus',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Share Tech Mono',
                fontSize: 18,
                color: manager.isRunning
                    ? FocusManager.neonCyan.withOpacity(0.8)
                    : FocusManager.neonMagenta.withOpacity(0.8),
                letterSpacing: 2,
              ),
            ),
            const Spacer(flex: 1),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(child: _buildPresetButton(context, 25)),
                const SizedBox(width: 16),
                Expanded(child: _buildPresetButton(context, 45)),
                const SizedBox(width: 16),
                Expanded(child: _buildPresetButton(context, 60)),
              ],
            ),
            const SizedBox(height: 32),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: manager.isRunning
                          ? Colors.grey[800]
                          : FocusManager.neonCyan,
                      foregroundColor: manager.isRunning
                          ? FocusManager.neonCyan
                          : Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      shadowColor: FocusManager.neonCyan,
                      elevation: 5,
                    ),
                    // --- MODIFIKASI: Panggil fungsi baru ---
                    onPressed: () {
                      context.read<FocusManager>().startTimer();
                    },
                    icon: Icon(
                      manager.isRunning
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      size: 30,
                    ),
                    label: Text(
                      manager.isRunning ? 'Pause' : 'Start',
                      style: const TextStyle(
                        fontFamily: 'Orbitron',
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white.withOpacity(0.7),
                    side: BorderSide(color: Colors.white.withOpacity(0.5)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  // --- MODIFIKASI: Panggil fungsi baru ---
                  onPressed: () {
                    context.read<FocusManager>().resetTimer();
                  },
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text(
                    'Reset',
                    style: TextStyle(
                      fontFamily: 'Share Tech Mono',
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(flex: 3),
          ],
        ),
      ),
    );
  }
}
