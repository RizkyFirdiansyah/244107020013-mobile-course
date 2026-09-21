import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

void main() => runApp(const DashboardApp());

const kWideBreakpoint = 700;

class DashboardApp extends StatefulWidget {
  const DashboardApp({super.key});

  @override
  State<DashboardApp> createState() => _DashboardAppState();
}

class _DashboardAppState extends State<DashboardApp> {
  bool isDark = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Academic Overview',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.dark,
      ),
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      home: DashboardPage(
        isDark: isDark,
        onDarkChanged: (value) => setState(() => isDark = value),
      ),
    );
  }
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({
    required this.isDark,
    required this.onDarkChanged,
    super.key,
  });
  final bool isDark;
  final ValueChanged<bool> onDarkChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Academic Overview'),
        actions: [
          Row(
            children: [
              Icon(
                isDark ? Icons.dark_mode : Icons.light_mode,
                color: theme.colorScheme.onSurface,
              ),
              const SizedBox(width: 8),
              Semantics(
                label: 'Toggle Dark Mode',
                hint: 'Mengubah tema aplikasi antara terang dan gelap',
                toggled: isDark,
                child: Switch.adaptive(value: isDark, onChanged: onDarkChanged),
              ),
              const SizedBox(width: 12),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Profil Mahasiswa
            const ProfileHeader(),
            const SizedBox(height: 20),

            // Grid Responsif Kartu Informasi Academic
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= kWideBreakpoint;
                final columns = isWide ? 2 : 1;

                return GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: columns,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: isWide ? 2.8 : 2.4,
                  children: const [
                    InfoCard(
                      title: 'SKS Ditempuh',
                      value: '20 SKS',
                      icon: Icons.school,
                    ),
                    InfoCard(
                      title: 'IPK Kumulatif',
                      value: '3.85',
                      icon: Icons.grade,
                    ),
                    InfoCard(
                      title: 'Kehadiran',
                      value: '96%',
                      icon: Icons.assignment_turned_in,
                    ),
                    InfoCard(
                      title: 'Tugas Aktif',
                      value: '3 Pending',
                      icon: Icons.pending_actions,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      label: 'Informasi Profil Mahasiswa',
      container: true,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: theme.colorScheme.primary,
              child: Icon(
                Icons.person,
                color: theme.colorScheme.onPrimary,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Muhammad Rizky Firdiansyah',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'NIM: 244107020013 | Kelas: TI 3E',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class InfoCard extends StatelessWidget {
  const InfoCard({
    required this.title,
    required this.value,
    required this.icon,
    super.key,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      label: '$title: $value',
      container: true,
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, size: 32, color: theme.colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// class DashboardCard extends StatelessWidget {
//   const DashboardCard({required this.title, required this.value, super.key});
//   final String title;
//   final String value;

//   @override
//   Widget build(BuildContext context) {
//     return Semantics(
//       label: 'Kartu Informasi $title',
//       value: value,
//       container: true,
//       child: Card(
//         child: Padding(
//           padding: const EdgeInsets.all(20),
//           child: Row(
//             children: [
//               Expanded(child: Text(title)),
//               Text(value, style: Theme.of(context).textTheme.headlineSmall),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// void main() => runApp(const ProfileApp());

// class ProfileApp extends StatelessWidget {
//   const ProfileApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return const MaterialApp(
//       debugShowCheckedModeBanner: false,
//       home: Scaffold(body: Center(child: ProfileCard())),
//     );
//   }
// }

// class ProfileCard extends StatelessWidget {
//   const ProfileCard({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       width: 320,
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.indigo.shade50,
//         borderRadius: BorderRadius.circular(16),
//       ),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Row(
//             children: [
//               const CircleAvatar(child: Icon(Icons.person)),
//               const SizedBox(width: 12),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: const [
//                     Text(
//                       'Nama Mahasiswa',
//                       style: TextStyle(fontWeight: FontWeight.bold),
//                     ),
//                     Text('Muhammad Rizky Firdiansyah, S.Tr.Kom.'),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 12),
//           const Row(
//             children: [
//               Expanded(child: Text('NIM')),
//               Text('244107020013'),
//             ],
//           ),
//           const Row(
//             children: [
//               Expanded(child: Text('Kelas')),
//               Text('TI-3E'),
//             ],
//           ),
//           const Row(
//             children: [
//               Expanded(child: Text('Email')),
//               Text('mr.frdsyh@gmail.com'),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }
