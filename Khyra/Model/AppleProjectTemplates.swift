//
//  AppleProjectTemplates.swift
//  Khyra
//
//  Created by Tufan Cakir on 31.07.26.
//

import Foundation

extension ProjectTemplate {
    static let swiftBasics = ProjectTemplate(
        id: "swift-basics",
        category: .app,
        title: "Swift",
        subtitle: "Modern Swift with async/await and strong types.",
        systemImage: "swift",
        files: [
            ProjectTemplateFile(
                name: "Main.swift",
                languageID: "swift",
                code: """
                    import Foundation

                    struct Repository {
                        func loadGreeting() async throws -> String {
                            try await Task.sleep(for: .milliseconds(250))
                            return "Hello from modern Swift"
                        }
                    }

                    @main
                    struct KhyraApp {
                        static func main() async {
                            do {
                                let greeting = try await Repository().loadGreeting()
                                print(greeting)
                            } catch {
                                print("Loading failed: \\(error.localizedDescription)")
                            }
                        }
                    }
                    """
            )
        ]
    )

    static let swiftUIApp = ProjectTemplate(
        id: "swiftui-app",
        category: .app,
        title: "SwiftUI App",
        subtitle: "A clean multi-file SwiftUI starter.",
        systemImage: "rectangle.3.group",
        files: [
            ProjectTemplateFile(
                name: "StarterApp.swift",
                languageID: "swift",
                code: """
                    import SwiftUI

                    @main
                    struct StarterApp: App {
                        var body: some Scene {
                            WindowGroup {
                                ContentView()
                            }
                        }
                    }
                    """
            ),
            ProjectTemplateFile(
                name: "ContentView.swift",
                languageID: "swift",
                code: """
                    import SwiftUI

                    struct ContentView: View {
                        @State private var count = 0

                        var body: some View {
                            VStack(spacing: 20) {
                                Image(systemName: "swift")
                                    .font(.largeTitle)
                                    .foregroundStyle(.orange)

                                Text("Count: \\(count)")
                                    .font(.title2)

                                Button("Increase") {
                                    count += 1
                                }
                                .buttonStyle(.borderedProminent)
                            }
                            .padding()
                        }
                    }

                    #Preview {
                        ContentView()
                    }
                    """
            ),
        ]
    )

    static let swiftUINavigation = ProjectTemplate(
        id: "swiftui-navigation",
        category: .app,
        title: "SwiftUI Navigation",
        subtitle: "Type-safe NavigationStack with detail screens.",
        systemImage: "point.topleft.down.to.point.bottomright.curvepath",
        files: [
            ProjectTemplateFile(
                name: "NavigationApp.swift",
                languageID: "swift",
                code: """
                    import SwiftUI

                    @main
                    struct NavigationApp: App {
                        var body: some Scene {
                            WindowGroup {
                                ItemListView()
                            }
                        }
                    }
                    """
            ),
            ProjectTemplateFile(
                name: "Item.swift",
                languageID: "swift",
                code: """
                    import Foundation

                    struct Item: Identifiable, Hashable {
                        let id = UUID()
                        let title: String
                        let details: String

                        static let examples = [
                            Item(title: "SwiftUI", details: "Build declarative interfaces."),
                            Item(title: "SwiftData", details: "Persist model data.")
                        ]
                    }
                    """
            ),
            ProjectTemplateFile(
                name: "ItemListView.swift",
                languageID: "swift",
                code: """
                    import SwiftUI

                    struct ItemListView: View {
                        let items = Item.examples

                        var body: some View {
                            NavigationStack {
                                List(items) { item in
                                    NavigationLink(item.title, value: item)
                                }
                                .navigationTitle("Topics")
                                .navigationDestination(for: Item.self) { item in
                                    ItemDetailView(
                                        title: item.title,
                                        details: item.details
                                    )
                                }
                            }
                        }
                    }

                    private struct ItemDetailView: View {
                        let title: String
                        let details: String

                        var body: some View {
                            VStack(alignment: .leading, spacing: 12) {
                                Text(title)
                                    .font(.title.bold())
                                Text(details)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .navigationTitle(title)
                        }
                    }
                    """
            ),
        ]
    )

