import 'dart:async';
import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:looper_tv/bloc/bloc.dart';
import 'package:looper_tv/bloc/post.dart';
import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';

import 'model/post_data.dart';

class PostBloc extends Bloc<PostEvent, PostState> {
  final http.Client httpClient;

  PostBloc({@required this.httpClient});

  @override
  PostState get initialState => PostUninitialized();

  @override
  Stream<PostState> mapEventToState(PostEvent event) async* {
    if (event is Fetch) {
      try {
        if (currentState is PostUninitialized || currentState is PostLoaded) {
          final posts = await _fetchPosts();
          yield PostLoaded(posts: posts);
          return;
        }
      } catch (_) {
        yield PostError();
      }
    }
  }

  Future<List<Post>> _fetchPosts() async {
    final response =
        await httpClient.get('https://www.reddit.com/r/funny/top.json');
    print(response);
    if (response.statusCode == 200) {
      JsonResponse jsonResponse =
          JsonResponse.fromJson(json.decode(response.body));
      print(jsonResponse.kind);
      return jsonResponse.data.children
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
}
