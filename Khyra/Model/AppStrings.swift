//
//  AppStrings.swift
//  Khyra
//
//  Created by Tufan Cakir on 31.07.26.
//

import Foundation

struct AppStrings: Codable {
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
    // MARK: - AI Assistant

    let aiHeaderTitle: String
    let aiHeaderSubtitle: String
    let aiMode: String
    let aiGenerate: String
    let aiGenerating: String
    let aiPlaceholder: String
    let aiOnDeviceProcessing: String
    let aiGenerationFailed: String

    static func load(
        languageCode: String = Locale.current.language.languageCode?.identifier
            ?? "en"
    ) -> AppStrings {
        guard let data = try? JSONEncoder().encode(englishFallback),
            var values = try? JSONSerialization.jsonObject(with: data)
                as? [String: String]
        else {
            return .englishFallback
        }

        let locale = Locale(identifier: languageCode)
        for key in values.keys {
            values[key] = String(
                localized: String.LocalizationValue(key),
                locale: locale
            )
        }

        guard
            let localizedData = try? JSONSerialization.data(
                withJSONObject: values
            ),
            let strings = try? JSONDecoder().decode(
                AppStrings.self,
                from: localizedData
            )
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
        buildingBlocks: "Building blocks",

        aiHeaderTitle: "What would you like to create?",
        aiHeaderSubtitle:
            "Your intelligent coding assistant. Right on your device.",
        aiMode: "Mode",
        aiGenerate: "Generate",
        aiGenerating: "Generating code…",
        aiPlaceholder:
            "Describe your idea, a feature, or something you'd like to improve…",
        aiOnDeviceProcessing: "AI processing happens directly on your device.",
        aiGenerationFailed: "Generation failed. Please try again."
    )
}

