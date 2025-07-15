// Simple Modal System - No classes, no complex initialization
// Just basic functions that work immediately

// Modal HTML templates
const MODAL_TEMPLATES = {
    quest: `
        <div id="questModal" class="fixed inset-0 bg-black bg-opacity-50 z-50 flex items-center justify-center">
            <div class="bg-white rounded-lg p-6 w-full max-w-2xl max-h-[90vh] overflow-y-auto">
                <div class="flex justify-between items-center mb-4">
                    <h2 id="questModalTitle" class="text-xl font-bold">Add New Quest</h2>
                    <button onclick="closeModal('questModal')" class="text-gray-500 hover:text-gray-700">
                        <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
                        </svg>
                    </button>
                </div>
                <form id="questForm">
                    <input type="hidden" id="questId" name="id">
                    <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                        <div>
                            <label class="block text-sm font-medium mb-2">Title *</label>
                            <input type="text" id="questTitle" name="title" required class="w-full p-2 border rounded-md">
                        </div>
                        <div>
                            <label class="block text-sm font-medium mb-2">Category *</label>
                            <select id="questCategory" name="category_id" required class="w-full p-2 border rounded-md">
                                <option value="">Select Category</option>
                            </select>
                        </div>
                        <div>
                            <label class="block text-sm font-medium mb-2">City *</label>
                            <select id="questCity" name="city_id" required class="w-full p-2 border rounded-md">
                                <option value="">Select City</option>
                            </select>
                        </div>
                        <div>
                            <label class="block text-sm font-medium mb-2">Difficulty</label>
                            <select id="questDifficulty" name="difficulty" class="w-full p-2 border rounded-md">
                                <option value="beginner">Beginner</option>
                                <option value="intermediate">Intermediate</option>
                                <option value="advanced">Advanced</option>
                            </select>
                        </div>
                        <div>
                            <label class="block text-sm font-medium mb-2">Duration (minutes)</label>
                            <input type="number" id="questDuration" name="estimated_duration" class="w-full p-2 border rounded-md">
                        </div>
                        <div>
                            <label class="block text-sm font-medium mb-2">Distance (km)</label>
                            <input type="number" step="0.1" id="questDistance" name="estimated_distance" class="w-full p-2 border rounded-md">
                        </div>
                    </div>
                    <div class="mt-4">
                        <label class="block text-sm font-medium mb-2">Description</label>
                        <textarea id="questDescription" name="description" rows="3" class="w-full p-2 border rounded-md"></textarea>
                    </div>
                    <div class="mt-4">
                        <label class="block text-sm font-medium mb-2">Start Instructions</label>
                        <textarea id="questStartInstructions" name="start_instructions" rows="3" class="w-full p-2 border rounded-md"></textarea>
                    </div>
                    <div class="flex justify-end gap-2 mt-6">
                        <button type="button" onclick="closeModal('questModal')" class="px-4 py-2 text-gray-600 bg-gray-100 rounded-md hover:bg-gray-200">Cancel</button>
                        <button type="submit" class="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700">Save Quest</button>
                    </div>
                </form>
            </div>
        </div>
    `,

    questStop: `
        <div id="questStopModal" class="fixed inset-0 bg-black bg-opacity-50 z-50 flex items-center justify-center">
            <div class="bg-white rounded-lg p-6 w-full max-w-2xl max-h-[90vh] overflow-y-auto">
                <div class="flex justify-between items-center mb-4">
                    <h2 id="questStopModalTitle" class="text-xl font-bold">Add New Quest Stop</h2>
                    <button onclick="closeModal('questStopModal')" class="text-gray-500 hover:text-gray-700">
                        <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
                        </svg>
                    </button>
                </div>
                <form id="questStopForm">
                    <input type="hidden" id="questStopId" name="id">
                    <input type="hidden" id="questStopQuestId" name="quest_id">
                    <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                        <div>
                            <label class="block text-sm font-medium mb-2">Name *</label>
                            <input type="text" id="questStopName" name="name" required class="w-full p-2 border rounded-md">
                        </div>
                        <div>
                            <label class="block text-sm font-medium mb-2">Order *</label>
                            <input type="number" id="questStopOrder" name="order_index" required class="w-full p-2 border rounded-md">
                        </div>
                        <div>
                            <label class="block text-sm font-medium mb-2">Latitude</label>
                            <input type="number" step="any" id="questStopLatitude" name="latitude" class="w-full p-2 border rounded-md">
                        </div>
                        <div>
                            <label class="block text-sm font-medium mb-2">Longitude</label>
                            <input type="number" step="any" id="questStopLongitude" name="longitude" class="w-full p-2 border rounded-md">
                        </div>
                    </div>
                    <div class="mt-4">
                        <label class="block text-sm font-medium mb-2">Clue</label>
                        <textarea id="questStopClue" name="clue" rows="3" class="w-full p-2 border rounded-md"></textarea>
                    </div>
                    <div class="mt-4">
                        <label class="block text-sm font-medium mb-2">Instructions</label>
                        <textarea id="questStopInstructions" name="instructions" rows="3" class="w-full p-2 border rounded-md"></textarea>
                    </div>
                    <div class="flex justify-end gap-2 mt-6">
                        <button type="button" onclick="closeModal('questStopModal')" class="px-4 py-2 text-gray-600 bg-gray-100 rounded-md hover:bg-gray-200">Cancel</button>
                        <button type="submit" class="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700">Save Quest Stop</button>
                    </div>
                </form>
            </div>
        </div>
    `,

    city: `
        <div id="cityModal" class="fixed inset-0 bg-black bg-opacity-50 z-50 flex items-center justify-center">
            <div class="bg-white rounded-lg p-6 w-full max-w-md">
                <div class="flex justify-between items-center mb-4">
                    <h2 id="cityModalTitle" class="text-xl font-bold">Add New City</h2>
                    <button onclick="closeModal('cityModal')" class="text-gray-500 hover:text-gray-700">
                        <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
                        </svg>
                    </button>
                </div>
                <form id="cityForm">
                    <input type="hidden" id="cityId" name="id">
                    <div class="space-y-4">
                        <div>
                            <label class="block text-sm font-medium mb-2">Name *</label>
                            <input type="text" id="cityName" name="name" required class="w-full p-2 border rounded-md">
                        </div>
                        <div>
                            <label class="block text-sm font-medium mb-2">Description</label>
                            <textarea id="cityDescription" name="description" rows="3" class="w-full p-2 border rounded-md"></textarea>
                        </div>
                    </div>
                    <div class="flex justify-end gap-2 mt-6">
                        <button type="button" onclick="closeModal('cityModal')" class="px-4 py-2 text-gray-600 bg-gray-100 rounded-md hover:bg-gray-200">Cancel</button>
                        <button type="submit" class="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700">Save City</button>
                    </div>
                </form>
            </div>
        </div>
    `,

    category: `
        <div id="categoryModal" class="fixed inset-0 bg-black bg-opacity-50 z-50 flex items-center justify-center">
            <div class="bg-white rounded-lg p-6 w-full max-w-md">
                <div class="flex justify-between items-center mb-4">
                    <h2 id="categoryModalTitle" class="text-xl font-bold">Add New Category</h2>
                    <button onclick="closeModal('categoryModal')" class="text-gray-500 hover:text-gray-700">
                        <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
                        </svg>
                    </button>
                </div>
                <form id="categoryForm">
                    <input type="hidden" id="categoryId" name="id">
                    <div class="space-y-4">
                        <div>
                            <label class="block text-sm font-medium mb-2">Name *</label>
                            <input type="text" id="categoryName" name="name" required class="w-full p-2 border rounded-md">
                        </div>
                        <div>
                            <label class="block text-sm font-medium mb-2">Description</label>
                            <textarea id="categoryDescription" name="description" rows="3" class="w-full p-2 border rounded-md"></textarea>
                        </div>
                    </div>
                    <div class="flex justify-end gap-2 mt-6">
                        <button type="button" onclick="closeModal('categoryModal')" class="px-4 py-2 text-gray-600 bg-gray-100 rounded-md hover:bg-gray-200">Cancel</button>
                        <button type="submit" class="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700">Save Category</button>
                    </div>
                </form>
            </div>
        </div>
    `,

    user: `
        <div id="userModal" class="fixed inset-0 bg-black bg-opacity-50 z-50 flex items-center justify-center">
            <div class="bg-white rounded-lg p-6 w-full max-w-2xl">
                <div class="flex justify-between items-center mb-4">
                    <h2 id="userModalTitle" class="text-xl font-bold">User Details</h2>
                    <button onclick="closeModal('userModal')" class="text-gray-500 hover:text-gray-700">
                        <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
                        </svg>
                    </button>
                </div>
                <div id="userModalContent">
                    <!-- User details will be populated here -->
                </div>
                <div class="flex justify-end mt-6">
                    <button onclick="closeModal('userModal')" class="px-4 py-2 bg-gray-600 text-white rounded-md hover:bg-gray-700">Close</button>
                </div>
            </div>
        </div>
    `
};

