//
//  DocumentationCatalog.swift
//  Khyra
//
//  Created by Tufan Cakir on 31.07.26.
//

import Foundation

struct DocumentationLanguageGuide: Identifiable, Hashable {
    let id: String
    let name: String
    let systemImage: String
    let frameworks: [DocumentationFrameworkGuide]
}

struct DocumentationFrameworkGuide: Identifiable, Hashable {
    let id: String
    let name: String
    let summary: String
    let systemImage: String
    let topics: [DocumentationTopic]
}

struct DocumentationTopic: Identifiable, Hashable {
    let id: String
    let title: String
    let summary: String
    let code: String
    let framework: String
    let availability: String?
    let tips: [String]

    init(
        id: String,
        title: String,
        summary: String,
        code: String,
        framework: String,
        availability: String? = nil,
        tips: [String] = []
    ) {
        self.id = id
        self.title = title
        self.summary = summary
        self.code = code
        self.framework = framework
        self.availability = availability
        self.tips = tips
    }
}

enum DocumentationCatalog {
    static func make(from store: LanguageStore) -> [DocumentationLanguageGuide]
    {
        store.languages.map { language in
            if language.id == "swift" {
                return swiftGuide(language: language)
            }
            return genericGuide(language: language)
        }
    }

    private static func swiftGuide(
        language: CodeLanguage
    ) -> DocumentationLanguageGuide {
        DocumentationLanguageGuide(
            id: language.id,
            name: language.name,
            systemImage: "swift",
            frameworks: [
                swiftCoreGuide(language: language),
                swiftUIGuide(),
                swiftDataGuide(),
                foundationGuide(),
                observationGuide(),
                foundationModelsGuide(),
            ]
                + language.frameworks.map {
                    frameworkGuide($0, language: language)
                }
        )
    }

    private static func swiftCoreGuide(
        language: CodeLanguage
    ) -> DocumentationFrameworkGuide {
        DocumentationFrameworkGuide(
            id: "swift-language",
            name: "Swift",
            summary: "Types, Optionals, Funktionen und Concurrency.",
            systemImage: "swift",
            topics: [
                DocumentationTopic(
                    id: "swift-values",
                    title: "Werte und Typen",
                    summary:
                        "let erzeugt Konstanten, var veränderbare Werte. Swift leitet Typen meistens automatisch ab.",
                    code: """
                        let appName = "Khyra"
                        var openFiles = 1
                        openFiles += 1

                        struct Project {
                            let name: String
                            let files: [String]
                        }
                        """,
                    framework: "Swift",
                    tips: [
                        "Bevorzuge let, solange sich ein Wert nicht ändern muss."
                    ]
                ),
                DocumentationTopic(
                    id: "swift-optionals",
                    title: "Optionals sicher öffnen",
                    summary:
                        "Optionals bilden fehlende Werte typisiert ab. if let und guard let vermeiden erzwungenes Entpacken.",
                    code: """
                        func displayName(for name: String?) -> String {
                            guard let name, !name.isEmpty else {
                                return "Unbekannt"
                            }
                            return name
                        }
                        """,
                    framework: "Swift",
                    tips: [
                        "Vermeide !, wenn der Wert zur Laufzeit fehlen kann."
                    ]
                ),
                DocumentationTopic(
                    id: "swift-async-await",
                    title: "async/await",
                    summary:
                        "Asynchrone Funktionen können pausieren, ohne einen Thread zu blockieren.",
                    code: """
                        func loadProject(from url: URL) async throws -> Data {
                            let (data, response) = try await URLSession.shared.data(
                                from: url
                            )
                            guard let http = response as? HTTPURLResponse,
                                  http.statusCode == 200 else {
                                throw URLError(.badServerResponse)
                            }
                            return data
                        }
                        """,
                    framework: "Swift Concurrency",
                    tips: [
                        "Fehler mit throws weiterreichen.",
                        "UI-Zustand auf dem MainActor aktualisieren.",
                    ]
                ),
                DocumentationTopic(
                    id: "swift-structured-concurrency",
                    title: "Parallele Aufgaben",
                    summary:
                        "async let und TaskGroup erzeugen strukturierte Kindaufgaben, die nicht länger als ihr Scope leben.",
                    code: """
                        async let profile = loadProfile()
                        async let projects = loadProjects()

                        let result = try await (profile, projects)
                        """,
                    framework: "Swift Concurrency",
                    tips: [
                        "Nutze Task.detached nur, wenn Actor-Kontext bewusst nicht geerbt werden soll."
                    ]
                ),
                DocumentationTopic(
                    id: "swift-actor",
                    title: "Actor",
                    summary:
                        "Actors schützen veränderlichen Zustand vor konkurrierenden Zugriffen.",
                    code: """
                        actor DownloadCounter {
                            private var completed = 0

                            func recordCompletion() {
                                completed += 1
                            }

                            func value() -> Int {
                                completed
                            }
                        }
                        """,
                    framework: "Swift Concurrency"
                ),
            ] + sourceTopics(language: language, framework: "Swift")
        )
    }

