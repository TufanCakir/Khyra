//
//  DocumentationLibraryView.swift
//  Khyra
//
//  Created by Tufan Cakir on 31.07.26.
//

import SwiftUI
import UIKit

struct DocumentationView: View {
    let model: EditorModel

    var body: some View {
        DocumentationLibraryView(model: model)
    }
}

struct DocumentationLibraryView: View {
    let model: EditorModel

    @State private var guides: [DocumentationLanguageGuide] = []
    @State private var searchText = ""

    var body: some View {
        DocumentationLibraryContent(
            guides: guides,
            searchText: searchText,
            theme: model.selectedTheme
        )
        .searchable(
            text: $searchText,
            prompt: model.appLanguageCode == "de"
                ? "Sprache, Framework oder API"
                : "Language, framework, or API"
        )
        .background(model.selectedTheme.background)
        .navigationTitle(model.appStrings.documentation)
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: DocumentationTopic.self) { topic in
            DocumentationTopicView(
                topic: topic,
                language: language(for: topic),
                theme: model.selectedTheme,
                editorTitle: model.appStrings.editor,
                copyTitle: model.appStrings.copy,
                onUseInEditor: {
                    model.activeCode.wrappedValue = topic.code
                    model.cursorLocation = topic.code.utf16.count
                }
            )
        }

        .task {
            guides = DocumentationCatalog.make(from: model.languageStore)
        }
    }

    private func language(for topic: DocumentationTopic) -> CodeLanguage {
        let languageID = guides.first { guide in
            guide.frameworks.contains { framework in
                framework.topics.contains(topic)
            }
        }?.id

        return model.languageStore.languages.first {
            $0.id == languageID
        } ?? model.selectedLanguage
    }
}

private struct DocumentationLibraryContent: View {
    let guides: [DocumentationLanguageGuide]
    let searchText: String
    let theme: EditorTheme

    var body: some View {
        List {
            if searchText.trimmingCharacters(in: .whitespacesAndNewlines)
                .isEmpty
            {
                DocumentationTree(guides: guides, theme: theme)
            } else {
                DocumentationSearchResults(
                    guides: guides,
                    query: searchText,
                    theme: theme
                )
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .overlay {
            if guides.isEmpty {
                ProgressView()
                    .tint(theme.accent)
            }
        }
    }
}

private struct DocumentationTree: View {
    let guides: [DocumentationLanguageGuide]
    let theme: EditorTheme

    var body: some View {
        ForEach(guides) { guide in
            DisclosureGroup {
                ForEach(guide.frameworks) { framework in
                    Section {
                        ForEach(framework.topics) { topic in
                            NavigationLink(value: topic) {
                                DocumentationTopicRow(
                                    topic: topic,
                                    theme: theme
                                )
                            }
                        }
                    } header: {
                        Label(
                            framework.name,
                            systemImage: framework.systemImage
                        )
                        .font(.subheadline.bold())
                        .foregroundStyle(theme.accent)
                    }
                }
            } label: {
                DocumentationLanguageLabel(
                    name: guide.name,
                    systemImage: guide.systemImage,
                    frameworkCount: guide.frameworks.count,
                    theme: theme
                )
            }
            .listRowBackground(theme.panelBackground)
        }
    }
}

private struct DocumentationLanguageLabel: View {
    let name: String
    let systemImage: String
    let frameworkCount: Int
    let theme: EditorTheme

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .foregroundStyle(theme.accent)
                .frame(width: 24)
            Text(name)
                .font(.headline)
            Spacer()
            Text(frameworkCount, format: .number)
                .font(.caption.monospacedDigit())
                .foregroundStyle(theme.secondaryText)
        }
    }
}

private struct DocumentationFrameworkBranch: View {
    let framework: DocumentationFrameworkGuide
    let theme: EditorTheme

    var body: some View {
        DisclosureGroup {
            ForEach(framework.topics) { topic in
                NavigationLink(value: topic) {
                    DocumentationTopicRow(topic: topic, theme: theme)
                }
            }
        } label: {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: framework.systemImage)
                    .foregroundStyle(theme.accent)
                    .frame(width: 22)
                VStack(alignment: .leading, spacing: 2) {
                    Text(framework.name)
                        .font(.subheadline.bold())
                    Text(framework.summary)
                        .font(.caption)
                        .foregroundStyle(theme.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.vertical, 3)
        }
    }
}

private struct DocumentationTopicRow: View {
    let topic: DocumentationTopic
    let theme: EditorTheme

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(topic.title)
                    .font(.subheadline.weight(.semibold))
                if let availability = topic.availability {
                    Text(availability)
                        .font(.caption2.bold())
                        .foregroundStyle(theme.accent)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            theme.accent.opacity(0.14),
                            in: Capsule()
                        )
                }
            }
            Text(topic.summary)
                .font(.caption)
                .foregroundStyle(theme.secondaryText)
                .lineLimit(2)
        }
        .padding(.vertical, 4)
    }
}

