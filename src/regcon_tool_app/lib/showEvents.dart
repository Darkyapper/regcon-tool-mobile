import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

class ShowEventsScreen extends StatefulWidget {
  const ShowEventsScreen({super.key});

  @override
  _ShowEventsScreenState createState() => _ShowEventsScreenState();
}

class _ShowEventsScreenState extends State<ShowEventsScreen> {
  List<dynamic> events = [];
  bool isLoading = true;
  bool isLoadingMore = false;
  int offset = 0;
  final int limit = 10; // Número de eventos por página
  final Dio dio = Dio();
  bool hasMore = true; // Controla si hay más eventos por cargar

  @override
  void initState() {
    super.initState();
    fetchEvents();
  }

  Future<void> fetchEvents() async {
    if (!hasMore) return;

    setState(() {
      isLoading = true;
    });

    try {
      final response = await dio.get(
        'https://recgonback-8awa0rdv.b4a.run/events',
        queryParameters: {'offset': offset, 'limit': limit},
      );

      if (response.statusCode == 200) {
        final data = response.data;

        setState(() {
          events.addAll(data['data']); // Agrega los eventos a la lista
          offset = data['pagination']['next_offset']; // Actualiza el offset
          hasMore = data['data'].length ==
              limit; // Si la longitud es menor al límite, no hay más datos
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load events');
      }
    } catch (e) {
      print('Error fetching events: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> fetchMoreEvents() async {
    if (isLoadingMore || !hasMore) return;

    setState(() {
      isLoadingMore = true;
    });

    try {
      final response = await dio.get(
        'https://recgonback-8awa0rdv.b4a.run/events',
        queryParameters: {'offset': offset, 'limit': limit},
      );

      if (response.statusCode == 200) {
        final data = response.data;

        setState(() {
          events.addAll(data['data']);
          offset = data['pagination']['next_offset'];
          hasMore = data['data'].length == limit;
          isLoadingMore = false;
        });
      } else {
        throw Exception('Failed to load more events');
      }
    } catch (e) {
      print('Error fetching more events: $e');
      setState(() {
        isLoadingMore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Eventos Registrados'),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : events.isEmpty
              ? Center(child: Text('No se encontraron eventos.'))
              : NotificationListener<ScrollNotification>(
                  onNotification: (ScrollNotification scrollInfo) {
                    if (scrollInfo.metrics.pixels ==
                            scrollInfo.metrics.maxScrollExtent &&
                        !isLoadingMore) {
                      fetchMoreEvents();
                    }
                    return false;
                  },
                  child: ListView.builder(
                    itemCount: events.length + (isLoadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == events.length) {
                        return Center(child: CircularProgressIndicator());
                      }
                      final event = events[index];
                      return Card(
                        margin: EdgeInsets.all(8.0),
                        child: ListTile(
                          leading: Icon(Icons.event),
                          title: Text(event['name'] ?? 'Sin nombre'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(event['event_date'] ?? 'Sin fecha'),
                              Text(event['location'] ?? 'Sin ubicación'),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
