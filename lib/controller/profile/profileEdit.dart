import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:saferader/controller/SeakerHome/seakerHomeController.dart';
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

      Logger.log(
        "Raw Hive Data - name: $name, email: $email, phone: $phone, dob: $dob, gender: $gender, image: $image",
        type: "info",
      );

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
        imageQuality: 80,
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
      // Prepare fields for the multipart request
      final Map<String, String> fields = {};

      final fullName =
      '${nameController.text.trim()} ${lastnameController.text.trim()}'
          .trim();
      if (fullName.isNotEmpty) fields['name'] = fullName;
      fields['phone'] = phoneController.text.trim();
      fields['gender'] = selectedGender.value;

      if (dateOfBirth.value.isNotEmpty && dateOfBirth.value != 'Not provided') {
        final parts = dateOfBirth.value.split('/');
        if (parts.length == 3) {
          final isoDate = "${parts[2]}-${parts[1]}-${parts[0]}";
          fields['dateOfBirth'] = isoDate;
        }
      }

      // Prepare files for the multipart request
      List<http.MultipartFile> files = [];

      if (profileImage != null && await profileImage.exists()) {
        // Detect extension to set correct MIME type
        final ext = profileImage.path.split('.').last.toLowerCase();
        final mimeType = ext == 'png'
            ? 'image/png'
            : ext == 'gif'
            ? 'image/gif'
            : ext == 'webp'
            ? 'image/webp'
            : 'image/jpeg';

        final file = await http.MultipartFile.fromPath(
          'profileImage',
          profileImage.path,
          contentType: http.MediaType.parse(mimeType),
        );
        files.add(file);

        Logger.log("📎 Attaching profile image: ${profileImage.path} as $mimeType", type: "info",);
      } else {
        Logger.log("⚠️ No profile image to upload or file does not exist", type: "warning");
      }

      Logger.log("📤 Sending multipart request with fields: $fields", type: "info");
      Logger.log("📤 Files count: ${files.length}", type: "info");

      final apiService = ApiService();
      final response = await apiService.putWithMultipart(
        endpoint: '/api/users/me',
        fields: fields,
        files: files,
      );

      Logger.log("Profile Update Response - Status: ${response != null ? 'Success' : 'Failed'}", type: "info",);
      Logger.log("Profile Update Response - Body: $response", type: "info",);

      if (response == null) {
        return {'success': false, 'message': 'Failed to update profile'};
      }

      return {
        'success': true,
        'data': response['data'] ?? response,
        'message': response['message'] ?? 'Profile updated successfully',
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

      // ✅ FIXED: Robust image URL extraction and normalization
      String imageUrl = '';

      // Check all possible keys the server might return
      for (final key in ['profileImage', 'image', 'avatar', 'photo', 'picture']) {
        final val = user[key];
        if (val != null && val.toString().isNotEmpty) {
          imageUrl = val.toString();
          Logger.log("📸 Found image URL under key '$key': $imageUrl", type: "info");
          break;
        }
      }

      // ✅ Prepend base URL only if it's a relative path
      if (imageUrl.isNotEmpty &&
          !imageUrl.startsWith('http://') &&
          !imageUrl.startsWith('https://')) {
        // Ensure no double slash
        final base = AppConstants.BASE_URL.endsWith('/')
            ? AppConstants.BASE_URL.substring(0, AppConstants.BASE_URL.length - 1)
            : AppConstants.BASE_URL;
        final path = imageUrl.startsWith('/') ? imageUrl : '/$imageUrl';
        imageUrl = '$base$path';
      }

      // ✅ Add cache-busting timestamp to force image reload in UI
      if (imageUrl.isNotEmpty) {
        final separator = imageUrl.contains('?') ? '&' : '?';
        imageUrl = '$imageUrl${separator}t=${DateTime.now().millisecondsSinceEpoch}';
      }

      await userBox.put('profileImage', imageUrl);
      Logger.log("✅ Hive data updated successfully", type: "info");
      Logger.log("📸 Final saved image URL: $imageUrl", type: "info");

      // ✅ Update observable immediately so UI reacts right away
      profileImageUrl.value = imageUrl;

      // Reload local controller data
      await loadUserData();

      // ✅ Refresh ProfileController so profile screen also updates
      if (Get.isRegistered<ProfileController>()) {
        final profileController = Get.find<ProfileController>();
        Logger.log("🔄 Forcing ProfileController refresh from API...", type: "info");
        await profileController.refreshProfile();
        Logger.log("✅ ProfileController refreshed successfully", type: "success");
      } else {
        Logger.log(
          "⚠️ ProfileController not registered, skipping refresh",
          type: "warning",
        );
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        Navigator.pop(context);
      }
    } catch (e) {
      Logger.log("Error in _handleSuccessfulUpdate: $e", type: "error");

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Profile updated but failed to save locally. Please restart the app.',
            ),
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