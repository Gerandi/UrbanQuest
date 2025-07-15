// Main Application Logic

// Global state
let currentUser = null;

// Wait for DOM to be ready
document.addEventListener('DOMContentLoaded', async function() {
    console.log('DOM loaded, initializing UrbanQuest Admin Dashboard...');
    
    // Check if Supabase is initialized (should be done in config.js)
    if (typeof window.supabase === 'undefined') {
        console.error('❌ Supabase not initialized. Check config.js');
        return;
    }
    
    console.log('✅ Using Supabase client initialized in config.js');

    // Check authentication first
    await initializeAuth();
    
    // Test modal system
    if (typeof showModal !== 'undefined') {
        console.log('✅ Simple Modal System is available and working');
    } else {
        console.error('❌ Simple Modal System is not available');
    }
    
    console.log('UrbanQuest Admin Dashboard loaded successfully');
});

// Authentication functions
async function initializeAuth() {
    // Check if user is already logged in
    const { data: { session } } = await window.supabase.auth.getSession();
    if (session) {
        await handleAuthSuccess(session.user);
    } else {
        // Show login form
        showLoginForm();
    }

    // Set up auth listener
    window.supabase.auth.onAuthStateChange(async (event, session) => {
        if (event === 'SIGNED_IN' && session) {
            await handleAuthSuccess(session.user);
        } else if (event === 'SIGNED_OUT') {
            handleAuthSignOut();
        }
    });

    // Set up login form listener
    const loginForm = document.getElementById('loginFormElement');
    if (loginForm) {
        loginForm.addEventListener('submit', handleLogin);
    }

    // Set up logout button listener
    const logoutBtn = document.getElementById('logoutBtn');
    if (logoutBtn) {
        logoutBtn.addEventListener('click', handleLogout);
    }
}

async function handleLogin(e) {
    e.preventDefault();
    showLoading(true);
    
    const email = document.getElementById('email').value;
    const password = document.getElementById('password').value;
    
    try {
        const { data, error } = await window.supabase.auth.signInWithPassword({
            email,
            password
        });
        
        if (error) throw error;
        
        // Check if user has admin privileges
        const { data: profile, error: profileError } = await window.supabase
            .from('profiles')
            .select('role')
            .eq('id', data.user.id)
            .single();
            
        if (profileError || !['admin', 'super_admin', 'content_creator'].includes(profile?.role)) {
            await window.supabase.auth.signOut();
            throw new Error('Admin access required');
        }
        
    } catch (error) {
        const loginError = document.getElementById('loginError');
        const loginErrorText = document.getElementById('loginErrorText');
        if (loginErrorText) {
            loginErrorText.textContent = error.message;
        } else {
            loginError.textContent = error.message;
        }
        loginError.classList.remove('hidden');
    } finally {
        showLoading(false);
    }
}

async function handleAuthSuccess(user) {
    currentUser = user;
    const userEmail = document.getElementById('userEmail');
    if (userEmail) {
        userEmail.textContent = user.email;
    }
    
    // Hide login form and show dashboard
    const loginForm = document.getElementById('loginForm');
    const dashboard = document.getElementById('dashboard');
    const loginError = document.getElementById('loginError');
    
    if (loginForm) loginForm.classList.add('hidden');
    if (dashboard) dashboard.classList.remove('hidden');
    if (loginError) loginError.classList.add('hidden');
    
    // Set up navigation and load initial data
    setupNavigation();
    showTab('quests');
    
    console.log('✅ User authenticated successfully');
}

function handleAuthSignOut() {
    currentUser = null;
    showLoginForm();
    
    // Clear form fields
    const emailField = document.getElementById('email');
    const passwordField = document.getElementById('password');
    if (emailField) emailField.value = '';
    if (passwordField) passwordField.value = '';
}

function showLoginForm() {
    const loginForm = document.getElementById('loginForm');
    const dashboard = document.getElementById('dashboard');
    
    if (loginForm) loginForm.classList.remove('hidden');
    if (dashboard) dashboard.classList.add('hidden');
}

async function handleLogout() {
    showLoading(true);
    await window.supabase.auth.signOut();
    showLoading(false);
}

function showLoading(show) {
    const loadingOverlay = document.getElementById('loadingOverlay');
    if (loadingOverlay) {
        if (show) {
            loadingOverlay.classList.remove('hidden');
        } else {
            loadingOverlay.classList.add('hidden');
        }
    }
}

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