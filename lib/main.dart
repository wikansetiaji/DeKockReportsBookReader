import 'package:de_kock_reports_reader/models/book.dart';
import 'package:de_kock_reports_reader/pages/simple_book_reader_page.dart';
import 'package:de_kock_reports_reader/service/size_config.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: SimpleBookReaderPage(book: Book(id: "tjehaja_sijang_1", title: "Tjehaja Sijang", numberOfPage: 4)),
    );
  }
}