//
//  AIAgentModels.swift
//  Khyra
//
//  Created by Tufan Cakir on 31.07.26.
//

import Foundation

struct AIProjectPlan: Equatable {
    let summary: String
    let folders: [String]
    let files: [AIProjectFileChange]
}

struct AIProjectFileChange: Identifiable, Equatable {
    var id: String { name }
    let name: String
    let languageID: String
    let content: String
}

#if canImport(FoundationModels)
    import FoundationModels

    @available(iOS 26.0, *)
    @Generable(description: "A safe project creation or refactoring plan")
    struct GeneratedAIProjectPlan {
        @Guide(description: "A short summary of the planned project changes")
        var summary: String

        @Guide(
            description:
                "Folder names to create. Use simple relative names without parent traversal."
        )
        var folders: [String]

        @Guide(
            description: "Complete files to create or update",
            .minimumCount(1)
        )
        var files: [GeneratedAIProjectFile]
    }

    @available(iOS 26.0, *)
    @Generable(description: "A complete source file in a project")
    struct GeneratedAIProjectFile {
        @Guide(
            description:
                "Relative file name including extension, for example index.html"
        )
        var name: String

        @Guide(
            description:
                "Khyra language identifier such as html, css, javascript, swift, python, json, or markdown"
        )
        var languageID: String

        @Guide(
            description:
                "The complete content of the file without Markdown fences"
        )
        var content: String
    }

    @available(iOS 26.0, *)
    extension GeneratedAIProjectPlan {
        var projectPlan: AIProjectPlan {
            AIProjectPlan(
                summary: summary,
                folders: folders,
                files: files.map {
                    AIProjectFileChange(
                        name: $0.name,
                        languageID: $0.languageID,
                        content: $0.content
                    )
                }
            )
        }
    }
#endif
