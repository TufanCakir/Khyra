//
//  KhyraApp.swift
//  Khyra
//
//  Created by Tufan Cakir on 31.07.26.
//

import SwiftUI

@main
struct KhyraApp: App {
    var body: some Scene {
        WindowGroup {
            RootView(model: EditorModel())
        }
    }
}
