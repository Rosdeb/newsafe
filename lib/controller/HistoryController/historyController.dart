import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:saferader/Models/ActivityHistory/activityHistory.dart';
import 'package:saferader/utils/api_service.dart';
import 'package:saferader/utils/logger.dart';
import 'package:saferader/utils/token_service.dart';
import '../../utils/app_constant.dart';
import '../../utils/auth_service.dart';
import '../networkService/networkService.dart';

class Historycontroller extends GetxController {
  RxList<HistoryModel> historyList = <HistoryModel>[].obs;
  RxBool isLoading = false.obs;

  int currentPage = 1;
  int pageSize = 10;
  int totalPages = 1;

  bool _isFirstLoad = true;

  @override
  void onInit() {
    super.onInit();
    if (_isFirstLoad) {
      refresh();
      _isFirstLoad = false;
    }
  }

  Future<void> getHistoryActivity(BuildContext context, {int page = 1}) async {
    final networkController = Get.find<NetworkController>();
    if (!networkController.isOnline.value) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No internet connection')),
      );
      return;
    }

    isLoading.value = true;
    try {
      final response = await ApiService.get('/api/users/me/activity-logs?page=$page&pagesize=$pageSize');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final pagination = data['pagination'];
        currentPage = pagination['currentPage'] ?? 1;
        pageSize = pagination['pageSize'] ?? 10;
        totalPages = pagination['totalPages'] ?? 1;

        final list = data['data'] as List? ?? [];
        historyList.addAll(list.map((item) => HistoryModel.fromJson(item)));
        Logger.log("Fetch successful: ${historyList.length} items", type: "info");
      } else {
        Logger.log("Fetch failed: ${response.body}", type: "error");
      }
    } catch (e, stackTrace) {
      Logger.log("Unexpected error: $e\nStack: $stackTrace", type: "error");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadNextPage(BuildContext context) async {
    if (currentPage < totalPages) {
      currentPage++;
      await getHistoryActivity(context, page: currentPage);
    }
  }

  @override
  void refresh() {
    historyList.clear();
    currentPage = 1;
    getHistoryActivity(Get.context!, page: currentPage);
  }
}