// Simple function to create and show a modal
function showModal(modalType, data = {}) {
    console.log('showModal called:', modalType, data);
    
    // Remove any existing modal
    const existingModal = document.querySelector('.fixed.inset-0.bg-black.bg-opacity-50');
    if (existingModal) {
        existingModal.remove();
    }
    
    // Get the template
    const template = MODAL_TEMPLATES[modalType];
    if (!template) {
        console.error('Modal template not found:', modalType);
        return;
    }
    
    // Create modal element
    const modalDiv = document.createElement('div');
    modalDiv.innerHTML = template;
    const modal = modalDiv.firstElementChild;
    
    // Add to document
    document.body.appendChild(modal);
    
    // Populate data if provided
    if (Object.keys(data).length > 0) {
        populateModal(modalType, data);
    }
    
    // Add event listeners
    setupModalEventListeners(modalType);
    
    // Focus first input
    const firstInput = modal.querySelector('input:not([type="hidden"]), textarea, select');
    if (firstInput) {
        setTimeout(() => firstInput.focus(), 100);
    }
}

// Simple function to close a modal
function closeModal(modalId) {
    console.log('closeModal called:', modalId);
    const modal = document.getElementById(modalId);
    if (modal) {
        modal.remove();
    }
}

// Populate modal with data
function populateModal(modalType, data) {
    console.log('Populating modal:', modalType, data);
    
    switch (modalType) {
        case 'quest':
            if (data.id) document.getElementById('questId').value = data.id;
            if (data.title) document.getElementById('questTitle').value = data.title;
            if (data.category_id) document.getElementById('questCategory').value = data.category_id;
            if (data.city_id) document.getElementById('questCity').value = data.city_id;
            if (data.difficulty) document.getElementById('questDifficulty').value = data.difficulty;
            if (data.estimated_duration) document.getElementById('questDuration').value = data.estimated_duration;
            if (data.estimated_distance) document.getElementById('questDistance').value = data.estimated_distance;
            if (data.description) document.getElementById('questDescription').value = data.description;
            if (data.start_instructions) document.getElementById('questStartInstructions').value = data.start_instructions;
            
            document.getElementById('questModalTitle').textContent = data.id ? 'Edit Quest' : 'Add New Quest';
            break;
            
        case 'questStop':
            if (data.id) document.getElementById('questStopId').value = data.id;
            if (data.quest_id) document.getElementById('questStopQuestId').value = data.quest_id;
            if (data.name) document.getElementById('questStopName').value = data.name;
            if (data.order_index) document.getElementById('questStopOrder').value = data.order_index;
            if (data.latitude) document.getElementById('questStopLatitude').value = data.latitude;
            if (data.longitude) document.getElementById('questStopLongitude').value = data.longitude;
            if (data.clue) document.getElementById('questStopClue').value = data.clue;
            if (data.instructions) document.getElementById('questStopInstructions').value = data.instructions;
            
            document.getElementById('questStopModalTitle').textContent = data.id ? 'Edit Quest Stop' : 'Add New Quest Stop';
            break;
            
        case 'city':
            if (data.id) document.getElementById('cityId').value = data.id;
            if (data.name) document.getElementById('cityName').value = data.name;
            if (data.description) document.getElementById('cityDescription').value = data.description;
            
            document.getElementById('cityModalTitle').textContent = data.id ? 'Edit City' : 'Add New City';
            break;
            
        case 'category':
            if (data.id) document.getElementById('categoryId').value = data.id;
            if (data.name) document.getElementById('categoryName').value = data.name;
            if (data.description) document.getElementById('categoryDescription').value = data.description;
            
            document.getElementById('categoryModalTitle').textContent = data.id ? 'Edit Category' : 'Add New Category';
            break;
            
        case 'user':
            const content = document.getElementById('userModalContent');
            content.innerHTML = `
                <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <div><strong>ID:</strong> ${data.id || 'N/A'}</div>
                    <div><strong>Email:</strong> ${data.email || 'N/A'}</div>
                    <div><strong>Display Name:</strong> ${data.display_name || 'N/A'}</div>
                    <div><strong>Created:</strong> ${data.created_at ? new Date(data.created_at).toLocaleDateString() : 'N/A'}</div>
                    <div><strong>Points:</strong> ${data.total_points || 0}</div>
                    <div><strong>Quests Completed:</strong> ${data.completed_quests || 0}</div>
                </div>
            `;
            break;
    }
}

// Setup event listeners for modal forms
function setupModalEventListeners(modalType) {
    const formId = modalType + 'Form';
    const form = document.getElementById(formId);
    
    if (form) {
        form.addEventListener('submit', function(e) {
            e.preventDefault();
            
            // Get form data
            const formData = new FormData(form);
            const data = Object.fromEntries(formData);
            
            // Remove empty values
            Object.keys(data).forEach(key => {
                if (data[key] === '' || data[key] === null) {
                    delete data[key];
                }
            });
            
            console.log('Form submit:', modalType, data);
            
            // Call the appropriate save function
            switch (modalType) {
                case 'quest':
                    if (window.saveQuest) window.saveQuest(data);
                    break;
                case 'questStop':
                    if (window.saveQuestStop) window.saveQuestStop(data);
                    break;
                case 'city':
                    if (window.saveCity) window.saveCity(data);
                    break;
                case 'category':
                    if (window.saveCategory) window.saveCategory(data);
                    break;
            }
            
            closeModal(modalType + 'Modal');
        });
    }
}

// Make functions globally available
window.showModal = showModal;
window.closeModal = closeModal;
window.populateModal = populateModal;

console.log('Simple Modal System initialized');