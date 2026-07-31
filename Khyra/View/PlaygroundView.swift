//
//  PlaygroundView.swift
//  Khyra
//
//  Created by Tufan Cakir on 31.07.26.
//

import SwiftUI

struct PlaygroundView: View {
    let template: ProjectTemplate?
    @State private var model: EditorModel
    @State private var didLoadTemplate = false
    @State private var showSavedToast = false
    @State private var showConsoleSheet = false

    init(template: ProjectTemplate? = nil) {
        self.template = template
        _model = State(initialValue: EditorModel())
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
            set: { model.selectLanguage($0) }
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
                        versions: model.codeVersions,
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
                        onDeleteVersion: { version in
                            model.deleteCodeVersion(version)
                        },
                        onIssueSelect: { issue in
                            model.jumpToIssue(issue)
                        },
                        onOpenSheet: {
                            showConsoleSheet = true
                        },
                        languageForVersion: { version in
                            model.language(for: version.languageID)
                        }
                    )
                    .frame(height: 190)
                } else {
                    ConsoleCollapsedBar(theme: model.selectedTheme) {
                        withAnimation(.snappy) {
                            model.showConsole.toggle()
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
        }
        .sheet(isPresented: $showConsoleSheet) {
            ConsoleView(
                issues: model.issues,
                theme: model.selectedTheme,
                versions: model.codeVersions,
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
        .foregroundStyle(model.selectedTheme.primaryText)
        .navigationTitle(template?.title ?? "Playground")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            guard !didLoadTemplate else { return }
            didLoadTemplate = true
            if let template {
                model.createProject(template: template)
            } else {
                model.seedDocumentsIfNeeded()
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    model.insertBoilerplate()
                } label: {
                    Image(systemName: "wand.and.stars")
                }
                .accessibilityLabel("Boilerplate einfuegen")
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

                    Button(role: .destructive) {
                        model.activeCode.wrappedValue = ""
                        model.cursorLocation = 0
                    } label: {
                        Label("Clear", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .accessibilityLabel("Mehr Aktionen")
            }
        }
        .preferredColorScheme(model.selectedTheme.preferredScheme)
    }

    private func showSavedFeedback() {
        withAnimation(.snappy) {
            showSavedToast = true
        }
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            withAnimation(.snappy) {
                showSavedToast = false
            }
        }
    }

}

#Preview {
    NavigationStack {
        PlaygroundView()
    }
}
