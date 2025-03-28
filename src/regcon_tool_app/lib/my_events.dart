import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
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
  bool isRefreshing = false;
  final ScrollController _scrollController = ScrollController();
  final Color primaryColor = Color(0xFF3A31D8);

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

  Future<void> _refreshEvents() async {
    setState(() {
      isRefreshing = true;
      offset = 0;
      events = [];
      hasMore = true;
    });
    await fetchEvents();
    setState(() {
      isRefreshing = false;
    });
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

    try {
      final response =
          await http.get(url, headers: {'Authorization': 'Bearer $token'});

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['data'] != null && data['data'] is List) {
          setState(() {
            events.addAll(data['data']);
            offset += limit;
            hasMore = data['pagination']?['next_offset'] != null;
          });
        } else {
          print("Error: 'data' es NULL o no es una lista válida");
        }
      } else {
        print("Error en la petición: ${response.statusCode}");
      }
    } catch (e) {
      print("Error en la solicitud HTTP: $e");
    }

    setState(() => isLoading = false);
  }

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'Sin fecha';

    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd MMM yyyy', 'es').format(date);
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          'Mis Eventos',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: primaryColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _refreshEvents,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshEvents,
        color: primaryColor,
        child: events.isEmpty && !isLoading
            ? _buildEmptyState()
            : _buildEventsList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_busy,
            size: 80,
            color: primaryColor.withOpacity(0.5),
          ),
          SizedBox(height: 16),
          Text(
            'No hay eventos disponibles',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Desliza hacia abajo para actualizar',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _refreshEvents,
            icon: Icon(Icons.refresh),
            label: Text('Actualizar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventsList() {
    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.all(16),
      itemCount: events.length + (hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == events.length) {
          return _buildLoadingIndicator();
        }
        final event = events[index];
        return _buildEventCard(event, index);
      },
    );
  }

  Widget _buildEventCard(dynamic event, int index) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              // Navigate to event details
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Event Image
                Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                  ),
                  child: event['image'] != null
                      ? Image.network(
                          event['image'],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Center(
                              child: Icon(
                                Icons.image_not_supported,
                                size: 40,
                                color: primaryColor.withOpacity(0.5),
                              ),
                            );
                          },
                        )
                      : Center(
                          child: Icon(
                            Icons.event,
                            size: 50,
                            color: primaryColor.withOpacity(0.5),
                          ),
                        ),
                ),
                // Event Details
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _formatDate(event['event_date']),
                              style: TextStyle(
                                color: primaryColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          Spacer(),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: Colors.grey[400],
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        event['name'] ?? 'Evento sin nombre',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              event['location'] ?? 'Ubicación desconocida',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if (event['description'] != null) ...[
                        SizedBox(height: 8),
                        Text(
                          event['description'],
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[800],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: Column(
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
              strokeWidth: 3,
            ),
            SizedBox(height: 16),
            Text(
              'Cargando más eventos...',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
