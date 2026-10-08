//
//  ThemedComponents.swift
//  Khyra
//
//  Created by Tufan Cakir on 31.07.26.
//

import SwiftUI

struct ThemedActionButton: View {
    let title: String
    let systemImage: String
    let theme: EditorTheme
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .font(.system(size: 18, weight: .heavy))
                    .frame(width: 26)
                Text(title)
                    .font(
                        .system(size: 16, weight: .heavy, design: .monospaced)
                    )
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .bold))
            }
            .padding(16)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .foregroundStyle(theme.selectedText)
        .background(
            theme.panelBackground,
            in: RoundedRectangle(cornerRadius: 8)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(theme.border, lineWidth: 1)
        )
    }
}

struct ThemedModal<Content: View>: View {
    let title: String
    let theme: EditorTheme
    let onClose: () -> Void
    @ViewBuilder let content: () -> Content

    var body: some View {
        ZStack {
            Color.black.opacity(0.42)
                .ignoresSafeArea()
                .onTapGesture(perform: onClose)

            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    Text(title)
                        .font(.headline)
                        .lineLimit(1)

                    Spacer(minLength: 8)

                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .font(.subheadline.weight(.semibold))
                            .frame(width: 28, height: 28)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Close")
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

                Divider()
                    .overlay(theme.border)

                content()
                    .padding(14)
            }
            .frame(maxWidth: 340)
            .background(
                theme.panelBackground,
                in: RoundedRectangle(
                    cornerRadius: 18,
                    style: .continuous
                )
            )
            .overlay {
                RoundedRectangle(
                    cornerRadius: 18,
                    style: .continuous
                )
                .strokeBorder(theme.border, lineWidth: 1)
            }
            .padding(16)
        }
        .foregroundStyle(theme.primaryText)
        .tint(theme.accent)
    }
}
