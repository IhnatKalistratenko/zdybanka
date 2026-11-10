import 'package:client/src/models/event_query.dart';
import 'package:http/http.dart' as http;
import '../models/event_boundary_request.dart';
import '../services/auth_aware_http_client.dart';

class ApiRoutes {
  static final String baseUrl = "http://localhost:5071/api";
  static final String loginRoute = "$baseUrl/Auth/login";
  static final String registerRoute = "$baseUrl/User";
  static final String userRoute = "$baseUrl/User/me";
  static final String tagsRoute = "$baseUrl/Tag";
  static final String createEventRoute = "$baseUrl/Event";
  static final String getEventsRoute = "$baseUrl/Event";
  static final String myEventsRoute = "$baseUrl/Event/me";
  static final String getEventsInBounds = "$baseUrl/Event/in-bounds";
  static String leaveEventRoute(String eventId) =>
      "$baseUrl/Event/$eventId/leave";
  static String userByIdRoute(String id) => "$baseUrl/User/$id";

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
    if(queryParams.userStatus != null) {
      parameters['UserStatus'] = queryParams.userStatus;
    }

    if(queryParams.orderMethod != null && queryParams.orderMethod!.isNotEmpty) {
        parameters['OrderMethod'] = queryParams.orderMethod!.trim();
    }


    return Uri.parse(getEventsRoute)
        .replace(queryParameters: parameters)
        .toString();
  }
  static String buildGetEventsInBoundaries(EventBoundaryRequest queryParams) {
    final parameters = <String, dynamic> {};

    parameters["TopLeftCornerLongitude"] = queryParams.topLeftCornerLongitude.toString();
    parameters["TopLeftCornerLatitude"] = queryParams.topLeftCornerLatitude.toString();
    parameters["BottomRightCornerLongitude"] = queryParams.bottomRightCornerLongitude.toString();
    parameters["BottomRightCornerLatitude"] = queryParams.bottomRightCornerLatitude.toString();

    return Uri.parse(getEventsInBounds).replace(queryParameters: parameters).toString();
  }
}

final http.Client httpClient = AuthAwareHttpClient();
