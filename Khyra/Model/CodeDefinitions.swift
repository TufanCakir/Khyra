//
//  CodeDefinitions.swift
//  Khyra
//
//  Created by Tufan Cakir on 31.07.26.
//

import Foundation

struct LanguageStore: Decodable {
    let languages: [CodeLanguage]

    static func load() -> LanguageStore {
        guard
            let url = Bundle.main.url(
                forResource: "code",
                withExtension: "json"
            ),
            let data = try? Data(contentsOf: url),
            let store = try? JSONDecoder().decode(
                LanguageStore.self,
                from: data
            ),
            !store.languages.isEmpty
        else {
            return LanguageStore(languages: [
                .htmlFallback, .cssFallback, .javascriptFallback,
            ])
        }
        return store
    }
}

struct CodeLanguage: Decodable, Identifiable, Equatable {
    let id: String
    let name: String
    let fileExtension: String
    let keywords: [String]
    let sampleCode: String
    let boilerplateCode: String?
    let snippets: [CodeSnippet]
    let frameworks: [CodeFramework]
    let referenceSections: [CodeReferenceSection]

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case fileExtension
        case keywords
        case sampleCode
        case boilerplateCode
        case snippets
        case frameworks
        case referenceSections
    }

    init(
        id: String,
        name: String,
        fileExtension: String,
        keywords: [String],
        sampleCode: String,
        boilerplateCode: String?,
        snippets: [CodeSnippet],
        frameworks: [CodeFramework],
        referenceSections: [CodeReferenceSection]
    ) {
        self.id = id
        self.name = name
        self.fileExtension = fileExtension
        self.keywords = keywords
        self.sampleCode = sampleCode
        self.boilerplateCode = boilerplateCode
        self.snippets = snippets
        self.frameworks = frameworks
        self.referenceSections = referenceSections
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        fileExtension = try container.decode(
            String.self,
            forKey: .fileExtension
        )
        keywords = try container.decode([String].self, forKey: .keywords)
        sampleCode =
            try container.decodeIfPresent(String.self, forKey: .sampleCode)
            ?? ""
        boilerplateCode = try container.decodeIfPresent(
            String.self,
            forKey: .boilerplateCode
        )
        snippets =
            try container.decodeIfPresent([CodeSnippet].self, forKey: .snippets)
            ?? []
        frameworks =
            try container.decodeIfPresent(
                [CodeFramework].self,
                forKey: .frameworks
            ) ?? []
        referenceSections =
            try container.decodeIfPresent(
                [CodeReferenceSection].self,
                forKey: .referenceSections
            ) ?? []
    }

    static let htmlFallback = CodeLanguage(
        id: "html",
        name: "HTML",
        fileExtension: "index.html",
        keywords: [
            "html", "head", "body", "main", "div", "span", "class", "id",
        ],
        sampleCode: "",
        boilerplateCode:
            "<main class=\"app\">\n  <h1>Hello Khyra</h1>\n</main>",
        snippets: [],
        frameworks: [],
        referenceSections: []
    )

    static let cssFallback = CodeLanguage(
        id: "css",
        name: "CSS",
        fileExtension: "style.css",
        keywords: [
            "display", "grid", "color", "background", "padding", "margin",
        ],
        sampleCode: "",
        boilerplateCode: ".app {\n  display: grid;\n  color: #19f26b;\n}",
        snippets: [],
        frameworks: [],
        referenceSections: []
    )

    static let javascriptFallback = CodeLanguage(
        id: "javascript",
        name: "JS",
        fileExtension: "app.js",
        keywords: [
            "const", "let", "function", "return", "if", "else", "document",
            "console",
        ],
        sampleCode: "",
        boilerplateCode:
            "const app = document.querySelector('.app');\nconsole.log(app);",
        snippets: [],
        frameworks: [],
        referenceSections: []
    )
}

struct CodeSnippet: Decodable, Identifiable, Equatable {
    var id: String { trigger + title }
    let trigger: String
    let title: String
    let insertText: String
}

struct CodeFramework: Decodable, Identifiable, Equatable {
    let id: String
    let name: String
    let runtime: String
    let previewSupported: Bool
    let detectionPatterns: [String]
    let boilerplateCode: String
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case runtime
        case previewSupported
        case detectionPatterns
        case boilerplateCode
        case notes
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        runtime =
            try container.decodeIfPresent(String.self, forKey: .runtime)
            ?? "local"
        previewSupported =
            try container.decodeIfPresent(Bool.self, forKey: .previewSupported)
            ?? false
        detectionPatterns =
            try container.decodeIfPresent(
                [String].self,
                forKey: .detectionPatterns
            ) ?? []
        boilerplateCode = try container.decode(
            String.self,
            forKey: .boilerplateCode
        )
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
    }
}

struct CodeReferenceSection: Decodable, Identifiable, Equatable {
    var id: String { title }
    let title: String
    let body: String
    let code: String
}
