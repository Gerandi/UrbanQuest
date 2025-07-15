// Cities Management

// Load cities data for the main view
async function loadCitiesData() {
    try {
        Utils.showElementLoading('citiesList');
        
        const { data: cities, error } = await supabaseClient
            .from('cities')
            .select(`
                *,
                quests(id, title, is_active)
            `)
            .order('name');
            
        if (error) throw error;
        
        const citiesList = document.getElementById('citiesList');
        if (!citiesList) return;
        
        if (cities && cities.length > 0) {
            citiesList.innerHTML = cities.map(city => createCityCard(city)).join('');
        } else {
            citiesList.innerHTML = UIComponents.createEmptyState(
                'No Cities Found',
                'Start by adding cities where your quests will take place.',
                'Add City',
                'showCityModal()',
                'fas fa-city'
            );
        }
        
    } catch (error) {
        Utils.handleError(error, 'Failed to load cities');
        const citiesList = document.getElementById('citiesList');
        if (citiesList) {
            citiesList.innerHTML = `
                <div class="text-center py-8">
                    <i class="fas fa-exclamation-triangle text-red-500 text-3xl mb-4"></i>
                    <p class="text-red-600">Failed to load cities</p>
                </div>
            `;
        }
    }
}

// Create a city card component
function createCityCard(city) {
    const quests = city.quests || [];
    const activeQuests = quests.filter(quest => quest.is_active).length;
    const totalQuests = quests.length;
    
    const statusBadge = city.is_active 
        ? UIComponents.createBadge('Active', 'green')
        : UIComponents.createBadge('Inactive', 'gray');
    
    return `
        <div class="bg-white border border-gray-200 rounded-lg p-6 hover:shadow-md transition-shadow">
            <div class="flex justify-between items-start mb-4">
                <div class="flex-1">
                    <div class="flex items-center mb-2">
                        <h3 class="text-lg font-semibold text-gray-900 mr-3">${city.name}</h3>
                        ${statusBadge}
                    </div>
                    
                    <p class="text-gray-600 mb-3">${Utils.truncateText(city.description, 120)}</p>
                    
                    <div class="flex items-center space-x-4 text-sm text-gray-500">
                        <span>
                            <i class="fas fa-flag mr-1"></i>
                            ${city.country}
                        </span>
                        <span>
                            <i class="fas fa-map-marker-alt mr-1"></i>
                            ${city.latitude?.toFixed(4)}, ${city.longitude?.toFixed(4)}
                        </span>
                        <span>
                            <i class="fas fa-users mr-1"></i>
                            ${Utils.formatNumber(city.population)} people
                        </span>
                    </div>
                </div>
                
                <div class="flex space-x-2 ml-4">
                    <button onclick="editCity('${city.id}')" 
                            class="bg-blue-500 hover:bg-blue-600 text-white text-sm font-semibold py-2 px-3 rounded transition duration-200">
                        <i class="fas fa-edit"></i>
                    </button>
                    <button onclick="deleteCity('${city.id}')" 
                            class="bg-red-500 hover:bg-red-600 text-white text-sm font-semibold py-2 px-3 rounded transition duration-200">
                        <i class="fas fa-trash"></i>
                    </button>
                </div>
            </div>
            
            <div class="border-t border-gray-200 pt-4">
                <div class="flex justify-between items-center">
                    <div class="flex items-center space-x-3">
                        <span class="text-sm text-gray-600">
                            <i class="fas fa-map mr-1"></i>
                            ${totalQuests} quests (${activeQuests} active)
                        </span>
                        ${city.timezone ? `
                            <span class="text-sm text-gray-500">
                                <i class="fas fa-clock mr-1"></i>
                                ${city.timezone}
                            </span>
                        ` : ''}
                    </div>
                    
                    <div class="flex space-x-2">
                        <button onclick="viewCityQuests('${city.id}')" 
                                class="text-blue-600 hover:text-blue-800 text-sm font-medium">
                            <i class="fas fa-list mr-1"></i>View Quests
                        </button>
                        <button onclick="viewCityMap('${city.id}')" 
                                class="text-green-600 hover:text-green-800 text-sm font-medium">
                            <i class="fas fa-map mr-1"></i>View Map
                        </button>
                    </div>
                </div>
            </div>
        </div>
    `;
}

