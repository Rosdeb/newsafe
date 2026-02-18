// import 'dart:convert';
// import 'dart:io';
//
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:http/http.dart' as http;
// import 'package:hive/hive.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:saferader/utils/api_service.dart';
// import 'package:saferader/utils/app_constant.dart';
// import 'package:saferader/utils/logger.dart';
// import 'package:saferader/utils/token_service.dart';
// import '../../utils/app_color.dart';
// import '../../utils/auth_service.dart';
//
// class ProfileEditController extends GetxController {
//
//   RxString selectedGender = "Male".obs;
//   List<String> genderList = ["Male", "Female", "Other"];
//   RxInt selectedIndex = 0.obs;
//
//   TextEditingController nameController = TextEditingController();
//   TextEditingController lastnameController = TextEditingController();
//   TextEditingController emailController = TextEditingController();
//   TextEditingController phoneController = TextEditingController();
//   TextEditingController password = TextEditingController();
//
//   RxString userName = ''.obs;
//   RxString userEmail = ''.obs;
//   RxString userPhone = ''.obs;
//   RxString dateOfBirth = ''.obs;
//   RxString userId = ''.obs;
//   RxString userRole = ''.obs;
//   Rx<File?> selectedProfileImage = Rx<File?>(null);
//   RxBool isPasswordVisible = false.obs;
//   RxBool isLoading = false.obs;
//   RxBool save = false.obs;
//   late PageController pageController;
//
//   @override
//   void onInit() {
//     super.onInit();
//     pageController = PageController(viewportFraction: 0.4);
//     pageController.addListener(() {
//       if (pageController.page != null) {
//         int newIndex = pageController.page!.round();
//         if (selectedIndex.value != newIndex) {
//           selectedIndex.value = newIndex;
//           selectedGender.value = genderList[newIndex];
//         }
//       }
//     });
//     password.text = '********';
//     loadUserData();
//   }
//
//   Future<void> loadUserData() async {
//     try {
//       isLoading.value = true;
//
//       final userBox = await Hive.openBox('userProfileBox');
//       final name = userBox.get('name');
//       final email = userBox.get('email');
//       final phone = userBox.get('phone');
//       final dob = userBox.get('dateOfBirth');
//       final id = userBox.get('_id');
//       final role = userBox.get('role');
//
//       Logger.log("Raw Hive Data - name: $name, email: $email, phone: $phone, dob: $dob", type: "info");
//       userName.value = name ?? '';
//       userEmail.value = email ?? '';
//       userPhone.value = phone ?? '';
//       userId.value = id ?? '';
//       userRole.value = role ?? '';
//       if (name != null && name.toString().isNotEmpty) {
//         final nameParts = name.toString().split(' ');
//         if (nameParts.isNotEmpty) {
//           nameController.text = nameParts[0];
//           if (nameParts.length > 1) {
//             lastnameController.text = nameParts.sublist(1).join(' ');
//           }
//         }
//       }
//
//
//       if (email != null && email.toString().isNotEmpty) {
//         emailController.text = email.toString();
//       }
//
//       if (phone != null && phone.toString().isNotEmpty) {
//         phoneController.text = phone.toString();
//         userPhone.value = phone.toString();
//       } else {
//
//         phoneController.text = '';
//         userPhone.value = 'Not provided';
//       }
//
//
//       if (dob != null && dob.toString().isNotEmpty) {
//         dateOfBirth.value = formatDate(dob.toString());
//       } else {
//
//         dateOfBirth.value = 'Not provided';
//       }
//
//       Logger.log("User data loaded - Name: ${userName.value}, Email: ${userEmail.value}, Phone: ${userPhone.value}, DOB: ${dateOfBirth.value}", type: "info");
//
//     } catch (e) {
//       Logger.log("Error loading user data: $e", type: "error");
//
//
//       userName.value = 'Error loading';
//       userEmail.value = 'Error loading';
//       userPhone.value = 'Not available';
//       dateOfBirth.value = 'Not available';
//
//     } finally {
//       isLoading.value = false;
//     }
//   }
//
//   String formatDate(String date) {
//     try {
//       final DateTime parsedDate = DateTime.parse(date);
//       return "${parsedDate.day.toString().padLeft(2, '0')}/${parsedDate.month.toString().padLeft(2, '0')}/${parsedDate.year}";
//     } catch (e) {
//       Logger.log("Error formatting date: $e", type: "error");
//       return date;
//     }
//   }
//
//   void togglePasswordVisibility() {
//     isPasswordVisible.value = !isPasswordVisible.value;
//   }
//
//   void onGenderPageChanged(int index) {
//     selectedIndex.value = index;
//     selectedGender.value = genderList[index];
//   }
//
//   Future<void> refreshUserData() async {
//     await loadUserData();
//   }
//
//   Future<void> selectDateOfBirth(BuildContext context) async {
//     DateTime initialDate = DateTime.now().subtract(const Duration(days: 365 * 25));
//
//     if (dateOfBirth.value.isNotEmpty && dateOfBirth.value != 'Not provided') {
//       try {
//         final parts = dateOfBirth.value.split('/');
//         if (parts.length == 3) {
//           initialDate = DateTime(
//             int.parse(parts[2]),
//             int.parse(parts[1]),
//             int.parse(parts[0]),
//           );
//         }
//       } catch (e) {
//         Logger.log("⚠️ Error parsing existing date: $e", type: "warning");
//       }
//     }
//
//     final DateTime? picked = await showDatePicker(
//       context: context,
//       initialDate: initialDate,
//       firstDate: DateTime(1900),
//       lastDate: DateTime.now(),
//       builder: (context, child) {
//         return Theme(
//           data: Theme.of(context).copyWith(
//             colorScheme: const ColorScheme.light(
//               primary: AppColors.colorYellow,
//               onPrimary: Colors.black,
//               onSurface: AppColors.color2Box,
//             ),
//             textButtonTheme: TextButtonThemeData(
//               style: TextButton.styleFrom(
//                 foregroundColor: AppColors.colorYellow,
//               ),
//             ),
//           ),
//           child: child!,
//         );
//       },
//     );
//
//     if (picked != null) {
//
//       final formattedDate = "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
//       dateOfBirth.value = formattedDate;
//
//       try {
//         final userBox = await Hive.openBox('userProfileBox');
//         await userBox.put('dateOfBirth', picked.toIso8601String());
//
//         Logger.log("✅ Date of birth updated: $formattedDate", type: "info");
//
//       } catch (e) {
//         Logger.log("Error saving date: $e", type: "error");
//       }
//     }
//   }
//
//   Future<void> pickProfileImage() async {
//     try {
//       final ImagePicker picker = ImagePicker();
//       final XFile? image = await picker.pickImage(
//         source: ImageSource.gallery,
//         imageQuality: 60,
//       );
//
//       if (image != null) {
//         selectedProfileImage.value = File(image.path);
//         Logger.log("✅ Image selected: ${image.path}", type: "info");
//       }
//     } catch (e) {
//       Logger.log("Error picking image: $e", type: "error");
//     }
//   }
//
//   Future<void> updateProfileHttp(BuildContext context, {
//     File? profileImage,
//   }) async {
//     save.value = true;
//     try {
//       final result = await _attemptProfileUpdate(profileImage);
//       if (result['success']) {
//         await _handleSuccessfulUpdate(context, result['data']);
//       } else {
//         final message = result['message'] ?? 'Unknown error occurred';
//         Logger.log("⚠️ Profile update failed: $message", type: "warning");
//       }
//     } on Exception catch (e, st) {
//       Logger.log("❌ Error updating profile: $e\n$st", type: "error");
//     } finally {
//       save.value = false;
//     }
//   }
//
//   Future<Map<String, dynamic>> _attemptProfileUpdate(File? profileImage) async {
//     try {
//       final uri = Uri.parse("${AppConstants.BASE_URL}/api/users/me");
//       final request = http.MultipartRequest('PUT', uri);
//
//       final fullName = '${nameController.text.trim()} ${lastnameController.text.trim()}'.trim();
//       if (fullName.isNotEmpty) request.fields['name'] = fullName;
//       request.fields['phone'] = phoneController.text.trim();
//       request.fields['gender'] = selectedGender.value;
//
//       if (dateOfBirth.value.isNotEmpty && dateOfBirth.value != 'Not provided') {
//         final parts = dateOfBirth.value.split('/');
//         if (parts.length == 3) {
//           final isoDate = "${parts[2]}-${parts[1]}-${parts[0]}";
//           request.fields['dateOfBirth'] = isoDate;
//         }
//       }
//
//       // Add profile image if available
//       if (profileImage != null && await profileImage.exists()) {
//         final file = await http.MultipartFile.fromPath('profileImage', profileImage.path);
//         request.files.add(file);
//       }
//
//       // Use ApiService multipart which handles token refresh automatically
//       final streamedResp = await ApiService.multipart('/api/users/me', request);
//       final respString = await streamedResp.stream.bytesToString();
//
//       // Parse response
//       Map<String, dynamic> parsed;
//       try {
//         parsed = json.decode(respString) as Map<String, dynamic>;
//       } on Exception catch (e) {
//         Logger.log("Failed to parse response JSON: $e — raw: $respString", type: "error");
//         return {
//           'success': false,
//           'message': 'Invalid server response',
//         };
//       }
//
//       return {
//         'success': streamedResp.statusCode == 200,
//         'statusCode': streamedResp.statusCode,
//         'data': parsed['data'] ?? parsed,
//         'message': parsed['message'] ?? parsed['error'] ?? 'Unknown error',
//       };
//     } on Exception catch (e) {
//       Logger.log("❌ Exception in _attemptProfileUpdate: $e", type: "error");
//       return {
//         'success': false,
//         'message': 'Network error: ${e.toString()}',
//       };
//     }
//   }
//
//
//   Future<void> _handleSuccessfulUpdate(BuildContext context, Map<String, dynamic> user) async {
//     Logger.log("✅ Profile updated successfully!", type: "info");
//
//     // Save to Hive
//     final userBox = await Hive.openBox('userProfileBox');
//     await userBox.put('name', user['name'] ?? '');
//     await userBox.put('email', user['email'] ?? '');
//     await userBox.put('_id', user['_id'] ?? user['id'] ?? '');
//     await userBox.put('role', user['role'] ?? '');
//     await userBox.put('phone', user['phone'] ?? '');
//     await userBox.put('dateOfBirth', user['dateOfBirth'] ?? '');
//     await userBox.put('profileImage', user['profileImage'] ?? user['image'] ?? '');
//     await userBox.put('gender', user['gender'] ?? '');
//
//     Logger.log("✅ Hive data updated successfully", type: "info");
//
//     await loadUserData();
//
//     if (context.mounted) {
//       Navigator.pop(context);
//     }
//   }
//
//
//
//   @override
//   void onClose() {
//     nameController.dispose();
//     lastnameController.dispose();
//     emailController.dispose();
//     phoneController.dispose();
//     password.dispose();
//     pageController.dispose();
//     super.onClose();
//   }
// }

