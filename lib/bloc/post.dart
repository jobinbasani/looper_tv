import 'package:equatable/equatable.dart';

class Post extends Equatable implements Comparable {
  final String id;
  final String title;
  final String url;
  final bool isVideo;
  final double height;
  final double width;

  Post({this.id, this.title, this.url, this.isVideo, this.height, this.width})
      : super([id, title, url, isVideo, height, width]);

  String getMimeType() => isVideo
      ? "video/mpd+mp4"
      : url.endsWith(".gif") ? "image/gif" : "image/jpg";

  String getFileType() =>
      isVideo ? ".mpd" : url.endsWith(".gif") ? ".gif" : "jpg";

  @override
  String toString() => 'Post { Url: $url}';

  @override
  int compareTo(other) {
    return this.id.compareTo((other as Post).id);
  }
}
