// Categories Management Module
const CategoryManager = {
    currentCategories: [],
    
    async init() {
        await this.loadCategories();
        this.setupEventListeners();
    },

    setupEventListeners() {
        // Any additional event listeners can be added here
    },

    async loadCategories() {
        try {
            const { data: categories, error } = await supabase
                .from('quest_categories')
                .select('*')
                .order('name');

            if (error) throw error;

            this.currentCategories = categories || [];
            this.displayCategories();
        } catch (error) {
            console.error('Error loading categories:', error);
            Utils.showNotification('Error loading categories: ' + error.message, 'error');
        }
    },

    displayCategories() {
        const categoriesList = document.getElementById('categoriesList');
        if (!categoriesList) return;

        if (this.currentCategories.length === 0) {
            categoriesList.innerHTML = '<div class="text-center py-8 text-gray-500">No categories found</div>';
            return;
        }

        categoriesList.innerHTML = this.currentCategories.map(category => this.createCategoryCard(category)).join('');
    },

    createCategoryCard(category) {
        return `
            <div class="bg-white rounded-lg shadow-md p-6 category-card" data-category-id="${category.id}">
                <div class="flex justify-between items-start mb-4">
                    <div class="flex-1">
                        <h3 class="text-lg font-semibold text-gray-900 mb-2">${Utils.escapeHtml(category.name || 'Untitled Category')}</h3>
                        <p class="text-gray-600 text-sm mb-3">${Utils.escapeHtml(category.description || 'No description')}</p>
                        <div class="flex gap-4 text-sm text-gray-500">
                            <span>🆔 ${category.id}</span>
                            <span>📅 ${category.created_at ? new Date(category.created_at).toLocaleDateString() : 'Unknown'}</span>
                        </div>
                    </div>
                    <div class="flex gap-2 ml-4">
                        <button onclick="CategoryManager.editCategory('${category.id}')" 
                                class="text-blue-600 hover:text-blue-800 p-2" title="Edit Category">
                            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"></path>
                            </svg>
                        </button>
                        <button onclick="CategoryManager.deleteCategory('${category.id}')" 
                                class="text-red-600 hover:text-red-800 p-2" title="Delete Category">
                            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"></path>
                            </svg>
                        </button>
                    </div>
                </div>
            </div>
        `;
    },

    createCategory() {
        console.log('Creating new category');
        showModal('category');
    },

    editCategory(categoryId) {
        console.log('Editing category:', categoryId);
        const category = this.currentCategories.find(c => c.id === categoryId);
        if (!category) {
            Utils.showNotification('Category not found', 'error');
            return;
        }

        showModal('category', category);
    },

    async deleteCategory(categoryId) {
        if (!confirm('Are you sure you want to delete this category? This action cannot be undone.')) {
            return;
        }

        try {
            const { error } = await supabase
                .from('quest_categories')
                .delete()
                .eq('id', categoryId);

            if (error) throw error;

            Utils.showNotification('Category deleted successfully!', 'success');
            await this.loadCategories();
        } catch (error) {
            console.error('Error deleting category:', error);
            Utils.showNotification('Error deleting category: ' + error.message, 'error');
        }
    },

    async saveCategory(categoryData) {
        try {
            console.log('Saving category data:', categoryData);

            // Clean up data
            const cleanData = { ...categoryData };

            // Remove empty strings
            Object.keys(cleanData).forEach(key => {
                if (cleanData[key] === '') {
                    delete cleanData[key];
                }
            });

            let result;
            if (cleanData.id) {
                // Update existing category
                const updateData = { ...cleanData };
                delete updateData.id; // Don't include ID in update
                
                const { data, error } = await supabase
                    .from('quest_categories')
                    .update(updateData)
                    .eq('id', cleanData.id)
                    .select()
                    .single();

                if (error) throw error;
                result = data;
                Utils.showNotification('Category updated successfully!', 'success');
            } else {
                // Create new category with generated ID
                cleanData.id = Utils.generateId();
                
                const { data, error } = await supabase
                    .from('quest_categories')
                    .insert([cleanData])
                    .select()
                    .single();

                if (error) throw error;
                result = data;
                Utils.showNotification('Category created successfully!', 'success');
            }

            await this.loadCategories();
        } catch (error) {
            console.error('Error saving category:', error);
            Utils.showNotification('Error saving category: ' + error.message, 'error');
        }
    }
};

// Make saveCategory globally available for the modal system
window.saveCategory = (data) => CategoryManager.saveCategory(data);

// Initialize when DOM is ready
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', () => CategoryManager.init());
} else {
    CategoryManager.init();
}

// Export for use in other modules
window.CategoryManager = CategoryManager;