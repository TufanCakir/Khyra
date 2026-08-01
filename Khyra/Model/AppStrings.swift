//
//  AppStrings.swift
//  Khyra
//
//  Created by Tufan Cakir on 31.07.26.
//

import Foundation

struct AppStrings: Decodable {
    let welcomeTitle: String
    let welcomeSubtitle: String
    let newProject: String
    let openProject: String
    let playground: String
    let templates: String
    let home: String
    let editor: String
    let preview: String
    let docs: String
    let settings: String
    let appearance: String
    let theme: String
    let language: String
    let german: String
    let english: String
    let about: String
    let support: String
    let rateApp: String
    let rateAppSubtitle: String
    let appInfo: String
    let version: String
    let build: String
    let capabilities: String
    let infoTitle: String
    let infoDescription: String
    let infoEditor: String
    let infoProjects: String
    let infoPreview: String
    let infoDocs: String
    let infoPlayground: String
    let infoNative: String
    let terminal: String
    let clean: String
    let error: String
    let errors: String
    let warning: String
    let warnings: String
    let issues: String
    let versions: String
    let save: String
    let cancel: String
    let create: String
    let delete: String
    let rename: String
    let export: String
    let copy: String
    let insert: String
    let edit: String
    let restore: String
    let info: String
    let saved: String
    let line: String
    let lines: String
    let issueCount: String
    let noLintErrors: String
    let saveVersion: String
    let versionName: String
    let saveVersionMessage: String
    let noLocalVersions: String
    let openTerminalLarge: String
    let newFolder: String
    let newFile: String
    let fileName: String
    let name: String
    let chooseFileName: String
    let noFiles: String
    let noFilesHint: String
    let files: String
    let snippets: String
    let noSnippets: String
    let noSnippetsHint: String
    let frameworks: String
    let examples: String
    let emptyUsesBoilerplate: String
    let useFramework: String
    let use: String
    let newSnippet: String
    let editSnippet: String
    let title: String
    let trigger: String
    let fixSnippetErrors: String
    let projectManagerChanges: String
    let plannedChange: String
    let refactor: String
    let format: String
    let cleanCode: String
    let moreActions: String
    let toggleProjectNavigator: String
    let insertBoilerplate: String
    let saveProject: String
    let shareCode: String
    let activeLanguage: String
    let codeCopy: String
    let codeShare: String
    let explain: String
    let projectSetup: String
    let projectName: String
    let projectID: String
    let projectNameRequired: String
    let projectIDRequired: String
    let projectIDExists: String
    let framework: String
    let none: String
    let addReadme: String
    let projects: String
    let noProjects: String
    let saveProjectFirst: String
    let items: String
    let renameProject: String
    let documentation: String
    let file: String
    let writeOnly: String
    let boilerplate: String
    let starterCode: String
    let starterCodeDescription: String
    let reference: String
    let keywords: String
    let whatDoesItDo: String
    let buildingBlocks: String

    static func load(
        languageCode: String = Locale.current.language.languageCode?.identifier
            ?? "en"
    ) -> AppStrings {
        let resource = languageCode == "de" ? "strings_de" : "strings_en"
        guard
            let url = Bundle.main.url(
                forResource: resource,
                withExtension: "json"
            ),
            let data = try? Data(contentsOf: url),
            let strings = try? JSONDecoder().decode(AppStrings.self, from: data)
        else {
            return .englishFallback
        }
        return strings
    }

