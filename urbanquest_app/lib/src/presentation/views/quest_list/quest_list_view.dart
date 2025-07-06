import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
// import 'package:lucide_icons_flutter/lucide_icons.dart';  // Comment out for now
import '../../organisms/top_navigation_bar.dart';
import '../../molecules/quest_card.dart';
import '../../../data/models/quest_model.dart';
import '../../../data/repositories/quest_repository.dart';
import '../../../core/constants/app_colors.dart';
import '../../templates/app_template.dart';

enum QuestSortBy { name, duration, difficulty, rating, newest }
enum QuestFilterBy { all, easy, medium, hard }

class QuestListView extends StatefulWidget {
  final String cityId;
  final String cityName;
  final Function(AppView, [NavigationData?])? onNavigate;
  final Function(String)? onQuestSelected;

  const QuestListView({
    super.key,
    required this.cityId,
    required this.cityName,
    this.onNavigate,
    this.onQuestSelected,
  });

  @override
  State<QuestListView> createState() => _QuestListViewState();
}

class _QuestListViewState extends State<QuestListView> {
  QuestSortBy _sortBy = QuestSortBy.rating;
  QuestFilterBy _filterBy = QuestFilterBy.all;
  String _searchQuery = '';
  List<Quest> _quests = [];
  bool _isLoading = true;
  String? _errorMessage;
  final TextEditingController _searchController = TextEditingController();
  final QuestRepository _questRepository = QuestRepository();

