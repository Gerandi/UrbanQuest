// Quests Management

// Load quests data for the main view
async function loadQuestsData() {
    try {
        Utils.showElementLoading('questsList');
        
        const { data: quests, error } = await supabaseClient
            .from('quests')
            .select(`
                *,
                cities(name, id),
                quest_categories(name, id),
                quest_stops(id, title, challenge_type, points)
            `)
            .order('created_at', { ascending: false });
            
        if (error) throw error;
        
        const questsList = document.getElementById('questsList');
        if (!questsList) return;
        
        if (quests && quests.length > 0) {
            questsList.innerHTML = quests.map(quest => createQuestCard(quest)).join('');
        } else {
            questsList.innerHTML = UIComponents.createEmptyState(
                'No Quests Found',
                'Start by creating your first quest to guide players through the city.',
                'Add Quest',
                'showQuestModal()',
                'fas fa-map'
            );
        }
        
    } catch (error) {
        Utils.handleError(error, 'Failed to load quests');
        const questsList = document.getElementById('questsList');
        if (questsList) {
            questsList.innerHTML = `
                <div class="text-center py-8">
                    <i class="fas fa-exclamation-triangle text-red-500 text-3xl mb-4"></i>
                    <p class="text-red-600">Failed to load quests</p>
                </div>
            `;
        }
    }
}

// Create a quest card component
function createQuestCard(quest) {
    const stops = quest.quest_stops || [];
    const totalPoints = stops.reduce((sum, stop) => sum + (stop.points || 0), 0);
    const challengeTypes = [...new Set(stops.map(stop => stop.challenge_type))];
    
    const statusBadge = quest.is_active 
        ? UIComponents.createBadge('Active', 'green')
        : UIComponents.createBadge('Inactive', 'gray');
    
    const difficultyBadge = UIComponents.createBadge(
        Utils.capitalizeFirst(quest.difficulty), 
        quest.difficulty === 'easy' ? 'green' : 
        quest.difficulty === 'medium' ? 'yellow' : 'red'
    );
    
    return `
        <div class="bg-white border border-gray-200 rounded-lg p-6 hover:shadow-md transition-shadow">
            <div class="flex justify-between items-start mb-4">
                <div class="flex-1">
                    <div class="flex items-center mb-2">
                        <h3 class="text-lg font-semibold text-gray-900 mr-3">${quest.title}</h3>
                        ${statusBadge}
                        ${difficultyBadge}
                    </div>
                    
                    <p class="text-gray-600 mb-3">${Utils.truncateText(quest.description, 120)}</p>
                    
                    <div class="flex items-center space-x-4 text-sm text-gray-500">
                        <span>
                            <i class="fas fa-map-marker-alt mr-1"></i>
                            ${quest.cities?.name || 'Unknown City'}
                        </span>
                        <span>
                            <i class="fas fa-tag mr-1"></i>
                            ${quest.quest_categories?.name || 'No Category'}
                        </span>
                        <span>
                            <i class="fas fa-clock mr-1"></i>
                            ${quest.estimated_duration_minutes || 0} min
                        </span>
                        <span>
                            <i class="fas fa-star mr-1"></i>
                            ${totalPoints} points
                        </span>
                    </div>
                </div>
                
                <div class="flex space-x-2 ml-4">
                    <button onclick="editQuest('${quest.id}')" 
                            class="bg-blue-500 hover:bg-blue-600 text-white text-sm font-semibold py-2 px-3 rounded transition duration-200">
                        <i class="fas fa-edit"></i>
                    </button>
                    <button onclick="duplicateQuest('${quest.id}')" 
                            class="bg-green-500 hover:bg-green-600 text-white text-sm font-semibold py-2 px-3 rounded transition duration-200">
                        <i class="fas fa-copy"></i>
                    </button>
                    <button onclick="deleteQuest('${quest.id}')" 
                            class="bg-red-500 hover:bg-red-600 text-white text-sm font-semibold py-2 px-3 rounded transition duration-200">
                        <i class="fas fa-trash"></i>
                    </button>
                </div>
            </div>
            
            <div class="border-t border-gray-200 pt-4">
                <div class="flex justify-between items-center">
                    <div class="flex items-center space-x-3">
                        <span class="text-sm text-gray-600">
                            <i class="fas fa-map-signs mr-1"></i>
                            ${stops.length} stops
                        </span>
                        ${challengeTypes.length > 0 ? `
                            <div class="flex space-x-1">
                                ${challengeTypes.slice(0, 3).map(type => {
                                    const config = CONFIG.CHALLENGE_TYPES[type] || CONFIG.CHALLENGE_TYPES.text;
                                    return `<i class="${config.icon} text-${config.color}-600" title="${config.name}"></i>`;
                                }).join('')}
                                ${challengeTypes.length > 3 ? `<span class="text-xs text-gray-500">+${challengeTypes.length - 3}</span>` : ''}
                            </div>
                        ` : ''}
                    </div>
                    
                    <div class="flex space-x-2">
                        <button onclick="previewQuest('${quest.id}')" 
                                class="text-blue-600 hover:text-blue-800 text-sm font-medium">
                            <i class="fas fa-eye mr-1"></i>Preview
                        </button>
                        <button onclick="exportQuest('${quest.id}')" 
                                class="text-green-600 hover:text-green-800 text-sm font-medium">
                            <i class="fas fa-download mr-1"></i>Export
                        </button>
                    </div>
                </div>
            </div>
        </div>
    `;
}

