// Quest Stops Management

// Initialize map functionality
function initializeMap() {
    if (window.AppState.map) return; // Map already initialized
    
    // Initialize map centered on Tirana, Albania
    window.AppState.map = L.map('map').setView(CONFIG.DEFAULT_MAP_CENTER, CONFIG.DEFAULT_MAP_ZOOM);
    
    // Add OpenStreetMap tiles
    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
        attribution: '© <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
    }).addTo(window.AppState.map);
    
    // Initialize quest stops layer
    window.AppState.questStopsLayer = L.layerGroup().addTo(window.AppState.map);
    
    // Add click event listener
    window.AppState.map.on('click', function(e) {
        window.AppState.selectedLocation = {
            lat: e.latlng.lat,
            lng: e.latlng.lng
        };
        
        // Update location display
        const locationDisplay = document.getElementById('locationDisplay');
        if (locationDisplay) {
            locationDisplay.textContent = `${e.latlng.lat.toFixed(6)}, ${e.latlng.lng.toFixed(6)}`;
        }
        
        // Clear previous markers and reload existing stops
        window.AppState.questStopsLayer.clearLayers();
        loadExistingQuestStopsOnMap();
        
        // Add selected location marker (green)
        L.marker([e.latlng.lat, e.latlng.lng], {
            icon: L.icon({
                iconUrl: 'https://raw.githubusercontent.com/pointhi/leaflet-color-markers/master/img/marker-icon-2x-green.png',
                shadowUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/0.7.7/images/marker-shadow.png',
                iconSize: [25, 41],
                iconAnchor: [12, 41],
                popupAnchor: [1, -34],
                shadowSize: [41, 41]
            })
        }).addTo(window.AppState.questStopsLayer).bindPopup('📍 Selected location for new quest stop');
    });
}

// Load existing quest stops on map
async function loadExistingQuestStopsOnMap() {
    try {
        const { data: questStops, error } = await supabaseClient
            .from('quest_stops')
            .select(`
                *,
                quests(title, id)
            `);
            
        if (error) throw error;
        
        questStops?.forEach(stop => {
            const challengeConfig = CONFIG.CHALLENGE_TYPES[stop.challenge_type] || CONFIG.CHALLENGE_TYPES.text;
            
            // Create custom icon based on challenge type
            const iconHtml = `
                <div style="
                    background: white; 
                    border: 3px solid #${challengeConfig.color === 'blue' ? '3B82F6' : 
                                            challengeConfig.color === 'green' ? '10B981' :
                                            challengeConfig.color === 'purple' ? '8B5CF6' :
                                            challengeConfig.color === 'red' ? 'EF4444' :
                                            challengeConfig.color === 'indigo' ? '6366F1' :
                                            challengeConfig.color === 'pink' ? 'EC4899' :
                                            challengeConfig.color === 'orange' ? 'F59E0B' : '6B7280'}; 
                    border-radius: 50%; 
                    width: 24px; 
                    height: 24px; 
                    display: flex; 
                    align-items: center; 
                    justify-content: center;
                    font-size: 12px;
                    box-shadow: 0 2px 4px rgba(0,0,0,0.2);
                ">
                    <i class="${challengeConfig.icon}" style="color: #${challengeConfig.color === 'blue' ? '3B82F6' : 
                                                                   challengeConfig.color === 'green' ? '10B981' :
                                                                   challengeConfig.color === 'purple' ? '8B5CF6' :
                                                                   challengeConfig.color === 'red' ? 'EF4444' :
                                                                   challengeConfig.color === 'indigo' ? '6366F1' :
                                                                   challengeConfig.color === 'pink' ? 'EC4899' :
                                                                   challengeConfig.color === 'orange' ? 'F59E0B' : '6B7280'};"></i>
                </div>
            `;
            
            const customIcon = L.divIcon({
                html: iconHtml,
                className: 'custom-quest-stop-marker',
                iconSize: [24, 24],
                iconAnchor: [12, 12]
            });
            
            L.marker([stop.latitude, stop.longitude], { icon: customIcon })
                .addTo(window.AppState.questStopsLayer)
                .bindPopup(`
                    <div class="p-2">
                        <h4 class="font-semibold text-gray-900">${stop.title}</h4>
                        <p class="text-sm text-gray-600">Quest: ${stop.quests?.title || 'Unknown'}</p>
                        <div class="flex items-center mt-2 space-x-2">
                            <span class="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-${challengeConfig.color}-100 text-${challengeConfig.color}-800">
                                <i class="${challengeConfig.icon} mr-1"></i>
                                ${challengeConfig.name}
                            </span>
                            <span class="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-gray-100 text-gray-800">
                                ${stop.points} pts
                            </span>
                        </div>
                        <div class="mt-2 space-x-1">
                            <button onclick="editQuestStop('${stop.id}')" 
                                    class="text-xs bg-blue-500 hover:bg-blue-600 text-white px-2 py-1 rounded">
                                Edit
                            </button>
                            <button onclick="deleteQuestStop('${stop.id}')" 
                                    class="text-xs bg-red-500 hover:bg-red-600 text-white px-2 py-1 rounded">
                                Delete
                            </button>
                        </div>
                    </div>
                `);
        });
    } catch (error) {
        console.error('Error loading quest stops on map:', error);
    }
}

