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
            "Built with native Apple frameworks like SwiftUI, UIKit and WebKit."
    )
}
