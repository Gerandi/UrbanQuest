// Quest Management Module
const QuestManager = {
    currentQuests: [],
    
    async init() {
        await this.loadQuests();
        await this.loadCategoriesForModal();
        await this.loadCitiesForModal();
        this.setupEventListeners();
    },

    setupEventListeners() {
        const questForm = document.getElementById('questForm');
        if (questForm) {
            questForm.addEventListener('submit', async (e) => {
                e.preventDefault();
                const formData = new FormData(questForm);
                const questData = Object.fromEntries(formData);
                await this.saveQuest(questData);
            });
        }
    },

    async loadQuests() {
        try {
            const { data: quests, error } = await supabase
                .from('quests')
                .select(`
                    *,
                    quest_categories(name),
                    cities(name),
                    quest_stops(count)
                `);

            if (error) throw error;

            this.currentQuests = quests || [];
            this.displayQuests();
        } catch (error) {
            console.error('Error loading quests:', error);
            Utils.showNotification('Error loading quests: ' + error.message, 'error');
        }
    },

    displayQuests() {
        const questsList = document.getElementById('questsList');
        if (!questsList) return;

        if (this.currentQuests.length === 0) {
            questsList.innerHTML = '<div class="text-center py-8 text-gray-500">No quests found</div>';
            return;
        }

        questsList.innerHTML = this.currentQuests.map(quest => this.createQuestCard(quest)).join('');
    },

    createQuestCard(quest) {
        const categoryName = quest.quest_categories?.name || 'Uncategorized';
        const cityName = quest.cities?.name || 'No City';
        const stopCount = quest.quest_stops?.length || 0;

        return `
            <div class="bg-white rounded-lg shadow-md p-6 quest-card" data-quest-id="${quest.id}">
                <div class="flex justify-between items-start mb-4">
                    <div class="flex-1">
                        <h3 class="text-lg font-semibold text-gray-900 mb-2">${Utils.escapeHtml(quest.title || 'Untitled Quest')}</h3>
                        <div class="flex flex-wrap gap-2 mb-2">
                            <span class="px-2 py-1 bg-blue-100 text-blue-800 text-xs rounded-full">${categoryName}</span>
                            <span class="px-2 py-1 bg-green-100 text-green-800 text-xs rounded-full">${cityName}</span>
                            <span class="px-2 py-1 bg-purple-100 text-purple-800 text-xs rounded-full">${quest.difficulty || 'Unknown'}</span>
                        </div>
                        <p class="text-gray-600 text-sm mb-3">${Utils.escapeHtml(quest.description || 'No description')}</p>
                        <div class="flex gap-4 text-sm text-gray-500">
                            <span>⏱️ ${quest.estimated_duration || 0} min</span>
                            <span>📍 ${quest.estimated_distance || 0} km</span>
                            <span>🏁 ${stopCount} stops</span>
                        </div>
                    </div>
                    <div class="flex gap-2 ml-4">
                        <button onclick="QuestManager.editQuest('${quest.id}')" 
                                class="text-blue-600 hover:text-blue-800 p-2" title="Edit Quest">
                            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"></path>
                            </svg>
                        </button>
                        <button onclick="QuestManager.duplicateQuest('${quest.id}')" 
                                class="text-green-600 hover:text-green-800 p-2" title="Duplicate Quest">
                            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 16H6a2 2 0 01-2-2V6a2 2 0 012-2h8a2 2 0 012 2v2m-6 12h8a2 2 0 002-2v-8a2 2 0 00-2-2h-8a2 2 0 00-2 2v8a2 2 0 002 2z"></path>
                            </svg>
                        </button>
                        <button onclick="QuestManager.deleteQuest('${quest.id}')" 
                                class="text-red-600 hover:text-red-800 p-2" title="Delete Quest">
                            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"></path>
                            </svg>
                        </button>
                        <button onclick="QuestManager.manageQuestStops('${quest.id}')" 
                                class="text-purple-600 hover:text-purple-800 p-2" title="Manage Quest Stops">
                            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z"></path>
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 11a3 3 0 11-6 0 3 3 0 016 0z"></path>
                            </svg>
                        </button>
                    </div>
                </div>
            </div>
        `;
    },

    async loadCategoriesForModal() {
        try {
            const { data: categories, error } = await supabase
                .from('quest_categories')
                .select('*')
                .order('name');

            if (error) throw error;

            // Update category dropdown whenever modal is shown
            document.addEventListener('DOMContentLoaded', () => {
                this.updateCategoryDropdown(categories);
            });
            
            // Store for later use
            this.categories = categories || [];
        } catch (error) {
            console.error('Error loading categories:', error);
        }
    },

    async loadCitiesForModal() {
        try {
            const { data: cities, error } = await supabase
                .from('cities')
                .select('*')
                .order('name');

            if (error) throw error;

            // Update city dropdown whenever modal is shown
            document.addEventListener('DOMContentLoaded', () => {
                this.updateCityDropdown(cities);
            });
            
            // Store for later use
            this.cities = cities || [];
        } catch (error) {
            console.error('Error loading cities:', error);
        }
    },

    updateCategoryDropdown(categories) {
        const categorySelect = document.getElementById('questCategory');
        if (categorySelect && categories) {
            const currentValue = categorySelect.value;
            categorySelect.innerHTML = '<option value="">Select Category</option>' +
                categories.map(cat => `<option value="${cat.id}" ${currentValue === cat.id ? 'selected' : ''}>${Utils.escapeHtml(cat.name)}</option>`).join('');
        }
    },

    updateCityDropdown(cities) {
        const citySelect = document.getElementById('questCity');
        if (citySelect && cities) {
            const currentValue = citySelect.value;
            citySelect.innerHTML = '<option value="">Select City</option>' +
                cities.map(city => `<option value="${city.id}" ${currentValue === city.id ? 'selected' : ''}>${Utils.escapeHtml(city.name)}</option>`).join('');
        }
    },

    createQuest() {
        console.log('Creating new quest');
        showModal('quest');
        
        // Update dropdowns with current data
        setTimeout(() => {
            this.updateCategoryDropdown(this.categories);
            this.updateCityDropdown(this.cities);
        }, 100);
    },

    editQuest(questId) {
        console.log('Editing quest:', questId);
        const quest = this.currentQuests.find(q => q.id === questId);
        if (!quest) {
            Utils.showNotification('Quest not found', 'error');
            return;
        }

        showModal('quest', quest);
        
        // Update dropdowns with current data
        setTimeout(() => {
            this.updateCategoryDropdown(this.categories);
            this.updateCityDropdown(this.cities);
        }, 100);
    },

    async duplicateQuest(questId) {
        try {
            const quest = this.currentQuests.find(q => q.id === questId);
            if (!quest) {
                Utils.showNotification('Quest not found', 'error');
                return;
            }

            // Create quest copy with new ID
            const questCopy = { ...quest };
            delete questCopy.id;
            questCopy.id = Utils.generateId();
            questCopy.title = questCopy.title + ' (Copy)';

            // Insert the duplicated quest
            const { data: newQuest, error: questError } = await supabase
                .from('quests')
                .insert([questCopy])
                .select()
                .single();

            if (questError) throw questError;

            // Load quest stops for duplication
            const { data: questStops, error: stopsError } = await supabase
                .from('quest_stops')
                .select('*')
                .eq('quest_id', questId);

            if (stopsError) throw stopsError;

            // Duplicate quest stops if any exist
            if (questStops && questStops.length > 0) {
                const stopsCopy = questStops.map(stop => {
                    const stopCopy = { ...stop };
                    delete stopCopy.id;
                    stopCopy.id = Utils.generateId();
                    stopCopy.quest_id = newQuest.id;
                    return stopCopy;
                });

                const { error: stopsInsertError } = await supabase
                    .from('quest_stops')
                    .insert(stopsCopy);

                if (stopsInsertError) throw stopsInsertError;
            }

            Utils.showNotification('Quest duplicated successfully!', 'success');
            await this.loadQuests();
        } catch (error) {
            console.error('Error duplicating quest:', error);
            Utils.showNotification('Error duplicating quest: ' + error.message, 'error');
        }
    },

    async deleteQuest(questId) {
        if (!confirm('Are you sure you want to delete this quest? This action cannot be undone.')) {
            return;
        }

        try {
            // Delete quest stops first (foreign key constraint)
            const { error: stopsError } = await supabase
                .from('quest_stops')
                .delete()
                .eq('quest_id', questId);

            if (stopsError) throw stopsError;

            // Delete the quest
            const { error: questError } = await supabase
                .from('quests')
                .delete()
                .eq('id', questId);

            if (questError) throw questError;

            Utils.showNotification('Quest deleted successfully!', 'success');
            await this.loadQuests();
        } catch (error) {
            console.error('Error deleting quest:', error);
            Utils.showNotification('Error deleting quest: ' + error.message, 'error');
        }
    },

    async saveQuest(questData) {
        try {
            console.log('Saving quest data:', questData);

            // Clean up data
            const cleanData = { ...questData };
            
            // Convert numeric fields
            if (cleanData.estimated_duration) {
                cleanData.estimated_duration = parseInt(cleanData.estimated_duration);
            }
            if (cleanData.estimated_distance) {
                cleanData.estimated_distance = parseFloat(cleanData.estimated_distance);
            }

            // Remove empty strings
            Object.keys(cleanData).forEach(key => {
                if (cleanData[key] === '') {
                    delete cleanData[key];
                }
            });

            let result;
            if (cleanData.id) {
                // Update existing quest
                const updateData = { ...cleanData };
                delete updateData.id; // Don't include ID in update
                
                const { data, error } = await supabase
                    .from('quests')
                    .update(updateData)
                    .eq('id', cleanData.id)
                    .select()
                    .single();

                if (error) throw error;
                result = data;
                Utils.showNotification('Quest updated successfully!', 'success');
            } else {
                // Create new quest with generated ID
                cleanData.id = Utils.generateId();
                
                const { data, error } = await supabase
                    .from('quests')
                    .insert([cleanData])
                    .select()
                    .single();

                if (error) throw error;
                result = data;
                Utils.showNotification('Quest created successfully!', 'success');
            }

            await this.loadQuests();
        } catch (error) {
            console.error('Error saving quest:', error);
            Utils.showNotification('Error saving quest: ' + error.message, 'error');
        }
    },

    manageQuestStops(questId) {
        console.log('Managing quest stops for quest:', questId);
        
        // Switch to quest stops view and set quest filter
        const questStopsTab = document.querySelector('[data-tab="quest-stops"]');
        if (questStopsTab) {
            questStopsTab.click();
            
            // Set quest filter after a brief delay to ensure the quest stops module is loaded
            setTimeout(() => {
                if (window.QuestStopManager && window.QuestStopManager.filterByQuest) {
                    window.QuestStopManager.filterByQuest(questId);
                }
            }, 100);
        }
    }
};

// Make saveQuest globally available for the modal system
window.saveQuest = (data) => QuestManager.saveQuest(data);

// Initialize when DOM is ready
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', () => QuestManager.init());
} else {
    QuestManager.init();
}

// Export for use in other modules
window.QuestManager = QuestManager;