    private static func swiftUIGuide() -> DocumentationFrameworkGuide {
        DocumentationFrameworkGuide(
            id: "swiftui",
            name: "SwiftUI",
            summary: "Deklarative, native Oberflächen für Apple-Plattformen.",
            systemImage: "rectangle.3.group",
            topics: [
                DocumentationTopic(
                    id: "swiftui-view",
                    title: "View aufbauen",
                    summary:
                        "Eine View beschreibt Oberfläche deklarativ. Eigene Bereiche bleiben als kleine View-Typen übersichtlich.",
                    code: """
                        import SwiftUI

                        struct ProfileView: View {
                            let name: String

                            var body: some View {
                                VStack(spacing: 12) {
                                    Image(systemName: "person.circle.fill")
                                        .font(.largeTitle)
                                    Text(name)
                                        .font(.headline)
                                }
                            }
                        }
                        """,
                    framework: "SwiftUI"
                ),
                DocumentationTopic(
                    id: "swiftui-state",
                    title: "State und Binding",
                    summary:
                        "@State besitzt lokalen Zustand. @Binding erlaubt einer Unteransicht, den Zustand des Elternteils zu bearbeiten.",
                    code: """
                        struct CounterView: View {
                            @State private var count = 0

                            var body: some View {
                                CounterButton(count: $count)
                            }
                        }

                        struct CounterButton: View {
                            @Binding var count: Int

                            var body: some View {
                                Button("Count: \\(count)") {
                                    count += 1
                                }
                            }
                        }
                        """,
                    framework: "SwiftUI"
                ),
                DocumentationTopic(
                    id: "swiftui-navigation",
                    title: "NavigationStack",
                    summary:
                        "Wertbasierte Navigation trennt Links und Ziele und bleibt typsicher.",
                    code: """
                        NavigationStack {
                            List(projects) { project in
                                NavigationLink(project.name, value: project)
                            }
                            .navigationDestination(for: Project.self) { project in
                                ProjectDetail(project: project)
                            }
                            .navigationTitle("Projects")
                        }
                        """,
                    framework: "SwiftUI",
                    availability: "iOS 16+"
                ),
                DocumentationTopic(
                    id: "swiftui-tabs",
                    title: "Moderne Tabs",
                    summary:
                        "Tab verbindet Titel, Symbol, Auswahlwert und Inhalt. sidebarAdaptable passt die Darstellung an die Plattform an.",
                    code: """
                        enum AppTab: Hashable {
                            case home, projects, settings
                        }

                        struct RootView: View {
                            @State private var selection = AppTab.home

                            var body: some View {
                                TabView(selection: $selection) {
                                    Tab("Home", systemImage: "house", value: .home) {
                                        HomeView()
                                    }
                                    Tab("Projects", systemImage: "folder", value: .projects) {
                                        ProjectsView()
                                    }
                                    Tab("Settings", systemImage: "gear", value: .settings) {
                                        SettingsView()
                                    }
                                }
                                .tabViewStyle(.sidebarAdaptable)
                            }
                        }
                        """,
                    framework: "SwiftUI",
                    tips: [
                        "Verwende für Tab-Symbole die Outline-Variante; das System wählt den gefüllten Zustand."
                    ]
                ),
                DocumentationTopic(
                    id: "swiftui-menu-tree",
                    title: "Verschachteltes Menu",
                    summary:
                        "Menu kann weitere Menüs enthalten und eignet sich für kompakte Hierarchien.",
                    code: """
                        Menu("Einfügen", systemImage: "plus") {
                            Menu("SwiftUI") {
                                Button("View") { insertView() }
                                Button("NavigationStack") { insertNavigation() }
                            }

                            Menu("SwiftData") {
                                Button("@Model") { insertModel() }
                                Button("@Query") { insertQuery() }
                            }
                        }
                        """,
                    framework: "SwiftUI"
                ),
                DocumentationTopic(
                    id: "swiftui-toolbar-27",
                    title: "Toolbar Overflow",
                    summary:
                        "iOS 27 kann wichtige Aktionen anheften und weitere Aktionen immer im Overflow-Menü platzieren.",
                    code: """
                        .toolbar {
                            ToolbarItem(placement: .topBarPinnedTrailing) {
                                Button("Share", systemImage: "square.and.arrow.up") {
                                    share()
                                }
                            }

                            ToolbarOverflowMenu {
                                Button("Export") { export() }
                                Button("Delete", role: .destructive) { delete() }
                            }
                        }
                        """,
                    framework: "SwiftUI",
                    availability: "iOS 27+",
                    tips: [
                        "Bei älteren Deployment Targets mit #available absichern."
                    ]
                ),
                DocumentationTopic(
                    id: "swiftui-reorder-27",
                    title: "Freies Sortieren",
                    summary:
                        "reorderable und reorderContainer ermöglichen Drag-to-Reorder auch außerhalb einer List.",
                    code: """
                        LazyVGrid(columns: columns) {
                            ForEach(items) { item in
                                ItemCard(item: item)
                            }
                            .reorderable()
                        }
                        .reorderContainer(for: Item.self) { difference in
                            difference.apply(to: &items)
                        }
                        """,
                    framework: "SwiftUI",
                    availability: "iOS 27+",
                    tips: [
                        "Die apply-Hilfsfunktion bildet ReorderDifference auf dein Datenmodell ab."
                    ]
                ),
                DocumentationTopic(
                    id: "swiftui-swipe-27",
                    title: "Swipe Actions im ScrollView",
                    summary:
                        "Mit swipeActionsContainer funktionieren Swipe-Aktionen in LazyVStack und LazyVGrid.",
                    code: """
                        ScrollView {
                            LazyVStack {
                                ForEach(items) { item in
                                    ItemRow(item: item)
                                        .swipeActions {
                                            Button("Delete", role: .destructive) {
                                                delete(item)
                                            }
                                        }
                                }
                            }
                        }
                        .swipeActionsContainer()
                        """,
                    framework: "SwiftUI",
                    availability: "iOS 27+"
                ),
                DocumentationTopic(
                    id: "swiftui-async-image-27",
                    title: "AsyncImage Cache",
                    summary:
                        "Auf iOS 27 nutzt AsyncImage HTTP-Caching automatisch. URLRequest erlaubt eine eigene Cache-Policy.",
                    code: """
                        let request = URLRequest(
                            url: imageURL,
                            cachePolicy: .returnCacheDataElseLoad
                        )

                        AsyncImage(request: request) { image in
                            image
                                .resizable()
                                .scaledToFit()
                        } placeholder: {
                            ProgressView()
                        }
                        """,
                    framework: "SwiftUI",
                    availability: "iOS 27+"
                ),
            ]
        )
    }

