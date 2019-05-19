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

  PostInfo(
      {this.title, this.isMeta, this.over18, this.id, this.url, this.isVideo});

  factory PostInfo.fromJson(Map<String, dynamic> json) {
    var dataMap = json['data'] as Map<String, dynamic>;
    return new PostInfo(
        title: dataMap['title'] as String,
        isMeta: dataMap['is_meta'] as bool,
        over18: dataMap['over_18'] as bool,
        id: dataMap['id'] as String,
        url: dataMap['url'] as String,
        isVideo: dataMap['is_video'] as bool);
  }
}
