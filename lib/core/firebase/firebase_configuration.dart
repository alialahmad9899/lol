final class FirebaseConfigurationMissing implements Exception {
  const FirebaseConfigurationMissing();

  @override
  String toString() {
    return 'Firebase is not configured. Run flutterfire configure first.';
  }
}
