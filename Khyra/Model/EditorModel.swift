//
//  EditorModel.swift
//  Khyra
//
//  Created by Tufan Cakir on 31.07.26.
//

import Observation
import SwiftUI

@MainActor
@Observable
final class EditorModel {
    private static let selectedThemeKey = "khyra.selectedThemeID"
    private static let appLanguageKey = "khyra.appLanguageCode"

    var languageStore = LanguageStore.load()
    var selectedLanguageID = "html"
    var selectedThemeID = EditorTheme.classicDark.id {
        didSet {
            UserDefaults.standard.set(
                selectedThemeID,
                forKey: Self.selectedThemeKey
            )
        }
    }
    var appLanguageCode = "de" {
        didSet {
            UserDefaults.standard.set(
                appLanguageCode,
                forKey: Self.appLanguageKey
            )
        }
    }
    var documents: [String: String] = [:]
    var showConsole = true
    var showNavigator = false
    var cursorLocation = 0
    var projectItems: [ProjectItem] = []
    var selectedProjectItemID: UUID?
    var projectName = "Untitled"
    var currentProjectID = UUID()
    var hasActiveProject = false
    var snippetLibrary = SnippetLibraryViewModel()

    var selectedLanguage: CodeLanguage {
        if let activeItem, let languageID = activeItem.languageID {
            return languageStore.languages.first { $0.id == languageID }
                ?? CodeLanguage.htmlFallback
        }
        return languageStore.languages.first { $0.id == selectedLanguageID }
            ?? CodeLanguage.htmlFallback
    }

    var selectedTheme: EditorTheme {
        EditorTheme.all.first { $0.id == selectedThemeID } ?? .classicDark
    }

    var appStrings: AppStrings {
        AppStrings.load(languageCode: appLanguageCode)
    }

    var activeCode: Binding<String> {
        Binding(
            get: {
                self.documents[self.activeDocumentKey]
                    ?? self.selectedLanguage.sampleCode
            },
            set: { self.setCode($0, for: self.activeDocumentKey) }
        )
    }

    var activeItem: ProjectItem? {
        guard let selectedProjectItemID else { return nil }
        return projectItems.first { $0.id == selectedProjectItemID }
    }

    private var activeDocumentKey: String {
        activeItem?.documentKey ?? "scratch-\(selectedLanguageID)"
    }

    var issues: [LintIssue] {
        CodeLinter.lint(activeCode.wrappedValue, language: selectedLanguage)
    }

    var lineCount: Int {
        max(
            1,
            activeCode.wrappedValue.split(
                separator: "\n",
                omittingEmptySubsequences: false
            ).count
        )
    }

    init() {
        let fallbackLanguage =
            Locale.current.language.languageCode?.identifier == "de"
            ? "de" : "en"
        appLanguageCode =
            UserDefaults.standard.string(forKey: Self.appLanguageKey)
            ?? fallbackLanguage
        selectedThemeID =
            UserDefaults.standard.string(forKey: Self.selectedThemeKey)
            ?? EditorTheme.classicDark.id
        seedDocumentsIfNeeded()
    }

    func setLanguage(_ languageCode: String) {
        appLanguageCode = languageCode == "de" ? "de" : "en"
    }

    func seedDocumentsIfNeeded() {
        if let activeItem {
            if documents[activeItem.documentKey] == nil {
                setCode("", for: activeItem.documentKey)
            }
        } else {
            if documents[activeDocumentKey] == nil {
                setCode("", for: activeDocumentKey)
            }
        }
    }

    func insertBoilerplate() {
        let boilerplate =
            selectedLanguage.boilerplateCode ?? selectedLanguage.sampleCode
        setActiveCode(boilerplate)
        cursorLocation = boilerplate.utf16.count
    }

    func formatActiveDocument() {
        let formatted = CodeFormatter.format(
            activeCode.wrappedValue,
            language: selectedLanguage
        )
        setActiveCode(formatted)
        cursorLocation = min(cursorLocation, formatted.utf16.count)
    }

