// Modal Management System

class ModalManager {
    constructor() {
        this.modals = new Map();
        this.setupModalContainer();
    }

    setupModalContainer() {
        const container = document.getElementById('modalsContainer');
        if (!container) {
            console.error('Modals container not found');
            return;
        }
        
        // Add escape key listener
        document.addEventListener('keydown', (e) => {
            if (e.key === 'Escape') {
                this.closeTopModal();
            }
        });
    }

    create(id, title, content, size = 'md', closable = true) {
        const sizes = {
            sm: 'max-w-md',
            md: 'max-w-2xl',
            lg: 'max-w-4xl',
            xl: 'max-w-6xl',
            full: 'max-w-7xl'
        };

        const closeButton = closable ? `
            <button onclick="ModalManager.close('${id}')" 
                    class="text-gray-400 hover:text-gray-600 transition duration-200">
                <i class="fas fa-times text-xl"></i>
            </button>
        ` : '';

        const modalHtml = `
            <div id="${id}" class="modal fixed inset-0 bg-gray-900 bg-opacity-50 flex items-center justify-center z-50 p-4">
                <div class="bg-white rounded-xl shadow-2xl ${sizes[size]} w-full max-h-full overflow-hidden">
                    <div class="flex justify-between items-center p-6 border-b border-gray-200">
                        <h2 class="text-xl font-bold text-gray-900">${title}</h2>
                        ${closeButton}
                    </div>
                    <div class="p-6 overflow-y-auto max-h-96">
                        ${content}
                    </div>
                </div>
            </div>
        `;

        const container = document.getElementById('modalsContainer');
        container.insertAdjacentHTML('beforeend', modalHtml);
        
        const modal = document.getElementById(id);
        this.modals.set(id, modal);
        
        // Add click outside to close
        if (closable) {
            modal.addEventListener('click', (e) => {
                if (e.target === modal) {
                    this.close(id);
                }
            });
        }

        return modal;
    }

    show(id) {
        const modal = this.modals.get(id);
        if (modal) {
            modal.classList.add('active');
            document.body.style.overflow = 'hidden';
        }
    }

    close(id) {
        const modal = this.modals.get(id);
        if (modal) {
            modal.classList.remove('active');
            document.body.style.overflow = '';
            setTimeout(() => {
                modal.remove();
                this.modals.delete(id);
            }, 300);
        }
    }

    closeAll() {
        this.modals.forEach((modal, id) => {
            this.close(id);
        });
    }

    closeTopModal() {
        const activeModals = Array.from(this.modals.values()).filter(modal => 
            modal.classList.contains('active')
        );
        if (activeModals.length > 0) {
            const topModal = activeModals[activeModals.length - 1];
            const modalId = topModal.id;
            this.close(modalId);
        }
    }
}

// Initialize global modal manager
window.ModalManager = new ModalManager();

// Quest Stop Modal
function showQuestStopModal(questStop = null) {
    const isEdit = !!questStop;
    const title = isEdit ? 'Edit Quest Stop' : 'Add New Quest Stop';
    
    // Load cities and quests for dropdowns
    Promise.all([
        loadCitiesForDropdown(),
        loadQuestsForDropdown()
    ]).then(([cities, quests]) => {
        const challengeTypes = Object.entries(CONFIG.CHALLENGE_TYPES).map(([key, config]) => ({
            value: key,
            label: config.name
        }));

        const content = `
            <form id="questStopForm" class="space-y-4">
                ${UIComponents.createSelect('questId', 'Quest', quests, true, questStop?.quest_id || '')}
                ${UIComponents.createInput('title', 'Stop Title', 'text', true, 'Enter stop title', questStop?.title || '')}
                ${UIComponents.createTextarea('description', 'Description', false, 'Enter stop description', questStop?.description || '')}
                ${UIComponents.createTextarea('clue', 'Clue', false, 'Enter clue for players', questStop?.clue || '')}
                ${UIComponents.createSelect('challengeType', 'Challenge Type', challengeTypes, true, questStop?.challenge_type || '')}
                
                <div id="challengeSpecificFields"></div>
                
                ${UIComponents.createInput('points', 'Points', 'number', true, '10', questStop?.points || '10')}
                ${UIComponents.createInput('radius', 'Location Radius (meters)', 'number', false, '50', questStop?.radius || '50')}
                ${UIComponents.createInput('orderIndex', 'Order', 'number', true, '1', questStop?.order_index || '1')}
                
                <div id="locationInfo" class="p-4 bg-gray-50 rounded-lg">
                    <h4 class="font-semibold mb-2">Location Information</h4>
                    <p id="locationDisplay" class="text-sm text-gray-600">
                        ${questStop ? `${questStop.latitude}, ${questStop.longitude}` : 'Click on the map to select a location'}
                    </p>
                </div>
                
                <div class="flex justify-end space-x-4 pt-4">
                    <button type="button" onclick="ModalManager.close('questStopModal')" 
                            class="bg-gray-500 hover:bg-gray-600 text-white font-semibold py-2 px-4 rounded-lg">
                        Cancel
                    </button>
                    <button type="submit" 
                            class="bg-blue-600 hover:bg-blue-700 text-white font-semibold py-2 px-4 rounded-lg">
                        ${isEdit ? 'Update' : 'Create'} Stop
                    </button>
                </div>
            </form>
        `;

        ModalManager.create('questStopModal', title, content, 'lg');
        ModalManager.show('questStopModal');

        // Set up form handlers
        setupQuestStopForm(questStop);
    });
}

