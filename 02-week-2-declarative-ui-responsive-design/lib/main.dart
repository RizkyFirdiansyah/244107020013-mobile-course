import 'package:flutter/material.dart';

void main() => runApp(const DashboardApp());

class DashboardApp extends StatelessWidget {
  const DashboardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: Colors.indigo,
      ),
      themeMode: ThemeMode.system,
      home: const DashboardPage(),
    );
  }
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Student Dashboard')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 700 ? 2 : 1;
          return GridView.count(
            padding: const EdgeInsets.all(16),
            crossAxisCount: columns,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 2.6,
            children: const [
              DashboardCard(title: 'Assignments', value: '8'),
              DashboardCard(title: 'Attendance', value: '92%'),
              DashboardCard(title: 'Portfolio', value: 'Ready'),
              DashboardCard(title: 'Current week', value: '02'),
            ],
          );
        },
      ),
    );
  }
}

class DashboardCard extends StatelessWidget {
  const DashboardCard({required this.title, required this.value, super.key});
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(child: Text(title)),
            Text(value, style: Theme.of(context).textTheme.headlineSmall),
          ],
        ),
      ),
    );
  }
}

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
