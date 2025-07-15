// Analytics Dashboard

// Load analytics data for the main view
async function loadAnalyticsData() {
    try {
        Utils.showElementLoading('analyticsContent');
        
        // Load all analytics data in parallel
        await Promise.all([
            loadUserAnalytics(),
            loadQuestAnalytics(),
            loadEngagementAnalytics(),
            loadPerformanceAnalytics()
        ]);
        
    } catch (error) {
        Utils.handleError(error, 'Failed to load analytics');
        const analyticsContent = document.getElementById('analyticsContent');
        if (analyticsContent) {
            analyticsContent.innerHTML = `
                <div class="text-center py-8">
                    <i class="fas fa-exclamation-triangle text-red-500 text-3xl mb-4"></i>
                    <p class="text-red-600">Failed to load analytics</p>
                </div>
            `;
        }
    }
}

// User Analytics
async function loadUserAnalytics() {
    try {
        const [usersRes, newUsersRes, activeUsersRes] = await Promise.all([
            supabaseClient.from('profiles').select('id, created_at', { count: 'exact', head: true }),
            supabaseClient.from('profiles').select('id').gte('created_at', new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString()),
            supabaseClient.from('profiles').select('id').gte('last_active', new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString())
        ]);
        
        const totalUsers = usersRes.count || 0;
        const newUsers = newUsersRes.data?.length || 0;
        const activeUsers = activeUsersRes.data?.length || 0;
        const retentionRate = totalUsers > 0 ? Math.round((activeUsers / totalUsers) * 100) : 0;
        
        const userAnalyticsContainer = document.getElementById('userAnalytics');
        if (userAnalyticsContainer) {
            userAnalyticsContainer.innerHTML = `
                <div class="grid grid-cols-2 md:grid-cols-4 gap-4">
                    ${UIComponents.createStatCard('Total Users', Utils.formatNumber(totalUsers), 'fas fa-users', 'blue')}
                    ${UIComponents.createStatCard('New Users (30d)', Utils.formatNumber(newUsers), 'fas fa-user-plus', 'green')}
                    ${UIComponents.createStatCard('Active Users (7d)', Utils.formatNumber(activeUsers), 'fas fa-user-check', 'purple')}
                    ${UIComponents.createStatCard('Retention Rate', `${retentionRate}%`, 'fas fa-chart-line', 'orange')}
                </div>
            `;
        }
        
    } catch (error) {
        console.error('Error loading user analytics:', error);
    }
}

// Quest Analytics
async function loadQuestAnalytics() {
    try {
        const [questsRes, completionsRes] = await Promise.all([
            supabaseClient.from('quests').select('id, is_active', { count: 'exact' }),
            supabaseClient.from('user_quest_progress').select('id').eq('status', 'completed')
        ]);
        
        const totalQuests = questsRes.count || 0;
        const activeQuests = questsRes.data?.filter(q => q.is_active).length || 0;
        const totalCompletions = completionsRes.data?.length || 0;
        const avgRating = 'N/A'; // Rating field doesn't exist in current schema
        
        const questAnalyticsContainer = document.getElementById('questAnalytics');
        if (questAnalyticsContainer) {
            questAnalyticsContainer.innerHTML = `
                <div class="grid grid-cols-2 md:grid-cols-4 gap-4">
                    ${UIComponents.createStatCard('Total Quests', Utils.formatNumber(totalQuests), 'fas fa-map', 'blue')}
                    ${UIComponents.createStatCard('Active Quests', Utils.formatNumber(activeQuests), 'fas fa-play', 'green')}
                    ${UIComponents.createStatCard('Completions', Utils.formatNumber(totalCompletions), 'fas fa-check-circle', 'purple')}
                    ${UIComponents.createStatCard('Avg Rating', avgRating, 'fas fa-star', 'yellow')}
                </div>
            `;
        }
        
        // Load popular quests
        await loadPopularQuests();
        
    } catch (error) {
        console.error('Error loading quest analytics:', error);
    }
}

// Engagement Analytics
async function loadEngagementAnalytics() {
    try {
        // Get quest completion data for the last 30 days
        const { data: recentActivity } = await supabaseClient
            .from('user_quest_progress')
            .select('created_at, completed_at, status')
            .gte('created_at', new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString())
            .order('created_at');
        
        // Get challenge type distribution
        const { data: challengeStats } = await supabaseClient
            .from('quest_stops')
            .select('challenge_type');
        
        const engagementContainer = document.getElementById('engagementAnalytics');
        if (engagementContainer) {
            engagementContainer.innerHTML = `
                <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
                    <div class="bg-white p-6 rounded-lg border border-gray-200">
                        <h4 class="font-semibold text-gray-900 mb-4">Activity Timeline (30 days)</h4>
                        <div id="activityChart" class="h-64">
                            ${createActivityChart(recentActivity || [])}
                        </div>
                    </div>
                    
                    <div class="bg-white p-6 rounded-lg border border-gray-200">
                        <h4 class="font-semibold text-gray-900 mb-4">Challenge Type Distribution</h4>
                        <div id="challengeChart" class="h-64">
                            ${createChallengeChart(challengeStats || [])}
                        </div>
                    </div>
                </div>
            `;
        }
        
    } catch (error) {
        console.error('Error loading engagement analytics:', error);
    }
}

