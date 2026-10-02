import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../models/staff_dashboard_dto.dart';

class StaffDashboardRepository {
  final Dio _dio = ApiClient.create();

  Future<StaffDashboardData> cargarDashboard() async {
    try {
      final res = await _dio.get('/api/staff-portal/dashboard');
      return StaffDashboardData.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
