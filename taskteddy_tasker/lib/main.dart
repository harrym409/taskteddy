import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'l10n/app_localizations.dart';
import 'theme/theme.dart';
import 'services/locale_controller.dart';
import 'screens/splash.dart';
import 'screens/messages.dart';
import 'screens/login_otp.dart';
import 'screens/shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  // Load the saved language before the first frame so the UI opens localized.
  await LocaleController().load();
  runApp(const TaskerApp());
}

class TaskerApp extends StatelessWidget {
  const TaskerApp({super.key});

  @override
  Widget build(BuildContext context) {
    final localeController = LocaleController();
    return ListenableBuilder(
      listenable: localeController,
      builder: (context, _) {
        return MaterialApp(
          title: 'TaskTeddy Tasker',
          debugShowCheckedModeBanner: false,
          theme: buildTaskerTheme(),
          locale: localeController.locale,
          localizationsDelegates: AppL10n.localizationsDelegates,
          supportedLocales: AppL10n.supportedLocales,
          initialRoute: '/splash',
          routes: {
            '/': (_) => const SplashScreen(),
            '/splash': (_) => const SplashScreen(),
            '/post-login-splash': (_) => const SplashScreen.afterLogin(),
            '/login': (_) => const TaskerOtpLoginScreen(),
            '/home': (_) => const MainShell(),
            '/messages': (_) => const MessagesScreen(),
          },
        );
      },
    );
  }
}