function setupQuestStopForm(questStop = null) {
    const form = document.getElementById('questStopForm');
    const challengeTypeSelect = document.getElementById('challengeType');
    const challengeFieldsContainer = document.getElementById('challengeSpecificFields');

    // Handle challenge type change
    challengeTypeSelect.addEventListener('change', function() {
        updateChallengeFields(this.value, questStop);
    });

    // Initialize challenge fields if editing
    if (questStop && questStop.challenge_type) {
        updateChallengeFields(questStop.challenge_type, questStop);
    }

    // Handle form submission
    form.addEventListener('submit', async function(e) {
        e.preventDefault();
        await handleQuestStopSubmit(questStop);
    });
}

function updateChallengeFields(challengeType, questStop = null) {
    const container = document.getElementById('challengeSpecificFields');
    let fields = '';

    switch(challengeType) {
        case 'text':
            fields = `
                ${UIComponents.createInput('challengeText', 'Question', 'text', true, 'Enter the question', questStop?.challenge_text || '')}
                ${UIComponents.createInput('challengeAnswer', 'Correct Answer', 'text', true, 'Enter the correct answer', questStop?.challenge_answer || '')}
                ${UIComponents.createTextarea('successMessage', 'Success Message', false, 'Message when correct', questStop?.success_message || '')}
                ${UIComponents.createTextarea('failureMessage', 'Failure Message', false, 'Message when incorrect', questStop?.failure_message || '')}
            `;
            break;

        case 'multiple_choice':
            const options = questStop?.multiple_choice_options || ['', '', '', ''];
            fields = `
                ${UIComponents.createInput('challengeText', 'Question', 'text', true, 'Enter the question', questStop?.challenge_text || '')}
                <div class="mb-4">
                    <label class="block text-gray-700 text-sm font-semibold mb-2">Answer Options</label>
                    ${options.map((option, index) => `
                        <div class="mb-2">
                            <input type="text" 
                                   id="option${index}" 
                                   name="option${index}"
                                   placeholder="Option ${index + 1}"
                                   value="${option || ''}"
                                   class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                                   required />
                        </div>
                    `).join('')}
                </div>
                ${UIComponents.createSelect('correctChoiceIndex', 'Correct Answer', [
                    { value: 0, label: 'Option 1' },
                    { value: 1, label: 'Option 2' },
                    { value: 2, label: 'Option 3' },
                    { value: 3, label: 'Option 4' }
                ], true, questStop?.correct_choice_index?.toString() || '')}
                ${UIComponents.createTextarea('successMessage', 'Success Message', false, 'Message when correct', questStop?.success_message || '')}
                ${UIComponents.createTextarea('failureMessage', 'Failure Message', false, 'Message when incorrect', questStop?.failure_message || '')}
            `;
            break;

        case 'photo':
            fields = `
                ${UIComponents.createInput('challengeText', 'Photo Instructions', 'text', true, 'What should they photograph?', questStop?.challenge_text || '')}
                ${UIComponents.createTextarea('successMessage', 'Success Message', false, 'Message when photo taken', questStop?.success_message || '')}
            `;
            break;

        case 'qr_code':
            fields = `
                ${UIComponents.createInput('challengeText', 'QR Code Instructions', 'text', true, 'Instructions for finding QR code', questStop?.challenge_text || '')}
                ${UIComponents.createInput('challengeAnswer', 'Expected QR Code Content', 'text', true, 'What the QR code should contain', questStop?.challenge_answer || '')}
                ${UIComponents.createTextarea('successMessage', 'Success Message', false, 'Message when QR scanned', questStop?.success_message || '')}
                ${UIComponents.createTextarea('failureMessage', 'Failure Message', false, 'Message when wrong QR', questStop?.failure_message || '')}
            `;
            break;

        case 'audio':
            fields = `
                ${UIComponents.createInput('challengeText', 'Audio Instructions', 'text', true, 'What should they record?', questStop?.challenge_text || '')}
                ${UIComponents.createTextarea('successMessage', 'Success Message', false, 'Message when audio recorded', questStop?.success_message || '')}
            `;
            break;

        case 'regex':
            fields = `
                ${UIComponents.createInput('challengeText', 'Pattern Instructions', 'text', true, 'Describe the pattern to match', questStop?.challenge_text || '')}
                ${UIComponents.createInput('challengeRegex', 'Regular Expression', 'text', true, 'The regex pattern (e.g., ^[0-9]{4}-[A-Z]{2}$)', questStop?.challenge_regex || '')}
                ${UIComponents.createTextarea('successMessage', 'Success Message', false, 'Message when pattern matches', questStop?.success_message || '')}
                ${UIComponents.createTextarea('failureMessage', 'Failure Message', false, 'Message when pattern fails', questStop?.failure_message || '')}
            `;
            break;

        case 'location_only':
        default:
            fields = `
                ${UIComponents.createTextarea('successMessage', 'Success Message', false, 'Message when location reached', questStop?.success_message || '')}
            `;
            break;
    }

    container.innerHTML = fields;
}

