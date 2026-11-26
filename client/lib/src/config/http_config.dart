import 'package:client/src/models/event_query.dart';

import '../models/event_boundary_request.dart';
import '../services/api_client.dart';
import '../services/auth_aware_http_client.dart';

class ApiRoutes {
  static final String baseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:5000');
  static final String baseApiUrl = "$baseUrl/api";
  static final String baseSignalrUrl = "$baseUrl/hubs/chat";
  static final String loginRoute = "$baseApiUrl/Auth/login";
  static final String registerRoute = "$baseApiUrl/User";
  static final String userRoute = "$baseApiUrl/User/me";
  static final String tagsRoute = "$baseApiUrl/Tag";
  static final String createEventRoute = "$baseApiUrl/Event";
  static final String getEventsRoute = "$baseApiUrl/Event";
  static final String myEventsRoute = "$baseApiUrl/Event/me";
  static final String getEventsInBounds = "$baseApiUrl/Event/in-bounds";
  static final String getUserChats = "$baseApiUrl/Chat/me";
  static String getChatById(String chatId) => "$baseApiUrl/Chat/$chatId";
  static String updateChat(String chatId) => "$baseApiUrl/Chat/$chatId";
  static String leaveEventRoute(String eventId) =>
      "$baseApiUrl/Event/$eventId/leave";
  static String userByIdRoute(String id) => "$baseApiUrl/User/$id";

  static String buildGetEventsFromQuery(EventQuery queryParams) {
    final parameters = <String, dynamic>{
      'Radius': queryParams.radiusMeters.toString(),
      'Page': queryParams.page.toString(),
      'PageSize': queryParams.pageSize.toString(),
    };

    if (queryParams.status != null) {
      parameters['Status'] = queryParams.status!;
    }
    if (queryParams.creatorId != null) {
      parameters['CreatorId'] = queryParams.creatorId!;
    }
    if (queryParams.startFrom != null) {
      parameters['StartFrom'] = queryParams.startFrom!.toIso8601String();
    }
    if (queryParams.endTo != null) {
      parameters['EndTo'] = queryParams.endTo!.toIso8601String();
    }
    if (queryParams.userLongitude != null) {
      parameters['UserLongitude'] = queryParams.userLongitude!.toString();
    }
    if (queryParams.userLatitude != null) {
      parameters['UserLatitude'] = queryParams.userLatitude!.toString();
    }
    if (queryParams.tags.isNotEmpty) {
      parameters['Tags'] = queryParams.tags.toList();
    }
    if (queryParams.userStatus != null) {
      parameters['UserStatus'] = queryParams.userStatus;
    }

    if (queryParams.orderMethod != null &&
        queryParams.orderMethod!.isNotEmpty) {
      parameters['OrderMethod'] = queryParams.orderMethod!.trim();
    }

    return Uri.parse(getEventsRoute)
        .replace(queryParameters: parameters)
        .toString();
  }

  static String buildGetEventsInBoundaries(EventBoundaryRequest queryParams) {
    final parameters = <String, dynamic>{};

    parameters["TopLeftCornerLongitude"] = queryParams.topLeftCornerLongitude
        .toString();
    parameters["TopLeftCornerLatitude"] = queryParams.topLeftCornerLatitude
        .toString();
    parameters["BottomRightCornerLongitude"] = queryParams
        .bottomRightCornerLongitude
        .toString();
    parameters["BottomRightCornerLatitude"] = queryParams
        .bottomRightCornerLatitude
        .toString();

    return Uri.parse(getEventsInBounds)
        .replace(queryParameters: parameters)
        .toString();
  }
}

final ApiClient apiClient = ApiClient(client: AuthAwareHttpClient());