// Show city modal for create/edit
function showCityModal(city = null) {
    const isEdit = !!city;
    const title = isEdit ? 'Edit City' : 'Add New City';
    
    const content = `
        <form id="cityForm" class="space-y-4">
            ${UIComponents.createInput('name', 'City Name', 'text', true, 'Enter city name', city?.name || '')}
            ${UIComponents.createInput('country', 'Country', 'text', true, 'Enter country name', city?.country || '')}
            ${UIComponents.createTextarea('description', 'Description', true, 'Enter city description', city?.description || '', 4)}
            
            <div class="grid grid-cols-2 gap-4">
                ${UIComponents.createInput('latitude', 'Latitude', 'number', true, '41.3275', city?.latitude || '', 'step="any"')}
                ${UIComponents.createInput('longitude', 'Longitude', 'number', true, '19.8187', city?.longitude || '', 'step="any"')}
            </div>
            
            ${UIComponents.createInput('population', 'Population', 'number', false, '500000', city?.population || '')}
            ${UIComponents.createInput('timezone', 'Timezone', 'text', false, 'Europe/Tirane', city?.timezone || '')}
            ${UIComponents.createInput('languages', 'Languages (comma-separated)', 'text', false, 'Albanian, English', city?.languages || '')}
            ${UIComponents.createInput('currency', 'Currency', 'text', false, 'ALL', city?.currency || '')}
            ${UIComponents.createTextarea('touristInfo', 'Tourist Information', false, 'Key tourist attractions and information', city?.tourist_info || '')}
            ${UIComponents.createTextarea('safetyTips', 'Safety Tips', false, 'Important safety information for visitors', city?.safety_tips || '')}
            ${UIComponents.createCheckbox('isActive', 'City is Active', city?.is_active !== false, '1')}
            
            <div class="flex justify-end space-x-4 pt-4">
                <button type="button" onclick="ModalManager.close('cityModal')" 
                        class="bg-gray-500 hover:bg-gray-600 text-white font-semibold py-2 px-4 rounded-lg">
                    Cancel
                </button>
                <button type="submit" 
                        class="bg-blue-600 hover:bg-blue-700 text-white font-semibold py-2 px-4 rounded-lg">
                    ${isEdit ? 'Update' : 'Create'} City
                </button>
            </div>
        </form>
    `;

    // Ensure ModalManager is available
    if (typeof ModalManager === 'undefined' || !ModalManager.create) {
        console.error('ModalManager not available');
        Utils.showToast('Error: Modal system not initialized', 'error');
        return;
    }
    
    ModalManager.create('cityModal', title, content, 'lg');
    ModalManager.show('cityModal');

    // Set up form handler
    setupCityForm(city);
}

function setupCityForm(city = null) {
    const form = document.getElementById('cityForm');
    
    form.addEventListener('submit', async function(e) {
        e.preventDefault();
        await handleCitySubmit(city);
    });
}

async function handleCitySubmit(existingCity = null) {
    const form = document.getElementById('cityForm');
    const formData = new FormData(form);
    
    try {
        showLoading(true);

        // Validate coordinates
        const lat = parseFloat(formData.get('latitude'));
        const lng = parseFloat(formData.get('longitude'));
        
        if (!Utils.validateLatLng(lat, lng)) {
            throw new Error('Invalid latitude or longitude coordinates');
        }

        // Build city data
        const cityData = {
            name: formData.get('name'),
            country: formData.get('country'),
            description: formData.get('description'),
            latitude: lat,
            longitude: lng,
            population: parseInt(formData.get('population')) || null,
            timezone: formData.get('timezone') || null,
            languages: formData.get('languages') || null,
            currency: formData.get('currency') || null,
            tourist_info: formData.get('touristInfo') || null,
            safety_tips: formData.get('safetyTips') || null,
            is_active: formData.get('isActive') === '1'
        };

        // Save to database
        let result;
        if (existingCity) {
            result = await supabaseClient
                .from('cities')
                .update(cityData)
                .eq('id', existingCity.id);
        } else {
            result = await supabaseClient
                .from('cities')
                .insert([cityData]);
        }

        if (result.error) throw result.error;

        Utils.showToast(
            `City ${existingCity ? 'updated' : 'created'} successfully!`, 
            'success'
        );
        
        ModalManager.close('cityModal');
        await loadCitiesData();

    } catch (error) {
        Utils.handleError(error, 'Failed to save city');
    } finally {
        showLoading(false);
    }
}

// Edit city
async function editCity(cityId) {
    try {
        const { data: city, error } = await supabaseClient
            .from('cities')
            .select('*')
            .eq('id', cityId)
            .single();
            
        if (error) throw error;
        
        showCityModal(city);
        
    } catch (error) {
        Utils.handleError(error, 'Failed to load city for editing');
    }
}