    private static func swiftDataGuide() -> DocumentationFrameworkGuide {
        DocumentationFrameworkGuide(
            id: "swiftdata",
            name: "SwiftData",
            summary: "Persistente, typsichere Modelle für SwiftUI.",
            systemImage: "externaldrive",
            topics: [
                DocumentationTopic(
                    id: "swiftdata-model",
                    title: "@Model und Container",
                    summary:
                        "@Model macht eine Klasse persistent. modelContainer stellt Schema und ModelContext bereit.",
                    code: """
                        import SwiftData
                        import SwiftUI

                        @Model
                        final class Note {
                            var title: String
                            var createdAt: Date

                            init(title: String, createdAt: Date = .now) {
                                self.title = title
                                self.createdAt = createdAt
                            }
                        }

                        @main
                        struct NotesApp: App {
                            var body: some Scene {
                                WindowGroup {
                                    NotesView()
                                }
                                .modelContainer(for: Note.self)
                            }
                        }
                        """,
                    framework: "SwiftData",
                    availability: "iOS 17+"
                ),
                DocumentationTopic(
                    id: "swiftdata-query",
                    title: "@Query",
                    summary:
                        "@Query beobachtet gespeicherte Modelle und aktualisiert die View automatisch.",
                    code: """
                        struct NotesView: View {
                            @Environment(\\.modelContext) private var context
                            @Query(sort: \\Note.createdAt, order: .reverse)
                            private var notes: [Note]

                            var body: some View {
                                List(notes) { note in
                                    Text(note.title)
                                }
                                .toolbar {
                                    Button("Add", systemImage: "plus") {
                                        context.insert(Note(title: "Neue Notiz"))
                                    }
                                }
                            }
                        }
                        """,
                    framework: "SwiftData"
                ),
                DocumentationTopic(
                    id: "swiftdata-relationship",
                    title: "Relationships",
                    summary:
                        "Relationship beschreibt Verbindungen und das Verhalten beim Löschen.",
                    code: """
                        @Model
                        final class Folder {
                            var name: String

                            @Relationship(deleteRule: .cascade)
                            var notes: [Note] = []

                            init(name: String) {
                                self.name = name
                            }
                        }
                        """,
                    framework: "SwiftData",
                    tips: [
                        "cascade löscht zugehörige Modelle mit; nullify löst nur die Beziehung."
                    ]
                ),
            ]
        )
    }

