//
//  ConsoleView.swift
//  Khyra
//
//  Created by Tufan Cakir on 31.07.26.
//

import SwiftUI
import UIKit

enum ConsoleTab: String, CaseIterable, Identifiable {
    case issues
    case versions

    var id: String { rawValue }

    var title: String {
        switch self {
        case .issues: "Issues"
        case .versions: "Versions"
        }
    }

    var systemImage: String {
        switch self {
        case .issues: "exclamationmark.triangle"
        case .versions: "clock.arrow.circlepath"
        }
    }
}

struct ConsoleView: View {
    let issues: [LintIssue]
    let theme: EditorTheme
    var versions: [CodeVersion] = []
    var onToggle: (() -> Void)? = nil
    var onSaveVersion: ((String) -> Void)? = nil
    var onRestoreVersion: ((CodeVersion) -> Void)? = nil
    var onDeleteVersion: ((CodeVersion) -> Void)? = nil
    var onIssueSelect: ((LintIssue) -> Void)? = nil
    var onOpenSheet: (() -> Void)? = nil
    var languageForVersion: ((CodeVersion) -> CodeLanguage)? = nil

    @State private var selectedTab: ConsoleTab = .issues
    @State private var versionName = ""
    @State private var showVersionNamePrompt = false
    @State private var previewVersion: CodeVersion?

    private var statusText: String {
        if issues.isEmpty {
            return "clean"
        }
        let errors = issues.filter { $0.severity == .error }.count
        let warnings = issues.count - errors
        if errors > 0 {
            return "\(errors) error\(errors == 1 ? "" : "s")"
        }
        return "\(warnings) warning\(warnings == 1 ? "" : "s")"
    }

    private var statusColor: Color {
        if issues.contains(where: { $0.severity == .error }) {
            return theme.error
        }
        if !issues.isEmpty {
            return theme.warning
        }
        return theme.success
    }