// import 'dart:convert';
// import 'dart:io';
//
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:http/http.dart' as http;
// import 'package:hive/hive.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:saferader/utils/api_service.dart';
// import 'package:saferader/utils/app_constant.dart';
// import 'package:saferader/utils/logger.dart';
// import 'package:saferader/utils/token_service.dart';
// import '../../utils/app_color.dart';
// import '../../utils/auth_service.dart';
// import '../profile/profile.dart'; // Import ProfileController
//
// class ProfileEditController extends GetxController {
//
//   RxString selectedGender = "Male".obs;
//   List<String> genderList = ["Male", "Female", "Other"];
//   RxInt selectedIndex = 0.obs;
//
//   TextEditingController nameController = TextEditingController();
//   TextEditingController lastnameController = TextEditingController();
//   TextEditingController emailController = TextEditingController();
//   TextEditingController phoneController = TextEditingController();
//   TextEditingController password = TextEditingController();
//
//   RxString userName = ''.obs;
//   RxString userEmail = ''.obs;
//   RxString userPhone = ''.obs;
//   RxString dateOfBirth = ''.obs;
//   RxString userId = ''.obs;
//   RxString userRole = ''.obs;
//   RxString userGender = ''.obs;
//   Rx<File?> selectedProfileImage = Rx<File?>(null);
//   RxString profileImageUrl = ''.obs;
//   RxBool isPasswordVisible = false.obs;
//   RxBool isLoading = false.obs;
//   RxBool save = false.obs;
//   late PageController pageController;
//
//   @override
//   void onInit() {
//     super.onInit();
//     pageController = PageController(viewportFraction: 0.4);
//     pageController.addListener(() {
//       if (pageController.page != null) {
//         int newIndex = pageController.page!.round();
//         if (selectedIndex.value != newIndex) {
//           selectedIndex.value = newIndex;
//           selectedGender.value = genderList[newIndex];
//         }
//       }
//     });
//     password.text = '********';
//     loadUserData();
//   }
//
//   Future<void> loadUserData() async {
//     try {
//       isLoading.value = true;
//
//       final userBox = await Hive.openBox('userProfileBox');
//       final name = userBox.get('name');
//       final email = userBox.get('email');
//       final phone = userBox.get('phone');
//       final dob = userBox.get('dateOfBirth');
//       final id = userBox.get('_id');
//       final role = userBox.get('role');
//       final gender = userBox.get('gender');
//       final image = userBox.get('profileImage');
//
//       Logger.log("Raw Hive Data - name: $name, email: $email, phone: $phone, dob: $dob, gender: $gender", type: "info");
//
//       userName.value = name ?? '';
//       userEmail.value = email ?? '';
//       userPhone.value = phone ?? '';
//       userId.value = id ?? '';
//       userRole.value = role ?? '';
//       userGender.value = gender ?? '';
//       profileImageUrl.value = image ?? '';
//
//       // Split name into first and last name
//       if (name != null && name.toString().isNotEmpty) {
//         final nameParts = name.toString().split(' ');
//         if (nameParts.isNotEmpty) {
//           nameController.text = nameParts[0];
//           if (nameParts.length > 1) {
//             lastnameController.text = nameParts.sublist(1).join(' ');
//           }
//         }
//       }
//
//       if (email != null && email.toString().isNotEmpty) {
//         emailController.text = email.toString();
//       }
//
//       if (phone != null && phone.toString().isNotEmpty) {
//         phoneController.text = phone.toString();
//         userPhone.value = phone.toString();
//       } else {
//         phoneController.text = '';
//         userPhone.value = 'Not provided';
//       }
//
//       if (dob != null && dob.toString().isNotEmpty) {
//         dateOfBirth.value = formatDate(dob.toString());
//       } else {
//         dateOfBirth.value = 'Not provided';
//       }
//
//       // Set gender index for PageController
//       if (gender != null && gender.toString().isNotEmpty) {
//         final genderIndex = genderList.indexWhere(
//                 (g) => g.toLowerCase() == gender.toString().toLowerCase()
//         );
//         if (genderIndex != -1) {
//           selectedIndex.value = genderIndex;
//           selectedGender.value = genderList[genderIndex];
//           // Update PageController position
//           WidgetsBinding.instance.addPostFrameCallback((_) {
//             if (pageController.hasClients) {
//               pageController.jumpToPage(genderIndex);
//             }
//           });
//         }
//       }
//
//       Logger.log("User data loaded - Name: ${userName.value}, Email: ${userEmail.value}, Phone: ${userPhone.value}, DOB: ${dateOfBirth.value}, Gender: ${userGender.value}", type: "info");
//
//     } catch (e) {
//       Logger.log("Error loading user data: $e", type: "error");
//
//       userName.value = 'Error loading';
//       userEmail.value = 'Error loading';
//       userPhone.value = 'Not available';
//       dateOfBirth.value = 'Not available';
//
//     } finally {
//       isLoading.value = false;
//     }
//   }
//
//   String formatDate(String date) {
//     try {
//       final DateTime parsedDate = DateTime.parse(date);
//       return "${parsedDate.day.toString().padLeft(2, '0')}/${parsedDate.month.toString().padLeft(2, '0')}/${parsedDate.year}";
//     } catch (e) {
//       Logger.log("Error formatting date: $e", type: "error");
//       return date;
//     }
//   }
//
//   void togglePasswordVisibility() {
//     isPasswordVisible.value = !isPasswordVisible.value;
//   }
//
//   void onGenderPageChanged(int index) {
//     selectedIndex.value = index;
//     selectedGender.value = genderList[index];
//   }
//
//   Future<void> refreshUserData() async {
//     await loadUserData();
//   }
//
//   Future<void> selectDateOfBirth(BuildContext context) async {
//     DateTime initialDate = DateTime.now().subtract(const Duration(days: 365 * 25));
//
//     if (dateOfBirth.value.isNotEmpty && dateOfBirth.value != 'Not provided') {
//       try {
//         final parts = dateOfBirth.value.split('/');
//         if (parts.length == 3) {
//           initialDate = DateTime(
//             int.parse(parts[2]),
//             int.parse(parts[1]),
//             int.parse(parts[0]),
//           );
//         }
//       } catch (e) {
//         Logger.log("⚠️ Error parsing existing date: $e", type: "warning");
//       }
//     }
//
//     final DateTime? picked = await showDatePicker(
//       context: context,
//       initialDate: initialDate,
//       firstDate: DateTime(1900),
//       lastDate: DateTime.now(),
//       builder: (context, child) {
//         return Theme(
//           data: Theme.of(context).copyWith(
//             colorScheme: const ColorScheme.light(
//               primary: AppColors.colorYellow,
//               onPrimary: Colors.black,
//               onSurface: AppColors.color2Box,
//             ),
//             textButtonTheme: TextButtonThemeData(
//               style: TextButton.styleFrom(
//                 foregroundColor: AppColors.colorYellow,
//               ),
//             ),
//           ),
//           child: child!,
//         );
//       },
//     );
//
//     if (picked != null) {
//       final formattedDate = "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
//       dateOfBirth.value = formattedDate;
//
//       try {
//         final userBox = await Hive.openBox('userProfileBox');
//         await userBox.put('dateOfBirth', picked.toIso8601String());
//
//         Logger.log("✅ Date of birth updated: $formattedDate", type: "info");
//
//       } catch (e) {
//         Logger.log("Error saving date: $e", type: "error");
//       }
//     }
//   }
//
//   Future<void> pickProfileImage() async {
//     try {
//       final ImagePicker picker = ImagePicker();
//       final XFile? image = await picker.pickImage(
//         source: ImageSource.gallery,
//         imageQuality: 60,
//       );
//
//       if (image != null) {
//         selectedProfileImage.value = File(image.path);
//         Logger.log("✅ Image selected: ${image.path}", type: "info");
//       }
//     } catch (e) {
//       Logger.log("Error picking image: $e", type: "error");
//     }
//   }
//
//   Future<void> updateProfileHttp(BuildContext context, {
//     File? profileImage,
//   }) async {
//     save.value = true;
//     try {
//       final result = await _attemptProfileUpdate(profileImage);
//       if (result['success']) {
//         await _handleSuccessfulUpdate(context, result['data']);
//       } else {
//         final message = result['message'] ?? 'Unknown error occurred';
//         Logger.log("⚠️ Profile update failed: $message", type: "warning");
//
//         if (context.mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Text(message),
//               backgroundColor: Colors.red,
//               duration: const Duration(seconds: 3),
//             ),
//           );
//         }
//       }
//     } on Exception catch (e, st) {
//       Logger.log("❌ Error updating profile: $e\n$st", type: "error");
//
//       if (context.mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('Failed to update profile. Please try again.'),
//             backgroundColor: Colors.red,
//             duration: Duration(seconds: 3),
//           ),
//         );
//       }
//     } finally {
//       save.value = false;
//     }
//   }
//
//   Future<Map<String, dynamic>> _attemptProfileUpdate(File? profileImage) async {
//     try {
//       final uri = Uri.parse("${AppConstants.BASE_URL}/api/users/me");
//       final request = http.MultipartRequest('PUT', uri);
//
//       final fullName = '${nameController.text.trim()} ${lastnameController.text.trim()}'.trim();
//       if (fullName.isNotEmpty) request.fields['name'] = fullName;
//       request.fields['phone'] = phoneController.text.trim();
//       request.fields['gender'] = selectedGender.value;
//
//       if (dateOfBirth.value.isNotEmpty && dateOfBirth.value != 'Not provided') {
//         final parts = dateOfBirth.value.split('/');
//         if (parts.length == 3) {
//           final isoDate = "${parts[2]}-${parts[1]}-${parts[0]}";
//           request.fields['dateOfBirth'] = isoDate;
//         }
//       }
//
//       // Add profile image if available
//       if (profileImage != null && await profileImage.exists()) {
//         final file = await http.MultipartFile.fromPath('profileImage', profileImage.path);
//         request.files.add(file);
//       }
//
//       // Use ApiService multipart which handles token refresh automatically
//       final streamedResp = await ApiService.multipart('/api/users/me', request);
//       final respString = await streamedResp.stream.bytesToString();
//
//       Logger.log("📥 Profile Update Response - Status: ${streamedResp.statusCode}", type: "info");
//       Logger.log("📥 Profile Update Response - Body: $respString", type: "info");
//
//       // Parse response
//       Map<String, dynamic> parsed;
//       try {
//         parsed = json.decode(respString) as Map<String, dynamic>;
//       } on Exception catch (e) {
//         Logger.log("Failed to parse response JSON: $e — raw: $respString", type: "error");
//         return {
//           'success': false,
//           'message': 'Invalid server response',
//         };
//       }
//
//       return {
//         'success': streamedResp.statusCode == 200,
//         'statusCode': streamedResp.statusCode,
//         'data': parsed['data'] ?? parsed,
//         'message': parsed['message'] ?? parsed['error'] ?? 'Unknown error',
//       };
//     } on Exception catch (e) {
//       Logger.log("❌ Exception in _attemptProfileUpdate: $e", type: "error");
//       return {
//         'success': false,
//         'message': 'Network error: ${e.toString()}',
//       };
//     }
//   }
//
//   Future<void> _handleSuccessfulUpdate(BuildContext context, Map<String, dynamic> user) async {
//     Logger.log("✅ Profile updated successfully!", type: "info");
//
//     // Save to Hive
//     final userBox = await Hive.openBox('userProfileBox');
//     await userBox.put('name', user['name'] ?? '');
//     await userBox.put('email', user['email'] ?? '');
//     await userBox.put('_id', user['_id'] ?? user['id'] ?? '');
//     await userBox.put('role', user['role'] ?? '');
//     await userBox.put('phone', user['phone'] ?? '');
//     await userBox.put('dateOfBirth', user['dateOfBirth'] ?? '');
//     await userBox.put('profileImage', user['profileImage'] ?? user['image'] ?? '');
//     await userBox.put('gender', user['gender'] ?? '');
//
//     Logger.log("✅ Hive data updated successfully", type: "info");
//
//     // Reload local data
//     await loadUserData();
//
//     // ✅ CRITICAL: Refresh ProfileController with fresh API data
//     try {
//       if (Get.isRegistered<ProfileController>()) {
//         final profileController = Get.find<ProfileController>();
//         Logger.log("🔄 Refreshing ProfileController from API...", type: "info");
//         profileController.loadUserData();
//         await profileController.fetchUserProfile();
//         Logger.log("✅ ProfileController refreshed successfully", type: "success");
//       } else {
//         Logger.log("⚠️ ProfileController not registered, skipping refresh", type: "warning");
//       }
//     } catch (e) {
//       Logger.log("⚠️ Error refreshing ProfileController: $e", type: "warning");
//     }
//
//     if (context.mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Profile updated successfully!'),
//           backgroundColor: Colors.green,
//           duration: Duration(seconds: 2),
//         ),
//       );
//       Navigator.pop(context);
//     }
//   }
//
//   @override
//   void onClose() {
//     nameController.dispose();
//     lastnameController.dispose();
//     emailController.dispose();
//     phoneController.dispose();
//     password.dispose();
//     pageController.dispose();
//     super.onClose();
//   }
// }

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:hive/hive.dart';
import 'package:http/http.dart';
import 'package:image_picker/image_picker.dart';
import 'package:saferader/utils/api_service.dart';
import 'package:saferader/utils/app_constant.dart';
import 'package:saferader/utils/logger.dart';
import '../../utils/app_color.dart';
import '../profile/profile.dart';

