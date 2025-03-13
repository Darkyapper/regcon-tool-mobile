import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'shared_prefs.dart';

class MyEventsPage extends StatefulWidget {
  const MyEventsPage({super.key});

  @override
  _MyEventsPageState createState() => _MyEventsPageState();
}

class _MyEventsPageState extends State<MyEventsPage> {
  List events = [];
  int offset = 0;
  final int limit = 10;
  bool isLoading = false;
  bool hasMore = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    fetchEvents();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 100) {
        fetchEvents();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> fetchEvents() async {
    if (isLoading || !hasMore) return;
    setState(() => isLoading = true);

    final token = await SharedPrefs.getToken();
    final workgroupId = await SharedPrefs.getWorkgroupId();

    if (token == null || workgroupId == null) {
      setState(() {
        events = [];
        isLoading = false;
      });
      return;
    }

    final url = Uri.parse(
        'https://recgonback-8awa0rdv.b4a.run/my-events?workgroup_id=$workgroupId&limit=$limit&offset=$offset');

    final response =
        await http.get(url, headers: {'Authorization': 'Bearer $token'});

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        events.addAll(data['data']);
        offset += limit;
        hasMore = data['pagination']['next_offset'] != null;
      });
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mis Eventos'),
      ),
      body: ListView.builder(
        controller: _scrollController,
        itemCount: events.length + (hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == events.length) {
            return isLoading
                ? Center(child: CircularProgressIndicator())
                : SizedBox();
          }
          final event = events[index];
          return Card(
            margin: EdgeInsets.all(10),
            child: ListTile(
              leading: Image.network(event['image'],
                  width: 50, height: 50, fit: BoxFit.cover),
              title: Text(event['name']),
              subtitle:
                  Text('${event['location']}\nFecha: ${event['event_date']}'),
              isThreeLine: true,
            ),
          );
        },
      ),
    );
  }
}