// Delete city
async function deleteCity(cityId) {
    // First check if city has quests
    try {
        const { data: quests, error } = await supabaseClient
            .from('quests')
            .select('id, title')
            .eq('city_id', cityId);
            
        if (error) throw error;
        
        if (quests && quests.length > 0) {
            const questTitles = quests.map(q => q.title).join(', ');
            Utils.showToast(
                `Cannot delete city: It has ${quests.length} quest(s): ${Utils.truncateText(questTitles, 100)}`,
                'warning'
            );
            return;
        }
        
    } catch (error) {
        Utils.handleError(error, 'Failed to check city dependencies');
        return;
    }
    
    if (!confirm('Are you sure you want to delete this city? This action cannot be undone.')) {
        return;
    }
    
    try {
        showLoading(true);
        
        const { error } = await supabaseClient
            .from('cities')
            .delete()
            .eq('id', cityId);
            
        if (error) throw error;
        
        Utils.showToast('City deleted successfully!', 'success');
        await loadCitiesData();
        
    } catch (error) {
        Utils.handleError(error, 'Failed to delete city');
    } finally {
        showLoading(false);
    }
}

// View city quests
async function viewCityQuests(cityId) {
    try {
        const { data: cityData, error: cityError } = await supabaseClient
            .from('cities')
            .select('name')
            .eq('id', cityId)
            .single();
            
        if (cityError) throw cityError;
        
        const { data: quests, error } = await supabaseClient
            .from('quests')
            .select(`
                *,
                quest_categories(name),
                quest_stops(id)
            `)
            .eq('city_id', cityId)
            .order('title');
            
        if (error) throw error;
        
        const content = `
            <div class="space-y-4">
                ${quests && quests.length > 0 ? `
                    <div class="space-y-3">
                        ${quests.map(quest => {
                            const stopsCount = quest.quest_stops?.length || 0;
                            const statusBadge = quest.is_active 
                                ? UIComponents.createBadge('Active', 'green')
                                : UIComponents.createBadge('Inactive', 'gray');
                                
                            return `
                                <div class="border border-gray-200 rounded-lg p-4">
                                    <div class="flex justify-between items-start">
                                        <div class="flex-1">
                                            <div class="flex items-center mb-2">
                                                <h4 class="font-semibold text-gray-900 mr-2">${quest.title}</h4>
                                                ${statusBadge}
                                            </div>
                                            <p class="text-sm text-gray-600 mb-2">${Utils.truncateText(quest.description, 100)}</p>
                                            <div class="flex items-center space-x-4 text-xs text-gray-500">
                                                <span>
                                                    <i class="fas fa-tag mr-1"></i>
                                                    ${quest.quest_categories?.name || 'No Category'}
                                                </span>
                                                <span>
                                                    <i class="fas fa-map-signs mr-1"></i>
                                                    ${stopsCount} stops
                                                </span>
                                                <span>
                                                    <i class="fas fa-clock mr-1"></i>
                                                    ${quest.estimated_duration_minutes || 0} min
                                                </span>
                                                <span>
                                                    <i class="fas fa-signal mr-1"></i>
                                                    ${Utils.capitalizeFirst(quest.difficulty)}
                                                </span>
                                            </div>
                                        </div>
                                        <div class="flex space-x-2 ml-4">
                                            <button onclick="editQuest('${quest.id}')" 
                                                    class="text-blue-600 hover:text-blue-800 text-sm">
                                                <i class="fas fa-edit"></i>
                                            </button>
                                            <button onclick="previewQuest('${quest.id}')" 
                                                    class="text-green-600 hover:text-green-800 text-sm">
                                                <i class="fas fa-eye"></i>
                                            </button>
                                        </div>
                                    </div>
                                </div>
                            `;
                        }).join('')}
                    </div>
                ` : `
                    <div class="text-center py-8 text-gray-500">
                        <i class="fas fa-map text-3xl mb-2"></i>
                        <p>No quests found for this city</p>
                        <button onclick="showQuestModal()" class="mt-2 text-blue-600 hover:text-blue-800">
                            Create the first quest
                        </button>
                    </div>
                `}
            </div>
        `;
        
        if (typeof ModalManager !== 'undefined' && ModalManager.create) {
            ModalManager.create('cityQuestsModal', `Quests in ${cityData.name}`, content, 'lg');
            ModalManager.show('cityQuestsModal');
        } else {
            console.error('ModalManager not available for city quests modal');
            Utils.showToast('Error: Modal system not initialized', 'error');
        }
        
    } catch (error) {
        Utils.handleError(error, 'Failed to load city quests');
    }
}

