import 'dart:async';
import 'dart:convert';
import 'dart:collection';

import 'package:bloc/bloc.dart';
import 'package:looper_tv/bloc/bloc.dart';
import 'package:looper_tv/bloc/post.dart';
import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';
import 'package:rxdart/rxdart.dart';

import 'model/post_data.dart';

class PostBloc extends Bloc<PostEvent, PostState> {
  final http.Client httpClient;
  Queue<String> topicQueue = new Queue();
  List<String> topicList = [
    'BetterEveryLoop',
    'blackmagicfuckery',
    'Damnthatsinteresting',
    'interestingasfuck',
    'oddlysatisfying'
  ];

  PostBloc({@required this.httpClient});

  @override
  PostState get initialState => PostUninitialized();

  @override
  Stream<PostState> mapEventToState(PostEvent event) async* {
    if (event is Fetch) {
      try {
        if (currentState is PostUninitialized) {
          final posts = await _fetchPosts();
          yield PostLoaded(posts: posts, hasReachedMax: false);
          return;
        } else if (currentState is PostLoaded) {
          final posts = await _fetchPosts();
          yield posts.isEmpty
              ? (currentState as PostLoaded).copyWith(hasReachedMax: true)
              : PostLoaded(
                  posts: (currentState as PostLoaded).posts + posts,
                  hasReachedMax: false,
                );
        }
      } catch (_) {
        yield PostError();
      }
    }
  }

  @override
  Stream<PostEvent> transform(Stream<PostEvent> events) {
    return super.transform((events as Observable<PostEvent>)
        .debounce(Duration(milliseconds: 700)));
  }

  Future<List<Post>> _fetchPosts() async {
    if (topicQueue.isEmpty) {
      topicList.shuffle();
      topicQueue.addAll(topicList);
    }
    String topic = topicQueue.removeFirst();
    topicQueue.addLast(topic);
    final response = await httpClient
        .get("https://www.reddit.com/r/$topic/hot.json?count=50");
    print(response);
    if (response.statusCode == 200) {
      JsonResponse jsonResponse =
          JsonResponse.fromJson(json.decode(response.body));
      print(jsonResponse.kind);
      return jsonResponse.data.children
          .where((postInfo) => _isUrlDisplayable(postInfo))
          .map((postInfo) => Post(
              id: postInfo.id,
              title: postInfo.title,
              url: postInfo.url,
              isVideo: postInfo.isVideo,
              height: postInfo.height,
              width: postInfo.width))
          .toList();
    } else {
      throw Exception('error fetching posts');
    }
  }

  bool _isUrlDisplayable(PostInfo postInfo) {
    if (postInfo.textOnly) {
      return false;
    }
    var uri = Uri.parse(postInfo.url);
    if (uri.host == 'gfycat.com') {
      return false;
    }
    return true;
  }
}
