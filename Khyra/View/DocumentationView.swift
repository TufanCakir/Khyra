//
//  DocumentationView.swift
//  Khyra
//
//  Created by Tufan Cakir on 31.07.26.
//

import SwiftUI
import UIKit

struct DocumentationView: View {
    let model: EditorModel
    @State private var selectedLanguageID = "html"
    @State private var copiedTitle: String?

    private var selectedLanguage: CodeLanguage {
        model.languageStore.languages.first { $0.id == selectedLanguageID }
            ?? model.selectedLanguage
    }

    private var supportsPreview: Bool {
        ["html", "css", "javascript"].contains(selectedLanguage.id)
    }

    private var strings: AppStrings {
        model.appStrings
    }

    var body: some View {
        List {
            Section(strings.language) {
                Picker(strings.language, selection: $selectedLanguageID) {
                    ForEach(model.languageStore.languages) { language in
                        Text(language.name).tag(language.id)
                    }
                }

                LabeledContent(
                    strings.file,
                    value: selectedLanguage.fileExtension
                )
                LabeledContent(
                    strings.preview,
                    value: supportsPreview ? "WebKit" : strings.writeOnly
                )
            }

            if let boilerplate = selectedLanguage.boilerplateCode,
                !boilerplate.isEmpty
            {
                Section(strings.boilerplate) {
                    DocumentationCodeBlock(
                        title: strings.starterCode,
                        descriptionText: strings.starterCodeDescription,
                        code: boilerplate,
                        language: selectedLanguage,
                        explanation: CodeExplanation.make(
                            for: boilerplate,
                            language: selectedLanguage
                        ),
                        copiedTitle: copiedTitle,
                        theme: model.selectedTheme,
                        strings: strings,
                        onCopy: copy
                    )
                }
            }

            if !selectedLanguage.referenceSections.isEmpty {
                Section(strings.reference) {
                    ForEach(selectedLanguage.referenceSections) { reference in
                        DocumentationCodeBlock(
                            title: reference.title,
                            descriptionText: reference.body,
                            code: reference.code,
                            language: selectedLanguage,
                            explanation: CodeExplanation.make(
                                for: reference.code,
                                language: selectedLanguage
                            ),
                            copiedTitle: copiedTitle,
                            theme: model.selectedTheme,
                            strings: strings,
                            onCopy: copy
                        )
                    }
                }
            }

            if !selectedLanguage.snippets.isEmpty {
                Section(strings.snippets) {
                    ForEach(selectedLanguage.snippets) { snippet in
                        DocumentationCodeBlock(
                            title: snippet.title,
                            descriptionText: "Trigger: \(snippet.trigger)",
                            code: snippet.insertText,
                            language: selectedLanguage,
                            explanation: CodeExplanation.make(
                                for: snippet.insertText,
                                language: selectedLanguage
                            ),
                            copiedTitle: copiedTitle,
                            theme: model.selectedTheme,
                            strings: strings,
                            onCopy: copy
                        )
                    }
                }
            }

            Section(strings.keywords) {
                Text(selectedLanguage.keywords.joined(separator: "  "))
                    .font(
                        .system(
                            size: 13,
                            weight: .semibold,
                            design: .monospaced
                        )
                    )
                    .foregroundStyle(model.selectedTheme.secondaryText)
                    .textSelection(.enabled)
                    .padding(.vertical, 4)
            }
        }
        .scrollContentBackground(.hidden)
        .background(model.selectedTheme.background)
        .navigationTitle(strings.documentation)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    selectedLanguageID = model.selectedLanguageID
                } label: {
                    Image(systemName: "scope")
                }
                .accessibilityLabel(strings.activeLanguage)
            }
        }
        .onAppear {
            selectedLanguageID = model.selectedLanguageID
        }
    }

    private func copy(_ title: String, _ code: String) {
        UIPasteboard.general.string = code
        copiedTitle = title
    }
}