    private static func foundationGuide() -> DocumentationFrameworkGuide {
        DocumentationFrameworkGuide(
            id: "foundation",
            name: "Foundation",
            summary: "Netzwerk, Daten, Dateien, Datum und Systemtypen.",
            systemImage: "network",
            topics: [
                DocumentationTopic(
                    id: "foundation-urlsession",
                    title: "URLSession async",
                    summary:
                        "data(from:) lädt Daten asynchron und liefert Daten sowie Response.",
                    code: """
                        struct User: Decodable {
                            let id: Int
                            let name: String
                        }

                        func loadUser(from url: URL) async throws -> User {
                            let (data, response) = try await URLSession.shared.data(
                                from: url
                            )
                            guard let http = response as? HTTPURLResponse,
                                  (200..<300).contains(http.statusCode) else {
                                throw URLError(.badServerResponse)
                            }
                            return try JSONDecoder().decode(User.self, from: data)
                        }
                        """,
                    framework: "Foundation"
                ),
                DocumentationTopic(
                    id: "foundation-codable",
                    title: "Codable",
                    summary:
                        "Codable wandelt typsichere Swift-Werte in JSON und zurück.",
                    code: """
                        struct Settings: Codable {
                            let theme: String
                            let autosave: Bool
                        }

                        let data = try JSONEncoder().encode(settings)
                        let restored = try JSONDecoder().decode(
                            Settings.self,
                            from: data
                        )
                        """,
                    framework: "Foundation"
                ),
            ]
        )
    }

    private static func observationGuide() -> DocumentationFrameworkGuide {
        DocumentationFrameworkGuide(
            id: "observation",
            name: "Observation",
            summary: "Feingranulare Zustandsbeobachtung mit @Observable.",
            systemImage: "eye",
            topics: [
                DocumentationTopic(
                    id: "observation-observable",
                    title: "@Observable",
                    summary:
                        "SwiftUI verfolgt gelesene Eigenschaften automatisch. UI-Modelle gehören auf den MainActor.",
                    code: """
                        import Observation
                        import SwiftUI

                        @MainActor
                        @Observable
                        final class AppModel {
                            var projects: [Project] = []
                            var selectedProject: Project?
                        }

                        struct ProjectList: View {
                            @State private var model = AppModel()

                            var body: some View {
                                List(model.projects) { project in
                                    Text(project.name)
                                }
                            }
                        }
                        """,
                    framework: "Observation",
                    tips: [
                        "@Observable nicht zusätzlich mit @ObservedObject umschließen."
                    ]
                )
            ]
        )
    }

