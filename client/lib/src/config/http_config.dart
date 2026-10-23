import 'package:http/http.dart' as http;

class ApiRoutes {
  static final String baseUrl = "http://localhost:5071/api";
  static final String loginRoute = "$baseUrl/Auth/login";
  static final String registerRoute = "$baseUrl/User";
  static final String userRoute = "$baseUrl/User/me";
  static String userByIdRoute(String id) => "$baseUrl/User/$id";
}

final httpClient = http.Client();
