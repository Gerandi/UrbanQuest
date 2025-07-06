import React, { useState, createContext, useContext, useEffect } from 'react';
import { MapPin, Camera, Hash, CheckCircle, Volume2, ArrowLeft, Play, Sun, Moon, LogOut, Video, Compass, Award, Footprints, Droplets, Smartphone, Star, Clock, Users, Trophy, Share2, Heart, MessageCircle, Navigation, Zap, Target, BookOpen, Gift, Medal } from 'lucide-react';

// SVG Background Component
const SVGBackground = ({ isDarkMode }) => (
  <svg width="100%" height="100%" style={{ position: 'fixed', top: 0, left: 0, zIndex: 0 }}>
    <defs>
      <radialGradient id="gradient" cx="50%" cy="50%" r="50%">
        <stop offset="0%" stopColor={isDarkMode ? 'rgba(59, 130, 246, 0.1)' : 'rgba(249, 115, 22, 0.1)'} />
        <stop offset="100%" stopColor="transparent" />
      </radialGradient>
      <pattern id="pattern-dots" x="0" y="0" width="20" height="20" patternUnits="userSpaceOnUse">
        <circle cx="10" cy="10" r="1" fill={isDarkMode ? 'rgba(255, 255, 255, 0.03)' : 'rgba(0, 0, 0, 0.03)'} />
      </pattern>
    </defs>
    <rect width="100%" height="100%" fill="url(#gradient)" />
    <rect width="100%" height="100%" fill="url(#pattern-dots)" />
  </svg>
);

