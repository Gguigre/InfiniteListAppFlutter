import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'dart:async'; // Import nécessaire pour utiliser Timer

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
  final ScrollController _scrollController = ScrollController();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchMoreData();
      _startAutoScroll();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scrollController.dispose();
    super.dispose();
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

  void _startAutoScroll() {
    _timer = Timer.periodic(Duration(seconds: 5), (timer) {
      if (_scrollController.position.pixels <
          _scrollController.position.maxScrollExtent) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(seconds: 1),
          curve: Curves.easeInOut,
        );
      } else if (!_isLoading) {
        _fetchMoreData();
      }
    });
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
          controller: _scrollController,
          itemCount: _items.length + 1,
          itemBuilder: (context, index) {
            if (index == _items.length) {
              return Center(
                child: _isLoading
                    ? CircularProgressIndicator()
                    : Text('No more items'),
              );
            }
            return Row(
              children: [
                Image.network("https://picsum.photos/id/$index/100/100",
                    width: 100, height: 100),
                Text('Image by ${_items[index]['author']}'),
              ],
            );
          },
        ),
      ),
    );
  }
}
