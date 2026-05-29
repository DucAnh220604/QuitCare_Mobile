import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'routes/app_routes.dart';
import 'screens/main_app.dart';
import 'constants/colors.dart';
import 'services/auth_provider.dart';
import 'screens/auth/login_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late AuthProvider _authProvider;

  @override
  void initState() {
    super.initState();
    _authProvider = AuthProvider();
    _authProvider.checkAuthStatus();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider.value(value: _authProvider)],
      child: MaterialApp(
        title: 'QuitCare Mobile',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primaryBlue),
          useMaterial3: true,
          primaryColor: AppColors.primaryBlue,
          scaffoldBackgroundColor: AppColors.lightGrey,
        ),
        home: Consumer<AuthProvider>(
          builder: (context, auth, _) {
            if (auth.isCheckingAuth) {
              return Scaffold(
                backgroundColor: AppColors.background,
                body: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.primaryBlue,
                    ),
                  ),
                ),
              );
            }
            return auth.isLoggedIn ? const MainApp() : const LoginScreen();
          },
        ),
        onGenerateRoute: AppRoutes.generateRoute,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