// View city on map
async function viewCityMap(cityId) {
    try {
        const { data: city, error } = await supabaseClient
            .from('cities')
            .select('*')
            .eq('id', cityId)
            .single();
            
        if (error) throw error;
        
        const content = `
            <div class="space-y-4">
                <div class="bg-gray-50 p-4 rounded-lg">
                    <h4 class="font-semibold text-gray-900 mb-2">${city.name}, ${city.country}</h4>
                    <div class="grid grid-cols-2 gap-4 text-sm text-gray-600">
                        <div><strong>Coordinates:</strong> ${city.latitude?.toFixed(6)}, ${city.longitude?.toFixed(6)}</div>
                        <div><strong>Population:</strong> ${Utils.formatNumber(city.population)}</div>
                        <div><strong>Timezone:</strong> ${city.timezone || 'Unknown'}</div>
                        <div><strong>Currency:</strong> ${city.currency || 'Unknown'}</div>
                    </div>
                </div>
                <div id="cityMapContainer" style="height: 400px; width: 100%;" class="rounded-lg border border-gray-200"></div>
            </div>
        `;
        
        if (typeof ModalManager !== 'undefined' && ModalManager.create) {
            ModalManager.create('cityMapModal', `Map: ${city.name}`, content, 'xl');
            ModalManager.show('cityMapModal');
        } else {
            console.error('ModalManager not available for city map modal');
            Utils.showToast('Error: Modal system not initialized', 'error');
            return;
        }
        
        // Initialize map after modal is shown
        setTimeout(() => {
            const cityMap = L.map('cityMapContainer').setView([city.latitude, city.longitude], 13);
            
            L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
                attribution: '© <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
            }).addTo(cityMap);
            
            // Add city marker
            L.marker([city.latitude, city.longitude])
                .addTo(cityMap)
                .bindPopup(`<strong>${city.name}</strong><br>${city.country}`)
                .openPopup();
                
            // Load and display quest stops for this city
            loadCityQuestStops(cityMap, cityId);
        }, 300);
        
    } catch (error) {
        Utils.handleError(error, 'Failed to load city map');
    }
}

// Load quest stops for city map
async function loadCityQuestStops(map, cityId) {
    try {
        const { data: questStops, error } = await supabaseClient
            .from('quest_stops')
            .select(`
                *,
                quests!inner(city_id, title)
            `)
            .eq('quests.city_id', cityId);
            
        if (error) throw error;
        
        questStops?.forEach(stop => {
            const challengeConfig = CONFIG.CHALLENGE_TYPES[stop.challenge_type] || CONFIG.CHALLENGE_TYPES.text;
            
            // Create custom icon based on challenge type
            const iconHtml = `
                <div style="
                    background: white; 
                    border: 2px solid #${challengeConfig.color === 'blue' ? '3B82F6' : 
                                        challengeConfig.color === 'green' ? '10B981' :
                                        challengeConfig.color === 'purple' ? '8B5CF6' :
                                        challengeConfig.color === 'red' ? 'EF4444' :
                                        challengeConfig.color === 'indigo' ? '6366F1' :
                                        challengeConfig.color === 'pink' ? 'EC4899' :
                                        challengeConfig.color === 'orange' ? 'F59E0B' : '6B7280'}; 
                    border-radius: 50%; 
                    width: 20px; 
                    height: 20px; 
                    display: flex; 
                    align-items: center; 
                    justify-content: center;
                    font-size: 10px;
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
                iconSize: [20, 20],
                iconAnchor: [10, 10]
            });
            
            L.marker([stop.latitude, stop.longitude], { icon: customIcon })
                .addTo(map)
                .bindPopup(`
                    <div class="p-2">
                        <h5 class="font-semibold">${stop.title}</h5>
                        <p class="text-sm text-gray-600">Quest: ${stop.quests?.title}</p>
                        <p class="text-xs text-gray-500">${challengeConfig.name} • ${stop.points} points</p>
                    </div>
                `);
        });
    } catch (error) {
        console.error('Error loading city quest stops:', error);
    }
}

// Make functions globally available
window.Cities = {
    loadCitiesData,
    createCityCard,
    showCityModal,
    editCity,
    deleteCity,
    viewCityQuests,
    viewCityMap
};

// Make individual functions globally available for onclick handlers
window.loadCitiesData = loadCitiesData;
window.showCityModal = showCityModal;
window.editCity = editCity;
window.deleteCity = deleteCity;
window.viewCityQuests = viewCityQuests;
window.viewCityMap = viewCityMap;