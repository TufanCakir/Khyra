//
//  PlaygroundView.swift
//  Khyra
//
//  Created by Tufan Cakir on 31.07.26.
//

import SwiftUI

/// A temporary project that uses the same editor workspace as saved projects.
///
/// Keeping one workspace implementation prevents Playground features and
/// toolbars from drifting away from the main editor.
struct PlaygroundView: View {
    let template: ProjectTemplate?

    @State private var model: EditorModel
    @State private var didLoadTemplate = false

    init(template: ProjectTemplate? = nil) {
        self.template = template
        _model = State(initialValue: EditorModel())
    }

    var body: some View {
        EditorWorkspaceView(model: model)
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                loadTemplateIfNeeded()
            }
    }

    private func loadTemplateIfNeeded() {
        guard !didLoadTemplate else { return }
        didLoadTemplate = true

        if let template {
            model.createProject(template: template)
        } else {
            model.seedDocumentsIfNeeded()
        }
    }
}

#Preview {
    NavigationStack {
        PlaygroundView()
    }
}