// Load quest stops data for the main view
async function loadQuestStopsData() {
    try {
        Utils.showElementLoading('questStopsList');
        
        // Initialize map if not already done
        setTimeout(() => {
            initializeMap();
            loadExistingQuestStopsOnMap();
        }, 100);
        
        // Load quest stops for the list
        const { data: questStops, error } = await supabaseClient
            .from('quest_stops')
            .select(`
                *,
                quests(title, id, city_id)
            `)
            .order('created_at', { ascending: false });
            
        if (error) throw error;
        
        const questStopsList = document.getElementById('questStopsList');
        if (!questStopsList) return;
        
        if (questStops && questStops.length > 0) {
            // Group quest stops by quest
            const groupedStops = Utils.groupBy(questStops, 'quest_id');
            
            questStopsList.innerHTML = Object.entries(groupedStops).map(([questId, stops]) => {
                const questTitle = stops[0]?.quests?.title || 'Unknown Quest';
                const sortedStops = Utils.sortBy(stops, 'order_index');
                
                return `
                    <div class="border border-gray-200 rounded-lg p-4 mb-4">
                        <h4 class="font-semibold text-gray-900 mb-3">
                            <i class="fas fa-map-signs mr-2 text-blue-600"></i>
                            ${questTitle}
                        </h4>
                        <div class="space-y-2">
                            ${sortedStops.map(stop => createQuestStopCard(stop)).join('')}
                        </div>
                    </div>
                `;
            }).join('');
        } else {
            questStopsList.innerHTML = UIComponents.createEmptyState(
                'No Quest Stops Found',
                'Start by creating your first quest stop. Click on the map to select a location.',
                'Add Quest Stop',
                'showQuestStopModal()',
                'fas fa-map-marker-alt'
            );
        }
        
    } catch (error) {
        Utils.handleError(error, 'Failed to load quest stops');
        const questStopsList = document.getElementById('questStopsList');
        if (questStopsList) {
            questStopsList.innerHTML = `
                <div class="text-center py-8">
                    <i class="fas fa-exclamation-triangle text-red-500 text-3xl mb-4"></i>
                    <p class="text-red-600">Failed to load quest stops</p>
                </div>
            `;
        }
    }
}

