//
//  WelcomeView.swift
//  Khyra
//
//  Created by Tufan Cakir on 31.07.26.
//

import StoreKit
import SwiftUI

struct WelcomeView: View {
    let model: EditorModel
    let navigate: (AppRoute) -> Void
    @Environment(\.requestReview) private var requestReview
    @State private var library = ProjectLibraryViewModel()
    @State private var activeModal: WelcomeModal?
    @State private var selectedTemplate: ProjectTemplate?

    var body: some View {
        ZStack {
            content

            if activeModal == .templates {
                TemplatePickerModal(
                    model: model,
                    strings: model.appStrings,
                    theme: model.selectedTheme,
                    onSelect: { template in
                        selectedTemplate = template
                        activeModal = .projectSetup
                    },
                    onClose: { activeModal = nil }
                )
            }

            if activeModal == .projectSetup, let selectedTemplate {
                ProjectSetupModal(
                    model: model,
                    library: library,
                    template: selectedTemplate,
                    theme: model.selectedTheme,
                    onCreate: {
                        library.reload()
                        activeModal = nil
                        navigate(.editor)
                        requestReviewAfterFirstProjectCreation()
                    },
                    onClose: {
                        activeModal = nil
                    }
                )
            }

            if activeModal == .playgroundTemplates {
                PlaygroundTemplatePickerModal(
                    model: model,
                    strings: model.appStrings,
                    theme: model.selectedTheme,
                    onCreate: { template in
                        activeModal = nil
                        navigate(.playground(template.id))
                    },
                    onClose: { activeModal = nil }
                )
            }

            if activeModal == .projects {
                ProjectPickerModal(
                    model: model,
                    library: library,
                    theme: model.selectedTheme,
                    onOpen: {
                        activeModal = nil
                        navigate(.editor)
                    },
                    onClose: { activeModal = nil }
                )
            }
        }
        .onAppear {
            library.reload()
        }
    }

    private var content: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 18) {
                Image(.khyraLogo)
                    .resizable()
                    .scaledToFit()

                Text(strings.welcomeTitle)
                    .font(
                        .system(size: 30, weight: .heavy, design: .monospaced)
                    )
                    .multilineTextAlignment(.center)

                Text(strings.welcomeSubtitle)
                    .font(.subheadline)
                    .foregroundStyle(model.selectedTheme.secondaryText)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity)

            VStack(spacing: 10) {
                ThemedActionButton(
                    title: strings.newProject,
                    systemImage: "folder.badge.plus",
                    theme: model.selectedTheme
                ) {
                    activeModal = .templates
                }

                ThemedActionButton(
                    title: strings.openProject,
                    systemImage: "folder",
                    theme: model.selectedTheme
                ) {
                    library.reload()
                    activeModal = .projects
                }

                ThemedActionButton(
                    title: strings.playground,
                    systemImage: "play.square",
                    theme: model.selectedTheme
                ) {
                    activeModal = .playgroundTemplates
                }
            }
            .frame(maxWidth: 360)
            .padding(.top, 18)

            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 32)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .background(model.selectedTheme.background)
        .foregroundStyle(model.selectedTheme.primaryText)
    }

    private var strings: AppStrings {
        model.appStrings
    }

    private func requestReviewAfterFirstProjectCreation() {
        guard model.shouldRequestReviewAfterFirstProjectCreation() else {
            return
        }

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(650))
            requestReview()
        }
    }
}

enum WelcomeModal {
    case templates
    case projectSetup
    case playgroundTemplates
    case projects
}

struct TemplatePickerModal: View {
    let model: EditorModel
    let strings: AppStrings
    let theme: EditorTheme
    let onSelect: (ProjectTemplate) -> Void
    let onClose: () -> Void

    var body: some View {
        ThemedModal(title: strings.templates, theme: theme, onClose: onClose) {
            ExtensionView(
                templates: ProjectTemplate.catalog(from: model.languageStore),
                theme: theme
            ) { template in
                onSelect(template)
            }
        }
    }
}

struct ProjectSetupModal: View {
    let model: EditorModel
    let library: ProjectLibraryViewModel
    let template: ProjectTemplate
    let theme: EditorTheme
    let onCreate: () -> Void
    let onClose: () -> Void

    @State private var projectName: String
    @State private var projectIdentifier: String
    @State private var selectedLanguageID: String
    @State private var selectedFrameworkID = "none"
    @State private var includeReadme = true

