// Users Management

// Load users data for the main view
async function loadUsersData() {
    try {
        Utils.showElementLoading('usersList');
        
        const { data: users, error } = await supabaseClient
            .from('users')
            .select(`
                *,
                user_quest_progress(
                    id,
                    is_completed,
                    total_points,
                    quests(title)
                )
            `)
            .order('created_at', { ascending: false });
            
        if (error) throw error;
        
        const usersList = document.getElementById('usersList');
        if (!usersList) return;
        
        if (users && users.length > 0) {
            usersList.innerHTML = users.map(user => createUserCard(user)).join('');
        } else {
            usersList.innerHTML = UIComponents.createEmptyState(
                'No Users Found',
                'Users will appear here as they register and use the app.',
                null,
                null,
                'fas fa-users'
            );
        }
        
    } catch (error) {
        Utils.handleError(error, 'Failed to load users');
        const usersList = document.getElementById('usersList');
        if (usersList) {
            usersList.innerHTML = `
                <div class="text-center py-8">
                    <i class="fas fa-exclamation-triangle text-red-500 text-3xl mb-4"></i>
                    <p class="text-red-600">Failed to load users</p>
                </div>
            `;
        }
    }
}

// Create a user card component
function createUserCard(user) {
    const progress = user.user_quest_progress || [];
    const completedQuests = progress.filter(p => p.is_completed).length;
    const totalPoints = progress.reduce((sum, p) => sum + (p.total_points || 0), 0);
    const inProgressQuests = progress.filter(p => !p.is_completed).length;
    
    // Determine user status
    const isActive = user.last_active_at && 
        new Date(user.last_active_at) > new Date(Date.now() - 7 * 24 * 60 * 60 * 1000); // Active in last 7 days
    
    const statusBadge = isActive 
        ? UIComponents.createBadge('Active', 'green')
        : UIComponents.createBadge('Inactive', 'gray');
    
    const roleBadge = user.role === 'admin' 
        ? UIComponents.createBadge('Admin', 'red')
        : user.role === 'moderator'
        ? UIComponents.createBadge('Moderator', 'purple')
        : UIComponents.createBadge('User', 'blue');
    
    return `
        <div class="bg-white border border-gray-200 rounded-lg p-6 hover:shadow-md transition-shadow">
            <div class="flex justify-between items-start mb-4">
                <div class="flex items-start space-x-4">
                    <div class="w-12 h-12 bg-gradient-to-r from-blue-500 to-purple-600 rounded-full flex items-center justify-center">
                        <span class="text-white font-bold text-lg">
                            ${(user.full_name || user.email || 'U').charAt(0).toUpperCase()}
                        </span>
                    </div>
                    
                    <div class="flex-1">
                        <div class="flex items-center mb-2">
                            <h3 class="text-lg font-semibold text-gray-900 mr-3">
                                ${user.full_name || 'No name provided'}
                            </h3>
                            ${statusBadge}
                            ${roleBadge}
                        </div>
                        
                        <p class="text-gray-600 mb-2">${user.email}</p>
                        
                        <div class="flex items-center space-x-4 text-sm text-gray-500">
                            <span>
                                <i class="fas fa-calendar mr-1"></i>
                                Joined ${Utils.formatDate(user.created_at)}
                            </span>
                            ${user.last_active_at ? `
                                <span>
                                    <i class="fas fa-clock mr-1"></i>
                                    Active ${Utils.formatDate(user.last_active_at)}
                                </span>
                            ` : ''}
                            ${user.preferred_language ? `
                                <span>
                                    <i class="fas fa-language mr-1"></i>
                                    ${user.preferred_language.toUpperCase()}
                                </span>
                            ` : ''}
                        </div>
                    </div>
                </div>
                
                <div class="flex space-x-2">
                    <button onclick="viewUserDetails('${user.id}')" 
                            class="bg-blue-500 hover:bg-blue-600 text-white text-sm font-semibold py-2 px-3 rounded transition duration-200">
                        <i class="fas fa-eye"></i>
                    </button>
                    <button onclick="editUser('${user.id}')" 
                            class="bg-green-500 hover:bg-green-600 text-white text-sm font-semibold py-2 px-3 rounded transition duration-200">
                        <i class="fas fa-edit"></i>
                    </button>
                    ${user.role !== 'admin' ? `
                        <button onclick="deleteUser('${user.id}')" 
                                class="bg-red-500 hover:bg-red-600 text-white text-sm font-semibold py-2 px-3 rounded transition duration-200">
                            <i class="fas fa-trash"></i>
                        </button>
                    ` : ''}
                </div>
            </div>
            
            <div class="border-t border-gray-200 pt-4">
                <div class="grid grid-cols-3 gap-4">
                    <div class="text-center">
                        <div class="text-2xl font-bold text-blue-600">${completedQuests}</div>
                        <div class="text-sm text-gray-500">Completed Quests</div>
                    </div>
                    <div class="text-center">
                        <div class="text-2xl font-bold text-green-600">${Utils.formatNumber(totalPoints)}</div>
                        <div class="text-sm text-gray-500">Total Points</div>
                    </div>
                    <div class="text-center">
                        <div class="text-2xl font-bold text-orange-600">${inProgressQuests}</div>
                        <div class="text-sm text-gray-500">In Progress</div>
                    </div>
                </div>
                
                ${user.bio ? `
                    <div class="mt-4 p-3 bg-gray-50 rounded-lg">
                        <p class="text-sm text-gray-700">${Utils.truncateText(user.bio, 120)}</p>
                    </div>
                ` : ''}
            </div>
        </div>
    `;
}

