# WeReadMacElink

一个面向外接墨水屏的本地 macOS 微信读书阅读外壳，重点解决官方 iPad 版本在 Mac 外接墨水屏上字号偏小、对比度不足、动画过多和正文栏过窄的问题。

应用使用微信读书官方网页完成登录、内容展示和进度同步，只在本地调整显示效果。它不会提取登录凭证、拦截接口、解密、下载或保存书籍正文。

## 功能

- 字号使用 WebKit（苹果网页引擎）页面缩放，支持 100%–200%，能够触发网页重新排版。
- 对比度同时调整灰阶、文字墨色和笔画粗细，支持 100%–200%。
- 上下滚动阅读模式可将正文宽度调整为窗口的 60%–95%。
- 上下滚动模式的网页工具栏会自动移到正文右侧，不遮挡文字。
- 选中文字使用适合墨水屏的黑底白字高亮。
- 可关闭网页动画和滚动动画，减少墨水屏残影。
- 自动识别窗口所在显示器并显示其名称。
- 支持 `⌘K` 打开原生电子书搜索，并使用微信读书返回的官方链接跳转。
- 字号、对比度、正文宽度等设置自动保存在本机。
- 非微信读书域名的链接交由系统默认浏览器打开。

## 系统要求

- macOS 13 或更高版本。
- Xcode 及 Swift 6 工具链。
- 网络连接和可正常使用的微信读书账号。

## 构建与运行

搜索功能需要先设置微信读书 Agent API（智能体接口）密钥：

```bash
export WEREAD_API_KEY=<你的apikey>
```

应用只从环境变量读取密钥，不会把密钥写入仓库、网页脚本或偏好设置。

```bash
swift test
./scripts/build-app.sh
open dist/WeReadMacElink.app
```

构建脚本会生成并进行本地临时签名：

```text
dist/WeReadMacElink.app
```

## 快捷键

- `←` / `→`：上一页 / 下一页。
- `⌘+` / `⌘-`：增大 / 减小字号。

## 项目结构

```text
Sources/WeReadMacElink/
├── ContentView.swift        原生控制栏
├── EInkProfile.swift        墨水屏参数边界
├── EInkStyle.swift          网页样式和翻页脚本
├── ReaderNavigator.swift    页面导航
├── ReaderSettings.swift     设置持久化
├── ReaderWebView.swift      WebKit 容器与域名限制
├── WeReadAPIClient.swift    微信读书智能体接口客户端
├── WeReadAssistant.swift    原生搜索面板
└── WeReadMacElinkApp.swift  应用入口
```

## 隐私和使用边界

- 登录会话由 WebKit 默认数据存储管理，项目代码不会读取或上传 Cookie（网站登录凭证）。
- 项目不调用微信读书私有正文接口，也不导出受版权保护的内容。
- 项目仅调整用户本机上的页面显示效果。
- 请遵守微信读书用户协议及适用法律。

## 当前限制

- 页面样式依赖微信读书网页版当前的容器类名；官网改版后可能需要同步更新 `EInkStyle.swift`。
- 当前仅针对 macOS 和外接墨水屏进行设计与验证。
- 本项目与腾讯或微信读书没有隶属、授权或合作关系。
