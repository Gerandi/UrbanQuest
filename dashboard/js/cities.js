// Cities Management Module
const CityManager = {
    currentCities: [],
    
    async init() {
        await this.loadCities();
        this.setupEventListeners();
    },

    setupEventListeners() {
        // Any additional event listeners can be added here
    },

    async loadCities() {
        try {
            const { data: cities, error } = await supabase
                .from('cities')
                .select('*')
                .order('name');

            if (error) throw error;

            this.currentCities = cities || [];
            this.displayCities();
        } catch (error) {
            console.error('Error loading cities:', error);
            Utils.showNotification('Error loading cities: ' + error.message, 'error');
        }
    },

    displayCities() {
        const citiesList = document.getElementById('citiesList');
        if (!citiesList) return;

        if (this.currentCities.length === 0) {
            citiesList.innerHTML = '<div class="text-center py-8 text-gray-500">No cities found</div>';
            return;
        }

        citiesList.innerHTML = this.currentCities.map(city => this.createCityCard(city)).join('');
    },

    createCityCard(city) {
        return `
            <div class="bg-white rounded-lg shadow-md p-6 city-card" data-city-id="${city.id}">
                <div class="flex justify-between items-start mb-4">
                    <div class="flex-1">
                        <h3 class="text-lg font-semibold text-gray-900 mb-2">${Utils.escapeHtml(city.name || 'Untitled City')}</h3>
                        <p class="text-gray-600 text-sm mb-3">${Utils.escapeHtml(city.description || 'No description')}</p>
                        <div class="flex gap-4 text-sm text-gray-500">
                            <span>🆔 ${city.id}</span>
                            <span>📅 ${city.created_at ? new Date(city.created_at).toLocaleDateString() : 'Unknown'}</span>
                        </div>
                    </div>
                    <div class="flex gap-2 ml-4">
                        <button onclick="CityManager.editCity('${city.id}')" 
                                class="text-blue-600 hover:text-blue-800 p-2" title="Edit City">
                            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"></path>
                            </svg>
                        </button>
                        <button onclick="CityManager.deleteCity('${city.id}')" 
                                class="text-red-600 hover:text-red-800 p-2" title="Delete City">
                            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"></path>
                            </svg>
                        </button>
                    </div>
                </div>
            </div>
        `;
    },

    createCity() {
        console.log('Creating new city');
        showModal('city');
    },

    editCity(cityId) {
        console.log('Editing city:', cityId);
        const city = this.currentCities.find(c => c.id === cityId);
        if (!city) {
            Utils.showNotification('City not found', 'error');
            return;
        }

        showModal('city', city);
    },

    async deleteCity(cityId) {
        if (!confirm('Are you sure you want to delete this city? This action cannot be undone.')) {
            return;
        }

        try {
            const { error } = await supabase
                .from('cities')
                .delete()
                .eq('id', cityId);

            if (error) throw error;

            Utils.showNotification('City deleted successfully!', 'success');
            await this.loadCities();
        } catch (error) {
            console.error('Error deleting city:', error);
            Utils.showNotification('Error deleting city: ' + error.message, 'error');
        }
    },

    async saveCity(cityData) {
        try {
            console.log('Saving city data:', cityData);

            // Clean up data
            const cleanData = { ...cityData };

            // Remove empty strings
            Object.keys(cleanData).forEach(key => {
                if (cleanData[key] === '') {
                    delete cleanData[key];
                }
            });

            let result;
            if (cleanData.id) {
                // Update existing city
                const updateData = { ...cleanData };
                delete updateData.id; // Don't include ID in update
                
                const { data, error } = await supabase
                    .from('cities')
                    .update(updateData)
                    .eq('id', cleanData.id)
                    .select()
                    .single();

                if (error) throw error;
                result = data;
                Utils.showNotification('City updated successfully!', 'success');
            } else {
                // Create new city with generated ID
                cleanData.id = Utils.generateId();
                
                const { data, error } = await supabase
                    .from('cities')
                    .insert([cleanData])
                    .select()
                    .single();

                if (error) throw error;
                result = data;
                Utils.showNotification('City created successfully!', 'success');
            }

            await this.loadCities();
        } catch (error) {
            console.error('Error saving city:', error);
            Utils.showNotification('Error saving city: ' + error.message, 'error');
        }
    }
};

// Make saveCity globally available for the modal system
window.saveCity = (data) => CityManager.saveCity(data);

// Initialize when DOM is ready
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', () => CityManager.init());
} else {
    CityManager.init();
}

// Export for use in other modules
window.CityManager = CityManager;