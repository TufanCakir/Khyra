//
//  RootView.swift
//  Khyra
//
//  Created by Tufan Cakir on 31.07.26.
//

import SwiftUI
import WebKit

struct RootView: View {
    @State private var editorModel: EditorModel
    @State private var navigationPath: [AppRoute] = []
    @State private var selectedTab: AppTab = .home

    init(model: EditorModel) {
        _editorModel = State(initialValue: model)
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            homeTab
            editorTab
            aiTab
            documentationTab
            settingsTab
        }
        .tint(editorModel.selectedTheme.accent)
        .preferredColorScheme(
            editorModel.selectedTheme.preferredScheme
        )
        .environment(\.locale, editorModel.appLocale)
    }

    // MARK: - Home

    private var homeTab: some View {
        NavigationStack(path: $navigationPath) {
            WelcomeView(
                model: editorModel,
                navigate: navigate
            )
            .navigationDestination(for: AppRoute.self) { route in
                destination(for: route)
            }
        }
        .tabItem {
            Label(
                editorModel.appStrings.home,
                systemImage: "house"
            )
        }
        .tag(AppTab.home)
    }

    // MARK: - Editor

    private var editorTab: some View {
        NavigationStack {
            Group {
                if editorModel.hasActiveProject {
                    HomeView(model: editorModel)
                } else {
                    projectRequiredView
                }
            }
        }
        .tabItem {
            Label(
                editorModel.appStrings.editor,
                systemImage:
                    "chevron.left.forwardslash.chevron.right"
            )
        }
        .tag(AppTab.editor)
    }

    private var projectRequiredView: some View {
        ContentUnavailableView {
            Label(
                editorModel.appStrings.editor,
                systemImage:
                    "chevron.left.forwardslash.chevron.right"
            )
        } description: {
            Text(
                String(
                    localized: "Create or open a project first.",
                    locale: editorModel.appLocale
                )
            )
        } actions: {
            Button {
                openHome()
            } label: {
                Label(
                    String(
                        localized: "Go to Projects",
                        locale: editorModel.appLocale
                    ),
                    systemImage: "folder"
                )
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(editorModel.selectedTheme.background)
    }

    // MARK: - AI

    private var aiTab: some View {
        NavigationStack {
            AIAssistantView(model: editorModel) {
                selectedTab = .editor
            }
        }
        .tabItem {
            Label(
                "AI",
                systemImage: "apple.intelligence"
            )
        }
        .tag(AppTab.ai)
    }

    // MARK: - Documentation

    private var documentationTab: some View {
        NavigationStack {
            DocumentationView(model: editorModel)
        }
        .tabItem {
            Label(
                editorModel.appStrings.docs,
                systemImage: "book"
            )
        }
        .tag(AppTab.docs)
    }

    // MARK: - Settings

    private var settingsTab: some View {
        NavigationStack {
            SettingsView(model: editorModel)
        }
        .tabItem {
            Label(
                editorModel.appStrings.settings,
                systemImage: "gear"
            )
        }
        .tag(AppTab.settings)
    }

    // MARK: - Destinations

    @ViewBuilder
    private func destination(for route: AppRoute) -> some View {
        switch route {
        case .editor:
            if editorModel.hasActiveProject {
                HomeView(model: editorModel)
            } else {
                projectRequiredView
            }

        case .preview:
            if editorModel.hasActiveProject {
                WebPreviewScreen(model: editorModel)
            } else {
                projectRequiredView
            }

        case .playground(let templateID):
            let template = ProjectTemplate.catalog(
                from: editorModel.languageStore
            ).first { $0.id == templateID }

            PlaygroundView(template: template)
        }
    }

    // MARK: - Navigation

    private func navigate(to route: AppRoute) {
        switch route {
        case .editor:
            guard editorModel.hasActiveProject else {
                openHome()
                return
            }

            // Der Editor besitzt einen eigenen Tab.
            // Deshalb keinen zweiten Editor auf den
            // Home-NavigationStack legen.
            navigationPath.removeAll()
            selectedTab = .editor

        case .preview:
            guard editorModel.hasActiveProject else {
                openHome()
                return
            }

            selectedTab = .home
            navigationPath.append(.preview)

        case .playground:
            selectedTab = .home
            navigationPath.append(route)
        }
    }

    private func openHome() {
        navigationPath.removeAll()
        selectedTab = .home
    }
}

// MARK: - Navigation Types

private enum AppTab: Hashable {
    case home
    case editor
    case ai
    case docs
    case settings
}

enum AppRoute: Hashable {
    case editor
    case preview
    case playground(String?)
}

// MARK: - Web Preview

struct WebPreviewScreen: View {
    let model: EditorModel

    var body: some View {
        HTMLPreviewWebView(
            html: model.webPreviewHTML()
        )
        .background(model.selectedTheme.background)
        .navigationTitle(model.appStrings.preview)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - WKWebView

struct HTMLPreviewWebView: UIViewRepresentable {
    let html: String

    func makeCoordinator() -> Coordinator {
        Coordinator(html: html)
    }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()

        configuration.defaultWebpagePreferences
            .allowsContentJavaScript = true

        let webView = WKWebView(
            frame: .zero,
            configuration: configuration
        )

        webView.isOpaque = true
        webView.backgroundColor = .white
        webView.scrollView.backgroundColor = .white

        webView.loadHTMLString(
            html,
            baseURL: nil
        )

        return webView
    }

    func updateUIView(
        _ webView: WKWebView,
        context: Context
    ) {
        guard context.coordinator.lastHTML != html else {
            return
        }

        context.coordinator.lastHTML = html

        webView.loadHTMLString(
            html,
            baseURL: nil
        )
    }

    final class Coordinator {
        var lastHTML: String

        init(html: String) {
            self.lastHTML = html
        }
    }
}

// MARK: - Preview

#Preview {
    RootView(model: EditorModel())
}
