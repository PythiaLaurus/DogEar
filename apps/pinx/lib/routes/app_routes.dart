import 'package:go_router/go_router.dart';
import '../features/settings/presentation/settings_view.dart';
import '../features/shell/presentation/shell_view.dart';

final router = GoRouter(
  initialLocation: "/settings",
  routes: [
    ShellRoute(
      builder: (context, state, child) => ShellView(child: child),
      routes: <RouteBase>[
        GoRoute(
          name: "settings",
          path: "/settings",
          builder: (context, state) => const SettingsView(),
        ),
      ],
    ),
  ],
);