struct DocumentationCodeBlock: View {
    let title: String
    let descriptionText: String
    let code: String
    let language: CodeLanguage
    let explanation: CodeExplanation
    let copiedTitle: String?
    let theme: EditorTheme
    let strings: AppStrings
    let onCopy: (String, String) -> Void

    private var wasCopied: Bool {
        copiedTitle == title
    }

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
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                    Text(descriptionText)
                        .font(.caption)
                        .foregroundStyle(theme.secondaryText)
                }

                Spacer()

                HStack(spacing: 10) {
                    Button {
                        onCopy(title, code)
                    } label: {
                        Image(
                            systemName: wasCopied ? "checkmark" : "doc.on.doc"
                        )
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(wasCopied ? theme.success : theme.accent)
                    .accessibilityLabel(strings.codeCopy)

                    ShareLink(item: code) {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(theme.accent)
                    .accessibilityLabel(strings.codeShare)
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                Text(highlightedCode)
                    .textSelection(.enabled)
                    .padding(12)
            }
            .background(
                theme.editorBackground,
                in: RoundedRectangle(cornerRadius: 8)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(theme.border, lineWidth: 1)
            )

            NavigationLink {
                DocumentationDetailView(
                    title: title,
                    code: code,
                    language: language,
                    explanation: explanation,
                    theme: theme,
                    strings: strings
                )
            } label: {
                Label(strings.explain, systemImage: "info.circle")
                    .font(.system(size: 13, weight: .bold))
            }
            .foregroundStyle(theme.accent)
        }
        .padding(.vertical, 6)
        .listRowBackground(theme.panelBackground)
    }
}