    func cleanCodeRefactor() {
        guard selectedLanguage.id == "html" else {
            formatActiveDocument()
            return
        }

        var html = activeCode.wrappedValue
        let extractedCSS = extractContent(tag: "style", from: &html)
        let extractedJS = extractContent(tag: "script", from: &html)

        if !extractedCSS.isEmpty {
            let cssItem = fileForLanguage("css", fallbackName: "style.css")
            let currentCSS = documents[cssItem.documentKey] ?? ""
            setCode(
                merged(existing: currentCSS, extracted: extractedCSS),
                for: cssItem.documentKey
            )
            html = insertLinkIfNeeded(in: html)
        }

        if !extractedJS.isEmpty {
            let jsItem = fileForLanguage("javascript", fallbackName: "app.js")
            let currentJS = documents[jsItem.documentKey] ?? ""
            setCode(
                merged(existing: currentJS, extracted: extractedJS),
                for: jsItem.documentKey
            )
            html = insertScriptIfNeeded(in: html)
        }

        setActiveCode(CodeFormatter.format(html, language: selectedLanguage))
        selectedLanguageID = "html"
        cursorLocation = documents[activeDocumentKey]?.utf16.count ?? 0
    }

    func createProject(template: ProjectTemplate) {
        currentProjectID = UUID()
        projectName = template.title
        hasActiveProject = true
        documents = [:]
        projectItems = []
        selectedProjectItemID = nil
        selectedLanguageID = "html"
        cursorLocation = 0

        for file in template.files {
            guard
                let language = languageStore.languages.first(where: {
                    $0.id == file.languageID
                })
            else { continue }
            addFile(language: language, name: file.name)
            if let activeItem {
                setCode(file.code, for: activeItem.documentKey)
            }
        }

        selectedProjectItemID = projectItems.first?.id
        if let activeItem, let languageID = activeItem.languageID {
            selectedLanguageID = languageID
        }
    }

    func saveProject() {
        let project = SavedProject(
            id: currentProjectID,
            projectName: projectName,
            selectedLanguageID: selectedLanguageID,
            selectedProjectItemID: selectedProjectItemID,
            documents: documents,
            projectItems: projectItems,
            savedAt: Date()
        )
        ProjectStore.save(project)
    }

    func loadProject(_ project: SavedProject) {
        currentProjectID = project.id
        projectName = project.projectName
        hasActiveProject = true
        selectedLanguageID = project.selectedLanguageID
        selectedProjectItemID = project.selectedProjectItemID
        documents = project.documents
        projectItems = project.projectItems
        cursorLocation = 0
    }

    func selectProjectItem(_ item: ProjectItem) {
        guard item.kind == .file, let languageID = item.languageID else {
            return
        }
        selectedProjectItemID = item.id
        selectedLanguageID = languageID
        seedDocumentsIfNeeded()
        cursorLocation = min(
            cursorLocation,
            activeCode.wrappedValue.utf16.count
        )
    }

    func selectLanguage(_ languageID: String) {
        selectedProjectItemID = nil
        selectedLanguageID = languageID
        seedDocumentsIfNeeded()
        cursorLocation = min(
            cursorLocation,
            activeCode.wrappedValue.utf16.count
        )
    }

    func addFile(language: CodeLanguage, name: String) {
        let fileName = normalizedFileName(
            name,
            fallback: language.fileExtension
        )
        let item = ProjectItem(
            name: fileName,
            kind: .file,
            languageID: language.id,
            children: []
        )
        projectItems.append(item)
        selectedProjectItemID = item.id
        selectedLanguageID = language.id
        setCode("", for: item.documentKey)
        cursorLocation = 0
    }

    func addFolder() {
        let count = projectItems.filter { $0.kind == .folder }.count + 1
        projectItems.append(
            ProjectItem(
                name: "Folder \(count)",
                kind: .folder,
                languageID: nil,
                children: []
            )
        )
    }

    func renameProjectItem(_ item: ProjectItem, to newName: String) {
        let trimmedName = newName.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        guard !trimmedName.isEmpty,
            let index = projectItems.firstIndex(where: { $0.id == item.id })
        else { return }
        projectItems[index].name = trimmedName
    }

    func deleteProjectItem(_ item: ProjectItem) {
        projectItems.removeAll { $0.id == item.id }
        removeCode(for: item.documentKey)
        if selectedProjectItemID == item.id {
            selectedProjectItemID =
                projectItems.first(where: { $0.kind == .file })?.id
            if let activeItem, let languageID = activeItem.languageID {
                selectedLanguageID = languageID
            }
        }
    }

    func exportText(for item: ProjectItem) -> String {
        documents[item.documentKey] ?? ""
    }

