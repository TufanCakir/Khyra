//
//  EditorEnhancementsView.swift
//  Khyra
//
//  Created by Tufan Cakir on 31.07.26.
//

import SwiftUI

#if canImport(FoundationModels)
    import FoundationModels
#endif

enum EditorAIAction: String, CaseIterable, Identifiable {
    case explain
    case improve
    case repair

    var id: String { rawValue }

    func title(isGerman: Bool) -> String {
        switch self {
        case .explain: isGerman ? "Erklären" : "Explain"
        case .improve: isGerman ? "Verbessern" : "Improve"
        case .repair: isGerman ? "Reparieren" : "Repair"
        }
    }

    var systemImage: String {
        switch self {
        case .explain: "text.magnifyingglass"
        case .improve: "wand.and.stars"
        case .repair: "wrench.and.screwdriver"
        }
    }
}

struct EditorAISelectionView: View {
    let model: EditorModel
    let initialAction: EditorAIAction

    @Environment(\.dismiss) private var dismiss
    @State private var action: EditorAIAction
    @State private var result = ""
    @State private var isGenerating = false
    @State private var errorMessage: String?

    init(model: EditorModel, initialAction: EditorAIAction) {
        self.model = model
        self.initialAction = initialAction
        _action = State(initialValue: initialAction)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Picker("KI-Aktion", selection: $action) {
                        ForEach(EditorAIAction.allCases) { item in
                            Label(
                                item.title(isGerman: isGerman),
                                systemImage: item.systemImage
                            )
                            .tag(item)
                        }
                    }
                    .pickerStyle(.segmented)

                    SelectionCodeCard(
                        code: model.selectedCode,
                        title: isGerman ? "Auswahl" : "Selection"
                    )

                    if isGenerating {
                        HStack(spacing: 10) {
                            ProgressView()
                            Text(
                                isGerman
                                    ? "KI arbeitet lokal …"
                                    : "AI is working on device…"
                            )
                        }
                    }

                    if let errorMessage {
                        Label(
                            errorMessage,
                            systemImage: "exclamationmark.triangle.fill"
                        )
                        .foregroundStyle(.red)
                    }

                    if !result.isEmpty {
                        SelectionCodeCard(
                            code: result,
                            title: action.title(isGerman: isGerman)
                        )

                        if action != .explain {
                            Button {
                                model.replaceSelectedCode(
                                    with: sanitizedCode(result),
                                    versionTitle:
                                        "Vor KI-\(action.title(isGerman: true))"
                                )
                                dismiss()
                            } label: {
                                Label(
                                    isGerman
                                        ? "Auswahl ersetzen"
                                        : "Replace selection",
                                    systemImage: "checkmark.circle.fill"
                                )
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }

                    Button(action: generate) {
                        Label(
                            isGerman
                                ? "Mit Apple Intelligence ausführen"
                                : "Run with Apple Intelligence",
                            systemImage: "apple.intelligence"
                        )
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(model.selectedCode.isEmpty || isGenerating)
                }
                .padding()
            }
            .navigationTitle(isGerman ? "KI für Auswahl" : "AI Selection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(isGerman ? "Schließen" : "Close") { dismiss() }
                }
            }
        }
        .preferredColorScheme(model.selectedTheme.preferredScheme)
    }

    private var isGerman: Bool { model.resolvedAppLanguageCode == "de" }

    private func generate() {
        guard !model.selectedCode.isEmpty else { return }
        guard #available(iOS 26.0, *) else {
            errorMessage = isGerman ? "Benötigt iOS 26." : "Requires iOS 26."
            return
        }

        isGenerating = true
        result = ""
        errorMessage = nil
        generateWithFoundationModels()
    }

    @available(iOS 26.0, *)
    private func generateWithFoundationModels() {
        #if canImport(FoundationModels)
            guard case .available = SystemLanguageModel.default.availability
            else {
                isGenerating = false
                errorMessage =
                    isGerman
                    ? "Apple Intelligence ist nicht verfügbar."
                    : "Apple Intelligence is unavailable."
                return
            }

            let selectedCode = model.selectedCode
            let language = model.selectedLanguage.name
            let task: String
            switch action {
            case .explain:
                task =
                    "Explain this code clearly and compactly in \(isGerman ? "German" : "English")."
            case .improve:
                task =
                    "Improve readability, safety, and modern API usage. Return only replacement code."
            case .repair:
                task =
                    "Repair errors while preserving behavior. Return only replacement code."
            }

            Task {
                defer { isGenerating = false }
                do {
                    let session = LanguageModelSession(
                        instructions: """
                            You are Khyra's precise code assistant.
                            Never invent unavailable APIs. Keep the response compact.
                            """
                    )
                    let response = try await session.respond(
                        to: """
                            Language: \(language)
                            Task: \(task)

                            Selected code:
                            \(selectedCode)
                            """
                    )
                    result =
                        action == .explain
                        ? response.content.trimmingCharacters(
                            in: .whitespacesAndNewlines
                        )
                        : sanitizedCode(response.content)
                } catch {
                    errorMessage =
                        isGerman
                        ? "Die KI-Aktion konnte nicht ausgeführt werden."
                        : "The AI action could not be completed."
                }
            }
        #else
            isGenerating = false
            errorMessage =
                isGerman
                ? "Foundation Models fehlt."
                : "Foundation Models is unavailable."
        #endif
    }

    private func sanitizedCode(_ value: String) -> String {
        var code = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if code.hasPrefix("```"), let end = code.firstIndex(of: "\n") {
            code = String(code[code.index(after: end)...])
        }
        if code.hasSuffix("```") {
            code.removeLast(3)
        }
        return code.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

private struct SelectionCodeCard: View {
    let code: String
    let title: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            Text(code.isEmpty ? "—" : code)
                .font(.system(.callout, design: .monospaced))
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14))
    }
}