// Create a quest stop card component
function createQuestStopCard(stop) {
    const challengeConfig = CONFIG.CHALLENGE_TYPES[stop.challenge_type] || CONFIG.CHALLENGE_TYPES.text;
    
    return `
        <div class="bg-gray-50 border border-gray-200 rounded-lg p-3">
            <div class="flex justify-between items-start">
                <div class="flex-1">
                    <div class="flex items-center mb-2">
                        <span class="inline-flex items-center justify-center w-6 h-6 bg-blue-100 text-blue-800 text-xs font-bold rounded-full mr-2">
                            ${stop.order_index}
                        </span>
                        <h5 class="font-medium text-gray-900">${stop.title}</h5>
                    </div>
                    
                    ${stop.description ? `<p class="text-sm text-gray-600 mb-2">${Utils.truncateText(stop.description, 100)}</p>` : ''}
                    
                    <div class="flex items-center space-x-2">
                        <span class="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-${challengeConfig.color}-100 text-${challengeConfig.color}-800">
                            <i class="${challengeConfig.icon} mr-1"></i>
                            ${challengeConfig.name}
                        </span>
                        <span class="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-green-100 text-green-800">
                            ${stop.points} points
                        </span>
                        <span class="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-gray-100 text-gray-800">
                            <i class="fas fa-map-marker-alt mr-1"></i>
                            ${stop.radius}m radius
                        </span>
                    </div>
                    
                    ${stop.challenge_text ? `
                        <div class="mt-2 p-2 bg-white rounded border border-gray-200">
                            <p class="text-xs text-gray-700">
                                <strong>Challenge:</strong> ${Utils.truncateText(stop.challenge_text, 80)}
                            </p>
                        </div>
                    ` : ''}
                </div>
                
                <div class="flex space-x-1 ml-4">
                    <button onclick="editQuestStop('${stop.id}')" 
                            class="bg-blue-500 hover:bg-blue-600 text-white text-xs font-semibold py-1 px-2 rounded transition duration-200">
                        <i class="fas fa-edit"></i>
                    </button>
                    <button onclick="duplicateQuestStop('${stop.id}')" 
                            class="bg-green-500 hover:bg-green-600 text-white text-xs font-semibold py-1 px-2 rounded transition duration-200">
                        <i class="fas fa-copy"></i>
                    </button>
                    <button onclick="deleteQuestStop('${stop.id}')" 
                            class="bg-red-500 hover:bg-red-600 text-white text-xs font-semibold py-1 px-2 rounded transition duration-200">
                        <i class="fas fa-trash"></i>
                    </button>
                </div>
            </div>
        </div>
    `;
}

// Edit quest stop
async function editQuestStop(stopId) {
    try {
        const { data: questStop, error } = await supabaseClient
            .from('quest_stops')
            .select('*')
            .eq('id', stopId)
            .single();
            
        if (error) throw error;
        
        // Set the selected location for editing
        window.AppState.selectedLocation = {
            lat: questStop.latitude,
            lng: questStop.longitude
        };
        
        // Show the modal with existing data
        Modals.showQuestStopModal(questStop);
        
    } catch (error) {
        Utils.handleError(error, 'Failed to load quest stop for editing');
    }
}

// Duplicate quest stop
async function duplicateQuestStop(stopId) {
    try {
        const { data: questStop, error } = await supabaseClient
            .from('quest_stops')
            .select('*')
            .eq('id', stopId)
            .single();
            
        if (error) throw error;
        
        // Create a copy with modified title and incremented order
        const duplicatedStop = {
            ...questStop,
            id: undefined, // Remove ID so a new one is generated
            title: `${questStop.title} (Copy)`,
            order_index: questStop.order_index + 1,
            created_at: new Date().toISOString()
        };
        
        const { error: insertError } = await supabaseClient
            .from('quest_stops')
            .insert([duplicatedStop]);
            
        if (insertError) throw insertError;
        
        Utils.showToast('Quest stop duplicated successfully!', 'success');
        await loadQuestStopsData();
        
    } catch (error) {
        Utils.handleError(error, 'Failed to duplicate quest stop');
    }
}

// Delete quest stop
async function deleteQuestStop(stopId) {
    if (!confirm('Are you sure you want to delete this quest stop? This action cannot be undone.')) {
        return;
    }
    
    try {
        showLoading(true);
        
        const { error } = await supabaseClient
            .from('quest_stops')
            .delete()
            .eq('id', stopId);
            
        if (error) throw error;
        
        Utils.showToast('Quest stop deleted successfully!', 'success');
        await loadQuestStopsData();
        
    } catch (error) {
        Utils.handleError(error, 'Failed to delete quest stop');
    } finally {
        showLoading(false);
    }
}

