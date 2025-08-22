import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:tasknest/screens/auth/email_verification_screen.dart';
import 'package:tasknest/screens/team/create_team_screen.dart';
import 'package:tasknest/screens/team/team_list_screen.dart';

import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/profile/edit_profile_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/splash/splash_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String home = '/home';
  static const String profile = '/view_profile';
  static const String editProfile = '/edit_profile';
  static const String emailVerification = '/email_verification';
  static const String teamList = '/teams';
  static const String createTeam = '/create-team';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => SplashScreen());
      case login:
        return MaterialPageRoute(builder: (_) => LoginScreen());
      case signup:
        return MaterialPageRoute(builder: (_) => SignupScreen());
      case home:
        return MaterialPageRoute(builder: (_) => HomeScreen());
      case editProfile:
        return MaterialPageRoute(builder: (_) => EditProfileScreen());

      case teamList:
        return MaterialPageRoute(builder: (_) => TeamListScreen());

      case createTeam:
        return MaterialPageRoute(builder: (_) => CreateTeamScreen());

      case profile:
        return MaterialPageRoute(builder: (_) => ProfileScreen());
      case emailVerification:
        return MaterialPageRoute(builder: (_) => EmailVerificationScreen());
      default:
        return MaterialPageRoute(
          builder:
              (_) => Scaffold(
                body: Center(
                  child: Text("No route defined for ${settings.name}"),
                ),
              ),
        );
    }
  }
}