struct InlineDiagnosticsView: View {
    let issues: [LintIssue]
    let theme: EditorTheme
    let isGerman: Bool
    let onSelect: (LintIssue) -> Void
    let onQuickFix: (LintIssue) -> Void
    let onAIFix: (LintIssue) -> Void

    var body: some View {
        if !issues.isEmpty {
            ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    ForEach(issues) { issue in
                        InlineDiagnosticCard(
                            issue: issue,
                            theme: theme,
                            isGerman: isGerman,
                            onSelect: { onSelect(issue) },
                            onQuickFix: { onQuickFix(issue) },
                            onAIFix: { onAIFix(issue) }
                        )
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
            }
            .scrollIndicators(.hidden)
            .background(theme.panelBackground)
        }
    }
}

private struct InlineDiagnosticCard: View {
    let issue: LintIssue
    let theme: EditorTheme
    let isGerman: Bool
    let onSelect: () -> Void
    let onQuickFix: () -> Void
    let onAIFix: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Button(action: onSelect) {
                Label(
                    "L\(issue.line): \(issue.message)",
                    systemImage: issue.severity.iconName
                )
                .lineLimit(2)
            }
            .buttonStyle(.plain)

            Menu {
                Button(action: onQuickFix) {
                    Label(
                        isGerman ? "Quick Fix" : "Quick Fix",
                        systemImage: "bolt.fill"
                    )
                }
                Button(action: onAIFix) {
                    Label(
                        isGerman ? "Mit KI reparieren" : "Repair with AI",
                        systemImage: "apple.intelligence"
                    )
                }
            } label: {
                Image(systemName: "wrench.adjustable.fill")
            }
            .accessibilityLabel(isGerman ? "Fehler beheben" : "Fix issue")
        }
        .font(.caption)
        .foregroundStyle(issue.severity.color(in: theme))
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            theme.controlBackground,
            in: RoundedRectangle(cornerRadius: 10)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 10)
                .stroke(issue.severity.color(in: theme).opacity(0.4))
        }
    }
}

enum EditorWorkspacePanel: String, CaseIterable, Identifiable {
    case editor
    case console

    var id: String { rawValue }

    func title(isGerman: Bool) -> String {
        switch self {
        case .editor: isGerman ? "Editor" : "Editor"
        case .console: isGerman ? "Konsole" : "Console"
        }
    }

    var systemImage: String {
        switch self {
        case .editor: "chevron.left.forwardslash.chevron.right"
        case .console: "terminal"
        }
    }
}

struct EditorLayoutCustomizationView: View {
    @Binding var panels: [EditorWorkspacePanel]
    @Binding var showsSuggestions: Bool
    @Binding var showsDiagnostics: Bool
    let isGerman: Bool

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section(isGerman ? "Andocken & Reihenfolge" : "Docking & Order")
                {
                    ForEach(panels) { panel in
                        HStack {
                            Label(
                                panel.title(isGerman: isGerman),
                                systemImage: panel.systemImage
                            )
                            Spacer()
                            Image(systemName: "line.3.horizontal")
                                .foregroundStyle(.secondary)
                        }
                        .draggable(panel.rawValue)
                        .dropDestination(for: String.self) { values, _ in
                            guard let rawValue = values.first,
                                let dragged = EditorWorkspacePanel(
                                    rawValue: rawValue
                                )
                            else { return false }
                            move(dragged, before: panel)
                            return true
                        }
                    }
                    .onMove { source, destination in
                        panels.move(fromOffsets: source, toOffset: destination)
                    }
                }

                Section(isGerman ? "Editor-Bereiche" : "Editor Areas") {
                    Toggle(
                        isGerman ? "Vorschläge" : "Suggestions",
                        isOn: $showsSuggestions
                    )
                    Toggle(
                        isGerman ? "Inline-Fehler" : "Inline diagnostics",
                        isOn: $showsDiagnostics
                    )
                }
            }
            .environment(\.editMode, .constant(.active))
            .navigationTitle(isGerman ? "Layout bearbeiten" : "Edit Layout")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(isGerman ? "Fertig" : "Done") { dismiss() }
                }
            }
        }
    }

    private func move(
        _ dragged: EditorWorkspacePanel,
        before target: EditorWorkspacePanel
    ) {
        guard dragged != target,
            let source = panels.firstIndex(of: dragged),
            let destination = panels.firstIndex(of: target)
        else { return }

        var updated = panels
        let item = updated.remove(at: source)
        updated.insert(item, at: destination)
        panels = updated
    }
}
