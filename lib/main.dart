import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:looper_tv/post_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';

import 'bloc/post.dart';
import 'bloc/post_event.dart';
import 'bloc/post_state.dart';
import 'package:transparent_image/transparent_image.dart';
import 'package:chewie/chewie.dart';
import 'package:random_color/random_color.dart';
import 'package:screen/screen.dart';
import 'package:esys_flutter_share/esys_flutter_share.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

void main() {
  Screen.keepOn(true);
  runApp(new MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
        title: 'Looper TV',
        theme: new ThemeData(
          primarySwatch: Colors.teal,
        ),
        home: HomePage());
  }
}

class HomePage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => new HomePageState();
}

class HomePageState extends State<HomePage> {
  Future checkFirstSeen() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool _seen = (prefs.getBool('seen') ?? false);

    if (_seen) {
      Navigator.of(context).pushReplacement(new MaterialPageRoute(
          builder: (context) => Scaffold(
                appBar: AppBar(
                  title: Text('Looper TV'),
                ),
                body: PostList(),
              )));
    } else {
      prefs.setBool('seen', true);
      Navigator.of(context).pushReplacement(new MaterialPageRoute(
          builder: (context) => Scaffold(
                body: IntroScreen(),
              )));
    }
  }

  @override
  void initState() {
    super.initState();
    new Timer(new Duration(milliseconds: 200), () {
      checkFirstSeen();
    });
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      body: new Center(
        child: new Text('Loading...'),
      ),
    );
  }
}

class IntroScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => IntroState();
}

class IntroState extends State<IntroScreen> {
  Color _bgColor;
  String _textMessage;
  String _buttonMessage;
  List<String> _textMessages = [
    "Things that are amazing, interesting, and incredible!",
    "Clips that get better the longer you watch them!",
    "Pics that offer a very interesting perspective!",
    "A continuous feed of interesting pics and videos!",
    "All set! Let's go!"
  ];

  @override
  void initState() {
    super.initState();
    _bgColor =
        RandomColor().randomColor(colorBrightness: ColorBrightness.veryDark);
    _textMessage = _textMessages.removeAt(0);
    _buttonMessage = "Next";
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _bgColor,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Center(
            child: Container(
              child: Text(
                _textMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'Amatic SC',
                  fontSize: 25.0,
                ),
              ),
              margin: const EdgeInsets.only(left: 10.0, right: 10.0),
            ),
          ),
          Center(
            child: Container(
              child: RaisedButton(
                onPressed: () {
                  if (_textMessages.isNotEmpty) {
                    setState(() {
                      _bgColor = RandomColor().randomColor(
                          colorBrightness: ColorBrightness.veryDark);
                      _textMessage = _textMessages.removeAt(0);
                      if (_textMessages.isEmpty) {
                        _buttonMessage = "Done";
                      }
                    });
                  } else {
                    Navigator.of(context).pushReplacement(new MaterialPageRoute(
                        builder: (context) => Scaffold(
                              appBar: AppBar(
                                title: Text('Looper TV'),
                              ),
                              body: PostList(),
                            )));
                  }
                },
                child: Text(
                  _buttonMessage,
                  style: TextStyle(color: _bgColor),
                ),
              ),
              margin: const EdgeInsets.only(top: 15.0),
            ),
          )
        ],
      ),
    );
  }
}

class PostList extends StatefulWidget {
  PostList({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _PostListState createState() => new _PostListState();
}

class _PostListState extends State<PostList> {
  final _scrollController = new ScrollController();
  final PostBloc _postBloc = PostBloc(httpClient: http.Client());
  final _scrollThreshold = 200.0;

  _PostListState() {
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
            child: SpinKitRipple(color: Colors.teal),
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
  return Card(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        getPostDetails(post),
        ButtonTheme.bar(
          child: Visibility(
            child: ButtonBar(
              children: <Widget>[
                FlatButton(
                    onPressed: () {
                      sharePost(post);
                    },
                    child: const Text(
                      'SHARE',
                      style: TextStyle(color: Colors.white),
                    ))
              ],
            ),
            visible: !post.isVideo,
          ),
        )
      ],
    ),
    color: RandomColor().randomColor(colorBrightness: ColorBrightness.dark),
  );
}

Future sharePost(Post post) async {
  debugPrint(post.url);
  if (post.isVideo) {
    debugPrint("skipping video share");
  } else {
    var request = await HttpClient().getUrl(Uri.parse(post.url));
    var response = await request.close();
    Uint8List bytes = await consolidateHttpClientResponseBytes(response);
    await Share.file(
        'Share', 'looper_tv${post.getFileType()}', bytes, post.getMimeType(),
        text: post.title);
  }
}

Widget getPostDetails(Post post) {
  debugPrint("Url is " + post.url);
  return ListTile(
      contentPadding: EdgeInsets.all(0.0),
      title: Container(
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Text(
            post.title,
            style: TextStyle(
                fontSize: 20.0, fontFamily: 'Bitter', color: Colors.white),
          ),
        ),
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
      child: Center(child: SpinKitRipple(color: Colors.teal)),
    );
  }
}