    var body: some View {
        VStack(spacing: 0) {
            ConsoleCategoryBar(
                selectedTab: $selectedTab,
                theme: theme,
                canSaveVersion: onSaveVersion != nil
            ) {
                versionName = ""
                showVersionNamePrompt = true
            }

            HStack(spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "terminal.fill")
                        .foregroundStyle(theme.accent)
                    Text("Terminal")
                        .font(
                            .system(
                                size: 14,
                                weight: .heavy,
                                design: .monospaced
                            )
                        )
                    Spacer()
                    Text(statusText)
                        .font(
                            .system(
                                size: 12,
                                weight: .heavy,
                                design: .monospaced
                            )
                        )
                        .foregroundStyle(statusColor)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 11, weight: .heavy))
                        .foregroundStyle(theme.secondaryText)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    onToggle?()
                }

                if let onOpenSheet {
                    Button(action: onOpenSheet) {
                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                            .font(.system(size: 12, weight: .heavy))
                            .frame(width: 32, height: 32)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(theme.accent)
                    .accessibilityLabel("Terminal gross oeffnen")
                }
            }
            .padding(.horizontal, 14)
            .frame(height: 38)
            .background(theme.consoleHeader)

            Group {
                switch selectedTab {
                case .issues:
                    issuesContent
                case .versions:
                    versionsContent
                }
            }
            .background(theme.consoleBackground)
        }
        .alert("Save Version", isPresented: $showVersionNamePrompt) {
            TextField("Version name", text: $versionName)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

            Button("Save") {
                onSaveVersion?(versionName)
                selectedTab = .versions
                versionName = ""
            }
            Button("Cancel", role: .cancel) {
                versionName = ""
            }
        } message: {
            Text("Name this local code version.")
        }
        .sheet(item: $previewVersion) { version in
            CodeVersionPreviewSheet(
                version: version,
                language: languageForVersion?(version)
                    ?? CodeLanguage.htmlFallback,
                theme: theme,
                onRestore: {
                    onRestoreVersion?(version)
                    previewVersion = nil
                },
                onDelete: {
                    onDeleteVersion?(version)
                    previewVersion = nil
                }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
            .presentationBackground(theme.background)
        }
    }

    private var issuesContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                if issues.isEmpty {
                    ConsoleLine(
                        icon: "checkmark.circle.fill",
                        text: "No lint errors found.",
                        color: theme.success
                    )
                } else {
                    ForEach(issues) { issue in
                        Button {
                            onIssueSelect?(issue)
                        } label: {
                            ConsoleIssueRow(issue: issue, theme: theme)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
        }
    }

    private var versionsContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                if versions.isEmpty {
                    ConsoleLine(
                        icon: "clock.badge.exclamationmark",
                        text: "No local versions saved.",
                        color: theme.secondaryText
                    )
                } else {
                    ForEach(versions) { version in
                        ConsoleVersionRow(
                            version: version,
                            theme: theme,
                            onRestore: {
                                onRestoreVersion?(version)
                            },
                            onInfo: {
                                previewVersion = version
                            },
                            onDelete: {
                                onDeleteVersion?(version)
                            }
                        )
                        .contextMenu {
                            Button {
                                previewVersion = version
                            } label: {
                                Label("Info", systemImage: "info.circle")
                            }
                            Button(role: .destructive) {
                                onDeleteVersion?(version)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                onDeleteVersion?(version)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
        }
    }
}

struct ConsoleCategoryBar: View {
    @Binding var selectedTab: ConsoleTab
    let theme: EditorTheme
    let canSaveVersion: Bool
    let onSaveVersion: () -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(ConsoleTab.allCases) { tab in
                    Button {
                        selectedTab = tab
                    } label: {
                        Label(tab.title, systemImage: tab.systemImage)
                            .font(
                                .system(
                                    size: 11,
                                    weight: .heavy,
                                    design: .monospaced
                                )
                            )
                            .padding(.horizontal, 10)
                            .frame(height: 30)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(
                        selectedTab == tab
                            ? theme.selectedText : theme.secondaryText
                    )
                    .background(
                        selectedTab == tab
                            ? theme.accent.opacity(0.22)
                            : theme.controlBackground,
                        in: RoundedRectangle(cornerRadius: 8)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(
                                selectedTab == tab
                                    ? theme.accent : theme.border,
                                lineWidth: 1
                            )
                    )
                }

                if canSaveVersion {
                    Button(action: onSaveVersion) {
                        Label("Save", systemImage: "plus")
                            .font(
                                .system(
                                    size: 11,
                                    weight: .heavy,
                                    design: .monospaced
                                )
                            )
                            .padding(.horizontal, 10)
                            .frame(height: 30)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(theme.selectedText)
                    .background(
                        theme.controlBackground,
                        in: RoundedRectangle(cornerRadius: 8)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(theme.success.opacity(0.7), lineWidth: 1)
                    )
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
        }
        .background(theme.panelBackground)
    }
}

struct ConsoleIssueRow: View {
    let issue: LintIssue
    let theme: EditorTheme

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: issue.severity.iconName)
                .font(.system(size: 13, weight: .heavy))
                .foregroundStyle(issue.severity.color(in: theme))
                .frame(width: 18)

            VStack(alignment: .leading, spacing: 3) {
                Text(issue.severity.title)
                    .font(
                        .system(size: 10, weight: .heavy, design: .monospaced)
                    )
                    .foregroundStyle(issue.severity.color(in: theme))
                Text("Line \(issue.line)")
                    .font(
                        .system(size: 11, weight: .heavy, design: .monospaced)
                    )
                    .foregroundStyle(theme.selectedText)
                Text(issue.message)
                    .font(
                        .system(
                            size: 12,
                            weight: .semibold,
                            design: .monospaced
                        )
                    )
                    .foregroundStyle(theme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
            Image(systemName: "arrow.up.left")
                .font(.system(size: 11, weight: .heavy))
                .foregroundStyle(theme.secondaryText)
        }
        .padding(10)
        .background(
            theme.controlBackground,
            in: RoundedRectangle(cornerRadius: 8)
        )
    }
}

struct ConsoleVersionRow: View {
    let version: CodeVersion
    let theme: EditorTheme
    let onRestore: () -> Void
    let onInfo: () -> Void
    let onDelete: () -> Void

    private var dateText: String {
        version.createdAt.formatted(date: .abbreviated, time: .shortened)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 13, weight: .heavy))
                .foregroundStyle(theme.accent)
                .frame(width: 18)

            VStack(alignment: .leading, spacing: 4) {
                Text(version.title)
                    .font(
                        .system(size: 12, weight: .heavy, design: .monospaced)
                    )
                    .foregroundStyle(theme.selectedText)
                Text(dateText)
                    .font(
                        .system(
                            size: 10,
                            weight: .semibold,
                            design: .monospaced
                        )
                    )
                    .foregroundStyle(theme.secondaryText)
                Text(
                    "\(version.lineCount) lines • \(version.issueCount) issues"
                )
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundStyle(
                    version.issueCount == 0 ? theme.success : theme.warning
                )
            }
            Spacer(minLength: 0)
            Button(action: onRestore) {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 13, weight: .heavy))
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
            .foregroundStyle(theme.secondaryText)

            Button(action: onInfo) {
                Image(systemName: "info.circle")
                    .font(.system(size: 13, weight: .heavy))
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
            .foregroundStyle(theme.accent)

            Button(role: .destructive, action: onDelete) {
                Image(systemName: "trash")
                    .font(.system(size: 12, weight: .heavy))
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
            .foregroundStyle(theme.error)
        }
        .padding(10)
        .background(
            theme.controlBackground,
            in: RoundedRectangle(cornerRadius: 8)
        )
    }
}