    init(
        model: EditorModel,
        library: ProjectLibraryViewModel,
        template: ProjectTemplate,
        theme: EditorTheme,
        onCreate: @escaping () -> Void,
        onClose: @escaping () -> Void
    ) {
        self.model = model
        self.library = library
        self.template = template
        self.theme = theme
        self.onCreate = onCreate
        self.onClose = onClose

        let initialLanguageID =
            template.files.first?.languageID
            ?? model.languageStore.languages.first?.id
            ?? "html"
        _projectName = State(initialValue: template.title)
        _projectIdentifier = State(
            initialValue: Self.identifier(from: template.title)
        )
        _selectedLanguageID = State(initialValue: initialLanguageID)
    }

    private var selectedLanguage: CodeLanguage {
        model.languageStore.languages.first { $0.id == selectedLanguageID }
            ?? CodeLanguage.htmlFallback
    }

    private var availableFrameworks: [CodeFramework] {
        selectedLanguage.frameworks
    }

    private var normalizedIdentifier: String {
        Self.identifier(from: projectIdentifier)
    }

    private var identifierExists: Bool {
        library.projects.contains {
            Self.identifier(from: $0.projectIdentifier) == normalizedIdentifier
        }
    }

    private var validationMessage: String? {
        if projectName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return strings.projectNameRequired
        }
        if normalizedIdentifier.isEmpty {
            return strings.projectIDRequired
        }
        if identifierExists {
            return strings.projectIDExists
        }
        return nil
    }

    private var canCreate: Bool {
        validationMessage == nil
    }

    var body: some View {
        ThemedModal(title: strings.projectSetup, theme: theme, onClose: onClose)
        {
            VStack(alignment: .leading, spacing: 12) {
                setupHeader

                setupTextField(
                    title: strings.projectName,
                    text: $projectName,
                    systemImage: "textformat"
                )

                setupTextField(
                    title: strings.projectID,
                    text: $projectIdentifier,
                    systemImage: "number"
                )

                Picker(strings.language, selection: $selectedLanguageID) {
                    ForEach(model.languageStore.languages) { language in
                        Text(language.name).tag(language.id)
                    }
                }
                .pickerStyle(.navigationLink)
                .tint(theme.accent)

                Picker(strings.framework, selection: $selectedFrameworkID) {
                    Text(strings.none).tag("none")
                    ForEach(availableFrameworks) { framework in
                        Text(framework.name).tag(framework.id)
                    }
                }
                .pickerStyle(.navigationLink)
                .tint(theme.accent)

                Toggle(isOn: $includeReadme) {
                    Label(strings.addReadme, systemImage: "doc.richtext")
                        .font(
                            .system(
                                size: 13,
                                weight: .heavy,
                                design: .monospaced
                            )
                        )
                }
                .tint(theme.accent)
                .padding(10)
                .background(
                    theme.controlBackground,
                    in: RoundedRectangle(cornerRadius: 8)
                )

                if let validationMessage {
                    Label(
                        validationMessage,
                        systemImage: "exclamationmark.triangle.fill"
                    )
                    .font(
                        .system(size: 12, weight: .heavy, design: .monospaced)
                    )
                    .foregroundStyle(theme.error)
                } else {
                    Label(
                        "ID: \(normalizedIdentifier)",
                        systemImage: "checkmark.circle.fill"
                    )
                    .font(
                        .system(size: 12, weight: .heavy, design: .monospaced)
                    )
                    .foregroundStyle(theme.success)
                }

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

                    Button(action: createProject) {
                        Label(strings.create, systemImage: "checkmark")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(
                        canCreate ? theme.selectedText : theme.secondaryText
                    )
                    .padding(12)
                    .background(
                        canCreate
                            ? theme.accent.opacity(0.24)
                            : theme.controlBackground,
                        in: RoundedRectangle(cornerRadius: 8)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(
                                canCreate ? theme.accent : theme.border,
                                lineWidth: 1
                            )
                    )
                    .disabled(!canCreate)
                }
            }
            .onChange(of: selectedLanguageID) {
                selectedFrameworkID = "none"
            }
        }
    }

    private var setupHeader: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: template.systemImage)
                .font(.system(size: 18, weight: .heavy))
                .foregroundStyle(theme.accent)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 4) {
                Text(template.title)
                    .font(
                        .system(size: 14, weight: .heavy, design: .monospaced)
                    )
                Text(template.subtitle)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(theme.secondaryText)
            }
        }
    }

    private var strings: AppStrings {
        model.appStrings
    }

    private func setupTextField(
        title: String,
        text: Binding<String>,
        systemImage: String
    ) -> some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .foregroundStyle(theme.accent)
                .frame(width: 20)
            TextField(title, text: text)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .font(.system(size: 13, weight: .heavy, design: .monospaced))
        }
        .padding(10)
        .background(
            theme.controlBackground,
            in: RoundedRectangle(cornerRadius: 8)
        )
    }

    private func createProject() {
        guard canCreate else { return }
        model.createProject(
            template: template,
            name: projectName,
            identifier: normalizedIdentifier,
            languageID: selectedLanguageID,
            frameworkID: selectedFrameworkID == "none"
                ? nil : selectedFrameworkID,
            includeReadme: includeReadme
        )
        model.saveProject()
        onCreate()
    }

    private static func identifier(from value: String) -> String {
        let normalized = value.lowercased().map { character in
            character.isLetter || character.isNumber || character == "-"
                ? character : "-"
        }
        return String(normalized).split(separator: "-").joined(separator: "-")
    }
}

