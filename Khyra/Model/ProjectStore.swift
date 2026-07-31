//
//  ProjectStore.swift
//  Khyra
//
//  Created by Tufan Cakir on 31.07.26.
//

import Foundation
import Observation

struct SavedProject: Codable, Identifiable, Equatable {
    let id: UUID
    var projectIdentifier: String
    var projectName: String
    var selectedLanguageID: String
    var selectedProjectItemID: UUID?
    var documents: [String: String]
    var projectItems: [ProjectItem]
    var savedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case projectIdentifier
        case projectName
        case selectedLanguageID
        case selectedProjectItemID
        case documents
        case projectItems
        case savedAt
    }

    init(
        id: UUID,
        projectIdentifier: String,
        projectName: String,
        selectedLanguageID: String,
        selectedProjectItemID: UUID?,
        documents: [String: String],
        projectItems: [ProjectItem],
        savedAt: Date
    ) {
        self.id = id
        self.projectIdentifier = projectIdentifier
        self.projectName = projectName
        self.selectedLanguageID = selectedLanguageID
        self.selectedProjectItemID = selectedProjectItemID
        self.documents = documents
        self.projectItems = projectItems
        self.savedAt = savedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        projectName = try container.decode(String.self, forKey: .projectName)
        projectIdentifier =
            try container.decodeIfPresent(
                String.self,
                forKey: .projectIdentifier
            )
            ?? projectName
        selectedLanguageID = try container.decode(
            String.self,
            forKey: .selectedLanguageID
        )
        selectedProjectItemID = try container.decodeIfPresent(
            UUID.self,
            forKey: .selectedProjectItemID
        )
        documents = try container.decode(
            [String: String].self,
            forKey: .documents
        )
        projectItems = try container.decode(
            [ProjectItem].self,
            forKey: .projectItems
        )
        savedAt = try container.decode(Date.self, forKey: .savedAt)
    }
}

enum ProjectStore {
    private static let key = "khyra.savedProjects"

    static func loadProjects() -> [SavedProject] {
        guard let data = UserDefaults.standard.data(forKey: key),
            let projects = try? JSONDecoder().decode(
                [SavedProject].self,
                from: data
            )
        else {
            return []
        }
        return projects.sorted { $0.savedAt > $1.savedAt }
    }

    static func save(_ project: SavedProject) {
        var projects = loadProjects()
        projects.removeAll { $0.id == project.id }
        projects.insert(project, at: 0)
        persist(projects)
    }

    static func delete(_ project: SavedProject) {
        var projects = loadProjects()
        projects.removeAll { $0.id == project.id }
        persist(projects)
    }

    private static func persist(_ projects: [SavedProject]) {
        guard let data = try? JSONEncoder().encode(projects) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
}

@MainActor
@Observable
final class ProjectLibraryViewModel {
    var projects: [SavedProject] = []

    init() {
        reload()
    }

    func reload() {
        projects = ProjectStore.loadProjects()
    }

    func delete(_ project: SavedProject) {
        ProjectStore.delete(project)
        reload()
    }

    func rename(_ project: SavedProject, to name: String) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        var renamedProject = project
        renamedProject.projectName = trimmedName
        renamedProject.savedAt = Date()
        ProjectStore.save(renamedProject)
        reload()
    }
}
