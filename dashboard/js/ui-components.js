// Reusable UI Components

// Create a standard card component
function createCard(title, content, actions = [], icon = null) {
    const iconHtml = icon ? `<i class="${icon} mr-2"></i>` : '';
    const actionsHtml = actions.length > 0 ? 
        `<div class="flex space-x-2">${actions.join('')}</div>` : '';
    
    return `
        <div class="bg-white rounded-lg border border-gray-200 p-4">
            <div class="flex justify-between items-start">
                <div class="flex-1">
                    <h4 class="font-semibold text-lg text-gray-900">
                        ${iconHtml}${title}
                    </h4>
                    <div class="mt-2">
                        ${content}
                    </div>
                </div>
                ${actionsHtml ? `<div class="ml-4">${actionsHtml}</div>` : ''}
            </div>
        </div>
    `;
}

// Create a badge component
function createBadge(text, color = 'blue', size = 'sm') {
    const sizes = {
        xs: 'px-2 py-1 text-xs',
        sm: 'px-2 py-1 text-sm',
        md: 'px-3 py-2 text-sm',
        lg: 'px-4 py-2 text-base'
    };
    
    return `
        <span class="inline-flex items-center ${sizes[size]} font-medium bg-${color}-100 text-${color}-800 rounded-full">
            ${text}
        </span>
    `;
}

// Create a button component
function createButton(text, onClick, variant = 'primary', size = 'md', icon = null) {
    const variants = {
        primary: 'bg-blue-600 hover:bg-blue-700 text-white',
        secondary: 'bg-gray-600 hover:bg-gray-700 text-white',
        success: 'bg-green-600 hover:bg-green-700 text-white',
        danger: 'bg-red-600 hover:bg-red-700 text-white',
        warning: 'bg-yellow-600 hover:bg-yellow-700 text-white',
        outline: 'border border-gray-300 hover:bg-gray-50 text-gray-700'
    };
    
    const sizes = {
        sm: 'px-3 py-1 text-sm',
        md: 'px-4 py-2 text-sm',
        lg: 'px-6 py-3 text-base'
    };
    
    const iconHtml = icon ? `<i class="${icon} mr-2"></i>` : '';
    
    return `
        <button onclick="${onClick}" 
                class="${variants[variant]} ${sizes[size]} font-semibold rounded-lg transition duration-200">
            ${iconHtml}${text}
        </button>
    `;
}

// Create a form input component
function createInput(id, label, type = 'text', required = false, placeholder = '', value = '') {
    const requiredHtml = required ? '<span class="text-red-500">*</span>' : '';
    const requiredAttr = required ? 'required' : '';
    
    return `
        <div class="mb-4">
            <label class="block text-gray-700 text-sm font-semibold mb-2" for="${id}">
                ${label} ${requiredHtml}
            </label>
            <input 
                id="${id}" 
                name="${id}"
                type="${type}" 
                placeholder="${placeholder}"
                value="${value}"
                ${requiredAttr}
                class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
            />
        </div>
    `;
}

// Create a textarea component
function createTextarea(id, label, required = false, placeholder = '', value = '', rows = 3) {
    const requiredHtml = required ? '<span class="text-red-500">*</span>' : '';
    const requiredAttr = required ? 'required' : '';
    
    return `
        <div class="mb-4">
            <label class="block text-gray-700 text-sm font-semibold mb-2" for="${id}">
                ${label} ${requiredHtml}
            </label>
            <textarea 
                id="${id}" 
                name="${id}"
                placeholder="${placeholder}"
                rows="${rows}"
                ${requiredAttr}
                class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
            >${value}</textarea>
        </div>
    `;
}

// Create a select component
function createSelect(id, label, options, required = false, value = '') {
    const requiredHtml = required ? '<span class="text-red-500">*</span>' : '';
    const requiredAttr = required ? 'required' : '';
    
    const optionsHtml = options.map(option => {
        if (typeof option === 'string') {
            const selected = option === value ? 'selected' : '';
            return `<option value="${option}" ${selected}>${option}</option>`;
        } else {
            const selected = option.value === value ? 'selected' : '';
            return `<option value="${option.value}" ${selected}>${option.label}</option>`;
        }
    }).join('');
    
    return `
        <div class="mb-4">
            <label class="block text-gray-700 text-sm font-semibold mb-2" for="${id}">
                ${label} ${requiredHtml}
            </label>
            <select 
                id="${id}" 
                name="${id}"
                ${requiredAttr}
                class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
            >
                <option value="">Select ${label.toLowerCase()}...</option>
                ${optionsHtml}
            </select>
        </div>
    `;
}

// Create a checkbox component
function createCheckbox(id, label, checked = false, value = '') {
    const checkedAttr = checked ? 'checked' : '';
    
    return `
        <div class="mb-4">
            <label class="flex items-center">
                <input 
                    type="checkbox" 
                    id="${id}" 
                    name="${id}"
                    value="${value}"
                    ${checkedAttr}
                    class="rounded border-gray-300 text-blue-600 shadow-sm focus:border-blue-300 focus:ring focus:ring-blue-200 focus:ring-opacity-50"
                />
                <span class="ml-2 text-gray-700">${label}</span>
            </label>
        </div>
    `;
}