class ProfileEditController extends GetxController {
  RxString selectedGender = "Male".obs;
  List<String> genderList = ["Male", "Female", "Other"];
  RxInt selectedIndex = 0.obs;

  TextEditingController nameController = TextEditingController();
  TextEditingController lastnameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController password = TextEditingController();

  RxString userName = ''.obs;
  RxString userEmail = ''.obs;
  RxString userPhone = ''.obs;
  RxString dateOfBirth = ''.obs;
  RxString userId = ''.obs;
  RxString userRole = ''.obs;
  RxString userGender = ''.obs;
  Rx<File?> selectedProfileImage = Rx<File?>(null);
  RxString profileImageUrl = ''.obs;
  RxBool isPasswordVisible = false.obs;
  RxBool isLoading = false.obs;
  RxBool save = false.obs;
  late PageController pageController;

  @override
  void onInit() {
    super.onInit();
    pageController = PageController(viewportFraction: 0.4);
    pageController.addListener(() {
      if (pageController.page != null) {
        int newIndex = pageController.page!.round();
        if (selectedIndex.value != newIndex) {
          selectedIndex.value = newIndex;
          selectedGender.value = genderList[newIndex];
        }
      }
    });
    password.text = '********';
    loadUserData();
  }

  Future<void> loadUserData() async {
    try {
      isLoading.value = true;
      final userBox = await Hive.openBox('userProfileBox');
      final name = userBox.get('name');
      final email = userBox.get('email');
      final phone = userBox.get('phone');
      final dob = userBox.get('dateOfBirth');
      final id = userBox.get('_id');
      final role = userBox.get('role');
      final gender = userBox.get('gender');
      final image = userBox.get('profileImage');

      Logger.log("Raw Hive Data - name: $name, email: $email, phone: $phone, dob: $dob, gender: $gender, image: $image", type: "info",);

      userName.value = name ?? '';
      userEmail.value = email ?? '';
      userPhone.value = phone ?? '';
      userId.value = id ?? '';
      userRole.value = role ?? '';
      userGender.value = gender ?? '';
      profileImageUrl.value = image ?? '';

      if (name != null && name.toString().isNotEmpty) {
        final nameParts = name.toString().split(' ');
        if (nameParts.isNotEmpty) {
          nameController.text = nameParts[0];
          if (nameParts.length > 1) {
            lastnameController.text = nameParts.sublist(1).join(' ');
          }
        }
      }

      if (email != null && email.toString().isNotEmpty) {
        emailController.text = email.toString();
      }

      if (phone != null && phone.toString().isNotEmpty) {
        phoneController.text = phone.toString();
        userPhone.value = phone.toString();
      } else {
        phoneController.text = '';
        userPhone.value = 'Not provided';
      }

      if (dob != null && dob.toString().isNotEmpty) {
        dateOfBirth.value = formatDate(dob.toString());
      } else {
        dateOfBirth.value = 'Not provided';
      }


      if (gender != null && gender.toString().isNotEmpty) {
        final genderIndex = genderList.indexWhere(
          (g) => g.toLowerCase() == gender.toString().toLowerCase(),
        );
        if (genderIndex != -1) {
          selectedIndex.value = genderIndex;
          selectedGender.value = genderList[genderIndex];
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (pageController.hasClients) {
              pageController.jumpToPage(genderIndex);
            }
          });
        }
      }

