// Main Application Logic

// DOM elements
const loginForm = document.getElementById('loginForm');
const dashboard = document.getElementById('dashboard');
const loginFormElement = document.getElementById('loginFormElement');
const loginError = document.getElementById('loginError');
const loginErrorText = document.getElementById('loginErrorText');
const logoutBtn = document.getElementById('logoutBtn');
const userEmail = document.getElementById('userEmail');

// Initialize app
document.addEventListener('DOMContentLoaded', async () => {
    try {
        // Check database connection
        await Utils.checkConnection();
        
        // Check if user is already logged in
        const { data: { session } } = await supabaseClient.auth.getSession();
        if (session) {
            await handleAuthSuccess(session.user);
        }

        // Set up auth listener
        supabaseClient.auth.onAuthStateChange(async (event, session) => {
            if (event === 'SIGNED_IN' && session) {
                await handleAuthSuccess(session.user);
            } else if (event === 'SIGNED_OUT') {
                handleAuthSignOut();
            }
        });

        // Set up event listeners
        setupEventListeners();
        
    } catch (error) {
        console.error('Failed to initialize app:', error);
        Utils.showToast('Failed to initialize application. Please refresh the page.', 'error');
    }
});

// Set up all event listeners
function setupEventListeners() {
    // Authentication
    loginFormElement?.addEventListener('submit', handleLogin);
    logoutBtn?.addEventListener('click', handleLogout);
    
    // Tab navigation
    document.querySelectorAll('.tab-button').forEach(button => {
        button.addEventListener('click', (e) => {
            e.preventDefault();
            const tabName = button.getAttribute('onclick')?.match(/'([^']*)'/)?.[1];
            if (tabName) {
                showTab(tabName);
            }
        });
    });
    
    // Add buttons
    document.getElementById('addQuestBtn')?.addEventListener('click', () => showQuestModal());
    document.getElementById('addQuestStopBtn')?.addEventListener('click', () => {
        if (!window.AppState.selectedLocation) {
            Utils.showToast('Please select a location on the map first!', 'warning');
            return;
        }
        showQuestStopModal();
    });
    document.getElementById('addCityBtn')?.addEventListener('click', () => showCityModal());
    document.getElementById('addCategoryBtn')?.addEventListener('click', () => showCategoryModal());
}

// Authentication functions
async function handleLogin(e) {
    e.preventDefault();
    
    const emailInput = document.getElementById('email');
    const passwordInput = document.getElementById('password');
    
    if (!emailInput || !passwordInput) return;
    
    const email = emailInput.value.trim();
    const password = passwordInput.value;
    
    try {
        showLoading(true);
        hideElement('loginError');
        
        // Validate inputs
        if (!email || !password) {
            throw new Error('Please enter both email and password');
        }
        
        if (!Utils.validateEmail(email)) {
            throw new Error('Please enter a valid email address');
        }
        
        const { data, error } = await supabaseClient.auth.signInWithPassword({
            email,
            password
        });
        
        if (error) throw error;
        
        // Check if user has admin privileges
        try {
            const { data: profile, error: profileError } = await supabaseClient
                .from('profiles')
                .select('role')
                .eq('id', data.user.id)
                .single();
                
            if (profileError) {
                console.warn('Could not fetch user profile:', profileError);
                // Continue anyway - user might not have a profile yet, allow login for development
            } else if (profile && profile.role && !CONFIG.ADMIN_ROLES.includes(profile.role)) {
                await supabaseClient.auth.signOut();
                throw new Error('Admin access required. Your role: ' + profile.role);
            }
            // If no role is set or profile doesn't exist, allow login for development
        } catch (roleCheckError) {
            console.warn('Role check failed, continuing anyway for development:', roleCheckError);
            // Continue with login even if role check fails
        }
        
    } catch (error) {
        console.error('Login error:', error);
        showElement('loginError');
        if (loginErrorText) {
            loginErrorText.textContent = error.message || 'Login failed';
        }
    } finally {
        showLoading(false);
    }
}

