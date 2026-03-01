import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:saferader/controller/SeakerLocation/seakerLocationsController.dart';
import 'package:saferader/utils/app_color.dart';
import 'package:saferader/utils/logger.dart';
import 'package:saferader/views/base/Ios_effect/iosTapEffect.dart';
import 'package:saferader/views/screen/help_seaker/notifications/seaker_notifications.dart';
import '../../../../Service/Firebase/notifications.dart';
import '../../../../controller/SocketService/socket_service.dart';
import '../../../../controller/UserController/userController.dart';
import '../../../../controller/bottom_nav/bottomNavController.dart';
import '../../../../controller/notifications/notifications_controller.dart';
import '../../../../controller/profile/profile.dart';
import '../../controller/UnifiedHelpController.dart';
import '../base/AppText/appText.dart';
import 'help_seaker/locations/seaker_location.dart';
import 'map_seeker/map_seeker_enhanced.dart';  // For CustomBox

// ─────────────────────────────────────────────────────────────────────────────
// UnifiedHomePage
// Single page for the entire help flow.
// ─────────────────────────────────────────────────────────────────────────────
class UnifiedHomePage extends StatefulWidget {
  const UnifiedHomePage({super.key});

  @override
  State<UnifiedHomePage> createState() => _UnifiedHomePageState();
}

