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
    var projectName: String
    var selectedLanguageID: String
    var selectedProjectItemID: UUID?
    var documents: [String: String]
    var projectItems: [ProjectItem]
    var savedAt: Date
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
}
