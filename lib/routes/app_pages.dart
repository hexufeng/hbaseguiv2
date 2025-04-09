import 'package:get/get.dart';
import '../pages/home/home_view.dart';
import '../pages/home/home_binding.dart';
import '../pages/connection/connection_view.dart';
import '../pages/connection/connection_binding.dart';
import 'routes.dart';

class AppPages {
  static const INITIAL = Routes.CONNECTION;

  static final routes = [
    GetPage(
      name: Routes.HOME,
      page: () => const HomeView(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: Routes.CONNECTION,
      page: () => const ConnectionView(),
      binding: ConnectionBinding(),
    ),
  ];
} 