    func exportURL(for item: ProjectItem) -> URL? {
        let sanitizedName = item.name.replacingOccurrences(of: "/", with: "-")
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(
            sanitizedName
        )
        do {
            try exportText(for: item).write(
                to: url,
                atomically: true,
                encoding: .utf8
            )
            return url
        } catch {
            return nil
        }
    }

    func suggestions() -> [CodeSuggestion] {
        let prefix = currentPrefix()
        guard !prefix.isEmpty else { return [] }

        let snippetSuggestions = selectedLanguage.snippets.map { snippet in
            CodeSuggestion(
                title: snippet.title,
                insertText: snippet.insertText,
                replacementPrefix: prefix,
                kind: .snippet
            )
        }

        let keywordSuggestions = selectedLanguage.keywords.map { keyword in
            CodeSuggestion(
                title: keyword,
                insertText: keyword,
                replacementPrefix: prefix,
                kind: .keyword
            )
        }

        let userSnippetSuggestions = snippetLibrary.snippets(
            for: selectedLanguage.id
        ).map { snippet in
            CodeSuggestion(
                title: snippet.title,
                insertText: snippet.code,
                replacementPrefix: prefix,
                kind: .userSnippet
            )
        }

        return
            (snippetSuggestions + userSnippetSuggestions + keywordSuggestions)
            .filter { suggestion in
                suggestion.title.localizedCaseInsensitiveContains(prefix)
                    || suggestion.insertText.localizedCaseInsensitiveContains(
                        prefix
                    )
            }
            .prefix(12)
            .map { $0 }
    }

    func applySuggestion(_ suggestion: CodeSuggestion) {
        let source = activeCode.wrappedValue
        guard
            let range = prefixRange(
                in: source,
                cursorLocation: cursorLocation,
                prefix: suggestion.replacementPrefix
            )
        else {
            setActiveCode(source + suggestion.insertText)
            cursorLocation = documents[activeDocumentKey]?.utf16.count ?? 0
            return
        }

        var updated = source
        updated.replaceSubrange(range, with: suggestion.insertText)
        setActiveCode(updated)

        let prefixUTF16Count = suggestion.replacementPrefix.utf16.count
        cursorLocation =
            cursorLocation - prefixUTF16Count
            + suggestion.insertText.utf16.count
    }

    func replaceActiveCode(with snippet: UserSnippet) {
        let replacement = codeForSnippet(snippet)
        setActiveCode(replacement)
        cursorLocation = replacement.utf16.count
    }

    func replaceActiveCode(with snippet: CodeSnippet) {
        let replacement = snippet.insertText
        setActiveCode(replacement)
        cursorLocation = replacement.utf16.count
    }

    func replaceActiveCode(with framework: CodeFramework) {
        let replacement = framework.boilerplateCode
        setActiveCode(replacement)
        cursorLocation = replacement.utf16.count
    }

    func saveActiveSelectionAsSnippet(title: String, trigger: String) {
        let currentCode = activeCode.wrappedValue
        let codeToSave =
            currentCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? defaultSnippetCode(for: selectedLanguage) : currentCode
        snippetLibrary.save(
            title: title,
            languageID: selectedLanguage.id,
            trigger: trigger,
            code: codeToSave
        )
    }

    func webPreviewHTML() -> String {
        let html = sanitizedHTML(firstCode(for: "html"))
        let css = firstCode(for: "css")
        let javascript = firstCode(for: "javascript")
        let previewCSS =
            css.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? "html, body {\n  background: white;\n  color: black;\n}" : css
        let styleBlock = "<style>\n\(previewCSS)\n</style>"
        let scriptBlock = "<script>\n\(javascript)\n</script>"

        if html.localizedCaseInsensitiveContains("</head>")
            && html.localizedCaseInsensitiveContains("</body>")
        {
            return
                html
                .replacingOccurrences(
                    of: "</head>",
                    with: "\(styleBlock)\n</head>",
                    options: .caseInsensitive
                )
                .replacingOccurrences(
                    of: "</body>",
                    with: "\(scriptBlock)\n</body>",
                    options: .caseInsensitive
                )
        }

        return """
            <!DOCTYPE html>
            <html lang="de">
            <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            \(styleBlock)
            </head>
            <body>
            \(html)
            \(scriptBlock)
            </body>
            </html>
            """
    }

