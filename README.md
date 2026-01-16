# 🐶 DogEar

[![Flutter](https://img.shields.io/badge/Flutter-Windows-blue.svg)](https://flutter.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](https://opensource.org/licenses/MIT)

**DogEar** is a high-performance Windows desktop overlay application built with Flutter. 

It leverages `dart:ffi` to interact directly with low-level Windows APIs (`user32.dll`, `gdi32.dll`), breaking the limits of standard rectangular windows to achieve **custom polygonal shapes (triangle/dog-ear)**, pixel-perfect transparency, and native window management.

---

## ✨ Key Features

* **📐 Custom Shaped Window**
    * Physical window clipping using GDI32 `CreatePolygonRgn` and `SetWindowRgn`.
    * Supports complex geometries (like triangles); mouse events pass through non-shape areas.
* **🚀 Optimized FFI Bridge**
    * Uses `static final` for pre-loading DLLs to minimize runtime overhead.
    * Strict manual memory management for pointers and native handles (zero GC pressure).
* **🎨 Native Rendering Control**
    * Pixel-level transparency via `SetLayeredWindowAttributes`.
    * Flicker-free updates using targeted `Redraw` and `UpdateWindow` strategies.
* **🛡️ Robust Resource Management**
    * Built-in lifecycle management for GDI objects (Regions, Brushes) to prevent memory leaks.

## 🛠️ Project Structure

This project follows a **Layered Architecture** to decouple Win32 API complexities from Flutter business logic.

* `lib/native/`: FFI bindings, function mappings, and Win32 constants.
* `lib/overlay/`: Business logic for window shapes, positioning, and sync.
* `lib/main.dart`: Entry point and UI orchestration.

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

2.  **Run in Debug mode**
    ```bash
    flutter run -d windows
    ```

3.  **Build Release version**
    ```bash
    flutter build windows
    ```
