// random_ad_screen.dart
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';

class RandomAdScreen extends StatefulWidget {
  final VoidCallback onSkip;
  final VoidCallback onAdComplete;

  const RandomAdScreen({
    Key? key,
    required this.onSkip,
    required this.onAdComplete,
  }) : super(key: key);

  @override
  _RandomAdScreenState createState() => _RandomAdScreenState();
}

class _RandomAdScreenState extends State<RandomAdScreen>
    with TickerProviderStateMixin {
  int timeLeft = 5;
  bool canSkip = false;
  AdData? selectedAd;
  Timer? skipTimer;
  Timer? adDurationTimer;
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;
  bool isMuted = true;

  final List<AdData> sampleAds = [
    AdData(
      id: 1,
      type: AdType.video,
      title: 'Premium Gaming Experience',
      description: 'Upgrade your gaming with the latest graphics card technology',
      imageUrl: 'https://images.unsplash.com/photo-1542751371-adc38448a05e?w=800&h=600&fit=crop',
      advertiser: 'TechGaming Co.',
      ctaText: 'Learn More',
      duration: 15,
    ),
    AdData(
      id: 2,
      type: AdType.banner,
      title: 'Travel the World',
      description: 'Book your dream vacation with 50% off flights worldwide',
      imageUrl: 'https://images.unsplash.com/photo-1488646953014-85cb44e25828?w=800&h=600&fit=crop',
      advertiser: 'SkyHigh Travel',
      ctaText: 'Book Now',
      duration: 8,
    ),
    AdData(
      id: 3,
      type: AdType.video,
      title: 'Fitness Revolution',
      description: 'Transform your body in 30 days with our proven workout system',
      imageUrl: 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=800&h=600&fit=crop',
      advertiser: 'FitLife Pro',
      ctaText: 'Start Today',
      duration: 12,
    ),
    AdData(
      id: 4,
      type: AdType.banner,
      title: 'Smart Home Solutions',
      description: 'Control your entire home with voice commands and smart automation',
      imageUrl: 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=800&h=600&fit=crop',
      advertiser: 'SmartHome Inc.',
      ctaText: 'Shop Now',
      duration: 6,
    ),
    AdData(
      id: 5,
      type: AdType.video,
      title: 'Food Delivery Pro',
      description: 'Get your favorite meals delivered in 15 minutes or less',
      imageUrl: 'https://images.unsplash.com/photo-1565299624946-b28f40a0ca4b?w=800&h=600&fit=crop',
      advertiser: 'QuickBite',
      ctaText: 'Order Now',
      duration: 10,
    ),
    AdData(
      id: 6,
      type: AdType.banner,
      title: 'Crypto Investment',
      description: 'Start your crypto journey with zero fees for the first month',
      imageUrl: 'https://images.unsplash.com/photo-1621761191319-c6fb62004040?w=800&h=600&fit=crop',
      advertiser: 'CryptoPro',
      ctaText: 'Invest Now',
      duration: 7,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _selectRandomAd();
    _startSkipTimer();
    _initializeProgressAnimation();
    _startAdDurationTimer();
  }

  void _selectRandomAd() {
    final random = Random();
    selectedAd = sampleAds[random.nextInt(sampleAds.length)];
  }

  void _initializeProgressAnimation() {
    if (selectedAd != null) {
      _progressController = AnimationController(
        duration: Duration(seconds: selectedAd!.duration),
        vsync: this,
      );
      _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _progressController, curve: Curves.linear),
      );
      _progressController.forward();
    }
  }

  void _startSkipTimer() {
    skipTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (timeLeft > 0) {
        setState(() {
          timeLeft--;
        });
      } else {
        setState(() {
          canSkip = true;
        });
        timer.cancel();
      }
    });
  }

  void _startAdDurationTimer() {
    if (selectedAd != null) {
      adDurationTimer = Timer(Duration(seconds: selectedAd!.duration), () {
        widget.onAdComplete();
      });
    }
  }

  void _handleSkip() {
    _cleanup();
    widget.onSkip();
  }

  void _handleAdClick() {
    // Add analytics tracking here
    print('Ad clicked: ${selectedAd?.title}');
    // In real app, this would open the advertiser's link
  }

  void _cleanup() {
    skipTimer?.cancel();
    adDurationTimer?.cancel();
    _progressController.dispose();
  }

  @override
  void dispose() {
    _cleanup();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (selectedAd == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Main Ad Content
          Container(
            width: double.infinity,
            height: double.infinity,
            child: Column(
              children: [
                // Ad Image Section
                Expanded(
                  flex: 3,
                  child: Container(
                    width: double.infinity,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Background Image
                        Image.network(
                          selectedAd!.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[800],
                              child: Center(
                                child: Icon(
                                  Icons.image_not_supported,
                                  color: Colors.white,
                                  size: 50,
                                ),
                              ),
                            );
                          },
                        ),
                        
                        // Gradient Overlay
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.7),
                              ],
                            ),
                          ),
                        ),

                        // Video Play Button (for video ads)
                        if (selectedAd!.type == AdType.video)
                          Center(
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.play_arrow,
                                color: Colors.white,
                                size: 40,
                              ),
                            ),
                          ),

                        // Ad Label
                        Positioned(
                          top: 50,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.yellow,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'AD',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Ad Info Section
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.grey[900]!,
                          Colors.black,
                        ],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Advertiser
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Sponsored by ${selectedAd!.advertiser}',
                            style: TextStyle(
                              color: Colors.grey[300],
                              fontSize: 12,
                            ),
                          ),
                        ),
                        
                        SizedBox(height: 12),
                        
                        // Title
                        Text(
                          selectedAd!.title,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        
                        SizedBox(height: 8),
                        
                        // Description
                        Text(
                          selectedAd!.description,
                          style: TextStyle(
                            color: Colors.grey[300],
                            fontSize: 16,
                          ),
                        ),
                        
                        Spacer(),
                        
                        // CTA Button
                        GestureDetector(
                          onTap: _handleAdClick,
                          child: Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.blue[600]!, Colors.purple[600]!],
                              ),
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  selectedAd!.ctaText,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Icon(
                                  Icons.arrow_forward,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Skip Button
          Positioned(
            top: 50,
            right: 20,
            child: canSkip
                ? GestureDetector(
                    onTap: _handleSkip,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.close, color: Colors.white, size: 16),
                          SizedBox(width: 4),
                          Text(
                            'Skip Ad',
                            style: TextStyle(color: Colors.white, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  )
                : Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.access_time, color: Colors.white, size: 16),
                        SizedBox(width: 4),
                        Text(
                          'Skip in ${timeLeft}s',
                          style: TextStyle(color: Colors.white, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
          ),

          // Mute Button (for video ads)
          if (selectedAd!.type == AdType.video)
            Positioned(
              top: 50,
              left: 20,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    isMuted = !isMuted;
                  });
                },
                child: Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isMuted ? Icons.volume_off : Icons.volume_up,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),

          // Progress Bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 4,
              color: Colors.grey[800],
              child: AnimatedBuilder(
                animation: _progressAnimation,
                builder: (context, child) {
                  return Container(
                    height: 4,
                    width: MediaQuery.of(context).size.width * _progressAnimation.value,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue[500]!, Colors.purple[500]!],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Ad Data Model
class AdData {
  final int id;
  final AdType type;
  final String title;
  final String description;
  final String imageUrl;
  final String advertiser;
  final String ctaText;
  final int duration;

  AdData({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.advertiser,
    required this.ctaText,
    required this.duration,
  });
}

enum AdType { video, banner }

// Usage in your splash screen - Add this to your splash_screen.dart:
/*
// In your splash screen timer, replace the navigation to home with:
Timer(Duration(seconds: 3), () {
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (context) => RandomAdScreen(
        onSkip: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomeScreen()),
          );
        },
        onAdComplete: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomeScreen()),
          );
        },
      ),
    ),
  );
});
*/