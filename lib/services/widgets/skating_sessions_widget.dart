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

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:skating_times/services/edmonton/edmonton_skating_service.dart';
import 'package:skating_times/services/skating_service.dart';
import 'package:url_launcher/url_launcher.dart';

class SkatingSessionsStateWidget extends StatefulWidget {
  @override
  createState() => new SkatingSessionState();
}

class SkatingSessionState extends State<SkatingSessionsStateWidget> {
  final SkatingSessionService service = new EdmontonSkatingSessionsService();

  final _loadDisplaySessionsPer = 48;
  final _displaySessions = <ImmutableSkatingSession>[];
  final _saved = new Set<ImmutableSkatingSession>();

  final _titleFont = const TextStyle(fontSize: 20.0);
  final _hourFont = new TextStyle(fontSize: 28.0);

  Future<List<ImmutableSkatingSession>> currentlyLoading;

  @override
  Widget build(BuildContext context) {
    if (_displaySessions.isEmpty) {
      _loadMoreAndUpdateUi();
    }
    return new Scaffold (
      appBar: new AppBar(
        title: new Text('Skating sessions'),
        actions: <Widget>[
          new IconButton(icon: new Icon(Icons.list), onPressed: _pushSaved),
        ],
        ),
      body: _displaySessions.isEmpty
            ? new Center(child: new CircularProgressIndicator())
            : new RefreshIndicator(
        child: _buildDisplayList(context, _displaySessions),
        onRefresh: () => _loadMoreAndUpdateUi(reset: true),
        ),
      );
  }

  Future<List<ImmutableSkatingSession>> _loadMoreAndUpdateUi({bool reset}) {
    if (reset == null) reset = false;

    final length = _displaySessions.length;
    if (reset) {
      _displaySessions.clear();
    }
    final startFromIndex = reset ? 0 : length;
    final limit = reset ? length : null; // null = use default
    // @formatter:off
    return _loadIfRequired(startFromIndex: startFromIndex, maxNumberOfSessions: limit)
        .then((sessions) {
          if (!mounted) return [];
          setState(() => _displaySessions.insertAll(startFromIndex, sessions));
          return sessions;
        });
    // @formatter:on
  }

  void _pushSaved() {
    Navigator.of(context).push(
      new MaterialPageRoute(
        builder: (context) {
          final tiles = _saved.map((ImmutableSkatingSession s) {
            return new ListTile(
              title: new Text(
                s.locationDisplayName,
                style: _titleFont,
                ),
              subtitle: new Text(s.formattedTimeStr),
              );
          },);
          final divided = ListTile.divideTiles(
            context: context,
            tiles: tiles,
            ).toList();

          return new Scaffold(
            appBar: new AppBar(title: new Text('Saved sessions')),
            body: new ListView(children: divided),
            );
        },
        ),
      );
  }

  Widget _buildDisplayList(BuildContext context, List<
      ImmutableSkatingSession> sessions) {
    final existingDisplaySessionsLen = sessions.length;
    return new ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(4.0),
        itemCount: existingDisplaySessionsLen * 2 + 1,
        itemBuilder: (context, i) {
          // Mar 4 2018 https://flutter.io/get-started/codelab/#step-4-create-an-infinite-scrolling-listview
          if (i.isOdd) return new Divider();
          final index = i ~/ 2;
          if (index > existingDisplaySessionsLen) {
            return new Container();
          } else if (index == existingDisplaySessionsLen) {
            return new ListTile(
              title: new Center(child: new Text("Load more…")),
              onTap: () => _loadMoreAndUpdateUi(),
              );
          } else {
            return _buildRow(context, sessions[index]);
          }
        });
  }

  Future<List<ImmutableSkatingSession>> _loadIfRequired({
    num startFromIndex,
    num maxNumberOfSessions
  }) {
    if (maxNumberOfSessions == null) maxNumberOfSessions = _loadDisplaySessionsPer;
    if (startFromIndex == null) startFromIndex = 0;

    if (currentlyLoading == null) {
      // @formatter:off
      currentlyLoading = service
          .getSessions(
            minTime: new DateTime.now(),
            maxTime: new DateTime.now().add(new Duration(days: 7)),
            maxNumberOfSessions: maxNumberOfSessions,
            startFromIndex: startFromIndex
          )
          .then((r) {
            currentlyLoading = null;
            return r;
          });
      // @formatter:on
    }
    return currentlyLoading;
  }

  Future _openAddress(String a) async {
    final url = Uri.encodeFull(
        'https://www.google.com/maps/search/?api=1&query=$a');
    if (await canLaunch(url)) {
      return launch(url, forceSafariVC: false, forceWebView: false);
    }
  }

  Widget _buildRow(BuildContext context, ImmutableSkatingSession s) {
    final alreadySaved = _saved.contains(s);
    return new ListTile(
      leading: new Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          new Text(
            new DateFormat('h').format(s.startTime),
            style: _hourFont,
            ),
          new Text(new DateFormat('a').format(s.startTime)),
        ],
        ),
      title: new Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: new Text(s.locationDisplayName, style: _titleFont),
        ),
      subtitle: new RichText(
        text: new TextSpan(
          style: DefaultTextStyle
              .of(context)
              .style,
          children: <TextSpan>[
            new TextSpan(text: s.formattedShortDateStr + ' ',
                             style: new TextStyle(fontWeight: FontWeight.bold,
                                                      color: Theme
                                                          .of(context)
                                                          .primaryColor)),
            new TextSpan(text: s.formattedTimeStrWithoutDate),
          ],
          ),
        ),
      trailing: new Row(
        children: <Widget>[
          new IconButton(
            icon: new Icon(Icons.navigation, color: Theme
                .of(context)
                .accentColor,),
            onPressed: () {
              return _openAddress(s.locationAddress);
            },
            ),
          new IconButton(icon: new Icon(
            alreadySaved
            ? Icons.favorite
            : Icons.favorite_border,
            color: alreadySaved
                   ? Theme
                       .of(context)
                       .accentColor
                   : null,
            ), onPressed: () {
            setState(() {
              if (alreadySaved) {
                _saved.remove(s);
              } else {
                _saved.add(s);
              }
            });
          }),
        ],
        ),
      );
  }
}