    private func currentPrefix() -> String {
        let source = activeCode.wrappedValue
        guard
            let cursorIndex = stringIndex(
                in: source,
                utf16Offset: cursorLocation
            )
        else { return "" }
        var startIndex = cursorIndex

        while startIndex > source.startIndex {
            let previousIndex = source.index(before: startIndex)
            let character = source[previousIndex]
            guard
                character.isLetter || character.isNumber || character == "-"
                    || character == "_"
            else {
                break
            }
            startIndex = previousIndex
        }

        return String(source[startIndex..<cursorIndex])
    }

    private func prefixRange(
        in source: String,
        cursorLocation: Int,
        prefix: String
    ) -> Range<String.Index>? {
        guard
            let cursorIndex = stringIndex(
                in: source,
                utf16Offset: cursorLocation
            )
        else { return nil }
        guard
            let startIndex = source.index(
                cursorIndex,
                offsetBy: -prefix.count,
                limitedBy: source.startIndex
            )
        else { return nil }
        return startIndex..<cursorIndex
    }

    private func stringIndex(in source: String, utf16Offset: Int) -> String
        .Index?
    {
        let boundedOffset = min(max(utf16Offset, 0), source.utf16.count)
        let utf16Index = source.utf16.index(
            source.utf16.startIndex,
            offsetBy: boundedOffset
        )
        return String.Index(utf16Index, within: source)
    }

    private func firstCode(for languageID: String) -> String {
        let projectCode =
            projectItems
            .filter { $0.kind == .file && $0.languageID == languageID }
            .compactMap { documents[$0.documentKey] }
            .filter {
                !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            }
            .joined(separator: "\n\n")

        if !projectCode.isEmpty {
            return projectCode
        }

        return documents["scratch-\(languageID)"] ?? ""
    }

    private func sanitizedHTML(_ html: String) -> String {
        let pattern = #"(?m)^\s*[^<>\n]+\{[^}]*\}\s*$"#
        guard let expression = try? NSRegularExpression(pattern: pattern) else {
            return html
        }
        let range = NSRange(location: 0, length: (html as NSString).length)
        return expression.stringByReplacingMatches(
            in: html,
            range: range,
            withTemplate: ""
        )
    }

    private func fileForLanguage(_ languageID: String, fallbackName: String)
        -> ProjectItem
    {
        if let item = projectItems.first(where: { $0.languageID == languageID })
        {
            return item
        }

        let item = ProjectItem(
            name: fallbackName,
            kind: .file,
            languageID: languageID,
            children: []
        )
        projectItems.append(item)
        setCode("", for: item.documentKey)
        return item
    }

    private func setActiveCode(_ code: String) {
        setCode(code, for: activeDocumentKey)
    }

    private func setCode(_ code: String, for key: String) {
        var updatedDocuments = documents
        updatedDocuments[key] = code
        documents = updatedDocuments
    }

    private func removeCode(for key: String) {
        var updatedDocuments = documents
        updatedDocuments[key] = nil
        documents = updatedDocuments
    }

    private func codeForSnippet(_ snippet: UserSnippet) -> String {
        let trimmedCode = snippet.code.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        if !trimmedCode.isEmpty {
            return snippet.code
        }

        let language =
            languageStore.languages.first { $0.id == snippet.languageID }
            ?? selectedLanguage
        return defaultSnippetCode(for: language)
    }

    private func defaultSnippetCode(for language: CodeLanguage) -> String {
        if let boilerplate = language.boilerplateCode,
            !boilerplate.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        {
            return boilerplate
        }

        if !language.sampleCode.trimmingCharacters(in: .whitespacesAndNewlines)
            .isEmpty
        {
            return language.sampleCode
        }

        return ""
    }

    private func normalizedFileName(_ name: String, fallback: String) -> String
    {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? fallback : trimmed
    }

    private func extractContent(tag: String, from html: inout String) -> String
    {
        let pattern = "<\(tag)(?:\\s[^>]*)?>([\\s\\S]*?)</\(tag)>"
        guard
            let expression = try? NSRegularExpression(
                pattern: pattern,
                options: [.caseInsensitive]
            )
        else { return "" }
        let source = html
        let range = NSRange(location: 0, length: (source as NSString).length)
        let matches = expression.matches(in: source, range: range).reversed()
        var extracted: [String] = []

        for match in matches {
            let nsSource = source as NSString
            extracted.append(
                nsSource.substring(with: match.range(at: 1)).trimmingCharacters(
                    in: .whitespacesAndNewlines
                )
            )
            if let swiftRange = Range(match.range(at: 0), in: html) {
                html.removeSubrange(swiftRange)
            }
        }

        return extracted.reversed().filter { !$0.isEmpty }.joined(
            separator: "\n\n"
        )
    }

