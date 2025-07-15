// Helper function for loading cities for dropdowns
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
        return [{ value: '', label: 'Error loading cities' }];
    }
}

// Make function globally available
window.loadCitiesForDropdown = loadCitiesForDropdown;