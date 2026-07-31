//
//  WelcomeView.swift
//  Khyra
//
//  Created by Tufan Cakir on 31.07.26.
//

import SwiftUI

struct WelcomeView: View {
    let model: EditorModel
    let navigate: (AppRoute) -> Void
    @State private var library = ProjectLibraryViewModel()
    @State private var activeModal: WelcomeModal?

    var body: some View {
        ZStack {
            content

            if activeModal == .templates {
                TemplatePickerModal(
                    model: model,
                    strings: model.appStrings,
                    theme: model.selectedTheme,
                    onCreate: {
                        activeModal = nil
                        navigate(.editor)
                    },
                    onClose: { activeModal = nil }
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
        VStack(alignment: .leading, spacing: 24) {
            Spacer()

            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: "chevron.left.forwardslash.chevron.right")
                    .font(.system(size: 42, weight: .heavy))
                    .foregroundStyle(model.selectedTheme.accent)
                Text(strings.welcomeTitle)
                    .font(
                        .system(size: 34, weight: .heavy, design: .monospaced)
                    )
                Text(strings.welcomeSubtitle)
                    .font(.subheadline)
                    .foregroundStyle(model.selectedTheme.secondaryText)
            }

            VStack(spacing: 12) {
                ThemedActionButton(
                    title: strings.newProject,
                    systemImage: "plus.rectangle.on.folder",
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

            Spacer()
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(model.selectedTheme.background)
        .foregroundStyle(model.selectedTheme.primaryText)
        .navigationTitle("Welcome")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var strings: AppStrings {
        model.appStrings
    }
}

enum WelcomeModal {
    case templates
    case playgroundTemplates
    case projects
}

struct TemplatePickerModal: View {
    let model: EditorModel
    let strings: AppStrings
    let theme: EditorTheme
    let onCreate: () -> Void
    let onClose: () -> Void

    var body: some View {
        ThemedModal(title: strings.templates, theme: theme, onClose: onClose) {
            ExtensionView(
                templates: ProjectTemplate.catalog(from: model.languageStore),
                theme: theme
            ) { template in
                model.createProject(template: template)
                model.saveProject()
                onCreate()
            }
        }
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
        ThemedModal(title: "Projects", theme: theme, onClose: onClose) {
            if library.projects.isEmpty {
                ContentUnavailableView(
                    "No Projects",
                    systemImage: "folder",
                    description: Text("Save a project first.")
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
                                onOpen: {
                                    model.loadProject(project)
                                    onOpen()
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
    let onOpen: () -> Void
    let onDelete: () -> Void

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
                        Text("\(project.projectItems.count) items")
                            .font(.caption)
                            .foregroundStyle(theme.secondaryText)
                    }
                    Spacer()
                }
            }
            .buttonStyle(.plain)

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
    }
}

#Preview {
    NavigationStack {
        WelcomeView(model: EditorModel()) { _ in }
    }
}
