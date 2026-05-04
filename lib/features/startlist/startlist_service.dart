
import "../../core/api_client.dart";

class StartListService {
  Future<List<Map<String, dynamic>>> fetchEvents() async {
    final response = await ApiClient.dio.get<dynamic>(
      "/results/start-list/events/",
    );
    final list = (response.data as List<dynamic>?) ?? <dynamic>[];
    return list.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  Future<List<Map<String, dynamic>>> fetchClubs({
    required Map<String, dynamic> event,
  }) async {
    final response = await ApiClient.dio.get<dynamic>(
      "/results/start-list/clubs/",
      queryParameters: _eventParams(event),
    );
    final list = (response.data as List<dynamic>?) ?? <dynamic>[];
    return list.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  Future<List<Map<String, dynamic>>> fetchItems({
    required Map<String, dynamic> event,
    required Map<String, dynamic> club,
  }) async {
    final response = await ApiClient.dio.get<dynamic>(
      "/results/start-list/items/",
      queryParameters: {
        ..._eventParams(event),
        "club_raw": club["club_raw"]?.toString() ?? "",
      },
    );
    final list = (response.data as List<dynamic>?) ?? <dynamic>[];
    return list.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  Future<List<Map<String, dynamic>>> fetchEntries({
    required Map<String, dynamic> event,
    required Map<String, dynamic> club,
    required Map<String, dynamic> item,
  }) async {
    final response = await ApiClient.dio.get<dynamic>(
      "/results/start-list/entries/",
      queryParameters: {
        ..._eventParams(event),
        "club_raw": club["club_raw"]?.toString() ?? "",
        "gender": item["gender"]?.toString() ?? "",
        "stroke": item["stroke"]?.toString() ?? "",
        "distance": item["distance"]?.toString() ?? "",
      },
    );
    final list = (response.data as List<dynamic>?) ?? <dynamic>[];
    return list.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  Map<String, dynamic> _eventParams(Map<String, dynamic> event) {
    return <String, dynamic>{
      "event_title": event["event_title"]?.toString() ?? "",
      "event_location": event["event_location"]?.toString() ?? "",
      "event_date": event["event_date"]?.toString() ?? "",
    };
  }
}
