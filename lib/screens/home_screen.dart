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

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  bool isSearching = false;
  List<Map<String, String>> bookmarkedQuotes = [];
  List<dynamic> quotes = [];
  List<dynamic> filteredQuotes = [];
  List<String> authors = [];
  int currentIndex = 0;
  int skip = 0;
  final FlutterTts flutterTts = FlutterTts();
  final TextEditingController searchController = TextEditingController();
  
  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Gradient colors for quotes
  final List<List<Color>> gradients = [
    [const Color(0xFF667eea), const Color(0xFF764ba2)],
    [const Color(0xFF11998e), const Color(0xFF38ef7d)],
    [const Color(0xFFee0979), const Color(0xFFff6a00)],
    [const Color(0xFF4facfe), const Color(0xFF00f2fe)],
    [const Color(0xFFff9a9e), const Color(0xFFfecfef)],
    [const Color(0xFFa8edea), const Color(0xFFfed6e3)],
  ];

  @override
  void initState() {
    super.initState();
    _loadBookmarks();
    _fetchQuotes();
    
    // Initialize animations
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  // Your existing methods remain the same
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
      currentIndex = 0;
    });
  }

  void _bookmarkQuote(String quote, String author) {
    final alreadyBookmarked = bookmarkedQuotes.any((item) => item['quote'] == quote);
    if (alreadyBookmarked) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("This quote is already bookmarked!"),
          backgroundColor: Colors.orange.withOpacity(0.8),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      setState(() {
        bookmarkedQuotes.add({"quote": quote, "author": author});
      });
      _saveBookmarks();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Quote has been bookmarked!"),
          backgroundColor: Colors.green.withOpacity(0.8),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _removeBookmark(String quote) {
    setState(() {
      bookmarkedQuotes.removeWhere((item) => item['quote'] == quote);
    });
    _saveBookmarks();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("Quote has been removed from bookmarks!"),
        backgroundColor: Colors.red.withOpacity(0.8),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
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
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 15),
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  "Share quote as",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                child: GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    _shareQuoteAsText();
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                      ),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.text_fields, color: Colors.white),
                        SizedBox(width: 10),
                        Text(
                          "Share as Text",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
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

  void _nextQuote() {
    if (currentIndex < filteredQuotes.length - 1) {
      setState(() {
        currentIndex++;
      });
      _fadeController.reset();
      _slideController.reset();
      _fadeController.forward();
      _slideController.forward();
    }
  }

  void _previousQuote() {
    if (currentIndex > 0) {
      setState(() {
        currentIndex--;
      });
      _fadeController.reset();
      _slideController.reset();
      _fadeController.forward();
      _slideController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: isSearching
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: TextField(
                  controller: searchController,
                  autofocus: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: "Search quotes...",
                    hintStyle: TextStyle(color: Colors.white54),
                    border: InputBorder.none,
                    prefixIcon: Icon(Icons.search, color: Colors.white54),
                  ),
                  onChanged: (value) => _filterQuotes(value),
                ),
              )
            : const Text(
                "Daily Quotes",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
        leading: Builder(
          builder: (context) => Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
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
        ),
        actions: [
          Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
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
          ),
        ],
      ),
      drawer: _buildModernDrawer(),
      body: filteredQuotes.isEmpty
          ? Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0D0D0D), Color(0xFF1A1A1A)],
                ),
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                ),
              ),
            )
          : _buildQuoteBody(),
    );
  }

  Widget _buildModernDrawer() {
    return Drawer(
      backgroundColor: const Color(0xFF0D0D0D),
      child: Column(
        children: [
          Container(
            height: 200,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.format_quote,
                    size: 50,
                    color: Colors.white,
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Daily Quotes',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Inspire your day',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(
                  icon: Icons.home,
                  title: 'Home',
                  onTap: () => Navigator.pop(context),
                ),
                _buildDrawerItem(
                  icon: Icons.bookmark,
                  title: 'Bookmarks',
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
                _buildDrawerItem(
                  icon: Icons.person,
                  title: 'Authors',
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
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF667eea), Color(0xFF764ba2)],
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildQuoteBody() {
    final currentGradient = gradients[currentIndex % gradients.length];
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: currentGradient,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: AnimatedBuilder(
                    animation: _fadeAnimation,
                    builder: (context, child) {
                      return SlideTransition(
                        position: _slideAnimation,
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: Container(
                            padding: const EdgeInsets.all(30),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(25),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  child: const Icon(
                                    Icons.format_quote,
                                    color: Colors.white,
                                    size: 30,
                                  ),
                                ),
                                const SizedBox(height: 30),
                                Text(
                                  '"${filteredQuotes[currentIndex]['quote']}"',
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                    height: 1.4,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 25),
                                Text(
                                  '— ${filteredQuotes[currentIndex]['author']}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white.withOpacity(0.9),
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              
              // Navigation buttons
              Container(
                margin: const EdgeInsets.symmetric(vertical: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildNavButton(
                      icon: Icons.arrow_back_ios,
                      onPressed: currentIndex > 0 ? _previousQuote : null,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${currentIndex + 1} / ${filteredQuotes.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    _buildNavButton(
                      icon: Icons.arrow_forward_ios,
                      onPressed: currentIndex < filteredQuotes.length - 1 ? _nextQuote : null,
                    ),
                  ],
                ),
              ),
              
              // Action buttons
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildActionButton(
                      icon: Icons.volume_up,
                      onPressed: _speakQuote,
                    ),
                    _buildActionButton(
                      icon: Icons.share,
                      onPressed: _showShareOptions,
                    ),
                    _buildActionButton(
                      icon: Icons.bookmark_add,
                      onPressed: () {
                        _bookmarkQuote(
                          filteredQuotes[currentIndex]['quote'],
                          filteredQuotes[currentIndex]['author'],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(onPressed != null ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: IconButton(
        icon: Icon(
          icon,
          color: Colors.white.withOpacity(onPressed != null ? 1.0 : 0.5),
        ),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: IconButton(
        icon: Icon(
          icon,
          color: Colors.white,
          size: 24,
        ),
        onPressed: onPressed,
      ),
    );
  }
}

// Keep your existing BookmarkScreen class exactly as it is
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
        title: const Text("Bookmarks"),
        backgroundColor: Colors.orange,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0D0D0D), Color(0xFF1A1A1A)],
          ),
        ),
        child: localBookmarks.isEmpty
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.bookmark_border,
                      size: 80,
                      color: Colors.white24,
                    ),
                    SizedBox(height: 20),
                    Text(
                      "No bookmarks yet!",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      "Start bookmarking your favorite quotes",
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: localBookmarks.length,
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.grey[900]!,
                          Colors.grey[850]!,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                '"${localBookmarks[index]['quote']}"',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  height: 1.4,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              tooltip: "Remove Bookmark",
                              onPressed: () {
                                _removeAndUpdate(localBookmarks[index]['quote']!);
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '— ${localBookmarks[index]['author']!}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}