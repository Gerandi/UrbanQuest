// Utility functions

// Toast notifications
function showToast(message, type = 'info', duration = 5000) {
    const toastContainer = document.getElementById('toastContainer');
    const toastId = 'toast-' + Date.now();
    
    const iconMap = {
        success: 'fas fa-check-circle',
        error: 'fas fa-exclamation-circle',
        warning: 'fas fa-exclamation-triangle',
        info: 'fas fa-info-circle'
    };
    
    const colorMap = {
        success: 'bg-green-500',
        error: 'bg-red-500',
        warning: 'bg-yellow-500',
        info: 'bg-blue-500'
    };
    
    const toast = document.createElement('div');
    toast.id = toastId;
    toast.className = `toast ${colorMap[type]} text-white px-6 py-4 rounded-lg shadow-lg flex items-center space-x-3 max-w-sm fade-in`;
    toast.innerHTML = `
        <i class="${iconMap[type]}"></i>
        <span class="flex-1">${message}</span>
        <button onclick="removeToast('${toastId}')" class="text-white hover:text-gray-200">
            <i class="fas fa-times"></i>
        </button>
    `;
    
    toastContainer.appendChild(toast);
    
    if (duration > 0) {
        setTimeout(() => removeToast(toastId), duration);
    }
    
    return toastId;
}

function removeToast(toastId) {
    const toast = document.getElementById(toastId);
    if (toast) {
        toast.style.transform = 'translateX(100%)';
        toast.style.opacity = '0';
        setTimeout(() => toast.remove(), 300);
    }
}

// Loading states
function showLoading(show = true) {
    const overlay = document.getElementById('loadingOverlay');
    if (show) {
        overlay.classList.remove('hidden');
        window.AppState.isLoading = true;
    } else {
        overlay.classList.add('hidden');
        window.AppState.isLoading = false;
    }
}

function showElementLoading(elementId, show = true) {
    const element = document.getElementById(elementId);
    if (!element) return;
    
    if (show) {
        element.innerHTML = `
            <div class="flex items-center justify-center py-8">
                <div class="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
                <span class="ml-3 text-gray-600">Loading...</span>
            </div>
        `;
    }
}

// Error handling
function handleError(error, context = '') {
    console.error(`Error in ${context}:`, error);
    const message = error.message || 'An unexpected error occurred';
    showToast(context ? `${context}: ${message}` : message, 'error');
}

// Format functions
function formatDate(date) {
    if (!date) return 'Never';
    return new Date(date).toLocaleDateString('en-US', {
        year: 'numeric',
        month: 'short',
        day: 'numeric',
        hour: '2-digit',
        minute: '2-digit'
    });
}

function formatNumber(num) {
    if (num === null || num === undefined) return '0';
    return parseInt(num).toLocaleString();
}

function formatDistance(meters) {
    if (meters < 1000) {
        return `${Math.round(meters)}m`;
    }
    return `${(meters / 1000).toFixed(1)}km`;
}

// Validation functions
function validateEmail(email) {
    const re = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return re.test(email);
}

function validateRequired(value, fieldName) {
    if (!value || (typeof value === 'string' && value.trim() === '')) {
        throw new Error(`${fieldName} is required`);
    }
    return true;
}

function validateUrl(url) {
    try {
        new URL(url);
        return true;
    } catch {
        return false;
    }
}

function validateLatLng(lat, lng) {
    return lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180;
}

// String utilities
function truncateText(text, maxLength = 100) {
    if (!text) return '';
    if (text.length <= maxLength) return text;
    return text.substring(0, maxLength) + '...';
}

function slugify(text) {
    return text
        .toLowerCase()
        .trim()
        .replace(/[^\w\s-]/g, '')
        .replace(/[\s_-]+/g, '-')
        .replace(/^-+|-+$/g, '');
}

function capitalizeFirst(str) {
    if (!str) return '';
    return str.charAt(0).toUpperCase() + str.slice(1);
}

// DOM utilities
function createElement(tag, className = '', innerHTML = '') {
    const element = document.createElement(tag);
    if (className) element.className = className;
    if (innerHTML) element.innerHTML = innerHTML;
    return element;
}

