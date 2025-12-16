import 'package:geolocator/geolocator.dart';
import '../../../core/utils/distance_calculator.dart';
import '../../../core/constants/app_constants.dart';

class AttendanceChecker {
  /// 현재 위치 가져오기
  static Future<Position?> getCurrentPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return null;
    }

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
    } catch (e) {
      return null;
    }
  }

  /// 현장 도착 여부 확인
  /// 
  /// [siteLat] 현장 위도
  /// [siteLng] 현장 경도
  /// [siteRadius] 현장 반경 (미터, 기본값 30m)
  /// 
  /// Returns 현장 반경 내에 있으면 true
  static Future<bool> checkArrival({
    required double siteLat,
    required double siteLng,
    double siteRadius = AppConstants.attendanceRadiusMeters,
  }) async {
    final position = await getCurrentPosition();
    if (position == null) {
      return false;
    }

    return DistanceCalculator.isWithinRadius(
      position.latitude,
      position.longitude,
      siteLat,
      siteLng,
      siteRadius,
    );
  }

  /// 현장까지의 거리 계산
  /// 
  /// [siteLat] 현장 위도
  /// [siteLng] 현장 경도
  /// 
  /// Returns 거리 (미터), 위치를 가져올 수 없으면 null
  static Future<double?> getDistanceToSite({
    required double siteLat,
    required double siteLng,
  }) async {
    final position = await getCurrentPosition();
    if (position == null) {
      return null;
    }

    return DistanceCalculator.calculateDistance(
      position.latitude,
      position.longitude,
      siteLat,
      siteLng,
    );
  }
}