    private func merged(existing: String, extracted: String) -> String {
        guard !existing.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else { return extracted }
        return existing + "\n\n" + extracted
    }

    private func insertLinkIfNeeded(in html: String) -> String {
        guard !html.localizedCaseInsensitiveContains("style.css") else {
            return html
        }
        let link = "  <link rel=\"stylesheet\" href=\"style.css\">"
        if html.localizedCaseInsensitiveContains("</head>") {
            return html.replacingOccurrences(
                of: "</head>",
                with: "\(link)\n</head>",
                options: .caseInsensitive
            )
        }
        return link + "\n" + html
    }

    private func insertScriptIfNeeded(in html: String) -> String {
        guard !html.localizedCaseInsensitiveContains("app.js") else {
            return html
        }
        let script = "  <script src=\"app.js\"></script>"
        if html.localizedCaseInsensitiveContains("</body>") {
            return html.replacingOccurrences(
                of: "</body>",
                with: "\(script)\n</body>",
                options: .caseInsensitive
            )
        }
        return html + "\n" + script
    }
}

struct ProjectItem: Identifiable, Equatable, Codable {
    let id: UUID
    var name: String
    var kind: ProjectItemKind
    var languageID: String?
    var children: [ProjectItem]

    init(
        id: UUID = UUID(),
        name: String,
        kind: ProjectItemKind,
        languageID: String?,
        children: [ProjectItem]
    ) {
        self.id = id
        self.name = name
        self.kind = kind
        self.languageID = languageID
        self.children = children
    }

    var documentKey: String {
        id.uuidString
    }
}

enum ProjectItemKind: Equatable, Codable {
    case file
    case folder
}

struct ProjectTemplate: Identifiable, Equatable {
    let id: String
    let category: ProjectTemplateCategory
    let title: String
    let subtitle: String
    let systemImage: String
    let files: [ProjectTemplateFile]

    static let all: [ProjectTemplate] = [
        .blank, .webApp, .game, .extensionLike,
    ]

    static func catalog(from languageStore: LanguageStore) -> [ProjectTemplate]
    {
        all + languageTemplates(from: languageStore)
            + frameworkTemplates(from: languageStore)
    }

    static let blank = ProjectTemplate(
        id: "blank",
        category: .app,
        title: "Blank Project",
        subtitle: "Start with empty files.",
        systemImage: "doc",
        files: []
    )

    static let webApp = ProjectTemplate(
        id: "webapp",
        category: .web,
        title: "Web App",
        subtitle: "HTML, CSS and JS starter.",
        systemImage: "globe",
        files: [
            ProjectTemplateFile(
                name: "index.html",
                languageID: "html",
                code:
                    "<!DOCTYPE html>\n<html lang=\"de\">\n<head>\n  <meta charset=\"UTF-8\">\n  <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">\n  <title>Khyra App</title>\n</head>\n<body>\n  <main class=\"app\">\n    <h1>Hello Khyra</h1>\n  </main>\n</body>\n</html>"
            ),
            ProjectTemplateFile(
                name: "style.css",
                languageID: "css",
                code:
                    "body {\n  margin: 0;\n  min-height: 100vh;\n  background: #050706;\n  color: #19f26b;\n  font-family: system-ui, sans-serif;\n}\n\n.app {\n  padding: 24px;\n}"
            ),
            ProjectTemplateFile(
                name: "app.js",
                languageID: "javascript",
                code: "console.log('Khyra ready');"
            ),
        ]
    )

    static let game = ProjectTemplate(
        id: "game",
        category: .game,
        title: "Game",
        subtitle: "Small canvas game starter.",
        systemImage: "gamecontroller",
        files: [
            ProjectTemplateFile(
                name: "index.html",
                languageID: "html",
                code:
                    "<canvas id=\"game\" width=\"320\" height=\"240\"></canvas>"
            ),
            ProjectTemplateFile(
                name: "style.css",
                languageID: "css",
                code:
                    "body {\n  margin: 0;\n  display: grid;\n  place-items: center;\n  min-height: 100vh;\n  background: black;\n}\n\ncanvas {\n  background: #08120c;\n}"
            ),
            ProjectTemplateFile(
                name: "game.js",
                languageID: "javascript",
                code:
                    "const canvas = document.querySelector('#game');\nconst context = canvas.getContext('2d');\n\ncontext.fillStyle = '#19f26b';\ncontext.fillRect(40, 40, 80, 80);"
            ),
        ]
    )