// Enhanced Mock Data
const initialData = {
  users: { 
    'user123': { 
      id: 'user123',
      email: 'explorer@gmail.com', 
      displayName: 'Alex Explorer', 
      avatar: 'https://placehold.co/100x100/3b82f6/FFFFFF?text=AE',
      createdAt: new Date(), 
      completedQuests: ['tirana01'], 
      totalPoints: 850,
      level: 3,
      badges: ['first_quest', 'photo_master', 'trivia_champion'],
      stats: {
        questsCompleted: 3,
        stopsVisited: 12,
        photosShared: 8,
        totalDistance: '4.2 km'
      }
    } 
  },
  quests: {
    'tirana01': { 
      id: 'tirana01', 
      title: "Tirana's Timeless Heart", 
      city: "Tirana", 
      description: "Journey through the core of Albania's capital, uncovering tales from Skanderbeg Square to the bustling New Bazaar.", 
      coverImageUrl: 'https://images.unsplash.com/photo-1612289647225-2a29c3132145?w=600&h=400&fit=crop',
      estimatedDuration: "90 min", 
      difficulty: "Easy", 
      isActive: true, 
      numberOfStops: 5,
      rating: 4.8,
      completions: 1247,
      category: 'History & Culture',
      points: 250,
      tags: ['historic', 'walking', 'culture', 'beginner-friendly']
    },
    'berat01': { 
      id: 'berat01', 
      title: "Berat's Thousand Windows", 
      city: "Berat", 
      description: "Explore the UNESCO World Heritage city of Berat, from its ancient castle to the iconic Mangalem quarter with its distinctive white houses.", 
      coverImageUrl: 'https://images.unsplash.com/photo-1628283833969-53e32e8587b1?w=600&h=400&fit=crop',
      estimatedDuration: "120 min", 
      difficulty: "Medium", 
      isActive: true, 
      numberOfStops: 4,
      rating: 4.9,
      completions: 892,
      category: 'UNESCO Heritage',
      points: 350,
      tags: ['unesco', 'architecture', 'photography', 'moderate']
    },
    'shkoder01': { 
      id: 'shkoder01', 
      title: "The Legend of Rozafa", 
      city: "Shkodër", 
      description: "Uncover the ancient myth of Rozafa Castle and gaze upon the magnificent Lake Shkodra while learning about this legendary tale.", 
      coverImageUrl: 'https://images.unsplash.com/photo-1621334057077-4223c6f0e4b8?w=600&h=400&fit=crop',
      estimatedDuration: "150 min", 
      difficulty: "Hard", 
      isActive: true, 
      numberOfStops: 6,
      rating: 4.7,
      completions: 634,
      category: 'Legends & Myths',
      points: 450,
      tags: ['castle', 'lake', 'legends', 'challenging', 'scenic']
    },
    'durres01': {
      id: 'durres01',
      title: "Ancient Shores of Durrës",
      city: "Durrës",
      description: "Walk through millennia of history from Roman amphitheaters to modern seaside promenades in Albania's ancient port city.",
      coverImageUrl: 'https://images.unsplash.com/photo-1596701062353-8323a076a9a3?w=600&h=400&fit=crop',
      estimatedDuration: "110 min",
      difficulty: "Medium",
      isActive: true,
      numberOfStops: 5,
      rating: 4.6,
      completions: 756,
      category: 'Ancient History',
      points: 300,
      tags: ['roman', 'seaside', 'ancient', 'archaeology']
    }
  },
  questStops: {
    'tirana01': {
      'stop1': { 
        id: 'stop1', 
        order: 1, 
        title: "Skanderbeg Square", 
        location: { lat: 41.3275, lng: 19.8187 }, 
        clue: "Find the city's grand plaza where a national hero on horseback stands eternal guard, surrounded by colorful buildings and fountains.", 
        videoUrl: "mock_video_skanderbeg_history.mp4", 
        challengeType: "TRIVIA", 
        challengeText: "What year was the Skanderbeg Monument inaugurated in this square?", 
        triviaOptions: ["1945", "1968", "1982"], 
        correctAnswer: "1968", 
        infoText: "Perfect! The monument was unveiled in 1968, marking 500 years since Skanderbeg's death. He's Albania's national hero who resisted Ottoman expansion.",
        hints: ["Look for the date on the monument's base", "It was erected during the communist era"],
        points: 50
      },
      'stop2': { 
        id: 'stop2', 
        order: 2, 
        title: "Et'hem Bey Mosque", 
        location: { lat: 41.3279, lng: 19.8194 }, 
        clue: "Near the square, discover a historic mosque famous for its unique frescoes depicting natural scenes - quite unusual for Islamic art.", 
        videoUrl: null, 
        challengeType: "FIND", 
        challengeText: "What is the name of the tall clock tower beside the mosque?", 
        correctAnswer: "Clock Tower", 
        infoText: "Excellent! The Clock Tower (Kulla e Sahatit) was built in 1822 and was once Tirana's tallest structure. You can climb it for panoramic views!",
        hints: ["It's one of Tirana's most recognizable landmarks", "Look up - it's hard to miss!"],
        points: 40
      },
      'stop3': { 
        id: 'stop3', 
        order: 3, 
        title: "National History Museum", 
        location: { lat: 41.3281, lng: 19.8186 }, 
        clue: "Look for the building with the massive colorful mosaic on its facade - it tells the story of Albania's entire history.", 
        videoUrl: "mock_video_museum_tour.mp4", 
        challengeType: "PHOTO", 
        challengeText: "Take a photo of yourself with the iconic mosaic in the background", 
        correctAnswer: "PHOTO_TAKEN", 
        infoText: "Great shot! This mosaic called 'The Albanians' was created by local artists and depicts key moments in Albanian history from ancient Illyrians to modern times.",
        hints: ["The mosaic covers almost the entire front of the building", "It's right on Skanderbeg Square"],
        points: 60
      },
      'stop4': { 
        id: 'stop4', 
        order: 4, 
        title: "Blloku District", 
        location: { lat: 41.3194, lng: 19.8242 }, 
        clue: "Walk to the trendy neighborhood that was once forbidden to ordinary citizens during communist times - now it's the heart of Tirana's nightlife.", 
        videoUrl: null, 
        challengeType: "TRIVIA", 
        challengeText: "During communist rule, who was allowed to live in this exclusive area?", 
        triviaOptions: ["Foreign diplomats", "Party leaders", "University professors"], 
        correctAnswer: "Party leaders", 
        infoText: "Correct! This area was reserved for communist party elite and their families. Today it's filled with cafes, bars, and shops - quite a transformation!",
        hints: ["Think about who had power during the communist era", "It was highly restricted and guarded"],
        points: 45
      },
      'stop5': { 
        id: 'stop5', 
        order: 5, 
        title: "Pazari i Ri (New Bazaar)", 
        location: { lat: 41.3314, lng: 19.8236 }, 
        clue: "Follow the vibrant sounds and aromas to the colorful market under a distinctive diamond-patterned roof where locals shop for fresh produce.", 
        videoUrl: "mock_video_bazaar_experience.mp4", 
        challengeType: "PHOTO", 
        challengeText: "Capture the most colorful display of fruits or vegetables you can find!", 
        correctAnswer: "PHOTO_TAKEN", 
        infoText: "Beautiful! The New Bazaar perfectly represents Tirana's blend of tradition and modernity. It's where locals come for the freshest ingredients and best prices.",
        hints: ["Look for the vendors with the most vibrant displays", "Don't forget to smile at the friendly sellers!"],
        points: 55
      }
    }
  },
  leaderboard: [
    { id: 'user124', name: 'Maria Adventure', points: 1200, avatar: 'https://placehold.co/50x50/ef4444/FFFFFF?text=MA' },
    { id: 'user125', name: 'John Quest', points: 950, avatar: 'https://placehold.co/50x50/10b981/FFFFFF?text=JQ' },
    { id: 'user123', name: 'Alex Explorer', points: 850, avatar: 'https://placehold.co/50x50/3b82f6/FFFFFF?text=AE' },
  ]
};

const AppContext = createContext();

