import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:math';

class AppleSignInService {
  static String generateNonce([int length = 32]) {
    const charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
  }

  static String sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  static Future<Map<String, dynamic>?> signInWithApple() async {
    try {
      final rawNonce = generateNonce();
      final nonce = sha256ofString(rawNonce);

      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      if (appleCredential.identityToken == null) {
        throw FirebaseAuthException(
          code: 'ERROR_INVALID_ID_TOKEN',
          message: 'Invalid ID token from Apple.',
        );
      }

      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        rawNonce: rawNonce,
        accessToken: appleCredential.authorizationCode,
      );
      //       final appleCredential = await SignInWithApple.getAppleIDCredential(
//         scopes: [
//           AppleIDAuthorizationScopes.email,
//           AppleIDAuthorizationScopes.fullName,
//         ],
//         nonce: nonce,
//       );
//
// // Create an `OAuthCredential` from the credential returned by Apple.
//       final oauthCredential = OAuthProvider("apple.com").credential(
//           idToken: appleCredential.identityToken,
//           rawNonce: rawNonce,
//           accessToken: appleCredential.authorizationCode, <-- ADD THIS LINE
//       );
      final userCredential = await FirebaseAuth.instance.signInWithCredential(oauthCredential);
      final user = userCredential.user;

      if (user != null) {
        // Construct displayName from Apple credential if user.displayName is null
        final displayName = user.displayName ??
            '${appleCredential.givenName ?? ''} ${appleCredential.familyName ?? ''}'.trim();

        return {
          'uid': user.uid,
          'email': user.email ?? appleCredential.email ?? '',
          'displayName': displayName.isEmpty ? 'Apple User' : displayName,
          'photoURL': user.photoURL,
          'identityToken': appleCredential.identityToken,
          // authorizationCode = closest thing to accessToken Apple gives on mobile
          // Send this to YOUR backend to exchange for access_token + refresh_token
          'authorizationCode': appleCredential.authorizationCode,
          // Stable user ID from Apple (never changes even if email changes)
          'userIdentifier': appleCredential.userIdentifier,
        };
      }
      return null;
    } catch (e) {
      print("Apple Sign-In error: $e");

      rethrow; // Let controller handle the error
    }
  }
}