// Show quest modal for create/edit
function showQuestModal(quest = null) {
    const isEdit = !!quest;
    const title = isEdit ? 'Edit Quest' : 'Create New Quest';
    
    // Load cities and categories for dropdowns
    Promise.all([
        loadCitiesForDropdown(),
        loadCategoriesForDropdown()
    ]).then(([cities, categories]) => {
        const content = `
            <form id="questForm" class="space-y-4">
                ${UIComponents.createInput('title', 'Quest Title', 'text', true, 'Enter quest title', quest?.title || '')}
                ${UIComponents.createTextarea('description', 'Description', true, 'Enter quest description', quest?.description || '', 4)}
                ${UIComponents.createSelect('cityId', 'City', cities, true, quest?.city_id || '')}
                ${UIComponents.createSelect('categoryId', 'Category', categories, true, quest?.category_id || '')}
                ${UIComponents.createSelect('difficulty', 'Difficulty', [
                    { value: 'easy', label: 'Easy' },
                    { value: 'medium', label: 'Medium' },
                    { value: 'hard', label: 'Hard' },
                    { value: 'expert', label: 'Expert' }
                ], true, quest?.difficulty || '')}
                ${UIComponents.createInput('estimatedDuration', 'Estimated Duration (minutes)', 'number', true, '60', quest?.estimated_duration_minutes || '60')}
                ${UIComponents.createInput('maxPlayers', 'Max Players', 'number', false, '4', quest?.max_players || '4')}
                ${UIComponents.createInput('minAge', 'Minimum Age', 'number', false, '13', quest?.min_age || '13')}
                ${UIComponents.createTextarea('requirements', 'Requirements', false, 'Any special requirements or equipment needed', quest?.requirements || '')}
                ${UIComponents.createTextarea('rewards', 'Rewards Description', false, 'Describe what players earn upon completion', quest?.rewards || '')}
                ${UIComponents.createCheckbox('isActive', 'Quest is Active', quest?.is_active || false, '1')}
                ${UIComponents.createCheckbox('isPublic', 'Quest is Public', quest?.is_public !== false, '1')}
                
                <div class="flex justify-end space-x-4 pt-4">
                    <button type="button" onclick="ModalManager.close('questModal')" 
                            class="bg-gray-500 hover:bg-gray-600 text-white font-semibold py-2 px-4 rounded-lg">
                        Cancel
                    </button>
                    <button type="submit" 
                            class="bg-blue-600 hover:bg-blue-700 text-white font-semibold py-2 px-4 rounded-lg">
                        ${isEdit ? 'Update' : 'Create'} Quest
                    </button>
                </div>
            </form>
        `;

        ModalManager.create('questModal', title, content, 'lg');
        ModalManager.show('questModal');

        // Set up form handler
        setupQuestForm(quest);
    });
}

function setupQuestForm(quest = null) {
    const form = document.getElementById('questForm');
    
    form.addEventListener('submit', async function(e) {
        e.preventDefault();
        await handleQuestSubmit(quest);
    });
}

