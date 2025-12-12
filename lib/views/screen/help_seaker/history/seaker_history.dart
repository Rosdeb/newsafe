import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:saferader/controller/HistoryController/historyController.dart';
import 'package:saferader/views/screen/help_seaker/history/base/body.dart';


class SeakerHistory extends StatefulWidget {
  SeakerHistory({super.key});

  @override
  State<SeakerHistory> createState() => _SeakerHistoryState();
}

class _SeakerHistoryState extends State<SeakerHistory> {

  final Historycontroller controller = Get.put(Historycontroller());
  late ScrollController scrollController;

  @override
  void initState() {
    super.initState();
    scrollController = ScrollController();
    scrollController.addListener((){
      if(scrollController.position.pixels >= scrollController.position.maxScrollExtent - 50 &&
          !controller.isLoading.value){
        controller.loadNextPage(context);
      }
    });
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Body(scrollController: scrollController,),
    );
  }
}