// View user details
async function viewUserDetails(userId) {
    try {
        const { data: user, error } = await supabaseClient
            .from('users')
            .select(`
                *,
                user_quest_progress(
                    *,
                    quests(title, difficulty, estimated_duration)
                )
            `)
            .eq('id', userId)
            .single();
            
        if (error) throw error;
        
        const progress = user.user_quest_progress || [];
        const completedQuests = progress.filter(p => p.is_completed);
        const inProgressQuests = progress.filter(p => !p.is_completed);
        const totalPoints = progress.reduce((sum, p) => sum + (p.total_points || 0), 0);
        
        const content = `
            <div class="space-y-6">
                <!-- User Info -->
                <div class="border-b border-gray-200 pb-6">
                    <div class="flex items-start space-x-4">
                        <div class="w-16 h-16 bg-gradient-to-r from-blue-500 to-purple-600 rounded-full flex items-center justify-center">
                            <span class="text-white font-bold text-2xl">
                                ${(user.full_name || user.email || 'U').charAt(0).toUpperCase()}
                            </span>
                        </div>
                        
                        <div class="flex-1">
                            <h3 class="text-xl font-bold text-gray-900 mb-2">
                                ${user.full_name || 'No name provided'}
                            </h3>
                            <div class="grid grid-cols-2 gap-4 text-sm">
                                <div><strong>Email:</strong> ${user.email}</div>
                                <div><strong>Role:</strong> ${Utils.capitalizeFirst(user.role || 'user')}</div>
                                <div><strong>Joined:</strong> ${Utils.formatDate(user.created_at)}</div>
                                <div><strong>Last Active:</strong> ${user.last_active_at ? Utils.formatDate(user.last_active_at) : 'Never'}</div>
                                <div><strong>Language:</strong> ${user.preferred_language?.toUpperCase() || 'Not set'}</div>
                                <div><strong>Total Points:</strong> ${Utils.formatNumber(totalPoints)}</div>
                            </div>
                            ${user.bio ? `
                                <div class="mt-3">
                                    <strong>Bio:</strong>
                                    <p class="text-gray-600 mt-1">${user.bio}</p>
                                </div>
                            ` : ''}
                        </div>
                    </div>
                </div>
                
                <!-- Stats Overview -->
                <div class="grid grid-cols-3 gap-4">
                    <div class="bg-blue-50 p-4 rounded-lg text-center">
                        <div class="text-2xl font-bold text-blue-600">${completedQuests.length}</div>
                        <div class="text-sm text-blue-800">Completed Quests</div>
                    </div>
                    <div class="bg-green-50 p-4 rounded-lg text-center">
                        <div class="text-2xl font-bold text-green-600">${Utils.formatNumber(totalPoints)}</div>
                        <div class="text-sm text-green-800">Total Points</div>
                    </div>
                    <div class="bg-orange-50 p-4 rounded-lg text-center">
                        <div class="text-2xl font-bold text-orange-600">${inProgressQuests.length}</div>
                        <div class="text-sm text-orange-800">In Progress</div>
                    </div>
                </div>
                
                <!-- Quest Progress -->
                <div>
                    <h4 class="font-semibold text-gray-900 mb-3">Quest Progress</h4>
                    
                    ${completedQuests.length > 0 ? `
                        <div class="mb-6">
                            <h5 class="font-medium text-green-800 mb-2">Completed Quests (${completedQuests.length})</h5>
                            <div class="space-y-2">
                                ${completedQuests.map(quest => `
                                    <div class="flex justify-between items-center p-3 bg-green-50 rounded-lg">
                                        <div>
                                            <div class="font-medium text-green-900">${quest.quests?.title || 'Unknown Quest'}</div>
                                            <div class="text-sm text-green-700">
                                                Completed ${Utils.formatDate(quest.completed_at)} • 
                                                ${quest.total_points || 0} points
                                            </div>
                                        </div>
                                        <div class="text-green-600">
                                            <i class="fas fa-check-circle text-lg"></i>
                                        </div>
                                    </div>
                                `).join('')}
                            </div>
                        </div>
                    ` : ''}
                    
                    ${inProgressQuests.length > 0 ? `
                        <div>
                            <h5 class="font-medium text-orange-800 mb-2">In Progress (${inProgressQuests.length})</h5>
                            <div class="space-y-2">
                                ${inProgressQuests.map(quest => `
                                    <div class="flex justify-between items-center p-3 bg-orange-50 rounded-lg">
                                        <div>
                                            <div class="font-medium text-orange-900">${quest.quests?.title || 'Unknown Quest'}</div>
                                            <div class="text-sm text-orange-700">
                                                Started ${Utils.formatDate(quest.started_at)} • 
                                                ${quest.current_points || 0} points so far
                                            </div>
                                        </div>
                                        <div class="text-orange-600">
                                            <i class="fas fa-clock text-lg"></i>
                                        </div>
                                    </div>
                                `).join('')}
                            </div>
                        </div>
                    ` : ''}
                    
                    ${progress.length === 0 ? `
                        <div class="text-center py-8 text-gray-500">
                            <i class="fas fa-map text-3xl mb-2"></i>
                            <p>No quest activity yet</p>
                        </div>
                    ` : ''}
                </div>
            </div>
        `;
        
        ModalManager.create('userDetailsModal', `User Details: ${user.full_name || user.email}`, content, 'xl');
        ModalManager.show('userDetailsModal');
        
    } catch (error) {
        Utils.handleError(error, 'Failed to load user details');
    }
}