      Logger.log("User data loaded successfully", type: "info");
    } catch (e) {
      Logger.log("Error loading user data: $e", type: "error");
      userName.value = 'Error loading';
      userEmail.value = 'Error loading';
      userPhone.value = 'Not available';
      dateOfBirth.value = 'Not available';
    } finally {
      isLoading.value = false;
    }
  }

  String formatDate(String date) {
    try {
      final DateTime parsedDate = DateTime.parse(date);
      return "${parsedDate.day.toString().padLeft(2, '0')}/${parsedDate.month.toString().padLeft(2, '0')}/${parsedDate.year}";
    } catch (e) {
      Logger.log("Error formatting date: $e", type: "error");
      return date;
    }
  }

  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  void onGenderPageChanged(int index) {
    selectedIndex.value = index;
    selectedGender.value = genderList[index];
  }

  Future<void> refreshUserData() async {
    await loadUserData();
  }

  Future<void> selectDateOfBirth(BuildContext context) async {
    DateTime initialDate = DateTime.now().subtract(
      const Duration(days: 365 * 25),
    );

    if (dateOfBirth.value.isNotEmpty && dateOfBirth.value != 'Not provided') {
      try {
        final parts = dateOfBirth.value.split('/');
        if (parts.length == 3) {
          initialDate = DateTime(
            int.parse(parts[2]),
            int.parse(parts[1]),
            int.parse(parts[0]),
          );
        }
      } catch (e) {
        Logger.log("⚠️ Error parsing existing date: $e", type: "warning");
      }
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.colorYellow,
              onPrimary: Colors.black,
              onSurface: AppColors.color2Box,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.colorYellow,
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final formattedDate =
          "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
      dateOfBirth.value = formattedDate;
    }
  }

  Future<void> pickProfileImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 60,
      );

      if (image != null) {
        selectedProfileImage.value = File(image.path);
        Logger.log("Image selected: ${image.path}", type: "info");
      }
    } catch (e) {
      Logger.log("Error picking image: $e", type: "error");
    }
  }

  Future<void> updateProfileHttp(
    BuildContext context, {
    File? profileImage,
  }) async {
    save.value = true;
    try {
      final result = await _attemptProfileUpdate(profileImage);
      if (result['success']) {
        await _handleSuccessfulUpdate(context, result['data']);
      } else {
        final message = result['message'] ?? 'Unknown error occurred';
        Logger.log("Profile update failed: $message", type: "warning");

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } on Exception catch (e, st) {
      Logger.log("Error updating profile: $e\n$st", type: "error");

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update profile. Please try again.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } finally {
      save.value = false;
    }
  }

  Future<Map<String, dynamic>> _attemptProfileUpdate(File? profileImage) async {
    try {
      final uri = Uri.parse("${AppConstants.BASE_URL}/api/users/me");
      final request = http.MultipartRequest('PUT', uri);

      final fullName =
          '${nameController.text.trim()} ${lastnameController.text.trim()}'
              .trim();
      if (fullName.isNotEmpty) request.fields['name'] = fullName;
      request.fields['phone'] = phoneController.text.trim();
      request.fields['gender'] = selectedGender.value;

      if (dateOfBirth.value.isNotEmpty && dateOfBirth.value != 'Not provided') {
        final parts = dateOfBirth.value.split('/');
        if (parts.length == 3) {
          final isoDate = "${parts[2]}-${parts[1]}-${parts[0]}";
          request.fields['dateOfBirth'] = isoDate;
        }
      }

      // Add profile image if available
      if (profileImage != null && await profileImage.exists()) {
        final file = await http.MultipartFile.fromPath(
          'profileImage',
          profileImage.path,
          contentType: MediaType('image', 'jpeg'),
        );
        request.files.add(file);
      }

      final streamedResp = await ApiService.multipart('/api/users/me', request);
      final respString = await streamedResp.stream.bytesToString();

      Logger.log("Profile Update Response - Status: ${streamedResp.statusCode}", type: "info",);
      Logger.log("Profile Update Response - Body: $respString", type: "info",);


      Map<String, dynamic> parsed;
      try {
        parsed = json.decode(respString) as Map<String, dynamic>;
      } on Exception catch (e) {
        Logger.log(
          "Failed to parse response JSON: $e — raw: $respString",
          type: "error",
        );
        return {'success': false, 'message': 'Invalid server response'};
      }

      return {
        'success': streamedResp.statusCode == 200,
        'statusCode': streamedResp.statusCode,
        'data': parsed['data'] ?? parsed,
        'message': parsed['message'] ?? parsed['error'] ?? 'Unknown error',
      };
    } on Exception catch (e) {
      Logger.log("Exception in _attemptProfileUpdate: $e", type: "error");
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  Future<void> _handleSuccessfulUpdate(
    BuildContext context,
    Map<String, dynamic> user,
  ) async {
    Logger.log("✅ Profile updated successfully!", type: "info");
    Logger.log("📦 User data received: $user", type: "info");

    try {
      final userBox = await Hive.openBox('userProfileBox');
      await userBox.put('name', user['name'] ?? '');
      await userBox.put('email', user['email'] ?? '');
      await userBox.put('_id', user['_id'] ?? user['id'] ?? '');
      await userBox.put('role', user['role'] ?? '');
      await userBox.put('phone', user['phone'] ?? '');
      await userBox.put('dateOfBirth', user['dateOfBirth'] ?? '');
      await userBox.put('gender', user['gender'] ?? '');

      String imageUrl = '';
      if (user['profileImage'] != null &&
          user['profileImage'].toString().isNotEmpty) {
        imageUrl = user['profileImage'].toString();
      } else if (user['image'] != null && user['image'].toString().isNotEmpty) {
        imageUrl = user['image'].toString();
      }

      if (imageUrl.isNotEmpty && !imageUrl.startsWith('http')) {
        imageUrl = '${AppConstants.BASE_URL}$imageUrl';
      }

      await userBox.put('profileImage', imageUrl);

      Logger.log("✅ Hive data updated successfully", type: "info");
      Logger.log("📦 Saved to Hive - Image URL: $imageUrl", type: "info");


      await loadUserData();

      if (Get.isRegistered<ProfileController>()) {
        final profileController = Get.find<ProfileController>();
        Logger.log("Forcing ProfileController refresh from API...", type: "info",);
        await profileController.refreshProfile();
        Logger.log("ProfileController refreshed successfully", type: "success",);

      } else {
        Logger.log("ProfileController not registered, skipping refresh", type: "warning",);
      }


      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // Pop back to profile screen
        Navigator.pop(context);
      }
    } catch (e) {
      Logger.log("Error in _handleSuccessfulUpdate: $e", type: "error");

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated but failed to save locally. Please restart the app.',),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  void onClose() {
    nameController.dispose();
    lastnameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    password.dispose();
    pageController.dispose();
    super.onClose();
  }
}
