# UrbanQuest Admin Dashboard

## Recent Fixes Applied

### JavaScript Issues Fixed
1. **Modal Manager Conflict**: Removed duplicate `ModalManager` class definition that was causing conflicts
2. **Missing Modals Reference**: Fixed undefined `Modals` references throughout the codebase
3. **Database Insert Issues**: Fixed quest stop duplication by properly excluding auto-generated fields
4. **Function References**: Updated all modal function calls to use the correct naming convention

### Files Modified
- `js/modals.js` - Removed duplicate ModalManager class, kept only quest stop modal functionality
- `js/quest-stops.js` - Fixed function references and database duplication logic
- `js/app.js` - Updated event listeners to use correct function names
- `js/ui-components.js` - Added support for additional input attributes
- `index.html` - Added development note for Tailwind CSS
- `css/styles.css` - Created essential CSS file for production readiness

## Dashboard Features

### Overview Tab
- Real-time statistics (quests, users, cities, completions)
- Recent activity feed
- Challenge type distribution

### Quests Management
- Create, edit, duplicate, and delete quests
- Preview quest details and stops
- Export quest data
- Filter by city and category

### Quest Stops Management
- Interactive map for location selection
- Different challenge types (text, multiple choice, photo, QR code, etc.)
- Drag-and-drop reordering
- Duplicate stops for quick creation

### Cities Management
- Add cities with coordinates
- View quests per city
- Interactive city maps with quest stops
- Population and timezone information

### Categories Management
- Organize quests by themes
- Color-coded categories
- Target audience and difficulty settings
- Tag management

### Users Management
- View user profiles and progress
- Edit user roles and permissions
- Track quest completions and points
- Export user data

### Analytics
- User engagement metrics
- Quest performance data
- Challenge type popularity
- Completion time analysis

## Getting Started

1. **Login**: Use admin credentials to access the dashboard
2. **Setup Cities**: Add cities where your quests will take place
3. **Create Categories**: Organize your quests by themes
4. **Build Quests**: Create quests with multiple stops and challenges
5. **Manage Users**: Monitor user activity and progress

## Development Notes

### Production Deployment
- Replace Tailwind CDN with proper build process
- Set up environment variables for Supabase credentials
- Configure proper error logging and monitoring
- Set up automated backups for user data

### Database Schema
The dashboard expects these main tables:
- `cities` - City information and coordinates
- `quest_categories` - Quest categorization
- `quests` - Main quest data
- `quest_stops` - Individual quest locations and challenges
- `profiles` - User profiles and roles
- `user_quest_progress` - User progress tracking

### Security Considerations
- Role-based access control implemented
- Input validation on all forms
- SQL injection protection via Supabase
- XSS protection through proper escaping

## Troubleshooting

### Common Issues
1. **Map not loading**: Check Leaflet CDN and internet connection
2. **Database errors**: Verify Supabase credentials and table schema
3. **Modal not opening**: Ensure ModalManager is properly initialized
4. **Location selection**: Click directly on map to select quest stop locations

### Error Handling
- All errors are logged to browser console
- User-friendly toast notifications for feedback
- Graceful degradation when services are unavailable

## API Integration

The dashboard integrates with:
- **Supabase**: Database and authentication
- **Leaflet**: Interactive maps
- **Font Awesome**: Icons
- **Tailwind CSS**: Styling framework

## Support

For technical issues:
1. Check browser console for detailed error messages
2. Verify database connection and table schemas
3. Ensure all required environment variables are set
4. Check network connectivity for external APIs 