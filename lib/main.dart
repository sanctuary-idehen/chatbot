import 'package:chatbot_app/chatbotpage.dart';
import 'package:flutter/material.dart';
import 'camera_preview.dart';
import 'face_recognition.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Sancho's ChatBot",
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        cardColor: Colors.white,
        useMaterial3: true,
            ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

 

  @override
  
  Widget build(BuildContext context) {
   return Scaffold(
      appBar: AppBar(
       title: const Text("Chatbot with facial recognition authentication feature"),
      ),
      body: Center(
        
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children:[
            ElevatedButton(
              onPressed: (){
                Navigator.push(
                  context, 
                  MaterialPageRoute(builder: (context) => const FaceRecognitionPage()),
                );
              }
            , child: const Text("Login")),
            SizedBox(height: 10),
           
          ] 
          
          ), 
      ),
   );
   }
   }