struct DocumentationDetailView: View {
    let title: String
    let code: String
    let language: CodeLanguage
    let explanation: CodeExplanation
    let theme: EditorTheme
    let strings: AppStrings

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
        List {
            Section("Code") {
                ScrollView(.horizontal, showsIndicators: false) {
                    Text(highlightedCode)
                        .textSelection(.enabled)
                        .padding(12)
                }
                .background(
                    theme.editorBackground,
                    in: RoundedRectangle(cornerRadius: 8)
                )
            }

            Section(strings.whatDoesItDo) {
                Text(explanation.summary)
                    .foregroundStyle(theme.primaryText)
            }

            Section(strings.buildingBlocks) {
                ForEach(explanation.items) { item in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.term)
                            .font(
                                .system(
                                    size: 14,
                                    weight: .heavy,
                                    design: .monospaced
                                )
                            )
                            .foregroundStyle(theme.accent)
                        Text(item.meaning)
                            .font(.subheadline)
                            .foregroundStyle(theme.secondaryText)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(theme.background)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct CodeExplanation: Equatable {
    let summary: String
    let items: [CodeExplanationItem]

    static func make(for code: String, language: CodeLanguage)
        -> CodeExplanation
    {
        var items: [CodeExplanationItem] = []

        if language.id == "html" {
            items.append(contentsOf: htmlItems(in: code))
        } else if language.id == "css" {
            items.append(contentsOf: cssItems(in: code))
        } else if language.id == "javascript" {
            items.append(contentsOf: javascriptItems(in: code))
        } else {
            items.append(
                CodeExplanationItem(
                    term: language.name,
                    meaning:
                        "Dieser Block zeigt ein typisches Beispiel fuer \(language.name). Du kannst ihn kopieren, teilen oder als Vorlage im Editor nutzen."
                )
            )
        }

        if items.isEmpty {
            items.append(
                CodeExplanationItem(
                    term: "Code",
                    meaning:
                        "Der Block ist eine kurze Vorlage fuer die ausgewaehlte Sprache."
                )
            )
        }

        return CodeExplanation(
            summary:
                "Diese Detailansicht erklaert die wichtigsten Zeichen, Tags und Befehle im Beispiel.",
            items: items
        )
    }

    private static func htmlItems(in code: String) -> [CodeExplanationItem] {
        var items: [CodeExplanationItem] = [
            CodeExplanationItem(
                term: "<tag>",
                meaning:
                    "Oeffnet ein HTML-Element. Beispiel: <h1> startet eine Hauptueberschrift."
            ),
            CodeExplanationItem(
                term: "</tag>",
                meaning:
                    "Schliesst ein HTML-Element. Beispiel: </form> beendet ein Formular."
            ),
            CodeExplanationItem(
                term: "!",
                meaning:
                    "In <!DOCTYPE html> sagt das Ausrufezeichen dem Browser, dass eine besondere Deklaration folgt."
            ),
            CodeExplanationItem(
                term: "\"\"",
                meaning:
                    "Anfuehrungszeichen halten Attributwerte, zum Beispiel class=\"app\"."
            ),
        ]

        if code.contains("<h1") {
            items.append(
                CodeExplanationItem(
                    term: "h1",
                    meaning:
                        "Die wichtigste Ueberschrift auf der Seite. Sie sollte den Haupttitel beschreiben."
                )
            )
        }
        if code.contains("<form") {
            items.append(
                CodeExplanationItem(
                    term: "form",
                    meaning:
                        "Sammelt Eingaben, zum Beispiel Textfelder, E-Mail-Felder oder Buttons."
                )
            )
        }
        if code.contains("<input") {
            items.append(
                CodeExplanationItem(
                    term: "input",
                    meaning:
                        "Ein Eingabefeld. type=\"email\" optimiert es fuer E-Mail-Adressen."
                )
            )
        }
        if code.contains("<button") {
            items.append(
                CodeExplanationItem(
                    term: "button",
                    meaning: "Ein klickbares Element fuer Aktionen."
                )
            )
        }
        if code.contains("<main") {
            items.append(
                CodeExplanationItem(
                    term: "main",
                    meaning: "Markiert den Hauptinhalt der Seite."
                )
            )
        }
        return items
    }

    private static func cssItems(in code: String) -> [CodeExplanationItem] {
        var items: [CodeExplanationItem] = [
            CodeExplanationItem(
                term: "{ }",
                meaning:
                    "Klammern enthalten die CSS-Regeln fuer einen Selector."
            ),
            CodeExplanationItem(
                term: ":",
                meaning:
                    "Trennt Eigenschaft und Wert, zum Beispiel color: green."
            ),
            CodeExplanationItem(
                term: ";",
                meaning: "Beendet eine CSS-Deklaration."
            ),
        ]
        if code.contains("display: flex") {
            items.append(
                CodeExplanationItem(
                    term: "display: flex",
                    meaning:
                        "Aktiviert ein flexibles Layout fuer Ausrichtung in einer Richtung."
                )
            )
        }
        if code.contains("display: grid") {
            items.append(
                CodeExplanationItem(
                    term: "display: grid",
                    meaning:
                        "Aktiviert ein Rasterlayout fuer Zeilen und Spalten."
                )
            )
        }
        return items
    }

    private static func javascriptItems(in code: String)
        -> [CodeExplanationItem]
    {
        var items: [CodeExplanationItem] = [
            CodeExplanationItem(
                term: "const",
                meaning:
                    "Erstellt eine feste Variable, deren Binding nicht neu zugewiesen wird."
            ),
            CodeExplanationItem(
                term: "() =>",
                meaning: "Eine Arrow Function, oft fuer Callbacks genutzt."
            ),
            CodeExplanationItem(
                term: "{ }",
                meaning: "Block fuer Funktions- oder Kontrollfluss-Code."
            ),
        ]
        if code.contains("querySelector") {
            items.append(
                CodeExplanationItem(
                    term: "querySelector",
                    meaning:
                        "Sucht das erste passende Element im HTML-Dokument."
                )
            )
        }
        if code.contains("addEventListener") {
            items.append(
                CodeExplanationItem(
                    term: "addEventListener",
                    meaning:
                        "Registriert eine Reaktion auf ein Event, zum Beispiel einen Klick."
                )
            )
        }
        return items
    }
}

struct CodeExplanationItem: Identifiable, Equatable {
    let id = UUID()
    let term: String
    let meaning: String
}

#Preview {
    NavigationStack {
        DocumentationView(model: EditorModel())
    }
}