// Create a multi-checkbox component
function createMultiCheckbox(name, label, options, selectedValues = []) {
    const checkboxes = options.map(option => {
        const isChecked = selectedValues.includes(option.value);
        const checkedAttr = isChecked ? 'checked' : '';
        
        return `
            <label class="flex items-center py-2">
                <input 
                    type="checkbox" 
                    name="${name}" 
                    value="${option.value}"
                    ${checkedAttr}
                    class="rounded border-gray-300 text-blue-600 shadow-sm focus:border-blue-300 focus:ring focus:ring-blue-200 focus:ring-opacity-50"
                />
                <span class="ml-2 text-gray-700">${option.label}</span>
            </label>
        `;
    }).join('');
    
    return `
        <div class="mb-4">
            <label class="block text-gray-700 text-sm font-semibold mb-2">
                ${label}
            </label>
            <div class="space-y-1 max-h-48 overflow-y-auto border border-gray-300 rounded-lg p-3">
                ${checkboxes}
            </div>
        </div>
    `;
}

// Create a challenge type selector
function createChallengeTypeSelector(selectedType = '') {
    const options = Object.entries(CONFIG.CHALLENGE_TYPES).map(([key, config]) => ({
        value: key,
        label: `${config.name} - ${config.description}`
    }));
    
    return createSelect('challengeType', 'Challenge Type', options, true, selectedType);
}

// Create a difficulty selector
function createDifficultySelector(selectedDifficulty = '') {
    const options = CONFIG.DIFFICULTY_LEVELS.map(level => ({
        value: level,
        label: level.charAt(0).toUpperCase() + level.slice(1)
    }));
    
    return createSelect('difficulty', 'Difficulty', options, true, selectedDifficulty);
}

// Create a language selector
function createLanguageSelector(selectedLanguages = []) {
    const options = CONFIG.LANGUAGES.map(lang => ({
        value: lang,
        label: lang.toUpperCase()
    }));
    
    return createMultiCheckbox('languages', 'Languages', options, selectedLanguages);
}

// Create a statistics card
function createStatCard(title, value, icon, color = 'blue') {
    return `
        <div class="bg-white p-6 rounded-xl shadow-sm border border-gray-200">
            <div class="flex items-center">
                <div class="w-12 h-12 bg-${color}-100 rounded-lg flex items-center justify-center">
                    <i class="${icon} text-${color}-600 text-xl"></i>
                </div>
                <div class="ml-4">
                    <h3 class="text-sm font-medium text-gray-600">${title}</h3>
                    <p class="text-2xl font-bold text-gray-900">${value}</p>
                </div>
            </div>
        </div>
    `;
}

// Create a data table
function createDataTable(headers, rows, actions = []) {
    const headerHtml = headers.map(header => 
        `<th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">${header}</th>`
    ).join('');
    
    const rowsHtml = rows.map(row => {
        const cellsHtml = row.map(cell => 
            `<td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">${cell}</td>`
        ).join('');
        
        const actionsHtml = actions.length > 0 ? 
            `<td class="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                <div class="flex space-x-2">
                    ${actions.join('')}
                </div>
            </td>` : '';
        
        return `<tr class="hover:bg-gray-50">${cellsHtml}${actionsHtml}</tr>`;
    }).join('');
    
    const actionHeaderHtml = actions.length > 0 ? 
        '<th class="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">Actions</th>' : '';
    
    return `
        <div class="overflow-x-auto">
            <table class="min-w-full divide-y divide-gray-200">
                <thead class="bg-gray-50">
                    <tr>
                        ${headerHtml}
                        ${actionHeaderHtml}
                    </tr>
                </thead>
                <tbody class="bg-white divide-y divide-gray-200">
                    ${rowsHtml}
                </tbody>
            </table>
        </div>
    `;
}

// Create an empty state component
function createEmptyState(title, description, actionText = null, actionOnClick = null, icon = 'fas fa-inbox') {
    const actionHtml = actionText && actionOnClick ? 
        `<button onclick="${actionOnClick}" class="mt-4 bg-blue-600 hover:bg-blue-700 text-white font-semibold py-2 px-4 rounded-lg">
            ${actionText}
        </button>` : '';
    
    return `
        <div class="text-center py-12">
            <i class="${icon} text-gray-400 text-4xl mb-4"></i>
            <h3 class="text-lg font-medium text-gray-900 mb-2">${title}</h3>
            <p class="text-gray-600 mb-4">${description}</p>
            ${actionHtml}
        </div>
    `;
}

// Create a progress bar
function createProgressBar(value, max = 100, color = 'blue') {
    const percentage = Math.round((value / max) * 100);
    
    return `
        <div class="w-full bg-gray-200 rounded-full h-2">
            <div class="bg-${color}-600 h-2 rounded-full" style="width: ${percentage}%"></div>
        </div>
        <div class="text-sm text-gray-600 mt-1">${value} / ${max} (${percentage}%)</div>
    `;
}

// Export components
window.UIComponents = {
    createCard,
    createBadge,
    createButton,
    createInput,
    createTextarea,
    createSelect,
    createCheckbox,
    createMultiCheckbox,
    createChallengeTypeSelector,
    createDifficultySelector,
    createLanguageSelector,
    createStatCard,
    createDataTable,
    createEmptyState,
    createProgressBar
};