// Performance Analytics
async function loadPerformanceAnalytics() {
    try {
        // Get completion rates by difficulty
        const { data: questsWithCompletion } = await supabaseClient
            .from('quests')
            .select(`
                difficulty,
                user_quest_progress(status)
            `);
        
        // Get average completion times
        const { data: completionTimes } = await supabaseClient
            .from('user_quest_progress')
            .select('started_at, completed_at')
            .eq('status', 'completed')
            .not('started_at', 'is', null)
            .not('completed_at', 'is', null);
        
        const performanceContainer = document.getElementById('performanceAnalytics');
        if (performanceContainer) {
            performanceContainer.innerHTML = `
                <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
                    <div class="bg-white p-6 rounded-lg border border-gray-200">
                        <h4 class="font-semibold text-gray-900 mb-4">Completion Rates by Difficulty</h4>
                        <div id="difficultyChart" class="h-64">
                            ${createDifficultyChart(questsWithCompletion || [])}
                        </div>
                    </div>
                    
                    <div class="bg-white p-6 rounded-lg border border-gray-200">
                        <h4 class="font-semibold text-gray-900 mb-4">Performance Metrics</h4>
                        <div id="performanceMetrics" class="h-64">
                            ${createPerformanceMetrics(completionTimes || [])}
                        </div>
                    </div>
                </div>
            `;
        }
        
    } catch (error) {
        console.error('Error loading performance analytics:', error);
    }
}

// Load popular quests
async function loadPopularQuests() {
    try {
        const { data: popularQuests } = await supabaseClient
            .from('quests')
            .select(`
                *,
                user_quest_progress(id, status),
                cities(name)
            `)
            .limit(10);
        
        if (!popularQuests) return;
        
        // Calculate popularity score based on completions
        const questsWithStats = popularQuests.map(quest => {
            const progress = quest.user_quest_progress || [];
            const completions = progress.filter(p => p.status === 'completed').length;
            const avgRating = 0; // Rating system not implemented
            
            return {
                ...quest,
                completions,
                avgRating,
                popularityScore: completions
            };
        }).sort((a, b) => b.popularityScore - a.popularityScore);
        
        const popularQuestsContainer = document.getElementById('popularQuests');
        if (popularQuestsContainer) {
            popularQuestsContainer.innerHTML = `
                <div class="bg-white p-6 rounded-lg border border-gray-200">
                    <h4 class="font-semibold text-gray-900 mb-4">Most Popular Quests</h4>
                    <div class="space-y-3">
                        ${questsWithStats.slice(0, 5).map((quest, index) => `
                            <div class="flex items-center justify-between p-3 bg-gray-50 rounded-lg">
                                <div class="flex items-center">
                                    <span class="flex items-center justify-center w-8 h-8 bg-blue-100 text-blue-800 text-sm font-bold rounded-full mr-3">
                                        ${index + 1}
                                    </span>
                                    <div>
                                        <div class="font-medium text-gray-900">${quest.title}</div>
                                        <div class="text-sm text-gray-600">${quest.cities?.name || 'Unknown City'}</div>
                                    </div>
                                </div>
                                <div class="text-right">
                                    <div class="text-sm font-medium text-gray-900">${quest.completions} completions</div>
                                    <div class="text-xs text-gray-500">
                                        ${quest.avgRating > 0 ? `★ ${quest.avgRating.toFixed(1)}` : 'No ratings'}
                                    </div>
                                </div>
                            </div>
                        `).join('')}
                    </div>
                </div>
            `;
        }
        
    } catch (error) {
        console.error('Error loading popular quests:', error);
    }
}

