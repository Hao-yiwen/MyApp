import SwiftUI
import Markdown

// Custom image loading view
struct AsyncImageView: View {
    let url: URL
    
    var body: some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .empty:
                ProgressView()
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 200)
            case .failure:
                Image(systemName: "photo.fill")
                    .foregroundColor(.gray)
            @unknown default:
                EmptyView()
            }
        }
    }
}

// Custom text view to handle image inline with text
struct CustomTextView: View {
    let content: AttributedString
    let imageUrls: [(range: Range<String.Index>, url: URL)]
    let plainText: String
    
    var body: some View {
        buildTextWithImages()
    }
    
    @ViewBuilder
    private func buildTextWithImages() -> some View {
        if imageUrls.isEmpty {
            Text(content)
                .textSelection(.enabled)
        } else {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(0..<splitContent().count, id: \.self) { index in
                    let part = splitContent()[index]
                    if let url = part.imageUrl {
                        AsyncImageView(url: url)
                            .padding(.vertical, 4)
                    } else {
                        Text(AttributedString(part.text))
                            .textSelection(.enabled)
                    }
                }
            }
        }
    }
    
    private struct ContentPart {
        let text: String
        let imageUrl: URL?
    }
    
    private func splitContent() -> [ContentPart] {
        var parts: [ContentPart] = []
        var currentIndex = plainText.startIndex
        
        for (range, url) in imageUrls.sorted(by: { $0.range.lowerBound < $1.range.lowerBound }) {
            if currentIndex < range.lowerBound {
                let textPart = String(plainText[currentIndex..<range.lowerBound])
                parts.append(ContentPart(text: textPart, imageUrl: nil))
            }
            parts.append(ContentPart(text: String(plainText[range]), imageUrl: url))
            currentIndex = range.upperBound
        }
        
        if currentIndex < plainText.endIndex {
            let textPart = String(plainText[currentIndex..<plainText.endIndex])
            parts.append(ContentPart(text: textPart, imageUrl: nil))
        }
        
        return parts
    }
}

struct MarkdownView: View {
    let markdown: String
    @Binding var currentText: String
    
    private func attributedText(from markdown: String) -> NSAttributedString {
        let document = Document(parsing: markdown)
        var markdownosaur = Markdownosaur()
        return markdownosaur.attributedString(from: document)
    }
    
    private func processText(_ text: NSAttributedString) -> (AttributedString, String, [(Range<String.Index>, URL)]) {
        let content = AttributedString(text)
        let plainText = text.string
        var imageUrls: [(Range<String.Index>, URL)] = []
        
        text.enumerateAttribute(.markdownImage, in: NSRange(location: 0, length: text.length)) { value, range, _ in
            if let url = value as? URL {
                // Convert NSRange to String Range safely
                if let stringRange = Range(range, in: plainText) {
                    imageUrls.append((stringRange, url))
                }
            }
        }
        
        return (content, plainText, imageUrls)
    }
    
    var body: some View {
        let attributedText = attributedText(from: currentText)
        let (content, plainText, imageUrls) = processText(attributedText)
        
        ScrollView {
            CustomTextView(content: content, imageUrls: imageUrls, plainText: plainText)
                .padding()
        }
    }
}

// Extension for custom NSAttributedString key
extension NSAttributedString.Key {
    static let markdownImage = NSAttributedString.Key("MarkdownImage")
}

// Extend Markdownosaur to handle images and tables
extension Markdownosaur {
    mutating public func visitImage(_ image: Markdown.Image) -> NSAttributedString {
        let result = NSMutableAttributedString(string: image.plainText)
        
        if let source = image.source, let url = URL(string: source) {
            result.addAttribute(.markdownImage, value: url, range: NSRange(location: 0, length: result.length))
        }
        
        return result
    }
    
