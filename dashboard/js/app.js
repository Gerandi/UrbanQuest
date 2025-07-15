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
    initializeDarkMode();
    showTab('overview');
    
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
        tab.classList.add('hidden');
        tab.classList.remove('animate-fade-in');
    });
    
    // Remove active class from all sidebar buttons
    const allSidebarItems = document.querySelectorAll('.sidebar-item');
    allSidebarItems.forEach(button => {
        button.classList.remove('active');
    });
    
    // Show selected tab with animation
    const selectedTab = document.getElementById(tabName);
    if (selectedTab) {
        selectedTab.classList.remove('hidden');
        selectedTab.classList.add('animate-fade-in');
    }
    
    // Add active class to selected sidebar button
    const selectedNavButton = document.querySelector(`[onclick="showTab('${tabName}')"]`);
    if (selectedNavButton) {
        selectedNavButton.classList.add('active');
    }
    
    // Update page title
    updatePageTitle(tabName);
    
    // Load data for the selected tab
    loadTabData(tabName);
}

// Update page title based on current tab
function updatePageTitle(tabName) {
    const pageTitle = document.getElementById('pageTitle');
    const titles = {
        'overview': 'Dashboard',
        'users': 'Profile Management',
        'cities': 'City Management', 
        'quests': 'Quest Management',
        'quest-stops': 'Quest Stops Management',
        'categories': 'Categories Management',
        'analytics': 'Analytics & Reports'
    };
    
    if (pageTitle && titles[tabName]) {
        pageTitle.textContent = titles[tabName];
    }
}

// Load overview data for the dashboard
async function loadOverviewData() {
    try {
        // Load statistics in parallel
        const [questsRes, usersRes, citiesRes, progressRes] = await Promise.all([
            window.supabase.from('quests').select('id', { count: 'exact', head: true }),
            window.supabase.from('profiles').select('id', { count: 'exact', head: true }),
            window.supabase.from('cities').select('id', { count: 'exact', head: true }),
            window.supabase.from('user_quest_progress').select('id').eq('status', 'completed')
        ]);
        
        // Update stat cards
        const totalQuests = document.getElementById('totalQuests');
        const totalUsers = document.getElementById('totalUsers');
        const totalCities = document.getElementById('totalCities');
        const totalCompletions = document.getElementById('totalCompletions');
        
        if (totalQuests) totalQuests.textContent = Utils.formatNumber(questsRes.count || 0);
        if (totalUsers) totalUsers.textContent = Utils.formatNumber(usersRes.count || 0);
        if (totalCities) totalCities.textContent = Utils.formatNumber(citiesRes.count || 0);
        if (totalCompletions) totalCompletions.textContent = Utils.formatNumber(progressRes.data?.length || 0);
        
        // Load recent activity
        await loadRecentActivity();
        
    } catch (error) {
        console.error('Error loading overview data:', error);
        Utils.showNotification('Error loading dashboard statistics', 'error');
        
        // Set fallback values
        document.getElementById('totalQuests').textContent = '-';
        document.getElementById('totalUsers').textContent = '-';
        document.getElementById('totalCities').textContent = '-';
        document.getElementById('totalCompletions').textContent = '-';
    }
}

// Load recent activity
async function loadRecentActivity() {
    try {
        const { data: recentProgress } = await window.supabase
            .from('user_quest_progress')
            .select(`
                *,
                profiles(display_name, email),
                quests(title)
            `)
            .order('updated_at', { ascending: false })
            .limit(10);
            
        const activityContainer = document.getElementById('recentActivity');
        if (!activityContainer) return;
        
        if (!recentProgress || recentProgress.length === 0) {
            activityContainer.innerHTML = `
                <div class="text-center py-4 text-gray-500">
                    <i class="fas fa-info-circle mr-2"></i>No recent activity found
                </div>
            `;
            return;
        }
        
        activityContainer.innerHTML = recentProgress.map(progress => `
            <div class="flex items-center justify-between p-3 bg-gray-50 dark:bg-gray-700/50 rounded-lg">
                <div class="flex items-center">
                    <div class="w-8 h-8 bg-orange-100 dark:bg-orange-900/50 rounded-full flex items-center justify-center mr-3">
                        <i class="fas fa-user text-orange-500 text-sm"></i>
                    </div>
                    <div>
                        <p class="text-sm font-medium text-gray-900 dark:text-gray-100">
                            ${Utils.escapeHtml(progress.profiles?.display_name || 'Unknown User')}
                        </p>
                        <p class="text-xs text-gray-500 dark:text-gray-400">
                            ${progress.status === 'completed' ? 'Completed' : 'Started'} "${Utils.escapeHtml(progress.quests?.title || 'Unknown Quest')}"
                        </p>
                    </div>
                </div>
                <div class="text-xs text-gray-400">
                    ${Utils.formatDate(progress.updated_at)}
                </div>
            </div>
        `).join('');
        
    } catch (error) {
        console.error('Error loading recent activity:', error);
        const activityContainer = document.getElementById('recentActivity');
        if (activityContainer) {
            activityContainer.innerHTML = `
                <div class="text-center py-4 text-red-500">
                    <i class="fas fa-exclamation-triangle mr-2"></i>Error loading recent activity
                </div>
            `;
        }
    }
}

// Load data for specific tab
async function loadTabData(tabName) {
    console.log('Loading data for tab:', tabName);
    
    try {
        switch (tabName) {
            case 'overview':
                // Load overview statistics
                await loadOverviewData();
                break;
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
            case 'analytics':
                if (typeof loadAnalyticsData === 'function') {
                    await loadAnalyticsData();
                } else {
                    console.error('Analytics functionality not available');
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

// Dark Mode Toggle
function toggleDarkMode() {
    const html = document.documentElement;
    const isDark = html.classList.contains('dark');
    const darkModeIcon = document.getElementById('darkModeIcon');
    
    if (isDark) {
        html.classList.remove('dark');
        localStorage.setItem('darkMode', 'false');
        if (darkModeIcon) {
            darkModeIcon.className = 'fas fa-moon text-lg';
        }
    } else {
        html.classList.add('dark');
        localStorage.setItem('darkMode', 'true');
        if (darkModeIcon) {
            darkModeIcon.className = 'fas fa-sun text-lg';
        }
    }
}

// Initialize dark mode from localStorage
function initializeDarkMode() {
    const savedDarkMode = localStorage.getItem('darkMode');
    const prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
    
    if (savedDarkMode === 'true' || (savedDarkMode === null && prefersDark)) {
        document.documentElement.classList.add('dark');
        const darkModeIcon = document.getElementById('darkModeIcon');
        if (darkModeIcon) {
            darkModeIcon.className = 'fas fa-sun text-lg';
        }
    }
}

// Settings Toggle
function toggleSettings() {
    Utils.showNotification('Settings panel coming soon!', 'info');
}

// Add New Item functions (called by the + buttons in the header)
function addNewUser() {
    if (window.UserManager && window.UserManager.createUser) {
        window.UserManager.createUser();
    } else {
        showModal('user');
    }
}

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
window.toggleDarkMode = toggleDarkMode;
window.toggleSettings = toggleSettings;
window.addNewUser = addNewUser;
window.addNewQuest = addNewQuest;
window.addNewQuestStop = addNewQuestStop;
window.addNewCity = addNewCity;
window.addNewCategory = addNewCategory;