struct PlaygroundTemplatePickerModal: View {
    let model: EditorModel
    let strings: AppStrings
    let theme: EditorTheme
    let onCreate: (ProjectTemplate) -> Void
    let onClose: () -> Void

    var body: some View {
        ThemedModal(title: strings.playground, theme: theme, onClose: onClose) {
            ExtensionView(
                templates: ProjectTemplate.catalog(from: model.languageStore),
                theme: theme
            ) { template in
                onCreate(template)
            }
        }
    }
}

struct ProjectPickerModal: View {
    let model: EditorModel
    let library: ProjectLibraryViewModel
    let theme: EditorTheme
    let onOpen: () -> Void
    let onClose: () -> Void

    var body: some View {
        ThemedModal(
            title: model.appStrings.projects,
            theme: theme,
            onClose: onClose
        ) {
            if library.projects.isEmpty {
                ContentUnavailableView(
                    model.appStrings.noProjects,
                    systemImage: "folder",
                    description: Text(model.appStrings.saveProjectFirst)
                )
                .foregroundStyle(theme.secondaryText)
                .frame(height: 220)
            } else {
                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(library.projects) { project in
                            ProjectLibraryRow(
                                project: project,
                                theme: theme,
                                strings: model.appStrings,
                                onOpen: {
                                    model.loadProject(project)
                                    onOpen()
                                },
                                onRename: { name in
                                    library.rename(project, to: name)
                                },
                                onDelete: {
                                    library.delete(project)
                                }
                            )
                        }
                    }
                }
                .frame(maxHeight: 420)
            }
        }
    }
}

struct ProjectLibraryRow: View {
    let project: SavedProject
    let theme: EditorTheme
    let strings: AppStrings
    let onOpen: () -> Void
    let onRename: (String) -> Void
    let onDelete: () -> Void
    @State private var showRenamePrompt = false
    @State private var renamedProjectName = ""

    var body: some View {
        HStack(spacing: 10) {
            Button(action: onOpen) {
                HStack(spacing: 10) {
                    Image(systemName: "folder")
                        .foregroundStyle(theme.accent)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(project.projectName)
                            .font(
                                .system(
                                    size: 14,
                                    weight: .heavy,
                                    design: .monospaced
                                )
                            )
                        Text("\(project.projectItems.count) \(strings.items)")
                            .font(.caption)
                            .foregroundStyle(theme.secondaryText)
                        Text(project.projectIdentifier)
                            .font(
                                .system(
                                    size: 10,
                                    weight: .bold,
                                    design: .monospaced
                                )
                            )
                            .foregroundStyle(theme.accent)
                    }
                    Spacer()
                }
            }
            .buttonStyle(.plain)

            Button {
                renamedProjectName = project.projectName
                showRenamePrompt = true
            } label: {
                Image(systemName: "pencil")
                    .frame(width: 34, height: 34)
            }
            .buttonStyle(.plain)
            .foregroundStyle(theme.accent)

            Button(role: .destructive, action: onDelete) {
                Image(systemName: "trash")
                    .frame(width: 34, height: 34)
            }
            .buttonStyle(.plain)
            .foregroundStyle(theme.error)
        }
        .padding(12)
        .background(
            theme.controlBackground,
            in: RoundedRectangle(cornerRadius: 8)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(theme.border, lineWidth: 1)
        )
        .alert(strings.renameProject, isPresented: $showRenamePrompt) {
            TextField(strings.projectName, text: $renamedProjectName)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            Button(strings.save) {
                onRename(renamedProjectName)
            }
            Button(strings.cancel, role: .cancel) {}
        }
    }
}

#Preview {
    NavigationStack {
        WelcomeView(model: EditorModel()) { _ in }
    }
}
