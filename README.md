<div align="center">

# 🌊 Flowgu (Fl-洛谷)

**一款追求极致美学与现代感的洛谷第三方 Flutter 客户端**

*Fluid. Frosted. Future.* 

[![Flutter](https://img.shields.io/badge/Flutter-3.29-02569B?logo=flutter)](https://flutter.dev)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Linux%20%7C%20Windows%20%7C%20Android-lightgrey.svg)]()

<img width="2558" height="1597" alt="运行截图" src="https://github.com/user-attachments/assets/a7736c8b-0e3e-46d6-8018-fc0e6c3f930f" />


</div>

## ✨ 核心特性 / Features

Flowgu 的核心设计理念是 **“极简主义”** 与 **“动态丝滑体验”**。我们摒弃了传统 Material 呆板的纯色块，带来了完全可定制的视觉享受。

* 🎨 **标志性视觉语言**: 采用令人愉悦的 `#66CCFF` 天依蓝（我**绝对不会告诉你**这是我夹带的私货）为主色调，搭配 `GoogleFonts` 构建的现代字体排版系统。
* 📐 **流动的形状**: 随心所欲的 UI 倒角定制功能。从冷峻的直角 (`Sharp`) 到圆润的胶囊 (`Pill`)，所有列表、按钮及应用条都将随之联动变形。
* 🌌 **高性能动态背景**: 内置 12 款动态动画背景皮肤。采用 `ValueNotifier` 与 `RepaintBoundary` 进行隔离渲染，彻底告别后台重绘导致的主线程卡顿，即使在复杂的动效下也能保持 60fps 的桌面级纵享丝滑。
* ⚡ **原生体验支持**: 针对多平台深度适配（已针对 Linux 添加原生的 `FadeUpwards` 页面跳转过渡），兼顾操作体验与性能表现。

## 🛠 构建与运行 / Getting Started

本项目基于 **Flutter 3.29 SDK** 开发，支持如 Windows、Linux 及移动端等多端编译。

### 环境要求
* Flutter SDK (>= 3.29.0)
* Dart SDK

### 运行步骤
1. 克隆代码到本地：
   ```bash
   git clone https://github.com/FRBLanApps/flowgu.git
   cd flowgu
   ```
2. 拉取依赖：
   ```bash
   flutter pub get
   ```
3. 运行调试（例如在 Linux 平台）：
   ```bash
   flutter run -d linux
   ```
   *注意：如果需要通过 Web 开发环境构建并反向代理洛谷 API（解决跨域），可以在运行时通过传递参数运行（例：`--dart-define=LUOGU_PROXY_BASE_URL=http://localhost:8787/luogu`）。*

## 🧬 技术架构 / Architecture

* **UI 引擎**: Flutter Material 3 深度定制
* **主题混入**: 单例 `AppThemeController` 借助根节点的 `AnimatedBuilder` 实现全局无刷新主题（圆角、卡片风格、玻璃参数）热更新。
* **背景节流**: 使用 `PointerEvent` 控制器与严格限制的 BackdropFilter 模糊散列相结合，解决 hover 状态和重模糊带来的大量性能开销。

## 🤝 贡献 / Contributing

欢迎提交 Issue 和 PR 共同完善这系列现代化的洛谷社区体验。

**Author:** [tyLingyu](https://github.com/tyLingyu)

---

> **免责声明 (Disclaimer)**: 本项目为洛谷（Luogu）用户的第三方开源客户端实现，仅供学习、交流与界面设计探讨。本项目与洛谷官方（luogu.com.cn）无任何关联或附属关系。