// Main App Component
export default function App() {
  const [data, setData] = useState(initialData);
  const [currentView, setCurrentView] = useState('splash');
  const [currentUser, setCurrentUser] = useState(null);
  const [selectedCity, setSelectedCity] = useState(null);
  const [selectedQuestId, setSelectedQuestId] = useState(null);
  const [activeQuestProgress, setActiveQuestProgress] = useState(null);
  const [isDarkMode, setIsDarkMode] = useState(false);

  const navigate = (view) => setCurrentView(view);
  
  const useBackNavigation = () => {
    switch(currentView) {
      case 'citySelection': return () => navigate('home');
      case 'questList': return () => navigate('citySelection');
      case 'questDetail': return () => navigate('questList');
      case 'gameplay': return () => navigate('questDetail');
      case 'profile': return () => navigate('home');
      case 'leaderboard': return () => navigate('home');
      default: return null;
    }
  };
  const handleBack = useBackNavigation();

  // Auto-transition from splash to login after 3 seconds
  useEffect(() => {
    if (currentView === 'splash') {
      const timer = setTimeout(() => {
        navigate('login');
      }, 3000);
      return () => clearTimeout(timer);
    }
  }, [currentView]);

  const value = { 
    data, 
    navigate, 
    currentUser, 
    setCurrentUser, 
    selectedCity, 
    setSelectedCity, 
    selectedQuestId, 
    setSelectedQuestId, 
    activeQuestProgress, 
    setActiveQuestProgress, 
    isDarkMode, 
    setIsDarkMode, 
    handleBack 
  };

  const ViewRenderer = () => {
    if (currentView === 'splash') return <SplashScreen />;
    if (!currentUser) return <LoginScreen />;
    
    switch(currentView) {
      case 'home': return <HomeScreen />;
      case 'citySelection': return <CitySelectionScreen />;
      case 'questList': return <QuestListScreen />;
      case 'questDetail': return <QuestDetailScreen />;
      case 'gameplay': return <GameplayScreen />;
      case 'questComplete': return <QuestCompleteScreen />;
      case 'profile': return <ProfileScreen />;
      case 'leaderboard': return <LeaderboardScreen />;
      default: return <HomeScreen />;
    }
  };
  
  return (
    <AppContext.Provider value={value}>
      <div className={`${isDarkMode ? 'dark' : ''} font-inter`}>
        <div className="bg-gradient-to-br from-orange-50 to-blue-50 dark:from-gray-900 dark:to-gray-800 text-gray-900 dark:text-gray-100 min-h-screen transition-all duration-500 relative overflow-hidden">
          <SVGBackground isDarkMode={isDarkMode} />
          <div className="relative z-10">
            <ViewRenderer />
          </div>
        </div>
      </div>
    </AppContext.Provider>
  );
}

// Splash Screen
function SplashScreen() {
  return (
    <div className="flex flex-col items-center justify-center min-h-screen bg-gradient-to-br from-orange-500 via-red-500 to-pink-500 text-white">
      <div className="text-center animate-fade-in">
        <div className="relative mb-8">
          <Compass className="h-24 w-24 mx-auto animate-spin text-white drop-shadow-lg" />
          <div className="absolute inset-0 h-24 w-24 mx-auto rounded-full bg-white/20 animate-pulse"></div>
        </div>
        <h1 className="text-5xl font-black mb-2 tracking-tight">Urban Quest</h1>
        <p className="text-xl font-light opacity-90 tracking-wide">Discover • Explore • Adventure</p>
        <div className="mt-8 w-16 h-1 bg-white/60 mx-auto rounded-full animate-pulse"></div>
      </div>
    </div>
  );
}

// Enhanced Navigation Bar
function TopNavBar() {
  const { setIsDarkMode, isDarkMode, setCurrentUser, handleBack, navigate } = useContext(AppContext);
  const showBackButton = !!handleBack;

  return (
    <header className="p-4 flex justify-between items-center sticky top-0 z-30 bg-white/80 dark:bg-gray-900/80 backdrop-blur-xl border-b border-gray-200/50 dark:border-gray-700/50">
      {showBackButton ? 
        <button onClick={handleBack} className="p-3 rounded-2xl bg-white/90 dark:bg-gray-800/90 shadow-lg hover:shadow-xl transition-all duration-300 hover:scale-105">
          <ArrowLeft size={20}/>
        </button> 
        : <div className="w-12"></div>
      }
      <h1 className="text-lg font-bold bg-gradient-to-r from-orange-500 to-red-500 bg-clip-text text-transparent">
        Urban Quest
      </h1>
      <div className="flex items-center gap-2">
        <button 
          onClick={() => setIsDarkMode(!isDarkMode)} 
          className="p-3 rounded-2xl bg-white/90 dark:bg-gray-800/90 shadow-lg hover:shadow-xl transition-all duration-300 hover:scale-105"
        >
          {isDarkMode ? <Sun size={20} className="text-amber-500" /> : <Moon size={20} className="text-slate-600" />}
        </button>
        <button 
          onClick={() => { setCurrentUser(null); navigate('login'); }} 
          className="p-3 rounded-2xl bg-white/90 dark:bg-gray-800/90 shadow-lg hover:shadow-xl transition-all duration-300 hover:scale-105"
        >
          <LogOut size={20} className="text-red-500" />
        </button>
      </div>
    </header>
  );
}