class _UnifiedHomePageState extends State<UnifiedHomePage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  // ── Controllers ────────────────────────────────────────────────────────────
  late final UnifiedHelpController ctrl;
  late final UserController userController;
  late final ProfileController profileController;
  late final SeakerLocationsController locationController;
  late final NotificationsController notificationsController;

  // ── Animation ──────────────────────────────────────────────────────────────
  late AnimationController _blinkCtrl;
  late Animation<double> _blinkAnim;

  @override
  void initState() {
    super.initState();

    ctrl = Get.put(UnifiedHelpController());
    userController = Get.find<UserController>();
    profileController = Get.put(ProfileController());
    locationController = Get.put(SeakerLocationsController());
    notificationsController = Get.find<NotificationsController>();

    WidgetsBinding.instance.addObserver(this);

    if (Get.isRegistered<SocketService>()) {
      Get.find<SocketService>().updateRole('both');
    }

    _blinkCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _blinkAnim = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _blinkCtrl, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ctrl.initSocket();
      ctrl.helperStatus.value = true;
      ctrl.setHelperAvailability(true);
      locationController.startLiveLocation();
      NotificationService.processPendingNotification();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.resumed:
        ctrl.onAppResumed();
        break;
      case AppLifecycleState.paused:
        ctrl.onAppPaused();
        break;
      default:
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _blinkCtrl.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Color(0xff202020),
      statusBarBrightness: Brightness.light,
      statusBarIconBrightness: Brightness.light,
    ));

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerRight,
            end: Alignment.centerLeft,
            colors: [Color(0xFFFFF1A9), Color(0xFFFFFFFF), Color(0xFFFFF1A9)],
            stops: [0.0046, 0.5005, 0.9964],
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 70),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: _buildHeader(),
            ),
            SizedBox(height: size.height * 0.01),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Obx(() => _buildBody(context)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BODY — single switch on screenMode
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildBody(BuildContext context) {
    switch (ctrl.screenMode.value) {
      case HelpScreenMode.idle:
        return _buildIdleMode(context);
      case HelpScreenMode.seekerSending:
        return _buildSeekerSending(context);
      case HelpScreenMode.seekerWaiting:
        return _buildSeekerWaiting(context);
      case HelpScreenMode.giverSearching:
        return _buildGiverSearching(context);
      case HelpScreenMode.giverHelping:
        return _buildGiverHelping(context);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // MODE 0: IDLE
  // Shows toggle to become available to help + optional help button
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildIdleMode(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Column(
      children: [
        _buildHelperToggle(),
        SizedBox(height: size.height * 0.02),
        Obx(() {
          if (!ctrl.helperStatus.value) return const SizedBox();
          return Column(
            children: [
              // Emergency help button (tap to ask for help)
              IosTapEffect(
                onTap: () => _showNeedHelpDialog(context),
                child: AnimatedBuilder(
                  animation: _blinkAnim,
                  builder: (_, __) => _buildCircleButton(
                    outerColor: const Color(0xFFFBD3AB),
                    midColor: const Color(0xFFF24A4A),
                    innerColor: const Color(0xFFE94A4A),
                    opacity: _blinkAnim.value,
                    label: 'HELP',
                    sublabel: 'Emergency',
                  ),
                ),
              ),
              SizedBox(height: size.height * 0.05),
              CustomBox(
                backgroundColor: AppColors.colorYellow.withOpacity(0.10),
                child: Column(
                  children: [
                    const SizedBox(height: 15),
                    SvgPicture.asset('assets/icon/tabler_heart-handshake.svg'),
                    const SizedBox(height: 15),
                    const AppText(
                      'No emergency requests right now',
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.color2Box,
                    ),
                    const SizedBox(height: 10),
                    const AppText(
                      'Your helping keeps the community safe',
                      fontSize: 14,
                      fontWeight: FontWeight.w100,
                      color: AppColors.color2Box,
                    ),
                    const SizedBox(height: 15),
                  ],
                ),
              ),
            ],
          );
        }),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // MODE 1: SEEKER SENDING
  // I sent a help request, waiting for someone to accept
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildSeekerSending(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Column(
      children: [
        AnimatedBuilder(
          animation: _blinkAnim,
          builder: (_, __) => _buildCircleButton(
            outerColor: const Color(0xFFFEE3B5),
            midColor: const Color(0xFFFD7F2C),
            innerColor: const Color(0xFFFD9346),
            opacity: _blinkAnim.value,
            label: 'SENDING',
            sublabel: 'Request..',
          ),
        ),
        SizedBox(height: size.height * 0.02),
        _buildCancelButton(onTap: ctrl.cancelMyHelpRequest),
        SizedBox(height: size.height * 0.01),
        const Align(
          child: AppText(
            'Looking for Helpers',
            fontWeight: FontWeight.w500,
            fontSize: 20,
            color: AppColors.color2Box,
          ),
        ),
        const SizedBox(height: 12),
        CustomBox(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const AppText(
                    'Nearby Helpers',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.color2Box,
                  ),
                  SvgPicture.asset('assets/icon/Frame (1).svg'),
                ],
              ),
              const SizedBox(height: 12),
              Obx(() {
                final stats = [
                  {'label': 'Within 1 km', 'count': ctrl.nearbyStats.value.km1},
                  {'label': 'Within 2 km', 'count': ctrl.nearbyStats.value.km2},
                  {'label': 'Within 3 km', 'count': ctrl.nearbyStats.value.km3},
                ];
                return Column(
                  children: stats.map((item) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: AppColors.iconBg.withOpacity(0.10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          AppText(
                            item['label'] as String,
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                            color: AppColors.color2Box,
                          ),
                          AppText(
                            '${item['count']} available',
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppColors.colorIcons,
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // MODE 2: SEEKER WAITING (help is on the way)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildSeekerWaiting(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Column(
      children: [
        Container(
          height: 300,
          width: 300,
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFFD7E5FB),
          ),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF60A5FA),
            ),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF3B82F6),
              ),
              child: Center(
                child: Obx(() => Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const AppText(
                      'HELP',
                      fontSize: 34,
                      fontWeight: FontWeight.w700,
                      color: AppColors.colorWhite,
                    ),
                    const AppText(
                      'Coming..',
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                      color: AppColors.colorWhite,
                    ),
                    const SizedBox(height: 10),
                    AppText(
                      '${ctrl.helperName} is on the way',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.colorWhite,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    AppText(
                      '${ctrl.seekerToHelperDistance.value} · ETA ${ctrl.seekerToHelperEta.value}',
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: AppColors.colorWhite,
                    ),
                  ],
                )),
              ),
            ),
          ),
        ),
        SizedBox(height: size.height * 0.02),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 90),
          child: Column(
            children: [
              GradientButtons(
                gradientColors: const [Color(0xFFD93A3A), Color(0xFFE94A4A)],
                onTap: ctrl.cancelMyHelpRequest,
                text: 'Cancel Request',
                icon: Icons.cancel_outlined,
              ),
              const SizedBox(height: 10),
              GradientButtons(
                onTap: ctrl.seekerMarkHelpDone,
                text: 'Work is done',
                icon: Icons.check,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // MODE 3: GIVER SEARCHING (incoming request cards)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildGiverSearching(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Column(
      children: [
        AnimatedBuilder(
          animation: _blinkAnim,
          builder: (_, __) => _buildCircleButton(
            outerColor: const Color(0xFFFEE3B5),
            midColor: const Color(0xFFFD7F2C),
            innerColor: const Color(0xFFFD9346),
            opacity: _blinkAnim.value,
            label: 'Searching',
            sublabel: 'Please Wait..',
            labelFontSize: 38,
          ),
        ),
        SizedBox(height: size.height * 0.02),
        // Decline all
        _buildCancelButton(
          label: 'Decline All',
          onTap: () {
            final ids = ctrl.pendingRequests
                .map((r) => r['_id']?.toString() ?? '')
                .where((id) => id.isNotEmpty)
                .toList();
            for (final id in ids) {
              ctrl.declineRequest(id);
            }
          },
        ),
        SizedBox(height: size.height * 0.01),
        const Align(
          alignment: Alignment.topLeft,
          child: AppText(
            'Help Requests',
            fontWeight: FontWeight.w500,
            fontSize: 20,
            color: AppColors.color2Box,
          ),
        ),
        const SizedBox(height: 10),
        Obx(() => ListView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: ctrl.pendingRequests.length,
          itemBuilder: (context, index) {
            final req = ctrl.pendingRequests[index];
            return _buildRequestCard(context, req);
          },
        )),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // MODE 4: GIVER HELPING (I accepted, going to someone)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildGiverHelping(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Obx(() {
      final req = ctrl.acceptedRequest.value;
      if (req == null) return const SizedBox();

      final requestId = ctrl.acceptedRequestId;
      final seekerName = ctrl.acceptedSeekerName;
      final seekerImage = ctrl.acceptedSeekerImage;
      final distance = ctrl.acceptedDistance;
      final eta = ctrl.acceptedEta;

      return Column(
        children: [
          // ── Top info circle ──────────────────────────────────────────────
          Container(
            height: 300,
            width: 300,
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)],
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(50),
                  child: Image.network(
                    seekerImage,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: const Icon(Icons.person, size: 40, color: Colors.white),
                    ),
                  ),
                ),
                SizedBox(height: size.height * 0.02),
                AnimatedBuilder(
                  animation: _blinkAnim,
                  builder: (_, __) => Opacity(
                    opacity: _blinkAnim.value,
                    child: Column(
                      children: [
                        AppText(
                          'GOING TO HELP',
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.colorWhite,
                        ),
                        AppText(
                          seekerName,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.colorWhite,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.location_on, size: 14, color: Colors.white),
                            const SizedBox(width: 4),
                            AppText(distance, fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.colorWhite),
                            const SizedBox(width: 10),
                            const Icon(Icons.timer, size: 14, color: Colors.white),
                            const SizedBox(width: 4),
                            AppText('ETA $eta', fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.colorWhite),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: size.height * 0.03),

          // ── Action buttons ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 90),
            child: Column(
              children: [
                GradientButtons(
                  gradientColors: const [Color(0xFFD93A3A), Color(0xFFE94A4A)],
                  onTap: () => ctrl.giverCancelHelp(requestId),
                  text: 'Cancel Help',
                  icon: Icons.cancel_outlined,
                ),
                const SizedBox(height: 10),
                GradientButtons(
                  onTap: () => ctrl.giverMarkDone(requestId),
                  text: 'Work is done',
                  icon: Icons.check,
                ),
              ],
            ),
          ),
          SizedBox(height: size.height * 0.02),

          // ── Info card with map ───────────────────────────────────────────
          CustomBox(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(25),
                      child: Image.network(
                        seekerImage,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 50, height: 50,
                          decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(25)),
                          child: const Icon(Icons.person, color: Colors.grey),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppText(seekerName, fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.color2Box),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                              const SizedBox(width: 4),
                              Expanded(
                                child: AppText(
                                  '$distance away · ETA $eta',
                                  fontSize: 12, fontWeight: FontWeight.w400, color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const AppText('Seeker Location', fontSize: 18, fontWeight: FontWeight.w500, color: AppColors.color2Box),
                const SizedBox(height: 12),

                // ── Map ────────────────────────────────────────────────────
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(width: 2, color: AppColors.colorYellow),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Stack(
                    children: [
                      Obx(() {
                        final myPos = ctrl.myPosition;
                        final seekerLL = ctrl.seekerLatLng;

                        if (myPos == null || seekerLL == null) {
                          return const SizedBox(
                            height: 200,
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }

                        return SizedBox(
                          height: 200,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: GoogleMap(
                              initialCameraPosition: CameraPosition(target: seekerLL, zoom: 14),
                              markers: {
                                Marker(
                                  markerId: const MarkerId('me'),
                                  position: LatLng(myPos.latitude, myPos.longitude),
                                  infoWindow: const InfoWindow(title: 'You (Helper)'),
                                  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
                                ),
                                Marker(
                                  markerId: const MarkerId('seeker'),
                                  position: seekerLL,
                                  infoWindow: InfoWindow(title: seekerName),
                                  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                                ),
                              },
                              onTap: (_) => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const UniversalMapViewEnhanced(),
                                ),
                              ),
                              zoomControlsEnabled: false,
                              myLocationButtonEnabled: false,
                              liteModeEnabled: true,
                            ),
                          ),
                        );
                      }),
                      Positioned(
                        bottom: 0, right: 0,
                        child: Container(
                          height: 32, width: 83,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFDE047).withOpacity(0.80),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(16),
                              bottomRight: Radius.circular(8),
                            ),
                          ),
                          child: const Center(
                            child: AppText('View map', fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.color2Box),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // ── Address + last updated ────────────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(
                      width: 150,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppText('Address :', fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.colorStroke),
                          SizedBox(height: 4),
                          AppText('Last Updated :', fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.colorStroke),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Obx(() => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppText(
                            locationController.addressText.value.isEmpty
                                ? 'Fetching address...'
                                : locationController.addressText.value,
                            fontSize: 14, fontWeight: FontWeight.w200, color: AppColors.color2Box,
                            overflow: TextOverflow.ellipsis, maxLines: 2,
                          ),
                          const SizedBox(height: 4),
                          AppText(
                            locationController.currentPosition.value == null
                                ? '--/--/----'
                                : '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                            fontSize: 14, fontWeight: FontWeight.w200, color: AppColors.color2Box,
                          ),
                        ],
                      )),
                    ),
                  ],
                ),
                const SizedBox(height: 15),

                // ── Bottom action row ──────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: GradientButtons(
                        onTap: () => ctrl.giverMarkDone(requestId),
                        text: 'Done',
                        icon: Icons.check,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: GradientButtons(
                        onTap: () => ctrl.giverCancelHelp(requestId),
                        gradientColors: const [Color(0xFFD93A3A), Color(0xFFE94A4A)],
                        text: 'Cancel',
                        icon: Icons.cancel_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      );
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  // REQUEST CARD (giver mode)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildRequestCard(BuildContext context, Map<String, dynamic> request) {
    final seeker = request['seeker'] as Map<String, dynamic>?;
    final name = seeker?['name']?.toString() ?? 'Someone';
    final image = seeker?['profileImage']?.toString() ?? '';
    final distance = request['distance']?.toString() ?? 'Calculating...';
    final eta = request['eta']?.toString() ?? 'Calculating...';
    final requestId = request['_id']?.toString() ?? '';
    final createdAt = request['createdAt']?.toString();

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7C8),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row ─────────────────────────────────────────────────
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(40),
                child: image.isNotEmpty
                    ? Image.network(
                  image,
                  width: 45, height: 45, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _fallbackAvatar(),
                  loadingBuilder: (_, child, progress) =>
                  progress == null ? child : _loadingAvatar(),
                )
                    : _fallbackAvatar(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      '$name needs help',
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.color2Box,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 14, color: Colors.black54),
                        const SizedBox(width: 4),
                        AppText(distance, fontSize: 13, color: Colors.black54),
                        const SizedBox(width: 10),
                        const Icon(Icons.timer_outlined, size: 14, color: Colors.black54),
                        const SizedBox(width: 4),
                        AppText('ETA $eta', fontSize: 13, color: Colors.black54),
                      ],
                    ),
                    if (createdAt != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Text(
                          _formatTime(createdAt),
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ── Accept / Decline ───────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: IosTapEffect(
                  onTap: () => ctrl.acceptRequest(requestId),
                  child: Container(
                    height: 46,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check, color: Colors.white, size: 18),
                          SizedBox(width: 6),
                          AppText('Accept', fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: IosTapEffect(
                  onTap: () => ctrl.declineRequest(requestId),
                  child: Container(
                    height: 46,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.close, color: Colors.white, size: 18),
                          SizedBox(width: 6),
                          AppText('Decline', fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // HEADER
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return CustomBox(
      backgroundColor: AppColors.iconBg.withOpacity(0.01),
      child: Row(
        children: [
          // Profile image
          Obx(() => Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.colorYellow, width: 2),
              borderRadius: BorderRadius.circular(50),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(50),
              child: CachedNetworkImage(
                imageUrl: profileController.profileImage.value,
                cacheKey: profileController.profileImage.value.split('?').first,
                fit: BoxFit.cover, height: 50, width: 50,
                httpHeaders: const {'Accept': 'image/*'},
                placeholder: (_, __) => const CupertinoActivityIndicator(),
                errorWidget: (_, __, ___) => const Icon(Icons.error),
              ),
            ),
          )),
          const SizedBox(width: 10),

          // Name + role
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Obx(() => AppText(
                profileController.firstName.value,
                fontSize: 18, fontWeight: FontWeight.w600,
                color: AppColors.color2Box, maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )),
              Row(
                children: [
                  Obx(() => AppText(
                    'Help ${userController.userRole}',
                    fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.color2Box,
                  )),
                  const SizedBox(width: 5),
                  SvgPicture.asset('assets/icon/material-symbols-light_change-circle.svg'),
                ],
              ),
            ],
          ),
          const Spacer(),



          // Notifications
          IosTapEffect(
            onTap: () => Get.to(SeakerNotifications()),
            child: SizedBox(
              height: 50, width: 32,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    top: 4,
                    child: SvgPicture.asset('assets/icon/notifications.svg', height: 30, width: 30),
                  ),
                  Positioned(
                    right: -2, top: 0,
                    child: Obx(() {
                      final count = notificationsController.unreadCount;
                      if (count <= 0) return const SizedBox.shrink();
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(12)),
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        child: Center(
                          child: Text(
                            count > 99 ? '99+' : count.toString(),
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // HELPER TOGGLE (available to help switch)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildHelperToggle() {
    return CustomBox(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText('Helper Status', fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.color2Box),
              SizedBox(height: 8),
              AppText('Ready to help others', fontSize: 14, fontWeight: FontWeight.w100, color: AppColors.color2Box),
            ],
          ),
          Obx(() => Transform.scale(
            scale: 0.8,
            child: CupertinoSwitch(
              value: ctrl.helperStatus.value,
              onChanged: (v) => ctrl.setHelperAvailability(v),
              activeColor: AppColors.colorYellow,
              trackColor: Colors.grey.shade300,
              thumbColor: Colors.white,
              inactiveThumbColor: Colors.white,
            ),
          )),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // CIRCLE BUTTON (animated pulse)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildCircleButton({
    required Color outerColor,
    required Color midColor,
    required Color innerColor,
    required double opacity,
    required String label,
    required String sublabel,
    double labelFontSize = 35,
  }) {
    return Container(
      height: 300, width: 300,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(shape: BoxShape.circle, color: outerColor),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(shape: BoxShape.circle, color: midColor),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(shape: BoxShape.circle, color: innerColor),
          child: Center(
            child: Opacity(
              opacity: opacity,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AppText(label, fontSize: labelFontSize, fontWeight: FontWeight.w700, color: AppColors.colorWhite),
                  AppText(sublabel, fontSize: 22, fontWeight: FontWeight.w500, color: AppColors.colorWhite),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // CANCEL BUTTON
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildCancelButton({required VoidCallback onTap, String label = 'Cancel Request'}) {
    return IosTapEffect(
      onTap: onTap,
      child: Container(
        height: 46, width: 140,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: const LinearGradient(colors: [Color(0xFFD93A3A), Color(0xFFE94A4A)]),
        ),
        child: Center(
          child: AppText(label, fontWeight: FontWeight.w500, fontSize: 15, color: AppColors.colorWhite),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // DIALOGS
  // ─────────────────────────────────────────────────────────────────────────
  void _showNeedHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Need help?'),
        content: const Text('Send an emergency help request? Helpers nearby will be notified.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final pos = locationController.currentPosition.value;
              if (pos == null) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Location not ready. Please wait and try again.'),
                  ));
                }
                return;
              }
              ctrl.emergencyVibration();
              await ctrl.sendHelpRequest(pos.latitude, pos.longitude);
            },
            child: const Text('Yes'),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SMALL HELPERS
  // ─────────────────────────────────────────────────────────────────────────
  Widget _fallbackAvatar() => Container(
    width: 45, height: 45,
    decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(40)),
    child: const Icon(Icons.person, color: Colors.grey, size: 22),
  );

  Widget _loadingAvatar() => Container(
    width: 45, height: 45,
    decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(40)),
    child: const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Colors.amber)),
  );

  String _formatTime(String isoTime) {
    try {
      final dt = DateTime.parse(isoTime);
      final diff = DateTime.now().difference(dt);
      if (diff.inSeconds < 60) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (_) {
      return 'Recently';
    }
  }
}