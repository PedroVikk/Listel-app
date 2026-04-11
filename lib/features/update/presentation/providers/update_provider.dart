import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/app_update_service.dart';

final updateInfoProvider = FutureProvider<UpdateInfo?>((ref) {
  return AppUpdateService.checkForUpdate();
});
