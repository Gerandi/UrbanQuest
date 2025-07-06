// Supabase configuration
const SUPABASE_URL = 'https://tbvjpjoqlsinlkoopnwg.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRidmpwam9xbHNpbmxrb29wbndnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTEyMDU0MTcsImV4cCI6MjA2Njc4MTQxN30.DKCEuwT_8u5-LasNJQX0vRmlASwYe1TPwHkbbt60hmA';

// Initialize Supabase client
const { createClient } = supabase;
const supabaseClient = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

// Global state
let currentUser = null;
let map = null;
let selectedLocation = null;
let questStopsLayer = null;

// DOM elements
const loginForm = document.getElementById('loginForm');
const dashboard = document.getElementById('dashboard');
const loginFormElement = document.getElementById('loginFormElement');
const loginError = document.getElementById('loginError');
const logoutBtn = document.getElementById('logoutBtn');
const userEmail = document.getElementById('userEmail');
const loadingOverlay = document.getElementById('loadingOverlay');

// Initialize app
document.addEventListener('DOMContentLoaded', async () => {
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
    loginFormElement.addEventListener('submit', handleLogin);
    logoutBtn.addEventListener('click', handleLogout);
    
    // Quest Stop Modal listeners
    document.getElementById('addQuestStopBtn').addEventListener('click', showQuestStopModal);
    document.getElementById('cancelQuestStop').addEventListener('click', hideQuestStopModal);
    document.getElementById('questStopForm').addEventListener('submit', handleCreateQuestStop);
    
    // Set up tab button event listeners
    document.querySelectorAll('.tab-button').forEach(button => {
        button.addEventListener('click', (e) => {
            const tabName = e.target.getAttribute('onclick').match(/'([^']*)'/)[1];
            showTab(tabName);
        });
    });
});

// Authentication functions
async function handleLogin(e) {
    e.preventDefault();
    showLoading(true);
    
    const email = document.getElementById('email').value;
    const password = document.getElementById('password').value;
    
    try {
        const { data, error } = await supabaseClient.auth.signInWithPassword({
            email,
            password
        });
        
        if (error) throw error;
        
        // Check if user has admin privileges
        const { data: profile, error: profileError } = await supabaseClient
            .from('profiles')
            .select('role')
            .eq('id', data.user.id)
            .single();
            
        if (profileError || !['admin', 'super_admin', 'content_creator'].includes(profile?.role)) {
            await supabaseClient.auth.signOut();
            throw new Error('Admin access required');
        }
        
    } catch (error) {
        loginError.textContent = error.message;
        loginError.classList.remove('hidden');
    } finally {
        showLoading(false);
    }
}

async function handleAuthSuccess(user) {
    currentUser = user;
    userEmail.textContent = user.email;
    loginForm.classList.add('hidden');
    dashboard.classList.remove('hidden');
    loginError.classList.add('hidden');
    
    // Load dashboard data
    await loadDashboardData();
}

function handleAuthSignOut() {
    currentUser = null;
    loginForm.classList.remove('hidden');
    dashboard.classList.add('hidden');
    document.getElementById('email').value = '';
    document.getElementById('password').value = '';
}

async function handleLogout() {
    showLoading(true);
    await supabaseClient.auth.signOut();
    showLoading(false);
}

// UI functions
function showLoading(show) {
    if (show) {
        loadingOverlay.classList.remove('hidden');
    } else {
        loadingOverlay.classList.add('hidden');
    }
}

function showTab(tabName) {
    // Hide all tab contents
    document.querySelectorAll('.tab-content').forEach(content => {
        content.classList.remove('active');
    });
    
    // Remove active class from all tab buttons
    document.querySelectorAll('.tab-button').forEach(button => {
        button.classList.remove('active', 'bg-blue-500', 'text-white');
        button.classList.add('text-gray-300');
    });
    
    // Show selected tab content
    document.getElementById(tabName).classList.add('active');
    
    // Highlight active tab button
    event.target.classList.add('active', 'bg-blue-500', 'text-white');
    event.target.classList.remove('text-gray-300');
    
    // Load tab-specific data
    loadTabData(tabName);
}

// Dashboard data loading
async function loadDashboardData() {
    try {
        showLoading(true);
        await loadOverviewData();
    } catch (error) {
        console.error('Error loading dashboard data:', error);
    } finally {
        showLoading(false);
    }
}