// Literal declarations let Xcode extract the semantic keys and their English source values.
private enum AppStringCatalog {
    static let entries: [String] = [
        String(localized: "lines", defaultValue: "Lines"),
        String(localized: "language", defaultValue: "Language"),
        String(localized: "home", defaultValue: "Home"),
        String(
            localized: "infoDocs",
            defaultValue:
                "Documentation with examples, explanations, copy and share actions."
        ),
        String(localized: "info", defaultValue: "Info"),
        String(localized: "appearance", defaultValue: "Appearance"),
        String(localized: "refactor", defaultValue: "Refactor"),
        String(localized: "saveProject", defaultValue: "Save project"),
        String(
            localized: "infoProjects",
            defaultValue:
                "Project manager for files, folders, rename, delete, save and export."
        ),
        String(localized: "newProject", defaultValue: "New Project"),
        String(localized: "aiGenerate", defaultValue: "Generate"),
        String(localized: "noSnippets", defaultValue: "No Snippets"),
        String(
            localized: "chooseFileName",
            defaultValue: "Choose a custom name for this file."
        ),
        String(localized: "trigger", defaultValue: "Trigger"),
        String(localized: "boilerplate", defaultValue: "Boilerplate"),
        String(localized: "files", defaultValue: "Files"),
        String(localized: "title", defaultValue: "Title"),
        String(localized: "addReadme", defaultValue: "Add README.md"),
        String(localized: "none", defaultValue: "None"),
        String(localized: "delete", defaultValue: "Delete"),
        String(localized: "codeShare", defaultValue: "Share code"),
        String(localized: "frameworks", defaultValue: "Frameworks"),
        String(localized: "infoTitle", defaultValue: "What Khyra can do"),
        String(localized: "rateApp", defaultValue: "Rate Khyra"),
        String(localized: "clean", defaultValue: "clean"),
        String(localized: "saveVersion", defaultValue: "Save Version"),
        String(localized: "moreActions", defaultValue: "More Actions"),
        String(
            localized: "noFilesHint",
            defaultValue: "Tap + to create your own files."
        ),
        String(localized: "preview", defaultValue: "Preview"),
        String(localized: "version", defaultValue: "Version"),
        String(localized: "errors", defaultValue: "errors"),
        String(localized: "terminal", defaultValue: "Terminal"),
        String(localized: "line", defaultValue: "Line"),
        String(localized: "playground", defaultValue: "Playground"),
        String(localized: "german", defaultValue: "German"),
        String(localized: "format", defaultValue: "Format"),
        String(localized: "versionName", defaultValue: "Version name"),
        String(
            localized: "starterCodeDescription",
            defaultValue: "Adds a matching basic structure for this language."
        ),
        String(localized: "docs", defaultValue: "Docs"),
        String(
            localized: "activeLanguage",
            defaultValue: "Show active language"
        ),
        String(localized: "about", defaultValue: "About"),
        String(localized: "export", defaultValue: "Export"),
        String(localized: "issues", defaultValue: "Issues"),
        String(localized: "newFolder", defaultValue: "New Folder"),
        String(localized: "warning", defaultValue: "warning"),
        String(localized: "saved", defaultValue: "Saved"),
        String(
            localized: "noLintErrors",
            defaultValue: "No lint errors found."
        ),
        String(localized: "cleanCode", defaultValue: "Clean Code"),
        String(
            localized: "aiHeaderSubtitle",
            defaultValue:
                "Your intelligent coding assistant. Right on your device."
        ),
        String(localized: "appInfo", defaultValue: "App Info"),
        String(localized: "copy", defaultValue: "Copy"),
        String(
            localized: "noSnippetsHint",
            defaultValue:
                "Add frameworks/snippets in code.json or save your current code."
        ),
        String(localized: "warnings", defaultValue: "warnings"),
        String(localized: "save", defaultValue: "Save"),
        String(localized: "projects", defaultValue: "Projects"),
        String(localized: "whatDoesItDo", defaultValue: "What does it do?"),
        String(localized: "projectSetup", defaultValue: "Project Setup"),
        String(localized: "settings", defaultValue: "Settings"),
        String(
            localized: "infoDescription",
            defaultValue:
                "Khyra is a native mobile code workspace for writing, organizing, checking and previewing small projects directly on iPhone."
        ),
        String(localized: "editSnippet", defaultValue: "Edit Snippet"),
        String(localized: "renameProject", defaultValue: "Rename Project"),
        String(localized: "documentation", defaultValue: "Documentation"),
        String(localized: "error", defaultValue: "error"),
        String(
            localized: "insertBoilerplate",
            defaultValue: "Insert boilerplate"
        ),
        String(
            localized: "projectNameRequired",
            defaultValue: "Project name is required."
        ),
        String(
            localized: "openTerminalLarge",
            defaultValue: "Open terminal large"
        ),
        String(
            localized: "saveProjectFirst",
            defaultValue: "Save a project first."
        ),
        String(localized: "examples", defaultValue: "Examples"),
        String(localized: "capabilities", defaultValue: "Capabilities"),
        String(localized: "theme", defaultValue: "Theme"),
        String(localized: "newFile", defaultValue: "New File"),
        String(
            localized: "aiPlaceholder",
            defaultValue:
                "Describe your idea, a feature, or something you'd like to improve…"
        ),
        String(localized: "issueCount", defaultValue: "Issues"),
        String(localized: "support", defaultValue: "Support"),
        String(localized: "use", defaultValue: "Use"),
        String(
            localized: "aiGenerationFailed",
            defaultValue: "Generation failed. Please try again."
        ),
        String(localized: "insert", defaultValue: "Insert"),
        String(localized: "starterCode", defaultValue: "Starter code"),
        String(
            localized: "infoEditor",
            defaultValue:
                "Editor with syntax highlighting, suggestions, snippets, auto pairs, formatting and lint terminal."
        ),
        String(localized: "versions", defaultValue: "Versions"),
        String(localized: "projectName", defaultValue: "Project Name"),
        String(localized: "name", defaultValue: "Name"),
        String(localized: "english", defaultValue: "English"),
        String(
            localized: "infoNative",
            defaultValue:
                "Built with native Apple frameworks like SwiftUI, UIKit and WebKit."
        ),
        String(localized: "shareCode", defaultValue: "Share code"),
        String(localized: "create", defaultValue: "Create"),
        String(
            localized: "infoPreview",
            defaultValue:
                "Web preview renders HTML, CSS and JavaScript together with WebKit."
        ),
        String(localized: "restore", defaultValue: "Restore"),
        String(localized: "edit", defaultValue: "Edit"),
        String(
            localized: "projectIDExists",
            defaultValue: "Project ID already exists."
        ),
        String(localized: "aiGenerating", defaultValue: "Generating code…"),
        String(localized: "welcomeTitle", defaultValue: "Welcome to Khyra"),
        String(localized: "file", defaultValue: "File"),
        String(
            localized: "aiHeaderTitle",
            defaultValue: "What would you like to create?"
        ),
        String(localized: "build", defaultValue: "Build"),
        String(localized: "cancel", defaultValue: "Cancel"),
        String(localized: "fileName", defaultValue: "File name"),
        String(localized: "rename", defaultValue: "Rename"),
        String(localized: "plannedChange", defaultValue: "Planned change"),
        String(localized: "templates", defaultValue: "Templates"),
        String(localized: "codeCopy", defaultValue: "Copy code"),
        String(localized: "useFramework", defaultValue: "Use Framework"),
        String(
            localized: "aiOnDeviceProcessing",
            defaultValue: "AI processing happens directly on your device."
        ),
        String(
            localized: "projectIDRequired",
            defaultValue: "Project ID is required."
        ),
        String(
            localized: "noLocalVersions",
            defaultValue: "No local versions saved."
        ),
        String(
            localized: "projectManagerChanges",
            defaultValue: "Project Manager changes"
        ),
        String(localized: "explain", defaultValue: "Explain"),
        String(
            localized: "emptyUsesBoilerplate",
            defaultValue: "empty - uses boilerplate"
        ),
        String(
            localized: "saveVersionMessage",
            defaultValue: "Name this local code version."
        ),
        String(localized: "newSnippet", defaultValue: "New Snippet"),
        String(localized: "snippets", defaultValue: "Snippets"),
        String(
            localized: "infoPlayground",
            defaultValue:
                "Playground is for quick code experiments with editor and terminal."
        ),
        String(localized: "projectID", defaultValue: "Project ID"),
        String(
            localized: "toggleProjectNavigator",
            defaultValue: "Toggle Project Navigator"
        ),
        String(
            localized: "rateAppSubtitle",
            defaultValue: "Open App Store review"
        ),
        String(localized: "aiMode", defaultValue: "Mode"),
        String(localized: "writeOnly", defaultValue: "Write only"),
        String(localized: "noFiles", defaultValue: "No Files"),
        String(localized: "items", defaultValue: "items"),
        String(localized: "editor", defaultValue: "Editor"),
        String(
            localized: "fixSnippetErrors",
            defaultValue: "Fix snippet errors before saving."
        ),
        String(localized: "buildingBlocks", defaultValue: "Building blocks"),
        String(localized: "keywords", defaultValue: "Keywords"),
        String(
            localized: "welcomeSubtitle",
            defaultValue:
                "Create projects, open saved work, or start a quick playground."
        ),
        String(localized: "framework", defaultValue: "Framework"),
        String(localized: "noProjects", defaultValue: "No Projects"),
        String(localized: "reference", defaultValue: "Reference"),
        String(localized: "openProject", defaultValue: "Open Project"),
    ]
}