async function handleQuestSubmit(existingQuest = null) {
    const form = document.getElementById('questForm');
    const formData = new FormData(form);
    
    try {
        showLoading(true);

        // Build quest data
        const questData = {
            title: formData.get('title'),
            description: formData.get('description'),
            city_id: formData.get('cityId'),
            category_id: formData.get('categoryId'),
            difficulty: formData.get('difficulty'),
            estimated_duration_minutes: parseInt(formData.get('estimatedDuration')),
            max_players: parseInt(formData.get('maxPlayers')) || null,
            min_age: parseInt(formData.get('minAge')) || null,
            requirements: formData.get('requirements') || null,
            rewards: formData.get('rewards') || null,
            is_active: formData.get('isActive') === '1',
            is_public: formData.get('isPublic') === '1'
        };

        // Save to database
        let result;
        if (existingQuest) {
            result = await supabaseClient
                .from('quests')
                .update(questData)
                .eq('id', existingQuest.id);
        } else {
            result = await supabaseClient
                .from('quests')
                .insert([questData]);
        }

        if (result.error) throw result.error;

        Utils.showToast(
            `Quest ${existingQuest ? 'updated' : 'created'} successfully!`, 
            'success'
        );
        
        ModalManager.close('questModal');
        await loadQuestsData();

    } catch (error) {
        Utils.handleError(error, 'Failed to save quest');
    } finally {
        showLoading(false);
    }
}

// Edit quest
async function editQuest(questId) {
    try {
        const { data: quest, error } = await supabaseClient
            .from('quests')
            .select('*')
            .eq('id', questId)
            .single();
            
        if (error) throw error;
        
        showQuestModal(quest);
        
    } catch (error) {
        Utils.handleError(error, 'Failed to load quest for editing');
    }
}

// Duplicate quest
async function duplicateQuest(questId) {
    try {
        showLoading(true);
        
        const { data: quest, error } = await supabaseClient
            .from('quests')
            .select('*')
            .eq('id', questId)
            .single();
            
        if (error) throw error;
        
        // Create a copy with modified title
        const { id, created_at, updated_at, ...questDataWithoutId } = quest;
        const duplicatedQuest = {
            ...questDataWithoutId,
            title: `${quest.title} (Copy)`,
            is_active: false // Set as inactive by default
        };
        
        const { error: insertError } = await supabaseClient
            .from('quests')
            .insert([duplicatedQuest]);
            
        if (insertError) throw insertError;
        
        Utils.showToast('Quest duplicated successfully!', 'success');
        await loadQuestsData();
        
    } catch (error) {
        Utils.handleError(error, 'Failed to duplicate quest');
    } finally {
        showLoading(false);
    }
}

// Delete quest
async function deleteQuest(questId) {
    if (!confirm('Are you sure you want to delete this quest? This will also delete all associated quest stops. This action cannot be undone.')) {
        return;
    }
    
    try {
        showLoading(true);
        
        // First delete all quest stops
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
        
        Utils.showToast('Quest deleted successfully!', 'success');
        await loadQuestsData();
        
    } catch (error) {
        Utils.handleError(error, 'Failed to delete quest');
    } finally {
        showLoading(false);
    }
}