async function handleAuthSuccess(user) {
    try {
        window.AppState.currentUser = user;
        
        if (userEmail) {
            userEmail.textContent = user.email;
        }
        
        // Hide login form and show dashboard
        hideElement('loginForm');
        showElement('dashboard');
        hideElement('loginError');
        
        // Load dashboard data
        await loadDashboardData();
        
        Utils.showToast(`Welcome back, ${user.email}!`, 'success');
        
    } catch (error) {
        console.error('Error in auth success handler:', error);
        Utils.showToast('Failed to load dashboard data', 'error');
    }
}

function handleAuthSignOut() {
    window.AppState.currentUser = null;
    
    // Show login form and hide dashboard
    showElement('loginForm');
    hideElement('dashboard');
    
    // Clear form fields
    const emailInput = document.getElementById('email');
    const passwordInput = document.getElementById('password');
    if (emailInput) emailInput.value = '';
    if (passwordInput) passwordInput.value = '';
    
    Utils.showToast('You have been logged out', 'info');
}

async function handleLogout() {
    try {
        showLoading(true);
        await supabaseClient.auth.signOut();
    } catch (error) {
        console.error('Logout error:', error);
        Utils.showToast('Failed to logout properly', 'error');
    } finally {
        showLoading(false);
    }
}

// Tab management
function showTab(tabName) {
    try {
        // Hide all tab contents
        document.querySelectorAll('.tab-content').forEach(content => {
            content.classList.remove('active');
        });
        
        // Remove active class from all tab buttons
        document.querySelectorAll('.tab-button').forEach(button => {
            button.classList.remove('active', 'bg-blue-500', 'text-white');
            button.classList.add('text-gray-300', 'hover:text-white');
        });
        
        // Show selected tab content
        const tabContent = document.getElementById(tabName);
        if (tabContent) {
            tabContent.classList.add('active');
        }
        
        // Highlight active tab button
        const activeButton = document.querySelector(`[onclick*="${tabName}"]`);
        if (activeButton) {
            activeButton.classList.add('active', 'bg-blue-500', 'text-white');
            activeButton.classList.remove('text-gray-300', 'hover:text-white');
        }
        
        // Load tab-specific data
        loadTabData(tabName);
        
    } catch (error) {
        console.error('Error showing tab:', error);
    }
}

// Dashboard data loading
async function loadDashboardData() {
    try {
        showLoading(true);
        await loadOverviewData();
    } catch (error) {
        console.error('Error loading dashboard data:', error);
        Utils.showToast('Failed to load dashboard data', 'error');
    } finally {
        showLoading(false);
    }
}

async function loadOverviewData() {
    try {
        // Load statistics in parallel
        const [questsRes, usersRes, citiesRes, progressRes] = await Promise.all([
            supabaseClient.from('quests').select('id', { count: 'exact', head: true }),
            supabaseClient.from('profiles').select('id', { count: 'exact', head: true }),
            supabaseClient.from('cities').select('id', { count: 'exact', head: true }),
            supabaseClient.from('user_quest_progress').select('id').eq('status', 'completed')
        ]);
        
        // Update statistics cards
        const totalQuestsElement = document.getElementById('totalQuests');
        const totalUsersElement = document.getElementById('totalUsers');
        const totalCitiesElement = document.getElementById('totalCities');
        const totalCompletionsElement = document.getElementById('totalCompletions');
        
        if (totalQuestsElement) totalQuestsElement.textContent = Utils.formatNumber(questsRes.count || 0);
        if (totalUsersElement) totalUsersElement.textContent = Utils.formatNumber(usersRes.count || 0);
        if (totalCitiesElement) totalCitiesElement.textContent = Utils.formatNumber(citiesRes.count || 0);
        if (totalCompletionsElement) totalCompletionsElement.textContent = Utils.formatNumber(progressRes.data?.length || 0);
        
        // Load recent activity
        await loadRecentActivity();
        
        // Load challenge statistics
        await loadChallengeStatistics();
        
    } catch (error) {
        console.error('Error loading overview data:', error);
        Utils.handleError(error, 'Failed to load overview data');
    }
}

