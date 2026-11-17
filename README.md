# MyApp

用 [Tuist](https://tuist.io) 搭建的 **iOS SwiftUI 练习项目**：把一段写死的 Markdown 解析成 `NSAttributedString`，在界面上逐字打出，并把图片拆出来用 `AsyncImage` 显示。

仓库描述与代码一致，这是练习，不是可发布的产品。当前只有一个示例界面和一个占位单元测试，没有账号、网络接口或可配置的文档源。

[![Platform](https://img.shields.io/badge/platform-iOS-111111)](https://developer.apple.com/ios/)
[![UI](https://img.shields.io/badge/UI-SwiftUI-0A84FF)](https://developer.apple.com/xcode/swiftui/)
[![Tuist](https://img.shields.io/badge/Tuist-4.38.2-5B45FF)](https://docs.tuist.dev)
[![Swift tools](https://img.shields.io/badge/Swift_tools-6.0-F05138?logo=swift&logoColor=white)](https://www.swift.org)

## 这个练习在做什么

`ContentView` 里有一份中文 Markdown 示例。界面出现后，以 **每字 0.05 秒** 追加到 `currentText`，再交给 `MarkdownView`：

1. 用 `Markdown.Document` 解析当前文本。
2. 用 `Markdownosaur`（`MarkupVisitor`）转成带字体、颜色、链接的 `NSAttributedString`。
3. 若属性串里没有图片，直接用可选中的 `Text` 显示。
4. 若有图片，按图片位置把纯文本切开，文字和 `AsyncImage` 上下排列。图片加载中显示 `ProgressView`，失败显示灰色 `photo.fill`。

示例字符串里出现了这些写法：标题、粗体 / 斜体 / 粗斜体、删除线、行内代码、链接、引用、有序与无序列表、围栏代码块、表格、任务列表、分割线、远程图片、数学公式。

渲染器**单独实现**了下面这些节点（`MarkDownOsuar.swift` 的访问器，以及 `ContentView.swift` 里对图片、表格的扩展）：

| 节点 | 实际表现 |
| --- | --- |
| 标题 | 按级别加粗并放大（约 28pt 起，每深一级减 2pt） |
| 粗体、斜体、删除线 | 在原字体上叠加字重、斜体或删除线 |
| 链接 | 系统蓝色，并带上 URL |
| 行内代码、代码块 | 等宽字体，系统灰色 |
| 有序 / 无序列表、引用 | 用制表位缩进；嵌套深度来自父节点 |
| 图片 | 自定义属性 `MarkdownImage`，再交给 `AsyncImage`，最高 200pt |
| 表格 | 单元格用 ` \| ` 拼成文本；首行加粗并铺 `systemGray6`，下面加一行 `-` |

其余节点走 `defaultVisit`，只递归子节点。因此示例里的分割线、任务列表复选框、`$...$` / `$$...$$` 数学公式**没有专门样式**：分割线这类没有子节点的叶子不会画出横线，公式会按普通文本出现。

图片示例的地址是 `https://markdown-here.com/img/icon256.png`，显示它需要设备能访问该 URL。一旦解析出图片，文字段会用纯字符串重建 `AttributedString`，这一段上的粗体、颜色等属性不会保留。

## 目录

```text
.
├── .mise.toml              # 锁定 Tuist 4.38.2
├── Project.swift           # App 与单元测试两个 target
├── Tuist.swift             # Tuist 配置；Cloud 项目句柄仍是注释
├── Tuist/
│   └── Package.swift       # SwiftPM 清单，tools 版本 6.0，依赖列表为空
└── MyApp/
    ├── Sources/
    │   ├── MyAppApp.swift       # @main，窗口里放 ContentView
    │   ├── ContentView.swift    # 示例文案、逐字动画、图片与表格
    │   └── MarkDownOsuar.swift  # Markdown → NSAttributedString
    ├── Tests/
    │   └── MyAppTests.swift     # 占位测试：2 + 2 == 4
    └── Resources/
        ├── Assets.xcassets      # AppIcon、AccentColor 槽位，没有图片和色值
        └── Preview Content/     # SwiftUI Preview 资源目录，内容为空
```

工程清单里的两个 target：

| Target | 产物 | Bundle ID |
| --- | --- | --- |
| `MyApp` | iOS App | `io.tuist.MyApp` |
| `MyAppTests` | 单元测试，依赖 `MyApp` | `io.tuist.MyAppTests` |

`destinations` 只有 `.iOS`。`Project.swift` 没有设置 `deploymentTargets`，最低系统版本以 `tuist generate` 之后 Xcode 工程里的默认为准。启动屏的 `UILaunchScreen` 颜色名和图片名都是空字符串。

`MyAppTests` 不导入界面，也不解析 Markdown。

## 技术栈

| 项 | 仓库里的事实 |
| --- | --- |
| 工程生成 | Tuist **4.38.2**（`.mise.toml`） |
| 界面 | SwiftUI（`MyAppApp`、`ContentView`） |
| 富文本 | UIKit 的 `NSAttributedString` / `UIFont` |
| Markdown 解析 | 源码 `import Markdown`，类型为 `Document`、`MarkupVisitor`、`Markdown.Image`、`Markdown.Table`，对应 Apple 的 [swift-markdown](https://github.com/apple/swift-markdown) |
| 依赖声明 | `Tuist/Package.swift` 的 `dependencies` **是空的**，没有把 `swift-markdown` 写进去 |
| 包清单工具版本 | `// swift-tools-version: 6.0` |
| 渲染器来源 | `MarkDownOsuar.swift` 文件头注明改编自 Christian Selig 的 [Markdownosaur](https://github.com/christianselig/Markdownosaur)（2021-11-02）。本仓库文件名是 `MarkDownOsuar.swift`，类型名仍是 `Markdownosaur` |

## 环境要求

- **macOS**，并安装与 Swift tools 6.0 匹配的 **Xcode**（含 iOS Simulator）。本仓库的目标平台是 iOS，不能在 Linux 上编译或运行。
- [mise](https://mise.jdx.dev)（或自行安装同一版本的 Tuist），用来安装 `.mise.toml` 锁定的 Tuist 4.38.2。
- 生成物 `*.xcodeproj`、`*.xcworkspace` 已在 `.gitignore` 中，需要在本机生成，不会随仓库提交。

## 安装与运行

在仓库根目录：

```bash
mise install
tuist install
tuist generate
```

然后在 Xcode 中打开生成的工程，选择 **MyApp** scheme，用一台 iOS 模拟器运行。没有外部包时，Tuist 通常生成 `MyApp.xcodeproj`；若同时生成了 workspace，打开 workspace。

单元测试在 Xcode 里对 **MyAppTests** 执行 Test。目前只有 `test_twoPlusTwo_isFour`。

`Tuist.swift` 里的 `fullHandle` 仍被注释。不需要执行 `tuist auth` 或 `tuist project create` 也能生成本地工程。

### 当前编译不过的原因

源文件引用了 `Markdown` 模块，但 `Tuist/Package.swift` 没有声明对应的包。按上面的命令生成工程后，编译会在 `import Markdown` 处失败，直到把 [swift-markdown](https://github.com/apple/swift-markdown) 加进该清单并重新 `tuist install`。本次只更新文档，没有改工程或补依赖。

### 验证情况

已在当前环境核对：系统是 Ubuntu 24.04，`swift`、`xcodebuild`、`tuist`、`mise` 均不存在，因此 **没有** 执行 `tuist generate`，也没有编译或跑测试。上面的命令对应仓库里的 Tuist 清单；能否跑通还取决于本机 Xcode，以及是否补上 `Markdown` 包。

## 备注

- 仓库里没有截图或 App 图标位图，所以这里不放界面图。
- 没有许可证文件。
- `graph.dot`、`Derived/`、`Tuist/.build` 是 Tuist 生成物，已忽略。
