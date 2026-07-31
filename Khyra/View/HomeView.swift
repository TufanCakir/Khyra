//
//  HomeView.swift
//  Khyra
//
//  Created by Tufan Cakir on 31.07.26.
//

import SwiftUI
import UIKit

struct HomeView: View {
    let model: EditorModel
    @State private var snippetDraft: SnippetEditorDraft?
    @State private var snippetCursorLocation = 0
    @State private var showSavedToast = false

    init(model: EditorModel) {
        self.model = model
    }

    private var selectedThemeID: Binding<String> {
        Binding(
            get: { model.selectedThemeID },
            set: { model.selectedThemeID = $0 }
        )
    }

    private var selectedLanguageID: Binding<String> {
        Binding(
            get: { model.selectedLanguageID },
            set: { model.selectedLanguageID = $0 }
        )
    }

    private var cursorLocation: Binding<Int> {
        Binding(
            get: { model.cursorLocation },
            set: { model.cursorLocation = $0 }
        )
    }

    var body: some View {
        ZStack {
            model.selectedTheme.background
                .ignoresSafeArea()

            HStack(spacing: 0) {
                if model.showNavigator {
                    ProjectNavigatorView(
                        model: model,
                        onCreateSnippet: openNewSnippetEditor,
                        onEditSnippet: openSnippetEditor
                    )
                    .frame(width: 176)
                    .transition(.move(edge: .leading).combined(with: .opacity))
                }

                VStack(spacing: 0) {
                    LanguageTabsView(
                        languages: model.languageStore.languages,
                        selectedLanguageID: selectedLanguageID,
                        theme: model.selectedTheme,
                        onSelect: model.selectLanguage
                    )
                    EditorHeaderView(
                        language: model.selectedLanguage,
                        issueCount: model.issues.count,
                        lineCount: model.lineCount,
                        theme: model.selectedTheme
                    )
                    SuggestionsBarView(
                        suggestions: model.suggestions(),
                        theme: model.selectedTheme,
                        onSelect: model.applySuggestion
                    )
                    CodeEditorView(
                        text: model.activeCode,
                        cursorLocation: cursorLocation,
                        language: model.selectedLanguage,
                        theme: model.selectedTheme
                    )
                    .background(model.selectedTheme.editorBackground)

                    if model.showConsole {
                        ConsoleView(
                            issues: model.issues,
                            theme: model.selectedTheme,
                            onToggle: {
                                withAnimation(.snappy) {
                                    model.showConsole.toggle()
                                }
                            }
                        )
                        .frame(height: 178)
                        .transition(
                            .move(edge: .bottom).combined(with: .opacity)
                        )
                    } else {
                        ConsoleCollapsedBar(theme: model.selectedTheme) {
                            withAnimation(.snappy) {
                                model.showConsole.toggle()
                            }
                        }
                    }
                }
            }

            if showSavedToast {
                VStack {
                    Spacer()
                    SaveToast(theme: model.selectedTheme)
                        .padding(.bottom, 92)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            if snippetDraft != nil {
                SnippetEditorModal(
                    draft: Binding(
                        get: {
                            snippetDraft
                                ?? SnippetEditorDraft(
                                    languageID: model.selectedLanguage.id
                                )
                        },
                        set: { snippetDraft = $0 }
                    ),
                    cursorLocation: $snippetCursorLocation,
                    language: model.languageStore.languages.first {
                        $0.id == snippetDraft?.languageID
                    } ?? model.selectedLanguage,
                    theme: model.selectedTheme,
                    onSave: saveSnippetDraft,
                    onClose: { snippetDraft = nil }
                )
            }
        }
        .foregroundStyle(model.selectedTheme.primaryText)
        .onAppear {
            model.seedDocumentsIfNeeded()
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    withAnimation(.snappy) {
                        model.showNavigator.toggle()
                    }
                } label: {
                    Image(systemName: "sidebar.left")
                }
                .accessibilityLabel("Projekt Navigator umschalten")
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    model.insertBoilerplate()
                } label: {
                    Image(systemName: "wand.and.stars")
                }
                .accessibilityLabel("Boilerplate einfuegen")
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    model.saveProject()
                    showSavedFeedback()
                } label: {
                    Image(systemName: "square.and.arrow.down")
                }
                .accessibilityLabel("Projekt speichern")
            }

            ToolbarItem(placement: .topBarTrailing) {
                ShareLink(item: model.activeCode.wrappedValue) {
                    Image(systemName: "square.and.arrow.up")
                }
                .accessibilityLabel("Code teilen")
            }

            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Picker("Theme", selection: selectedThemeID) {
                        ForEach(EditorTheme.all) { theme in
                            Text(theme.name).tag(theme.id)
                        }
                    }

                    Divider()

                    Button {
                        model.formatActiveDocument()
                    } label: {
                        Label("Format", systemImage: "text.alignleft")
                    }

                    Button {
                        model.cleanCodeRefactor()
                    } label: {
                        Label("Clean Code", systemImage: "sparkles")
                    }

