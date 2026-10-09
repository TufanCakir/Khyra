//
//  AIAssistantView.swift
//  Khyra
//
//  Created by Tufan Cakir on 31.07.26.
//

import SwiftUI

#if canImport(FoundationModels)
    import FoundationModels
#endif

enum AIAssistantMode: String, CaseIterable, Identifiable {
    case generate
    case improve
    case repair
    case explain
    case agent

    var id: String { rawValue }

    func title(languageCode: String) -> String {
        let locale = Locale(identifier: languageCode)
        switch self {
        case .generate: return String(localized: "Create", locale: locale)
        case .improve: return String(localized: "Improve", locale: locale)
        case .repair: return String(localized: "Repair", locale: locale)
        case .explain: return String(localized: "Explain", locale: locale)
        case .agent: return String(localized: "Agent", locale: locale)
        }
    }

    var promptInstruction: String {
        switch self {
        case .generate:
            "Create complete code for the requested task."
        case .improve:
            "Improve the existing code while preserving its behavior."
        case .repair:
            "Repair errors in the existing code and return the corrected code."
        case .explain:
            "Explain the existing code clearly and compactly. Do not return replacement code."
        case .agent:
            "Plan complete project file and folder changes for the requested task."
        }
    }

    var producesCode: Bool {
        self != .explain && self != .agent
    }

    var isAgent: Bool { self == .agent }
}

struct AIAssistantView: View {
    let model: EditorModel
    let onOpenEditor: () -> Void

    var body: some View {
        if #available(iOS 26.0, *) {
            FoundationModelAssistantView(
                model: model,
                onOpenEditor: onOpenEditor
            )
        } else {
            AIAssistantUnavailableView(
                title: String(
                    localized: "AI requires iOS 26",
                    locale: model.appLocale
                ),
                message: String(
                    localized:
                        "Update your device to use the on-device language model.",
                    locale: model.appLocale
                )
            )
        }
    }

}

@available(iOS 26.0, *)
private struct FoundationModelAssistantView: View {
    let model: EditorModel
    let onOpenEditor: () -> Void

    @State private var showReplaceConfirmation = false
    @State private var generationTask: Task<Void, Never>?
    @State private var prompt = ""
    @State private var selectedMode: AIAssistantMode = .generate
    @State private var generatedCode = ""
    @State private var errorMessage: String?
    @State private var isGenerating = false
    @State private var projectPlan: AIProjectPlan?
    @State private var showApplyPlanConfirmation = false

    var body: some View {
        Group {
            #if canImport(FoundationModels)
                switch SystemLanguageModel.default.availability {

                case .available:
                    AIAssistantWorkspace(
                        prompt: $prompt,
                        mode: $selectedMode,
                        generatedCode: generatedCode,
                        projectPlan: projectPlan,
                        errorMessage: errorMessage,
                        isGenerating: isGenerating,
                        languageName: model.selectedLanguage.name,
                        theme: model.selectedTheme,
                        strings: strings,
                        onGenerate: generate,
                        onCancel: cancelGeneration,
                        onReplace: {
                            if model.activeCode.wrappedValue.isEmpty {
                                replaceActiveCode()
                            } else {
                                showReplaceConfirmation = true
                            }
                        },
                        onAppend: appendToActiveCode,
                        onOpenEditor: onOpenEditor,
                        onApplyPlan: {
                            showApplyPlanConfirmation = true
                        }
                    )
                case .unavailable(.deviceNotEligible):
                    AIAssistantUnavailableView(
                        title: strings.deviceUnavailableTitle,
                        message: strings.deviceUnavailableMessage
                    )
                case .unavailable(.appleIntelligenceNotEnabled):
                    AIAssistantUnavailableView(
                        title: strings.appleIntelligenceDisabledTitle,
                        message: strings.appleIntelligenceDisabledMessage
                    )
                case .unavailable(.modelNotReady):
                    AIAssistantUnavailableView(
                        title: strings.modelNotReadyTitle,
                        message: strings.modelNotReadyMessage
                    )
                case .unavailable:
                    AIAssistantUnavailableView(
                        title: strings.unavailableTitle,
                        message: strings.unavailableMessage
                    )
                }
            #else
                AIAssistantUnavailableView(
                    title: strings.unavailableTitle,
                    message: strings.unavailableMessage
                )
            #endif
        }
        .background(model.selectedTheme.background)
        .navigationTitle(strings.title)
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog(
            strings.replaceConfirmationTitle,
            isPresented: $showReplaceConfirmation
        ) {
            Button(strings.replace, role: .destructive) {
                replaceActiveCode()
            }

            Button(strings.cancel, role: .cancel) {}
        } message: {
            Text(strings.replaceConfirmationMessage)
        }
        .alert(
            strings.applyPlanTitle,
            isPresented: $showApplyPlanConfirmation
        ) {
            Button(strings.applyPlan) {
                guard let projectPlan else { return }
                model.applyAIProjectPlan(projectPlan)
                self.projectPlan = nil
                onOpenEditor()
            }
            Button(strings.cancel, role: .cancel) {}
        } message: {
            Text(projectPlan?.summary ?? "")
        }
        .onDisappear {
            generationTask?.cancel()
        }
    }

