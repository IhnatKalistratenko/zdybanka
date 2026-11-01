import 'package:http/http.dart' as http;
import '../services/auth_aware_http_client.dart';

class ApiRoutes {
  static final String baseUrl = "http://localhost:5071/api";
  static final String loginRoute = "$baseUrl/Auth/login";
  static final String registerRoute = "$baseUrl/User";
  static final String userRoute = "$baseUrl/User/me";
  static final String tagsRoute = "$baseUrl/Tag";
  static final String createEventRoute = "$baseUrl/Event";
  static String userByIdRoute(String id) => "$baseUrl/User/$id";
}

final http.Client httpClient = AuthAwareHttpClient();
