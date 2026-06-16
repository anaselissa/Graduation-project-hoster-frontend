import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:3000/api';
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  late Dio _dio;
  Dio get dio => _dio;

  ApiService._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        contentType: Headers.jsonContentType,
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('auth_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.remove('auth_token');
          }
          return handler.next(error);
        },
      ),
    );
  }

  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String userType,
    String? phone,
    String? serviceTypeId,
  }) async {
    try {
      final response = await _dio.post('/auth/register', data: {
        'email': email,
        'password': password,
        'first_name': firstName,
        'last_name': lastName,
        'user_type': userType,
        'phone': phone,
        if (serviceTypeId != null) 'service_type_id': serviceTypeId,
      });
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', response.data['token']);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', response.data['token']);
      await prefs.setString('user_id', response.data['user']['id'].toString());
      await prefs.setString(
          'user_type', response.data['user']['user_type'] ?? '');
      await prefs.setString(
          'user_role',
          response.data['user']['role'] ??
              response.data['user']['user_type'] ??
              '');
      await prefs.setString('user_name',
          '${response.data['user']['first_name'] ?? ''} ${response.data['user']['last_name'] ?? ''}');
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('auth_token');
  }

  // ✅ الإصلاح: بتشيك user_role أول، لو admin بترجع 'admin'
  Future<String?> getSavedUserType() async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('user_role') ?? '';
    if (role == 'admin') return 'admin';
    return prefs.getString('user_type');
  }

  Future<String?> getSavedUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_name');
  }

  Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final response = await _dio.get('/users/profile');
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> updateUserProfile({
    String? firstName,
    String? lastName,
    String? phone,
    String? bio,
    String? address,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final response = await _dio.put('/users/profile', data: {
        if (firstName != null) 'first_name': firstName,
        if (lastName != null) 'last_name': lastName,
        if (phone != null) 'phone': phone,
        if (bio != null) 'bio': bio,
        if (address != null) 'address': address,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
      });
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<dynamic>> getVolunteerRequests({String? status}) async {
    try {
      final response = await _dio.get('/requests', queryParameters: {
        if (status != null) 'status': status,
      });
      return response.data is List ? response.data : [];
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> acceptServiceRequest(String id) async {
    try {
      final response = await _dio.put('/requests/$id/accept');
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> completeServiceRequest(String id) async {
    try {
      final response = await _dio.put('/requests/$id/complete');
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> cancelServiceRequest(String id) async {
    try {
      final response = await _dio.put('/requests/$id/cancel');
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<dynamic>> getServiceTypes() async {
    try {
      final response = await _dio.get('/services/types');
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<dynamic>> getAvailableServices({
    double? latitude,
    double? longitude,
    int radius = 10,
    String? serviceTypeId,
  }) async {
    try {
      final response = await _dio.get('/services/available', queryParameters: {
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        'radius': radius,
        if (serviceTypeId != null) 'service_type_id': serviceTypeId,
      });
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> createServiceRequest(
      Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/services/requests', data: data);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<dynamic>> getUserServiceRequests({String? status}) async {
    try {
      final response = await _dio.get('/services/requests', queryParameters: {
        if (status != null) 'status': status,
      });
      return response.data is List ? response.data : [];
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getNearbyVolunteers({
    required double lat,
    required double lng,
    int radius = 10,
    String? serviceTypeId,
  }) async {
    try {
      final response =
          await _dio.get('/map-locations/volunteers', queryParameters: {
        'lat': lat,
        'lng': lng,
        'radius': radius,
        if (serviceTypeId != null) 'service_type_id': serviceTypeId,
      });
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getNearbyRequests({
    required double lat,
    required double lng,
    int radius = 50,
  }) async {
    try {
      final response =
          await _dio.get('/map-locations/requests', queryParameters: {
        'lat': lat,
        'lng': lng,
        'radius': radius,
      });
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getDrivingDistance({
    required double patientLat,
    required double patientLng,
    required double volunteerLat,
    required double volunteerLng,
  }) async {
    try {
      final response =
          await _dio.get('/map-locations/driving-distance', queryParameters: {
        'patient_lat': patientLat,
        'patient_lng': patientLng,
        'volunteer_lat': volunteerLat,
        'volunteer_lng': volunteerLng,
      });
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<String> sendChatMessage(String message) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      final response = await _dio.post('/chat', data: {
        'message': message,
        if (userId != null) 'userId': userId,
      });
      return response.data['reply'] ?? '';
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<dynamic>> getMedicalRecords(
    String userId, {
    String sort = 'date-desc',
    String search = '',
  }) async {
    try {
      final response = await _dio.get('/medical-records', queryParameters: {
        'user_id': userId,
        'sort': sort,
        if (search.isNotEmpty) 'search': search,
      });
      return response.data is List ? response.data : [];
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> addMedicalRecord(
      String userId, Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/medical-records', data: {
        ...data,
        'user_id': userId,
      });
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> deleteMedicalRecord(String id) async {
    try {
      await _dio.delete('/medical-records/$id');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // إنشاء حساب متطوع بواسطة الأدمن
  Future<Map<String, dynamic>> createVolunteerByAdmin({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String phone,
    required String serviceTypeId,
  }) async {
    try {
      final response = await _dio.post('/admin/create-volunteer', data: {
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
        'password': password,
        'phone': phone,
        'service_type_id': serviceTypeId,
      });
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  String _handleError(DioException error) {
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return 'انتهت مهلة الاتصال، تحقق من الشبكة';
    }
    if (error.type == DioExceptionType.connectionError) {
      return 'لا يمكن الاتصال بالسيرفر، تأكد من تشغيله';
    }
    if (error.response?.data != null) {
      return error.response?.data['error']?.toString() ?? 'خطأ في السيرفر';
    }
    return error.message ?? 'خطأ في الشبكة';
  }
}
