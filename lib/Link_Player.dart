import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class YoutubePlayerScreen extends StatefulWidget {
  const YoutubePlayerScreen({super.key});

  @override
  _YoutubePlayerScreenState createState() => _YoutubePlayerScreenState();
}

class _YoutubePlayerScreenState extends State<YoutubePlayerScreen> {
  late YoutubePlayerController? _controller;
  final TextEditingController _urlController = TextEditingController();
  bool _isLoading = false;
  String? _currentVideoId;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _controller = null;
  }

  void _initializePlayer(String videoId) {
    _controller = YoutubePlayerController(
      initialVideoId: videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        enableCaption: true,
      ),
    )..addListener(_onPlayerStateChange);
  }

  void _onPlayerStateChange() {
    if (_controller?.value.hasError ?? false) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Error: ${_controller?.value.errorCode ?? ''}';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_errorMessage)),
      );
    } else {
      setState(() {
        _hasError = false;
        _errorMessage = '';
      });
    }
  }

  Future<void> _pasteFromClipboard() async {
    final ClipboardData? clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
    if (clipboardData != null && clipboardData.text != null && clipboardData.text!.isNotEmpty) {
      setState(() {
        _urlController.text = clipboardData.text!;
      });
      _loadVideo();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No valid URL in clipboard')),
      );
    }
  }

  void _loadVideo() async {
    if (_urlController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a YouTube URL')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });
    
    try {
      String url = _urlController.text.trim();
      String? tempVideoId;
      
      // Handle different URL formats
      if (url.contains('youtu.be')) {
        var parts = url.split('youtu.be/');
        if (parts.length > 1) {
          tempVideoId = parts[1];
          if (tempVideoId.contains('?')) {
            tempVideoId = tempVideoId.split('?')[0];
          }
        }
      } else if (url.contains('youtube.com/watch?v=')) {
        tempVideoId = url.split('watch?v=')[1];
        if (tempVideoId.contains('&')) {
          tempVideoId = tempVideoId.split('&')[0];
        }
      } else {
        tempVideoId = YoutubePlayer.convertUrlToId(url);
      }

      if (tempVideoId != null && tempVideoId.isNotEmpty && tempVideoId != _currentVideoId) {
        final String videoId = tempVideoId;
        setState(() {
          _currentVideoId = videoId;
          // Dispose old controller and create new one
          _controller?.dispose();
          _initializePlayer(videoId);
        });
      } else {
        setState(() {
          _hasError = true;
          _errorMessage = 'Invalid YouTube URL';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid YouTube URL')),
        );
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Error loading video: $e';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_errorMessage)),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _clearInput() {
    _urlController.clear();
  }

  @override
  void dispose() {
    _controller?.dispose();
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('YouTube Player'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _urlController,
                      decoration: InputDecoration(
                        hintText: 'Paste YouTube video URL here',
                        border: const OutlineInputBorder(),
                        prefixIcon: IconButton(
                          icon: const Icon(Icons.paste),
                          onPressed: _pasteFromClipboard,
                        ),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.play_arrow),
                          onPressed: _loadVideo,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            AspectRatio(
              aspectRatio: 16 / 9,
              child: _controller != null
                ? YoutubePlayer(
                    controller: _controller!,
                    showVideoProgressIndicator: true,
                    progressIndicatorColor: Colors.red,
                  )
                : Container(
                    color: Colors.grey[300],
                    child: const Center(
                      child: Text('Enter a YouTube URL to play video'),
                    ),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}