function clearElement(elementId) {
    const element = document.getElementById(elementId);
    if (element) element.innerHTML = '';
}

function hideElement(elementId) {
    const element = document.getElementById(elementId);
    if (element) element.classList.add('hidden');
}

function showElement(elementId) {
    const element = document.getElementById(elementId);
    if (element) element.classList.remove('hidden');
}

// Array utilities
function groupBy(array, key) {
    return array.reduce((groups, item) => {
        const group = item[key];
        if (!groups[group]) groups[group] = [];
        groups[group].push(item);
        return groups;
    }, {});
}

function sortBy(array, key, ascending = true) {
    return array.sort((a, b) => {
        if (ascending) {
            return a[key] > b[key] ? 1 : -1;
        } else {
            return a[key] < b[key] ? 1 : -1;
        }
    });
}

// Local storage utilities
function saveToLocalStorage(key, data) {
    try {
        localStorage.setItem(key, JSON.stringify(data));
    } catch (error) {
        console.warn('Failed to save to localStorage:', error);
    }
}

function loadFromLocalStorage(key, defaultValue = null) {
    try {
        const data = localStorage.getItem(key);
        return data ? JSON.parse(data) : defaultValue;
    } catch (error) {
        console.warn('Failed to load from localStorage:', error);
        return defaultValue;
    }
}

// Challenge type utilities
function getChallengeIcon(challengeType) {
    return CONFIG.CHALLENGE_TYPES[challengeType]?.icon || 'fas fa-question';
}

function getChallengeColor(challengeType) {
    return CONFIG.CHALLENGE_TYPES[challengeType]?.color || 'gray';
}

function getChallengeName(challengeType) {
    return CONFIG.CHALLENGE_TYPES[challengeType]?.name || challengeType;
}

// Database utilities
async function checkConnection() {
    try {
        const { data, error } = await supabaseClient
            .from('cities')
            .select('id')
            .limit(1);
        
        if (error) throw error;
        return true;
    } catch (error) {
        console.error('Database connection failed:', error);
        showToast('Database connection failed. Please check your internet connection.', 'error');
        return false;
    }
}

// Fallback modal system
function createFallbackModal(title, content) {
    const modal = document.createElement('div');
    modal.style.cssText = `
        position: fixed;
        top: 0;
        left: 0;
        width: 100%;
        height: 100%;
        background: rgba(0,0,0,0.5);
        z-index: 9999;
        display: flex;
        align-items: center;
        justify-content: center;
    `;
    
    modal.innerHTML = `
        <div style="
            background: white;
            padding: 20px;
            border-radius: 8px;
            max-width: 600px;
            max-height: 80vh;
            overflow-y: auto;
            position: relative;
        ">
            <h3 style="margin-top: 0; margin-bottom: 15px; font-size: 18px; font-weight: bold;">${title}</h3>
            <div>${content}</div>
            <button onclick="this.closest('[style*=\"position: fixed\"]').remove()" 
                    style="
                        position: absolute;
                        top: 10px;
                        right: 15px;
                        background: none;
                        border: none;
                        font-size: 20px;
                        cursor: pointer;
                    ">×</button>
        </div>
    `;
    
    modal.addEventListener('click', (e) => {
        if (e.target === modal) modal.remove();
    });
    
    document.body.appendChild(modal);
    return modal;
}

// Check ModalManager availability
function ensureModalManager() {
    if (typeof window.ModalManager === 'undefined' || !window.ModalManager.create) {
        console.warn('ModalManager not available, using fallback');
        return false;
    }
    return true;
}

// Export utilities for use in other files
window.Utils = {
    showToast,
    removeToast,
    showLoading,
    showElementLoading,
    handleError,
    formatDate,
    formatNumber,
    formatDistance,
    validateEmail,
    validateRequired,
    validateUrl,
    validateLatLng,
    truncateText,
    slugify,
    capitalizeFirst,
    createElement,
    clearElement,
    hideElement,
    showElement,
    groupBy,
    sortBy,
    saveToLocalStorage,
    loadFromLocalStorage,
    getChallengeIcon,
    getChallengeColor,
    getChallengeName,
    checkConnection,
    createFallbackModal,
    ensureModalManager
};