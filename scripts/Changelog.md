### 🚀 What's New

- **Improved Startup with Administrator Privileges**: Fixed an issue where the application could not launch on system startup if it was configured to require **administrator privileges**.
  - Root cause: Applications that require elevation cannot be reliably auto-started via standard **registry-based startup entries**.
  - Solution: The app now registers a **Windows Scheduled Task** that triggers on user logon and launches the application with elevated privileges.
  - Requirement: To enable startup at login, the application itself must now be launched **as Administrator** so it can create the scheduled task.

### 🧹 Maintenance

- **Dependency Cleanup**: Removed unused dependencies to reduce binary size and streamline maintenance.
