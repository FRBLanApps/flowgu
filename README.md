# Flowgu Flutter Template

一个 Flutter 应用框架模板。当前 UI 和交互入口已经接好，题库、比赛、用户资料等只读数据源已开始接入洛谷真实接口，mock repository 仍保留用于离线开发和测试。

## 目录结构

```text
lib/
  main.dart
  app/
    app.dart
    routes/
    theme/
  core/
    config/
    constants/
    errors/
    network/
    services/
    utils/
  features/
    home/
      data/
      domain/
      presentation/
    problems/
      data/
      domain/
      presentation/
    contests/
      data/
      domain/
      presentation/
    records/
      data/
      domain/
      presentation/
    profile/
      data/
      domain/
      presentation/
  shared/
    pages/
    widgets/
assets/
  fonts/
  icons/
  images/
test/
```

## 使用

如果当前目录还没有 Flutter 平台文件，先执行：

```bash
flutter create .
```

然后运行：

```bash
flutter pub get
flutter run
```

## 真实接口接入

- 接口基地址：`https://www.luogu.com.cn`。
- `core/network/api_client.dart` 统一处理请求头、`_contentOnly`、`x-luogu-type`、`x-lentille-request` 和 JSON 解包。
- `features/*/data/luogu_*_repository.dart` 负责把洛谷返回映射到页面模型。
- 已接入：题库列表 `/problem/list`、比赛列表 `/contest/list`、用户资料 `/user/:uid`。
- 题库列表会优先读取真实洛谷接口；如果 Flutter Web 被 CORS 拦截，会自动使用内置题库种子数据，保证题目页面可以加载。
- 题库支持关键词、难度、算法标签和多种排序方式。
- 标签目录来自洛谷 `/_lfe/tags/zh-CN`，包含区域、算法、来源、时间、特殊题目和其他全部标签，并在题库里用可搜索底部面板展示。
- 题目详情会拉取 `/problem/:pid`，在 App 内展示题面 Markdown、输入输出格式、样例和提示。
- 比赛页包含洛谷官方赛、个人公开赛和 AtCoder；AtCoder 会尝试解析公开比赛页，失败时使用内置近期比赛数据。
- 我的页面支持连接洛谷和 AtCoder 账号的登录框架；当前不持久化密码或 Cookie。
- 评测列表 `/record/list` 已预留真实 repository，但未登录访问会跳转登录页，当前会显示“需要登录后才能访问”。
- Flutter Web 不能绕过浏览器 CORS 直接读取洛谷跨域响应；这是浏览器安全限制。移动端和桌面端会直接使用真实接口。

## 架构说明

- `app/`：应用入口、主题、命名路由和动态路由。
- `core/`：跨模块配置、API 客户端、异常和通用工具。
- `features/*/domain/`：业务模型和 repository 抽象。
- `features/*/data/`：数据源实现；默认使用 `luogu_*_repository.dart`，mock 实现可用于测试。
- `features/*/presentation/controllers/`：页面状态和交互逻辑。
- `features/*/presentation/pages/`：页面 UI。
- `shared/`：跨页面复用的占位页、空状态、状态标签、Snackbar 等组件。
