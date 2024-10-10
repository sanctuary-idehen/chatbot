import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';

class ChatbotPage extends StatefulWidget {
  const ChatbotPage({super.key});

  @override
  State<ChatbotPage> createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage> {
  final TextEditingController _askMeAnything = TextEditingController();
  final List<String> _messages = [];
  GenerativeModel? _model;
  ChatSession? _chatSession;
  stt.SpeechToText _speechToText = stt.SpeechToText();
  FlutterTts _flutterTts = FlutterTts();
  bool _isListening = false;

  Future<void> _requestPermissions() async {
  var status = await Permission.microphone.status;
  if (!status.isGranted) {
    await Permission.microphone.request();
  }
}

@override
void initState() {
  super.initState();
  _requestPermissions();
  _initializeModel();
}

  

  Future<void> _initializeModel() async {
    const apiKey = 'AIzaSyBL-Xg8XHdz1k0889M6WhmSd0QrAQqfp9c'; 
    if (apiKey.isEmpty) {
      print('No API key provided');
      return; 
    }

    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: apiKey,
      generationConfig: GenerationConfig(maxOutputTokens: 100),
    );

    // Start a chat session with initial history
    _chatSession = _model!.startChat(history: [
      Content.text('Hello! How can I assist you today?'),
      Content.model([TextPart('I am here to help you with your questions.')]),
    ]);
  }

  Future<String> getResponseFromGemini(String message) async {
  if (_chatSession == null) {
    return 'Chat initialization failed';
  }

  final content = Content.text(message);
  final response = await _chatSession!.sendMessage(content);

  // Debugging to print the response structure
  print('Response received: $response');

  // Check if response.text is not null before returning
  // Use null-aware operator `?.` to safely access response.text
  return response.text ?? 'No response text available';
}

  void sendMessage(String text) async {
  if (_askMeAnything.text.isNotEmpty) {
    setState(() {
      _messages.insert(0, "You: ${_askMeAnything.text}");
    });

    String userMessage = _askMeAnything.text;
    _askMeAnything.clear();

    try {
      String response = await getResponseFromGemini(userMessage);
      setState(() {
        _messages.insert(0, "Bot: $response");
      });
    } catch (e) {
      setState(() {
        _messages.insert(0, "Bot: Failed to get response. Please try again.");
      });
    }
  }
}

void _listen() async {
  if (!_isListening) {
    bool available = await _speechToText.initialize(
      debugLogging: true,
      onStatus: (val) => print('Status: $val'),
      onError: (val) => print('Error: ${val.errorMsg}'),
    );
    if (!available) {
  print('The device does not support speech recognition');
}
    if (available) {
      setState(() => _isListening = true);
      _speechToText.listen(onResult: (val) {
        setState(() {
          _askMeAnything.text = val.recognizedWords;
        });

        if (val.hasConfidenceRating && val.confidence > 0 && _askMeAnything.text.isNotEmpty) {
          _speechToText.stop();
          setState(() => _isListening = false);
          sendMessage(_askMeAnything.text);
        }
      });
    } else {
      print('Speech recognition not available');
    }
  } else {
    setState(() => _isListening = false);
    _speechToText.stop();
  }
}


  Widget buildTextComposer() {
    return Padding(
      padding: EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _askMeAnything,
              decoration: InputDecoration.collapsed(hintText: 'Ask me anything'),

            ),
          ),
          IconButton(
            onPressed: _listen,
            icon: Icon(Icons.mic),
          ),
          IconButton(onPressed: (){
            if (_askMeAnything.text.isNotEmpty) {
              sendMessage(_askMeAnything.text);
              _askMeAnything.clear();
              
            }
          }, icon: Icon(Icons.send),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ChatBot Demo'),
      ),
      body: Column(
        children: [
          Flexible(
            child: ListView.builder(
              itemCount: _messages.length,
              reverse: true, // Display items in reverse order
              itemBuilder: (context, index) {
                return Align(
                  alignment: _messages[index].startsWith("You:") ? Alignment.centerRight : Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                    child: Text(
                      _messages[index],
                      textAlign: _messages[index].startsWith("You:") ? TextAlign.right : TextAlign.left,
                    ),
                  ),
                );
              },
            ),
          ),
          buildTextComposer(),
        ],
      ),
    );
  }
}

