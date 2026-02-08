### 🚀 What's New

- **Startup Launch**: Added support for launching the application on system startup. This option is **disabled by default**, giving users full control over whether the app runs automatically after boot.

### ✨ Enhancements

- **Cursor Feedback**: The mouse cursor now changes to a **clickable indicator** when hovering over interactive areas of the interface, making available actions clearer and improving overall usability.

### 🐞 Bug Fixes

- **UI Rendering**: Fixed rendering issues with the **color preview circle**, **alpha slider**, and **window corner anti-aliasing**, ensuring smoother visuals and more accurate color representation.
- **Topmost Reliability**: Resolved an issue where setting or clearing "Always on Top" could fail when the target window was **not in an active state**.
- **Focus Restoration**: After removing "Always on Top" from a window, the application now brings the **current foreground window back to the front**, reducing visual disruption and improving user experience.

### 🧹 Maintenance

- **Dependency Cleanup**: Removed unused dependencies to reduce binary size and simplify maintenance.
