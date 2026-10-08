//
//  CodeVersionComparisonView.swift
//  Khyra
//
//  Created by Tufan Cakir on 31.07.26.
//

import SwiftUI
import UIKit

struct CodeVersionComparisonView: View {
    let version: CodeVersion
    let currentCode: String
    let language: CodeLanguage
    let theme: EditorTheme
    let strings: AppStrings
    let onRestore: () -> Void
    let onDelete: () -> Void

    @State private var selectedMode = VersionComparisonMode.changes
    @State private var diffLines: [CodeDiffLine] = []

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                VersionComparisonModePicker(
                    selectedMode: $selectedMode,
                    versionTitle: "Version",
                    changesTitle: "Diff"
                )

                switch selectedMode {
                case .version:
                    VersionCodeSnapshot(
                        code: version.code,
                        language: language,
                        theme: theme
                    )
                case .changes:
                    CodeDiffView(
                        lines: diffLines,
                        theme: theme,
                        oldTitle: version.title,
                        newTitle: strings.editor
                    )
                }
            }
            .background(theme.background)
            .foregroundStyle(theme.primaryText)
            .navigationTitle(version.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(role: .destructive, action: onDelete) {
                        Image(systemName: "trash")
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: onRestore) {
                        Label(
                            strings.restore,
                            systemImage: "arrow.counterclockwise"
                        )
                    }
                }
            }
            .task(id: currentCode) {
                diffLines = CodeDiffEngine.compare(
                    old: version.code,
                    new: currentCode
                )
            }
        }
        .preferredColorScheme(theme.preferredScheme)
    }
}

private enum VersionComparisonMode: String, CaseIterable, Identifiable {
    case version
    case changes

    var id: String { rawValue }
}

private struct VersionComparisonModePicker: View {
    @Binding var selectedMode: VersionComparisonMode

    let versionTitle: String
    let changesTitle: String

    var body: some View {
        Picker("Ansicht", selection: $selectedMode) {
            Label(versionTitle, systemImage: "doc.text")
                .tag(VersionComparisonMode.version)
            Label(changesTitle, systemImage: "arrow.left.arrow.right")
                .tag(VersionComparisonMode.changes)
        }
        .pickerStyle(.segmented)
        .padding()
    }
}

private struct VersionCodeSnapshot: View {
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
        ScrollView([.horizontal, .vertical]) {
            Text(highlightedCode)
                .font(.system(.callout, design: .monospaced))
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
        }
        .background(theme.editorBackground)
    }
}

private struct CodeDiffView: View {
    let lines: [CodeDiffLine]
    let theme: EditorTheme
    let oldTitle: String
    let newTitle: String

    var body: some View {
        VStack(spacing: 0) {
            CodeDiffSummary(
                lines: lines,
                oldTitle: oldTitle,
                newTitle: newTitle,
                theme: theme
            )

            ScrollView([.horizontal, .vertical]) {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(lines) { line in
                        CodeDiffRow(line: line, theme: theme)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(theme.editorBackground)
        }
    }
}

private struct CodeDiffSummary: View {
    let lines: [CodeDiffLine]
    let oldTitle: String
    let newTitle: String
    let theme: EditorTheme

    private var additions: Int {
        lines.lazy.filter { $0.kind == .added }.count
    }

    private var removals: Int {
        lines.lazy.filter { $0.kind == .removed }.count
    }

    var body: some View {
        HStack(spacing: 12) {
            Label(oldTitle, systemImage: "clock.arrow.circlepath")
                .lineLimit(1)
            Image(systemName: "arrow.right")
                .accessibilityHidden(true)
            Label(newTitle, systemImage: "pencil")
                .lineLimit(1)
            Spacer()
            Text("+\(additions)")
                .foregroundStyle(theme.success)
            Text("−\(removals)")
                .foregroundStyle(theme.error)
        }
        .font(.caption.weight(.bold))
        .padding(.horizontal)
        .padding(.bottom, 10)
    }
}

private struct CodeDiffRow: View {
    let line: CodeDiffLine
    let theme: EditorTheme

    private var marker: String {
        switch line.kind {
        case .unchanged: " "
        case .added: "+"
        case .removed: "−"
        }
    }

    private var markerColor: Color {
        switch line.kind {
        case .unchanged: theme.secondaryText
        case .added: theme.success
        case .removed: theme.error
        }
    }

    private var backgroundColor: Color {
        switch line.kind {
        case .unchanged: .clear
        case .added: theme.success.opacity(0.14)
        case .removed: theme.error.opacity(0.14)
        }
    }

    var body: some View {
        HStack(spacing: 8) {
            Text(line.oldLineNumber.map(String.init) ?? "")
                .frame(width: 34, alignment: .trailing)
            Text(line.newLineNumber.map(String.init) ?? "")
                .frame(width: 34, alignment: .trailing)
            Text(marker)
                .fontWeight(.bold)
                .foregroundStyle(markerColor)
                .frame(width: 12)
            Text(line.text.isEmpty ? " " : line.text)
                .foregroundStyle(theme.primaryText)
        }
        .font(.system(.caption, design: .monospaced))
        .padding(.horizontal, 8)
        .frame(minHeight: 23)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(backgroundColor)
        .accessibilityElement(children: .combine)
    }
}