  @override
  void initState() {
    super.initState();
    _loadQuests();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadQuests() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final quests = await _questRepository.getQuestsByCity(widget.cityId);

      if (mounted) {
      setState(() {
          _quests = quests;
        _isLoading = false;
      });
      }
    } catch (e) {
      print('Error loading quests: $e');
      if (mounted) {
      setState(() {
          _quests = [];
        _isLoading = false;
          _errorMessage = 'Failed to load quests. Please check your connection and try again.';
      });
    }
  }
  }

  Future<void> _searchQuests(String query) async {
    if (query.isEmpty) {
      await _loadQuests();
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await _questRepository.searchQuests(query);
      
      if (mounted) {
        setState(() {
          _quests = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error searching quests: $e');
      if (mounted) {
        setState(() {
          _quests = [];
          _isLoading = false;
          _errorMessage = 'Search failed. Please try again.';
        });
      }
    }
  }

  List<Quest> _getFilteredAndSortedQuests() {
    List<Quest> filtered = _quests.where((quest) {
      bool matchesSearch = _searchQuery.isEmpty ||
          quest.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          quest.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          quest.category.toLowerCase().contains(_searchQuery.toLowerCase());

      bool matchesFilter = true;
      switch (_filterBy) {
        case QuestFilterBy.easy:
          matchesFilter = quest.difficulty == 'Easy';
          break;
        case QuestFilterBy.medium:
          matchesFilter = quest.difficulty == 'Medium';
          break;
        case QuestFilterBy.hard:
          matchesFilter = quest.difficulty == 'Hard';
          break;
        case QuestFilterBy.all:
        default:
          matchesFilter = true;
      }

      return matchesSearch && matchesFilter;
    }).toList();

    // Sort quests
    switch (_sortBy) {
      case QuestSortBy.name:
        filtered.sort((a, b) => a.title.compareTo(b.title));
        break;
      case QuestSortBy.duration:
        filtered.sort((a, b) => a.estimatedDuration.compareTo(b.estimatedDuration));
        break;
      case QuestSortBy.difficulty:
        filtered.sort((a, b) => _getDifficultyValue(a.difficulty).compareTo(_getDifficultyValue(b.difficulty)));
        break;
      case QuestSortBy.rating:
        filtered.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case QuestSortBy.newest:
        filtered.sort((a, b) => b.completions.compareTo(a.completions));
        break;
    }

    return filtered;
  }

  int _getDifficultyValue(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy': return 1;
      case 'medium': return 2;
      case 'hard': return 3;
      default: return 1;
    }
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Quests'),
        content: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Enter quest name or keyword...',
            prefixIcon: Icon(Icons.search),
          ),
          autofocus: true,
          onSubmitted: (value) {
            Navigator.pop(context);
            setState(() {
              _searchQuery = value;
            });
            _searchQuests(value);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _searchQuery = _searchController.text;
              });
              _searchQuests(_searchController.text);
            },
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filter & Sort',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 20),
            Text('Sort by:', style: Theme.of(context).textTheme.titleMedium),
            Wrap(
              spacing: 8,
              children: QuestSortBy.values.map((sort) {
                return ChoiceChip(
                  label: Text(_getSortLabel(sort)),
                  selected: _sortBy == sort,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _sortBy = sort;
                      });
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            Text('Filter by difficulty:', style: Theme.of(context).textTheme.titleMedium),
            Wrap(
              spacing: 8,
              children: QuestFilterBy.values.map((filter) {
                return ChoiceChip(
                  label: Text(_getFilterLabel(filter)),
                  selected: _filterBy == filter,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _filterBy = filter;
                      });
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      setState(() {
                        _sortBy = QuestSortBy.rating;
                        _filterBy = QuestFilterBy.all;
                        _searchQuery = '';
                        _searchController.clear();
                      });
                      Navigator.pop(context);
                      _loadQuests();
                    },
                    child: const Text('Reset'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Apply'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getSortLabel(QuestSortBy sort) {
    switch (sort) {
      case QuestSortBy.name: return 'Name';
      case QuestSortBy.duration: return 'Duration';
      case QuestSortBy.difficulty: return 'Difficulty';
      case QuestSortBy.rating: return 'Rating';
      case QuestSortBy.newest: return 'Newest';
    }
  }

  String _getFilterLabel(QuestFilterBy filter) {
    switch (filter) {
      case QuestFilterBy.all: return 'All';
      case QuestFilterBy.easy: return 'Easy';
      case QuestFilterBy.medium: return 'Medium';
      case QuestFilterBy.hard: return 'Hard';
    }
  }

  Widget _buildCityHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.location_city,
                color: AppColors.primary,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.cityName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${_quests.length} quest${_quests.length != 1 ? 's' : ''} available',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'Something went wrong',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadQuests,
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.explore_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty 
                  ? 'No quests found for "$_searchQuery"'
                  : 'No quests available in ${widget.cityName}',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty 
                  ? 'Try adjusting your search or filters'
                  : 'Check back later for new adventures!',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            if (_searchQuery.isNotEmpty) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _searchQuery = '';
                    _searchController.clear();
                    _filterBy = QuestFilterBy.all;
                  });
                  _loadQuests();
                },
                child: const Text('Clear Search'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
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
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
                SizedBox(height: 16),
                Text(
                  'Loading quests...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ],
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
          title: '${widget.cityName} Quests',
          onBackPressed: () => widget.onNavigate?.call(AppView.citySelection),
          actions: [
            NavigationAction(
              icon: Icons.search,
              onPressed: _showSearchDialog,
            ),
            NavigationAction(
              icon: Icons.tune,
              onPressed: _showFilterBottomSheet,
            ),
          ],
        ),
        body: Column(
          children: [
            // City Header
            _buildCityHeader()
                .animate()
                .fadeIn(duration: 600.ms)
                .slideY(begin: -0.2, end: 0),

            // Search & Filter Indicators
            if (_searchQuery.isNotEmpty || _filterBy != QuestFilterBy.all)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                children: [
                    const Icon(Icons.filter_alt, size: 16, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _buildFilterText(),
                        style: const TextStyle(
                      color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                          ),
                        ),
                    ),
                    InkWell(
                      onTap: () {
                setState(() {
                  _searchQuery = '';
                  _searchController.clear();
                  _filterBy = QuestFilterBy.all;
                });
                        _loadQuests();
              },
                      child: const Icon(Icons.close, size: 16, color: AppColors.primary),
            ),
        ],
      ),
              ),

            // Content
            Expanded(
              child: _errorMessage != null
                  ? _buildErrorState()
                  : _quests.isEmpty 
                      ? _buildEmptyState()
                      : _buildQuestsList(),
            ),
          ],
        ),
      ),
    );
  }

  String _buildFilterText() {
    List<String> filters = [];
    if (_searchQuery.isNotEmpty) filters.add('Search: "$_searchQuery"');
    if (_filterBy != QuestFilterBy.all) filters.add('Difficulty: ${_getFilterLabel(_filterBy)}');
    if (_sortBy != QuestSortBy.rating) filters.add('Sort: ${_getSortLabel(_sortBy)}');
    return filters.join(' • ');
  }

  Widget _buildQuestsList() {
    final filteredQuests = _getFilteredAndSortedQuests();
    
    if (filteredQuests.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadQuests,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        itemCount: filteredQuests.length,
        itemBuilder: (context, index) {
          final quest = filteredQuests[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: QuestCard(
              quest: quest,
              onTap: () => widget.onQuestSelected?.call(quest.id),
            )
                .animate(delay: Duration(milliseconds: index * 100))
                .fadeIn(duration: 600.ms)
                .slideX(begin: 0.2, end: 0),
          );
        },
      ),
    );
  }
} 