async function loadOverviewData() {
    try {
        // Load statistics
        const [questsRes, usersRes, citiesRes, progressRes] = await Promise.all([
            supabaseClient.from('quests').select('id', { count: 'exact', head: true }),
            supabaseClient.from('profiles').select('id', { count: 'exact', head: true }),
            supabaseClient.from('cities').select('id', { count: 'exact', head: true }),
            supabaseClient.from('user_quest_progress').select('id').eq('status', 'completed')
        ]);
        
        document.getElementById('totalQuests').textContent = questsRes.count || 0;
        document.getElementById('totalUsers').textContent = usersRes.count || 0;
        document.getElementById('totalCities').textContent = citiesRes.count || 0;
        document.getElementById('totalCompletions').textContent = progressRes.data?.length || 0;
        
        // Load recent activity
        const { data: recentProgress } = await supabaseClient
            .from('user_quest_progress')
            .select(`
                *,
                profiles(display_name, email),
                quests(title)
            `)
            .order('updated_at', { ascending: false })
            .limit(10);
            
        const activityContainer = document.getElementById('recentActivity');
        if (recentProgress && recentProgress.length > 0) {
            activityContainer.innerHTML = recentProgress.map(progress => `
                <div class="flex justify-between items-center py-2 border-b border-gray-100">
                    <div>
                        <p class="font-medium">${progress.profiles?.display_name || progress.profiles?.email || 'Unknown User'}</p>
                        <p class="text-sm text-gray-600">${progress.status === 'completed' ? 'Completed' : 'Started'} "${progress.quests?.title || 'Unknown Quest'}"</p>
                    </div>
                    <span class="text-sm text-gray-500">${new Date(progress.updated_at).toLocaleDateString()}</span>
                </div>
            `).join('');
        } else {
            activityContainer.innerHTML = '<p class="text-gray-500">No recent activity</p>';
        }
        
    } catch (error) {
        console.error('Error loading overview data:', error);
    }
}

async function loadTabData(tabName) {
    switch (tabName) {
        case 'quests':
            await loadQuestsData();
            break;
        case 'cities':
            await loadCitiesData();
            break;
        case 'users':
            await loadUsersData();
            break;
        case 'achievements':
            await loadAchievementsData();
            break;
        case 'quest-stops':
            await loadQuestStopsData();
            break;
    }
}

async function loadQuestsData() {
    try {
        const { data: quests, error } = await supabaseClient
            .from('quests_with_city')
            .select(`
                *,
                quest_categories(name, color)
            `)
            .order('created_at', { ascending: false });
            
        if (error) throw error;
        
        const questsList = document.getElementById('questsList');
        if (quests && quests.length > 0) {
            questsList.innerHTML = quests.map(quest => `
                <div class="border border-gray-200 rounded-lg p-4">
                    <div class="flex justify-between items-start">
                        <div class="flex-1">
                            <h4 class="font-semibold text-lg">${quest.title}</h4>
                            <p class="text-gray-600 mt-1">${quest.description || 'No description'}</p>
                            <div class="flex items-center mt-2 space-x-4">
                                <span class="text-sm bg-blue-100 text-blue-800 px-2 py-1 rounded">${quest.city_name || 'Unknown City'}</span>
                                <span class="text-sm bg-green-100 text-green-800 px-2 py-1 rounded">${quest.difficulty || 'Unknown'}</span>
                                <span class="text-sm bg-purple-100 text-purple-800 px-2 py-1 rounded">${quest.number_of_stops} stops</span>
                                <span class="text-sm ${quest.is_active ? 'bg-green-100 text-green-800' : 'bg-red-100 text-red-800'} px-2 py-1 rounded">
                                    ${quest.is_active ? 'Active' : 'Inactive'}
                                </span>
                            </div>
                        </div>
                        <div class="flex space-x-2">
                            <button onclick="editQuest('${quest.id}')" 
                                    class="bg-blue-500 hover:bg-blue-700 text-white font-bold py-1 px-3 rounded text-sm">
                                Edit
                            </button>
                            <button onclick="deleteQuest('${quest.id}')" 
                                    class="bg-red-500 hover:bg-red-700 text-white font-bold py-1 px-3 rounded text-sm">
                                Delete
                            </button>
                        </div>
                    </div>
                </div>
            `).join('');
        } else {
            questsList.innerHTML = '<p class="text-gray-500">No quests found</p>';
        }
    } catch (error) {
        console.error('Error loading quests:', error);
    }
}

