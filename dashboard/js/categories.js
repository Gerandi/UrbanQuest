// Categories Management

// Load categories data for the main view
async function loadCategoriesData() {
    try {
        Utils.showElementLoading('categoriesList');
        
        const { data: categories, error } = await supabaseClient
            .from('quest_categories')
            .select(`
                *,
                quests(id, title, is_active)
            `)
            .order('name');
            
        if (error) throw error;
        
        const categoriesList = document.getElementById('categoriesList');
        if (!categoriesList) return;
        
        if (categories && categories.length > 0) {
            categoriesList.innerHTML = categories.map(category => createCategoryCard(category)).join('');
        } else {
            categoriesList.innerHTML = UIComponents.createEmptyState(
                'No Categories Found',
                'Create categories to organize your quests by theme or type.',
                'Add Category',
                'showCategoryModal()',
                'fas fa-tags'
            );
        }
        
    } catch (error) {
        Utils.handleError(error, 'Failed to load categories');
        const categoriesList = document.getElementById('categoriesList');
        if (categoriesList) {
            categoriesList.innerHTML = `
                <div class="text-center py-8">
                    <i class="fas fa-exclamation-triangle text-red-500 text-3xl mb-4"></i>
                    <p class="text-red-600">Failed to load categories</p>
                </div>
            `;
        }
    }
}

// Create a category card component
function createCategoryCard(category) {
    const quests = category.quests || [];
    const activeQuests = quests.filter(quest => quest.is_active).length;
    const totalQuests = quests.length;
    
    const statusBadge = category.is_active 
        ? UIComponents.createBadge('Active', 'green')
        : UIComponents.createBadge('Inactive', 'gray');
    
    // Get category color/icon
    const categoryColor = category.color || 'blue';
    const categoryIcon = category.icon || 'fas fa-tag';
    
    return `
        <div class="bg-white border border-gray-200 rounded-lg p-6 hover:shadow-md transition-shadow">
            <div class="flex justify-between items-start mb-4">
                <div class="flex-1">
                    <div class="flex items-center mb-2">
                        <div class="w-10 h-10 bg-${categoryColor}-100 rounded-lg flex items-center justify-center mr-3">
                            <i class="${categoryIcon} text-${categoryColor}-600"></i>
                        </div>
                        <div>
                            <h3 class="text-lg font-semibold text-gray-900">${category.name}</h3>
                            ${statusBadge}
                        </div>
                    </div>
                    
                    <p class="text-gray-600 mb-3">${Utils.truncateText(category.description, 120)}</p>
                    
                    <div class="flex items-center space-x-4 text-sm text-gray-500">
                        <span>
                            <i class="fas fa-map mr-1"></i>
                            ${totalQuests} quests (${activeQuests} active)
                        </span>
                        ${category.target_audience ? `
                            <span>
                                <i class="fas fa-users mr-1"></i>
                                ${category.target_audience}
                            </span>
                        ` : ''}
                        ${category.difficulty_level ? `
                            <span>
                                <i class="fas fa-signal mr-1"></i>
                                ${Utils.capitalizeFirst(category.difficulty_level)}
                            </span>
                        ` : ''}
                    </div>
                </div>
                
                <div class="flex space-x-2 ml-4">
                    <button onclick="editCategory('${category.id}')" 
                            class="bg-blue-500 hover:bg-blue-600 text-white text-sm font-semibold py-2 px-3 rounded transition duration-200">
                        <i class="fas fa-edit"></i>
                    </button>
                    <button onclick="deleteCategory('${category.id}')" 
                            class="bg-red-500 hover:bg-red-600 text-white text-sm font-semibold py-2 px-3 rounded transition duration-200">
                        <i class="fas fa-trash"></i>
                    </button>
                </div>
            </div>
            
            <div class="border-t border-gray-200 pt-4">
                <div class="flex justify-between items-center">
                    <div class="flex items-center space-x-3">
                        ${category.tags ? `
                            <div class="flex flex-wrap gap-1">
                                ${category.tags.split(',').slice(0, 3).map(tag => 
                                    `<span class="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-gray-100 text-gray-800">
                                        ${tag.trim()}
                                    </span>`
                                ).join('')}
                                ${category.tags.split(',').length > 3 ? 
                                    `<span class="text-xs text-gray-500">+${category.tags.split(',').length - 3}</span>` : ''
                                }
                            </div>
                        ` : ''}
                    </div>
                    
                    <div class="flex space-x-2">
                        <button onclick="viewCategoryQuests('${category.id}')" 
                                class="text-blue-600 hover:text-blue-800 text-sm font-medium">
                            <i class="fas fa-list mr-1"></i>View Quests
                        </button>
                    </div>
                </div>
            </div>
        </div>
    `;
}

