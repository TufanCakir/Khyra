//
//  VersionStore.swift
//  Khyra
//
//  Created by Tufan Cakir on 31.07.26.
//

import Foundation

struct CodeVersion: Codable, Identifiable, Equatable {
    let id: UUID
    let title: String
    let languageID: String
    let documentKey: String
    let code: String
    let lineCount: Int
    let issueCount: Int
    let createdAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        languageID: String,
        documentKey: String,
        code: String,
        lineCount: Int,
        issueCount: Int,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.languageID = languageID
        self.documentKey = documentKey
        self.code = code
        self.lineCount = lineCount
        self.issueCount = issueCount
        self.createdAt = createdAt
    }
}

enum VersionStore {
    private static let key = "khyra.codeVersions"

    static func load(projectID: UUID, documentKey: String) -> [CodeVersion] {
        allVersions()[
            storageKey(projectID: projectID, documentKey: documentKey)
        ] ?? []
    }

    static func save(
        _ version: CodeVersion,
        projectID: UUID,
        documentKey: String
    ) {
        let key = storageKey(projectID: projectID, documentKey: documentKey)
        var versionsByDocument = allVersions()
        var versions = versionsByDocument[key] ?? []
        versions.insert(version, at: 0)
        versionsByDocument[key] = Array(versions.prefix(30))
        persist(versionsByDocument)
    }

    static func delete(
        _ version: CodeVersion,
        projectID: UUID,
        documentKey: String
    ) {
        let key = storageKey(projectID: projectID, documentKey: documentKey)
        var versionsByDocument = allVersions()
        var versions = versionsByDocument[key] ?? []
        versions.removeAll { $0.id == version.id }
        versionsByDocument[key] = versions
        persist(versionsByDocument)
    }

    private static func allVersions() -> [String: [CodeVersion]] {
        guard let data = UserDefaults.standard.data(forKey: key),
            let versions = try? JSONDecoder().decode(
                [String: [CodeVersion]].self,
                from: data
            )
        else {
            return [:]
        }
        return versions
    }

    private static func persist(_ versions: [String: [CodeVersion]]) {
        guard let data = try? JSONEncoder().encode(versions) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    private static func storageKey(projectID: UUID, documentKey: String)
        -> String
    {
        "\(projectID.uuidString)|\(documentKey)"
    }
}
