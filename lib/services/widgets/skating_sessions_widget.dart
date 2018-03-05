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

import 'package:flutter/material.dart';
import 'package:skating_times/services/edmonton/edmonton_skating_service.dart';
import 'package:skating_times/services/skating_service.dart';

class SkatingSessionsStateWidget extends StatefulWidget {
  @override
  createState() => new SkatingSessionState();
}

class SkatingSessionState extends State<SkatingSessionsStateWidget> {
  final SkatingSessionService service = new EdmontonSkatingSessionsService();

  final _displaySessions = <ImmutableSkatingSession>[];
  final _saved = new Set<ImmutableSkatingSession>();

  final _biggerFont = const TextStyle(fontSize: 18.0);

  @override
  Widget build(BuildContext context) {
    return new Scaffold (
      appBar: new AppBar(
        title: new Text('Skating sessions'),
        actions: <Widget>[
          new IconButton(icon: new Icon(Icons.list), onPressed: _pushSaved),
        ],
      ),
      body: _buildSuggestions(),
    );
  }

  void _pushSaved() {
    Navigator.of(context).push(
      new MaterialPageRoute(
        builder: (context) {
          final tiles = _saved.map((ImmutableSkatingSession s) {
            return new ListTile(
              title: new Text(
                s.locationDisplayName,
                style: _biggerFont,
              ),
            );
          },
          );
          final divided = ListTile.divideTiles(
            context: context,
            tiles: tiles,
          ).toList();

          return new Scaffold(
            appBar: new AppBar(
              title: new Text('Saved Suggestionsz'),
            ),
            body: new ListView(children: divided),
          );
        },
      ),
    );
  }

  Widget _buildSuggestions() {
    return new ListView.builder(
        padding: const EdgeInsets.all(16.0),
        // The itemBuilder callback is called once per suggested word pairing,
        // and places each suggestion into a ListTile row.
        // For even rows, the function adds a ListTile row for the word pairing.
        // For odd rows, the function adds a Divider widget to visually
        // separate the entries. Note that the divider may be difficult
        // to see on smaller devices.
        itemBuilder: (context, i) {
          // Add a one-pixel-high divider widget before each row in theListView.
          if (i.isOdd) return new Divider();

          // The syntax "i ~/ 2" divides i by 2 and returns an integer result.
          // For example: 1, 2, 3, 4, 5 becomes 0, 1, 1, 2, 2.
          // This calculates the actual number of word pairings in the ListView,
          // minus the divider widgets.
          final index = i ~/ 2;
          // If you've reached the end of the available word pairings...
          if (index >= _displaySessions.length) {
            getAndUpdateSessions();
          }
          return _buildRow(_displaySessions[index]);
        }
    );
  }

  getAndUpdateSessions({
    num maxNumberOfSessions,
    String sortBy,
    DateTime maxTime,
  }) async {
    final sessions = await service.getSessions(
      maxNumberOfSessions: maxNumberOfSessions,
      sortBy: sortBy,
      maxTime: maxTime,
    );
    if (!mounted) return;

    setState(() => _displaySessions.addAll(sessions));
  }

  Widget _buildRow(ImmutableSkatingSession s) {
    final alreadySaved = _saved.contains(s);
    return new ListTile(
      title: new Text(
        s.locationDisplayName,
        style: _biggerFont,
      ),
      trailing: new Icon(
        alreadySaved ? Icons.favorite : Icons.favorite_border,
        color: alreadySaved ? Colors.red : null,
      ),
      onTap: () {
        setState(() {
          if (alreadySaved) {
            _saved.remove(s);
          } else {
            _saved.add(s);
          }
        });
      },
    );
  }
}