// Show category modal for create/edit
function showCategoryModal(category = null) {
    const isEdit = !!category;
    const title = isEdit ? 'Edit Category' : 'Add New Category';
    
    const colorOptions = [
        { value: 'blue', label: 'Blue' },
        { value: 'green', label: 'Green' },
        { value: 'purple', label: 'Purple' },
        { value: 'red', label: 'Red' },
        { value: 'yellow', label: 'Yellow' },
        { value: 'indigo', label: 'Indigo' },
        { value: 'pink', label: 'Pink' },
        { value: 'gray', label: 'Gray' }
    ];
    
    const difficultyOptions = [
        { value: '', label: 'No specific difficulty' },
        { value: 'easy', label: 'Easy' },
        { value: 'medium', label: 'Medium' },
        { value: 'hard', label: 'Hard' },
        { value: 'expert', label: 'Expert' }
    ];
    
    const content = `
        <form id="categoryForm" class="space-y-4">
            ${UIComponents.createInput('name', 'Category Name', 'text', true, 'Enter category name', category?.name || '')}
            ${UIComponents.createTextarea('description', 'Description', true, 'Enter category description', category?.description || '', 3)}
            
            <div class="grid grid-cols-2 gap-4">
                ${UIComponents.createSelect('color', 'Color Theme', colorOptions, true, category?.color || 'blue')}
                ${UIComponents.createInput('icon', 'Icon Class', 'text', true, 'fas fa-tag', category?.icon || 'fas fa-tag')}
            </div>
            
            ${UIComponents.createSelect('difficultyLevel', 'Typical Difficulty', difficultyOptions, false, category?.difficulty_level || '')}
            ${UIComponents.createInput('targetAudience', 'Target Audience', 'text', false, 'Families, Tourists, etc.', category?.target_audience || '')}
            ${UIComponents.createInput('estimatedDuration', 'Estimated Duration Range (minutes)', 'text', false, '30-60', category?.estimated_duration_range || '')}
            ${UIComponents.createInput('tags', 'Tags (comma-separated)', 'text', false, 'historical, outdoor, family-friendly', category?.tags || '')}
            
            <div class="grid grid-cols-2 gap-4">
                ${UIComponents.createInput('sortOrder', 'Sort Order', 'number', false, '0', category?.sort_order || '0')}
                ${UIComponents.createCheckbox('isActive', 'Category is Active', category?.is_active !== false, '1')}
            </div>
            
            <div class="bg-gray-50 p-4 rounded-lg">
                <h4 class="font-semibold text-gray-700 mb-2">Preview</h4>
                <div id="categoryPreview" class="flex items-center">
                    <div class="w-8 h-8 bg-blue-100 rounded-lg flex items-center justify-center mr-3">
                        <i class="fas fa-tag text-blue-600"></i>
                    </div>
                    <span class="font-medium text-gray-900">Category Name</span>
                </div>
            </div>
            
            <div class="flex justify-end space-x-4 pt-4">
                <button type="button" onclick="ModalManager.close('categoryModal')" 
                        class="bg-gray-500 hover:bg-gray-600 text-white font-semibold py-2 px-4 rounded-lg">
                    Cancel
                </button>
                <button type="submit" 
                        class="bg-blue-600 hover:bg-blue-700 text-white font-semibold py-2 px-4 rounded-lg">
                    ${isEdit ? 'Update' : 'Create'} Category
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
    
    ModalManager.create('categoryModal', title, content, 'lg');
    ModalManager.show('categoryModal');

    // Set up form handler
    setupCategoryForm(category);
}

function setupCategoryForm(category = null) {
    const form = document.getElementById('categoryForm');
    const nameInput = document.getElementById('name');
    const colorSelect = document.getElementById('color');
    const iconInput = document.getElementById('icon');
    const preview = document.getElementById('categoryPreview');
    
    // Update preview function
    function updatePreview() {
        const name = nameInput.value || 'Category Name';
        const color = colorSelect.value || 'blue';
        const icon = iconInput.value || 'fas fa-tag';
        
        preview.innerHTML = `
            <div class="w-8 h-8 bg-${color}-100 rounded-lg flex items-center justify-center mr-3">
                <i class="${icon} text-${color}-600"></i>
            </div>
            <span class="font-medium text-gray-900">${name}</span>
        `;
    }
    
    // Add event listeners for live preview
    nameInput.addEventListener('input', updatePreview);
    colorSelect.addEventListener('change', updatePreview);
    iconInput.addEventListener('input', updatePreview);
    
    // Initialize preview
    updatePreview();
    
    form.addEventListener('submit', async function(e) {
        e.preventDefault();
        await handleCategorySubmit(category);
    });
}

async function handleCategorySubmit(existingCategory = null) {
    const form = document.getElementById('categoryForm');
    const formData = new FormData(form);
    
    try {
        showLoading(true);

        // Build category data
        const categoryData = {
            name: formData.get('name'),
            description: formData.get('description'),
            color: formData.get('color'),
            icon: formData.get('icon'),
            difficulty_level: formData.get('difficultyLevel') || null,
            target_audience: formData.get('targetAudience') || null,
            estimated_duration_range: formData.get('estimatedDuration') || null,
            tags: formData.get('tags') || null,
            sort_order: parseInt(formData.get('sortOrder')) || 0,
            is_active: formData.get('isActive') === '1'
        };

        // Save to database
        let result;
        if (existingCategory) {
            result = await supabaseClient
                .from('quest_categories')
                .update(categoryData)
                .eq('id', existingCategory.id);
        } else {
            result = await supabaseClient
                .from('quest_categories')
                .insert([categoryData]);
        }

        if (result.error) throw result.error;

        Utils.showToast(
            `Category ${existingCategory ? 'updated' : 'created'} successfully!`, 
            'success'
        );
        
        ModalManager.close('categoryModal');
        await loadCategoriesData();

    } catch (error) {
        Utils.handleError(error, 'Failed to save category');
    } finally {
        showLoading(false);
    }
}

// Edit category
async function editCategory(categoryId) {
    try {
        const { data: category, error } = await supabaseClient
            .from('quest_categories')
            .select('*')
            .eq('id', categoryId)
            .single();
            
        if (error) throw error;
        
        showCategoryModal(category);
        
    } catch (error) {
        Utils.handleError(error, 'Failed to load category for editing');
    }
}

// Delete category
async function deleteCategory(categoryId) {
    // First check if category has quests
    try {
        const { data: quests, error } = await supabaseClient
            .from('quests')
            .select('id, title')
            .eq('category_id', categoryId);
            
        if (error) throw error;
        
        if (quests && quests.length > 0) {
            const questTitles = quests.map(q => q.title).join(', ');
            Utils.showToast(
                `Cannot delete category: It has ${quests.length} quest(s): ${Utils.truncateText(questTitles, 100)}`,
                'warning'
            );
            return;
        }
        
    } catch (error) {
        Utils.handleError(error, 'Failed to check category dependencies');
        return;
    }
    
    if (!confirm('Are you sure you want to delete this category? This action cannot be undone.')) {
        return;
    }
    
    try {
        showLoading(true);
        
        const { error } = await supabaseClient
            .from('quest_categories')
            .delete()
            .eq('id', categoryId);
            
        if (error) throw error;
        
        Utils.showToast('Category deleted successfully!', 'success');
        await loadCategoriesData();
        
    } catch (error) {
        Utils.handleError(error, 'Failed to delete category');
    } finally {
        showLoading(false);
    }
}

// View category quests
async function viewCategoryQuests(categoryId) {
    try {
        const { data: categoryData, error: categoryError } = await supabaseClient
            .from('quest_categories')
            .select('name')
            .eq('id', categoryId)
            .single();
            
        if (categoryError) throw categoryError;
        
        const { data: quests, error } = await supabaseClient
            .from('quests')
            .select(`
                *,
                cities(name),
                quest_stops(id)
            `)
            .eq('category_id', categoryId)
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
                                                    <i class="fas fa-map-marker-alt mr-1"></i>
                                                    ${quest.cities?.name || 'No City'}
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
                        <p>No quests found for this category</p>
                        <button onclick="showQuestModal()" class="mt-2 text-blue-600 hover:text-blue-800">
                            Create the first quest
                        </button>
                    </div>
                `}
            </div>
        `;
        
        if (typeof ModalManager !== 'undefined' && ModalManager.create) {
            ModalManager.create('categoryQuestsModal', `Quests in ${categoryData.name}`, content, 'lg');
            ModalManager.show('categoryQuestsModal');
        } else {
            console.error('ModalManager not available for category quests modal');
            Utils.showToast('Error: Modal system not initialized', 'error');
        }
        
    } catch (error) {
        Utils.handleError(error, 'Failed to load category quests');
    }
}

// Bulk operations
async function reorderCategories(categoryOrders) {
    try {
        showLoading(true);
        
        for (const { id, sort_order } of categoryOrders) {
            await supabaseClient
                .from('quest_categories')
                .update({ sort_order })
                .eq('id', id);
        }
        
        Utils.showToast('Categories reordered successfully!', 'success');
        await loadCategoriesData();
        
    } catch (error) {
        Utils.handleError(error, 'Failed to reorder categories');
    } finally {
        showLoading(false);
    }
}

// Export categories
async function exportCategories() {
    try {
        const { data: categories, error } = await supabaseClient
            .from('quest_categories')
            .select(`
                *,
                quests(id, title)
            `)
            .order('sort_order');
            
        if (error) throw error;
        
        const exportData = {
            exported_at: new Date().toISOString(),
            categories: categories
        };
        
        const blob = new Blob([JSON.stringify(exportData, null, 2)], { type: 'application/json' });
        const url = URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = `quest_categories_${new Date().toISOString().split('T')[0]}.json`;
        document.body.appendChild(a);
        a.click();
        document.body.removeChild(a);
        URL.revokeObjectURL(url);
        
        Utils.showToast('Categories exported successfully!', 'success');
        
    } catch (error) {
        Utils.handleError(error, 'Failed to export categories');
    }
}

// Make functions globally available
window.Categories = {
    loadCategoriesData,
    createCategoryCard,
    showCategoryModal,
    editCategory,
    deleteCategory,
    viewCategoryQuests,
    reorderCategories,
    exportCategories
};

// Make individual functions globally available for onclick handlers
window.loadCategoriesData = loadCategoriesData;
window.showCategoryModal = showCategoryModal;
window.editCategory = editCategory;
window.deleteCategory = deleteCategory;
window.viewCategoryQuests = viewCategoryQuests;
window.exportCategories = exportCategories;