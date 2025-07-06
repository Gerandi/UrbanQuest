import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../organisms/bottom_navigation_bar.dart';
import '../views/splash/splash_screen.dart';
import '../views/auth/auth_view.dart';
import '../views/home/home_view.dart';
import '../views/city_selection/city_selection_view.dart';
import '../views/quest_list/quest_list_view.dart';
import '../views/quest_detail/quest_detail_view.dart';
import '../views/quest_gameplay/quest_gameplay_view.dart';
import '../views/quest_complete/quest_complete_view.dart';
import '../views/profile/profile_view.dart';
import '../views/leaderboard/leaderboard_view.dart';
import '../../logic/auth_bloc/auth_bloc.dart';
import '../../data/models/quest_model.dart';
import '../../data/repositories/quest_repository.dart'; // Import QuestRepository

enum AppView {
  splash,
  auth,
  home,
  citySelection,
  questList,
  questDetail,
  questGameplay,
  questComplete,
  profile,
  leaderboard,
}

enum BottomNavTab { home, explore, leaderboard, profile }

class NavigationData {
  final String? cityId;
  final String? cityName;
  final String? questId;
  final Map<String, dynamic>? extras;

  const NavigationData({
    this.cityId,
    this.cityName,
    this.questId,
    this.extras,
  });

  NavigationData copyWith({
    String? cityId,
    String? cityName,
    String? questId,
    Map<String, dynamic>? extras,
  }) {
    return NavigationData(
      cityId: cityId ?? this.cityId,
      cityName: cityName ?? this.cityName,
      questId: questId ?? this.questId,
      extras: extras ?? this.extras,
    );
  }
}

class AppTemplate extends StatefulWidget {
  const AppTemplate({super.key});

  @override
  State<AppTemplate> createState() => _AppTemplateState();
}

class _AppTemplateState extends State<AppTemplate> {
  AppView _currentView = AppView.splash;
  BottomNavTab _currentBottomTab = BottomNavTab.home;
  NavigationData _navigationData = const NavigationData();
  final List<NavigationData> _navigationHistory = [];

  @override
  void initState() {
    super.initState();
    _startApp();
  }

  void _startApp() async {
    // SplashScreen now handles the auth check trigger, so we don't need to do it here
    // Just initialize the app template
    print('AppTemplate: App template initialized');
  }

  void _navigateToView(AppView view, [NavigationData? data]) {
    setState(() {
      // Add current view to history for back navigation
      if (_currentView != AppView.splash && _currentView != view) {
        _navigationHistory.add(NavigationData(
          cityId: _navigationData.cityId,
          cityName: _navigationData.cityName,
          questId: _navigationData.questId,
          extras: {..._navigationData.extras ?? {}, 'view': _currentView.toString()},
        ));
      }

      _currentView = view;
      _navigationData = data ?? const NavigationData();

      // Update bottom navigation tab based on view
      switch (view) {
        case AppView.home:
          _currentBottomTab = BottomNavTab.home;
          break;
        case AppView.citySelection:
        case AppView.questList:
        case AppView.questDetail:
          _currentBottomTab = BottomNavTab.explore;
          break;
        case AppView.leaderboard:
          _currentBottomTab = BottomNavTab.leaderboard;
          break;
        case AppView.profile:
          _currentBottomTab = BottomNavTab.profile;
          break;
        default:
          break;
      }
    });
  }

  void _onBottomNavTapped(BottomNavTab tab) {
    switch (tab) {
      case BottomNavTab.home:
        _navigateToView(AppView.home);
        break;
      case BottomNavTab.explore:
        _navigateToView(AppView.citySelection);
        break;
      case BottomNavTab.leaderboard:
        _navigateToView(AppView.leaderboard);
        break;
      case BottomNavTab.profile:
        _navigateToView(AppView.profile);
        break;
    }
  }

  bool _handleBackNavigation() {
    // Handle Android back button
    switch (_currentView) {
      case AppView.splash:
      case AppView.auth:
        return false; // Don't handle back, let system handle (exit app)
      
      case AppView.home:
      case AppView.citySelection:
      case AppView.leaderboard:
      case AppView.profile:
        // On main views, show exit confirmation
        _showExitConfirmation();
        return true;
      
      case AppView.questGameplay:
        // Show quit quest confirmation
        _showQuitQuestConfirmation();
        return true;
      
      default:
        // Navigate back to previous view
        _navigateBack();
        return true;
    }
  }

  void _navigateBack() {
    if (_navigationHistory.isNotEmpty) {
      final previousNav = _navigationHistory.removeLast();
      final previousViewString = previousNav.extras?['view'] as String?;
      
      if (previousViewString != null) {
        final previousView = AppView.values.firstWhere(
          (view) => view.toString() == previousViewString,
          orElse: () => AppView.home,
        );
        
        setState(() {
          _currentView = previousView;
          _navigationData = NavigationData(
            cityId: previousNav.cityId,
            cityName: previousNav.cityName,
            questId: previousNav.questId,
            extras: previousNav.extras,
          );
        });
      } else {
        _navigateToView(AppView.home);
      }
    } else {
      _navigateToView(AppView.home);
    }
  }