    static let swiftDataApp = ProjectTemplate(
        id: "swiftdata-app",
        category: .data,
        title: "SwiftData App",
        subtitle: "Persistent models with @Model and @Query.",
        systemImage: "externaldrive.badge.icloud",
        files: [
            ProjectTemplateFile(
                name: "SwiftDataStarterApp.swift",
                languageID: "swift",
                code: """
                    import SwiftData
                    import SwiftUI

                    @main
                    struct SwiftDataStarterApp: App {
                        var body: some Scene {
                            WindowGroup {
                                ItemsView()
                            }
                            .modelContainer(for: Item.self)
                        }
                    }
                    """
            ),
            ProjectTemplateFile(
                name: "Item.swift",
                languageID: "swift",
                code: """
                    import Foundation
                    import SwiftData

                    @Model
                    final class Item {
                        var title: String
                        var createdAt: Date

                        init(title: String, createdAt: Date = .now) {
                            self.title = title
                            self.createdAt = createdAt
                        }
                    }
                    """
            ),
            ProjectTemplateFile(
                name: "ItemsView.swift",
                languageID: "swift",
                code: """
                    import SwiftData
                    import SwiftUI

                    struct ItemsView: View {
                        @Environment(\\.modelContext) private var modelContext
                        @Query(sort: \\Item.createdAt, order: .reverse)
                        private var items: [Item]

                        var body: some View {
                            NavigationStack {
                                List {
                                    ForEach(items) { item in
                                        VStack(alignment: .leading) {
                                            Text(item.title)
                                            Text(item.createdAt, format: .dateTime)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    .onDelete(perform: deleteItems)
                                }
                                .navigationTitle("Items")
                                .toolbar {
                                    Button("Add", systemImage: "plus") {
                                        modelContext.insert(
                                            Item(title: "New Item")
                                        )
                                    }
                                }
                            }
                        }

                        private func deleteItems(at offsets: IndexSet) {
                            for index in offsets {
                                modelContext.delete(items[index])
                            }
                        }
                    }
                    """
            ),
        ]
    )

    static let foundationModelsApp = ProjectTemplate(
        id: "foundation-models-app",
        category: .frameworks,
        title: "Foundation Models",
        subtitle: "On-device generation with Apple Intelligence.",
        systemImage: "apple.intelligence",
        files: [
            ProjectTemplateFile(
                name: "IntelligenceApp.swift",
                languageID: "swift",
                code: """
                    import SwiftUI

                    @main
                    struct IntelligenceApp: App {
                        var body: some Scene {
                            WindowGroup {
                                GeneratorView()
                            }
                        }
                    }
                    """
            ),
            ProjectTemplateFile(
                name: "GeneratorView.swift",
                languageID: "swift",
                code: """
                    import FoundationModels
                    import SwiftUI

                    @available(iOS 26.0, *)
                    struct GeneratorView: View {
                        @State private var prompt = ""
                        @State private var response = ""
                        @State private var isGenerating = false

                        var body: some View {
                            NavigationStack {
                                Form {
                                    TextField("Ask something", text: $prompt)

                                    Button("Generate", systemImage: "sparkles") {
                                        generate()
                                    }
                                    .disabled(prompt.isEmpty || isGenerating)

                                    if isGenerating {
                                        ProgressView()
                                    }

                                    Text(response)
                                        .textSelection(.enabled)
                                }
                                .navigationTitle("On-device AI")
                            }
                        }

                        private func generate() {
                            guard SystemLanguageModel.default.availability == .available
                            else {
                                response = "Apple Intelligence is unavailable."
                                return
                            }

                            isGenerating = true
                            Task {
                                defer { isGenerating = false }
                                do {
                                    let session = LanguageModelSession()
                                    response = try await session.respond(
                                        to: prompt
                                    ).content
                                } catch {
                                    response = error.localizedDescription
                                }
                            }
                        }
                    }
                    """
            ),
        ]
    )
}
