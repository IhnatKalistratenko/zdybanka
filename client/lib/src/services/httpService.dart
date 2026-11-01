import 'dart:convert';

import 'package:client/src/config/http_config.dart';

Future<List> getTags() async
{
  try
  {
    var response = await httpClient.get(Uri.parse(ApiRoutes.tagsRoute));

    final body = json.decode(response.body);

    return body;
  }
  catch(e)
  {
    print(e);
    return [];
  }
}