// Bottom Navigation
function BottomNavigation() {
  const { navigate, currentView } = useContext(AppContext);
  
  const navItems = [
    { id: 'home', icon: Compass, label: 'Explore' },
    { id: 'citySelection', icon: MapPin, label: 'Cities' },
    { id: 'leaderboard', icon: Trophy, label: 'Leaderboard' },
    { id: 'profile', icon: Users, label: 'Profile' }
  ];

  return (
    <nav className="fixed bottom-0 left-0 right-0 bg-white/95 dark:bg-gray-900/95 backdrop-blur-xl border-t border-gray-200/50 dark:border-gray-700/50 px-4 py-2 z-30">
      <div className="flex justify-around items-center">
        {navItems.map(({ id, icon: Icon, label }) => (
          <button
            key={id}
            onClick={() => navigate(id)}
            className={`flex flex-col items-center p-3 rounded-2xl transition-all duration-300 ${
              currentView === id 
                ? 'bg-gradient-to-t from-orange-500 to-red-500 text-white shadow-lg scale-105' 
                : 'text-gray-600 dark:text-gray-400 hover:text-orange-500 dark:hover:text-orange-400'
            }`}
          >
            <Icon size={20} />
            <span className="text-xs mt-1 font-medium">{label}</span>
          </button>
        ))}
      </div>
    </nav>
  );
}

// Login Screen
function LoginScreen() {
  const { navigate, setCurrentUser, data } = useContext(AppContext);
  const handleLogin = () => {
    setCurrentUser(data.users['user123']);
    navigate('home');
  };

  return (
    <div className="flex flex-col items-center justify-center min-h-screen p-6">
      <div className="w-full max-w-sm text-center p-8 space-y-8 bg-white/90 dark:bg-gray-800/90 backdrop-blur-xl rounded-3xl shadow-2xl border border-white/20">
        <div className="space-y-4">
          <div className="relative">
            <Compass className="mx-auto h-20 w-20 text-orange-500 animate-spin-slow" />
            <div className="absolute inset-0 mx-auto h-20 w-20 rounded-full bg-gradient-to-r from-orange-500/20 to-red-500/20 animate-pulse"></div>
          </div>
          <h1 className="text-4xl font-black bg-gradient-to-r from-orange-500 to-red-500 bg-clip-text text-transparent">
            Urban Quest
          </h1>
          <p className="text-lg text-gray-600 dark:text-gray-300 font-medium">Albania</p>
        </div>
        <div className="space-y-4">
          <p className="text-gray-700 dark:text-gray-300">Ready to explore hidden gems and untold stories?</p>
          <button 
            onClick={handleLogin} 
            className="w-full py-4 font-bold text-white bg-gradient-to-r from-orange-500 to-red-500 rounded-2xl hover:from-orange-600 hover:to-red-600 transition-all duration-300 transform hover:scale-105 shadow-xl"
          >
            Start Exploring!
          </button>
        </div>
      </div>
    </div>
  );
}