  void _showExitConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit Urban Quest?'),
        content: const Text('Are you sure you want to exit the app?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              SystemNavigator.pop();
            },
            child: const Text('Exit'),
          ),
        ],
      ),
    );
  }

  void _showQuitQuestConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quit Quest?'),
        content: const Text('Are you sure you want to quit this quest? Your progress will be saved.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continue Quest'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _navigateToView(AppView.home);
            },
            child: const Text('Quit Quest'),
          ),
        ],
      ),
    );
  }

  bool _shouldShowBottomNav() {
    // Only show bottom nav on main top-level views
    switch (_currentView) {
      case AppView.home:
      case AppView.citySelection:
      case AppView.leaderboard:
      case AppView.profile:
        return true;
      case AppView.questList:
      case AppView.questDetail:
      case AppView.questGameplay:
      case AppView.questComplete:
      case AppView.splash:
      case AppView.auth:
        return false; // Hide for second-level navigation and special views
      default:
        return false;
    }
  }

  Widget _buildCurrentView() {
    switch (_currentView) {
      case AppView.splash:
        return const SplashScreen();
      
      case AppView.auth:
        return const AuthView();
      
      case AppView.home:
        return HomeView(
          onNavigate: _navigateToView,
        );
      
      case AppView.citySelection:
        return CitySelectionView(
          onNavigate: _navigateToView,
          onCitySelected: (cityId, cityName) {
            _navigateToView(
              AppView.questList,
              NavigationData(cityId: cityId, cityName: cityName),
            );
          },
        );
      
      case AppView.questList:
        return QuestListView(
          cityId: _navigationData.cityId ?? '',
          cityName: _navigationData.cityName ?? '',
          onNavigate: _navigateToView,
          onQuestSelected: (questId) {
            _navigateToView(
              AppView.questDetail,
              _navigationData.copyWith(questId: questId),
            );
          },
        );
      
      case AppView.questDetail:
        return QuestDetailView(
          questId: _navigationData.questId ?? '',
          onNavigate: _navigateToView,
          onBack: _navigateBack,
          onStartQuest: (questId) {
            _navigateToView(
              AppView.questGameplay,
              _navigationData.copyWith(questId: questId),
            );
          },
        );
      
      case AppView.questGameplay:
        return QuestGameplayWrapper(
          questId: _navigationData.questId ?? '',
          onNavigate: _navigateToView,
          onQuestComplete: (questId) {
            _navigateToView(
              AppView.questComplete,
              _navigationData.copyWith(questId: questId),
            );
          },
        );
      
      case AppView.questComplete:
        return QuestCompleteView(
          questId: _navigationData.questId ?? '',
          onNavigate: _navigateToView,
        );
      
      case AppView.profile:
        return ProfileView(
          onNavigate: _navigateToView,
        );
      
      case AppView.leaderboard:
        return LeaderboardView(
          onNavigate: _navigateToView,
        );
      
      default:
        return const SplashScreen();
    }
  }


  NavigationTab _mapBottomNavToNavTab(BottomNavTab bottomTab) {
    switch (bottomTab) {
      case BottomNavTab.home:
        return NavigationTab.home;
      case BottomNavTab.explore:
        return NavigationTab.citySelection;
      case BottomNavTab.leaderboard:
        return NavigationTab.leaderboard;
      case BottomNavTab.profile:
        return NavigationTab.profile;
    }
  }

  void _onNavTabChanged(NavigationTab tab) {
    switch (tab) {
      case NavigationTab.home:
        _navigateToView(AppView.home);
        break;
      case NavigationTab.citySelection:
        _navigateToView(AppView.citySelection);
        break;
      case NavigationTab.leaderboard:
        _navigateToView(AppView.leaderboard);
        break;
      case NavigationTab.profile:
        _navigateToView(AppView.profile);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        print('AppTemplate: Auth state changed to ${state.runtimeType}');
        if (state is AuthSuccess) {
          print('AppTemplate: User authenticated, navigating to home');
          _navigateToView(AppView.home);
        } else if ((state is AuthInitial || state is AuthFailure) && _currentView != AppView.auth) {
          print('AppTemplate: User not authenticated, navigating to auth');
          _navigateToView(AppView.auth);
        }
      },
      child: PopScope(
        canPop: false,
        onPopInvoked: (didPop) {
          if (!didPop) {
            _handleBackNavigation();
          }
        },
        child: Scaffold(
          body: _buildCurrentView(),
          bottomNavigationBar: _shouldShowBottomNav()
              ? BottomNavigationBarCustom(
                  currentTab: _mapBottomNavToNavTab(_currentBottomTab),
                  onTabChanged: (tab) => _onNavTabChanged(tab),
                )
              : null,
        ),
      ),
    );
  }
}

// Quest Gameplay Wrapper to load quest data
class QuestGameplayWrapper extends StatefulWidget {
  final String questId;
  final Function(AppView, [NavigationData?]) onNavigate;
  final Function(String) onQuestComplete;

  const QuestGameplayWrapper({
    Key? key,
    required this.questId,
    required this.onNavigate,
    required this.onQuestComplete,
  }) : super(key: key);

  @override
  State<QuestGameplayWrapper> createState() => _QuestGameplayWrapperState();
}

class _QuestGameplayWrapperState extends State<QuestGameplayWrapper> {
  Quest? _quest;
  bool _isLoading = true;
  String? _error;
  final QuestRepository _questRepository = QuestRepository(); // Instantiate QuestRepository

  @override
  void initState() {
    super.initState();
    _loadQuest();
  }

  Future<void> _loadQuest() async {
    try {
      final quest = await _questRepository.getQuestById(widget.questId);
      
      setState(() {
        _quest = quest;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Loading Quest...'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => widget.onNavigate(AppView.questDetail),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Error'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => widget.onNavigate(AppView.questDetail),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Failed to load quest: $_error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => widget.onNavigate(AppView.questDetail),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    return QuestGameplayView(
      quest: _quest!,
      onBack: () => widget.onNavigate(AppView.questDetail),
      onNavigate: widget.onNavigate,
    );
  }
}  