import 'package:flutter/material.dart';

class ScreenTransitions {
  /// Smooth slide transition from right to left (forward navigation)
  static Route<T> slideFromRight<T extends Object?>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 250),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOutCubic;

        var tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
  }

  /// Smooth slide transition from left to right (back navigation)
  static Route<T> slideFromLeft<T extends Object?>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 250),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(-1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOutCubic;

        var tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
  }

  /// Fade transition for overlay screens like settings
  static Route<T> fadeTransition<T extends Object?>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: const Duration(milliseconds: 200),
      reverseTransitionDuration: const Duration(milliseconds: 150),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
    );
  }

  /// Scale up transition for game screen (dramatic entrance)
  static Route<T> scaleUpTransition<T extends Object?>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: const Duration(milliseconds: 400),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const curve = Curves.easeOutBack;
        
        var scaleTween = Tween(begin: 0.8, end: 1.0).chain(
          CurveTween(curve: curve),
        );
        
        var fadeTween = Tween(begin: 0.0, end: 1.0).chain(
          CurveTween(curve: Curves.easeInOut),
        );

        return ScaleTransition(
          scale: animation.drive(scaleTween),
          child: FadeTransition(
            opacity: animation.drive(fadeTween),
            child: child,
          ),
        );
      },
    );
  }

  /// Helper method to navigate with specific transition
  static Future<T?> navigateTo<T extends Object?>(
    BuildContext context, 
    Widget page, 
    {TransitionType type = TransitionType.slideFromRight}
  ) {
    Route<T> route;
    
    switch (type) {
      case TransitionType.slideFromRight:
        route = slideFromRight<T>(page);
        break;
      case TransitionType.slideFromLeft:
        route = slideFromLeft<T>(page);
        break;
      case TransitionType.fade:
        route = fadeTransition<T>(page);
        break;
      case TransitionType.scaleUp:
        route = scaleUpTransition<T>(page);
        break;
    }

    return Navigator.push(context, route);
  }

  /// Helper method to replace current screen with transition
  static Future<T?> replaceTo<T extends Object?>(
    BuildContext context, 
    Widget page, 
    {TransitionType type = TransitionType.slideFromRight}
  ) {
    Route<T> route;
    
    switch (type) {
      case TransitionType.slideFromRight:
        route = slideFromRight<T>(page);
        break;
      case TransitionType.slideFromLeft:
        route = slideFromLeft<T>(page);
        break;
      case TransitionType.fade:
        route = fadeTransition<T>(page);
        break;
      case TransitionType.scaleUp:
        route = scaleUpTransition<T>(page);
        break;
    }

    return Navigator.pushReplacement(context, route);
  }
}

enum TransitionType {
  slideFromRight,
  slideFromLeft,
  fade,
  scaleUp,
}