// Enhanced Home Screen
function HomeScreen() {
  const { navigate, data, currentUser } = useContext(AppContext);
  const featuredQuests = Object.values(data.quests).filter(q => q.isActive).slice(0, 3);

  return (
    <div className="animate-fade-in pb-20">
      <TopNavBar />
      <main className="p-6 space-y-8">
        {/* Welcome Section */}
        <div className="bg-gradient-to-r from-orange-500 to-red-500 rounded-3xl p-6 text-white shadow-xl">
          <div className="flex items-center justify-between mb-4">
            <div>
              <h1 className="text-2xl font-bold">Welcome back, {currentUser.displayName.split(' ')[0]}!</h1>
              <p className="opacity-90">Level {currentUser.level} Explorer</p>
            </div>
            <div className="text-right">
              <p className="text-sm opacity-90">Total Points</p>
              <p className="text-2xl font-bold">{currentUser.totalPoints}</p>
            </div>
          </div>
          <div className="bg-white/20 rounded-2xl p-4">
            <div className="flex justify-between items-center mb-2">
              <span className="text-sm">Progress to Level {currentUser.level + 1}</span>
              <span className="text-sm">75%</span>
            </div>
            <div className="w-full bg-white/30 rounded-full h-2">
              <div className="bg-white h-2 rounded-full w-3/4"></div>
            </div>
          </div>
        </div>

        {/* Quick Stats */}
        <div className="grid grid-cols-3 gap-4">
          {[
            { label: 'Quests', value: currentUser.stats.questsCompleted, icon: Target },
            { label: 'Distance', value: currentUser.stats.totalDistance, icon: Navigation },
            { label: 'Photos', value: currentUser.stats.photosShared, icon: Camera }
          ].map(({ label, value, icon: Icon }) => (
            <div key={label} className="bg-white/90 dark:bg-gray-800/90 rounded-2xl p-4 text-center shadow-lg">
              <Icon className="mx-auto mb-2 text-orange-500" size={24} />
              <p className="text-xl font-bold">{value}</p>
              <p className="text-sm text-gray-600 dark:text-gray-400">{label}</p>
            </div>
          ))}
        </div>

        {/* Featured Quests */}
        <div>
          <div className="flex justify-between items-center mb-4">
            <h2 className="text-2xl font-bold">Featured Quests</h2>
            <button 
              onClick={() => navigate('citySelection')} 
              className="text-orange-500 font-semibold hover:text-orange-600"
            >
              View All
            </button>
          </div>
          <div className="space-y-4">
            {featuredQuests.map(quest => (
              <div 
                key={quest.id} 
                onClick={() => { 
                  setSelectedCity(quest.city); 
                  setSelectedQuestId(quest.id); 
                  navigate('questDetail'); 
                }} 
                className="bg-white/90 dark:bg-gray-800/90 rounded-3xl shadow-xl overflow-hidden cursor-pointer transform hover:scale-[1.02] transition-all duration-300"
              >
                <div className="relative">
                  <img 
                    src={quest.coverImageUrl} 
                    className="w-full h-48 object-cover" 
                    alt={quest.title} 
                  />
                  <div className="absolute top-4 left-4 bg-black/50 backdrop-blur text-white px-3 py-1 rounded-full text-sm">
                    {quest.category}
                  </div>
                  <div className="absolute top-4 right-4 bg-white/90 backdrop-blur text-gray-900 px-2 py-1 rounded-full text-sm font-semibold flex items-center gap-1">
                    <Star size={14} className="text-yellow-500" fill="currentColor" />
                    {quest.rating}
                  </div>
                </div>
                <div className="p-6">
                  <h3 className="text-xl font-bold mb-2">{quest.title}</h3>
                  <p className="text-gray-600 dark:text-gray-400 mb-4">{quest.description}</p>
                  <div className="flex justify-between items-center">
                    <div className="flex items-center gap-4 text-sm text-gray-500">
                      <span className="flex items-center gap-1">
                        <Clock size={14} />
                        {quest.estimatedDuration}
                      </span>
                      <span className="flex items-center gap-1">
                        <MapPin size={14} />
                        {quest.numberOfStops} stops
                      </span>
                    </div>
                    <div className="flex items-center gap-1 text-orange-500 font-semibold">
                      <Zap size={16} />
                      {quest.points} pts
                    </div>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>
      </main>
      <BottomNavigation />
    </div>
  );
}

// Enhanced City Selection Screen
function CitySelectionScreen() {
  const { navigate, setSelectedCity, data, currentUser } = useContext(AppContext);
  const cities = [...new Set(Object.values(data.quests).filter(q => q.isActive).map(q => q.city))];
  const cityStats = cities.map(city => {
    const quests = Object.values(data.quests).filter(q => q.city === city && q.isActive);
    return {
      name: city,
      questCount: quests.length,
      totalPoints: quests.reduce((sum, q) => sum + q.points, 0),
      difficulty: quests.reduce((sum, q) => sum + (q.difficulty === 'Easy' ? 1 : q.difficulty === 'Medium' ? 2 : 3), 0) / quests.length,
      coverImage: quests[0]?.coverImageUrl
    };
  });

  return (
    <div className="animate-fade-in pb-20">
      <TopNavBar />
      <main className="p-6">
        <div className="mb-8">
          <h1 className="text-3xl font-bold mb-2">Choose Your Adventure</h1>
          <p className="text-gray-600 dark:text-gray-400">Discover Albania's hidden gems, one city at a time.</p>
        </div>
        
        <div className="grid grid-cols-1 gap-6">
          {cityStats.map(city => (
            <div 
              key={city.name} 
              onClick={() => { setSelectedCity(city.name); navigate('questList'); }} 
              className="group bg-white/90 dark:bg-gray-800/90 rounded-3xl shadow-xl overflow-hidden cursor-pointer transform hover:scale-[1.02] transition-all duration-300"
            >
              <div className="relative">
                <img 
                  src={city.coverImage} 
                  className="w-full h-48 object-cover group-hover:scale-105 transition-transform duration-500" 
                  alt={city.name}
                />
                <div className="absolute inset-0 bg-gradient-to-t from-black/60 via-transparent to-transparent"></div>
                <div className="absolute bottom-4 left-4 right-4 text-white">
                  <h2 className="text-2xl font-bold mb-2">{city.name}</h2>
                  <div className="flex justify-between items-center">
                    <div className="flex gap-4 text-sm">
                      <span>{city.questCount} quests</span>
                      <span>{city.totalPoints} total points</span>
                    </div>
                    <div className="flex">
                      {[1, 2, 3].map(i => (
                        <div 
                          key={i} 
                          className={`w-2 h-2 rounded-full mx-0.5 ${
                            i <= city.difficulty ? 'bg-orange-400' : 'bg-white/30'
                          }`} 
                        />
                      ))}
                    </div>
                  </div>
                </div>
              </div>
            </div>
          ))}
        </div>
      </main>
      <BottomNavigation />
    </div>
  );
}

// Enhanced Quest List Screen
function QuestListScreen() {
  const { navigate, data, selectedCity, setSelectedQuestId } = useContext(AppContext);
  const questsInCity = Object.values(data.quests).filter(q => q.city === selectedCity && q.isActive);

  return (
    <div className="animate-fade-in pb-20">
      <TopNavBar />
      <main className="p-6">
        <div className="mb-8">
          <h1 className="text-3xl font-bold mb-2">
            Quests in <span className="text-orange-500">{selectedCity}</span>
          </h1>
          <p className="text-gray-600 dark:text-gray-400">
            {questsInCity.length} adventures waiting for you
          </p>
        </div>
        
        <div className="space-y-6">
            {questsInCity.map(quest => (
              <div 
                key={quest.id} 
                onClick={() => { 
                  setSelectedQuestId(quest.id); 
                  navigate('questDetail'); 
                }} 
                className="bg-white/90 dark:bg-gray-800/90 rounded-3xl shadow-xl overflow-hidden cursor-pointer transform hover:scale-[1.02] transition-all duration-300"
              >
                <div className="relative">
                  <img 
                    src={quest.coverImageUrl} 
                    className="w-full h-48 object-cover" 
                    alt={quest.title} 
                  />
                  <div className="absolute top-4 left-4 bg-black/50 backdrop-blur text-white px-3 py-1 rounded-full text-sm">
                    {quest.category}
                  </div>
                  <div className="absolute top-4 right-4 bg-white/90 backdrop-blur text-gray-900 px-2 py-1 rounded-full text-sm font-semibold flex items-center gap-1">
                    <Star size={14} className="text-yellow-500" fill="currentColor" />
                    {quest.rating}
                  </div>
                </div>
                <div className="p-6">
                  <h3 className="text-xl font-bold mb-2">{quest.title}</h3>
                  <p className="text-gray-600 dark:text-gray-400 mb-4">{quest.description}</p>
                  <div className="flex justify-between items-center">
                    <div className="flex items-center gap-4 text-sm text-gray-500">
                      <span className="flex items-center gap-1">
                        <Clock size={14} />
                        {quest.estimatedDuration}
                      </span>
                      <span className="flex items-center gap-1">
                        <MapPin size={14} />
                        {quest.numberOfStops} stops
                      </span>
                    </div>
                    <div className="flex items-center gap-1 text-orange-500 font-semibold">
                      <Zap size={16} />
                      {quest.points} pts
                    </div>
                  </div>
                </div>
              </div>
            ))}
          </div>
      </main>
      <BottomNavigation />
    </div>
  );
}

// Enhanced Quest Detail Screen
function QuestDetailScreen() {
    const { navigate, data, selectedQuestId, setActiveQuestProgress, currentUser } = useContext(AppContext);
    const quest = data.quests[selectedQuestId];

    const handleStartQuest = () => {
        setActiveQuestProgress({ userId: currentUser.id, questId: selectedQuestId, status: 'in-progress', currentStopOrder: 1, points: 0 });
        navigate('gameplay');
    };

    return (
        <div className="animate-fade-in pb-20">
            <TopNavBar />
            <main className="p-6">
                <div className="relative mb-8">
                    <img src={quest.coverImageUrl} className="w-full h-64 object-cover rounded-3xl shadow-2xl" alt={quest.title} />
                    <div className="absolute inset-0 bg-gradient-to-t from-black/50 to-transparent rounded-3xl"></div>
                    <div className="absolute bottom-6 left-6 text-white">
                        <h1 className="text-3xl font-bold">{quest.title}</h1>
                        <p className="opacity-90">{quest.city}</p>
                    </div>
                </div>

                <div className="bg-white/90 dark:bg-gray-800/90 rounded-3xl shadow-xl p-6 mb-6">
                    <p className="text-gray-700 dark:text-gray-300 mb-6">{quest.description}</p>
                    <div className="flex justify-around items-center border-t border-b border-gray-200/50 dark:border-gray-700/50 py-4">
                        <div className="text-center">
                            <p className="text-xl font-bold">{quest.estimatedDuration}</p>
                            <p className="text-sm text-gray-500">Duration</p>
                        </div>
                        <div className="text-center">
                            <p className="text-xl font-bold">{quest.difficulty}</p>
                            <p className="text-sm text-gray-500">Difficulty</p>
                        </div>
                        <div className="text-center">
                            <p className="text-xl font-bold">{quest.points}</p>
                            <p className="text-sm text-gray-500">Points</p>
                        </div>
                    </div>
                </div>
                
                <div className="bg-white/90 dark:bg-gray-800/90 rounded-3xl shadow-xl p-6 mb-6">
                     <h3 className="font-bold mb-2 text-lg">What you'll need:</h3>
                     <div className="flex justify-center gap-6 text-gray-600 dark:text-gray-400">
                         <div className="text-center"><Footprints/><span className="text-xs block">Good Shoes</span></div>
                         <div className="text-center"><Droplets/><span className="text-xs block">Water</span></div>
                         <div className="text-center"><Smartphone/><span className="text-xs block">Charged Phone</span></div>
                     </div>
                </div>
            </main>
            <div className="fixed bottom-6 left-6 right-6">
                <button onClick={handleStartQuest} className="w-full py-4 font-bold text-white bg-gradient-to-r from-orange-500 to-red-500 rounded-2xl hover:from-orange-600 hover:to-red-600 transition-all duration-300 transform hover:scale-105 shadow-xl flex items-center justify-center gap-2">
                    <Play /> Start Adventure!
                </button>
            </div>
        </div>
    );
}

// Enhanced Gameplay Screen
function GameplayScreen() {
    const { navigate, data, activeQuestProgress, setActiveQuestProgress } = useContext(AppContext);
    const [currentStop, setCurrentStop] = useState(null);
    const [hasArrived, setHasArrived] = useState(false);
    const [feedback, setFeedback] = useState({ show: false, correct: false, text: "" });
    const [challengeInput, setChallengeInput] = useState("");

    useEffect(() => {
        const stop = Object.values(data.questStops[activeQuestProgress.questId]).find(s => s.order === activeQuestProgress.currentStopOrder);
        setCurrentStop(stop);
        setHasArrived(false);
        setFeedback({ show: false });
        setChallengeInput("");
    }, [activeQuestProgress, data]);

    const handleArrival = () => setHasArrived(true);

    const handleChallengeSubmit = () => {
        let isCorrect = (currentStop.challengeType === 'PHOTO') || (challengeInput.toLowerCase() === currentStop.correctAnswer.toLowerCase());
        setFeedback({ show: true, correct: isCorrect, text: isCorrect ? currentStop.infoText : "Not quite right. Give it another thought!" });
    };

    const goToNextStop = () => {
        const nextOrder = activeQuestProgress.currentStopOrder + 1;
        if (nextOrder > data.quests[activeQuestProgress.questId].numberOfStops) {
            navigate('questComplete');
        } else {
            setActiveQuestProgress(prev => ({ ...prev, currentStopOrder: nextOrder }));
        }
    };

    if (!currentStop) return <div className="p-8 text-center">Loading...</div>;

    const quest = data.quests[activeQuestProgress.questId];
    const progressPercentage = ((currentStop.order - 1) / quest.numberOfStops) * 100;
    
    return (
        <div className="h-screen flex flex-col">
            <TopNavBar/>
            <main className="flex-grow p-4 space-y-4 overflow-y-auto">
                <div className="w-full bg-gray-200/50 dark:bg-gray-700/50 rounded-full h-4 shadow-inner">
                    <div className="bg-gradient-to-r from-orange-400 to-red-500 h-4 rounded-full transition-all duration-500" style={{ width: `${progressPercentage}%` }}></div>
                </div>
                <div className="text-center font-bold text-sm text-gray-600 dark:text-gray-400">{currentStop.order} of {quest.numberOfStops}</div>

                <div className="bg-white/90 dark:bg-gray-800/90 backdrop-blur-xl p-6 rounded-3xl shadow-xl border border-white/20">
                    <p className="text-sm font-bold text-orange-500">CLUE FOR: {currentStop.title}</p>
                    <div className="flex justify-between items-start mt-2">
                        <p className="text-2xl italic text-gray-700 dark:text-gray-300 pr-4">{currentStop.clue}</p>
                    </div>
                </div>
                {currentStop.videoUrl && (
                     <div className="bg-white/90 dark:bg-gray-800/90 backdrop-blur-xl p-4 rounded-3xl shadow-xl border border-white/20">
                        <div className="aspect-video bg-black rounded-xl flex items-center justify-center text-gray-500">
                           <Video className="mr-2"/> (Video placeholder)
                        </div>
                    </div>
                )}
            </main>
            
            <footer className={`bg-white dark:bg-gray-800 rounded-t-3xl shadow-[0_-20px_40px_-15px_rgba(0,0,0,0.1)] transition-all duration-500 flex-shrink-0 ${hasArrived ? 'h-3/5' : 'h-2/5'}`}>
                {/* Challenge Area */}
            </footer>
        </div>
    );
}

// Enhanced Quest Complete Screen
function QuestCompleteScreen() {
    const { navigate, data, selectedQuestId } = useContext(AppContext);
    const quest = data.quests[selectedQuestId];
    return (
        <div className="flex flex-col items-center justify-center min-h-screen text-center p-6 animate-fade-in">
            <div className="bg-white/90 dark:bg-gray-800/90 backdrop-blur-xl rounded-3xl shadow-2xl p-8 max-w-md w-full">
                <div className="relative mb-6">
                    <Trophy size={100} className="mx-auto text-amber-500 drop-shadow-lg" />
                    <div className="absolute inset-0 mx-auto h-24 w-24 rounded-full bg-amber-500/20 animate-pulse"></div>
                </div>
                <h1 className="text-4xl font-black mb-2">Quest Complete!</h1>
                <p className="text-lg text-gray-600 dark:text-gray-300 mb-4">You've conquered "{quest.title}"!</p>
                <div className="bg-gradient-to-r from-orange-100 to-red-100 dark:from-orange-900/50 dark:to-red-900/50 rounded-2xl p-4 mb-6">
                    <p className="text-sm text-orange-600 dark:text-orange-300">You've earned</p>
                    <p className="text-4xl font-bold text-orange-500">{quest.points} pts</p>
                </div>
                <div className="flex gap-4">
                    <button onClick={() => alert('Sharing your achievement!')} className="flex-1 py-3 font-bold bg-blue-500 text-white rounded-2xl shadow-lg flex items-center justify-center gap-2">
                        <Share2 size={16} /> Share
                    </button>
                    <button onClick={() => navigate('home')} className="flex-1 py-3 font-bold bg-gray-200 dark:bg-gray-700 rounded-2xl shadow-lg">
                        Done
                    </button>
                </div>
            </div>
        </div>
    );
}

// Enhanced Profile Screen
function ProfileScreen() {
    const { data, currentUser } = useContext(AppContext);
    return (
        <div className="animate-fade-in pb-20">
            <TopNavBar />
            <main className="p-6">
                <div className="text-center mb-8">
                    <div className="relative inline-block">
                        <img src={currentUser.avatar} alt="User Avatar" className="w-24 h-24 rounded-full shadow-xl border-4 border-white dark:border-gray-800" />
                        <div className="absolute -bottom-1 -right-1 bg-gradient-to-r from-orange-500 to-red-500 text-white w-8 h-8 rounded-full flex items-center justify-center font-bold text-sm shadow-md">
                            {currentUser.level}
                        </div>
                    </div>
                    <h1 className="text-2xl font-bold mt-4">{currentUser.displayName}</h1>
                    <p className="text-gray-600 dark:text-gray-400">Explorer since {new Date(currentUser.createdAt).toLocaleDateString()}</p>
                </div>

                <div className="bg-white/90 dark:bg-gray-800/90 rounded-3xl shadow-xl p-6 mb-6">
                    <h2 className="text-xl font-bold mb-4">Adventurer Stats</h2>
                    <div className="grid grid-cols-2 gap-4">
                        {[
                            { label: 'Quests Done', value: currentUser.stats.questsCompleted, icon: Target },
                            { label: 'Stops Visited', value: currentUser.stats.stopsVisited, icon: MapPin },
                            { label: 'Distance Walked', value: currentUser.stats.totalDistance, icon: Footprints },
                            { label: 'Photos Shared', value: currentUser.stats.photosShared, icon: Camera }
                        ].map(({ label, value, icon: Icon }) => (
                            <div key={label} className="bg-gray-100 dark:bg-gray-700/50 p-4 rounded-2xl">
                                <Icon className="text-orange-500 mb-2" size={24} />
                                <p className="text-lg font-bold">{value}</p>
                                <p className="text-xs text-gray-500">{label}</p>
                            </div>
                        ))}
                    </div>
                </div>

                <div className="bg-white/90 dark:bg-gray-800/90 rounded-3xl shadow-xl p-6">
                    <h2 className="text-xl font-bold mb-4">Badges Earned</h2>
                    <div className="flex gap-4 overflow-x-auto pb-2">
                        {[
                            { icon: Gift, label: "First Quest" },
                            { icon: Medal, label: "Tirana Master" },
                            { icon: Award, label: "Trivia Champion" }
                        ].map(({ icon: Icon, label }) => (
                            <div key={label} className="text-center flex-shrink-0">
                                <div className="w-16 h-16 bg-amber-100 dark:bg-amber-900/50 rounded-full flex items-center justify-center text-amber-500">
                                    <Icon size={32} />
                                </div>
                                <p className="text-xs mt-2">{label}</p>
                            </div>
                        ))}
                    </div>
                </div>
            </main>
            <BottomNavigation />
        </div>
    );
}

// Enhanced Leaderboard Screen
function LeaderboardScreen() {
    const { data } = useContext(AppContext);
    return (
        <div className="animate-fade-in pb-20">
            <TopNavBar />
            <main className="p-6">
                <div className="text-center mb-8">
                    <Trophy size={48} className="mx-auto text-amber-500" />
                    <h1 className="text-3xl font-bold mt-2">Leaderboard</h1>
                    <p className="text-gray-600 dark:text-gray-400">See who's leading the pack!</p>
                </div>
                <div className="space-y-4">
                    {data.leaderboard.sort((a, b) => b.points - a.points).map((user, index) => (
                        <div key={user.id} className="bg-white/90 dark:bg-gray-800/90 rounded-2xl shadow-lg p-4 flex items-center gap-4">
                            <span className="text-xl font-bold w-8 text-center text-gray-500">{index + 1}</span>
                            <img src={user.avatar} alt={user.name} className="w-12 h-12 rounded-full" />
                            <p className="flex-grow font-bold text-lg">{user.name}</p>
                            <div className="text-orange-500 font-bold text-lg flex items-center gap-1">
                                <Zap size={16} />
                                {user.points}
                            </div>
                        </div>
                    ))}
                </div>
            </main>
            <BottomNavigation />
        </div>
    );
}

