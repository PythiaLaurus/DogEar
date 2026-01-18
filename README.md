# 🐶 DogEar

[![Flutter](https://img.shields.io/badge/Flutter-Windows-blue.svg)](https://flutter.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](https://opensource.org/licenses/MIT)

**DogEar reimagines** how you manage a cluttered workspace by bringing the physical intuition of "book-folding" to the Windows desktop. It transforms your multi-window workflow by allowing you to fold a corner of any application—creating a visual **"DogEar" bookmark** that stays pinned to your target window, ensuring you never lose track of your active tasks again.

**Why DogEar?** In a sea of dozens of open windows, traditional taskbars and tab-switchers often fall short. DogEar provides a **persistent visual anchor** for your most important work. Whether you are tracking a critical document, locking a reference image, or managing complex multitasking, DogEar ensures your prioritized windows are instantly identifiable and always accessible.

---

## ✨ Key Features

* **📐 Intuitive Tagging**
    * Instantly "dog-ear" any active window with a customizable keyboard shortcut.
* **🎨 Zero-Interference Overlay**
    * Achieves pixel-perfect transparency and custom polygonal shapes (triangles) that stay on top without stealing focus or blocking your content.
* **🚀 Native Integration**
    * Leverages high-performance Win32 hooks to ensure markers follow their target windows flawlessly across the screen.
    * Built with Flutter and dart:ffi for a seamless, native experience that respects your system resources.

**Note on Permissions:** To "dog-ear" windows running with Administrator privileges (e.g., Task Manager or elevated Command Prompts), **DogEar** itself must be launched with **Administrator privileges** due to Windows UIPI security constraints.

## 🚀 Getting Started

### Prerequisites
* Windows 10/11
* Flutter SDK (Stable channel)
* Visual Studio 2019+ (with "Desktop development with C++" workload)

### Build & Run

1.  **Fetch dependencies**
    ```bash
    flutter pub get
    ```

2.  **Generate files**
    ```bash
    dart run build_runner build
    ```

3.  **Run in Debug mode**
    ```bash
    flutter run -d windows
    ```

4.  **Build Release version**
    ```bash
    flutter build windows
    ```
