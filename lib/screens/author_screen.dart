import 'package:flutter/material.dart';
import 'quote_screen.dart';

class AuthorScreen extends StatelessWidget {
  final List<String> authors;
  final List<dynamic> quotes;

  const AuthorScreen({super.key, required this.authors, required this.quotes});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Authors"),
        backgroundColor: Colors.orange,
      ),
      body: authors.isEmpty
          ? const Center(
        child: Text(
          "No authors found!",
          style: TextStyle(color: Colors.white70),
        ),
      )
          : ListView.builder(
        itemCount: authors.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Card(
              color: Colors.grey[900],
              child: ListTile(
                title: Text(
                  authors[index],
                  style: const TextStyle(
                    color: Colors.orange,
                    fontSize: 18,
                  ),
                ),
                onTap: () {
                  // Navigate to QuoteScreen with the selected author's quotes
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => QuoteScreen(
                        author: authors[index],
                        quotes: quotes
                            .where((quote) => quote['author'] == authors[index])
                            .toList(),
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
      backgroundColor: Colors.black,
    );
  }
}
