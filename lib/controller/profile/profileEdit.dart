import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:hive/hive.dart';
import 'package:image_picker/image_picker.dart';
import 'package:saferader/utils/app_constant.dart';
import 'package:saferader/utils/logger.dart';
import 'package:saferader/utils/token_service.dart';
import '../../utils/app_color.dart';
import '../../utils/auth_service.dart';

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
  Rx<File?> selectedProfileImage = Rx<File?>(null);
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

      Logger.log("Raw Hive Data - name: $name, email: $email, phone: $phone, dob: $dob", type: "info");
      userName.value = name ?? '';
      userEmail.value = email ?? '';
      userPhone.value = phone ?? '';
      userId.value = id ?? '';
      userRole.value = role ?? '';
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

      Logger.log("User data loaded - Name: ${userName.value}, Email: ${userEmail.value}, Phone: ${userPhone.value}, DOB: ${dateOfBirth.value}", type: "info");

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
    DateTime initialDate = DateTime.now().subtract(const Duration(days: 365 * 25));

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

      final formattedDate = "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
      dateOfBirth.value = formattedDate;

      try {
        final userBox = await Hive.openBox('userProfileBox');
        await userBox.put('dateOfBirth', picked.toIso8601String());

        Logger.log("✅ Date of birth updated: $formattedDate", type: "info");

      } catch (e) {
        Logger.log("Error saving date: $e", type: "error");
      }
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
        Logger.log("✅ Image selected: ${image.path}", type: "info");
      }
    } catch (e) {
      Logger.log("Error picking image: $e", type: "error");
    }
  }

  Future<void> updateProfileHttp(BuildContext context, {
    File? profileImage,
  }) async {
    save.value = true;
    try {
      final result = await _attemptProfileUpdate(profileImage);
      if (result['success']) {
        await _handleSuccessfulUpdate(context, result['data']);
      } else if (result['statusCode'] == 401) {
        Logger.log("🔄 Token expired (401), refreshing token...", type: "info");
        final bool refreshSuccess = await AuthService.refreshToken();

        if (refreshSuccess) {
          Logger.log("✅ Token refreshed successfully, retrying request...", type: "info");
          final retryResult = await _attemptProfileUpdate(profileImage);
          if (retryResult['success']) {
            await _handleSuccessfulUpdate(context, retryResult['data']);
          } else {
            final message = retryResult['message'] ?? 'Failed to update profile after token refresh';
            Logger.log("❌ Retry failed: $message", type: "error");
          }
        } else {
          Logger.log("❌ Token refresh failed, redirecting to login...", type: "error");
        }
      } else {
        final message = result['message'] ?? 'Unknown error occurred';
        Logger.log("⚠️ Profile update failed: $message", type: "warning");
      }
    } on Exception catch (e, st) {
      Logger.log("❌ Error updating profile: $e\n$st", type: "error");
    } finally {
      save.value = false;
    }
  }

  Future<Map<String, dynamic>> _attemptProfileUpdate(File? profileImage) async {
    try {
      final token = await TokenService().getToken();
      if (token == null || token.isEmpty) {
        Logger.log("❌ No auth token available", type: "error");
        return {
          'success': false,
          'statusCode': 401,
          'message': 'No authentication token available',
        };
      }

      final uri = Uri.parse("${AppConstants.BASE_URL}/api/users/me");
      final request = http.MultipartRequest('PUT', uri);

      request.headers['Authorization'] = 'Bearer $token';


      final fullName = '${nameController.text.trim()} ${lastnameController.text.trim()}'.trim();
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
        final file = await http.MultipartFile.fromPath('profileImage', profileImage.path);
        request.files.add(file);
      }

      // Send request
      final streamedResp = await request.send();
      final respString = await streamedResp.stream.bytesToString();

      // Parse response
      Map<String, dynamic> parsed;
      try {
        parsed = json.decode(respString) as Map<String, dynamic>;
      } on Exception catch (e) {
        Logger.log("Failed to parse response JSON: $e — raw: $respString", type: "error");
        return {
          'success': false,
          'message': 'Invalid server response',
        };
      }

      return {
        'success': streamedResp.statusCode == 200,
        'statusCode': streamedResp.statusCode,
        'data': parsed['data'] ?? parsed,
        'message': parsed['message'] ?? parsed['error'] ?? 'Unknown error',
      };
    } on Exception catch (e) {
      Logger.log("❌ Exception in _attemptProfileUpdate: $e", type: "error");
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  /// Helper method to handle successful profile update
  Future<void> _handleSuccessfulUpdate(BuildContext context, Map<String, dynamic> user) async {
    Logger.log("✅ Profile updated successfully!", type: "info");

    // Save to Hive
    final userBox = await Hive.openBox('userProfileBox');
    await userBox.put('name', user['name'] ?? '');
    await userBox.put('email', user['email'] ?? '');
    await userBox.put('_id', user['_id'] ?? user['id'] ?? '');
    await userBox.put('role', user['role'] ?? '');
    await userBox.put('phone', user['phone'] ?? '');
    await userBox.put('dateOfBirth', user['dateOfBirth'] ?? '');
    await userBox.put('profileImage', user['profileImage'] ?? user['image'] ?? '');
    await userBox.put('gender', user['gender'] ?? '');

    Logger.log("✅ Hive data updated successfully", type: "info");

    await loadUserData();


    if (context.mounted) {
      Navigator.pop(context);
    }
  }


  // Future<void> updateProfileHttp(BuildContext context,{
  //   File? profileImage,
  // }) async {
  //   save.value = true;
  //   try {
  //     final token = TokenService().getToken();
  //     if (token == null || token.isEmpty) {
  //       Logger.log("❌ No auth token available", type: "error");
  //       return;
  //     }
  //
  //     final uri = Uri.parse("${AppConstants.BASE_URL}/api/users/me");
  //     final request = http.MultipartRequest('PUT', uri);
  //
  //     request.headers['Authorization'] = 'Bearer $token';
  //     final fullName = '${nameController.text.trim()} ${lastnameController.text.trim()}'.trim();
  //     if (fullName.isNotEmpty) request.fields['name'] = fullName;
  //     request.fields['phone'] = phoneController.text.trim();
  //     request.fields['gender'] = selectedGender.value;
  //
  //     if (dateOfBirth.value.isNotEmpty && dateOfBirth.value != 'Not provided') {
  //       final parts = dateOfBirth.value.split('/');
  //       if (parts.length == 3) {
  //         final isoDate = "${parts[2]}-${parts[1]}-${parts[0]}";
  //         request.fields['dateOfBirth'] = isoDate;
  //       }
  //     }
  //
  //     if (profileImage != null && await profileImage.exists()) {
  //       final file = await http.MultipartFile.fromPath('profileImage', profileImage.path);
  //       request.files.add(file);
  //     }
  //
  //
  //     final streamedResp = await request.send();
  //     final respString = await streamedResp.stream.bytesToString();
  //
  //
  //     Map<String, dynamic> parsed;
  //     try {
  //       parsed = json.decode(respString) as Map<String, dynamic>;
  //     }on Exception catch (e) {
  //       Logger.log("Failed to parse response JSON: $e — raw: $respString", type: "error");
  //       throw Exception("Invalid server response");
  //     }
  //
  //     if (streamedResp.statusCode == 200) {
  //       Logger.log("✅ Profile updated successfully!${parsed}", type: "info");
  //
  //       final user = parsed['data'] ?? parsed;
  //       print("image ${user['profileImage']}");
  //
  //       final userBox = await Hive.openBox('userProfileBox');
  //       await userBox.put('name', user['name'] ?? '');
  //       await userBox.put('email', user['email'] ?? '');
  //       await userBox.put('_id', user['_id'] ?? user['id'] ?? '');
  //       await userBox.put('role', user['role'] ?? '');
  //       await userBox.put('phone', user['phone'] ?? '');
  //       await userBox.put('dateOfBirth', user['dateOfBirth'] ?? '');
  //       // store under 'profileImage' key to be explicit
  //       await userBox.put('profileImage', user['profileImage'] ?? user['image'] ?? '');
  //       await userBox.put('gender', user['gender'] ?? '');
  //
  //       Logger.log("✅ Hive data updated successfully: ${user}", type: "info");
  //       if(context.mounted){
  //         Navigator.pop(context);
  //       }
  //       await loadUserData();
  //     }else if(streamedResp.statusCode==401){
  //       final bool success = await AuthService.refreshToken();
  //     } else {
  //       final message = parsed['message'] ?? parsed['error'] ?? 'Unknown error';
  //       Logger.log("⚠️ Failed to update profile. Status: ${streamedResp.statusCode}. Message: $message", type: "warning");
  //     }
  //   }on Exception catch (e, st) {
  //     Logger.log("Error updating profile: $e\n$st", type: "error");
  //   } finally {
  //     save.value = false;
  //   }
  // }





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