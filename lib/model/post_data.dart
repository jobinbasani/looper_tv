class JsonResponse {
  final String kind;
  final Data data;

  JsonResponse({this.kind, this.data});
  factory JsonResponse.fromJson(Map<String, dynamic> json) {
    return new JsonResponse(
        kind: json['kind'] as String, data: Data.fromJson(json['data'] as Map));
  }
}

class Data {
  final String modhash;
  final int dist;
  final List<PostInfo> children;

  Data({this.modhash, this.dist, this.children});

  factory Data.fromJson(Map<String, dynamic> json) {
    return new Data(
        modhash: json['modhash'] as String,
        dist: json['dist'] as int,
        children: (json['children'] as List)
            .map((i) => PostInfo.fromJson(i))
            .toList());
  }
}

class PostInfo {
  final String title;
  final bool isMeta;
  final bool over18;
  final String id;
  final String url;
  final bool isVideo;
  final double height;
  final double width;

  PostInfo(
      {this.title,
      this.isMeta,
      this.over18,
      this.id,
      this.url,
      this.isVideo,
      this.height,
      this.width});

  factory PostInfo.fromJson(Map<String, dynamic> json) {
    var dataMap = json['data'] as Map<String, dynamic>;
    var url = dataMap['url'] as String;
    var isVideo = dataMap['is_video'] as bool;
    var height = 0.0;
    var width = 0.0;
    final RegExp imgurJpgRegex = new RegExp(r"imgur.com/\w+$");
    final RegExp gfycatGifRegex = new RegExp(r"https://gfycat.com/\w+$");
    if (isVideo) {
      var mediaMap = dataMap['media'] as Map<String, dynamic>;
      var redditVideo = mediaMap['reddit_video'] as Map<String, dynamic>;
      var dashUrl = redditVideo['dash_url'] as String;
      if (dashUrl != null) {
        url = dashUrl;
        height = double.parse(redditVideo['height'].toString());
        width = double.parse(redditVideo['width'].toString());
      }
    } else if (url.endsWith(".gifv")) {
      height = double.parse(dataMap['thumbnail_height'].toString());
      width = double.parse(dataMap['thumbnail_width'].toString());
      isVideo = true;
      url = url.replaceAll(".gifv", ".mp4");
    } else if (imgurJpgRegex.hasMatch(url)) {
      url = url + ".jpg";
    } else if (gfycatGifRegex.hasMatch(url)) {
      url = url.replaceAll("gfycat", "thumbs.gfycat") + "-small.gif";
    }
    return new PostInfo(
        title: dataMap['title'] as String,
        isMeta: dataMap['is_meta'] as bool,
        over18: dataMap['over_18'] as bool,
        id: dataMap['id'] as String,
        url: url,
        isVideo: isVideo,
        height: height,
        width: width);
  }
}
