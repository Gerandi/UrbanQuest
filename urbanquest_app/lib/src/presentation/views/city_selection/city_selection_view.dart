import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
// import 'package:lucide_icons_flutter/lucide_icons.dart';  // Comment out for now
import '../../organisms/top_navigation_bar.dart';
import '../../../core/constants/app_colors.dart';
import '../../templates/app_template.dart';
import '../../../data/services/app_data_service.dart';

class CityData {
  final String id;
  final String name;
  final String description;
  final String coverImageUrl;
  final int questCount;
  final int totalPoints;
  final double difficulty;

  const CityData({
    required this.id,
    required this.name,
    required this.description,
    required this.coverImageUrl,
    required this.questCount,
    required this.totalPoints,
    required this.difficulty,
  });

  factory CityData.fromJson(Map<String, dynamic> json) {
    return CityData(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      coverImageUrl: json['coverImageUrl'] ?? '',
      questCount: json['questCount'] ?? 0,
      totalPoints: json['totalPoints'] ?? 0,
      difficulty: (json['difficulty'] ?? 1.0).toDouble(),
    );
  }
}

class CitySelectionView extends StatefulWidget {
  final Function(AppView, [NavigationData?])? onNavigate;
  final Function(String)? onCitySelected;

  const CitySelectionView({super.key, this.onNavigate, this.onCitySelected});

  @override
  State<CitySelectionView> createState() => _CitySelectionViewState();
}

class _CitySelectionViewState extends State<CitySelectionView> {
  List<CityData> cities = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCities();
  }

  Future<void> _loadCities() async {
    try {
      final appDataService = AppDataService.instance;
      final backendCities = await appDataService.getCities();

      // Convert backend City objects to CityData objects
      final List<CityData> loadedCities = [];
      
      for (final city in backendCities) {
        // Get quest count for each city
        final quests = await appDataService.getQuestsByCity(city.id);
        final questCount = quests.length;
        final totalPoints = quests.fold<int>(0, (sum, quest) => sum + quest.points);
        
        // Calculate average difficulty
        final difficulties = {'Easy': 1.0, 'Medium': 2.0, 'Hard': 3.0};
        final avgDifficulty = quests.isEmpty ? 1.0 : 
          quests.map((q) => difficulties[q.difficulty] ?? 1.0).reduce((a, b) => a + b) / quests.length;

        loadedCities.add(CityData(
          id: city.id,
          name: city.name,
          description: city.description,
          coverImageUrl: city.coverImageUrl ?? 'https://picsum.photos/800/600?random=${city.id.hashCode}',
          questCount: questCount,
          totalPoints: totalPoints,
          difficulty: avgDifficulty,
        ));
      }

      if (mounted) {
      setState(() {
        cities = loadedCities;
        isLoading = false;
      });
      }
    } catch (e) {
      print('Error loading cities: $e');
      if (mounted) {
      setState(() {
          cities = []; // No fallback data - app should be backend-driven
        isLoading = false;
      });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
    return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: AppColors.primaryGradient,
            ),
          ),
          child: const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFfef3f2), // Orange-50
            Color(0xFFfdf2f8), // Pink-50
          ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: TopNavigationBar(
          title: 'Choose Your Adventure',
          onBackPressed: () => widget.onNavigate?.call(AppView.home),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Explore Albania\'s Hidden Gems',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              )
                  .animate()
                  .fadeIn(duration: 600.ms)
                  .slideX(begin: -0.3, end: 0),

              const SizedBox(height: 8),

              Text(
                'Each city tells a unique story. Choose your next adventure and discover the beauty, history, and culture that makes Albania special.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[600],
                ),
              )
                  .animate()
                  .fadeIn(duration: 600.ms, delay: 200.ms)
                  .slideX(begin: -0.3, end: 0),

              const SizedBox(height: 32),

              ...cities.asMap().entries.map((entry) {
                final index = entry.key;
                final city = entry.value;
                return _buildCityCard(city, index)
                    .animate()
                    .fadeIn(duration: 600.ms, delay: (300 + index * 100).ms)
                    .slideY(begin: 0.3, end: 0);
              }),

              const SizedBox(height: 100), // Bottom padding for navigation
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCityCard(CityData city, int index) {
    return GestureDetector(
      onTap: () => widget.onCitySelected?.call(city.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 24),
        decoration: BoxDecoration(
          color: AppColors.whiteOpacity90,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppColors.whiteOpacity30,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.blackOpacity10,
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // City Image
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                child: Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: NetworkImage(city.coverImageUrl),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Container(
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
                ),
              ),
              
              // City name overlay
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      city.name,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 16,
                          color: Colors.white70,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${city.questCount} quest${city.questCount != 1 ? 's' : ''} • ${city.totalPoints} points',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                        const Spacer(),
                        Row(
                          children: List.generate(3, (i) {
                            return Icon(
                              Icons.star,
                              size: 12,
                              color: i < city.difficulty 
                                  ? Colors.amber
                                  : Colors.white.withOpacity(0.3),
                            );
                          }),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          // City Details
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  city.description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    height: 1.5,
                    color: Colors.grey[700],
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Tap anywhere hint
                Row(
                  children: [
                    Icon(
                      Icons.touch_app,
                      size: 16,
                      color: Colors.grey[500],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Tap anywhere to explore',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ));
  }
} 