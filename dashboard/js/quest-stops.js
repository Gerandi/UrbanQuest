// Quest Stops Management Module
const QuestStopManager = {
    currentQuestStops: [],
    currentQuests: [],
    selectedQuestId: null,
    
    async init() {
        // Wait for Supabase to be available
        await this.waitForSupabase();
        await this.loadQuests();
        await this.loadQuestStops();
        this.setupEventListeners();
    },

    async waitForSupabase() {
        return new Promise((resolve) => {
            if (window.supabase) {
                resolve();
                return;
            }
            
            const checkInterval = setInterval(() => {
                if (window.supabase) {
                    clearInterval(checkInterval);
                    resolve();
                }
            }, 100);
            
            // Timeout after 10 seconds
            setTimeout(() => {
                clearInterval(checkInterval);
                console.error('❌ Supabase not available after 10 seconds in quest-stops.js');
                resolve();
            }, 10000);
        });
    },

    setupEventListeners() {
        // Quest filter handler
        const questFilter = document.getElementById('questStopQuestFilter');
        if (questFilter) {
            questFilter.addEventListener('change', (e) => {
                this.selectedQuestId = e.target.value || null;
                this.displayQuestStops();
            });
        }
    },

    async loadQuests() {
        try {
            const { data: quests, error } = await supabase
                .from('quests')
                .select('id, title')
                .order('title');

            if (error) throw error;
            
            this.currentQuests = quests || [];
            this.updateQuestFilter();
        } catch (error) {
            console.error('Error loading quests:', error);
        }
    },

    async loadQuestStops() {
        try {
            const { data: questStops, error } = await supabase
                .from('quest_stops')
                .select(`
                    *,
                    quests(title)
                `)
                .order('quest_id, order_index');

            if (error) throw error;

            this.currentQuestStops = questStops || [];
            this.displayQuestStops();
        } catch (error) {
            console.error('Error loading quest stops:', error);
            Utils.showNotification('Error loading quest stops: ' + error.message, 'error');
        }
    },

    updateQuestFilter() {
        const questFilter = document.getElementById('questStopQuestFilter');
        if (!questFilter) return;

        const currentValue = questFilter.value;
        questFilter.innerHTML = '<option value="">All Quests</option>' +
            this.currentQuests.map(quest => 
                `<option value="${quest.id}" ${currentValue === quest.id ? 'selected' : ''}>${Utils.escapeHtml(quest.title)}</option>`
            ).join('');
    },

    displayQuestStops() {
        const questStopsList = document.getElementById('questStopsList');
        if (!questStopsList) return;

        let filteredStops = this.currentQuestStops;
        if (this.selectedQuestId) {
            filteredStops = this.currentQuestStops.filter(stop => stop.quest_id === this.selectedQuestId);
        }

        if (filteredStops.length === 0) {
            questStopsList.innerHTML = '<div class="text-center py-8 text-gray-500">No quest stops found</div>';
            return;
        }

        questStopsList.innerHTML = filteredStops.map(stop => this.createQuestStopCard(stop)).join('');
    },

    createQuestStopCard(stop) {
        const questTitle = stop.quests?.title || 'Unknown Quest';

        return `
            <div class="bg-white rounded-lg shadow-md p-6 quest-stop-card" data-stop-id="${stop.id}">
                <div class="flex justify-between items-start mb-4">
                    <div class="flex-1">
                        <h3 class="text-lg font-semibold text-gray-900 mb-2">${Utils.escapeHtml(stop.name || 'Untitled Stop')}</h3>
                        <div class="flex flex-wrap gap-2 mb-2">
                            <span class="px-2 py-1 bg-blue-100 text-blue-800 text-xs rounded-full">${questTitle}</span>
                            <span class="px-2 py-1 bg-green-100 text-green-800 text-xs rounded-full">Order: ${stop.order_index || 0}</span>
                        </div>
                        <p class="text-gray-600 text-sm mb-3">${Utils.escapeHtml(stop.clue || 'No clue provided')}</p>
                        <div class="flex gap-4 text-sm text-gray-500">
                            <span>📍 ${stop.latitude || 'N/A'}, ${stop.longitude || 'N/A'}</span>
                        </div>
                    </div>
                    <div class="flex gap-2 ml-4">
                        <button onclick="QuestStopManager.editQuestStop('${stop.id}')" 
                                class="text-blue-600 hover:text-blue-800 p-2" title="Edit Quest Stop">
                            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"></path>
                            </svg>
                        </button>
                        <button onclick="QuestStopManager.duplicateQuestStop('${stop.id}')" 
                                class="text-green-600 hover:text-green-800 p-2" title="Duplicate Quest Stop">
                            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 16H6a2 2 0 01-2-2V6a2 2 0 012-2h8a2 2 0 012 2v2m-6 12h8a2 2 0 002-2v-8a2 2 0 00-2-2h-8a2 2 0 00-2 2v8a2 2 0 002 2z"></path>
                            </svg>
                        </button>
                        <button onclick="QuestStopManager.deleteQuestStop('${stop.id}')" 
                                class="text-red-600 hover:text-red-800 p-2" title="Delete Quest Stop">
                            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"></path>
                            </svg>
                        </button>
                    </div>
                </div>
            </div>
        `;
    },

    createQuestStop(questId = null) {
        console.log('Creating new quest stop for quest:', questId);
        
        const data = {};
        if (questId) {
            data.quest_id = questId;
        } else if (this.selectedQuestId) {
            data.quest_id = this.selectedQuestId;
        }
        
        // Get next order index
        const questStops = this.currentQuestStops.filter(stop => 
            stop.quest_id === (questId || this.selectedQuestId || '')
        );
        const nextOrder = Math.max(0, ...questStops.map(stop => stop.order_index || 0)) + 1;
        data.order_index = nextOrder;

        showModal('questStop', data);
    },

    editQuestStop(stopId) {
        console.log('Editing quest stop:', stopId);
        const stop = this.currentQuestStops.find(s => s.id === stopId);
        if (!stop) {
            Utils.showNotification('Quest stop not found', 'error');
            return;
        }

        showModal('questStop', stop);
    },

    async duplicateQuestStop(stopId) {
        try {
            const stop = this.currentQuestStops.find(s => s.id === stopId);
            if (!stop) {
                Utils.showNotification('Quest stop not found', 'error');
                return;
            }

            // Create stop copy with new ID
            const stopCopy = { ...stop };
            delete stopCopy.id;
            stopCopy.id = Utils.generateId();
            stopCopy.name = stopCopy.name + ' (Copy)';
            
            // Get next order index for the quest
            const questStops = this.currentQuestStops.filter(s => s.quest_id === stop.quest_id);
            const nextOrder = Math.max(0, ...questStops.map(s => s.order_index || 0)) + 1;
            stopCopy.order_index = nextOrder;

            const { data: newStop, error } = await supabase
                .from('quest_stops')
                .insert([stopCopy])
                .select()
                .single();

            if (error) throw error;

            Utils.showNotification('Quest stop duplicated successfully!', 'success');
            await this.loadQuestStops();
        } catch (error) {
            console.error('Error duplicating quest stop:', error);
            Utils.showNotification('Error duplicating quest stop: ' + error.message, 'error');
        }
    },

    async deleteQuestStop(stopId) {
        if (!confirm('Are you sure you want to delete this quest stop? This action cannot be undone.')) {
            return;
        }

        try {
            const { error } = await supabase
                .from('quest_stops')
                .delete()
                .eq('id', stopId);

            if (error) throw error;

            Utils.showNotification('Quest stop deleted successfully!', 'success');
            await this.loadQuestStops();
        } catch (error) {
            console.error('Error deleting quest stop:', error);
            Utils.showNotification('Error deleting quest stop: ' + error.message, 'error');
        }
    },

    async saveQuestStop(stopData) {
        try {
            console.log('Saving quest stop data:', stopData);

            // Clean up data
            const cleanData = { ...stopData };
            
            // Convert numeric fields
            if (cleanData.order_index) {
                cleanData.order_index = parseInt(cleanData.order_index);
            }
            if (cleanData.latitude) {
                cleanData.latitude = parseFloat(cleanData.latitude);
            }
            if (cleanData.longitude) {
                cleanData.longitude = parseFloat(cleanData.longitude);
            }

            // Remove empty strings
            Object.keys(cleanData).forEach(key => {
                if (cleanData[key] === '') {
                    delete cleanData[key];
                }
            });

            let result;
            if (cleanData.id) {
                // Update existing quest stop
                const updateData = { ...cleanData };
                delete updateData.id; // Don't include ID in update
                
                const { data, error } = await supabase
                    .from('quest_stops')
                    .update(updateData)
                    .eq('id', cleanData.id)
                    .select()
                    .single();

                if (error) throw error;
                result = data;
                Utils.showNotification('Quest stop updated successfully!', 'success');
            } else {
                // Create new quest stop with generated ID
                cleanData.id = Utils.generateId();
                
                const { data, error } = await supabase
                    .from('quest_stops')
                    .insert([cleanData])
                    .select()
                    .single();

                if (error) throw error;
                result = data;
                Utils.showNotification('Quest stop created successfully!', 'success');
            }

            await this.loadQuestStops();
        } catch (error) {
            console.error('Error saving quest stop:', error);
            Utils.showNotification('Error saving quest stop: ' + error.message, 'error');
        }
    },

    filterByQuest(questId) {
        console.log('Filtering quest stops by quest:', questId);
        this.selectedQuestId = questId;
        
        // Update the filter dropdown
        const questFilter = document.getElementById('questStopQuestFilter');
        if (questFilter) {
            questFilter.value = questId;
        }
        
        this.displayQuestStops();
    }
};

// Make saveQuestStop globally available for the modal system
window.saveQuestStop = (data) => QuestStopManager.saveQuestStop(data);

// Initialize when DOM is ready
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', () => QuestStopManager.init());
} else {
    QuestStopManager.init();
}

// Export for use in other modules
window.QuestStopManager = QuestStopManager;