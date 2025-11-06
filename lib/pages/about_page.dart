import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // Import package yang baru kita tambahkan

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  // --- Helper Function untuk Membuka URL ---
  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    // 'externalApplication' akan membukanya di browser, bukan di dalam app
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      debugPrint('Could not launch $url'); // Pesan error jika gagal
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color neonCyan = Color(0xFF00FFFF);

    return Scaffold(
      // 1. App Bar
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: neonCyan),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: const Text(
          'About App',
          style: TextStyle(
            fontFamily: 'Orbitron',
            fontWeight: FontWeight.bold,
            color: neonCyan,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),

      // 2. Body Halaman
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Header ---
            Text(
              '⚙️ About — LoFiLog',
              style: TextStyle(
                fontFamily: 'Orbitron',
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: neonCyan,
                shadows: [
                  BoxShadow(color: neonCyan.withOpacity(0.5), blurRadius: 10),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // --- Info Aplikasi (dari teks kamu) ---
            _buildInfoRow(title: 'App Name', value: 'LoFiLog'),
            _buildInfoRow(
              title: 'Developer',
              value: 'Thoriq Ahmad S.A.',
            ), // [cite: 308]
            _buildInfoRow(title: 'Framework', value: 'Flutter'),
            _buildInfoRow(title: 'Theme', value: 'Cyberpunk / Glassmorphism'),
            const SizedBox(height: 24),
            const Divider(color: neonCyan, thickness: 0.5),
            const SizedBox(height: 24),

            // --- Tentang Aplikasi (dari teks kamu) ---
            Text(
              '💬 Tentang Aplikasi',
              style: TextStyle(
                fontFamily: 'Orbitron',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'LoFiLog adalah aplikasi personal bergaya Cyberpunk yang dirancang untuk membantu pengguna untuk mencatat, merencanakan, dan menenangkan pikiran di tengah hiruk-pikuk aktivitas harian.\n\nDengan tampilan neon futuristik dan nuansa tenang khas musik Lo-Fi, aplikasi ini bikin kegiatan produktif terasa lebih santai dan reflektif.',
              style: TextStyle(
                fontFamily: 'Share Tech Mono',
                fontSize: 16,
                color: Colors.white.withOpacity(0.8),
                height: 1.5, // Jarak antar baris
              ),
            ),
            const SizedBox(height: 24),
            const Divider(color: neonCyan, thickness: 0.5),
            const SizedBox(height: 24),

            // --- Developer Info (dari teks kamu & konsep) ---
            Text(
              'Developer Info',
              style: TextStyle(
                fontFamily: 'Orbitron',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
            const SizedBox(height: 20),

            // Tombol LinkedIn
            _buildSocialButton(
              text: 'LinkedIn',
              icon: Icons.link,
              color: const Color(0xFF0A66C2), // Warna Biru LinkedIn
              onPressed: () => _launchURL(
                'https://www.linkedin.com/in/thoriq-ahmad-salahuddin-al-ayubi-87b3852b7/',
              ), // [cite: 309]
            ),
            const SizedBox(height: 16),

            // Tombol GitHub
            _buildSocialButton(
              text: 'GitHub',
              icon: Icons.code,
              color: Colors.white, // Warna Putih GitHub
              onPressed: () =>
                  _launchURL('https://github.com/Thrq19/'), // [cite: 311]
            ),
            const SizedBox(height: 16),

            // Tombol Instagram
            _buildSocialButton(
              text: 'Instagram',
              icon: Icons.camera_alt_outlined,
              color: const Color(0xFFE1306C), // Warna Pink Instagram
              onPressed: () => _launchURL(
                'https://www.instagram.com/thrq.a_19/',
              ), // [cite: 310]
            ),
          ],
        ),
      ),
    );
  }

  // --- Widget Helper untuk Baris Info ---
  Widget _buildInfoRow({required String title, required String value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$title: ',
            style: TextStyle(
              fontFamily: 'Share Tech Mono',
              color: Colors.white.withOpacity(0.7),
              fontSize: 16,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontFamily: 'Share Tech Mono',
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Widget Helper untuk Tombol Sosial Media ---
  Widget _buildSocialButton({
    required String text,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.1),
        foregroundColor: color,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: color.withOpacity(0.5)),
        ),
        shadowColor: color,
        elevation: 3,
      ),
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      label: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Share Tech Mono',
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
