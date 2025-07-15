// Main Application Logic

// Wait for DOM to be ready
document.addEventListener('DOMContentLoaded', async function() {
    console.log('DOM loaded, initializing UrbanQuest Admin Dashboard...');
    
    // Initialize Supabase
    const SUPABASE_URL = 'https://oimkghtvjyxfyfyxqrdt.supabase.co';
    const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9pbWtnaHR2anl4ZnlmeXhxcmR0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzU2MzQ4MDQsImV4cCI6MjA1MTIxMDgwNH0.wV6k5EqAmOGwX8yiJ8VH--wY26m-rwVgGT1b3z7pLTE';
    
    if (typeof supabase === 'undefined') {
        console.error('Supabase library not loaded');
        return;
    }
    
    window.supabase = supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
    console.log('Supabase initialized');

    // Set up navigation
    setupNavigation();
    
    // Load initial tab
    showTab('quests');
    
    // Test modal system
    if (typeof showModal !== 'undefined') {
        console.log('✅ Simple Modal System is available and working');
    } else {
        console.error('❌ Simple Modal System is not available');
    }
    
    console.log('UrbanQuest Admin Dashboard loaded successfully');
});

// Navigation setup
function setupNavigation() {
    const navButtons = document.querySelectorAll('[data-tab]');
    navButtons.forEach(button => {
        button.addEventListener('click', (e) => {
            e.preventDefault();
            const tabName = button.getAttribute('data-tab');
            showTab(tabName);
        });
    });
}

// Show specific tab
function showTab(tabName) {
    console.log('Showing tab:', tabName);
    
    // Hide all tab contents
    const allTabs = document.querySelectorAll('.tab-content');
    allTabs.forEach(tab => {
        tab.style.display = 'none';
    });
    
    // Remove active class from all nav buttons
    const allNavButtons = document.querySelectorAll('[data-tab]');
    allNavButtons.forEach(button => {
        button.classList.remove('bg-indigo-600', 'text-white');
        button.classList.add('text-gray-600', 'hover:text-gray-900');
    });
    
    // Show selected tab
    const selectedTab = document.getElementById(tabName + 'Tab');
    if (selectedTab) {
        selectedTab.style.display = 'block';
    }
    
    // Add active class to selected nav button
    const selectedNavButton = document.querySelector(`[data-tab="${tabName}"]`);
    if (selectedNavButton) {
        selectedNavButton.classList.add('bg-indigo-600', 'text-white');
        selectedNavButton.classList.remove('text-gray-600', 'hover:text-gray-900');
    }
    
    // Load data for the selected tab
    loadTabData(tabName);
}

// Load data for specific tab
async function loadTabData(tabName) {
    console.log('Loading data for tab:', tabName);
    
    try {
        switch (tabName) {
            case 'quests':
                if (window.QuestManager && window.QuestManager.loadQuests) {
                    await window.QuestManager.loadQuests();
                }
                break;
            case 'quest-stops':
                if (window.QuestStopManager && window.QuestStopManager.loadQuestStops) {
                    await window.QuestStopManager.loadQuestStops();
                }
                break;
            case 'cities':
                if (window.CityManager && window.CityManager.loadCities) {
                    await window.CityManager.loadCities();
                }
                break;
            case 'categories':
                if (window.CategoryManager && window.CategoryManager.loadCategories) {
                    await window.CategoryManager.loadCategories();
                }
                break;
            case 'users':
                if (window.UserManager && window.UserManager.loadUsers) {
                    await window.UserManager.loadUsers();
                }
                break;
            default:
                console.warn('Unknown tab:', tabName);
        }
    } catch (error) {
        console.error('Error loading tab data:', error);
        Utils.showNotification(`Error loading ${tabName}: ${error.message}`, 'error');
    }
}

// Add New Item functions (called by the + buttons in the header)
function addNewQuest() {
    if (window.QuestManager && window.QuestManager.createQuest) {
        window.QuestManager.createQuest();
    } else {
        showModal('quest');
    }
}

function addNewQuestStop() {
    if (window.QuestStopManager && window.QuestStopManager.createQuestStop) {
        window.QuestStopManager.createQuestStop();
    } else {
        showModal('questStop');
    }
}

function addNewCity() {
    if (window.CityManager && window.CityManager.createCity) {
        window.CityManager.createCity();
    } else {
        showModal('city');
    }
}

function addNewCategory() {
    if (window.CategoryManager && window.CategoryManager.createCategory) {
        window.CategoryManager.createCategory();
    } else {
        showModal('category');
    }
}

// Make functions globally available
window.showTab = showTab;
window.addNewQuest = addNewQuest;
window.addNewQuestStop = addNewQuestStop;
window.addNewCity = addNewCity;
window.addNewCategory = addNewCategory;