    mutating public func visitTable(_ table: Markdown.Table) -> NSAttributedString {
        let result = NSMutableAttributedString()
        var isFirstRow = true
        
        for child in table.children {
            if let row = child as? Markdown.Table.Row {
                // Process each cell in the row
                for cell in row.children {
                    let cellContent = NSMutableAttributedString()
                    cellContent.append(NSAttributedString(string: " "))
                    
                    // Visit cell content
                    for cellChild in cell.children {
                        cellContent.append(visit(cellChild))
                    }
                    
                    cellContent.append(NSAttributedString(string: " | "))
                    
                    // Apply cell styling
                    let fullRange = NSRange(location: 0, length: cellContent.length)
                    
                    // Apply different styles for header cells
                    if isFirstRow {
                        cellContent.addAttributes([
                            .font: UIFont.boldSystemFont(ofSize: baseFontSize),
                            .backgroundColor: UIColor.systemGray6
                        ], range: fullRange)
                    } else {
                        cellContent.addAttributes([
                            .font: UIFont.systemFont(ofSize: baseFontSize)
                        ], range: fullRange)
                    }
                    
                    result.append(cellContent)
                }
                
                // Add newline after each row
                result.append(.singleNewline(withFontSize: baseFontSize))
                
                // Add separator line after header
                if isFirstRow {
                    let separator = String(repeating: "-", count: result.string.components(separatedBy: "\n").last?.count ?? 20)
                    let separatorAttr = NSAttributedString(string: separator + "\n", attributes: [
                        .font: UIFont.systemFont(ofSize: baseFontSize)
                    ])
                    result.append(separatorAttr)
                    isFirstRow = false
                }
            }
        }
        
        // Add spacing after table
        if table.hasSuccessor {
            result.append(.doubleNewline(withFontSize: baseFontSize))
        }
        
        return result
    }
}



struct ContentView: View {
    let markdownText = """
    # Markdown 完整示例展示

    ## 1. 基础文本格式

    这是一段普通文本，包含**粗体**、*斜体*和***粗斜体***。
    还可以使用~~删除线~~和`行内代码`。

    ## 2. 链接与引用

    [访问 GitHub](https://github.com)

    > 这是一段引用文本
    > 多行引用效果
    >> 嵌套引用示例

    ## 3. 列表展示

    ### 无序列表：
    - 苹果 🍎
        - 红富士
        - 青苹果
    - 香蕉 🍌
    - 橙子 🍊

    ### 有序列表：
    1. 第一步
    2. 第二步
        1. 子步骤 1
        2. 子步骤 2
    3. 第三步

    ## 4. 代码展示

    ```swift
    func hello() {
        print("Hello, Markdown!")
    }
    ```

    ## 5. 表格示例

    | 功能 | 基础版 | 专业版 | 企业版 |
    |------|--------|--------|--------|
    | 在线编辑 | ✅ | ✅ | ✅ |
    | 历史记录 | ❌ | ✅ | ✅ |
    | 团队协作 | ❌ | ❌ | ✅ |
    | 价格/月 | $0 | $9.9 | $29.9 |

    ## 6. 任务列表

    - [x] 已完成任务
    - [ ] 待办任务
    - [ ] 进行中的任务

    ## 7. 分割线

    ---

    ## 8. 图片示例
    ![Markdown Logo](https://markdown-here.com/img/icon256.png)

    ## 9. 数学公式
    当 $a \\ne 0$ 时，一元二次方程 $ax^2 + bx + c = 0$ 的解为：
    $$ x = {-b \\pm \\sqrt{b^2-4ac} \\over 2a} $$
    """
    
    @State private var currentText = ""
    @State private var shouldAnimate = true
    
    var body: some View {
        MarkdownView(markdown: markdownText, currentText: $currentText)
            .onAppear {
                animateText()
            }
    }
    
    private func animateText() {
        guard shouldAnimate else { return }
        
        var characters = Array(markdownText)
        var index = 0
        
        func addNextCharacter() {
            guard index < characters.count else {
                shouldAnimate = false
                return
            }
            
            currentText += String(characters[index])
            index += 1
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                addNextCharacter()
            }
        }
        
        addNextCharacter()
    }
}
