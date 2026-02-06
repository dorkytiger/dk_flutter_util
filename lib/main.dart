import 'package:dk_util/app_routes.dart';
import 'package:dk_util/dk_util.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!await DKLog.hasStoragePermission()) {
    await DKLog.requestStoragePermission();
  }
  await DKLog.initFileLog();

  DKLog.i('应用启动', tag: 'App');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DK Util Demo',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple)),
      initialRoute: AppRoutes.home,
      routes: AppRoutes.routes,
    );
  }
}