// Preview quest
async function previewQuest(questId) {
    try {
        const { data: quest, error } = await supabaseClient
            .from('quests')
            .select(`
                *,
                cities(name),
                quest_categories(name),
                quest_stops(*)
            `)
            .eq('id', questId)
            .single();
            
        if (error) throw error;
        
        const stops = quest.quest_stops || [];
        const totalPoints = stops.reduce((sum, stop) => sum + (stop.points || 0), 0);
        
        const content = `
            <div class="space-y-6">
                <div class="border-b border-gray-200 pb-4">
                    <h3 class="text-xl font-bold text-gray-900 mb-2">${quest.title}</h3>
                    <p class="text-gray-600 mb-4">${quest.description}</p>
                    
                    <div class="grid grid-cols-2 gap-4 text-sm">
                        <div><strong>City:</strong> ${quest.cities?.name || 'Unknown'}</div>
                        <div><strong>Category:</strong> ${quest.quest_categories?.name || 'None'}</div>
                        <div><strong>Difficulty:</strong> ${Utils.capitalizeFirst(quest.difficulty)}</div>
                        <div><strong>Duration:</strong> ${quest.estimated_duration_minutes} min</div>
                        <div><strong>Total Points:</strong> ${totalPoints}</div>
                        <div><strong>Stops:</strong> ${stops.length}</div>
                    </div>
                </div>
                
                ${stops.length > 0 ? `
                    <div>
                        <h4 class="font-semibold text-gray-900 mb-3">Quest Stops</h4>
                        <div class="space-y-2">
                            ${stops.sort((a, b) => a.order_index - b.order_index).map(stop => {
                                const config = CONFIG.CHALLENGE_TYPES[stop.challenge_type] || CONFIG.CHALLENGE_TYPES.text;
                                return `
                                    <div class="flex items-center p-3 bg-gray-50 rounded-lg">
                                        <span class="flex items-center justify-center w-8 h-8 bg-blue-100 text-blue-800 text-sm font-bold rounded-full mr-3">
                                            ${stop.order_index}
                                        </span>
                                        <div class="flex-1">
                                            <div class="font-medium">${stop.title}</div>
                                            <div class="text-sm text-gray-600">${Utils.truncateText(stop.description || stop.challenge_text, 80)}</div>
                                        </div>
                                        <div class="flex items-center space-x-2">
                                            <span class="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-${config.color}-100 text-${config.color}-800">
                                                <i class="${config.icon} mr-1"></i>
                                                ${config.name}
                                            </span>
                                            <span class="text-sm text-gray-500">${stop.points} pts</span>
                                        </div>
                                    </div>
                                `;
                            }).join('')}
                        </div>
                    </div>
                ` : `
                    <div class="text-center py-8 text-gray-500">
                        <i class="fas fa-map-marker-alt text-3xl mb-2"></i>
                        <p>No quest stops configured yet</p>
                    </div>
                `}
            </div>
        `;
        
        ModalManager.create('questPreviewModal', `Quest Preview: ${quest.title}`, content, 'xl');
        ModalManager.show('questPreviewModal');
        
    } catch (error) {
        Utils.handleError(error, 'Failed to load quest preview');
    }
}

// Export quest
async function exportQuest(questId) {
    try {
        const { data: quest, error } = await supabaseClient
            .from('quests')
            .select(`
                *,
                cities(name, id),
                quest_categories(name, id),
                quest_stops(*)
            `)
            .eq('id', questId)
            .single();
            
        if (error) throw error;
        
        const exportData = {
            exported_at: new Date().toISOString(),
            quest: quest
        };
        
        const blob = new Blob([JSON.stringify(exportData, null, 2)], { type: 'application/json' });
        const url = URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = `quest_${Utils.slugify(quest.title)}_${new Date().toISOString().split('T')[0]}.json`;
        document.body.appendChild(a);
        a.click();
        document.body.removeChild(a);
        URL.revokeObjectURL(url);
        
        Utils.showToast('Quest exported successfully!', 'success');
        
    } catch (error) {
        Utils.handleError(error, 'Failed to export quest');
    }
}

// Helper functions for loading dropdown data
async function loadCitiesForDropdown() {
    try {
        const { data: cities, error } = await supabaseClient
            .from('cities')
            .select('id, name')
            .eq('is_active', true)
            .order('name');
            
        if (error) throw error;
        
        return cities.map(city => ({
            value: city.id,
            label: city.name
        }));
    } catch (error) {
        console.error('Error loading cities:', error);
        return [];
    }
}

async function loadCategoriesForDropdown() {
    try {
        const { data: categories, error } = await supabaseClient
            .from('quest_categories')
            .select('id, name')
            .eq('is_active', true)
            .order('name');
            
        if (error) throw error;
        
        return categories.map(category => ({
            value: category.id,
            label: category.name
        }));
    } catch (error) {
        console.error('Error loading categories:', error);
        return [];
    }
}

// Make functions globally available
window.Quests = {
    loadQuestsData,
    createQuestCard,
    showQuestModal,
    editQuest,
    duplicateQuest,
    deleteQuest,
    previewQuest,
    exportQuest
};

// Make individual functions globally available for onclick handlers
window.loadQuestsData = loadQuestsData;
window.showQuestModal = showQuestModal;
window.editQuest = editQuest;
window.duplicateQuest = duplicateQuest;
window.deleteQuest = deleteQuest;
window.previewQuest = previewQuest;
window.exportQuest = exportQuest;