async function loadCitiesData() {
    try {
        const { data: cities, error } = await supabaseClient
            .from('cities')
            .select(`
                *,
                countries(name)
            `)
            .order('created_at', { ascending: false });
            
        if (error) throw error;
        
        const citiesList = document.getElementById('citiesList');
        if (cities && cities.length > 0) {
            citiesList.innerHTML = cities.map(city => `
                <div class="border border-gray-200 rounded-lg p-4">
                    <div class="flex justify-between items-start">
                        <div class="flex-1">
                            <h4 class="font-semibold text-lg">${city.name}</h4>
                            <p class="text-gray-600 mt-1">${city.description || 'No description'}</p>
                            <div class="flex items-center mt-2 space-x-4">
                                <span class="text-sm bg-blue-100 text-blue-800 px-2 py-1 rounded">${city.countries?.name || 'Unknown Country'}</span>
                                <span class="text-sm bg-green-100 text-green-800 px-2 py-1 rounded">${city.quest_count || 0} quests</span>
                                <span class="text-sm ${city.is_active ? 'bg-green-100 text-green-800' : 'bg-red-100 text-red-800'} px-2 py-1 rounded">
                                    ${city.is_active ? 'Active' : 'Inactive'}
                                </span>
                            </div>
                        </div>
                        <div class="flex space-x-2">
                            <button onclick="editCity('${city.id}')" 
                                    class="bg-blue-500 hover:bg-blue-700 text-white font-bold py-1 px-3 rounded text-sm">
                                Edit
                            </button>
                            <button onclick="deleteCity('${city.id}')" 
                                    class="bg-red-500 hover:bg-red-700 text-white font-bold py-1 px-3 rounded text-sm">
                                Delete
                            </button>
                        </div>
                    </div>
                </div>
            `).join('');
        } else {
            citiesList.innerHTML = '<p class="text-gray-500">No cities found</p>';
        }
    } catch (error) {
        console.error('Error loading cities:', error);
    }
}

async function loadUsersData() {
    try {
        const { data: users, error } = await supabaseClient
            .from('profiles')
            .select('*')
            .order('created_at', { ascending: false });
            
        if (error) throw error;
        
        const usersList = document.getElementById('usersList');
        if (users && users.length > 0) {
            usersList.innerHTML = users.map(user => `
                <div class="border border-gray-200 rounded-lg p-4">
                    <div class="flex justify-between items-start">
                        <div class="flex-1">
                            <h4 class="font-semibold text-lg">${user.display_name || user.email}</h4>
                            <p class="text-gray-600 mt-1">${user.email}</p>
                            <div class="flex items-center mt-2 space-x-4">
                                <span class="text-sm bg-blue-100 text-blue-800 px-2 py-1 rounded">Level ${user.level || 1}</span>
                                <span class="text-sm bg-green-100 text-green-800 px-2 py-1 rounded">${user.total_points || 0} points</span>
                                <span class="text-sm bg-purple-100 text-purple-800 px-2 py-1 rounded">${user.quests_completed || 0} completed</span>
                                <span class="text-sm bg-orange-100 text-orange-800 px-2 py-1 rounded">${user.role || 'user'}</span>
                            </div>
                        </div>
                        <div class="flex space-x-2">
                            <button onclick="editUser('${user.id}')" 
                                    class="bg-blue-500 hover:bg-blue-700 text-white font-bold py-1 px-3 rounded text-sm">
                                Edit
                            </button>
                        </div>
                    </div>
                </div>
            `).join('');
        } else {
            usersList.innerHTML = '<p class="text-gray-500">No users found</p>';
        }
    } catch (error) {
        console.error('Error loading users:', error);
    }
}