// Edit user
async function editUser(userId) {
    try {
        const { data: user, error } = await supabaseClient
            .from('users')
            .select('*')
            .eq('id', userId)
            .single();
            
        if (error) throw error;
        
        const content = `
            <form id="userForm" class="space-y-4">
                <div class="grid grid-cols-2 gap-4">
                    ${UIComponents.createInput('fullName', 'Full Name', 'text', false, 'Enter full name', user.full_name || '')}
                    ${UIComponents.createInput('email', 'Email', 'email', true, 'Enter email', user.email || '')}
                </div>
                
                ${UIComponents.createSelect('role', 'Role', [
                    { value: 'user', label: 'User' },
                    { value: 'moderator', label: 'Moderator' },
                    { value: 'admin', label: 'Admin' }
                ], true, user.role || 'user')}
                
                ${UIComponents.createSelect('preferredLanguage', 'Preferred Language', [
                    { value: 'en', label: 'English' },
                    { value: 'sq', label: 'Albanian' },
                    { value: 'de', label: 'German' },
                    { value: 'fr', label: 'French' },
                    { value: 'es', label: 'Spanish' },
                    { value: 'it', label: 'Italian' }
                ], false, user.preferred_language || '')}
                
                ${UIComponents.createTextarea('bio', 'Bio', false, 'User biography', user.bio || '', 3)}
                
                <div class="bg-yellow-50 border border-yellow-200 rounded-lg p-4">
                    <div class="flex">
                        <i class="fas fa-exclamation-triangle text-yellow-600 mr-2 mt-1"></i>
                        <div class="text-sm text-yellow-800">
                            <strong>Note:</strong> Changing user roles affects their permissions in the system. 
                            Admin users have full access to all dashboard features.
                        </div>
                    </div>
                </div>
                
                <div class="flex justify-end space-x-4 pt-4">
                    <button type="button" onclick="ModalManager.close('editUserModal')" 
                            class="bg-gray-500 hover:bg-gray-600 text-white font-semibold py-2 px-4 rounded-lg">
                        Cancel
                    </button>
                    <button type="submit" 
                            class="bg-blue-600 hover:bg-blue-700 text-white font-semibold py-2 px-4 rounded-lg">
                        Update User
                    </button>
                </div>
            </form>
        `;

        ModalManager.create('editUserModal', `Edit User: ${user.full_name || user.email}`, content, 'md');
        ModalManager.show('editUserModal');

        // Set up form handler
        const form = document.getElementById('userForm');
        form.addEventListener('submit', async function(e) {
            e.preventDefault();
            await handleUserEdit(userId);
        });
        
    } catch (error) {
        Utils.handleError(error, 'Failed to load user for editing');
    }
}

async function handleUserEdit(userId) {
    const form = document.getElementById('userForm');
    const formData = new FormData(form);
    
    try {
        showLoading(true);

        // Build user data
        const userData = {
            full_name: formData.get('fullName') || null,
            email: formData.get('email'),
            role: formData.get('role'),
            preferred_language: formData.get('preferredLanguage') || null,
            bio: formData.get('bio') || null
        };

        const { error } = await supabaseClient
            .from('users')
            .update(userData)
            .eq('id', userId);

        if (error) throw error;

        Utils.showToast('User updated successfully!', 'success');
        ModalManager.close('editUserModal');
        await loadUsersData();

    } catch (error) {
        Utils.handleError(error, 'Failed to update user');
    } finally {
        showLoading(false);
    }
}