                    NavigationLink(value: AppRoute.preview) {
                        Label("Preview", systemImage: "safari")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .accessibilityLabel("Mehr Aktionen")
            }
        }
        .preferredColorScheme(model.selectedTheme.preferredScheme)
    }

    private func openNewSnippetEditor() {
        let currentCode = model.activeCode.wrappedValue
        let fallback =
            model.selectedLanguage.boilerplateCode
            ?? model.selectedLanguage.sampleCode
        snippetDraft = SnippetEditorDraft(
            languageID: model.selectedLanguage.id,
            title: model.activeItem?.name ?? model.selectedLanguage.name,
            trigger: "",
            code: currentCode.trimmingCharacters(in: .whitespacesAndNewlines)
                .isEmpty ? fallback : currentCode,
            existingSnippet: nil
        )
        snippetCursorLocation = snippetDraft?.code.utf16.count ?? 0
    }

    private func openSnippetEditor(_ snippet: UserSnippet) {
        snippetDraft = SnippetEditorDraft(
            languageID: snippet.languageID,
            title: snippet.title,
            trigger: snippet.trigger,
            code: snippet.code,
            existingSnippet: snippet
        )
        snippetCursorLocation = snippet.code.utf16.count
    }

    private func saveSnippetDraft() {
        guard let snippetDraft else { return }
        let language =
            model.languageStore.languages.first {
                $0.id == snippetDraft.languageID
            } ?? model.selectedLanguage
        let issues = CodeLinter.lint(snippetDraft.code, language: language)
        guard !issues.contains(where: { $0.severity == .error }) else { return }

        if let existingSnippet = snippetDraft.existingSnippet {
            model.snippetLibrary.update(
                existingSnippet,
                title: snippetDraft.title,
                trigger: snippetDraft.trigger,
                code: snippetDraft.code
            )
        } else {
            model.snippetLibrary.save(
                title: snippetDraft.title,
                languageID: snippetDraft.languageID,
                trigger: snippetDraft.trigger,
                code: snippetDraft.code
            )
        }

        self.snippetDraft = nil
    }

    private func showSavedFeedback() {
        withAnimation(.snappy) {
            showSavedToast = true
        }

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_250_000_000)
            withAnimation(.snappy) {
                showSavedToast = false
            }
        }
    }
}

