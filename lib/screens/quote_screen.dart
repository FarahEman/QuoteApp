import 'package:flutter/material.dart';

class QuoteScreen extends StatelessWidget {
  final String author;
  final List<dynamic> quotes;

  const QuoteScreen({super.key, required this.author, required this.quotes});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(author),
        backgroundColor: Colors.orange,
      ),
      body: quotes.isEmpty
          ? Center(
        child: Text(
          "No quotes found for $author!",
          style: const TextStyle(color: Colors.white70),
        ),
      )
          : ListView.builder(
        itemCount: quotes.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              color: Colors.grey[900],
              child: ListTile(
                title: Text(
                  '"${quotes[index]['quote']}"',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
          );
        },
      ),
      backgroundColor: Colors.black,
    );
  }
}
