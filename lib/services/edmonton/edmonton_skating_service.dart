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

import 'package:intl/intl.dart';
import 'package:skating_times/secret_consts.dart';
import 'package:skating_times/services/skating_service.dart';

class EdmontonSkatingSessionsService implements SkatingSessionService {
  // Mar 4 2018 https://gist.github.com/theburningmonk/6401183
  static final EdmontonSkatingSessionsService _singleton
  = new EdmontonSkatingSessionsService._internal();

  factory EdmontonSkatingSessionsService() {
    return _singleton;
  }

  EdmontonSkatingSessionsService._internal();

  @override
  Future<List<ImmutableSkatingSession>> getSessions({
    num maxNumberOfSessions,
    num startFromIndex,
    String sortBy,
    DateTime minTime,
    DateTime maxTime,
  }) async {
    return _mapJsonArrayToSessions(
        await _getRawJson(
          maxNumberOfSessions: maxNumberOfSessions,
          startFromIndex: startFromIndex,
          sortBy: sortBy,
          minTime: minTime,
          maxTime: maxTime,
        )
    );
  }

  Future<List<dynamic>> _getRawJson({
    num maxNumberOfSessions,
    num startFromIndex,
    String sortBy,
    DateTime minTime,
    DateTime maxTime,
  }) async {
    final url = makeUriStrFrom(
      maxNumberOfSessions: maxNumberOfSessions,
      sortBy: sortBy,
      startFromIndex: startFromIndex,
      minTime: minTime,
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
    num maxNumberOfSessions,
    num startFromIndex,
    String sortBy,
    DateTime minTime,
    DateTime maxTime,
  }) {
    if (sortBy == null) sortBy = 'start_date_time_sort';

    //@formatter:off
    final b = new StringBuffer()
      ..write('https://data.edmonton.ca/resource/jir8-stwr.json?')
      ..write(r'$$app_token=')
      ..write(sodaAppToken);

    if (maxNumberOfSessions != null) {
      b.write('&\$limit=$maxNumberOfSessions');
    }
    
    if (startFromIndex != null) {
      b.write('&\$offset=$startFromIndex');
    }

    if (minTime != null && maxTime != null) {
      final minT = minTime.toIso8601String();
      final maxT = maxTime.toIso8601String();
      b..write(r'&$where=')..write("date between '$minT' and '$maxT'");

    } else if (maxTime != null) {
      b..write(r'&$where=')..write("date<='${maxTime.toIso8601String()}'");
    } else if (minTime != null) {
      b..write(r'&$where=')..write("date>='${minTime.toIso8601String()}'");
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
    final f = new DateFormat('yyyy-MM-dd hh:mm a');

    return json.map((dynamic entry) {
      final dateWithZeroTimeStr = entry['date'] as String;
      final dateStr = dateWithZeroTimeStr.split('T')[0];
      return new ImmutableSkatingSession(
        f.parse('$dateStr ${entry["start_time"]}'),
        f.parse('$dateStr ${entry["end_time"]}'),
        entry['function'],
        entry['complex'],
        entry['address_1'],
      );
    }).toList();
  }

/* Sample JSON from server:
[
   {
      "address_1":"10245 105 Avenue NW",
      "complex":"Downtown Community Arena",
      "date":"2018-03-07T00:00:00.000",
      "end_time":"7:45 AM",
      "function":"Drop In Public Skating - Adult Fitness",
      "start_time":"6:30 AM"
   },
   {
      "address_1":"2051 Leger Road NW",
      "complex":"Terwillegar Subway Arena",
      "date":"2018-03-07T00:00:00.000",
      "end_time":"8:15 AM",
      "function":"Drop In Public Skating - Adult Fitness",
      "start_time":"6:45 AM"
   },
   {
      "address_1":"2704 17 Street NW",
      "complex":"The Meadows Arena",
      "date":"2018-03-07T00:00:00.000",
      "end_time":"8:15 AM",
      "function":"Drop In Public Skating - Adult Fitness",
      "start_time":"6:45 AM"
   },
   {
      "address_1":"3804 139 Avenue NW",
      "complex":"Clareview Arena",
      "date":"2018-03-07T00:00:00.000",
      "end_time":"8:15 AM",
      "function":"Drop In Public Skating - Adult Fitness",
      "start_time":"6:45 AM"
   },
   {
      "address_1":"2704 17 Street NW",
      "complex":"The Meadows Arena",
      "date":"2018-03-07T00:00:00.000",
      "end_time":"10:45 AM",
      "function":"Drop In Public Skating - Older Adults",
      "start_time":"9:45 AM"
   },
   {
      "address_1":"2704 17 Street NW",
      "complex":"The Meadows Arena",
      "date":"2018-03-07T00:00:00.000",
      "end_time":"12:00 PM",
      "function":"Drop In Public Skating - Parent and Tots",
      "start_time":"11:00 AM"
   },
   {
      "address_1":"2704 17 Street NW",
      "complex":"The Meadows Arena",
      "date":"2018-03-07T00:00:00.000",
      "end_time":"1:00 PM",
      "function":"Drop In Member Skate Open Skate",
      "start_time":"12:00 PM"
   },
   {
      "address_1":"2704 17 Street NW",
      "complex":"The Meadows Arena",
      "date":"2018-03-07T00:00:00.000",
      "end_time":"2:00 PM",
      "function":"Drop In Public Skating - Parent and Tots",
      "start_time":"1:00 PM"
   }
]
*/
}