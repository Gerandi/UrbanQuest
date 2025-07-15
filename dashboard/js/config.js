// Configuration and constants
const CONFIG = {
    SUPABASE_URL: 'https://tbvjpjoqlsinlkoopnwg.supabase.co',
    SUPABASE_ANON_KEY: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRidmpwam9xbHNpbmxrb29wbndnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTEyMDU0MTcsImV4cCI6MjA2Njc4MTQxN30.DKCEuwT_8u5-LasNJQX0vRmlASwYe1TPwHkbbt60hmA',
    DEFAULT_MAP_CENTER: [41.3275, 19.8187], // Tirana, Albania
    DEFAULT_MAP_ZOOM: 13,
    ADMIN_ROLES: ['admin', 'super_admin', 'content_creator'],
    CHALLENGE_TYPES: {
        'text': {
            name: 'Text Answer',
            icon: 'fas fa-keyboard',
            color: 'blue',
            description: 'Users type a text answer'
        },
        'multiple_choice': {
            name: 'Multiple Choice',
            icon: 'fas fa-list-ul',
            color: 'green',
            description: 'Users select from multiple options'
        },
        'photo': {
            name: 'Photo Challenge',
            icon: 'fas fa-camera',
            color: 'purple',
            description: 'Users take a photo'
        },
        'location_only': {
            name: 'Location Only',
            icon: 'fas fa-map-marker-alt',
            color: 'red',
            description: 'Simply arrive at the location'
        },
        'qr_code': {
            name: 'QR Code',
            icon: 'fas fa-qrcode',
            color: 'indigo',
            description: 'Scan a QR code'
        },
        'audio': {
            name: 'Audio Challenge',
            icon: 'fas fa-microphone',
            color: 'pink',
            description: 'Record audio response'
        },
        'regex': {
            name: 'Pattern Match',
            icon: 'fas fa-code',
            color: 'orange',
            description: 'Match a specific pattern'
        }
    },
    DIFFICULTY_LEVELS: ['easy', 'medium', 'hard', 'expert'],
    LANGUAGES: ['en', 'sq', 'de', 'fr', 'it'],
    QUEST_REQUIREMENTS: {
        'permissions': ['location', 'camera', 'microphone'],
        'device_features': ['gps', 'camera', 'microphone', 'internet'],
        'physical_requirements': ['walking', 'moderate_fitness', 'climbing'],
        'equipment': ['smartphone', 'headphones_recommended', 'comfortable_shoes']
    }
};

// Initialize Supabase client
const { createClient } = supabase;
const supabaseClient = createClient(CONFIG.SUPABASE_URL, CONFIG.SUPABASE_ANON_KEY);

// Global state
window.AppState = {
    currentUser: null,
    map: null,
    selectedLocation: null,
    questStopsLayer: null,
    currentQuest: null,
    currentQuestStop: null,
    isLoading: false
};

// Initialize Supabase early so modules can use it
function initializeSupabase() {
    if (typeof supabase !== 'undefined' && CONFIG.SUPABASE_URL && CONFIG.SUPABASE_ANON_KEY) {
        window.supabase = supabase.createClient(CONFIG.SUPABASE_URL, CONFIG.SUPABASE_ANON_KEY);
        window.supabaseClient = window.supabase;
        globalThis.supabase = window.supabase;
        console.log('✅ Supabase initialized early in config.js');
        return true;
    }
    return false;
}

// Wait for Supabase library to load and then initialize
function waitForSupabaseAndInit() {
    if (initializeSupabase()) {
        return;
    }
    
    // If supabase isn't loaded yet, wait for it
    const checkInterval = setInterval(() => {
        if (initializeSupabase()) {
            clearInterval(checkInterval);
        }
    }, 100);
    
    // Timeout after 10 seconds
    setTimeout(() => {
        clearInterval(checkInterval);
        if (typeof window.supabase === 'undefined') {
            console.error('❌ Failed to initialize Supabase after 10 seconds');
        }
    }, 10000);
}

// Start initialization
waitForSupabaseAndInit();