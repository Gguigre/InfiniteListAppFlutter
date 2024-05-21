import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:cached_network_image/cached_network_image.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Infinite List App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: InfiniteListScreen(),
    );
  }
}

class InfiniteListScreen extends StatefulWidget {
  @override
  _InfiniteListScreenState createState() => _InfiniteListScreenState();
}

class _InfiniteListScreenState extends State<InfiniteListScreen> {
  List<dynamic> _items = [];
  bool _isLoading = false;
  int _page = 1;
  final int _maxItems = 1000;
  final Dio _dio = Dio();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchMoreData();
    });
  }

  Future<void> _fetchMoreData() async {
    if (_isLoading || _items.length >= _maxItems) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final response =
          await _dio.get('https://picsum.photos/v2/list?page=$_page&limit=50');
      if (response.statusCode == 200) {
        setState(() {
          _items.addAll(response.data);
          _page++;
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      print('Error: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Infinite List App'),
      ),
      body: NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification scrollInfo) {
          if (scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent &&
              !_isLoading) {
            _fetchMoreData();
          }
          return false;
        },
        child: ListView.builder(
          itemCount: _items.length + 1,
          itemBuilder: (context, index) {
            if (index == _items.length) {
              return Center(
                child: _isLoading
                    ? CircularProgressIndicator()
                    : Text('No more items'),
              );
            }
            return ListTile(
              leading: CachedNetworkImage(
                imageUrl: _items[index]['download_url'],
                placeholder: (context, url) => CircularProgressIndicator(),
                errorWidget: (context, url, error) => Icon(Icons.error),
              ),
              title: Text('Image by ${_items[index]['author']}'),
            );
          },
        ),
      ),
    );
  }
}
