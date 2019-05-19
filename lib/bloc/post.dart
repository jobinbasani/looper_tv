import 'package:equatable/equatable.dart';

class Post extends Equatable{
  final String id;
  final String title;
  final String url;
  final bool isVideo;

  Post({this.id,this.title,this.url,this.isVideo}):super([id, title, url, isVideo]);

  @override
  String toString() => 'Post { id: $id}';


}