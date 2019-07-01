import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:looper_tv/post_bloc.dart';
import 'package:video_player/video_player.dart';

import 'bloc/post.dart';
import 'bloc/post_event.dart';
import 'bloc/post_state.dart';
import 'package:transparent_image/transparent_image.dart';
import 'package:chewie/chewie.dart';
import 'package:random_color/random_color.dart';

void main() {
  runApp(new MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
        title: 'Looper TV',
        theme: new ThemeData(
          primarySwatch: Colors.red,
        ),
        home: Scaffold(
          appBar: AppBar(
            title: Text('Looper TV'),
          ),
          body: HomePage(),
        ));
  }
}

class HomePage extends StatefulWidget {
  HomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _HomePageState createState() => new _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _scrollController = new ScrollController();
  final PostBloc _postBloc = PostBloc(httpClient: http.Client());
  final _scrollThreshold = 200.0;

  _HomePageState() {
    _scrollController.addListener(_onScroll);
    _postBloc.dispatch(Fetch());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder(
      bloc: _postBloc,
      builder: (BuildContext context, PostState state) {
        if (state is PostUninitialized) {
          return Center(
            child: CircularProgressIndicator(),
          );
        }
        if (state is PostError) {
          return Center(
            child: Text("Failed to fetch posts!"),
          );
        }
        if (state is PostLoaded) {
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: ListView.builder(
              itemBuilder: (BuildContext context, int index) {
                return index >= state.posts.length
                    ? BottomLoader()
                    : PostWidget(post: state.posts[index]);
              },
              scrollDirection: Axis.vertical,
              itemCount: state.posts.length + 1,
              controller: _scrollController,
            ),
          );
        }
      },
    );
  }

  @override
  void dispose() {
    _postBloc.dispose();
    super.dispose();
  }

  void _onScroll() {
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    if (maxScroll - currentScroll <= _scrollThreshold) {
      _postBloc.dispatch(Fetch());
    }
  }
}

class PostWidget extends StatelessWidget {
  final Post post;

  const PostWidget({Key key, @required this.post}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return getCard(post);
  }
}

Widget getCard(Post post) {
  Color postColor =
      RandomColor().randomColor(colorBrightness: ColorBrightness.dark);
  return Card(
    child: getPostDetails(post, postColor),
    color: postColor,
  );
}

Widget getPostDetails(Post post, Color postColor) {
  debugPrint("Url is " + post.url);
  return ListTile(
      contentPadding: EdgeInsets.all(0.0),
      title: Container(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            post.title,
            style: TextStyle(
                fontSize: 20.0, fontFamily: 'Bitter', color: Colors.white),
          ),
        ),
        color: postColor,
      ),
      subtitle: post.isVideo
          ? VideoEntry(post: post)
          : FadeInImage.memoryNetwork(
              placeholder: kTransparentImage, image: post.url));
}

class VideoEntry extends StatefulWidget {
  final Post post;

  const VideoEntry({Key key, this.post}) : super(key: key);

  @override
  _VideoEntryState createState() => _VideoEntryState();
}

class _VideoEntryState extends State<VideoEntry> {
  ChewieController _chewieController;
  VideoPlayerController _videoPlayerController;

  @override
  void initState() {
    super.initState();

    _videoPlayerController = VideoPlayerController.network(widget.post.url);
    _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController,
        autoPlay: true,
        aspectRatio: widget.post.width / widget.post.height,
        looping: true,
        autoInitialize: true);
  }

  @override
  Widget build(BuildContext context) {
    return Chewie(
      controller: _chewieController,
    );
  }

  @override
  void dispose() {
    super.dispose();
    _videoPlayerController.dispose();
    _chewieController.dispose();
  }
}

class BottomLoader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      child: Center(
        child: SizedBox(
          width: 33,
          height: 33,
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
          ),
        ),
      ),
    );
  }
}
