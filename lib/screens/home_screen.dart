import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:daily_quotes_app/screens/author_screen.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool isSearching = false;
  List<Map<String, String>> bookmarkedQuotes = [];
  List<dynamic> quotes = [];
  List<dynamic> filteredQuotes = [];
  List<String> authors = [];
  int currentIndex = 0;
  int skip = 0;
  final FlutterTts flutterTts = FlutterTts();
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadBookmarks();
    _fetchQuotes();
  }

  Future<void> _loadBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    final bookmarks = prefs.getString('bookmarkedQuotes');
    print("Loaded bookmarks from SharedPreferences: $bookmarks");

    if (bookmarks != null && bookmarks.isNotEmpty) {
      try {
        setState(() {
          bookmarkedQuotes = (json.decode(bookmarks) as List<dynamic>)
              .map((e) => Map<String, String>.from(e as Map))
              .toList();
        });
        print("Bookmarks successfully loaded: $bookmarkedQuotes");
      } catch (e) {
        print("Error decoding bookmarks: $e");
      }
    } else {
      print("No bookmarks found in SharedPreferences.");
    }
  }

  Future<void> _saveBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('bookmarkedQuotes', json.encode(bookmarkedQuotes));
    print("Bookmarks saved: ${json.encode(bookmarkedQuotes)}");
  }


  Future<void> _fetchQuotes() async {
    final url = Uri.parse('https://dummyjson.com/quotes?skip=$skip&limit=30');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          quotes.addAll(data['quotes']);
          filteredQuotes = quotes;
          data['quotes'].forEach((quote) {
            if (!authors.contains(quote['author'])) {
              authors.add(quote['author']);
            }
          });
        });
        if (data['quotes'].length == 30) {
          setState(() {
            skip += 30;
          });
          _fetchQuotes();
        }
      } else {
        throw Exception('Failed to load quotes');
      }
    } catch (error) {
      setState(() {
        quotes = [
          {'quote': 'Error fetching quotes.', 'author': ''},
        ];
        filteredQuotes = quotes;
      });
    }
  }

  void _filterQuotes(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredQuotes = quotes;
      } else {
        filteredQuotes = quotes
            .where((quote) =>
        quote['quote'].toLowerCase().contains(query.toLowerCase()) ||
            quote['author'].toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
      currentIndex = 0; // Reset to the first result after filtering
    });
  }

  void _bookmarkQuote(String quote, String author) {
    final alreadyBookmarked = bookmarkedQuotes.any((item) => item['quote'] == quote);
    if (alreadyBookmarked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("This quote is already bookmarked!"),
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      setState(() {
        bookmarkedQuotes.add({"quote": quote, "author": author});
      });
      _saveBookmarks(); // Save bookmarks to local storage
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Quote has been bookmarked!"),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _removeBookmark(String quote) {
    setState(() {
      bookmarkedQuotes.removeWhere((item) => item['quote'] == quote);
    });
    _saveBookmarks(); // Update the saved bookmarks
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Quote has been removed from bookmarks!"),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _speakQuote() async {
    if (filteredQuotes.isNotEmpty) {
      final quoteText =
          '"${filteredQuotes[currentIndex]['quote']}" by ${filteredQuotes[currentIndex]['author']}';
      await flutterTts.speak(quoteText);
    }
  }

  void _showShareOptions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          color: Colors.black,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  "Share quote as",
                  style: TextStyle(
                    color: Colors.orange,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.text_fields, color: Colors.white),
                        onPressed: () {
                          Navigator.pop(context);
                          _shareQuoteAsText();
                        },
                      ),
                      const Text(
                        "Text",
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _shareQuoteAsText() {
    final String shareText =
        '"${filteredQuotes[currentIndex]['quote']}" By ${filteredQuotes[currentIndex]['author']}';
    Share.share(shareText);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: isSearching
            ? TextField(
          controller: searchController,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: "Search quotes...",
            hintStyle: TextStyle(color: Colors.white54),
            border: InputBorder.none,
          ),
          onChanged: (value) => _filterQuotes(value),
        )
            : const Text("Home"),
        backgroundColor: Colors.orange,
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(isSearching ? Icons.close : Icons.menu),
            onPressed: () {
              if (isSearching) {
                setState(() {
                  isSearching = false;
                  searchController.clear();
                  filteredQuotes = quotes;
                });
              } else {
                Scaffold.of(context).openDrawer();
              }
            },
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(isSearching ? Icons.close : Icons.search),
            tooltip: "Search",
            onPressed: () {
              setState(() {
                isSearching = !isSearching;
                if (!isSearching) {
                  searchController.clear();
                  filteredQuotes = quotes;
                }
              });
            },
          ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: Colors.black,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.orange,
              ),
              child: Text(
                'Menu',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home, color: Colors.orange),
              title: const Text('Home', style: TextStyle(color: Colors.orange)),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.bookmark, color: Colors.orange),
              title: const Text('Bookmark', style: TextStyle(color: Colors.orange)),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BookmarkScreen(
                      bookmarkedQuotes: bookmarkedQuotes,
                      removeBookmark: _removeBookmark,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.person, color: Colors.orange),
              title: const Text('Authors', style: TextStyle(color: Colors.orange)),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AuthorScreen(
                      authors: authors,
                      quotes: quotes,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      body: filteredQuotes.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '"${filteredQuotes[currentIndex]['quote']}"',
                style: const TextStyle(
                  fontSize: 24,
                  fontStyle: FontStyle.italic,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Text(
                '- ${filteredQuotes[currentIndex]['author']}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: currentIndex > 0
                        ? () {
                      setState(() {
                        currentIndex--;
                      });
                    }
                        : null,
                    child: const Text("Previous"),
                  ),
                  ElevatedButton(
                    onPressed: currentIndex < filteredQuotes.length - 1
                        ? () {
                      setState(() {
                        currentIndex++;
                      });
                    }
                        : null,
                    child: const Text("Next"),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: const Icon(Icons.play_circle_fill, color: Colors.orange),
                    onPressed: _speakQuote,
                  ),
                  IconButton(
                    icon: const Icon(Icons.share, color: Colors.orange),
                    onPressed: _showShareOptions,
                  ),
                  IconButton(
                    icon: const Icon(Icons.bookmark, color: Colors.orange),
                    onPressed: () {
                      _bookmarkQuote(filteredQuotes[currentIndex]['quote'],
                          filteredQuotes[currentIndex]['author']);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      backgroundColor: Colors.black,
    );
  }
}

class BookmarkScreen extends StatefulWidget {
  final List<Map<String, String>> bookmarkedQuotes;
  final Function(String) removeBookmark;

  const BookmarkScreen({super.key, required this.bookmarkedQuotes, required this.removeBookmark});

  @override
  _BookmarkScreenState createState() => _BookmarkScreenState();
}

class _BookmarkScreenState extends State<BookmarkScreen> {
  late List<Map<String, String>> localBookmarks;

  @override
  void initState() {
    super.initState();
    localBookmarks = List.from(widget.bookmarkedQuotes);
  }

  void _removeAndUpdate(String quote) {
    setState(() {
      localBookmarks.removeWhere((item) => item['quote'] == quote);
    });
    widget.removeBookmark(quote);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Bookmark"),
        backgroundColor: Colors.orange,
      ),
      body: localBookmarks.isEmpty
          ? const Center(
        child: Text(
          "No bookmarks yet!",
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
      )
          : ListView.builder(
        itemCount: localBookmarks.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(10),
              ),
              child: ListTile(
                title: Text(
                  '"${localBookmarks[index]['quote']}"',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
                subtitle: Text(
                  localBookmarks[index]['author']!,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white70,
                  ),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  tooltip: "Remove Bookmark",
                  onPressed: () {
                    _removeAndUpdate(localBookmarks[index]['quote']!);
                  },
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