    private var strings: AIAssistantStrings {
        AIAssistantStrings(languageCode: model.resolvedAppLanguageCode)
    }

    #if canImport(FoundationModels)

        private func generate() {
            let trimmedPrompt = prompt.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

            guard !trimmedPrompt.isEmpty, !isGenerating else {
                return
            }

            isGenerating = true
            generatedCode = ""
            projectPlan = nil
            errorMessage = nil

            let language = model.selectedLanguage.name
            let currentCode = String(
                model.activeCode.wrappedValue.suffix(4_000)
            )
            let projectStructure = model.projectItems.map { item in
                item.kind == .folder
                    ? "folder: \(item.name)"
                    : "file: \(item.name) [\(item.languageID ?? "text")]"
            }.joined(separator: "\n")

            let request = """
                Language: \(language)
                Mode: \(selectedMode.promptInstruction)
                User request: \(trimmedPrompt)

                Current project structure:
                \(projectStructure)

                Current editor content, if useful:
                \(currentCode)
                """

            generationTask = Task { @MainActor in
                defer {
                    isGenerating = false
                    generationTask = nil
                }

                do {
                    let session = LanguageModelSession(
                        instructions: """
                            You are Khyra's precise coding assistant.
                            Follow the selected mode exactly.
                            For code-producing modes, return only complete code without Markdown fences.
                            For explanation mode, return a concise explanation in the person's language.
                            Respect existing code and never claim that unverified code is guaranteed to compile.
                            """
                    )

                    if selectedMode.isAgent {
                        let response = try await session.respond(
                            to: request,
                            generating: GeneratedAIProjectPlan.self
                        )
                        projectPlan = response.content.projectPlan
                        return
                    }

                    for try await partial in session.streamResponse(
                        to: request
                    ) {
                        try Task.checkCancellation()
                        generatedCode =
                            selectedMode.producesCode
                            ? sanitize(partial.content)
                            : partial.content.trimmingCharacters(
                                in: .whitespacesAndNewlines
                            )
                    }
                } catch is CancellationError {
                    // Nutzer hat die Generierung abgebrochen.
                } catch {
                    guard !Task.isCancelled else { return }
                    errorMessage = strings.generationFailed
                }
            }
        }

        private func cancelGeneration() {
            generationTask?.cancel()
        }

    #endif

    private func replaceActiveCode() {
        model.replaceActiveCodeFromAI(generatedCode)
        onOpenEditor()
    }

    private func appendToActiveCode() {
        model.appendActiveCodeFromAI(generatedCode)
        onOpenEditor()
    }

