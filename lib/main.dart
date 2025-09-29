import 'package:flutter/material.dart';
import 'package:hipster_task/providers/video_call_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'providers/auth_provider.dart';
import 'providers/user_provider.dart';
import 'screens/login_screen.dart';
import 'screens/user_list_screen.dart';
import 'screens/video_call_screen.dart';
import 'widgets/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => VideoCallProvider()),
      ],
      child: MaterialApp(
        title: 'Video Call App',
        theme: ThemeData(primarySwatch: Colors.blue),
        debugShowCheckedModeBanner: false,
        initialRoute: '/splash',
        routes: {
          '/splash': (context) => const SplashScreen(),
          '/login': (context) => const LoginScreen(),
          '/users': (context) => const UserListScreen(),
          '/video-call': (context) => const VideoCallScreen(
            // channelName: 'default@reqres.in',
            userName: 'Default User',
          ),
        },
      ),
    );
  }
}