// Delete user
async function deleteUser(userId) {
    if (!confirm('Are you sure you want to delete this user? This will also delete all their quest progress. This action cannot be undone.')) {
        return;
    }
    
    try {
        showLoading(true);
        
        // First delete user quest progress
        await supabaseClient
            .from('user_quest_progress')
            .delete()
            .eq('user_id', userId);
        
        // Then delete the user
        const { error } = await supabaseClient
            .from('users')
            .delete()
            .eq('id', userId);
            
        if (error) throw error;
        
        Utils.showToast('User deleted successfully!', 'success');
        await loadUsersData();
        
    } catch (error) {
        Utils.handleError(error, 'Failed to delete user');
    } finally {
        showLoading(false);
    }
}

// Export users data
async function exportUsers() {
    try {
        const { data: users, error } = await supabaseClient
            .from('users')
            .select(`
                *,
                user_quest_progress(
                    *,
                    quests(title)
                )
            `)
            .order('created_at', { ascending: false });
            
        if (error) throw error;
        
        const exportData = {
            exported_at: new Date().toISOString(),
            users: users.map(user => ({
                ...user,
                // Remove sensitive data
                id: undefined
            }))
        };
        
        const blob = new Blob([JSON.stringify(exportData, null, 2)], { type: 'application/json' });
        const url = URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = `users_export_${new Date().toISOString().split('T')[0]}.json`;
        document.body.appendChild(a);
        a.click();
        document.body.removeChild(a);
        URL.revokeObjectURL(url);
        
        Utils.showToast('Users data exported successfully!', 'success');
        
    } catch (error) {
        Utils.handleError(error, 'Failed to export users data');
    }
}

// Send notification to user
async function sendNotificationToUser(userId, message) {
    try {
        showLoading(true);
        
        // Insert notification into the database
        const notificationData = {
            user_id: userId,
            message: message,
            created_at: new Date().toISOString(),
            is_read: false,
            type: 'admin_message'
        };
        
        const { error } = await supabaseClient
            .from('notifications')
            .insert([notificationData]);
            
        if (error) {
            // If notifications table doesn't exist, show a helpful message
            if (error.code === '42P01') {
                Utils.showToast('Notifications table not found. Create the notifications table in your database first.', 'warning');
                return;
            }
            throw error;
        }
        
        Utils.showToast('Notification sent successfully!', 'success');
        
    } catch (error) {
        Utils.handleError(error, 'Failed to send notification');
    } finally {
        showLoading(false);
    }
}

// Ban/unban user
async function toggleUserBan(userId, isBanned) {
    try {
        showLoading(true);
        
        const action = isBanned ? 'banned' : 'unbanned';
        
        // Update user's banned status
        const { error } = await supabaseClient
            .from('users')
            .update({ 
                is_banned: isBanned,
                banned_at: isBanned ? new Date().toISOString() : null,
                banned_reason: isBanned ? 'Banned by administrator' : null
            })
            .eq('id', userId);
            
        if (error) {
            // If is_banned column doesn't exist, show a helpful message
            if (error.code === '42703') {
                Utils.showToast('User ban fields not found. Add is_banned, banned_at, and banned_reason columns to your users table.', 'warning');
                return;
            }
            throw error;
        }
        
        // Send notification to user about ban status change
        const message = isBanned 
            ? 'Your account has been suspended by an administrator.' 
            : 'Your account suspension has been lifted.';
            
        try {
            await sendNotificationToUser(userId, message);
        } catch (notifError) {
            console.warn('Failed to send ban notification:', notifError);
        }
        
        Utils.showToast(`User ${action} successfully!`, 'success');
        await loadUsersData(); // Refresh user list
        
    } catch (error) {
        Utils.handleError(error, `Failed to ${isBanned ? 'ban' : 'unban'} user`);
    } finally {
        showLoading(false);
    }
}

// Make functions globally available
window.Users = {
    loadUsersData,
    createUserCard,
    viewUserDetails,
    editUser,
    deleteUser,
    exportUsers,
    sendNotificationToUser,
    toggleUserBan
};

// Make individual functions globally available for onclick handlers
window.loadUsersData = loadUsersData;
window.viewUserDetails = viewUserDetails;
window.editUser = editUser;
window.deleteUser = deleteUser;
window.exportUsers = exportUsers;
window.sendNotificationToUser = sendNotificationToUser;
window.toggleUserBan = toggleUserBan;