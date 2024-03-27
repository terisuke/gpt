import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  await dotenv.load(fileName: '.env');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'エセGPT'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  
  final apiKey = dotenv.env['apiKey'];
  // TextEditingControllerのインスタンスを追加
  final TextEditingController _searchController = TextEditingController();
  List<String> chatHistory = [];
  bool _isLoading = false;
  // String? _apiText;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    // コントローラーを破棄する
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: chatHistory.length,
                    itemBuilder: (context, index) {
                      bool isUserMessage =
                          chatHistory[index].startsWith('User: ');
                      return ListTile(
                        leading: Container(
                          width: 40.0, // アイコンの幅を指定
                          height: 40.0, // アイコンの高さを指定
                          child: Image.asset(
                            isUserMessage
                                ? 'assets/image/person.png'
                                : 'assets/image/robot.png',
                            fit: BoxFit.cover, // 画像がコンテナにフィットするように調整
                          ),
                        ),
                        title: Text(
                          isUserMessage ? chatHistory[index].substring(5): chatHistory[index]),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(30.0,0,30.0,0),
            child: TextField(
              
              controller: _searchController, // コントローラーを設定
              decoration: InputDecoration(
                hintText: '何でも聞いてね！',
              ),
              onChanged: (text) {
                // searchText変数は不要になるため、ここでは何もしない
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.all(30.0),
            child: SizedBox(
              width: 100.0,
              height: 50.0,
              child: ElevatedButton(
                onPressed: () {
                  callAPI();
                },
                child: const Text('Chat'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void callAPI() async {
    setState(() {
      _isLoading = true;
    });
    chatHistory.add('User: ${_searchController.text}');
    final response = await http.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode(<String, dynamic>{
        'model': 'gpt-4-turbo-preview',
        'messages': chatHistory
            .map((message) => {'role': 'user', 'content': message})
            .toList(),
      }),
    );
    if (response.statusCode == 200) {
      final body = response.bodyBytes;
      final jsonString = utf8.decode(body);
      final json = jsonDecode(jsonString);
      final content = json['choices'][0]['message']['content'];
      chatHistory.add('$content'); // APIからの応答をchatHistoryに追加
      setState(() {
        // _apiText = content; // APIからの応答を保持
      });
    } else {
      // エラーハンドリング
      print('Request failed with status: ${response.statusCode}.');
    }
    setState(() {
      _isLoading = false;
      _searchController.clear(); // テキストフィールドをクリア
    });
  }
}
