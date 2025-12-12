class AppUtils{
  void logError(String message) {
    print('\x1B[31m[ERROR]: $message\x1B[0m'); // Red
  }

  void logSuccess(String message) {
    print('\x1B[32m[SUCCESS]: $message\x1B[0m'); // Green
  }

  void logInfo(String message) {
    print('\x1B[34m[INFO]: $message\x1B[0m'); // Blue
  }

}