    private static func foundationModelsGuide() -> DocumentationFrameworkGuide {
        DocumentationFrameworkGuide(
            id: "foundation-models",
            name: "Foundation Models",
            summary: "On-device Textgenerierung mit Apple Intelligence.",
            systemImage: "apple.intelligence",
            topics: [
                DocumentationTopic(
                    id: "foundation-models-availability",
                    title: "Verfügbarkeit prüfen",
                    summary:
                        "Prüfe das Systemmodell, bevor eine Session erstellt wird.",
                    code: """
                        import FoundationModels

                        switch SystemLanguageModel.default.availability {
                        case .available:
                            let session = LanguageModelSession()
                        case .unavailable(let reason):
                            print("Nicht verfügbar: \\(reason)")
                        }
                        """,
                    framework: "FoundationModels",
                    availability: "iOS 26+"
                ),
                DocumentationTopic(
                    id: "foundation-models-response",
                    title: "Antwort generieren",
                    summary:
                        "Eine Session behält Kontext zwischen mehreren Anfragen.",
                    code: """
                        let session = LanguageModelSession(
                            instructions: "Antworte kompakt und verständlich."
                        )

                        let response = try await session.respond(
                            to: "Erkläre async/await in Swift."
                        )
                        print(response.content)
                        """,
                    framework: "FoundationModels",
                    availability: "iOS 26+"
                ),
                DocumentationTopic(
                    id: "foundation-models-stream",
                    title: "Antwort streamen",
                    summary:
                        "ResponseStream liefert fortlaufende Snapshots des bisher generierten Inhalts.",
                    code: """
                        let session = LanguageModelSession()

                        for try await partial in session.streamResponse(
                            to: "Erstelle eine SwiftUI View."
                        ) {
                            generatedText = partial.content
                        }
                        """,
                    framework: "FoundationModels",
                    availability: "iOS 26+",
                    tips: [
                        "Eine Session verarbeitet immer nur eine Anfrage gleichzeitig."
                    ]
                ),
            ]
        )
    }

    private static func genericGuide(
        language: CodeLanguage
    ) -> DocumentationLanguageGuide {
        let core = DocumentationFrameworkGuide(
            id: "\(language.id)-core",
            name: language.name,
            summary: "Syntax, Beispiele, Snippets und Schlüsselwörter.",
            systemImage: icon(for: language.id),
            topics: sourceTopics(language: language, framework: language.name)
        )

        return DocumentationLanguageGuide(
            id: language.id,
            name: language.name,
            systemImage: icon(for: language.id),
            frameworks: [core]
                + language.frameworks.map {
                    frameworkGuide($0, language: language)
                }
        )
    }

    private static func sourceTopics(
        language: CodeLanguage,
        framework: String
    ) -> [DocumentationTopic] {
        var topics: [DocumentationTopic] = []

        if let boilerplate = language.boilerplateCode,
            !boilerplate.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        {
            topics.append(
                DocumentationTopic(
                    id: "\(language.id)-starter",
                    title: "Starter",
                    summary: "Kompakter Einstieg für eine neue Datei.",
                    code: boilerplate,
                    framework: framework
                )
            )
        }

        topics.append(
            contentsOf: language.referenceSections.enumerated().map {
                index,
                reference in
                DocumentationTopic(
                    id: "\(language.id)-reference-\(index)",
                    title: reference.title,
                    summary: reference.body,
                    code: reference.code,
                    framework: framework
                )
            }
        )

        topics.append(
            contentsOf: language.snippets.enumerated().map {
                index,
                snippet in
                DocumentationTopic(
                    id: "\(language.id)-snippet-\(index)",
                    title: snippet.title,
                    summary: "Snippet-Trigger: \(snippet.trigger)",
                    code: snippet.insertText,
                    framework: framework
                )
            }
        )

        if topics.isEmpty {
            topics.append(
                DocumentationTopic(
                    id: "\(language.id)-keywords",
                    title: "Keywords",
                    summary: "Wichtige Begriffe dieser Sprache.",
                    code: language.keywords.joined(separator: "\n"),
                    framework: framework
                )
            )
        }

        return topics
    }

    private static func frameworkGuide(
        _ framework: CodeFramework,
        language: CodeLanguage
    ) -> DocumentationFrameworkGuide {
        DocumentationFrameworkGuide(
            id: "\(language.id)-\(framework.id)",
            name: framework.name,
            summary: framework.notes ?? framework.runtime,
            systemImage: "shippingbox",
            topics: [
                DocumentationTopic(
                    id: "\(language.id)-\(framework.id)-starter",
                    title: "Starter",
                    summary: framework.notes
                        ?? "Grundstruktur für \(framework.name).",
                    code: framework.boilerplateCode,
                    framework: framework.name,
                    tips: framework.previewSupported
                        ? ["Vorschau wird von Khyra unterstützt."]
                        : ["In Khyra als Codevorlage verfügbar."]
                )
            ]
        )
    }

    private static func icon(for languageID: String) -> String {
        switch languageID {
        case "html": "chevron.left.forwardslash.chevron.right"
        case "css": "paintbrush.pointed.fill"
        case "javascript": "curlybraces"
        case "swift": "swift"
        case "python": "terminal"
        case "json": "curlybraces.square"
        case "sql": "cylinder.split.1x2"
        case "markdown": "doc.richtext"
        default: "doc.text"
        }
    }
}
