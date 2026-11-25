import '../../models/demo_config.dart';

/// Bottom-bar slots for the check-in shell. Page dressing is later plans.
abstract final class CheckInTabs {
  static const scan = 'scan';
  static const history = 'history';
  static const settings = 'settings';
  static const dashboard = 'dashboard';
  static const workers = 'workers';
  static const bench = 'bench';
  static const crew = 'crew';
  static const tools = 'tools';

  static const worker = [scan, history, settings];
  static const supervisor = [dashboard, workers, settings];
  static const admin = [bench, crew, tools];

  static List<String> forRole(String role) {
    switch (role) {
      case DemoRoles.supervisor:
        return supervisor;
      case DemoRoles.demoAdmin:
        return admin;
      default:
        return worker;
    }
  }

  static String label(String tab) {
    switch (tab) {
      case scan:
        return 'Scan';
      case history:
        return 'History';
      case settings:
        return 'Settings';
      case dashboard:
        return 'Dashboard';
      case workers:
        return 'Workers';
      case bench:
        return 'Bench';
      case crew:
        return 'Crew';
      case tools:
        return 'Tools';
      default:
        return tab;
    }
  }
}