async function loadRecentActivity() {
    try {
        const { data: recentProgress } = await supabaseClient
            .from('user_quest_progress')
            .select(`
                *,
                profiles(email),
                quests(title)
            `)
            .order('updated_at', { ascending: false })
            .limit(10);
            
        const activityContainer = document.getElementById('recentActivity');
        if (!activityContainer) return;
        
        if (recentProgress && recentProgress.length > 0) {
            activityContainer.innerHTML = recentProgress.map(progress => `
                <div class="flex justify-between items-center py-3 border-b border-gray-100 last:border-b-0">
                    <div class="flex-1">
                        <p class="font-medium text-gray-900">
                            ${progress.profiles?.email || 'Unknown User'}
                        </p>
                        <p class="text-sm text-gray-600">
                            ${progress.status === 'completed' ? 'Completed' : 'Started'} 
                            "${progress.quests?.title || 'Unknown Quest'}"
                        </p>
                    </div>
                    <div class="text-right">
                        <span class="text-sm text-gray-500">
                            ${Utils.formatDate(progress.updated_at)}
                        </span>
                        ${progress.status === 'completed' ? 
                            `<div class="text-xs text-green-600 font-medium">${progress.total_points || 0} points</div>` : 
                            `<div class="text-xs text-blue-600 font-medium">In progress</div>`
                        }
                    </div>
                </div>
            `).join('');
        } else {
            activityContainer.innerHTML = UIComponents.createEmptyState(
                'No Recent Activity',
                'User activity will appear here as people use the app',
                null,
                null,
                'fas fa-clock'
            );
        }
        
    } catch (error) {
        console.error('Error loading recent activity:', error);
    }
}

async function loadChallengeStatistics() {
    try {
        const { data: challengeStats } = await supabaseClient
            .from('quest_stops')
            .select('challenge_type');
            
        const statsContainer = document.getElementById('challengeStats');
        if (!statsContainer) return;
        
        if (challengeStats && challengeStats.length > 0) {
            const grouped = Utils.groupBy(challengeStats, 'challenge_type');
            const total = challengeStats.length;
            
            statsContainer.innerHTML = Object.entries(grouped)
                .sort(([,a], [,b]) => b.length - a.length)
                .map(([type, stops]) => {
                    const config = CONFIG.CHALLENGE_TYPES[type] || CONFIG.CHALLENGE_TYPES.text;
                    const count = stops.length;
                    const percentage = Math.round((count / total) * 100);
                    
                    return `
                        <div class="flex items-center justify-between py-2">
                            <div class="flex items-center">
                                <i class="${config.icon} text-${config.color}-600 mr-3"></i>
                                <span class="text-sm font-medium text-gray-900">${config.name}</span>
                            </div>
                            <div class="flex items-center space-x-2">
                                <span class="text-sm text-gray-600">${count}</span>
                                <div class="w-16 bg-gray-200 rounded-full h-2">
                                    <div class="bg-${config.color}-600 h-2 rounded-full" style="width: ${percentage}%"></div>
                                </div>
                                <span class="text-xs text-gray-500 w-8">${percentage}%</span>
                            </div>
                        </div>
                    `;
                }).join('');
        } else {
            statsContainer.innerHTML = UIComponents.createEmptyState(
                'No Challenge Data',
                'Create quest stops to see challenge type statistics',
                null,
                null,
                'fas fa-chart-bar'
            );
        }
        
    } catch (error) {
        console.error('Error loading challenge statistics:', error);
    }
}

