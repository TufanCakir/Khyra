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
                        onToggle: {
                            withAnimation(.snappy) {
                                model.showConsole.toggle()
                            }
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
}

#Preview {
    NavigationStack {
        PlaygroundView()
    }
}