// Create activity chart (simplified version)
function createActivityChart(data) {
    if (!data || data.length === 0) {
        return `
            <div class="flex items-center justify-center h-full text-gray-500">
                <div class="text-center">
                    <i class="fas fa-chart-line text-3xl mb-2"></i>
                    <p>No activity data available</p>
                </div>
            </div>
        `;
    }
    
    // Group by date
    const dailyStats = {};
    data.forEach(item => {
        const date = new Date(item.created_at).toISOString().split('T')[0];
        if (!dailyStats[date]) {
            dailyStats[date] = { started: 0, completed: 0 };
        }
        dailyStats[date].started++;
        if (item.status === 'completed' && item.completed_at) {
            const completedDate = new Date(item.completed_at).toISOString().split('T')[0];
            if (!dailyStats[completedDate]) {
                dailyStats[completedDate] = { started: 0, completed: 0 };
            }
            dailyStats[completedDate].completed++;
        }
    });
    
    const dates = Object.keys(dailyStats).sort().slice(-7); // Last 7 days
    
    return `
        <div class="space-y-2">
            ${dates.map(date => {
                const stats = dailyStats[date];
                const maxValue = Math.max(...Object.values(dailyStats).map(s => Math.max(s.started, s.completed)));
                const startedWidth = maxValue > 0 ? (stats.started / maxValue) * 100 : 0;
                const completedWidth = maxValue > 0 ? (stats.completed / maxValue) * 100 : 0;
                
                return `
                    <div class="mb-3">
                        <div class="flex justify-between text-sm text-gray-600 mb-1">
                            <span>${new Date(date).toLocaleDateString()}</span>
                            <span>${stats.started} started, ${stats.completed} completed</span>
                        </div>
                        <div class="space-y-1">
                            <div class="w-full bg-gray-200 rounded-full h-2">
                                <div class="bg-blue-600 h-2 rounded-full" style="width: ${startedWidth}%"></div>
                            </div>
                            <div class="w-full bg-gray-200 rounded-full h-2">
                                <div class="bg-green-600 h-2 rounded-full" style="width: ${completedWidth}%"></div>
                            </div>
                        </div>
                    </div>
                `;
            }).join('')}
        </div>
    `;
}

// Create challenge type distribution chart
function createChallengeChart(data) {
    if (!data || data.length === 0) {
        return `
            <div class="flex items-center justify-center h-full text-gray-500">
                <div class="text-center">
                    <i class="fas fa-chart-pie text-3xl mb-2"></i>
                    <p>No challenge data available</p>
                </div>
            </div>
        `;
    }
    
    const grouped = Utils.groupBy(data, 'challenge_type');
    const total = data.length;
    
    return `
        <div class="space-y-3">
            ${Object.entries(grouped).map(([type, items]) => {
                const config = CONFIG.CHALLENGE_TYPES[type] || CONFIG.CHALLENGE_TYPES.text;
                const count = items.length;
                const percentage = Math.round((count / total) * 100);
                
                return `
                    <div class="flex items-center justify-between">
                        <div class="flex items-center">
                            <i class="${config.icon} text-${config.color}-600 mr-3"></i>
                            <span class="text-sm font-medium text-gray-900">${config.name}</span>
                        </div>
                        <div class="flex items-center space-x-2">
                            <span class="text-sm text-gray-600">${count}</span>
                            <div class="w-20 bg-gray-200 rounded-full h-2">
                                <div class="bg-${config.color}-600 h-2 rounded-full" style="width: ${percentage}%"></div>
                            </div>
                            <span class="text-xs text-gray-500 w-8">${percentage}%</span>
                        </div>
                    </div>
                `;
            }).join('')}
        </div>
    `;
}

// Create difficulty completion rates chart
function createDifficultyChart(data) {
    const difficultyStats = {};
    
    data.forEach(quest => {
        const difficulty = quest.difficulty || 'unknown';
        if (!difficultyStats[difficulty]) {
            difficultyStats[difficulty] = { total: 0, completed: 0 };
        }
        difficultyStats[difficulty].total++;
        
        const completions = quest.user_quest_progress?.filter(p => p.status === 'completed').length || 0;
        difficultyStats[difficulty].completed += completions;
    });
    
    return `
        <div class="space-y-3">
            ${Object.entries(difficultyStats).map(([difficulty, stats]) => {
                const rate = stats.total > 0 ? Math.round((stats.completed / stats.total) * 100) : 0;
                const color = difficulty === 'easy' ? 'green' : 
                            difficulty === 'medium' ? 'yellow' :
                            difficulty === 'hard' ? 'orange' : 'red';
                
                return `
                    <div class="flex items-center justify-between">
                        <div class="flex items-center">
                            <span class="text-sm font-medium text-gray-900 capitalize">${difficulty}</span>
                        </div>
                        <div class="flex items-center space-x-2">
                            <span class="text-sm text-gray-600">${stats.completed}/${stats.total}</span>
                            <div class="w-20 bg-gray-200 rounded-full h-2">
                                <div class="bg-${color}-600 h-2 rounded-full" style="width: ${rate}%"></div>
                            </div>
                            <span class="text-xs text-gray-500 w-8">${rate}%</span>
                        </div>
                    </div>
                `;
            }).join('')}
        </div>
    `;
}