    static let englishFallback = AppStrings(
        welcomeTitle: "Welcome to Khyra",
        welcomeSubtitle:
            "Create projects, open saved work, or start a quick playground.",
        newProject: "New Project",
        openProject: "Open Project",
        playground: "Playground",
        templates: "Templates",
        home: "Home",
        editor: "Editor",
        preview: "Preview",
        docs: "Docs",
        settings: "Settings",
        appearance: "Appearance",
        theme: "Theme",
        language: "Language",
        german: "German",
        english: "English",
        about: "About",
        support: "Support",
        rateApp: "Rate Khyra",
        rateAppSubtitle: "Open App Store review",
        appInfo: "App Info",
        version: "Version",
        build: "Build",
        capabilities: "Capabilities",
        infoTitle: "What Khyra can do",
        infoDescription:
            "Khyra is a native mobile code workspace for writing, organizing, checking and previewing small projects directly on iPhone.",
        infoEditor:
            "Editor with syntax highlighting, suggestions, snippets, auto pairs, formatting and lint output.",
        infoProjects:
            "Project manager for files, folders, rename, delete, save and export.",
        infoPreview:
            "Web preview renders HTML, CSS and JavaScript together with WebKit.",
        infoDocs:
            "Documentation includes examples, explanations, copy and share actions.",
        infoPlayground:
            "Playground is for quick experiments with editor and terminal only.",
        infoNative:
            "Built with native Apple frameworks like SwiftUI, UIKit and WebKit.",
        terminal: "Terminal",
        clean: "clean",
        error: "error",
        errors: "errors",
        warning: "warning",
        warnings: "warnings",
        issues: "Issues",
        versions: "Versions",
        save: "Save",
        cancel: "Cancel",
        create: "Create",
        delete: "Delete",
        rename: "Rename",
        export: "Export",
        copy: "Copy",
        insert: "Insert",
        edit: "Edit",
        restore: "Restore",
        info: "Info",
        saved: "Saved",
        line: "Line",
        lines: "Lines",
        issueCount: "Issues",
        noLintErrors: "No lint errors found.",
        saveVersion: "Save Version",
        versionName: "Version name",
        saveVersionMessage: "Name this local code version.",
        noLocalVersions: "No local versions saved.",
        openTerminalLarge: "Open terminal large",
        newFolder: "New Folder",
        newFile: "New File",
        fileName: "File name",
        name: "Name",
        chooseFileName: "Choose a custom name for this file.",
        noFiles: "No Files",
        noFilesHint: "Tap + to create your own files.",
        files: "Files",
        snippets: "Snippets",
        noSnippets: "No Snippets",
        noSnippetsHint:
            "Add frameworks/snippets in code.json or save your current code.",
        frameworks: "Frameworks",
        examples: "Examples",
        emptyUsesBoilerplate: "empty - uses boilerplate",
        useFramework: "Use Framework",
        use: "Use",
        newSnippet: "New Snippet",
        editSnippet: "Edit Snippet",
        title: "Title",
        trigger: "Trigger",
        fixSnippetErrors: "Fix snippet errors before saving.",
        projectManagerChanges: "Project Manager changes",
        plannedChange: "Planned change",
        refactor: "Refactor",
        format: "Format",
        cleanCode: "Clean Code",
        moreActions: "More Actions",
        toggleProjectNavigator: "Toggle Project Navigator",
        insertBoilerplate: "Insert boilerplate",
        saveProject: "Save project",
        shareCode: "Share code",
        activeLanguage: "Show active language",
        codeCopy: "Copy code",
        codeShare: "Share code",
        explain: "Explain",
        projectSetup: "Project Setup",
        projectName: "Project Name",
        projectID: "Project ID",
        projectNameRequired: "Project name is required.",
        projectIDRequired: "Project ID is required.",
        projectIDExists: "Project ID already exists.",
        framework: "Framework",
        none: "None",
        addReadme: "Add README.md",
        projects: "Projects",
        noProjects: "No Projects",
        saveProjectFirst: "Save a project first.",
        items: "items",
        renameProject: "Rename Project",
        documentation: "Documentation",
        file: "File",
        writeOnly: "Write only",
        boilerplate: "Boilerplate",
        starterCode: "Starter code",
        starterCodeDescription:
            "Adds a matching basic structure for this language.",
        reference: "Reference",
        keywords: "Keywords",
        whatDoesItDo: "What does it do?",
        buildingBlocks: "Building blocks"
    )
}