async function handleQuestStopSubmit(existingQuestStop = null) {
    const form = document.getElementById('questStopForm');
    const formData = new FormData(form);
    
    try {
        showLoading(true);

        // Validate location is selected
        const selectedLocation = window.AppState.selectedLocation;
        if (!existingQuestStop && !selectedLocation) {
            throw new Error('Please select a location on the map');
        }

        // Build quest stop data
        const questStopData = {
            quest_id: formData.get('questId'),
            title: formData.get('title'),
            description: formData.get('description') || null,
            clue: formData.get('clue') || null,
            challenge_type: formData.get('challengeType'),
            challenge_text: formData.get('challengeText') || null,
            points: parseInt(formData.get('points')),
            radius: parseInt(formData.get('radius')) || 50,
            order_index: parseInt(formData.get('orderIndex')),
            latitude: selectedLocation?.lat || existingQuestStop?.latitude,
            longitude: selectedLocation?.lng || existingQuestStop?.longitude,
            success_message: formData.get('successMessage') || null,
            failure_message: formData.get('failureMessage') || null
        };

        // Handle challenge-specific fields
        const challengeType = formData.get('challengeType');
        
        if (challengeType === 'text' || challengeType === 'qr_code') {
            questStopData.challenge_answer = formData.get('challengeAnswer');
        }
        
        if (challengeType === 'multiple_choice') {
            const options = [
                formData.get('option0'),
                formData.get('option1'),
                formData.get('option2'),
                formData.get('option3')
            ].filter(opt => opt && opt.trim());
            
            questStopData.multiple_choice_options = JSON.stringify(options);
            questStopData.correct_choice_index = parseInt(formData.get('correctChoiceIndex'));
        }
        
        if (challengeType === 'regex') {
            questStopData.challenge_regex = formData.get('challengeRegex');
        }

        // Save to database
        let result;
        if (existingQuestStop) {
            result = await supabaseClient
                .from('quest_stops')
                .update(questStopData)
                .eq('id', existingQuestStop.id);
        } else {
            result = await supabaseClient
                .from('quest_stops')
                .insert([questStopData]);
        }

        if (result.error) throw result.error;

        Utils.showToast(
            `Quest stop ${existingQuestStop ? 'updated' : 'created'} successfully!`, 
            'success'
        );
        
        ModalManager.close('questStopModal');
        
        // Clear selected location
        window.AppState.selectedLocation = null;
        document.getElementById('locationDisplay').textContent = 'None selected';
        
        // Reload quest stops
        if (typeof loadQuestStopsData === 'function') {
            await loadQuestStopsData();
        }

    } catch (error) {
        Utils.handleError(error, 'Failed to save quest stop');
    } finally {
        showLoading(false);
    }
}

// Helper functions for dropdowns
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

async function loadQuestsForDropdown() {
    try {
        const { data: quests, error } = await supabaseClient
            .from('quests')
            .select('id, title')
            .eq('is_active', true)
            .order('title');
            
        if (error) throw error;
        
        return quests.map(quest => ({
            value: quest.id,
            label: quest.title
        }));
    } catch (error) {
        console.error('Error loading quests:', error);
        return [];
    }
}

// Export modal functions
window.Modals = {
    showQuestStopModal,
    setupQuestStopForm,
    updateChallengeFields,
    handleQuestStopSubmit
};