// Create performance metrics
function createPerformanceMetrics(data) {
    if (!data || data.length === 0) {
        return `
            <div class="flex items-center justify-center h-full text-gray-500">
                <div class="text-center">
                    <i class="fas fa-chart-bar text-3xl mb-2"></i>
                    <p>No completion data available</p>
                </div>
            </div>
        `;
    }
    
    // Calculate metrics
    const completionTimes = data.map(item => {
        const started = new Date(item.started_at);
        const completed = new Date(item.completed_at);
        return (completed - started) / (1000 * 60); // minutes
    }).filter(time => time > 0);
    
    const avgCompletionTime = completionTimes.length > 0 
        ? Math.round(completionTimes.reduce((sum, time) => sum + time, 0) / completionTimes.length)
        : 0;
    
    const medianTime = completionTimes.length > 0 
        ? completionTimes.sort((a, b) => a - b)[Math.floor(completionTimes.length / 2)]
        : 0;
    
    return `
        <div class="space-y-4">
            <div class="grid grid-cols-2 gap-4">
                <div class="text-center p-4 bg-blue-50 rounded-lg">
                    <div class="text-2xl font-bold text-blue-600">${avgCompletionTime}</div>
                    <div class="text-sm text-blue-800">Avg Time (min)</div>
                </div>
                <div class="text-center p-4 bg-green-50 rounded-lg">
                    <div class="text-2xl font-bold text-green-600">${Math.round(medianTime)}</div>
                    <div class="text-sm text-green-800">Median Time (min)</div>
                </div>
            </div>
            
            <div class="space-y-2">
                <h5 class="font-medium text-gray-700">Completion Time Distribution</h5>
                ${createTimeDistribution(completionTimes)}
            </div>
        </div>
    `;
}

// Create time distribution chart
function createTimeDistribution(times) {
    if (times.length === 0) return '<p class="text-gray-500 text-sm">No data available</p>';
    
    const buckets = [
        { label: '< 30 min', min: 0, max: 30 },
        { label: '30-60 min', min: 30, max: 60 },
        { label: '60-120 min', min: 60, max: 120 },
        { label: '120+ min', min: 120, max: Infinity }
    ];
    
    const distribution = buckets.map(bucket => {
        const count = times.filter(time => time >= bucket.min && time < bucket.max).length;
        const percentage = Math.round((count / times.length) * 100);
        return { ...bucket, count, percentage };
    });
    
    return `
        <div class="space-y-2">
            ${distribution.map(bucket => `
                <div class="flex items-center justify-between">
                    <span class="text-sm text-gray-600">${bucket.label}</span>
                    <div class="flex items-center space-x-2">
                        <span class="text-sm text-gray-600">${bucket.count}</span>
                        <div class="w-16 bg-gray-200 rounded-full h-2">
                            <div class="bg-purple-600 h-2 rounded-full" style="width: ${bucket.percentage}%"></div>
                        </div>
                        <span class="text-xs text-gray-500 w-8">${bucket.percentage}%</span>
                    </div>
                </div>
            `).join('')}
        </div>
    `;
}

// Export analytics data
async function exportAnalyticsData() {
    try {
        showLoading(true);
        
        const [users, quests, progress, stops] = await Promise.all([
            supabaseClient.from('profiles').select('*'),
            supabaseClient.from('quests').select('*'),
            supabaseClient.from('user_quest_progress').select('*'),
            supabaseClient.from('quest_stops').select('*')
        ]);
        
        const analyticsData = {
            exported_at: new Date().toISOString(),
            summary: {
                total_users: users.data?.length || 0,
                total_quests: quests.data?.length || 0,
                total_progress_records: progress.data?.length || 0,
                total_quest_stops: stops.data?.length || 0
            },
            detailed_data: {
                users: users.data || [],
                quests: quests.data || [],
                progress: progress.data || [],
                stops: stops.data || []
            }
        };
        
        const blob = new Blob([JSON.stringify(analyticsData, null, 2)], { type: 'application/json' });
        const url = URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = `analytics_export_${new Date().toISOString().split('T')[0]}.json`;
        document.body.appendChild(a);
        a.click();
        document.body.removeChild(a);
        URL.revokeObjectURL(url);
        
        Utils.showToast('Analytics data exported successfully!', 'success');
        
    } catch (error) {
        Utils.handleError(error, 'Failed to export analytics data');
    } finally {
        showLoading(false);
    }
}

// Make functions globally available
window.Analytics = {
    loadAnalyticsData,
    loadUserAnalytics,
    loadQuestAnalytics,
    loadEngagementAnalytics,
    loadPerformanceAnalytics,
    exportAnalyticsData
};

// Make individual functions globally available
window.loadAnalyticsData = loadAnalyticsData;
window.exportAnalyticsData = exportAnalyticsData;