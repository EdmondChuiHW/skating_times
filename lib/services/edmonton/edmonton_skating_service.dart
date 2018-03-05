/*
 * MIT License
 *
 * Copyright (c) 2018 Edmond Chui
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:skating_times/secret_consts.dart';
import 'package:skating_times/services/skating_service.dart';

class EdmontonSkatingService implements SkatingService {
  // Mar 4 2018 https://gist.github.com/theburningmonk/6401183
  static final EdmontonSkatingService _singleton
  = new EdmontonSkatingService._internal();

  factory EdmontonSkatingService() {
    return _singleton;
  }

  EdmontonSkatingService._internal();

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