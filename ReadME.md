# 🚀 Service Manager

A professional service management platform featuring dual-mode operation for scripts and applications, with a modern GUI design and comprehensive functionality.

## 🎯 Features

- Script and Application Management
- Modern GUI Interface
- Automated Setup Wizard
- Real-time Service Monitoring
- Category Organization
- Bulk Operations Support
- Advanced Validation
- Professional Settings System

## 🗂️ File Structure

```
ServiceManager/
├── ServiceManager.ps1              # Main application
├── ServiceManager-PSADMIN-setup.ps1 # Setup wizard
├── init.app_settings.json          # Default settings
├── init.scripts_storage.json       # Default configuration
├── start/                         # Start scripts folder
├── stop/                          # Stop scripts folder
├── templates/                     # Script templates
└── user_config/                   # User configuration (created by setup)
```

## 🚀 Quick Start

1. **Setup:**

   ```powershell
   # Run as Administrator
   .\ServiceManager-PSADMIN-setup.ps1
   ```

2. **Alternative Setup:**
   ```powershell
   .\ServiceManager.ps1
   # Will run setup wizard if no configuration exists
   ```

## 📋 Configuration

- **Default Configuration** (in repository):

  - `init.app_settings.json` - Default settings
  - `init.scripts_storage.json` - Default service configuration

- **User Configuration** (created during setup):
  - `user_config/app_settings.json` - Personalized settings
  - `user_config/scripts_storage.json` - Configured services

## 🔒 Requirements

- Windows PowerShell 5.1 or later
- Administrator privileges for setup
- .NET Framework 4.5 or later

## 🎮 Usage

1. **Add New Service:**

   - Click "Add Script/App"
   - Choose Script or Application mode
   - Configure service settings
   - Save and validate

2. **Manage Services:**

   - Start/Stop individual services
   - Use bulk operations
   - Monitor service status
   - Organize by categories

3. **Settings:**
   - Configure application paths
   - Manage service locations
   - Customize application behavior
   - Export/backup configurations

## 🔧 Technical Details

- Built with Windows Forms and PowerShell
- Modern UI with professional theming
- Real-time validation and monitoring
- Comprehensive error handling
- Modular, maintainable codebase

## 📝 Version

Current Version: 2.0
