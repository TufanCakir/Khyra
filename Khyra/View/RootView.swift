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

    init(model: EditorModel) {
        _editorModel = State(initialValue: model)
    }

    var body: some View {
        let strings = editorModel.appStrings

        TabView {
            NavigationStack(path: $navigationPath) {
                WelcomeView(model: editorModel) { route in
                    navigationPath.append(route)
                }
                .navigationDestination(for: AppRoute.self) { route in
                    switch route {
                    case .editor:
                        HomeView(model: editorModel)
                    case .preview:
                        WebPreviewScreen(model: editorModel)
                    case .playground(let templateID):
                        let template = ProjectTemplate.catalog(
                            from: editorModel.languageStore
                        ).first { $0.id == templateID }
                        PlaygroundView(template: template)
                    }
                }
            }
            .tabItem {
                Label(strings.home, systemImage: "house")
            }

            if editorModel.hasActiveProject {
                NavigationStack {
                    HomeView(model: editorModel)
                }
                .tabItem {
                    Label(
                        strings.editor,
                        systemImage: "chevron.left.forwardslash.chevron.right"
                    )
                }

                NavigationStack {
                    WebPreviewScreen(model: editorModel)
                }
                .tabItem {
                    Label(strings.preview, systemImage: "safari")
                }
            }

            NavigationStack {
                DocumentationView(model: editorModel)
            }
            .tabItem {
                Label(strings.docs, systemImage: "book")
            }

            NavigationStack {
                SettingsView(model: editorModel)
            }
            .tabItem {
                Label(strings.settings, systemImage: "gear")
            }
        }
        .tint(editorModel.selectedTheme.accent)
        .preferredColorScheme(editorModel.selectedTheme.preferredScheme)
    }
}

enum AppRoute: Hashable {
    case editor
    case preview
    case playground(String?)
}

struct WebPreviewScreen: View {
    let model: EditorModel

    var body: some View {
        HTMLPreviewWebView(html: model.webPreviewHTML())
            .background(model.selectedTheme.background)
            .navigationTitle(model.appStrings.preview)
            .navigationBarTitleDisplayMode(.inline)
    }
}

struct HTMLPreviewWebView: UIViewRepresentable {
    let html: String

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.isOpaque = true
        webView.backgroundColor = .white
        webView.scrollView.backgroundColor = .white
        webView.loadHTMLString(html, baseURL: nil)
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        guard context.coordinator.lastHTML != html else { return }
        context.coordinator.lastHTML = html
        webView.loadHTMLString(html, baseURL: nil)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(html: html)
    }

    final class Coordinator {
        var lastHTML: String

        init(html: String) {
            self.lastHTML = html
        }
    }
}

#Preview {
    RootView(model: EditorModel())
}
