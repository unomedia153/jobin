import 'dart:math';

class DistanceCalculator {
  /// 두 좌표 간의 거리를 미터 단위로 계산 (Haversine 공식)
  /// 
  /// [lat1] 첫 번째 위치의 위도
  /// [lng1] 첫 번째 위치의 경도
  /// [lat2] 두 번째 위치의 위도
  /// [lng2] 두 번째 위치의 경도
  /// 
  /// Returns 두 지점 간의 거리 (미터)
  static double calculateDistance(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const double earthRadius = 6371000; // 지구 반지름 (미터)

    final double dLat = _toRadians(lat2 - lat1);
    final double dLng = _toRadians(lng2 - lng1);

    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLng / 2) *
            sin(dLng / 2);

    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  /// 도(degree)를 라디안으로 변환
  static double _toRadians(double degree) {
    return degree * (pi / 180);
  }

  /// 현재 위치가 목표 위치의 반경 내에 있는지 확인
  /// 
  /// [currentLat] 현재 위치의 위도
  /// [currentLng] 현재 위치의 경도
  /// [targetLat] 목표 위치의 위도
  /// [targetLng] 목표 위치의 경도
  /// [radiusMeters] 허용 반경 (미터)
  /// 
  /// Returns 반경 내에 있으면 true
  static bool isWithinRadius(
    double currentLat,
    double currentLng,
    double targetLat,
    double targetLng,
    double radiusMeters,
  ) {
    final distance = calculateDistance(
      currentLat,
      currentLng,
      targetLat,
      targetLng,
    );
    return distance <= radiusMeters;
  }
}

