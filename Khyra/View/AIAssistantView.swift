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

struct AIAssistantView: View {
    let model: EditorModel

    var body: some View {
        if #available(iOS 26.0, *) {
            FoundationModelAssistantView(model: model)
        } else {
            AIAssistantUnavailableView(
                title: localized(
                    german: "KI benötigt iOS 26",
                    english: "AI requires iOS 26"
                ),
                message: localized(
                    german:
                        "Aktualisiere dein Gerät, um das lokale Sprachmodell zu verwenden.",
                    english:
                        "Update your device to use the on-device language model."
                )
            )
        }
    }

    private func localized(german: String, english: String) -> String {
        model.appLanguageCode == "de" ? german : english
    }
}

@available(iOS 26.0, *)
private struct FoundationModelAssistantView: View {
    let model: EditorModel

    @State private var showReplaceConfirmation = false
    @State private var generationTask: Task<Void, Never>?
    @State private var prompt = ""
    @State private var generatedCode = ""
    @State private var errorMessage: String?
    @State private var isGenerating = false

    var body: some View {
        Group {
            #if canImport(FoundationModels)
                switch SystemLanguageModel.default.availability {

                case .available:
                    AIAssistantWorkspace(
                        prompt: $prompt,
                        generatedCode: generatedCode,
                        errorMessage: errorMessage,
                        isGenerating: isGenerating,
                        languageName: model.selectedLanguage.name,
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
                        onAppend: appendToActiveCode
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
        }.onDisappear {
            generationTask?.cancel()
        }
    }

    private var strings: AIAssistantStrings {
        AIAssistantStrings(languageCode: model.appLanguageCode)
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
            errorMessage = nil

            let language = model.selectedLanguage.name
            let currentCode = String(
                model.activeCode.wrappedValue.suffix(4_000)
            )

            let request = """
                Language: \(language)
                Task: \(trimmedPrompt)

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
                            You are Khyra's code assistant.
                            Return only code in the requested language.
                            Do not use Markdown code fences.
                            Respect existing code when relevant.
                            """
                    )

                    for try await partial in session.streamResponse(
                        to: request
                    ) {
                        try Task.checkCancellation()
                        generatedCode = sanitize(partial.content)
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
        model.activeCode.wrappedValue = generatedCode
        model.cursorLocation = generatedCode.utf16.count
    }

    private func appendToActiveCode() {
        let existing = model.activeCode.wrappedValue
        let separator =
            existing.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? "" : "\n\n"
        let updatedCode = existing + separator + generatedCode
        model.activeCode.wrappedValue = updatedCode
        model.cursorLocation = updatedCode.utf16.count
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

    let generatedCode: String
    let errorMessage: String?
    let isGenerating: Bool
    let languageName: String
    let strings: AIAssistantStrings

    let onGenerate: () -> Void
    let onCancel: () -> Void
    let onReplace: () -> Void
    let onAppend: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                AIAssistantHeader(
                    title: strings.headerTitle,
                    subtitle: strings.headerSubtitle
                )

                AIPromptComposer(
                    prompt: $prompt,
                    placeholder: strings.placeholder,
                    buttonTitle: strings.generate,
                    cancelTitle: strings.languageCode == "de"
                        ? "Abbrechen"
                        : "Cancel",
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

                if !generatedCode.isEmpty || isGenerating {
                    AIGeneratedCodeCard(
                        code: generatedCode,
                        languageName: languageName,
                        generatingTitle: strings.generating,
                        replaceTitle: strings.replace,
                        appendTitle: strings.append,
                        isGenerating: isGenerating,
                        onReplace: onReplace,
                        onAppend: onAppend
                    )
                }
            }
            .padding()
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

    let placeholder: String
    let buttonTitle: String
    let cancelTitle: String
    let isGenerating: Bool
    let onGenerate: () -> Void
    let onCancel: () -> Void

    @FocusState private var isFocused: Bool

    private var isPromptEmpty: Bool {
        prompt.trimmingCharacters(
            in: .whitespacesAndNewlines
        ).isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            promptField
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
                    .frame(minHeight: 120)
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
                        ? Color.accentColor.opacity(0.6)
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

private struct AIGeneratedCodeCard: View {
    let code: String
    let languageName: String
    let generatingTitle: String
    let replaceTitle: String
    let appendTitle: String
    let isGenerating: Bool
    let onReplace: () -> Void
    let onAppend: () -> Void

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
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
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

    private var isGerman: Bool {
        languageCode == "de"
    }

    // MARK: - Navigation

    var title: String {
        "Khyra AI"
    }

    // MARK: - Header

    var headerTitle: String {
        isGerman
            ? "Was möchtest du erstellen?"
            : "What would you like to create?"
    }

    var headerSubtitle: String {
        isGerman
            ? "Dein intelligenter Code-Assistent. Direkt auf deinem Gerät."
            : "Your intelligent coding assistant. Right on your device."
    }

    // MARK: - Prompt

    var placeholder: String {
        isGerman
            ? "Beschreibe deine Idee, eine Funktion oder was du verbessern möchtest …"
            : "Describe your idea, a feature, or something you'd like to improve…"
    }

    // MARK: - Generation

    var generate: String {
        isGerman ? "Generieren" : "Generate"
    }

    var generating: String {
        isGerman ? "Code wird erstellt …" : "Generating code…"
    }

    var cancel: String {
        isGerman ? "Abbrechen" : "Cancel"
    }

    var generationFailed: String {
        isGerman
            ? "Die Generierung ist fehlgeschlagen. Bitte versuche es erneut."
            : "Generation failed. Please try again."
    }

    // MARK: - Editor Actions

    var replace: String {
        isGerman ? "Code ersetzen" : "Replace code"
    }

    var append: String {
        isGerman ? "Code hinzufügen" : "Add code"
    }

    var copy: String {
        isGerman ? "Kopieren" : "Copy"
    }

    // MARK: - Confirmation

    var replaceConfirmationTitle: String {
        isGerman
            ? "Vorhandenen Code ersetzen?"
            : "Replace existing code?"
    }

    var replaceConfirmationMessage: String {
        isGerman
            ? "Der aktuelle Editorinhalt wird durch den generierten Code ersetzt."
            : "The current editor content will be replaced with the generated code."
    }

    // MARK: - Device Availability

    var deviceUnavailableTitle: String {
        isGerman
            ? "Gerät nicht unterstützt"
            : "Device not supported"
    }

    var deviceUnavailableMessage: String {
        isGerman
            ? "Khyra AI benötigt ein Gerät mit Apple Intelligence."
            : "Khyra AI requires a device that supports Apple Intelligence."
    }

    // MARK: - Apple Intelligence

    var appleIntelligenceDisabledTitle: String {
        isGerman
            ? "Apple Intelligence ist deaktiviert"
            : "Apple Intelligence is disabled"
    }

    var appleIntelligenceDisabledMessage: String {
        isGerman
            ? "Aktiviere Apple Intelligence in den Einstellungen, um Khyra AI zu verwenden."
            : "Enable Apple Intelligence in Settings to use Khyra AI."
    }

    // MARK: - Model Status

    var modelNotReadyTitle: String {
        isGerman
            ? "KI wird vorbereitet"
            : "AI is getting ready"
    }

    var modelNotReadyMessage: String {
        isGerman
            ? "Das Sprachmodell ist noch nicht bereit. Versuche es in Kürze erneut."
            : "The language model isn't ready yet. Please try again shortly."
    }

    // MARK: - Unavailable

    var unavailableTitle: String {
        isGerman
            ? "Khyra AI nicht verfügbar"
            : "Khyra AI unavailable"
    }

    var unavailableMessage: String {
        isGerman
            ? "Der KI-Assistent ist momentan nicht verfügbar. Bitte versuche es später erneut."
            : "The AI assistant is currently unavailable. Please try again later."
    }

    // MARK: - Privacy

    var privacyTitle: String {
        isGerman
            ? "Privat und lokal"
            : "Private and on-device"
    }

    var privacyMessage: String {
        isGerman
            ? "Die KI-Verarbeitung erfolgt direkt auf deinem Gerät."
            : "AI processing happens directly on your device."
    }
}
