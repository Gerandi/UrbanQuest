// Modal Manager for Dynamic Modal Creation and Management

class ModalManager {
    constructor() {
        this.modals = new Map();
        this.setupGlobalStyles();
    }

    setupGlobalStyles() {
        // Add modal styles if they don't exist
        if (!document.querySelector('#modal-styles')) {
            const style = document.createElement('style');
            style.id = 'modal-styles';
            style.textContent = `
                .modal-overlay {
                    position: fixed;
                    top: 0;
                    left: 0;
                    width: 100%;
                    height: 100%;
                    background-color: rgba(0, 0, 0, 0.5);
                    z-index: 9999;
                    display: flex;
                    align-items: center;
                    justify-content: center;
                    opacity: 0;
                    visibility: hidden;
                    transition: opacity 0.3s ease, visibility 0.3s ease;
                }
                
                .modal-overlay.show {
                    opacity: 1;
                    visibility: visible;
                }
                
                .modal-content {
                    background: white;
                    border-radius: 8px;
                    box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.25);
                    max-height: 90vh;
                    overflow-y: auto;
                    transform: scale(0.95);
                    transition: transform 0.3s ease;
                }
                
                .modal-overlay.show .modal-content {
                    transform: scale(1);
                }
                
                .modal-content.size-sm { max-width: 400px; }
                .modal-content.size-md { max-width: 600px; }
                .modal-content.size-lg { max-width: 800px; }
                .modal-content.size-xl { max-width: 1200px; }
                .modal-content.size-full { max-width: 95vw; }
                
                .modal-header {
                    padding: 1.5rem;
                    border-bottom: 1px solid #e5e7eb;
                    display: flex;
                    justify-content: space-between;
                    align-items: center;
                }
                
                .modal-title {
                    font-size: 1.25rem;
                    font-weight: 600;
                    color: #111827;
                    margin: 0;
                }
                
                .modal-close {
                    background: none;
                    border: none;
                    font-size: 1.5rem;
                    color: #6b7280;
                    cursor: pointer;
                    padding: 0.25rem;
                    border-radius: 0.25rem;
                    transition: color 0.2s;
                }
                
                .modal-close:hover {
                    color: #374151;
                }
                
                .modal-body {
                    padding: 1.5rem;
                }
            `;
            document.head.appendChild(style);
        }
    }

    create(id, title, content, size = 'md') {
        // Remove existing modal with same ID
        this.destroy(id);

        // Create modal HTML
        const modal = document.createElement('div');
        modal.id = id;
        modal.className = 'modal-overlay';
        modal.innerHTML = `
            <div class="modal-content size-${size}">
                <div class="modal-header">
                    <h3 class="modal-title">${title}</h3>
                    <button type="button" class="modal-close" onclick="window.ModalManager.close('${id}')">&times;</button>
                </div>
                <div class="modal-body">
                    ${content}
                </div>
            </div>
        `;

        // Add click outside to close
        modal.addEventListener('click', (e) => {
            if (e.target === modal) {
                this.close(id);
            }
        });

        // Add escape key to close
        const handleEscape = (e) => {
            if (e.key === 'Escape') {
                this.close(id);
                document.removeEventListener('keydown', handleEscape);
            }
        };

        document.addEventListener('keydown', handleEscape);

        // Store modal and its cleanup function
        this.modals.set(id, {
            element: modal,
            cleanup: () => document.removeEventListener('keydown', handleEscape)
        });

        // Add to DOM
        document.body.appendChild(modal);

        return modal;
    }

    show(id) {
        const modalData = this.modals.get(id);
        if (modalData) {
            // Force a reflow to ensure transition works
            modalData.element.offsetHeight;
            modalData.element.classList.add('show');
            document.body.style.overflow = 'hidden';
        }
    }

    close(id) {
        const modalData = this.modals.get(id);
        if (modalData) {
            modalData.element.classList.remove('show');
            
            // Wait for transition to complete before removing
            setTimeout(() => {
                this.destroy(id);
            }, 300);
            
            // Restore body scroll
            document.body.style.overflow = '';
        }
    }

    destroy(id) {
        const modalData = this.modals.get(id);
        if (modalData) {
            // Run cleanup
            if (modalData.cleanup) {
                modalData.cleanup();
            }
            
            // Remove from DOM
            if (modalData.element && modalData.element.parentNode) {
                modalData.element.parentNode.removeChild(modalData.element);
            }
            
            // Remove from map
            this.modals.delete(id);
        }
    }

    closeAll() {
        Array.from(this.modals.keys()).forEach(id => this.close(id));
    }

    isOpen(id) {
        const modalData = this.modals.get(id);
        return modalData && modalData.element.classList.contains('show');
    }
}

// Create global instance immediately
window.ModalManager = new ModalManager();
console.log('ModalManager initialized successfully');

// Make it available in global scope for all modules
if (typeof globalThis !== 'undefined') {
    globalThis.ModalManager = window.ModalManager;
}

// Also make it available without window prefix in script scope
if (typeof global !== 'undefined') {
    global.ModalManager = window.ModalManager;
}

// Export for modules
if (typeof module !== 'undefined' && module.exports) {
    module.exports = ModalManager;
}