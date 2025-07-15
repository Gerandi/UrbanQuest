// Users Management Module
const UserManager = {
    currentUsers: [],
    
    async init() {
        await this.waitForSupabase();
        await this.loadUsers();
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
            
            setTimeout(() => {
                clearInterval(checkInterval);
                console.error('❌ Supabase not available after 10 seconds in users.js');
                resolve();
            }, 10000);
        });
    },

    setupEventListeners() {
        // Any additional event listeners can be added here
    },

    async loadUsers() {
        try {
            const { data: users, error } = await supabase
                .from('profiles')
                .select('*')
                .order('created_at', { ascending: false });

            if (error) throw error;

            this.currentUsers = users || [];
            this.displayUsers();
        } catch (error) {
            console.error('Error loading users:', error);
            Utils.showNotification('Error loading users: ' + error.message, 'error');
        }
    },

    displayUsers() {
        const usersList = document.getElementById('usersList');
        if (!usersList) return;

        if (this.currentUsers.length === 0) {
            usersList.innerHTML = '<div class="text-center py-8 text-gray-500">No users found</div>';
            return;
        }

        usersList.innerHTML = this.currentUsers.map(user => this.createUserCard(user)).join('');
    },

    createUserCard(user) {
        return `
            <div class="bg-white rounded-lg shadow-md p-6 user-card" data-user-id="${user.id}">
                <div class="flex justify-between items-start mb-4">
                    <div class="flex-1">
                        <h3 class="text-lg font-semibold text-gray-900 mb-2">${Utils.escapeHtml(user.display_name || user.email || 'Unknown User')}</h3>
                        <div class="flex flex-wrap gap-2 mb-2">
                            <span class="px-2 py-1 bg-blue-100 text-blue-800 text-xs rounded-full">${user.email || 'No email'}</span>
                            <span class="px-2 py-1 bg-green-100 text-green-800 text-xs rounded-full">${user.total_points || 0} pts</span>
                        </div>
                        <div class="flex gap-4 text-sm text-gray-500">
                            <span>📅 Joined: ${user.created_at ? new Date(user.created_at).toLocaleDateString() : 'Unknown'}</span>
                            <span>🏆 Quests: ${user.completed_quests || 0}</span>
                        </div>
                    </div>
                    <div class="flex gap-2 ml-4">
                        <button onclick="UserManager.viewUser('${user.id}')" 
                                class="text-blue-600 hover:text-blue-800 p-2" title="View User Details">
                            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"></path>
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"></path>
                            </svg>
                        </button>
                        <button onclick="UserManager.deleteUser('${user.id}')" 
                                class="text-red-600 hover:text-red-800 p-2" title="Delete User">
                            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"></path>
                            </svg>
                        </button>
                    </div>
                </div>
            </div>
        `;
    },

    viewUser(userId) {
        console.log('Viewing user:', userId);
        const user = this.currentUsers.find(u => u.id === userId);
        if (!user) {
            Utils.showNotification('User not found', 'error');
            return;
        }

        showModal('user', user);
    },

    async deleteUser(userId) {
        if (!confirm('Are you sure you want to delete this user? This action cannot be undone.')) {
            return;
        }

        try {
            const { error } = await supabase
                .from('profiles')
                .delete()
                .eq('id', userId);

            if (error) throw error;

            Utils.showNotification('User deleted successfully!', 'success');
            await this.loadUsers();
        } catch (error) {
            console.error('Error deleting user:', error);
            Utils.showNotification('Error deleting user: ' + error.message, 'error');
        }
    }
};

// Initialize when DOM is ready
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', () => UserManager.init());
} else {
    UserManager.init();
}

// Export for use in other modules
window.UserManager = UserManager;