// Bulk operations
async function bulkUpdateQuestStops(questId, updates) {
    try {
        showLoading(true);
        
        const { error } = await supabaseClient
            .from('quest_stops')
            .update(updates)
            .eq('quest_id', questId);
            
        if (error) throw error;
        
        Utils.showToast('Quest stops updated successfully!', 'success');
        await loadQuestStopsData();
        
    } catch (error) {
        Utils.handleError(error, 'Failed to update quest stops');
    } finally {
        showLoading(false);
    }
}

// Export quest stops to JSON
async function exportQuestStops(questId = null) {
    try {
        let query = supabaseClient
            .from('quest_stops')
            .select(`
                *,
                quests(title, id)
            `);
            
        if (questId) {
            query = query.eq('quest_id', questId);
        }
        
        const { data: questStops, error } = await query;
        if (error) throw error;
        
        const exportData = {
            exported_at: new Date().toISOString(),
            quest_stops: questStops
        };
        
        const blob = new Blob([JSON.stringify(exportData, null, 2)], { type: 'application/json' });
        const url = URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = `quest_stops_${questId || 'all'}_${new Date().toISOString().split('T')[0]}.json`;
        document.body.appendChild(a);
        a.click();
        document.body.removeChild(a);
        URL.revokeObjectURL(url);
        
        Utils.showToast('Quest stops exported successfully!', 'success');
        
    } catch (error) {
        Utils.handleError(error, 'Failed to export quest stops');
    }
}

// Validate quest stop order
async function validateQuestStopOrder(questId) {
    try {
        const { data: questStops, error } = await supabaseClient
            .from('quest_stops')
            .select('id, order_index')
            .eq('quest_id', questId)
            .order('order_index');
            
        if (error) throw error;
        
        const issues = [];
        
        // Check for gaps and duplicates
        for (let i = 0; i < questStops.length; i++) {
            const currentOrder = questStops[i].order_index;
            const expectedOrder = i + 1;
            
            if (currentOrder !== expectedOrder) {
                issues.push(`Stop at position ${i + 1} has order ${currentOrder}, expected ${expectedOrder}`);
            }
        }
        
        return { valid: issues.length === 0, issues };
        
    } catch (error) {
        console.error('Error validating quest stop order:', error);
        return { valid: false, issues: ['Failed to validate order'] };
    }
}

// Auto-fix quest stop order
async function fixQuestStopOrder(questId) {
    try {
        showLoading(true);
        
        const { data: questStops, error } = await supabaseClient
            .from('quest_stops')
            .select('id, order_index')
            .eq('quest_id', questId)
            .order('order_index');
            
        if (error) throw error;
        
        const updates = questStops.map((stop, index) => ({
            id: stop.id,
            order_index: index + 1
        }));
        
        for (const update of updates) {
            await supabaseClient
                .from('quest_stops')
                .update({ order_index: update.order_index })
                .eq('id', update.id);
        }
        
        Utils.showToast('Quest stop order fixed successfully!', 'success');
        await loadQuestStopsData();
        
    } catch (error) {
        Utils.handleError(error, 'Failed to fix quest stop order');
    } finally {
        showLoading(false);
    }
}

// Make functions globally available
window.QuestStops = {
    initializeMap,
    loadExistingQuestStopsOnMap,
    loadQuestStopsData,
    createQuestStopCard,
    editQuestStop,
    duplicateQuestStop,
    deleteQuestStop,
    bulkUpdateQuestStops,
    exportQuestStops,
    validateQuestStopOrder,
    fixQuestStopOrder
};

// Make individual functions globally available for onclick handlers
window.editQuestStop = editQuestStop;
window.duplicateQuestStop = duplicateQuestStop;
window.deleteQuestStop = deleteQuestStop;
window.showQuestStopModal = Modals.showQuestStopModal;