    static let extensionLike = ProjectTemplate(
        id: "extension",
        category: .extension,
        title: "Extension",
        subtitle: "Manifest-style starter.",
        systemImage: "puzzlepiece.extension",
        files: [
            ProjectTemplateFile(
                name: "manifest.json",
                languageID: "json",
                code:
                    "{\n  \"name\": \"Khyra Extension\",\n  \"version\": \"1.0.0\",\n  \"enabled\": true\n}"
            ),
            ProjectTemplateFile(
                name: "README.md",
                languageID: "markdown",
                code: "# Khyra Extension\n\nNotes and setup."
            ),
        ]
    )

    private static func languageTemplates(from languageStore: LanguageStore)
        -> [ProjectTemplate]
    {
        languageStore.languages.compactMap { language in
            guard let boilerplateCode = language.boilerplateCode,
                !boilerplateCode.trimmingCharacters(in: .whitespacesAndNewlines)
                    .isEmpty
            else {
                return nil
            }

            return ProjectTemplate(
                id: "language-\(language.id)",
                category: category(for: language),
                title: "\(language.name) File",
                subtitle: "Starter for \(language.fileExtension).",
                systemImage: iconName(for: language),
                files: [
                    ProjectTemplateFile(
                        name: language.fileExtension,
                        languageID: language.id,
                        code: boilerplateCode
                    )
                ]
            )
        }
    }

    private static func frameworkTemplates(from languageStore: LanguageStore)
        -> [ProjectTemplate]
    {
        languageStore.languages.flatMap { language in
            language.frameworks.map { framework in
                ProjectTemplate(
                    id: "framework-\(language.id)-\(framework.id)",
                    category: .frameworks,
                    title: framework.name,
                    subtitle: framework.runtime,
                    systemImage: framework.previewSupported
                        ? "shippingbox.fill" : "shippingbox",
                    files: [
                        ProjectTemplateFile(
                            name: language.fileExtension,
                            languageID: language.id,
                            code: framework.boilerplateCode
                        )
                    ]
                )
            }
        }
    }

    private static func category(for language: CodeLanguage)
        -> ProjectTemplateCategory
    {
        switch language.id {
        case "html", "css", "javascript", "php":
            return .web
        case "json", "sql", "markdown":
            return .data
        default:
            return .app
        }
    }

    private static func iconName(for language: CodeLanguage) -> String {
        switch language.id {
        case "html": "chevron.left.forwardslash.chevron.right"
        case "css": "paintbrush.pointed.fill"
        case "javascript": "curlybraces"
        case "php": "globe.badge.chevron.backward"
        case "json": "curlybraces.square"
        case "markdown": "doc.richtext"
        case "sql": "cylinder.split.1x2"
        case "swift": "swift"
        case "python": "terminal"
        default: "doc.text"
        }
    }
}

struct ProjectTemplateFile: Equatable {
    let name: String
    let languageID: String
    let code: String
}

enum ProjectTemplateCategory: String, CaseIterable, Identifiable {
    case all
    case web
    case app
    case game
    case `extension`
    case data
    case frameworks

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: "All"
        case .web: "Web"
        case .app: "App"
        case .game: "Game"
        case .extension: "Extensions"
        case .data: "Data"
        case .frameworks: "Frameworks"
        }
    }

    var systemImage: String {
        switch self {
        case .all: "square.grid.2x2"
        case .web: "globe"
        case .app: "app"
        case .game: "gamecontroller"
        case .extension: "puzzlepiece.extension"
        case .data: "cylinder.split.1x2"
        case .frameworks: "shippingbox"
        }
    }
}

struct CodeSuggestion: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let insertText: String
    let replacementPrefix: String
    let kind: CodeSuggestionKind
}

enum CodeSuggestionKind: Equatable {
    case snippet
    case userSnippet
    case keyword

    var iconName: String {
        switch self {
        case .snippet: "curlybraces.square"
        case .userSnippet: "tray.full"
        case .keyword: "textformat"
        }
    }
}
