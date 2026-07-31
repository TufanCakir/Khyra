//
//  SnippetStore.swift
//  Khyra
//
//  Created by Tufan Cakir on 31.07.26.
//

import Foundation
import Observation

struct UserSnippet: Codable, Identifiable, Equatable {
    let id: UUID
    var title: String
    var languageID: String
    var trigger: String
    var code: String
    var createdAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        languageID: String,
        trigger: String,
        code: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.languageID = languageID
        self.trigger = trigger
        self.code = code
        self.createdAt = createdAt
    }
}

enum SnippetStore {
    private static let key = "khyra.userSnippets"

    static func load() -> [UserSnippet] {
        guard let data = UserDefaults.standard.data(forKey: key),
            let snippets = try? JSONDecoder().decode(
                [UserSnippet].self,
                from: data
            )
        else {
            return []
        }
        return snippets.sorted { $0.createdAt > $1.createdAt }
    }

    static func save(_ snippet: UserSnippet) {
        var snippets = load()
        snippets.removeAll { $0.id == snippet.id }
        snippets.insert(snippet, at: 0)
        persist(snippets)
    }

    static func delete(_ snippet: UserSnippet) {
        var snippets = load()
        snippets.removeAll { $0.id == snippet.id }
        persist(snippets)
    }

    private static func persist(_ snippets: [UserSnippet]) {
        guard let data = try? JSONEncoder().encode(snippets) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
}

@MainActor
@Observable
final class SnippetLibraryViewModel {
    var snippets: [UserSnippet] = []

    init() {
        reload()
    }

    func reload() {
        snippets = SnippetStore.load()
    }

    func save(title: String, languageID: String, trigger: String, code: String)
    {
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanTrigger = trigger.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        let snippet = UserSnippet(
            title: cleanTitle.isEmpty ? "Snippet" : cleanTitle,
            languageID: languageID,
            trigger: cleanTrigger,
            code: code
        )
        SnippetStore.save(snippet)
        reload()
    }

    func update(
        _ snippet: UserSnippet,
        title: String,
        trigger: String,
        code: String
    ) {
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanTrigger = trigger.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        let updatedSnippet = UserSnippet(
            id: snippet.id,
            title: cleanTitle.isEmpty ? "Snippet" : cleanTitle,
            languageID: snippet.languageID,
            trigger: cleanTrigger,
            code: code,
            createdAt: snippet.createdAt
        )
        SnippetStore.save(updatedSnippet)
        reload()
    }

    func delete(_ snippet: UserSnippet) {
        SnippetStore.delete(snippet)
        reload()
    }

    func snippets(for languageID: String) -> [UserSnippet] {
        snippets.filter { $0.languageID == languageID }
    }
}