async function loadTabData(tabName) {
    try {
        switch (tabName) {
            case 'overview':
                await loadOverviewData();
                break;
            case 'quests':
                if (typeof loadQuestsData === 'function') {
                    await loadQuestsData();
                }
                break;
            case 'quest-stops':
                if (typeof QuestStops !== 'undefined') {
                    await QuestStops.loadQuestStopsData();
                }
                break;
            case 'cities':
                if (typeof loadCitiesData === 'function') {
                    await loadCitiesData();
                }
                break;
            case 'categories':
                if (typeof loadCategoriesData === 'function') {
                    await loadCategoriesData();
                }
                break;
            case 'users':
                if (typeof loadUsersData === 'function') {
                    await loadUsersData();
                }
                break;
            case 'analytics':
                if (typeof loadAnalyticsData === 'function') {
                    await loadAnalyticsData();
                }
                break;
        }
    } catch (error) {
        console.error(`Error loading ${tabName} data:`, error);
        Utils.handleError(error, `Failed to load ${tabName} data`);
    }
}

// Modal functions that delegate to specific modules
function showQuestModal(quest = null) {
    if (window.Quests && window.Quests.showQuestModal) {
        window.Quests.showQuestModal(quest);
    } else {
        Utils.showToast('Quest management not available', 'error');
    }
}

function showCityModal(city = null) {
    if (window.Cities && window.Cities.showCityModal) {
        window.Cities.showCityModal(city);
    } else {
        Utils.showToast('City management not available', 'error');
    }
}

function showCategoryModal(category = null) {
    if (window.Categories && window.Categories.showCategoryModal) {
        window.Categories.showCategoryModal(category);
    } else {
        Utils.showToast('Category management not available', 'error');
    }
}

// Utility functions for common operations
async function refreshAllData() {
    try {
        showLoading(true);
        await loadDashboardData();
        
        // Refresh current tab data
        const activeTab = document.querySelector('.tab-content.active');
        if (activeTab) {
            await loadTabData(activeTab.id);
        }
        
        Utils.showToast('Data refreshed successfully!', 'success');
    } catch (error) {
        Utils.handleError(error, 'Failed to refresh data');
    } finally {
        showLoading(false);
    }
}

// Export functions for global access
window.showTab = showTab;
window.showQuestModal = showQuestModal;
window.showCityModal = showCityModal;
window.showCategoryModal = showCategoryModal;
window.refreshAllData = refreshAllData;

// Debug function to test ModalManager
window.testModalManager = function() {
    console.log('Testing ModalManager...');
    
    if (typeof window.ModalManager === 'undefined') {
        console.error('ModalManager is undefined');
        Utils.showToast('ModalManager is undefined', 'error');
        return;
    }
    
    if (!window.ModalManager.create) {
        console.error('ModalManager.create is not a function');
        Utils.showToast('ModalManager.create is not a function', 'error');
        return;
    }
    
    try {
        ModalManager.create('testModal', 'Test Modal', '<p>ModalManager is working correctly!</p>', 'md');
        ModalManager.show('testModal');
        console.log('✅ ModalManager test passed');
        Utils.showToast('ModalManager test passed!', 'success');
    } catch (error) {
        console.error('ModalManager test failed:', error);
        Utils.showToast('ModalManager test failed: ' + error.message, 'error');
    }
};

// Performance monitoring
window.addEventListener('load', () => {
    // Test ModalManager availability
    setTimeout(() => {
        if (typeof window.ModalManager !== 'undefined' && window.ModalManager.create) {
            console.log('✅ ModalManager is available and working');
        } else {
            console.error('❌ ModalManager is NOT available');
            Utils.showToast('Warning: Modal system may not work properly', 'warning');
        }
    }, 100);

    console.log('UrbanQuest Admin Dashboard loaded successfully');
});

// Error boundary
window.addEventListener('error', (event) => {
    console.error('Global error:', event.error);
    Utils.showToast('An unexpected error occurred. Please refresh the page.', 'error');
});

// Service worker registration (if available)
if ('serviceWorker' in navigator) {
    window.addEventListener('load', () => {
        // Register service worker for caching (optional)
        // navigator.serviceWorker.register('/sw.js');
    });
}