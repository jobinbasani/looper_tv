import 'package:equatable/equatable.dart';

class Post extends Equatable {
  final String id;
  final String title;
  final String url;
  final bool isVideo;
  final double height;
  final double width;

  Post({this.id, this.title, this.url, this.isVideo, this.height, this.width})
      : super([id, title, url, isVideo, height, width]);

  @override
  String toString() => 'Post { id: $id}';
}