private struct DocumentationSearchResults: View {
    let guides: [DocumentationLanguageGuide]
    let query: String
    let theme: EditorTheme

    private var matches: [DocumentationSearchMatch] {
        let normalizedQuery = query.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        guard !normalizedQuery.isEmpty else { return [] }

        return guides.flatMap { guide in
            guide.frameworks.flatMap { framework in
                framework.topics.compactMap { topic in
                    let haystack = [
                        guide.name,
                        framework.name,
                        topic.title,
                        topic.summary,
                        topic.code,
                    ].joined(separator: " ")

                    guard haystack.localizedStandardContains(normalizedQuery)
                    else {
                        return nil
                    }
                    return DocumentationSearchMatch(
                        languageName: guide.name,
                        frameworkName: framework.name,
                        topic: topic
                    )
                }
            }
        }
    }

    var body: some View {
        if matches.isEmpty {
            ContentUnavailableView.search(text: query)
                .listRowBackground(Color.clear)
        } else {
            Section {
                ForEach(matches) { match in
                    NavigationLink(value: match.topic) {
                        VStack(alignment: .leading, spacing: 4) {
                            DocumentationTopicRow(
                                topic: match.topic,
                                theme: theme
                            )
                            Text(
                                "\(match.languageName) › \(match.frameworkName)"
                            )
                            .font(.caption2)
                            .foregroundStyle(theme.accent)
                        }
                    }
                }
            }
            .listRowBackground(theme.panelBackground)
        }
    }
}

private struct DocumentationSearchMatch: Identifiable {
    var id: String {
        "\(languageName)-\(frameworkName)-\(topic.id)"
    }

    let languageName: String
    let frameworkName: String
    let topic: DocumentationTopic
}

private struct DocumentationLanguageScreen: View {
    let guide: DocumentationLanguageGuide
    let theme: EditorTheme

    var body: some View {
        List {
            ForEach(guide.frameworks) { framework in
                Section {
                    ForEach(framework.topics) { topic in
                        NavigationLink(value: topic) {
                            DocumentationTopicRow(
                                topic: topic,
                                theme: theme
                            )
                        }
                    }
                } header: {
                    Label(
                        framework.name,
                        systemImage: framework.systemImage
                    )
                } footer: {
                    Text(framework.summary)
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(theme.background)
        .navigationTitle(guide.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct DocumentationTopicView: View {
    let topic: DocumentationTopic
    let language: CodeLanguage
    let theme: EditorTheme
    let editorTitle: String
    let copyTitle: String
    let onUseInEditor: () -> Void

    @State private var copied = false

    var body: some View {
        List {
            DocumentationTopicHeader(
                topic: topic,
                theme: theme
            )
            .listRowBackground(theme.panelBackground)

            Section("Code") {
                DocumentationTopicCode(
                    code: topic.code,
                    language: language,
                    theme: theme
                )
            }
            .listRowBackground(theme.panelBackground)

            if !topic.tips.isEmpty {
                Section("Tipps") {
                    ForEach(topic.tips, id: \.self) { tip in
                        Label(tip, systemImage: "lightbulb")
                            .foregroundStyle(theme.secondaryText)
                    }
                }
                .listRowBackground(theme.panelBackground)
            }
        }
        .scrollContentBackground(.hidden)
        .background(theme.background)
        .navigationTitle(topic.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    UIPasteboard.general.string = topic.code
                    copied = true
                } label: {
                    Image(systemName: copied ? "checkmark" : "doc.on.doc")
                }
                .accessibilityLabel(copyTitle)

                ShareLink(item: topic.code) {
                    Image(systemName: "square.and.arrow.up")
                }

                Button(action: onUseInEditor) {
                    Image(systemName: "square.and.pencil")
                }
                .accessibilityLabel(editorTitle)
            }
        }
    }
}

private struct DocumentationTopicHeader: View {
    let topic: DocumentationTopic
    let theme: EditorTheme

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label(topic.framework, systemImage: "shippingbox")
                    .font(.caption.bold())
                    .foregroundStyle(theme.accent)
                Spacer()
                if let availability = topic.availability {
                    Text(availability)
                        .font(.caption.bold())
                        .foregroundStyle(theme.accent)
                }
            }
            Text(topic.summary)
                .font(.body)
                .foregroundStyle(theme.primaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 6)
    }
}

private struct DocumentationTopicCode: View {
    let code: String
    let language: CodeLanguage
    let theme: EditorTheme

    private var highlightedCode: AttributedString {
        let highlighted = SyntaxHighlighter.highlight(
            code,
            language: language,
            theme: theme
        )
        return (try? AttributedString(highlighted, including: \.uiKit))
            ?? AttributedString(code)
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            Text(highlightedCode)
                .font(.system(.callout, design: .monospaced))
                .textSelection(.enabled)
                .padding(12)
        }
        .background(
            theme.editorBackground,
            in: RoundedRectangle(cornerRadius: 10)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 10)
                .stroke(theme.border, lineWidth: 1)
        }
    }
}