    private func sanitize(_ response: String) -> String {
        var result = response.trimmingCharacters(in: .whitespacesAndNewlines)
        guard result.hasPrefix("```") else { return result }

        if let firstLineEnd = result.firstIndex(of: "\n") {
            result = String(result[result.index(after: firstLineEnd)...])
        }
        if result.hasSuffix("```") {
            result.removeLast(3)
        }
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

private struct AIAssistantWorkspace: View {
    @Binding var prompt: String
    @Binding var mode: AIAssistantMode

    let generatedCode: String
    let projectPlan: AIProjectPlan?
    let errorMessage: String?
    let isGenerating: Bool
    let languageName: String
    let theme: EditorTheme
    let strings: AIAssistantStrings

    let onGenerate: () -> Void
    let onCancel: () -> Void
    let onReplace: () -> Void
    let onAppend: () -> Void
    let onOpenEditor: () -> Void
    let onApplyPlan: () -> Void

    @FocusState private var isPromptFocused: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                AIAssistantHeader(
                    title: strings.headerTitle,
                    subtitle: strings.headerSubtitle
                )

                Picker(
                    strings.modeTitle,
                    selection: $mode
                ) {
                    ForEach(AIAssistantMode.allCases) { item in
                        Text(item.title(languageCode: strings.languageCode))
                            .tag(item)
                    }
                }
                .pickerStyle(.segmented)

                AIPromptComposer(
                    prompt: $prompt,
                    isFocused: $isPromptFocused,
                    placeholder: strings.placeholder,
                    buttonTitle: strings.generate,
                    cancelTitle: strings.languageCode == "de"
                        ? "Abbrechen"
                        : "Cancel",
                    theme: theme,
                    isGenerating: isGenerating,
                    onGenerate: onGenerate,
                    onCancel: onCancel
                )

                if let errorMessage {
                    Label(
                        errorMessage,
                        systemImage: "exclamationmark.triangle.fill"
                    )
                    .font(.callout)
                    .foregroundStyle(.red)
                }

                if let projectPlan {
                    AIProjectPlanCard(
                        plan: projectPlan,
                        strings: strings,
                        onApply: onApplyPlan
                    )
                }

                if isGenerating && generatedCode.isEmpty {
                    AIGenerationStatusCard(
                        title: strings.generating,
                        message: strings.onDeviceProcessing,
                        theme: theme
                    )
                }

                if !generatedCode.isEmpty {
                    AIGeneratedCodeCard(
                        code: generatedCode,
                        languageName: languageName,
                        generatingTitle: strings.generating,
                        replaceTitle: strings.replace,
                        appendTitle: strings.append,
                        isGenerating: isGenerating,
                        theme: theme,
                        onReplace: onReplace,
                        onAppend: onAppend,
                        onOpenEditor: onOpenEditor,
                        openEditorTitle: strings.openEditor,
                        allowsCodeActions: mode.producesCode
                    )
                }
            }
            .padding()
        }
        .scrollDismissesKeyboard(.interactively)
        .keyboardDismissToolbar(
            accessibilityTitle: strings.languageCode == "de"
                ? "Tastatur schließen"
                : "Dismiss Keyboard"
        ) {
            isPromptFocused = false
        }
    }
}

private struct AIAssistantHeader: View {
    let title: String
    let subtitle: String

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.title2.bold())

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 8)
    }
}

private struct AIPromptComposer: View {
    @Binding var prompt: String
    @FocusState.Binding var isFocused: Bool

    let placeholder: String
    let buttonTitle: String
    let cancelTitle: String
    let theme: EditorTheme
    let isGenerating: Bool
    let onGenerate: () -> Void
    let onCancel: () -> Void

