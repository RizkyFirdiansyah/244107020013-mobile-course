import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'pages/todo_page.dart';

void main() => runApp(const ProviderScope(child: MyApp()));

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Week 3 - ToDo',
        theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
        home: const TodoPage(),
      );
}

// import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';
// import 'pages/detail_page.dart';
// import 'pages/home_page.dart';

// void main() => runApp(const MyApp());

// final _router = GoRouter(
//   initialLocation: '/',
//   routes: [
//     GoRoute(
//       path: '/',
//       builder: (context, state) => const HomePage(),
//       routes: [
//         GoRoute(
//           path: 'detail/:id',
//           builder: (context, state) => DetailPage(
//             id: state.pathParameters['id']!,
//           ),
//         ),
//       ],
//     ),
//   ],
// );

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp.router(
//       title: 'Week 3 - Navigation',
//       routerConfig: _router,
//       theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
//     );
//   }
// }