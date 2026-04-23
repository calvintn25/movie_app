import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/movie_provider.dart';
import 'views/home_view.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => MovieProvider()..fetchMovies(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MovieNest',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
      ),
      home: const HomeView(),
    );
  }
}
