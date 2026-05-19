import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'app/modules/home/home_controller.dart';
import 'app/modules/home/home_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    Get.put(HomeController(), permanent: true);

    return GetMaterialApp(
      title: 'Cash In/Out',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF3B82F6)),
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
        ),
      ),
      home: const HomePage(),
    );
  }
}