    private var isPromptEmpty: Bool {
        prompt.trimmingCharacters(
            in: .whitespacesAndNewlines
        ).isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            promptField

            if isFocused {
                HStack {
                    Spacer()

                    Button {
                        isFocused = false
                    } label: {
                        Label(
                            "Fertig",
                            systemImage: "keyboard.chevron.compact.down"
                        )
                    }
                    .buttonStyle(.bordered)
                }
            }

            actionButton
        }
    }

    // MARK: - Prompt Field

    private var promptField: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .topLeading) {
                if prompt.isEmpty {
                    Text(placeholder)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 8)
                        .allowsHitTesting(false)
                }

                TextEditor(text: $prompt)
                    .focused($isFocused)
                    .font(.body)
                    .frame(height: 128)
                    .scrollContentBackground(.hidden)
                    .disabled(isGenerating)
            }

            HStack {
                Spacer()

                Text(prompt.count, format: .number)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.tertiary)
                    .contentTransition(.numericText())
            }
        }
        .padding(14)
        .background(
            .regularMaterial,
            in: RoundedRectangle(cornerRadius: 18)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(
                    isFocused
                        ? theme.accent.opacity(0.75)
                        : Color.primary.opacity(0.08),
                    lineWidth: isFocused ? 1.5 : 1
                )
        }
    }

    // MARK: - Action Button

    @ViewBuilder
    private var actionButton: some View {
        if isGenerating {
            Button(role: .destructive) {
                onCancel()
            } label: {
                HStack(spacing: 10) {
                    ProgressView()
                        .controlSize(.small)

                    Text(cancelTitle)
                        .fontWeight(.medium)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
        } else {
            Button {
                isFocused = false
                onGenerate()
            } label: {
                Text(buttonTitle)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(isPromptEmpty)
        }
    }
}

private struct AIGenerationStatusCard: View {
    let title: String
    let message: String
    let theme: EditorTheme

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 16) {
            ProgressView()
                .controlSize(.large)
                .tint(theme.accent)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(theme.primaryText)

                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(theme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            theme.accent.opacity(0.08),
            in: RoundedRectangle(cornerRadius: 18, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(theme.accent, lineWidth: 2)
                .phaseAnimator(reduceMotion ? [false] : [false, true]) {
                    content,
                    highlighted in
                    content.opacity(highlighted ? 0.35 : 0.9)
                } animation: { _ in
                    .easeInOut(duration: 0.9)
                }
        }
        .accessibilityElement(children: .combine)
    }
}

private struct AIProjectPlanCard: View {
    let plan: AIProjectPlan
    let strings: AIAssistantStrings
    let onApply: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(strings.projectPlan, systemImage: "folder.badge.gearshape")
                .font(.headline)

            Text(plan.summary)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if !plan.folders.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(plan.folders, id: \.self) { folder in
                        Label(folder, systemImage: "folder")
                    }
                }
                .font(.caption)
            }

            VStack(alignment: .leading, spacing: 8) {
                ForEach(plan.files) { file in
                    HStack {
                        Image(systemName: "doc.text")
                        Text(file.name)
                            .font(.system(.callout, design: .monospaced))
                        Spacer()
                        Text(file.languageID.uppercased())
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Button(action: onApply) {
                Label(strings.applyPlan, systemImage: "checkmark.circle.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

private struct AIGeneratedCodeCard: View {
    let code: String
    let languageName: String
    let generatingTitle: String
    let replaceTitle: String
    let appendTitle: String
    let isGenerating: Bool
    let theme: EditorTheme
    let onReplace: () -> Void
    let onAppend: () -> Void
    let onOpenEditor: () -> Void
    let openEditorTitle: String
    let allowsCodeActions: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(
                    languageName,
                    systemImage: "chevron.left.forwardslash.chevron.right"
                )
                .font(.headline)
                Spacer()
                if isGenerating {
                    Text(generatingTitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            ScrollView(.horizontal) {
                Text(code.isEmpty ? "…" : code)
                    .font(.system(.callout, design: .monospaced))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(minHeight: 160, maxHeight: 360)

            if allowsCodeActions {
                ViewThatFits {
                    HStack {
                        actionButtons
                    }
                    VStack {
                        actionButtons
                    }
                }
                .disabled(code.isEmpty || isGenerating)
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    isGenerating ? theme.accent : theme.border,
                    lineWidth: isGenerating ? 2 : 1
                )
        }
    }

    @ViewBuilder
    private var actionButtons: some View {
        Button(action: onReplace) {
            Label(replaceTitle, systemImage: "arrow.triangle.2.circlepath")
        }
        .buttonStyle(.borderedProminent)

        Button(action: onAppend) {
            Label(appendTitle, systemImage: "text.append")
        }
        .buttonStyle(.bordered)

        Button(action: onOpenEditor) {
            Label(openEditorTitle, systemImage: "arrow.right.circle")
        }
        .buttonStyle(.bordered)
    }
}

private struct AIAssistantUnavailableView: View {
    let title: String
    let message: String

    var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: "apple.intelligence")
        } description: {
            Text(message)
        }
    }
}

private struct AIAssistantStrings {
    let languageCode: String

    private var locale: Locale {
        Locale(identifier: languageCode)
    }

    private func localized(_ resource: String.LocalizationValue) -> String {
        String(localized: resource, locale: locale)
    }

    // MARK: - Navigation

    var title: String {
        "Khyra AI"
    }

    // MARK: - Header

    var headerTitle: String {
        localized("What would you like to create?")
    }

    var headerSubtitle: String {
        localized("Your intelligent coding assistant. Right on your device.")
    }

    // MARK: - Prompt

    var placeholder: String {
        localized(
            "Describe your idea, a feature, or something you'd like to improve…"
        )
    }

    // MARK: - Generation

    var modeTitle: String {
        localized("Mode")
    }

    var generate: String {
        localized("Generate")
    }

    var generating: String {
        localized("Generating code…")
    }

    var onDeviceProcessing: String {
        localized("AI processing happens directly on your device.")
    }

    var cancel: String {
        localized("Cancel")
    }

    var generationFailed: String {
        localized("Generation failed. Please try again.")
    }

    // MARK: - Editor Actions

    var replace: String {
        localized("Replace code")
    }

    var append: String {
        localized("Add code")
    }

    var openEditor: String {
        localized("Open Editor")
    }

    var copy: String {
        localized("Copy")
    }

    // MARK: - Confirmation

    var projectPlan: String {
        localized("Project Plan")
    }

    var applyPlan: String {
        localized("Apply Plan")
    }

    var applyPlanTitle: String {
        localized("Apply project changes?")
    }

    var replaceConfirmationTitle: String {
        localized("Replace existing code?")
    }

    var replaceConfirmationMessage: String {
        localized(
            "The current editor content will be replaced with the generated code."
        )
    }

    // MARK: - Device Availability

    var deviceUnavailableTitle: String {
        localized("Device not supported")
    }

    var deviceUnavailableMessage: String {
        localized(
            "Khyra AI requires a device that supports Apple Intelligence."
        )
    }

    // MARK: - Apple Intelligence

    var appleIntelligenceDisabledTitle: String {
        localized("Apple Intelligence is disabled")
    }

    var appleIntelligenceDisabledMessage: String {
        localized("Enable Apple Intelligence in Settings to use Khyra AI.")
    }

    // MARK: - Model Status

    var modelNotReadyTitle: String {
        localized("AI is getting ready")
    }

    var modelNotReadyMessage: String {
        localized(
            "The language model isn't ready yet. Please try again shortly."
        )
    }

    // MARK: - Unavailable

    var unavailableTitle: String {
        localized("Khyra AI unavailable")
    }

    var unavailableMessage: String {
        localized(
            "The AI assistant is currently unavailable. Please try again later."
        )
    }

    // MARK: - Privacy

    var privacyTitle: String {
        localized("Private and on-device")
    }

    var privacyMessage: String {
        localized("AI processing happens directly on your device.")
    }
}