async function loadAchievementsData() {
    try {
        const { data: achievements, error } = await supabaseClient
            .from('achievements')
            .select('*')
            .order('created_at', { ascending: false });
            
        if (error) throw error;
        
        const achievementsList = document.getElementById('achievementsList');
        if (achievements && achievements.length > 0) {
            achievementsList.innerHTML = achievements.map(achievement => `
                <div class="border border-gray-200 rounded-lg p-4">
                    <div class="flex justify-between items-start">
                        <div class="flex-1">
                            <h4 class="font-semibold text-lg">${achievement.title}</h4>
                            <p class="text-gray-600 mt-1">${achievement.description || 'No description'}</p>
                            <div class="flex items-center mt-2 space-x-4">
                                <span class="text-sm bg-blue-100 text-blue-800 px-2 py-1 rounded">${achievement.condition_type}</span>
                                <span class="text-sm bg-green-100 text-green-800 px-2 py-1 rounded">${achievement.points || 0} points</span>
                                <span class="text-sm bg-purple-100 text-purple-800 px-2 py-1 rounded">Threshold: ${achievement.condition_threshold}</span>
                                <span class="text-sm ${achievement.is_active ? 'bg-green-100 text-green-800' : 'bg-red-100 text-red-800'} px-2 py-1 rounded">
                                    ${achievement.is_active ? 'Active' : 'Inactive'}
                                </span>
                            </div>
                        </div>
                        <div class="flex space-x-2">
                            <button onclick="editAchievement('${achievement.id}')" 
                                    class="bg-blue-500 hover:bg-blue-700 text-white font-bold py-1 px-3 rounded text-sm">
                                Edit
                            </button>
                            <button onclick="deleteAchievement('${achievement.id}')" 
                                    class="bg-red-500 hover:bg-red-700 text-white font-bold py-1 px-3 rounded text-sm">
                                Delete
                            </button>
                        </div>
                    </div>
                </div>
            `).join('');
        } else {
            achievementsList.innerHTML = '<p class="text-gray-500">No achievements found</p>';
        }
    } catch (error) {
        console.error('Error loading achievements:', error);
    }
}

// Map functionality
function initializeMap() {
    if (map) return; // Map already initialized
    
    // Initialize map centered on Tirana, Albania
    map = L.map('map').setView([41.3275, 19.8187], 13);
    
    // Add OpenStreetMap tiles
    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
        attribution: '© <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
    }).addTo(map);
    
    // Initialize quest stops layer
    questStopsLayer = L.layerGroup().addTo(map);
    
    // Add click event listener
    map.on('click', function(e) {
        selectedLocation = {
            lat: e.latlng.lat,
            lng: e.latlng.lng
        };
        
        // Update location display
        document.getElementById('locationDisplay').textContent = 
            `${e.latlng.lat.toFixed(6)}, ${e.latlng.lng.toFixed(6)}`;
        
        // Add temporary marker
        questStopsLayer.clearLayers();
        loadExistingQuestStops(); // Reload existing stops
        
        // Add selected location marker
        L.marker([e.latlng.lat, e.latlng.lng], {
            icon: L.icon({
                iconUrl: 'https://raw.githubusercontent.com/pointhi/leaflet-color-markers/master/img/marker-icon-2x-green.png',
                shadowUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/0.7.7/images/marker-shadow.png',
                iconSize: [25, 41],
                iconAnchor: [12, 41],
                popupAnchor: [1, -34],
                shadowSize: [41, 41]
            })
        }).addTo(questStopsLayer).bindPopup('Selected location for new quest stop');
    });
}

async function loadExistingQuestStops() {
    try {
        const { data: questStops, error } = await supabaseClient
            .from('quest_stops')
            .select(`
                *,
                quests(title)
            `);
            
        if (error) throw error;
        
        questStops?.forEach(stop => {
            L.marker([stop.latitude, stop.longitude], {
                icon: L.icon({
                    iconUrl: 'https://raw.githubusercontent.com/pointhi/leaflet-color-markers/master/img/marker-icon-2x-red.png',
                    shadowUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/0.7.7/images/marker-shadow.png',
                    iconSize: [25, 41],
                    iconAnchor: [12, 41],
                    popupAnchor: [1, -34],
                    shadowSize: [41, 41]
                })
            }).addTo(questStopsLayer).bindPopup(`
                <strong>${stop.title}</strong><br>
                Quest: ${stop.quests?.title || 'Unknown'}<br>
                Type: ${stop.challenge_type}<br>
                Points: ${stop.points}
            `);
        });
    } catch (error) {
        console.error('Error loading quest stops on map:', error);
    }
}

