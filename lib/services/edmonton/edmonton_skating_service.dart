import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:skating_times/secret_consts.dart';
import 'package:skating_times/services/skating_service.dart';

class EdmontonSkatingService implements SkatingService {
  @override
  Future<Iterable<ImmutableSkatingSession>> getSessions({
    num maxNumberOfSessions, String sortBy, DateTime maxTime
  }) async {
    return _mapJsonArrayToSessions(
        await _getRawJson(
          maxNumberOfSessions: maxNumberOfSessions,
          sortBy: sortBy,
          maxTime: maxTime,
        )
    );
  }

  Future<List<dynamic>> _getRawJson({
    num maxNumberOfSessions,
    String sortBy,
    DateTime maxTime
  }) async {
    final url = makeUriStrFrom(
      maxNumberOfSessions: maxNumberOfSessions,
      sortBy: sortBy,
      maxTime: maxTime,
    );
    final httpClient = new HttpClient();
    final request = await httpClient.getUrl(Uri.parse(url));
    final response = await request.close();
    if (response.statusCode == HttpStatus.OK) {
      final responseBody = await response.transform(UTF8.decoder).join();
      return JSON.decode(responseBody) as List<dynamic>;
    } else {
      throw "HttpStatus not OK, ${response.statusCode}";
    }
  }

  String makeUriStrFrom({
    num maxNumberOfSessions, String sortBy, DateTime minTime, DateTime maxTime
  }) {
    //@formatter:off
    final b = new StringBuffer()
      ..write('https://data.edmonton.ca/resource/jir8-stwr.json?')
      ..write(r'$$app_token=')
      ..write(sodaAppToken);

    if (maxNumberOfSessions != null) {
      b.write('&\$limit=$maxNumberOfSessions');
    }

    if (minTime != null && maxTime != null) {
      final minT = minTime.toIso8601String();
      final maxT = maxTime.toIso8601String();
      b..write(r'&$where=')..write("date between '$minT' and '$maxT'");

    } else if (maxTime != null) {
      b..write(r'&$where=')..write("date<='${maxTime.toIso8601String()}'");
    } else if (minTime != null) {
      b..write(r'&$where=')..write("date>='${maxTime.toIso8601String()}'");
    }

    if (sortBy != null) {
      b..write(r'&$order=')..write(sortBy);
    }

    b.write('&\$select=function,date,start_time,end_time,complex,address_1');
    //@formatter:on
    return b.toString();
  }

  // See below: 'Sample JSON from server'
  Iterable<ImmutableSkatingSession> _mapJsonArrayToSessions(List json) {
    return json.map((dynamic entry) {
      final dateWithZeroTimeStr = entry['date'] as String;
      final dateStr = dateWithZeroTimeStr.split('T')[0];
      return new ImmutableSkatingSession(
        DateTime.parse('$dateStr ${entry["start_time"]}'),
        DateTime.parse('$dateStr ${entry["end_time"]}'),
        entry['function'],
        entry['complex'],
        entry['address_1'],
      );
    });
  }

/* Sample JSON from server:
 [
   {
      "address":"2051 Leger Road NW",
      "arena":"Terwillegar Subway Arena",
      "date":"2018-03-04T00:00:00.000",
      "end":"05:45 PM",
      "start":"04:45 PM",
      "title":"Drop In Public Skating"
   },
   {
      "address":"3804 139 Avenue NW",
      "arena":"Clareview Arena",
      "date":"2018-03-09T00:00:00.000",
      "end":"08:15 AM",
      "start":"06:45 AM",
      "title":"Drop In Public Skating - Adult Fitness"
   },
   {
      "address":"2704 17 Street NW",
      "arena":"The Meadows Arena",
      "date":"2018-03-09T00:00:00.000",
      "end":"08:15 AM",
      "start":"06:45 AM",
      "title":"Drop In Public Skating - Adult Fitness"
   },
   {
      "address":"2704 17 Street NW",
      "arena":"The Meadows Arena",
      "date":"2018-03-04T00:00:00.000",
      "end":"10:15 PM",
      "start":"09:15 PM",
      "title":"Drop In Shinny - Adult"
   },
   {
      "address":"10404 56 Street NW",
      "arena":"Michael Cameron Arena",
      "date":"2018-03-09T00:00:00.000",
      "end":"06:00 PM",
      "start":"05:00 PM",
      "title":"Drop In Public Skating"
   }
] */
}