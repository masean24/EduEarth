/// Sumber tunggal untuk seluruh nama dan path route di aplikasi EduEarth.
///
/// Jangan menggunakan string path mentah di luar file ini.
class RouteNames {
  const RouteNames._();

  // Route sebelum masuk shell utama
  static const String splashName = 'splash';
  static const String splashPath = '/splash';

  static const String onboardingName = 'onboarding';
  static const String onboardingPath = '/onboarding';

  static const String loginName = 'login';
  static const String loginPath = '/login';

  static const String registerName = 'register';
  static const String registerPath = '/register';

  // 5 Tab Utama (StatefulShellRoute)
  static const String homeName = 'home';
  static const String homePath = '/home';

  static const String exploreMapName = 'explore-map';
  static const String exploreMapPath = '/explore';

  static const String learningName = 'learning';
  static const String learningPath = '/learning';

  static const String quizName = 'quiz';
  static const String quizPath = '/quiz';

  static const String profileName = 'profile';
  static const String profilePath = '/profile';

  // Route detail / utilitas di atas shell
  static const String designShowcaseName = 'design-showcase';
  static const String designShowcasePath = '/design-showcase';

  static const String plantDetailName = 'plant-detail';
  static const String plantDetailPath = '/plants/:id';

  static const String nearbyPlantsName = 'nearby-plants';
  static const String nearbyPlantsPath = '/nearby-plants';

  static const String energyCategoryName = 'energy-category';
  static const String energyCategoryPath = '/learning/category/:slug';

  static const String learningDetailName = 'learning-detail';
  static const String learningDetailPath = '/learning/material/:slug';

  static const String bookmarksName = 'bookmarks';
  static const String bookmarksPath = '/bookmarks';

  static const String quizGameplayName = 'quiz-gameplay';
  static const String quizGameplayPath = '/quiz/:id/play';

  static const String quizResultName = 'quiz-result';
  static const String quizResultPath = '/quiz/:id/result';

  static const String myLearningName = 'my-learning';
  static const String myLearningPath = '/my-learning';

  static const String settingsName = 'settings';
  static const String settingsPath = '/settings';

  static const String aboutName = 'about';
  static const String aboutPath = '/about';

  static const String searchName = 'search';
  static const String searchPath = '/search';

  static const String achievementsName = 'achievements';
  static const String achievementsPath = '/achievements';

  static const String notificationsName = 'notifications';
  static const String notificationsPath = '/notifications';

  static const String energyComparisonName = 'energy-comparison';
  static const String energyComparisonPath = '/energy-comparison';
}

