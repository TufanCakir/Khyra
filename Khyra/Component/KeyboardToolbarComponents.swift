//
//  KeyboardToolbarComponents.swift
//  Khyra
//
//  Created by Tufan Cakir on 31.07.26.
//

import SwiftUI

private struct KeyboardDismissToolbarModifier: ViewModifier {

    let accessibilityTitle: String
    let dismiss: () -> Void

    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()

                    Button {
                        dismiss()
                    } label: {
                        Image(
                            systemName: "keyboard.chevron.compact.down"
                        )
                    }
                    .accessibilityLabel(accessibilityTitle)
                }
            }
    }
}

extension View {

    func keyboardDismissToolbar(
        accessibilityTitle: String,
        dismiss: @escaping () -> Void
    ) -> some View {
        modifier(
            KeyboardDismissToolbarModifier(
                accessibilityTitle: accessibilityTitle,
                dismiss: dismiss
            )
        )
    }
}
