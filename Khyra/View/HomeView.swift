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
    @State private var snippetSelectionLength = 0
    @State private var showSavedToast = false
    @State private var showConsoleSheet = false
    @State private var showCleanCodeConfirmation = false
    @State private var isEditorFocused = false
    @State private var focusModeEnabled = false
    @State private var wrapsLongLines = true
    @State private var editorFontSize: CGFloat = 15
    @State private var showFindReplace = false
    @State private var showGoToLine = false
    @State private var showRunPreview = false
    @State private var showAISelection = false
    @State private var selectedAIAction: EditorAIAction = .explain
    @State private var showLayoutCustomization = false
    @State private var workspacePanels = EditorWorkspacePanel.allCases
    @State private var showsSuggestions = true
    @State private var showsInlineDiagnostics = true

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

    private var selectionLength: Binding<Int> {
        Binding(
            get: { model.editorSelectionLength },
            set: { model.editorSelectionLength = $0 }
        )
    }

    var body: some View {
        @Bindable var model = model

        ZStack {
            model.selectedTheme.background
                .ignoresSafeArea()

            HStack(spacing: 0) {
                if model.showNavigator && !(focusModeEnabled && isEditorFocused)
                {
                    ProjectNavigatorView(
                        model: model,
                        strings: model.appStrings,
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
                        theme: model.selectedTheme,
                        strings: model.appStrings
                    )

                    if showsSuggestions {
                        SuggestionsBarView(
                            suggestions: model.suggestions(),
                            theme: model.selectedTheme,
                            onSelect: model.applySuggestion
                        )
                    }

                    CodeEditorView(
                        text: $model.activeCodeText,
                        cursorLocation: $model.cursorLocation,
                        selectionLength: $model.editorSelectionLength,
                        language: model.selectedLanguage,
                        theme: model.selectedTheme,
                        wrapsLongLines: wrapsLongLines,
                        fontSize: $editorFontSize,
                        issues: model.issues,
                        onFocusChange: { isEditorFocused = $0 }
                    )
                    .background(model.selectedTheme.editorBackground)

                    if showsInlineDiagnostics {
                        InlineDiagnosticsView(
                            issues: model.issues,
                            theme: model.selectedTheme,
                            isGerman: model.resolvedAppLanguageCode == "de",
                            onSelect: model.jumpToIssue,
                            onQuickFix: { issue in
                                if !model.applyQuickFix(for: issue) {
                                    selectedAIAction = .repair
                                    showAISelection = true
                                }
                            },
                            onAIFix: { issue in
                                model.jumpToIssue(issue)
                                model.editorSelectionLength =
                                    lineLength(for: issue.line)
                                selectedAIAction = .repair
                                showAISelection = true
                            }
                        )
                    }

                    if !(focusModeEnabled && isEditorFocused) {
                        if model.showConsole {
                            ConsoleView(
                                issues: model.issues,
                                theme: model.selectedTheme,
                                strings: model.appStrings,
                                versions: model.codeVersions,
                                currentCode: model.activeCode.wrappedValue,
                                onToggle: {
                                    withAnimation(.snappy) {
                                        model.showConsole.toggle()
                                    }
                                },
                                onSaveVersion: { name in
                                    model.saveCodeVersion(title: name)
                                    showSavedFeedback()
                                },
                                onRestoreVersion: { version in
                                    model.restoreCodeVersion(version)
                                    showSavedFeedback()
                                },
                                onDeleteVersion: model.deleteCodeVersion,
                                onIssueSelect: model.jumpToIssue,
                                onOpenSheet: { showConsoleSheet = true },
                                languageForVersion: { version in
                                    model.language(for: version.languageID)
                                }
                            )
                            .frame(height: 178)
                        } else {
                            ConsoleCollapsedBar(
                                theme: model.selectedTheme,
                                strings: model.appStrings
                            ) {
                                withAnimation(.snappy) {
                                    model.showConsole.toggle()
                                }
                            }
                        }
                    }
                }
            }

            if showSavedToast {
                VStack {
                    Spacer()
                    SaveToast(
                        theme: model.selectedTheme,
                        strings: model.appStrings
                    )
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
                    selectionLength: $snippetSelectionLength,
                    language: model.languageStore.languages.first {
                        $0.id == snippetDraft?.languageID
                    } ?? model.selectedLanguage,
                    theme: model.selectedTheme,
                    strings: model.appStrings,
                    onSave: saveSnippetDraft,
                    onClose: { snippetDraft = nil }
                )
            }

            if showCleanCodeConfirmation {
                CleanCodeConfirmationModal(
                    plan: model.cleanCodePlan,
                    theme: model.selectedTheme,
                    strings: model.appStrings,
                    onConfirm: {
                        model.cleanCodeRefactor()
                        showCleanCodeConfirmation = false
                        withAnimation(.snappy) {
                            model.showNavigator = true
                        }
                        showSavedFeedback()
                    },
                    onCancel: {
                        showCleanCodeConfirmation = false
                    }
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
                .accessibilityLabel(model.appStrings.toggleProjectNavigator)
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    model.insertBoilerplate()
                } label: {
                    Image(systemName: "wand.and.stars")
                }
                .accessibilityLabel(model.appStrings.insertBoilerplate)
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    model.saveProject()
                    showSavedFeedback()
                } label: {
                    Image(systemName: "square.and.arrow.down")
                }
                .accessibilityLabel(model.appStrings.saveProject)
                .keyboardShortcut("s", modifiers: .command)
            }

            ToolbarItem(placement: .topBarTrailing) {
                ShareLink(item: model.activeCode.wrappedValue) {
                    Image(systemName: "square.and.arrow.up")
                }
                .accessibilityLabel(model.appStrings.shareCode)
            }

            ToolbarItem(placement: .topBarTrailing) {
                Menu {

                    Button {
                        model.formatActiveDocument()
                    } label: {
                        Label(
                            model.appStrings.format,
                            systemImage: "text.alignleft"
                        )
                    }

                    Button {
                        showCleanCodeConfirmation = true
                    } label: {
                        Label(
                            model.appStrings.cleanCode,
                            systemImage: "sparkles"
                        )
                    }

                    Divider()

                    Button {
                        showFindReplace = true
                    } label: {
                        Label(
                            model.resolvedAppLanguageCode == "de"
                                ? "Suchen & Ersetzen" : "Find & Replace",
                            systemImage: "magnifyingglass"
                        )
                    }
                    .keyboardShortcut("f", modifiers: .command)

                    Button {
                        showGoToLine = true
                    } label: {
                        Label(
                            model.resolvedAppLanguageCode == "de"
                                ? "Gehe zu Zeile" : "Go to Line",
                            systemImage: "arrow.right.to.line"
                        )
                    }
                    .keyboardShortcut("l", modifiers: .command)

                    Button {
                        showRunPreview = true
                    } label: {
                        Label(
                            model.appStrings.preview,
                            systemImage: "play.fill"
                        )
                    }
                    .keyboardShortcut(.return, modifiers: .command)

                    Divider()

                    Toggle(isOn: $wrapsLongLines) {
                        Label(
                            model.resolvedAppLanguageCode == "de"
                                ? "Lange Zeilen umbrechen" : "Wrap long lines",
                            systemImage: "text.word.spacing"
                        )
                    }

                    Toggle(isOn: $focusModeEnabled) {
                        Label(
                            model.resolvedAppLanguageCode == "de"
                                ? "Fokusmodus" : "Focus mode",
                            systemImage: "viewfinder"
                        )
                    }

                    Button {
                        selectedAIAction = .explain
                        showAISelection = true
                    } label: {
                        Label(
                            model.resolvedAppLanguageCode == "de"
                                ? "Auswahl mit KI" : "AI for Selection",
                            systemImage: "apple.intelligence"
                        )
                    }
                    .disabled(model.editorSelectionLength == 0)

                    Button {
                        showLayoutCustomization = true
                    } label: {
                        Label(
                            model.resolvedAppLanguageCode == "de"
                                ? "Layout bearbeiten" : "Edit Layout",
                            systemImage: "rectangle.3.group"
                        )
                    }

                    NavigationLink(value: AppRoute.preview) {
                        Label(model.appStrings.preview, systemImage: "safari")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .accessibilityLabel(model.appStrings.moreActions)
            }
        }
        .sheet(isPresented: $showConsoleSheet) {
            ConsoleView(
                issues: model.issues,
                theme: model.selectedTheme,
                strings: model.appStrings,
                versions: model.codeVersions,
                currentCode: model.activeCode.wrappedValue,
                onToggle: {
                    showConsoleSheet = false
                },
                onSaveVersion: { name in
                    model.saveCodeVersion(title: name)
                    showSavedFeedback()
                },
                onRestoreVersion: { version in
                    model.restoreCodeVersion(version)
                    showSavedFeedback()
                },
                onDeleteVersion: { version in
                    model.deleteCodeVersion(version)
                },
                onIssueSelect: { issue in
                    model.jumpToIssue(issue)
                },
                languageForVersion: { version in
                    model.language(for: version.languageID)
                }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
            .presentationBackground(model.selectedTheme.background)
            .preferredColorScheme(model.selectedTheme.preferredScheme)
        }
        .sheet(isPresented: $showFindReplace) {
            EditorSearchToolsView(
                code: model.activeCode,
                cursorLocation: cursorLocation,
                selectionLength: selectionLength,
                isGerman: model.resolvedAppLanguageCode == "de"
            )
            .preferredColorScheme(model.selectedTheme.preferredScheme)
        }
        .sheet(isPresented: $showGoToLine) {
            GoToLineView(
                cursorLocation: cursorLocation,
                selectionLength: selectionLength,
                code: model.activeCode.wrappedValue,
                isGerman: model.resolvedAppLanguageCode == "de"
            )
            .preferredColorScheme(model.selectedTheme.preferredScheme)
        }
        .sheet(isPresented: $showRunPreview) {
            NavigationStack {
                WebPreviewScreen(model: model)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button(model.appStrings.cancel) {
                                showRunPreview = false
                            }
                        }
                    }
            }
            .preferredColorScheme(model.selectedTheme.preferredScheme)
        }
        .sheet(isPresented: $showAISelection) {
            EditorAISelectionView(
                model: model,
                initialAction: selectedAIAction
            )
        }
        .sheet(isPresented: $showLayoutCustomization) {
            EditorLayoutCustomizationView(
                panels: $workspacePanels,
                showsSuggestions: $showsSuggestions,
                showsDiagnostics: $showsInlineDiagnostics,
                isGerman: model.resolvedAppLanguageCode == "de"
            )
            .preferredColorScheme(model.selectedTheme.preferredScheme)
        }
        .preferredColorScheme(model.selectedTheme.preferredScheme)
    }

    private func lineLength(for line: Int) -> Int {
        let lines = model.activeCode.wrappedValue.components(
            separatedBy: .newlines
        )
        guard lines.indices.contains(line - 1) else { return 0 }
        return lines[line - 1].utf16.count
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
    let strings: AppStrings
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
                Text(selectedTab.title(strings: strings))
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

                        Button(strings.newFolder) {
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
                SnippetLibraryPanel(
                    model: model,
                    strings: strings,
                    onEditSnippet: onEditSnippet
                )
            }
        }
        .foregroundStyle(model.selectedTheme.primaryText)
        .background(model.selectedTheme.panelBackground)
        .overlay(alignment: .trailing) {
            Rectangle()
                .fill(model.selectedTheme.border)
                .frame(width: 1)
        }
        .alert(strings.newFile, isPresented: newFileAlertBinding) {
            TextField(strings.fileName, text: $newFileName)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            Button(strings.create) {
                if let newFileLanguage {
                    model.addFile(language: newFileLanguage, name: newFileName)
                }
                self.newFileLanguage = nil
            }
            Button(strings.cancel, role: .cancel) {
                newFileLanguage = nil
            }
        } message: {
            Text(strings.chooseFileName)
        }
        .alert(strings.rename, isPresented: renameAlertBinding) {
            TextField(strings.name, text: $renameText)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            Button(strings.save) {
                if let renameItem {
                    model.renameProjectItem(renameItem, to: renameText)
                }
                self.renameItem = nil
            }
            Button(strings.cancel, role: .cancel) {
                renameItem = nil
            }
        }
    }

    private var filesList: some View {
        Group {
            if model.projectItems.isEmpty {
                ContentUnavailableView(
                    strings.noFiles,
                    systemImage: "folder",
                    description: Text(strings.noFilesHint)
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
                            strings: strings,
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

    func title(strings: AppStrings) -> String {
        switch self {
        case .files: strings.files
        case .snippets: strings.snippets
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
    @Binding var selectionLength: Int
    let language: CodeLanguage
    let theme: EditorTheme
    let strings: AppStrings
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
                ? strings.newSnippet : strings.editSnippet,
            theme: theme,
            onClose: onClose
        ) {
            VStack(spacing: 12) {
                TextField(strings.title, text: $draft.title)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .padding(10)
                    .background(
                        theme.controlBackground,
                        in: RoundedRectangle(cornerRadius: 8)
                    )

                TextField(strings.trigger, text: $draft.trigger)
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
                    selectionLength: $selectionLength,
                    language: language,
                    theme: theme,
                    wrapsLongLines: true,
                    fontSize: .constant(15),
                    onFocusChange: { _ in }
                )
                .frame(height: 230)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(theme.border, lineWidth: 1)
                )

                ConsoleView(issues: issues, theme: theme, strings: strings)
                    .frame(height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                HStack(spacing: 10) {
                    Button(action: onClose) {
                        Label(strings.cancel, systemImage: "xmark")
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
                        Label(strings.save, systemImage: "checkmark")
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
                    Text(strings.fixSnippetErrors)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(theme.error)
                }
            }
        }
    }
}

struct CleanCodeConfirmationModal: View {
    let plan: CleanCodePlan
    let theme: EditorTheme
    let strings: AppStrings
    let onConfirm: () -> Void
    let onCancel: () -> Void

    var body: some View {
        ThemedModal(title: plan.title, theme: theme, onClose: onCancel) {
            VStack(alignment: .leading, spacing: 14) {
                Text(plan.summary)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(theme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(alignment: .leading, spacing: 8) {
                    Label(
                        plan.extractsFiles
                            ? strings.projectManagerChanges
                            : strings.plannedChange,
                        systemImage: plan.extractsFiles
                            ? "folder.badge.gearshape" : "text.alignleft"
                    )
                    .font(
                        .system(size: 12, weight: .heavy, design: .monospaced)
                    )
                    .foregroundStyle(theme.accent)

                    ForEach(plan.files, id: \.self) { file in
                        HStack(spacing: 8) {
                            Image(systemName: fileIconName(for: file))
                                .foregroundStyle(theme.accent)
                                .frame(width: 18)
                            Text(file)
                                .font(
                                    .system(
                                        size: 12,
                                        weight: .heavy,
                                        design: .monospaced
                                    )
                                )
                            Spacer(minLength: 0)
                        }
                        .padding(10)
                        .background(
                            theme.controlBackground,
                            in: RoundedRectangle(cornerRadius: 8)
                        )
                    }
                }

                HStack(spacing: 10) {
                    Button(action: onCancel) {
                        Label(strings.cancel, systemImage: "xmark")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(theme.secondaryText)
                    .padding(12)
                    .background(
                        theme.controlBackground,
                        in: RoundedRectangle(cornerRadius: 8)
                    )

                    Button(action: onConfirm) {
                        Label(
                            plan.extractsFiles
                                ? strings.refactor : strings.format,
                            systemImage: "sparkles"
                        )
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(theme.selectedText)
                    .padding(12)
                    .background(
                        theme.accent.opacity(0.24),
                        in: RoundedRectangle(cornerRadius: 8)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(theme.accent, lineWidth: 1)
                    )
                }
            }
        }
    }

    private func fileIconName(for fileName: String) -> String {
        if fileName.hasSuffix(".css") {
            return "paintbrush.pointed.fill"
        }
        if fileName.hasSuffix(".js") {
            return "curlybraces"
        }
        if fileName.hasSuffix(".html") {
            return "chevron.left.forwardslash.chevron.right"
        }
        return "doc.text"
    }
}

struct SnippetLibraryPanel: View {
    let model: EditorModel
    let strings: AppStrings
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
                    strings.noSnippets,
                    systemImage: "tray",
                    description: Text(strings.noSnippetsHint)
                )
                .font(.caption)
                .foregroundStyle(model.selectedTheme.secondaryText)
            } else {
                List {
                    if !frameworks.isEmpty {
                        Section(strings.frameworks) {
                            ForEach(frameworks) { framework in
                                FrameworkRow(
                                    framework: framework,
                                    language: model.selectedLanguage,
                                    theme: model.selectedTheme,
                                    strings: strings,
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
                        Section(strings.examples) {
                            ForEach(builtinSnippets) { snippet in
                                BuiltinSnippetRow(
                                    snippet: snippet,
                                    language: model.selectedLanguage,
                                    theme: model.selectedTheme,
                                    strings: strings,
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
                        Section(strings.saved) {
                            ForEach(userSnippets) { snippet in
                                SnippetRow(
                                    snippet: snippet,
                                    language: model.selectedLanguage,
                                    theme: model.selectedTheme,
                                    strings: strings,
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
            theme: theme,
            fontSize: 10
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
    let strings: AppStrings
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
                Label(strings.useFramework, systemImage: "text.insert")
            }
            Button {
                UIPasteboard.general.string = framework.boilerplateCode
            } label: {
                Label(strings.copy, systemImage: "doc.on.doc")
            }
        }
        .swipeActions(edge: .leading) {
            Button(action: onInsert) {
                Label(strings.use, systemImage: "shippingbox")
            }
            .tint(.green)
        }
    }
}

struct BuiltinSnippetRow: View {
    let snippet: CodeSnippet
    let language: CodeLanguage
    let theme: EditorTheme
    let strings: AppStrings
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
                Label(strings.insert, systemImage: "text.insert")
            }
            Button {
                UIPasteboard.general.string = snippet.insertText
            } label: {
                Label(strings.copy, systemImage: "doc.on.doc")
            }
        }
        .swipeActions(edge: .leading) {
            Button(action: onInsert) {
                Label(strings.insert, systemImage: "text.insert")
            }
            .tint(.green)
        }
    }
}

struct SnippetRow: View {
    let snippet: UserSnippet
    let language: CodeLanguage
    let theme: EditorTheme
    let strings: AppStrings
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
                Text(strings.emptyUsesBoilerplate)
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
                Label(strings.insert, systemImage: "text.insert")
            }
            Button {
                UIPasteboard.general.string = snippet.code
            } label: {
                Label(strings.copy, systemImage: "doc.on.doc")
            }
            Button(action: onEdit) {
                Label(strings.edit, systemImage: "pencil")
            }
            Button(role: .destructive, action: onDelete) {
                Label(strings.delete, systemImage: "trash")
            }
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive, action: onDelete) {
                Label(strings.delete, systemImage: "trash")
            }
        }
        .swipeActions(edge: .leading) {
            Button(action: onEdit) {
                Label(strings.edit, systemImage: "pencil")
            }
            .tint(.blue)

            Button(action: onInsert) {
                Label(strings.insert, systemImage: "text.insert")
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
    let strings: AppStrings
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
                Label(strings.rename, systemImage: "pencil")
            }

            if item.kind == .file, let exportURL {
                ShareLink(item: exportURL) {
                    Label(strings.export, systemImage: "square.and.arrow.up")
                }
            }

            Button(role: .destructive) {
                onDelete()
            } label: {
                Label(strings.delete, systemImage: "trash")
            }
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label(strings.delete, systemImage: "trash")
            }

            Button {
                onRename()
            } label: {
                Label(strings.rename, systemImage: "pencil")
            }
            .tint(.blue)
        }
        .swipeActions(edge: .leading) {
            if item.kind == .file, let exportURL {
                ShareLink(item: exportURL) {
                    Label(strings.export, systemImage: "square.and.arrow.up")
                }
                .tint(.green)
            }
        }
    }
}

private final class CodeTextView: UITextView {
    var onToggleComment: (() -> Void)?

    override var keyCommands: [UIKeyCommand]? {
        let toggleComment = UIKeyCommand(
            input: "/",
            modifierFlags: .command,
            action: #selector(toggleCommentCommand)
        )
        toggleComment.discoverabilityTitle = "Kommentar umschalten"
        return (super.keyCommands ?? []) + [toggleComment]
    }

    @objc private func toggleCommentCommand() {
        onToggleComment?()
    }
}

struct CodeEditorView: UIViewRepresentable {
    @Binding var text: String
    @Binding var cursorLocation: Int
    @Binding var selectionLength: Int
    let language: CodeLanguage
    let theme: EditorTheme
    let wrapsLongLines: Bool
    @Binding var fontSize: CGFloat
    var issues: [LintIssue] = []
    let onFocusChange: (Bool) -> Void

    func makeUIView(context: Context) -> UITextView {
        let textView = CodeTextView()
        textView.delegate = context.coordinator
        textView.onToggleComment = { [weak coordinator = context.coordinator] in
            coordinator?.toggleCommentFromKeyboard()
        }
        textView.autocorrectionType = .no
        textView.autocapitalizationType = .none
        textView.smartQuotesType = .no
        textView.smartDashesType = .no
        textView.keyboardType = .asciiCapable
        textView.keyboardDismissMode = .interactive
        textView.alwaysBounceVertical = true
        configureLineWrapping(for: textView)
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
        textView.font = .monospacedSystemFont(
            ofSize: fontSize,
            weight: .regular
        )
        context.coordinator.attachPinchGesture(to: textView)
        context.coordinator.attachKeyboardToolbar(to: textView)
        applyHighlight(to: textView)
        return textView
    }

    func updateUIView(_ textView: UITextView, context: Context) {
        context.coordinator.parent = self
        textView.backgroundColor = UIColor(theme.editorBackground)
        textView.tintColor = UIColor(theme.accent)
        textView.font = .monospacedSystemFont(
            ofSize: fontSize,
            weight: .regular
        )
        configureLineWrapping(for: textView)
        context.coordinator.updateKeyboardToolbar(theme: theme)

        if textView.text != text
            || context.coordinator.lastLanguageID != language.id
            || context.coordinator.lastThemeID != theme.id
            || context.coordinator.lastFontSize != fontSize
            || context.coordinator.lastIssues != issues
        {
            applyHighlight(to: textView)
            context.coordinator.lastLanguageID = language.id
            context.coordinator.lastThemeID = theme.id
            context.coordinator.lastFontSize = fontSize
            context.coordinator.lastIssues = issues
        }
        let requestedSelection = NSRange(
            location: cursorLocation,
            length: selectionLength
        )
        if textView.selectedRange != requestedSelection,
            NSMaxRange(requestedSelection) <= textView.text.utf16.count
        {
            textView.selectedRange = requestedSelection
            textView.scrollRangeToVisible(requestedSelection)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    private func configureLineWrapping(for textView: UITextView) {
        textView.textContainer.widthTracksTextView = wrapsLongLines
        textView.alwaysBounceHorizontal = !wrapsLongLines
        textView.showsHorizontalScrollIndicator = !wrapsLongLines
        textView.textContainer.size = CGSize(
            width: wrapsLongLines ? 0 : CGFloat.greatestFiniteMagnitude,
            height: CGFloat.greatestFiniteMagnitude
        )
    }

    private func applyHighlight(to textView: UITextView) {
        let selectedRange = textView.selectedRange
        let contentOffset = textView.contentOffset
        let highlighted = NSMutableAttributedString(
            attributedString: SyntaxHighlighter.highlight(
                text,
                language: language,
                theme: theme,
                fontSize: fontSize
            )
        )
        applyIssueUnderlines(to: highlighted)
        textView.attributedText = highlighted
        textView.typingAttributes = [
            .font: UIFont.monospacedSystemFont(
                ofSize: fontSize,
                weight: .regular
            ),
            .foregroundColor: UIColor(theme.codeText),
        ]
        textView.selectedRange =
            selectedRange.location <= highlighted.length
            ? selectedRange : NSRange(location: highlighted.length, length: 0)
        textView.setContentOffset(contentOffset, animated: false)
    }

    private func applyIssueUnderlines(to attributed: NSMutableAttributedString)
    {
        let source = text as NSString
        for issue in issues {
            var location = 0
            var currentLine = 1
            while currentLine < issue.line && location < source.length {
                let range = source.lineRange(
                    for: NSRange(location: location, length: 0)
                )
                location = NSMaxRange(range)
                currentLine += 1
            }
            guard currentLine == issue.line, location < source.length else {
                continue
            }
            let lineRange = source.lineRange(
                for: NSRange(location: location, length: 0)
            )
            let visibleLength = max(
                0,
                lineRange.length
                    - (source.substring(with: lineRange).hasSuffix("\n")
                        ? 1 : 0)
            )
            guard visibleLength > 0 else { continue }
            attributed.addAttributes(
                [
                    .underlineStyle: NSUnderlineStyle.single.rawValue
                        | NSUnderlineStyle.patternDot.rawValue,
                    .underlineColor: UIColor(issue.severity.color(in: theme)),
                ],
                range: NSRange(
                    location: lineRange.location,
                    length: visibleLength
                )
            )
        }
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
        var lastFontSize: CGFloat
        var lastIssues: [LintIssue]
        private weak var textView: UITextView?
        private weak var keyboardToolbar: UIToolbar?

        init(parent: CodeEditorView) {
            self.parent = parent
            self.lastLanguageID = parent.language.id
            self.lastThemeID = parent.theme.id
            self.lastFontSize = parent.fontSize
            self.lastIssues = parent.issues
        }

        func attachPinchGesture(to textView: UITextView) {
            let pinch = UIPinchGestureRecognizer(
                target: self,
                action: #selector(handlePinch(_:))
            )
            textView.addGestureRecognizer(pinch)
        }

        @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
            guard gesture.state == .changed || gesture.state == .ended,
                let textView
            else {
                return
            }

            let newSize = min(
                28,
                max(11, parent.fontSize * gesture.scale)
            )
            parent.fontSize = newSize
            lastFontSize = newSize
            gesture.scale = 1
            parent.applyHighlight(to: textView)
        }

        func attachKeyboardToolbar(to textView: UITextView) {
            self.textView = textView

            let toolbar = UIToolbar()
            toolbar.sizeToFit()
            toolbar.items = keyboardToolbarItems()

            textView.inputAccessoryView = toolbar
            keyboardToolbar = toolbar
            updateKeyboardToolbar(theme: parent.theme)
        }

        private func keyboardToolbarItems() -> [UIBarButtonItem] {
            [
                barButton(
                    systemImage: "keyboard.chevron.compact.down",
                    accessibilityLabel: "Tastatur schließen",
                    action: #selector(dismissKeyboard)
                ),
                flexibleSpace(),
                barButton(
                    systemImage: "arrow.left",
                    accessibilityLabel: "Cursor nach links",
                    action: #selector(moveCursorLeft)
                ),
                barButton(
                    systemImage: "arrow.right",
                    accessibilityLabel: "Cursor nach rechts",
                    action: #selector(moveCursorRight)
                ),
                barButton(
                    title: "⇤",
                    accessibilityLabel: "Ausrücken",
                    action: #selector(outdentSelection)
                ),
                barButton(
                    title: "⇥",
                    accessibilityLabel: "Einrücken",
                    action: #selector(indentSelection)
                ),
                lineActionsMenuItem(),
                symbolMenuItem(),
                flexibleSpace(),
                barButton(
                    systemImage: "arrow.uturn.backward",
                    accessibilityLabel: "Rückgängig",
                    action: #selector(undo)
                ),
                barButton(
                    systemImage: "arrow.uturn.forward",
                    accessibilityLabel: "Wiederholen",
                    action: #selector(redo)
                ),
            ]
        }

        func updateKeyboardToolbar(theme: EditorTheme) {
            keyboardToolbar?.tintColor = UIColor(theme.accent)
            keyboardToolbar?.barStyle =
                theme.preferredScheme == .dark ? .black : .default
        }

        @objc private func dismissKeyboard() {
            textView?.resignFirstResponder()
        }

        @objc private func moveCursorLeft() {
            moveCursor(by: -1)
        }

        @objc private func moveCursorRight() {
            moveCursor(by: 1)
        }

        @objc private func indentSelection() {
            guard let textView else { return }
            let selection = textView.selectedRange

            guard selection.length > 0 else {
                replaceSelection(in: textView, with: "  ")
                return
            }

            let source = textView.text as NSString
            let lineRange = source.lineRange(for: selection)
            let selectedLines = source.substring(with: lineRange)
            var indented =
                "  "
                + selectedLines.replacingOccurrences(
                    of: "\n",
                    with: "\n  "
                )
            if selectedLines.hasSuffix("\n") {
                indented.removeLast(2)
            }

            let addedCount = indented.utf16.count - selectedLines.utf16.count
            replace(
                range: lineRange,
                with: indented,
                selection: NSRange(
                    location: selection.location + 2,
                    length: selection.length + max(0, addedCount - 2)
                ),
                in: textView
            )
        }

        @objc private func outdentSelection() {
            guard let textView else { return }
            let selection = textView.selectedRange
            let source = textView.text as NSString
            let lineRange = source.lineRange(for: selection)
            let selectedLines = source.substring(with: lineRange)
            let transformed = removeIndentation(from: selectedLines)

            guard transformed.text != selectedLines else { return }

            let newLocation = max(
                lineRange.location,
                selection.location - transformed.firstLineRemoval
            )
            let newLength: Int
            if selection.length == 0 {
                newLength = 0
            } else {
                newLength = max(
                    0,
                    selection.length - transformed.totalRemoval
                        + transformed.firstLineRemoval
                )
            }

            replace(
                range: lineRange,
                with: transformed.text,
                selection: NSRange(location: newLocation, length: newLength),
                in: textView
            )
        }

        @objc private func duplicateLines() {
            guard let textView else { return }
            let source = textView.text as NSString
            let selection = textView.selectedRange
            let lineRange = source.lineRange(for: selection)
            let lineText = source.substring(with: lineRange)
            let separator = lineText.hasSuffix("\n") ? "" : "\n"
            let replacement = lineText + separator + lineText
            replace(
                range: lineRange,
                with: replacement,
                selection: NSRange(
                    location: selection.location
                        + lineText.utf16.count + separator.utf16.count,
                    length: selection.length
                ),
                in: textView
            )
        }

        @objc private func deleteLines() {
            guard let textView else { return }
            let source = textView.text as NSString
            let lineRange = source.lineRange(for: textView.selectedRange)
            let updatedLength = max(0, source.length - lineRange.length)
            replace(
                range: lineRange,
                with: "",
                selection: NSRange(
                    location: min(lineRange.location, updatedLength),
                    length: 0
                ),
                in: textView
            )
        }

        @objc private func moveLinesUp() {
            guard let textView else { return }
            let source = textView.text as NSString
            let selection = textView.selectedRange
            let lineRange = source.lineRange(for: selection)
            guard lineRange.location > 0 else { return }

            let previousRange = source.lineRange(
                for: NSRange(location: lineRange.location - 1, length: 0)
            )
            let previousText = source.substring(with: previousRange)
            let currentText = source.substring(with: lineRange)
            let combinedRange = NSRange(
                location: previousRange.location,
                length: previousRange.length + lineRange.length
            )

            let replacement =
                removingTrailingNewline(from: currentText)
                + "\n"
                + removingTrailingNewline(from: previousText)
                + (currentText.hasSuffix("\n") ? "\n" : "")

            replace(
                range: combinedRange,
                with: replacement,
                selection: NSRange(
                    location: selection.location - previousRange.length,
                    length: selection.length
                ),
                in: textView
            )
        }

        @objc private func moveLinesDown() {
            guard let textView else { return }
            let source = textView.text as NSString
            let selection = textView.selectedRange
            let lineRange = source.lineRange(for: selection)
            guard NSMaxRange(lineRange) < source.length else { return }

            let nextRange = source.lineRange(
                for: NSRange(location: NSMaxRange(lineRange), length: 0)
            )
            let currentText = source.substring(with: lineRange)
            let nextText = source.substring(with: nextRange)
            let combinedRange = NSRange(
                location: lineRange.location,
                length: lineRange.length + nextRange.length
            )

            let replacement =
                removingTrailingNewline(from: nextText)
                + "\n"
                + removingTrailingNewline(from: currentText)
                + (nextText.hasSuffix("\n") ? "\n" : "")

            replace(
                range: combinedRange,
                with: replacement,
                selection: NSRange(
                    location: selection.location + nextRange.length,
                    length: selection.length
                ),
                in: textView
            )
        }

        private func removingTrailingNewline(from text: String) -> String {
            text.hasSuffix("\n") ? String(text.dropLast()) : text
        }

        func toggleCommentFromKeyboard() {
            toggleComment()
        }

        @objc private func toggleComment() {
            guard let textView else { return }
            let source = textView.text as NSString
            let selection = textView.selectedRange
            let lineRange = source.lineRange(for: selection)
            let selectedText = source.substring(with: lineRange)
            let style = commentStyle(for: parent.language.id)
            let transformed: String

            switch style {
            case .line(let prefix):
                let lines = selectedText.components(separatedBy: "\n")
                let contentLines =
                    selectedText.hasSuffix("\n")
                    ? Array(lines.dropLast()) : lines
                let allCommented =
                    contentLines
                    .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
                    .allSatisfy {
                        $0.trimmingCharacters(in: .whitespaces)
                            .hasPrefix(prefix)
                    }

                transformed =
                    contentLines.map { line in
                        if line.trimmingCharacters(in: .whitespaces).isEmpty {
                            return line
                        }
                        if allCommented,
                            let range = line.range(of: prefix)
                        {
                            var uncommented = line
                            uncommented.removeSubrange(range)
                            if uncommented.hasPrefix(" ") {
                                uncommented.removeFirst()
                            }
                            return uncommented
                        }
                        return prefix + " " + line
                    }.joined(separator: "\n")
                    + (selectedText.hasSuffix("\n") ? "\n" : "")
            case .block(let opening, let closing):
                let trimmed = selectedText.trimmingCharacters(
                    in: .whitespacesAndNewlines
                )
                if trimmed.hasPrefix(opening), trimmed.hasSuffix(closing),
                    let openRange = selectedText.range(of: opening),
                    let closeRange = selectedText.range(
                        of: closing,
                        options: .backwards
                    )
                {
                    var result = selectedText
                    result.removeSubrange(closeRange)
                    result.removeSubrange(openRange)
                    transformed = result
                } else {
                    transformed = opening + " " + selectedText + " " + closing
                }
            }

            replace(
                range: lineRange,
                with: transformed,
                selection: NSRange(
                    location: lineRange.location,
                    length: transformed.utf16.count
                ),
                in: textView
            )
        }

        @objc private func undo() {
            textView?.undoManager?.undo()
        }

        @objc private func redo() {
            textView?.undoManager?.redo()
        }

        private func moveCursor(by offset: Int) {
            guard let textView,
                let selectedTextRange = textView.selectedTextRange
            else {
                return
            }

            let anchor =
                offset < 0
                ? selectedTextRange.start : selectedTextRange.end
            guard
                let position = textView.position(
                    from: anchor,
                    offset: offset
                )
            else {
                return
            }

            textView.selectedTextRange = textView.textRange(
                from: position,
                to: position
            )
            textView.scrollRangeToVisible(textView.selectedRange)
        }

        private func replaceSelection(
            in textView: UITextView,
            with text: String
        ) {
            let selection = textView.selectedRange
            replace(
                range: selection,
                with: text,
                selection: NSRange(
                    location: selection.location + text.utf16.count,
                    length: 0
                ),
                in: textView
            )
        }

        private func replace(
            range: NSRange,
            with replacement: String,
            selection: NSRange,
            in textView: UITextView
        ) {
            guard let swiftRange = Range(range, in: textView.text) else {
                return
            }

            var updatedText = textView.text ?? ""
            updatedText.replaceSubrange(swiftRange, with: replacement)
            textView.text = updatedText
            textView.selectedRange = selection
            parent.text = updatedText
            parent.cursorLocation = selection.location
            parent.applyHighlight(to: textView)
            lastLanguageID = parent.language.id
            lastThemeID = parent.theme.id
        }

        private func removeIndentation(
            from text: String
        ) -> (text: String, totalRemoval: Int, firstLineRemoval: Int) {
            let keepsTrailingLine = text.hasSuffix("\n")
            var lines = text.components(separatedBy: "\n")
            if keepsTrailingLine {
                lines.removeLast()
            }

            var removals: [Int] = []
            let transformedLines = lines.map { line in
                let removal: Int
                if line.hasPrefix("  ") {
                    removal = 2
                } else if line.hasPrefix(" ") || line.hasPrefix("\t") {
                    removal = 1
                } else {
                    removal = 0
                }
                removals.append(removal)
                return String(line.dropFirst(removal))
            }

            var result = transformedLines.joined(separator: "\n")
            if keepsTrailingLine {
                result += "\n"
            }
            return (
                result,
                removals.reduce(0, +),
                removals.first ?? 0
            )
        }

        private enum CommentStyle {
            case line(String)
            case block(String, String)
        }

        private func commentStyle(for languageID: String) -> CommentStyle {
            switch languageID {
            case "html", "markdown":
                return .block("<!--", "-->")
            case "css":
                return .block("/*", "*/")
            case "python":
                return .line("#")
            case "sql":
                return .line("--")
            default:
                return .line("//")
            }
        }

        private func lineActionsMenuItem() -> UIBarButtonItem {
            let menu = UIMenu(
                title: "Zeile",
                children: [
                    UIAction(
                        title: "Duplizieren",
                        image: UIImage(systemName: "plus.square.on.square")
                    ) { [weak self] _ in
                        self?.duplicateLines()
                    },
                    UIAction(
                        title: "Nach oben",
                        image: UIImage(systemName: "arrow.up")
                    ) { [weak self] _ in
                        self?.moveLinesUp()
                    },
                    UIAction(
                        title: "Nach unten",
                        image: UIImage(systemName: "arrow.down")
                    ) { [weak self] _ in
                        self?.moveLinesDown()
                    },
                    UIAction(
                        title: "Kommentar umschalten",
                        image: UIImage(systemName: "text.bubble")
                    ) { [weak self] _ in
                        self?.toggleComment()
                    },
                    UIAction(
                        title: "Löschen",
                        image: UIImage(systemName: "trash"),
                        attributes: .destructive
                    ) { [weak self] _ in
                        self?.deleteLines()
                    },
                ]
            )
            let item = UIBarButtonItem(
                image: UIImage(
                    systemName: "text.line.first.and.arrowtriangle.forward"
                ),
                menu: menu
            )
            item.accessibilityLabel = "Zeilenaktionen"
            return item
        }

        private func symbolMenuItem() -> UIBarButtonItem {
            let symbols: [String]
            switch parent.language.id {
            case "html":
                symbols = ["<", ">", "</", "/>", "=", "\"", "'", "&"]
            case "css":
                symbols = ["{", "}", ":", ";", ".", "#", "(", ")"]
            case "swift":
                symbols = ["{", "}", "(", ")", "[", "]", ":", ".", "\""]
            case "python":
                symbols = ["(", ")", "[", "]", "{", "}", ":", "#"]
            case "sql":
                symbols = ["(", ")", ",", ";", "'", "\"", "*", "="]
            default:
                symbols = [
                    "{", "}", "(", ")", "[", "]", "<", ">", ";", ":", "\"",
                ]
            }
            let actions = symbols.map { symbol in
                UIAction(title: symbol) { [weak self] _ in
                    guard let self, let textView = self.textView else { return }
                    self.replaceSelection(in: textView, with: symbol)
                }
            }
            let item = UIBarButtonItem(
                image: UIImage(
                    systemName: "chevron.left.forwardslash.chevron.right"
                ),
                menu: UIMenu(title: "Codezeichen", children: actions)
            )
            item.accessibilityLabel = "Codezeichen"
            return item
        }

        private func barButton(
            systemImage: String,
            accessibilityLabel: String,
            action: Selector
        ) -> UIBarButtonItem {
            let item = UIBarButtonItem(
                image: UIImage(systemName: systemImage),
                style: .plain,
                target: self,
                action: action
            )
            item.accessibilityLabel = accessibilityLabel
            return item
        }

        private func barButton(
            title: String,
            accessibilityLabel: String,
            action: Selector
        ) -> UIBarButtonItem {
            let item = UIBarButtonItem(
                title: title,
                style: .plain,
                target: self,
                action: action
            )
            item.accessibilityLabel = accessibilityLabel
            return item
        }

        private func flexibleSpace() -> UIBarButtonItem {
            UIBarButtonItem(systemItem: .flexibleSpace)
        }

        private func fixedSpace(_ width: CGFloat) -> UIBarButtonItem {
            let item = UIBarButtonItem(systemItem: .fixedSpace)
            item.width = width
            return item
        }

        func textViewDidBeginEditing(_ textView: UITextView) {
            parent.onFocusChange(true)
        }

        func textViewDidEndEditing(_ textView: UITextView) {
            parent.onFocusChange(false)
        }

        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.text
            parent.cursorLocation = textView.selectedRange.location
            parent.selectionLength = textView.selectedRange.length
            parent.applyHighlight(to: textView)
            lastLanguageID = parent.language.id
            lastThemeID = parent.theme.id
        }

        func textViewDidChangeSelection(_ textView: UITextView) {
            parent.cursorLocation = textView.selectedRange.location
            parent.selectionLength = textView.selectedRange.length
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
            parent.selectionLength = 0
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

    private static func palette(
        id: String,
        name: String,
        scheme: ColorScheme = .dark,
        base: Color,
        surface: Color,
        accent: Color,
        text: Color,
        secondary: Color,
        keyword: Color,
        string: Color
    ) -> EditorTheme {
        EditorTheme(
            id: id,
            name: name,
            preferredScheme: scheme,
            background: base,
            headerBackground: surface,
            toolbarBackground: surface.opacity(0.96),
            panelBackground: surface.opacity(0.82),
            editorBackground: base.opacity(0.96),
            consoleBackground: base,
            consoleHeader: surface,
            controlBackground: accent.opacity(scheme == .dark ? 0.12 : 0.09),
            border: accent.opacity(0.28),
            primaryText: text,
            secondaryText: secondary,
            selectedText: text,
            codeText: text.opacity(0.94),
            keyword: keyword,
            string: string,
            number: accent,
            comment: secondary.opacity(0.78),
            tag: keyword,
            accent: accent,
            success: Color(red: 0.24, green: 0.82, blue: 0.45),
            warning: Color(red: 1.00, green: 0.72, blue: 0.20),
            error: Color(red: 1.00, green: 0.28, blue: 0.30)
        )
    }

    static let lemonade = palette(
        id: "lemonade",
        name: "Lemonade",
        scheme: .light,
        base: Color(red: 1.00, green: 0.99, blue: 0.86),
        surface: Color(red: 1.00, green: 0.96, blue: 0.62),
        accent: Color(red: 0.82, green: 0.68, blue: 0.02),
        text: Color(red: 0.19, green: 0.22, blue: 0.08),
        secondary: Color(red: 0.43, green: 0.45, blue: 0.22),
        keyword: Color(red: 0.20, green: 0.52, blue: 0.14),
        string: Color(red: 0.72, green: 0.38, blue: 0.04)
    )
    static let water = palette(
        id: "water",
        name: "Water",
        base: Color(red: 0.01, green: 0.09, blue: 0.16),
        surface: Color(red: 0.02, green: 0.18, blue: 0.28),
        accent: Color(red: 0.16, green: 0.76, blue: 1.00),
        text: Color(red: 0.84, green: 0.96, blue: 1.00),
        secondary: Color(red: 0.45, green: 0.69, blue: 0.78),
        keyword: Color(red: 0.32, green: 0.90, blue: 1.00),
        string: Color(red: 0.48, green: 0.92, blue: 0.72)
    )
    static let nature = palette(
        id: "nature",
        name: "Nature",
        base: Color(red: 0.025, green: 0.10, blue: 0.055),
        surface: Color(red: 0.06, green: 0.18, blue: 0.09),
        accent: Color(red: 0.32, green: 0.82, blue: 0.35),
        text: Color(red: 0.86, green: 0.96, blue: 0.82),
        secondary: Color(red: 0.48, green: 0.67, blue: 0.46),
        keyword: Color(red: 0.48, green: 0.94, blue: 0.38),
        string: Color(red: 0.92, green: 0.78, blue: 0.38)
    )
    static let fire = palette(
        id: "fire",
        name: "Fire",
        base: Color(red: 0.13, green: 0.025, blue: 0.01),
        surface: Color(red: 0.26, green: 0.055, blue: 0.015),
        accent: Color(red: 1.00, green: 0.36, blue: 0.05),
        text: Color(red: 1.00, green: 0.90, blue: 0.76),
        secondary: Color(red: 0.76, green: 0.50, blue: 0.36),
        keyword: Color(red: 1.00, green: 0.66, blue: 0.08),
        string: Color(red: 1.00, green: 0.36, blue: 0.24)
    )
    static let lava = palette(
        id: "lava",
        name: "Lava",
        base: Color(red: 0.07, green: 0.005, blue: 0.008),
        surface: Color(red: 0.20, green: 0.018, blue: 0.02),
        accent: Color(red: 1.00, green: 0.12, blue: 0.04),
        text: Color(red: 1.00, green: 0.84, blue: 0.78),
        secondary: Color(red: 0.70, green: 0.38, blue: 0.34),
        keyword: Color(red: 1.00, green: 0.40, blue: 0.08),
        string: Color(red: 1.00, green: 0.72, blue: 0.14)
    )
    static let wind = palette(
        id: "wind",
        name: "Wind",
        scheme: .light,
        base: Color(red: 0.94, green: 0.98, blue: 0.98),
        surface: Color(red: 0.84, green: 0.93, blue: 0.94),
        accent: Color(red: 0.20, green: 0.60, blue: 0.66),
        text: Color(red: 0.08, green: 0.20, blue: 0.22),
        secondary: Color(red: 0.34, green: 0.48, blue: 0.50),
        keyword: Color(red: 0.10, green: 0.48, blue: 0.56),
        string: Color(red: 0.42, green: 0.36, blue: 0.70)
    )
    static let earth = palette(
        id: "earth",
        name: "Earth",
        base: Color(red: 0.11, green: 0.07, blue: 0.035),
        surface: Color(red: 0.22, green: 0.14, blue: 0.07),
        accent: Color(red: 0.70, green: 0.48, blue: 0.20),
        text: Color(red: 0.94, green: 0.86, blue: 0.70),
        secondary: Color(red: 0.62, green: 0.52, blue: 0.38),
        keyword: Color(red: 0.56, green: 0.78, blue: 0.32),
        string: Color(red: 0.92, green: 0.58, blue: 0.28)
    )
    static let berry = palette(
        id: "berry",
        name: "Berry",
        base: Color(red: 0.10, green: 0.02, blue: 0.12),
        surface: Color(red: 0.23, green: 0.05, blue: 0.25),
        accent: Color(red: 0.84, green: 0.22, blue: 0.78),
        text: Color(red: 0.98, green: 0.86, blue: 1.00),
        secondary: Color(red: 0.68, green: 0.48, blue: 0.70),
        keyword: Color(red: 1.00, green: 0.38, blue: 0.76),
        string: Color(red: 0.66, green: 0.70, blue: 1.00)
    )
    static let cherry = palette(
        id: "cherry",
        name: "Cherry",
        base: Color(red: 0.12, green: 0.01, blue: 0.04),
        surface: Color(red: 0.25, green: 0.025, blue: 0.08),
        accent: Color(red: 0.94, green: 0.08, blue: 0.28),
        text: Color(red: 1.00, green: 0.86, blue: 0.90),
        secondary: Color(red: 0.72, green: 0.44, blue: 0.50),
        keyword: Color(red: 1.00, green: 0.24, blue: 0.44),
        string: Color(red: 1.00, green: 0.62, blue: 0.70)
    )
    static let strawberry = palette(
        id: "strawberry",
        name: "Strawberry",
        scheme: .light,
        base: Color(red: 1.00, green: 0.94, blue: 0.94),
        surface: Color(red: 1.00, green: 0.82, blue: 0.84),
        accent: Color(red: 0.88, green: 0.16, blue: 0.28),
        text: Color(red: 0.30, green: 0.06, blue: 0.10),
        secondary: Color(red: 0.56, green: 0.30, blue: 0.34),
        keyword: Color(red: 0.72, green: 0.06, blue: 0.20),
        string: Color(red: 0.20, green: 0.48, blue: 0.24)
    )
    static let kiwi = palette(
        id: "kiwi",
        name: "Kiwi",
        base: Color(red: 0.055, green: 0.09, blue: 0.018),
        surface: Color(red: 0.12, green: 0.19, blue: 0.035),
        accent: Color(red: 0.58, green: 0.90, blue: 0.14),
        text: Color(red: 0.91, green: 0.98, blue: 0.78),
        secondary: Color(red: 0.56, green: 0.68, blue: 0.39),
        keyword: Color(red: 0.70, green: 1.00, blue: 0.22),
        string: Color(red: 0.94, green: 0.78, blue: 0.28)
    )
    static let pineapple = palette(
        id: "pineapple",
        name: "Pineapple",
        base: Color(red: 0.10, green: 0.075, blue: 0.012),
        surface: Color(red: 0.20, green: 0.15, blue: 0.025),
        accent: Color(red: 1.00, green: 0.78, blue: 0.08),
        text: Color(red: 1.00, green: 0.95, blue: 0.74),
        secondary: Color(red: 0.72, green: 0.62, blue: 0.38),
        keyword: Color(red: 1.00, green: 0.86, blue: 0.14),
        string: Color(red: 0.48, green: 0.84, blue: 0.32)
    )
    static let space = palette(
        id: "space",
        name: "Space",
        base: Color(red: 0.025, green: 0.02, blue: 0.10),
        surface: Color(red: 0.07, green: 0.055, blue: 0.20),
        accent: Color(red: 0.52, green: 0.42, blue: 1.00),
        text: Color(red: 0.90, green: 0.90, blue: 1.00),
        secondary: Color(red: 0.52, green: 0.52, blue: 0.74),
        keyword: Color(red: 0.74, green: 0.48, blue: 1.00),
        string: Color(red: 0.32, green: 0.86, blue: 1.00)
    )
    static let deepSpace = palette(
        id: "deepSpace",
        name: "Deep Space",
        base: Color(red: 0.002, green: 0.004, blue: 0.015),
        surface: Color(red: 0.018, green: 0.025, blue: 0.065),
        accent: Color(red: 0.20, green: 0.50, blue: 1.00),
        text: Color(red: 0.80, green: 0.86, blue: 1.00),
        secondary: Color(red: 0.34, green: 0.40, blue: 0.58),
        keyword: Color(red: 0.48, green: 0.64, blue: 1.00),
        string: Color(red: 0.66, green: 0.44, blue: 1.00)
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
        .lemonade,
        .water,
        .nature,
        .fire,
        .lava,
        .wind,
        .earth,
        .berry,
        .cherry,
        .strawberry,
        .kiwi,
        .pineapple,
        .space,
        .deepSpace,
    ]
}

#Preview {
    NavigationStack {
        HomeView(model: EditorModel())
    }
}