struct ProjectNavigatorView: View {
    let model: EditorModel
    let onCreateSnippet: () -> Void
    let onEditSnippet: (UserSnippet) -> Void
    @State private var newFileName = ""
    @State private var newFileLanguage: CodeLanguage?
    @State private var renameItem: ProjectItem?
    @State private var renameText = ""
    @State private var selectedTab: NavigatorTab = .files

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: selectedTab.systemImage)
                    .foregroundStyle(model.selectedTheme.accent)
                Text(selectedTab.title)
                    .font(
                        .system(size: 13, weight: .heavy, design: .monospaced)
                    )
                Spacer()
                if selectedTab == .files {
                    Menu {
                        ForEach(model.languageStore.languages) { language in
                            Button(language.name) {
                                newFileName = language.fileExtension
                                newFileLanguage = language
                            }
                        }

                        Button("New Folder") {
                            model.addFolder()
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(model.selectedTheme.accent)
                } else {
                    Button(action: onCreateSnippet) {
                        Image(systemName: "plus")
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(model.selectedTheme.accent)
                }
            }
            .padding(.horizontal, 12)
            .frame(height: 42)

            Picker("Navigator", selection: $selectedTab) {
                ForEach(NavigatorTab.allCases) { tab in
                    Image(systemName: tab.systemImage).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 8)
            .padding(.bottom, 8)

            switch selectedTab {
            case .files:
                filesList
            case .snippets:
                SnippetLibraryPanel(model: model, onEditSnippet: onEditSnippet)
            }
        }
        .foregroundStyle(model.selectedTheme.primaryText)
        .background(model.selectedTheme.panelBackground)
        .overlay(alignment: .trailing) {
            Rectangle()
                .fill(model.selectedTheme.border)
                .frame(width: 1)
        }
        .alert("New File", isPresented: newFileAlertBinding) {
            TextField("File name", text: $newFileName)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            Button("Create") {
                if let newFileLanguage {
                    model.addFile(language: newFileLanguage, name: newFileName)
                }
                self.newFileLanguage = nil
            }
            Button("Cancel", role: .cancel) {
                newFileLanguage = nil
            }
        } message: {
            Text("Choose a custom name for this file.")
        }
        .alert("Rename", isPresented: renameAlertBinding) {
            TextField("Name", text: $renameText)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            Button("Save") {
                if let renameItem {
                    model.renameProjectItem(renameItem, to: renameText)
                }
                self.renameItem = nil
            }
            Button("Cancel", role: .cancel) {
                renameItem = nil
            }
        }
    }

    private var filesList: some View {
        Group {
            if model.projectItems.isEmpty {
                ContentUnavailableView(
                    "No Files",
                    systemImage: "folder",
                    description: Text("Tap + to create your own files.")
                )
                .font(.caption)
                .foregroundStyle(model.selectedTheme.secondaryText)
            } else {
                List {
                    ForEach(model.projectItems) { item in
                        ProjectItemRow(
                            item: item,
                            isSelected: model.selectedProjectItemID == item.id,
                            exportURL: model.exportURL(for: item),
                            theme: model.selectedTheme,
                            onSelect: { model.selectProjectItem(item) },
                            onRename: {
                                renameItem = item
                                renameText = item.name
                            },
                            onDelete: { model.deleteProjectItem(item) }
                        )
                        .listRowInsets(
                            EdgeInsets(
                                top: 2,
                                leading: 8,
                                bottom: 2,
                                trailing: 8
                            )
                        )
                        .listRowBackground(model.selectedTheme.panelBackground)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
    }

    private var newFileAlertBinding: Binding<Bool> {
        Binding(
            get: { newFileLanguage != nil },
            set: { if !$0 { newFileLanguage = nil } }
        )
    }

    private var renameAlertBinding: Binding<Bool> {
        Binding(
            get: { renameItem != nil },
            set: { if !$0 { renameItem = nil } }
        )
    }
}

enum NavigatorTab: String, CaseIterable, Identifiable {
    case files
    case snippets

    var id: String { rawValue }

    var title: String {
        switch self {
        case .files: "Files"
        case .snippets: "Snippets"
        }
    }

    var systemImage: String {
        switch self {
        case .files: "folder"
        case .snippets: "tray.full"
        }
    }
}

struct SnippetEditorDraft: Identifiable, Equatable {
    let id = UUID()
    var languageID: String
    var title = ""
    var trigger = ""
    var code = ""
    var existingSnippet: UserSnippet?
}

struct SnippetEditorModal: View {
    @Binding var draft: SnippetEditorDraft
    @Binding var cursorLocation: Int
    let language: CodeLanguage
    let theme: EditorTheme
    let onSave: () -> Void
    let onClose: () -> Void

    private var issues: [LintIssue] {
        CodeLinter.lint(draft.code, language: language)
    }

    private var hasErrors: Bool {
        issues.contains { $0.severity == .error }
    }

    private var canSave: Bool {
        !draft.code.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !hasErrors
    }

    var body: some View {
        ThemedModal(
            title: draft.existingSnippet == nil
                ? "New Snippet" : "Edit Snippet",
            theme: theme,
            onClose: onClose
        ) {
            VStack(spacing: 12) {
                TextField("Title", text: $draft.title)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .padding(10)
                    .background(
                        theme.controlBackground,
                        in: RoundedRectangle(cornerRadius: 8)
                    )

                TextField("Trigger", text: $draft.trigger)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .padding(10)
                    .background(
                        theme.controlBackground,
                        in: RoundedRectangle(cornerRadius: 8)
                    )

                CodeEditorView(
                    text: $draft.code,
                    cursorLocation: $cursorLocation,
                    language: language,
                    theme: theme
                )
                .frame(height: 230)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(theme.border, lineWidth: 1)
                )

                ConsoleView(issues: issues, theme: theme)
                    .frame(height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                HStack(spacing: 10) {
                    Button(action: onClose) {
                        Label("Cancel", systemImage: "xmark")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(theme.secondaryText)
                    .padding(12)
                    .background(
                        theme.controlBackground,
                        in: RoundedRectangle(cornerRadius: 8)
                    )

                    Button(action: onSave) {
                        Label("Save", systemImage: "checkmark")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(
                        canSave ? theme.selectedText : theme.secondaryText
                    )
                    .padding(12)
                    .background(
                        canSave
                            ? theme.accent.opacity(0.28)
                            : theme.controlBackground,
                        in: RoundedRectangle(cornerRadius: 8)
                    )
                    .disabled(!canSave)
                }

                if hasErrors {
                    Text("Fix snippet errors before saving.")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(theme.error)
                }
            }
        }
    }
}

struct SnippetLibraryPanel: View {
    let model: EditorModel
    let onEditSnippet: (UserSnippet) -> Void

    private var builtinSnippets: [CodeSnippet] {
        model.selectedLanguage.snippets
    }

    private var frameworks: [CodeFramework] {
        model.selectedLanguage.frameworks
    }

    private var userSnippets: [UserSnippet] {
        model.snippetLibrary.snippets(for: model.selectedLanguage.id)
    }

    var body: some View {
        Group {
            if frameworks.isEmpty && builtinSnippets.isEmpty
                && userSnippets.isEmpty
            {
                ContentUnavailableView(
                    "No Snippets",
                    systemImage: "tray",
                    description: Text(
                        "Add frameworks/snippets in code.json or save your current code."
                    )
                )
                .font(.caption)
                .foregroundStyle(model.selectedTheme.secondaryText)
            } else {
                List {
                    if !frameworks.isEmpty {
                        Section("Frameworks") {
                            ForEach(frameworks) { framework in
                                FrameworkRow(
                                    framework: framework,
                                    language: model.selectedLanguage,
                                    theme: model.selectedTheme,
                                    onInsert: {
                                        model.replaceActiveCode(with: framework)
                                    }
                                )
                                .listRowInsets(
                                    EdgeInsets(
                                        top: 2,
                                        leading: 8,
                                        bottom: 2,
                                        trailing: 8
                                    )
                                )
                                .listRowBackground(
                                    model.selectedTheme.panelBackground
                                )
                            }
                        }
                    }

                    if !builtinSnippets.isEmpty {
                        Section("Examples") {
                            ForEach(builtinSnippets) { snippet in
                                BuiltinSnippetRow(
                                    snippet: snippet,
                                    language: model.selectedLanguage,
                                    theme: model.selectedTheme,
                                    onInsert: {
                                        model.replaceActiveCode(with: snippet)
                                    }
                                )
                                .listRowInsets(
                                    EdgeInsets(
                                        top: 2,
                                        leading: 8,
                                        bottom: 2,
                                        trailing: 8
                                    )
                                )
                                .listRowBackground(
                                    model.selectedTheme.panelBackground
                                )
                            }
                        }
                    }

                    if !userSnippets.isEmpty {
                        Section("Saved") {
                            ForEach(userSnippets) { snippet in
                                SnippetRow(
                                    snippet: snippet,
                                    language: model.selectedLanguage,
                                    theme: model.selectedTheme,
                                    onInsert: {
                                        model.replaceActiveCode(with: snippet)
                                    },
                                    onEdit: { onEditSnippet(snippet) },
                                    onDelete: {
                                        model.snippetLibrary.delete(snippet)
                                    }
                                )
                                .listRowInsets(
                                    EdgeInsets(
                                        top: 2,
                                        leading: 8,
                                        bottom: 2,
                                        trailing: 8
                                    )
                                )
                                .listRowBackground(
                                    model.selectedTheme.panelBackground
                                )
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .onAppear {
            model.snippetLibrary.reload()
        }
    }
}

struct SnippetCodePreview: View {
    let code: String
    let language: CodeLanguage
    let theme: EditorTheme

    private var firstLine: String {
        code
            .components(separatedBy: .newlines)
            .first?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    private var highlightedCode: AttributedString {
        let source = firstLine.isEmpty ? "empty" : firstLine
        let highlighted = SyntaxHighlighter.highlight(
            source,
            language: language,
            theme: theme
        )
        return (try? AttributedString(highlighted, including: \.uiKit))
            ?? AttributedString(source)
    }

    var body: some View {
        Text(highlightedCode)
            .font(.system(size: 10, weight: .semibold, design: .monospaced))
            .lineLimit(1)
            .padding(.top, 1)
    }
}

struct FrameworkRow: View {
    let framework: CodeFramework
    let language: CodeLanguage
    let theme: EditorTheme
    let onInsert: () -> Void

    private var supportText: String {
        framework.previewSupported
            ? "\(framework.runtime) preview" : framework.runtime
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Image(
                    systemName: framework.previewSupported
                        ? "shippingbox.fill" : "shippingbox"
                )
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(theme.accent)
                Text(framework.name)
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .lineLimit(1)
                Spacer(minLength: 0)
            }

            Text(supportText)
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundStyle(
                    framework.previewSupported ? theme.success : theme.warning
                )
                .lineLimit(1)

            SnippetCodePreview(
                code: framework.boilerplateCode,
                language: language,
                theme: theme
            )
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 7)
        .contentShape(Rectangle())
        .onTapGesture {
            onInsert()
        }
        .foregroundStyle(theme.selectedText)
        .background(
            theme.controlBackground,
            in: RoundedRectangle(cornerRadius: 7)
        )
        .contextMenu {
            Button {
                onInsert()
            } label: {
                Label("Use Framework", systemImage: "text.insert")
            }
            Button {
                UIPasteboard.general.string = framework.boilerplateCode
            } label: {
                Label("Copy", systemImage: "doc.on.doc")
            }
        }
        .swipeActions(edge: .leading) {
            Button(action: onInsert) {
                Label("Use", systemImage: "shippingbox")
            }
            .tint(.green)
        }
    }
}

struct BuiltinSnippetRow: View {
    let snippet: CodeSnippet
    let language: CodeLanguage
    let theme: EditorTheme
    let onInsert: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Image(systemName: "curlybraces.square.fill")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(theme.accent)
                Text(snippet.title)
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .lineLimit(1)
                Spacer(minLength: 0)
            }

            Text(snippet.trigger)
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundStyle(theme.secondaryText)
                .lineLimit(1)

            SnippetCodePreview(
                code: snippet.insertText,
                language: language,
                theme: theme
            )
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 7)
        .contentShape(Rectangle())
        .onTapGesture {
            onInsert()
        }
        .foregroundStyle(theme.selectedText)
        .background(
            theme.controlBackground,
            in: RoundedRectangle(cornerRadius: 7)
        )
        .contextMenu {
            Button {
                onInsert()
            } label: {
                Label("Insert", systemImage: "text.insert")
            }
            Button {
                UIPasteboard.general.string = snippet.insertText
            } label: {
                Label("Copy", systemImage: "doc.on.doc")
            }
        }
        .swipeActions(edge: .leading) {
            Button(action: onInsert) {
                Label("Insert", systemImage: "text.insert")
            }
            .tint(.green)
        }
    }
}

struct SnippetRow: View {
    let snippet: UserSnippet
    let language: CodeLanguage
    let theme: EditorTheme
    let onInsert: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Image(systemName: "tray.full")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(theme.accent)
                Text(snippet.title)
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .lineLimit(1)
                Spacer(minLength: 0)
            }

            if !snippet.trigger.isEmpty {
                Text(snippet.trigger)
                    .font(
                        .system(
                            size: 10,
                            weight: .semibold,
                            design: .monospaced
                        )
                    )
                    .foregroundStyle(theme.secondaryText)
                    .lineLimit(1)
            } else if snippet.code.trimmingCharacters(
                in: .whitespacesAndNewlines
            ).isEmpty {
                Text("empty - uses boilerplate")
                    .font(
                        .system(
                            size: 10,
                            weight: .semibold,
                            design: .monospaced
                        )
                    )
                    .foregroundStyle(theme.warning)
                    .lineLimit(1)
            }

            SnippetCodePreview(
                code: snippet.code,
                language: language,
                theme: theme
            )
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 7)
        .contentShape(Rectangle())
        .onTapGesture {
            onInsert()
        }
        .foregroundStyle(theme.selectedText)
        .background(
            theme.controlBackground,
            in: RoundedRectangle(cornerRadius: 7)
        )
        .contextMenu {
            Button {
                onInsert()
            } label: {
                Label("Insert", systemImage: "text.insert")
            }
            Button {
                UIPasteboard.general.string = snippet.code
            } label: {
                Label("Copy", systemImage: "doc.on.doc")
            }
            Button(action: onEdit) {
                Label("Edit", systemImage: "pencil")
            }
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
        .swipeActions(edge: .leading) {
            Button(action: onEdit) {
                Label("Edit", systemImage: "pencil")
            }
            .tint(.blue)

            Button(action: onInsert) {
                Label("Insert", systemImage: "text.insert")
            }
            .tint(.green)
        }
    }
}

struct ProjectItemRow: View {
    let item: ProjectItem
    let isSelected: Bool
    let exportURL: URL?
    let theme: EditorTheme
    let onSelect: () -> Void
    let onRename: () -> Void
    let onDelete: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 8) {
                Image(systemName: item.kind == .folder ? "folder" : "doc.text")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(
                        item.kind == .folder ? theme.warning : theme.accent
                    )
                Text(item.name)
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .lineLimit(1)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 8)
            .frame(height: 32)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(isSelected ? theme.selectedText : theme.secondaryText)
        .background(
            isSelected ? theme.accent.opacity(0.18) : Color.clear,
            in: RoundedRectangle(cornerRadius: 7)
        )
        .contextMenu {
            Button {
                onRename()
            } label: {
                Label("Rename", systemImage: "pencil")
            }

            if item.kind == .file, let exportURL {
                ShareLink(item: exportURL) {
                    Label("Export", systemImage: "square.and.arrow.up")
                }
            }

            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }

            Button {
                onRename()
            } label: {
                Label("Rename", systemImage: "pencil")
            }
            .tint(.blue)
        }
        .swipeActions(edge: .leading) {
            if item.kind == .file, let exportURL {
                ShareLink(item: exportURL) {
                    Label("Export", systemImage: "square.and.arrow.up")
                }
                .tint(.green)
            }
        }
    }
}

struct CodeEditorView: UIViewRepresentable {
    @Binding var text: String
    @Binding var cursorLocation: Int
    let language: CodeLanguage
    let theme: EditorTheme

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.autocorrectionType = .no
        textView.autocapitalizationType = .none
        textView.smartQuotesType = .no
        textView.smartDashesType = .no
        textView.keyboardType = .asciiCapable
        textView.alwaysBounceVertical = true
        textView.textContainerInset = UIEdgeInsets(
            top: 18,
            left: 14,
            bottom: 30,
            right: 14
        )
        textView.textContainer.lineFragmentPadding = 0
        textView.backgroundColor = UIColor(theme.editorBackground)
        textView.tintColor = UIColor(theme.accent)
        textView.isEditable = true
        textView.isSelectable = true
        textView.font = .monospacedSystemFont(ofSize: 15, weight: .regular)
        applyHighlight(to: textView)
        return textView
    }

    func updateUIView(_ textView: UITextView, context: Context) {
        context.coordinator.parent = self
        textView.backgroundColor = UIColor(theme.editorBackground)
        textView.tintColor = UIColor(theme.accent)

        if textView.text != text
            || context.coordinator.lastLanguageID != language.id
            || context.coordinator.lastThemeID != theme.id
        {
            applyHighlight(to: textView)
            context.coordinator.lastLanguageID = language.id
            context.coordinator.lastThemeID = theme.id
        }
        if textView.selectedRange.location != cursorLocation
            && cursorLocation <= textView.text.utf16.count
        {
            textView.selectedRange = NSRange(
                location: cursorLocation,
                length: 0
            )
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    private func applyHighlight(to textView: UITextView) {
        let selectedRange = textView.selectedRange
        let contentOffset = textView.contentOffset
        let highlighted = SyntaxHighlighter.highlight(
            text,
            language: language,
            theme: theme
        )
        textView.attributedText = highlighted
        textView.typingAttributes = [
            .font: UIFont.monospacedSystemFont(ofSize: 15, weight: .regular),
            .foregroundColor: UIColor(theme.codeText),
        ]
        textView.selectedRange =
            selectedRange.location <= highlighted.length
            ? selectedRange : NSRange(location: highlighted.length, length: 0)
        textView.setContentOffset(contentOffset, animated: false)
    }

    final class Coordinator: NSObject, UITextViewDelegate {
        private static let htmlSelfClosingTags: Set<String> = {
            let tagNames =
                "area base br col embed hr img input link meta param source track wbr"
            return Set(tagNames.split(separator: " ").map(String.init))
        }()

        var parent: CodeEditorView
        var lastLanguageID: String
        var lastThemeID: String

        init(parent: CodeEditorView) {
            self.parent = parent
            self.lastLanguageID = parent.language.id
            self.lastThemeID = parent.theme.id
        }

        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.text
            parent.cursorLocation = textView.selectedRange.location
            parent.applyHighlight(to: textView)
            lastLanguageID = parent.language.id
            lastThemeID = parent.theme.id
        }

        func textViewDidChangeSelection(_ textView: UITextView) {
            parent.cursorLocation = textView.selectedRange.location
        }

        func textView(
            _ textView: UITextView,
            shouldChangeTextIn range: NSRange,
            replacementText: String
        ) -> Bool {
            if let pairedInsertion = pairedInsertion(
                for: replacementText,
                in: textView,
                range: range
            ) {
                insert(
                    pairedInsertion.text,
                    cursorOffset: pairedInsertion.cursorOffset,
                    in: textView,
                    range: range
                )
                return false
            }

            if replacementText == ">", parent.language.id == "html",
                let closingTag = closingTagInsertion(in: textView, range: range)
            {
                insert(
                    ">\(closingTag)",
                    cursorOffset: 1,
                    in: textView,
                    range: range
                )
                return false
            }

            return true
        }

        private func pairedInsertion(
            for text: String,
            in textView: UITextView,
            range: NSRange
        ) -> (text: String, cursorOffset: Int)? {
            guard range.length == 0 else { return nil }

            switch text {
            case "(": return ("()", 1)
            case "[": return ("[]", 1)
            case "{": return ("{}", 1)
            case "\"": return ("\"\"", 1)
            case "'": return ("''", 1)
            case "\n":
                return newlineInsertion(in: textView, range: range)
            default:
                return nil
            }
        }

        private func newlineInsertion(in textView: UITextView, range: NSRange)
            -> (text: String, cursorOffset: Int)?
        {
            let source = textView.text ?? ""
            let lineIndent = indentationBeforeCursor(
                in: source,
                cursorLocation: range.location
            )
            let extraIndent =
                previousCharacter(in: source, cursorLocation: range.location)
                    == "{" ? "  " : ""
            let insertion = "\n\(lineIndent)\(extraIndent)"
            return (insertion, insertion.utf16.count)
        }

        private func closingTagInsertion(
            in textView: UITextView,
            range: NSRange
        ) -> String? {
            let source = textView.text ?? ""
            guard
                let tagName = openTagNameBeforeCursor(
                    in: source,
                    cursorLocation: range.location
                )
            else { return nil }
            guard !Self.htmlSelfClosingTags.contains(tagName) else {
                return nil
            }
            return "</\(tagName)>"
        }

        private func insert(
            _ insertion: String,
            cursorOffset: Int,
            in textView: UITextView,
            range: NSRange
        ) {
            guard let textRange = Range(range, in: textView.text) else {
                return
            }
            var updatedText = textView.text ?? ""
            updatedText.replaceSubrange(textRange, with: insertion)
            textView.text = updatedText
            textView.selectedRange = NSRange(
                location: range.location + cursorOffset,
                length: 0
            )
            parent.text = updatedText
            parent.cursorLocation = textView.selectedRange.location
            parent.applyHighlight(to: textView)
        }

        private func openTagNameBeforeCursor(
            in source: String,
            cursorLocation: Int
        ) -> String? {
            guard
                let cursorIndex = stringIndex(
                    in: source,
                    utf16Offset: cursorLocation
                )
            else { return nil }
            let prefix = source[..<cursorIndex]
            guard let openBracket = prefix.lastIndex(of: "<") else {
                return nil
            }
            let tagText = prefix[source.index(after: openBracket)...]
            guard !tagText.contains(">"), !tagText.hasPrefix("/"),
                !tagText.hasPrefix("!")
            else { return nil }
            let tagName = tagText.prefix { character in
                character.isLetter || character.isNumber || character == "-"
            }
            return tagName.isEmpty ? nil : String(tagName).lowercased()
        }

        private func indentationBeforeCursor(
            in source: String,
            cursorLocation: Int
        ) -> String {
            guard
                let cursorIndex = stringIndex(
                    in: source,
                    utf16Offset: cursorLocation
                )
            else { return "" }
            let prefix = source[..<cursorIndex]
            let lineStart =
                prefix.lastIndex(of: "\n").map { source.index(after: $0) }
                ?? source.startIndex
            return String(
                source[lineStart..<cursorIndex].prefix {
                    $0 == " " || $0 == "\t"
                }
            )
        }

        private func previousCharacter(in source: String, cursorLocation: Int)
            -> Character?
        {
            guard
                let cursorIndex = stringIndex(
                    in: source,
                    utf16Offset: cursorLocation
                ), cursorIndex > source.startIndex
            else { return nil }
            return source[source.index(before: cursorIndex)]
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
    }
}

struct EditorTheme: Identifiable, Equatable {
    let id: String
    let name: String
    let preferredScheme: ColorScheme
    let background: Color
    let headerBackground: Color
    let toolbarBackground: Color
    let panelBackground: Color
    let editorBackground: Color
    let consoleBackground: Color
    let consoleHeader: Color
    let controlBackground: Color
    let border: Color
    let primaryText: Color
    let secondaryText: Color
    let selectedText: Color
    let codeText: Color
    let keyword: Color
    let string: Color
    let number: Color
    let comment: Color
    let tag: Color
    let accent: Color
    let success: Color
    let warning: Color
    let error: Color

    static let techDark = EditorTheme(
        id: "techDark",
        name: "Tech Dark",
        preferredScheme: .dark,
        background: Color(red: 0.02, green: 0.03, blue: 0.025),
        headerBackground: Color(red: 0.025, green: 0.04, blue: 0.035),
        toolbarBackground: Color(red: 0.035, green: 0.055, blue: 0.045),
        panelBackground: Color(red: 0.045, green: 0.065, blue: 0.055),
        editorBackground: Color(red: 0.015, green: 0.02, blue: 0.018),
        consoleBackground: Color(red: 0.01, green: 0.015, blue: 0.013),
        consoleHeader: Color(red: 0.035, green: 0.055, blue: 0.045),
        controlBackground: Color.white.opacity(0.07),
        border: Color.white.opacity(0.13),
        primaryText: Color(red: 0.88, green: 0.95, blue: 0.90),
        secondaryText: Color(red: 0.54, green: 0.66, blue: 0.58),
        selectedText: Color(red: 0.86, green: 1.00, blue: 0.90),
        codeText: Color(red: 0.84, green: 0.90, blue: 0.86),
        keyword: Color(red: 0.20, green: 0.85, blue: 0.45),
        string: Color(red: 0.95, green: 0.72, blue: 0.35),
        number: Color(red: 0.30, green: 0.75, blue: 0.95),
        comment: Color(red: 0.40, green: 0.50, blue: 0.44),
        tag: Color(red: 0.00, green: 0.95, blue: 0.52),
        accent: Color(red: 0.08, green: 0.95, blue: 0.42),
        success: Color(red: 0.08, green: 0.95, blue: 0.42),
        warning: Color(red: 1.00, green: 0.78, blue: 0.22),
        error: Color(red: 1.00, green: 0.25, blue: 0.25)
    )

    static let codeLight = EditorTheme(
        id: "codeLight",
        name: "Light",
        preferredScheme: .light,
        background: Color(red: 0.95, green: 0.97, blue: 0.95),
        headerBackground: Color.white,
        toolbarBackground: Color(red: 0.90, green: 0.94, blue: 0.91),
        panelBackground: Color(red: 0.96, green: 0.98, blue: 0.96),
        editorBackground: Color(red: 0.99, green: 1.00, blue: 0.99),
        consoleBackground: Color(red: 0.96, green: 0.98, blue: 0.96),
        consoleHeader: Color(red: 0.88, green: 0.93, blue: 0.89),
        controlBackground: Color.black.opacity(0.06),
        border: Color.black.opacity(0.13),
        primaryText: Color(red: 0.07, green: 0.10, blue: 0.08),
        secondaryText: Color(red: 0.30, green: 0.38, blue: 0.33),
        selectedText: Color(red: 0.02, green: 0.15, blue: 0.07),
        codeText: Color(red: 0.08, green: 0.10, blue: 0.09),
        keyword: Color(red: 0.00, green: 0.45, blue: 0.20),
        string: Color(red: 0.70, green: 0.33, blue: 0.00),
        number: Color(red: 0.00, green: 0.35, blue: 0.78),
        comment: Color(red: 0.42, green: 0.50, blue: 0.45),
        tag: Color(red: 0.00, green: 0.45, blue: 0.20),
        accent: Color(red: 0.00, green: 0.60, blue: 0.25),
        success: Color(red: 0.00, green: 0.55, blue: 0.23),
        warning: Color(red: 0.75, green: 0.46, blue: 0.00),
        error: Color(red: 0.84, green: 0.05, blue: 0.05)
    )

    static let matrix = EditorTheme(
        id: "matrix",
        name: "Matrix",
        preferredScheme: .dark,
        background: Color.black,
        headerBackground: Color(red: 0.00, green: 0.04, blue: 0.02),
        toolbarBackground: Color(red: 0.00, green: 0.07, blue: 0.035),
        panelBackground: Color(red: 0.00, green: 0.05, blue: 0.025),
        editorBackground: Color.black,
        consoleBackground: Color(red: 0.00, green: 0.025, blue: 0.01),
        consoleHeader: Color(red: 0.00, green: 0.08, blue: 0.04),
        controlBackground: Color.green.opacity(0.08),
        border: Color.green.opacity(0.25),
        primaryText: Color(red: 0.82, green: 1.00, blue: 0.84),
        secondaryText: Color(red: 0.40, green: 0.70, blue: 0.45),
        selectedText: Color.green,
        codeText: Color(red: 0.74, green: 1.00, blue: 0.78),
        keyword: Color.green,
        string: Color(red: 0.74, green: 0.95, blue: 0.35),
        number: Color(red: 0.22, green: 0.78, blue: 0.40),
        comment: Color(red: 0.25, green: 0.45, blue: 0.28),
        tag: Color(red: 0.20, green: 1.00, blue: 0.45),
        accent: Color.green,
        success: Color.green,
        warning: Color.yellow,
        error: Color.red
    )

    static let classicDark = EditorTheme(
        id: "classicDark",
        name: "Classic Dark",
        preferredScheme: .dark,
        background: Color(red: 0.11, green: 0.11, blue: 0.12),
        headerBackground: Color(red: 0.14, green: 0.14, blue: 0.15),
        toolbarBackground: Color(red: 0.16, green: 0.16, blue: 0.17),
        panelBackground: Color(red: 0.13, green: 0.13, blue: 0.14),
        editorBackground: Color(red: 0.08, green: 0.08, blue: 0.09),
        consoleBackground: Color(red: 0.07, green: 0.07, blue: 0.08),
        consoleHeader: Color(red: 0.13, green: 0.13, blue: 0.14),
        controlBackground: Color.white.opacity(0.08),
        border: Color.white.opacity(0.16),
        primaryText: Color(red: 0.92, green: 0.92, blue: 0.94),
        secondaryText: Color(red: 0.64, green: 0.66, blue: 0.70),
        selectedText: Color.white,
        codeText: Color(red: 0.88, green: 0.88, blue: 0.90),
        keyword: Color(red: 0.55, green: 0.72, blue: 1.00),
        string: Color(red: 0.92, green: 0.68, blue: 0.44),
        number: Color(red: 0.72, green: 0.86, blue: 0.55),
        comment: Color(red: 0.50, green: 0.54, blue: 0.58),
        tag: Color(red: 0.44, green: 0.82, blue: 0.72),
        accent: Color(red: 0.44, green: 0.72, blue: 1.00),
        success: Color(red: 0.44, green: 0.82, blue: 0.55),
        warning: Color(red: 1.00, green: 0.76, blue: 0.32),
        error: Color(red: 1.00, green: 0.36, blue: 0.36)
    )

    static let dataStream = EditorTheme(
        id: "dataStream",
        name: "DataStream",
        preferredScheme: .dark,
        background: Color(red: 0.01, green: 0.04, blue: 0.08),
        headerBackground: Color(red: 0.02, green: 0.07, blue: 0.13),
        toolbarBackground: Color(red: 0.02, green: 0.08, blue: 0.16),
        panelBackground: Color(red: 0.02, green: 0.06, blue: 0.12),
        editorBackground: Color(red: 0.00, green: 0.025, blue: 0.055),
        consoleBackground: Color(red: 0.00, green: 0.02, blue: 0.045),
        consoleHeader: Color(red: 0.02, green: 0.07, blue: 0.13),
        controlBackground: Color.blue.opacity(0.12),
        border: Color.cyan.opacity(0.24),
        primaryText: Color(red: 0.84, green: 0.94, blue: 1.00),
        secondaryText: Color(red: 0.46, green: 0.67, blue: 0.82),
        selectedText: Color(red: 0.88, green: 0.98, blue: 1.00),
        codeText: Color(red: 0.78, green: 0.90, blue: 0.98),
        keyword: Color(red: 0.30, green: 0.65, blue: 1.00),
        string: Color(red: 0.48, green: 0.92, blue: 1.00),
        number: Color(red: 0.66, green: 0.82, blue: 1.00),
        comment: Color(red: 0.34, green: 0.46, blue: 0.58),
        tag: Color(red: 0.16, green: 0.86, blue: 1.00),
        accent: Color(red: 0.10, green: 0.64, blue: 1.00),
        success: Color(red: 0.26, green: 0.92, blue: 0.78),
        warning: Color(red: 0.92, green: 0.78, blue: 0.32),
        error: Color(red: 1.00, green: 0.28, blue: 0.36)
    )

    static let electroYellow = EditorTheme(
        id: "electroYellow",
        name: "Electro Yellow",
        preferredScheme: .dark,
        background: Color(red: 0.06, green: 0.055, blue: 0.015),
        headerBackground: Color(red: 0.10, green: 0.09, blue: 0.02),
        toolbarBackground: Color(red: 0.13, green: 0.11, blue: 0.025),
        panelBackground: Color(red: 0.09, green: 0.08, blue: 0.025),
        editorBackground: Color(red: 0.035, green: 0.032, blue: 0.012),
        consoleBackground: Color(red: 0.028, green: 0.025, blue: 0.010),
        consoleHeader: Color(red: 0.10, green: 0.09, blue: 0.02),
        controlBackground: Color.yellow.opacity(0.10),
        border: Color.yellow.opacity(0.28),
        primaryText: Color(red: 1.00, green: 0.97, blue: 0.78),
        secondaryText: Color(red: 0.72, green: 0.66, blue: 0.42),
        selectedText: Color(red: 1.00, green: 1.00, blue: 0.84),
        codeText: Color(red: 0.96, green: 0.94, blue: 0.76),
        keyword: Color(red: 1.00, green: 0.88, blue: 0.12),
        string: Color(red: 0.56, green: 0.94, blue: 0.46),
        number: Color(red: 0.42, green: 0.82, blue: 1.00),
        comment: Color(red: 0.48, green: 0.45, blue: 0.28),
        tag: Color(red: 1.00, green: 0.78, blue: 0.00),
        accent: Color(red: 1.00, green: 0.90, blue: 0.08),
        success: Color(red: 0.52, green: 0.95, blue: 0.36),
        warning: Color(red: 1.00, green: 0.72, blue: 0.00),
        error: Color(red: 1.00, green: 0.25, blue: 0.18)
    )

    static let bloodRed = EditorTheme(
        id: "bloodRed",
        name: "Blood Dark",
        preferredScheme: .dark,
        background: Color(red: 0.055, green: 0.005, blue: 0.010),
        headerBackground: Color(red: 0.10, green: 0.015, blue: 0.020),
        toolbarBackground: Color(red: 0.13, green: 0.018, blue: 0.025),
        panelBackground: Color(red: 0.085, green: 0.012, blue: 0.018),
        editorBackground: Color(red: 0.028, green: 0.004, blue: 0.007),
        consoleBackground: Color(red: 0.020, green: 0.002, blue: 0.005),
        consoleHeader: Color(red: 0.09, green: 0.012, blue: 0.018),
        controlBackground: Color.red.opacity(0.10),
        border: Color.red.opacity(0.25),
        primaryText: Color(red: 1.00, green: 0.86, blue: 0.86),
        secondaryText: Color(red: 0.68, green: 0.42, blue: 0.42),
        selectedText: Color(red: 1.00, green: 0.92, blue: 0.90),
        codeText: Color(red: 0.94, green: 0.82, blue: 0.82),
        keyword: Color(red: 1.00, green: 0.24, blue: 0.28),
        string: Color(red: 1.00, green: 0.62, blue: 0.38),
        number: Color(red: 0.92, green: 0.45, blue: 0.82),
        comment: Color(red: 0.48, green: 0.28, blue: 0.28),
        tag: Color(red: 1.00, green: 0.36, blue: 0.36),
        accent: Color(red: 0.95, green: 0.08, blue: 0.12),
        success: Color(red: 0.54, green: 0.88, blue: 0.42),
        warning: Color(red: 1.00, green: 0.70, blue: 0.22),
        error: Color(red: 1.00, green: 0.10, blue: 0.10)
    )

    static let aquaCyan = EditorTheme(
        id: "aquaCyan",
        name: "Aqua Cyan",
        preferredScheme: .dark,
        background: Color(red: 0.00, green: 0.055, blue: 0.06),
        headerBackground: Color(red: 0.00, green: 0.09, blue: 0.10),
        toolbarBackground: Color(red: 0.00, green: 0.12, blue: 0.13),
        panelBackground: Color(red: 0.00, green: 0.08, blue: 0.09),
        editorBackground: Color(red: 0.00, green: 0.035, blue: 0.04),
        consoleBackground: Color(red: 0.00, green: 0.028, blue: 0.032),
        consoleHeader: Color(red: 0.00, green: 0.09, blue: 0.10),
        controlBackground: Color.cyan.opacity(0.10),
        border: Color.cyan.opacity(0.26),
        primaryText: Color(red: 0.82, green: 1.00, blue: 0.98),
        secondaryText: Color(red: 0.45, green: 0.72, blue: 0.72),
        selectedText: Color(red: 0.88, green: 1.00, blue: 1.00),
        codeText: Color(red: 0.80, green: 0.96, blue: 0.95),
        keyword: Color(red: 0.12, green: 0.96, blue: 0.92),
        string: Color(red: 0.70, green: 0.92, blue: 0.45),
        number: Color(red: 0.42, green: 0.70, blue: 1.00),
        comment: Color(red: 0.30, green: 0.52, blue: 0.52),
        tag: Color(red: 0.18, green: 1.00, blue: 0.88),
        accent: Color(red: 0.00, green: 0.88, blue: 0.92),
        success: Color(red: 0.18, green: 0.92, blue: 0.62),
        warning: Color(red: 1.00, green: 0.82, blue: 0.24),
        error: Color(red: 1.00, green: 0.30, blue: 0.30)
    )

    static let highContrast = EditorTheme(
        id: "highContrast",
        name: "High Contrast",
        preferredScheme: .dark,
        background: Color.black,
        headerBackground: Color.black,
        toolbarBackground: Color(red: 0.04, green: 0.04, blue: 0.04),
        panelBackground: Color.black,
        editorBackground: Color.black,
        consoleBackground: Color.black,
        consoleHeader: Color(red: 0.04, green: 0.04, blue: 0.04),
        controlBackground: Color.white.opacity(0.14),
        border: Color.white.opacity(0.52),
        primaryText: Color.white,
        secondaryText: Color(red: 0.86, green: 0.86, blue: 0.86),
        selectedText: Color.white,
        codeText: Color.white,
        keyword: Color.yellow,
        string: Color(red: 0.20, green: 1.00, blue: 0.20),
        number: Color.cyan,
        comment: Color(red: 0.82, green: 0.82, blue: 0.82),
        tag: Color(red: 1.00, green: 0.70, blue: 0.00),
        accent: Color.yellow,
        success: Color.green,
        warning: Color.yellow,
        error: Color(red: 1.00, green: 0.18, blue: 0.18)
    )

    static let all: [EditorTheme] = [
        .techDark,
        .classicDark,
        .codeLight,
        .matrix,
        .dataStream,
        .electroYellow,
        .bloodRed,
        .aquaCyan,
        .highContrast,
    ]
}

#Preview {
    HomeView(model: EditorModel())
}