struct CodeVersionPreviewSheet: View {
    let version: CodeVersion
    let language: CodeLanguage
    let theme: EditorTheme
    let onRestore: () -> Void
    let onDelete: () -> Void

    private var highlightedCode: AttributedString {
        let highlighted = SyntaxHighlighter.highlight(
            version.code,
            language: language,
            theme: theme
        )
        return (try? AttributedString(highlighted, including: \.uiKit))
            ?? AttributedString(version.code)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                Text(highlightedCode)
                    .font(
                        .system(size: 13, weight: .regular, design: .monospaced)
                    )
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .background(
                        theme.editorBackground,
                        in: RoundedRectangle(cornerRadius: 8)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(theme.border, lineWidth: 1)
                    )
                    .padding(16)
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
                        Label("Restore", systemImage: "arrow.counterclockwise")
                    }
                }
            }
        }
        .preferredColorScheme(theme.preferredScheme)
    }
}

struct ConsoleCollapsedBar: View {
    let theme: EditorTheme
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 8) {
                Image(systemName: "terminal")
                    .foregroundStyle(theme.accent)
                Text("Terminal")
                    .font(
                        .system(size: 14, weight: .heavy, design: .monospaced)
                    )
                Spacer()
                Image(systemName: "chevron.up")
                    .font(.system(size: 11, weight: .heavy))
                    .foregroundStyle(theme.secondaryText)
            }
            .padding(.horizontal, 14)
            .frame(height: 42)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .background(theme.consoleHeader)
    }
}

struct SaveToast: View {
    let theme: EditorTheme

    var body: some View {
        Label("Saved", systemImage: "checkmark.circle.fill")
            .font(.system(size: 13, weight: .heavy, design: .monospaced))
            .padding(.horizontal, 14)
            .frame(height: 40)
            .foregroundStyle(theme.selectedText)
            .background(
                theme.panelBackground,
                in: RoundedRectangle(cornerRadius: 8)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(theme.success.opacity(0.7), lineWidth: 1)
            )
    }
}

struct ConsoleLine: View {
    let icon: String
    let text: String
    let color: Color

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .heavy))
                .foregroundStyle(color)
                .frame(width: 18)
            Text(text)
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundStyle(color)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

extension LintSeverity {
    var title: String {
        switch self {
        case .error: "Error"
        case .warning: "Warning"
        }
    }
}