async function loadQuestStopsData() {
    try {
        // Initialize map if not already done
        initializeMap();
        
        // Load quest stops for the list
        const { data: questStops, error } = await supabaseClient
            .from('quest_stops')
            .select(`
                *,
                quests(title, id)
            `)
            .order('created_at', { ascending: false });
            
        if (error) throw error;
        
        // Load existing stops on map
        await loadExistingQuestStops();
        
        // Load quests for the dropdown
        await loadQuestsForDropdown();
        
        const questStopsList = document.getElementById('questStopsList');
        if (questStops && questStops.length > 0) {
            questStopsList.innerHTML = questStops.map(stop => `
                <div class="border border-gray-200 rounded p-3">
                    <div class="flex justify-between items-start">
                        <div class="flex-1">
                            <h5 class="font-medium">${stop.title}</h5>
                            <p class="text-sm text-gray-600">${stop.quests?.title || 'No Quest'}</p>
                            <div class="flex items-center mt-1 space-x-2">
                                <span class="text-xs bg-blue-100 text-blue-800 px-2 py-1 rounded">${stop.challenge_type}</span>
                                <span class="text-xs bg-green-100 text-green-800 px-2 py-1 rounded">${stop.points} pts</span>
                            </div>
                        </div>
                        <div class="flex space-x-1">
                            <button onclick="editQuestStop('${stop.id}')" 
                                    class="bg-blue-500 hover:bg-blue-700 text-white font-bold py-1 px-2 rounded text-xs">
                                Edit
                            </button>
                            <button onclick="deleteQuestStop('${stop.id}')" 
                                    class="bg-red-500 hover:bg-red-700 text-white font-bold py-1 px-2 rounded text-xs">
                                Del
                            </button>
                        </div>
                    </div>
                </div>
            `).join('');
        } else {
            questStopsList.innerHTML = '<p class="text-gray-500">No quest stops found</p>';
        }
    } catch (error) {
        console.error('Error loading quest stops:', error);
    }
}

async function loadQuestsForDropdown() {
    try {
        const { data: quests, error } = await supabaseClient
            .from('quests')
            .select('id, title')
            .eq('is_active', true)
            .order('title');
            
        if (error) throw error;
        
        const questSelect = document.getElementById('questSelect');
        questSelect.innerHTML = '<option value="">Select a quest...</option>' + 
            quests.map(quest => `<option value="${quest.id}">${quest.title}</option>`).join('');
    } catch (error) {
        console.error('Error loading quests for dropdown:', error);
    }
}

function showQuestStopModal() {
    if (!selectedLocation) {
        alert('Please select a location on the map first!');
        return;
    }
    document.getElementById('questStopModal').classList.remove('hidden');
}

function hideQuestStopModal() {
    document.getElementById('questStopModal').classList.add('hidden');
    // Reset form
    document.getElementById('questStopForm').reset();
}

async function handleCreateQuestStop(e) {
    e.preventDefault();
    
    if (!selectedLocation) {
        alert('Please select a location on the map first!');
        return;
    }
    
    showLoading(true);
    
    try {
        const formData = new FormData(e.target);
        const questStopData = {
            quest_id: document.getElementById('questSelect').value,
            title: document.getElementById('stopTitle').value,
            description: document.getElementById('stopDescription').value,
            challenge_type: document.getElementById('challengeType').value,
            points: parseInt(document.getElementById('stopPoints').value),
            latitude: selectedLocation.lat,
            longitude: selectedLocation.lng,
            order_index: 1, // Default order
            is_required: true,
            created_at: new Date().toISOString()
        };
        
        const { error } = await supabaseClient
            .from('quest_stops')
            .insert([questStopData]);
            
        if (error) throw error;
        
        alert('Quest stop created successfully!');
        hideQuestStopModal();
        selectedLocation = null;
        document.getElementById('locationDisplay').textContent = 'None selected';
        
        // Reload quest stops
        await loadQuestStopsData();
        
    } catch (error) {
        console.error('Error creating quest stop:', error);
        alert('Error creating quest stop: ' + error.message);
    } finally {
        showLoading(false);
    }
}

// Enhanced CRUD operations
async function editQuest(questId) {
    const newTitle = prompt('Enter new quest title:');
    if (!newTitle) return;
    
    try {
        showLoading(true);
        const { error } = await supabaseClient
            .from('quests')
            .update({ title: newTitle, updated_at: new Date().toISOString() })
            .eq('id', questId);
            
        if (error) throw error;
        
        alert('Quest updated successfully!');
        await loadQuestsData();
    } catch (error) {
        alert('Error updating quest: ' + error.message);
    } finally {
        showLoading(false);
    }
}

