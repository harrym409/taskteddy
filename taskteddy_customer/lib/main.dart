import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'l10n/app_localizations.dart';
import 'state/locale_provider.dart';
import 'screens/splash.dart';
import 'screens/auth.dart';
import 'screens/shell.dart';
import 'screens/tasks.dart';
import 'screens/messages.dart';
import 'screens/other.dart';
import 'screens/profile.dart';
import 'state/app_provider_observer.dart';
import 'theme/theme.dart';
import 'widgets/alert_banner.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(const TaskTeddyCustomerApp());
}

class TaskTeddyCustomerApp extends StatelessWidget {
  const TaskTeddyCustomerApp({super.key});

  @override
  Widget build(BuildContext context) => ProviderScope(
        observers: [
          if (kDebugMode) const AppProviderObserver(),
        ],
        child: const App(),
      );
}

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext ctx, WidgetRef ref) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'TaskTeddy',
        theme: buildCustomerTheme(),
        navigatorKey: appNavigatorKey,
        builder: (context, child) =>
            AlertBannerHost(child: child ?? const SizedBox.shrink()),
        locale: ref.watch(localeProvider),
        localizationsDelegates: AppL10n.localizationsDelegates,
        supportedLocales: AppL10n.supportedLocales,
        initialRoute: '/splash',
        routes: {
          '/splash': (_) => const SplashScreen(),
          '/post-login-splash': (_) => const SplashScreen.afterLogin(),
          '/login': (_) => const LoginScreen(),
          '/register': (_) => const RegisterScreen(),
          '/home': (_) => const MainShell(),
          '/post-task': (_) => const PostTaskScreen(),
          '/messages': (_) => const MessagesScreen(),
          '/notifications': (_) => const NotificationsScreen(),
          '/profile': (_) => const ProfileScreen(),
        },
      );
}
