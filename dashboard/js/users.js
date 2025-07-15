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
        const container = document.getElementById('usersTableContainer');
        if (!container) return;

        if (this.currentUsers.length === 0) {
            container.innerHTML = `
                <div class="text-center py-8 text-gray-500">
                    <i class="fas fa-users text-3xl mb-4"></i>
                    <p>No users found</p>
                </div>
            `;
            return;
        }

        container.innerHTML = `
            <table class="w-full text-left">
                <thead class="bg-gray-50 dark:bg-gray-700">
                    <tr>
                        <th class="p-4 font-semibold text-gray-900 dark:text-gray-100">Profile</th>
                        <th class="p-4 font-semibold text-gray-900 dark:text-gray-100">Email</th>
                        <th class="p-4 font-semibold text-gray-900 dark:text-gray-100">Role</th>
                        <th class="p-4 font-semibold text-gray-900 dark:text-gray-100">Level</th>
                        <th class="p-4 font-semibold text-gray-900 dark:text-gray-100">Points</th>
                        <th class="p-4 font-semibold text-gray-900 dark:text-gray-100">Actions</th>
                    </tr>
                </thead>
                <tbody>
                    ${this.currentUsers.map(user => this.createUserRow(user)).join('')}
                </tbody>
            </table>
        `;
    },

    createUserRow(user) {
        return `
            <tr class="table-row border-b border-gray-200 dark:border-gray-700 transition-colors">
                <td class="p-4 flex items-center">
                    <img src="${user.avatar_url || 'https://placehold.co/40x40/f59e0b/FFFFFF?text=' + (user.display_name ? user.display_name.charAt(0) : 'U')}" 
                         alt="${Utils.escapeHtml(user.display_name)}" 
                         class="w-10 h-10 rounded-full">
                    <span class="ml-3 font-medium text-gray-900 dark:text-gray-100">${Utils.escapeHtml(user.display_name || 'Unknown')}</span>
                </td>
                <td class="p-4 text-gray-600 dark:text-gray-400">${Utils.escapeHtml(user.email)}</td>
                <td class="p-4">
                    <span class="px-2 py-1 text-xs rounded-full capitalize ${this.getRoleBadgeClasses(user.role)}">
                        ${Utils.escapeHtml(user.role || 'user')}
                    </span>
                </td>
                <td class="p-4 text-gray-600 dark:text-gray-400">${user.level || 1}</td>
                <td class="p-4 text-gray-600 dark:text-gray-400">${Utils.formatNumber(user.total_points || 0)}</td>
                <td class="p-4">
                    <div class="flex gap-2">
                        <button onclick="UserManager.viewUser('${user.id}')" 
                                class="p-2 text-blue-500 hover:bg-blue-100 dark:hover:bg-blue-900/50 rounded-full transition-colors" title="View Details">
                            <i class="fas fa-eye text-sm"></i>
                        </button>
                        <button onclick="UserManager.editUser('${user.id}')" 
                                class="p-2 text-blue-500 hover:bg-blue-100 dark:hover:bg-blue-900/50 rounded-full transition-colors" title="Edit User">
                            <i class="fas fa-edit text-sm"></i>
                        </button>
                        <button onclick="UserManager.deleteUser('${user.id}')" 
                                class="p-2 text-red-500 hover:bg-red-100 dark:hover:bg-red-900/50 rounded-full transition-colors" title="Delete User">
                            <i class="fas fa-trash text-sm"></i>
                        </button>
                    </div>
                </td>
            </tr>
        `;
    },

    getRoleBadgeClasses(role) {
        const classes = {
            'admin': 'bg-red-100 text-red-800 dark:bg-red-900/50 dark:text-red-300',
            'super_admin': 'bg-purple-100 text-purple-800 dark:bg-purple-900/50 dark:text-purple-300',
            'content_creator': 'bg-blue-100 text-blue-800 dark:bg-blue-900/50 dark:text-blue-300',
            'user': 'bg-gray-100 text-gray-800 dark:bg-gray-700 dark:text-gray-300'
        };
        return classes[role] || classes['user'];
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
    },

    viewUser(userId) {
        const user = this.currentUsers.find(u => u.id === userId);
        if (!user) {
            Utils.showNotification('User not found', 'error');
            return;
        }
        
        Utils.showNotification(`Viewing user: ${user.display_name || user.email}`, 'info');
        // TODO: Implement user detail modal
    },

    editUser(userId) {
        const user = this.currentUsers.find(u => u.id === userId);
        if (!user) {
            Utils.showNotification('User not found', 'error');
            return;
        }
        
        Utils.showNotification(`Edit user: ${user.display_name || user.email}`, 'info');
        // TODO: Implement user edit modal
    },

    createUser() {
        Utils.showNotification('Create new user modal coming soon!', 'info');
        // TODO: Implement user creation modal
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