async function deleteQuest(questId) {
    if (!confirm('Are you sure you want to delete this quest? This will also delete all associated quest stops.')) return;
    
    try {
        showLoading(true);
        
        // First delete quest stops
        await supabaseClient
            .from('quest_stops')
            .delete()
            .eq('quest_id', questId);
            
        // Then delete the quest
        const { error } = await supabaseClient
            .from('quests')
            .delete()
            .eq('id', questId);
            
        if (error) throw error;
        
        alert('Quest deleted successfully!');
        await loadQuestsData();
    } catch (error) {
        alert('Error deleting quest: ' + error.message);
    } finally {
        showLoading(false);
    }
}

async function editCity(cityId) {
    const newName = prompt('Enter new city name:');
    if (!newName) return;
    
    try {
        showLoading(true);
        const { error } = await supabaseClient
            .from('cities')
            .update({ name: newName, updated_at: new Date().toISOString() })
            .eq('id', cityId);
            
        if (error) throw error;
        
        alert('City updated successfully!');
        await loadCitiesData();
    } catch (error) {
        alert('Error updating city: ' + error.message);
    } finally {
        showLoading(false);
    }
}

async function deleteCity(cityId) {
    if (!confirm('Are you sure you want to delete this city? This will also affect all associated quests.')) return;
    
    try {
        showLoading(true);
        const { error } = await supabaseClient
            .from('cities')
            .delete()
            .eq('id', cityId);
            
        if (error) throw error;
        
        alert('City deleted successfully!');
        await loadCitiesData();
    } catch (error) {
        alert('Error deleting city: ' + error.message);
    } finally {
        showLoading(false);
    }
}

async function editUser(userId) {
    const newRole = prompt('Enter new user role (user, content_creator, moderator, admin):');
    if (!newRole || !['user', 'content_creator', 'moderator', 'admin'].includes(newRole)) {
        alert('Invalid role. Please use: user, content_creator, moderator, or admin');
        return;
    }
    
    try {
        showLoading(true);
        const { error } = await supabaseClient
            .from('profiles')
            .update({ role: newRole, updated_at: new Date().toISOString() })
            .eq('id', userId);
            
        if (error) throw error;
        
        alert('User role updated successfully!');
        await loadUsersData();
    } catch (error) {
        alert('Error updating user: ' + error.message);
    } finally {
        showLoading(false);
    }
}

async function editAchievement(achievementId) {
    const newTitle = prompt('Enter new achievement title:');
    if (!newTitle) return;
    
    try {
        showLoading(true);
        const { error } = await supabaseClient
            .from('achievements')
            .update({ title: newTitle, updated_at: new Date().toISOString() })
            .eq('id', achievementId);
            
        if (error) throw error;
        
        alert('Achievement updated successfully!');
        await loadAchievementsData();
    } catch (error) {
        alert('Error updating achievement: ' + error.message);
    } finally {
        showLoading(false);
    }
}

async function deleteAchievement(achievementId) {
    if (!confirm('Are you sure you want to delete this achievement?')) return;
    
    try {
        showLoading(true);
        const { error } = await supabaseClient
            .from('achievements')
            .delete()
            .eq('id', achievementId);
            
        if (error) throw error;
        
        alert('Achievement deleted successfully!');
        await loadAchievementsData();
    } catch (error) {
        alert('Error deleting achievement: ' + error.message);
    } finally {
        showLoading(false);
    }
}

// Quest Stop CRUD operations
async function editQuestStop(stopId) {
    const newTitle = prompt('Enter new quest stop title:');
    if (!newTitle) return;
    
    try {
        showLoading(true);
        const { error } = await supabaseClient
            .from('quest_stops')
            .update({ title: newTitle, updated_at: new Date().toISOString() })
            .eq('id', stopId);
            
        if (error) throw error;
        
        alert('Quest stop updated successfully!');
        await loadQuestStopsData();
    } catch (error) {
        alert('Error updating quest stop: ' + error.message);
    } finally {
        showLoading(false);
    }
}

async function deleteQuestStop(stopId) {
    if (!confirm('Are you sure you want to delete this quest stop?')) return;
    
    try {
        showLoading(true);
        const { error } = await supabaseClient
            .from('quest_stops')
            .delete()
            .eq('id', stopId);
            
        if (error) throw error;
        
        alert('Quest stop deleted successfully!');
        await loadQuestStopsData();
    } catch (error) {
        alert('Error deleting quest stop: ' + error.message);
    } finally {
        showLoading(false);
    }
} 