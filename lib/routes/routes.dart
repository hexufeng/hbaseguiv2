import 'package:get/get.dart';
import '../pages/connection/connection_view.dart';
import '../pages/home/home_view.dart';

abstract class Routes {
  static const CONNECTION = '/connection';
  static const HOME = '/home';

  static List<GetPage> get pages => [
        GetPage(
          name: CONNECTION,
          page: () => const ConnectionView(),
        ),
        GetPage(
          name: HOME,
          page: () => const HomeView(),
        ),
      ];
} 